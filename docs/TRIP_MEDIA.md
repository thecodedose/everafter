# Landscape gallery with one photo per frame

The app has 12 destinations; MSC 2025 is removed. Trip slugs and the other
stable internal trip IDs remain unchanged.

## Orientation and photo framing

The entire application, including navigation overlays and the editor, uses
landscape dimensions. When the browser viewport is upright, LandscapeViewport
rotates the application by 90 degrees before layout and swaps its dimensions.
When the phone/browser is already landscape, no extra rotation is applied.
There is no portrait gallery view or orientation toggle. This rotates the
website content rather than depending on the browser to lock the device.
Safe-area insets are rotated with the content. Browser controls remain part
of the browser and are not controlled by the Flutter widget.

The trip selector is a gold-accented photo button above the gallery. It opens
a scrollable Your travels picker with destination thumbnails, year labels and
a selected-trip indicator. The selector has its own row above the gallery. The wall scales to the
remaining height, so the controls no longer cover the tops of frames.
Wall frames match the full photo's shape. The ornate frame artwork changes
proportions so its opening has exactly the image's aspect ratio; no automatic
image stretching, cropping, or black letterboxing is needed. The initial equal
frame gaps are measured from the outside edges after this sizing.

Tapped photos open in a clean frameless viewer at the photo's natural shape,
with pinch zoom up to 6x, panning, Save image, and Close. The viewer uses the
original asset without a thumbnail-size decode. Zoom cannot create detail
missing from the original file. Save image downloads the original photo;
the browser chooses the save destination. Existing video-viewer captions still
scale to fit without a text-overflow warning.

## Automatic media discovery

The 12 existing assets/memories/<trip-slug>/ directories are declared in
pubspec.yaml. Startup loads Flutter's asset manifest, then the saved layout,
then binds one distinct photo to each frame. Photos are assigned landscape or portrait frames from their displayed image
dimensions, including JPEG EXIF orientation. Initial frames have equal rendered
heights and 80-unit gaps between their outside edges. The original ornate
frame artwork and wall design remain. Extra photos extend the wall; trips
with fewer photos have fewer photo frames.
Every video also receives its own video placement. Frames never automatically
cycle through a trip's complete collection. All Taste-of-country books, food
menu screens/routes, book animations and book editor controls are removed.
Legacy layout JSON containing foodMenu keys is accepted and those keys are
ignored; new exports no longer include them.

The uploaded inventory has 228 JPEGs total: Spain 19, Paris 22, Georgia
Aquarium 16, Philippines 52, Washington 3, New York 14, Carnival 24, Royal
Caribbean 2024 7, EPIC Universal 21, Norwegian 16, Royal Caribbean 2026 18,
and Universal 2026 16. Those should be the photo-frame counts after startup.
The wall still loops for continuous horizontal navigation, so the same wall
appears again after a full circuit.

The editor replaces the single photo in a frame and retains cropping,
positioning, frame styles, decorations, and layout export/reset. Selecting a
new photo replaces the old selection. Initial layout reflow normalizes the old
inconsistent demonstration spacing. Exported layouts include a media-layout
version and title position so subsequent manual geometry edits are preserved
rather than reflowed on every reload. Export to retain your customized layout;
runtime binding does not rewrite the source layout JSON.

## Add photos and videos

No handwritten filename list is needed. Files sort by filename, not EXIF date.
The updater builds assets/data/photo_dimensions.json locally from image headers,
without uploading photos. Rebuild this small index when adding/replacing photos,
then fully stop and restart Flutter:

```sh
python3 tool/index_trip_photos.py .
flutter pub get
flutter run -d chrome
```

Nested media folders need their own pubspec asset directory declarations.
Recognized photos: JPG, JPEG, PNG, WebP, GIF, AVIF, BMP. Recognized videos:
MP4, M4V, MOV, WebM, OGV. Matching is case insensitive. HEIC photos need
conversion to a supported format such as JPEG. Video decoding still depends
on the browser and codec; this update does not transcode media.

A video poster uses a matching clip.jpg or clip.poster.jpg, then a photo from
the same trip, then the existing globe artwork if there are no photos. Video
playback remains muted until an explicit sound-button tap. No old demo video
is used as runtime trip content.

## Verify on your Mac

```sh
flutter pub get
dart format .
flutter analyze
flutter test
flutter run -d chrome
flutter build web --release
```

Check upright and horizontal phone viewports; in both cases the gallery must
use a horizontal canvas. The app cannot rotate the browser's address bar.
Check a tapped photo opens frameless and zooms without cropping on entry,
the wall-frame openings match photo proportions without letterboxing, each
frame keeps one photo, all photos have a frame, and the editor replaces rather
than accumulates its selection. Check the new travel picker switches trips
and has no menu/book entry. Check /trips/msc-2025 uses unknown-trip recovery. Test real devices
and physical NFC tags after hosting.

Flutter and Dart are unavailable in this workspace, so automated Flutter
execution, compilation, and real-browser verification have not been claimed.
Dart syntax, source/data checks, and the update installer are checked separately.
The actual private photos were not supplied, so decoding and appearance still
need checking on your Mac.

## Privacy

No personal photo or video is included in this update. Public hosting exposes
bundled media even when its Git repository is private or the media folder is
ignored. This update adds no login or private-media hosting.

References:
- https://api.flutter.dev/flutter/widgets/RotatedBox-class.html
- https://api.flutter.dev/flutter/services/AssetManifest-class.html
- https://developer.mozilla.org/en-US/docs/Web/API/ScreenOrientation/lock

Dimension-index checks here cover JPEG, PNG, GIF and BMP header sizes, JPEG
EXIF rotations, and filtering unknown trips/hidden files. Other supported image
formats use macOS sips as a fallback. A skipped file is reported by the indexer;
check those warnings rather than assuming every file was indexed.
