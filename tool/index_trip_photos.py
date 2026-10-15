#!/usr/bin/env python3
"""Index local photo dimensions without copying or uploading image contents."""

import json
from pathlib import Path
import re
import struct
import subprocess
import sys


def _exif_orientation(data):
    if not data.startswith(b"Exif\x00\x00"):
        return 1
    tiff = data[6:]
    order = "<" if tiff[:2] == b"II" else ">"
    try:
        offset = struct.unpack_from(order + "I", tiff, 4)[0]
        count = struct.unpack_from(order + "H", tiff, offset)[0]
        for index in range(count):
            entry = offset + 2 + index * 12
            tag, kind, length = struct.unpack_from(order + "HHI", tiff, entry)
            if tag == 0x112 and kind == 3 and length == 1:
                return struct.unpack_from(order + "H", tiff, entry + 8)[0]
    except (struct.error, IndexError):
        pass
    return 1


def image_size(path):
    with path.open("rb") as stream:
        header = stream.read(32)
        if header.startswith(b"\xff\xd8"):
            stream.seek(2)
            size = None
            orientation = 1
            while True:
                byte = stream.read(1)
                if not byte:
                    break
                if byte != b"\xff":
                    continue
                marker = stream.read(1)
                while marker == b"\xff":
                    marker = stream.read(1)
                if not marker or marker[0] in (0xDA, 0xD9):
                    break
                if marker[0] in (0x00, 0x01, 0xD8) or 0xD0 <= marker[0] <= 0xD7:
                    continue
                length = struct.unpack(">H", stream.read(2))[0] - 2
                if length < 0:
                    raise ValueError("Invalid JPEG segment")
                if marker[0] == 0xE1:
                    segment = stream.read(length)
                    if segment.startswith(b"Exif\x00\x00"):
                        orientation = _exif_orientation(segment)
                elif marker[0] in (0xC0, 0xC1, 0xC2, 0xC3, 0xC5, 0xC6, 0xC7,
                                   0xC9, 0xCA, 0xCB, 0xCD, 0xCE, 0xCF):
                    segment = stream.read(length)
                    height, width = struct.unpack_from(">HH", segment, 1)
                    size = (width, height)
                else:
                    stream.seek(length, 1)
            if size:
                return size[::-1] if orientation in (5, 6, 7, 8) else size
        if header.startswith(b"\x89PNG\r\n\x1a\n"):
            return struct.unpack_from(">II", header, 16)
        if header.startswith((b"GIF87a", b"GIF89a")):
            return struct.unpack_from("<HH", header, 6)
        if header.startswith(b"BM"):
            width, height = struct.unpack_from("<ii", header, 18)
            return abs(width), abs(height)
    # Built into macOS; handles other browser-compatible image formats.
    try:
        result = subprocess.run(
            ["sips", "-g", "pixelWidth", "-g", "pixelHeight", str(path)],
            capture_output=True, text=True, check=True, timeout=15,
        )
        width = re.search(r"pixelWidth:\s*(\d+)", result.stdout)
        height = re.search(r"pixelHeight:\s*(\d+)", result.stdout)
        if width and height:
            return int(width[1]), int(height[1])
    except (OSError, subprocess.SubprocessError):
        pass
    raise ValueError("Photo dimensions could not be read")


def build_index(project):
    catalog = (project / "lib/data/trip_catalog.dart").read_text()
    slugs = set(re.findall(r"slug: '([^']+)'", catalog))
    extensions = {".jpg", ".jpeg", ".png", ".gif", ".webp", ".avif", ".bmp"}
    photos = {}
    warnings = []
    for slug in sorted(slugs):
        directory = project / "assets/memories" / slug
        for path in sorted(directory.rglob("*")):
            relative = path.relative_to(project)
            if not path.is_file() or path.suffix.lower() not in extensions:
                continue
            if any(part.startswith(".") for part in relative.parts):
                continue
            try:
                width, height = image_size(path)
                if width <= 0 or height <= 0:
                    raise ValueError("Invalid dimensions")
                photos[relative.as_posix()] = {"width": width, "height": height}
            except (OSError, ValueError, struct.error) as error:
                warnings.append(f"{relative}: {error}")
    return {"version": 1, "photos": photos}, warnings


if __name__ == "__main__":
    project = Path(sys.argv[1] if len(sys.argv) > 1 else ".").expanduser().resolve()
    index, warnings = build_index(project)
    output = project / "assets/data/photo_dimensions.json"
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(index, indent=2) + "\n")
    print(f"Indexed {len(index['photos'])} photos: {output}")
    for warning in warnings:
        print("Warning:", warning, file=sys.stderr)
