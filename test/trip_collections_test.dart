import 'dart:typed_data';

import 'package:everafter/data/gallery_memory_content.dart';
import 'package:everafter/data/public_demo_assets.dart';
import 'package:everafter/data/trip_catalog.dart';
import 'package:everafter/data/trip_collections.dart';
import 'package:everafter/models/gallery_media.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _ManifestBundle extends CachingAssetBundle {
  _ManifestBundle(this.assets);

  final List<String> assets;

  @override
  Future<ByteData> load(String key) async {
    if (key != 'AssetManifest.bin') throw StateError('Unexpected asset: $key');
    return const StandardMessageCodec().encodeMessage(<String, Object>{
      for (final asset in assets)
        asset: <Object>[
          <String, Object>{'asset': asset, 'dpr': 1.0},
        ],
    })!;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('removed trip is absent and real media stays in its own trip', () {
    final collections = buildTripCollections(<String>[
      'assets/memories/spain-2026/b.jpeg',
      'assets/memories/paris-2026/a.jpeg',
      'assets/memories/spain-2026/a.jpeg',
      'assets/memories/spain-2026/a.jpeg',
      'assets/memories/msc-2025/a.jpeg',
      'assets/memories/spain-2026-other/wrong.jpeg',
      'assets/images/experience/earth-globe-fallback.png',
    ]);
    expect(collections, hasLength(12));
    expect(collections.containsKey('msc-2025'), isFalse);
    expect(tripGalleryItems.any((trip) => trip.slug == 'msc-2025'), isFalse);
    expect(collections['spain-2026']!.locations.expand((location) => location.assetPaths).toList(), <String>[
      'assets/memories/spain-2026/a.jpeg',
      'assets/memories/spain-2026/b.jpeg',
    ]);
    expect(collections['paris-2026']!.locations.single.assetPaths, <String>[
      'assets/memories/paris-2026/a.jpeg',
    ]);
    expect(collections['spain-2026']!.videoPosts, isEmpty);
    expect(collections['washington-2022']!.locations, isEmpty);
  });

  test('metadata is ignored and nested, uppercase image paths are supported', () {
    final collection = buildTripCollections(<String>[
      'assets/memories/spain-2026/.DS_Store',
      'assets/memories/spain-2026/._photo.jpeg',
      'assets/memories/spain-2026/.hidden/photo.jpg',
      'assets/memories/spain-2026/readme.txt',
      'assets/memories/spain-2026/unsupported.heic',
      'assets/memories/spain-2026/day-1/PHOTO.JPEG',
      'assets/memories/spain-2026/animated.gif',
    ])['spain-2026']!;
    expect(collection.locations.expand((location) => location.assetPaths).toList(), <String>[
      'assets/memories/spain-2026/animated.gif',
      'assets/memories/spain-2026/day-1/PHOTO.JPEG',
    ]);
    expect(collection.locations.every((location) => location.media.length == 1 && !location.media.single.isVideo), isTrue);
  });

  test('videos stay videos with matching or same-trip fallback posters', () {
    final collection = buildTripCollections(<String>[
      'assets/memories/spain-2026/a.jpeg',
      'assets/memories/spain-2026/clip.MP4',
      'assets/memories/spain-2026/clip.poster.jpg',
      'assets/memories/spain-2026/other.mov',
      'assets/memories/paris-2026/other.jpg',
    ])['spain-2026']!;
    expect(collection.locations, hasLength(2));
    expect(collection.locations.every((location) => location.media.length == 1), isTrue);
    expect(collection.videoPosts, hasLength(2));
    expect(collection.videoPosts.first.coverAssetPath,
        'assets/memories/spain-2026/clip.poster.jpg');
    expect(collection.videoPosts.last.coverAssetPath,
        'assets/memories/spain-2026/a.jpeg');
    final videoOnly = buildTripCollections(<String>[
      'assets/memories/spain-2026/video.webm',
    ])['spain-2026']!;
    expect(videoOnly.locations, isEmpty);
    expect(videoOnly.videoPosts.single.videoAssetPath, 'assets/memories/spain-2026/video.webm');
    expect(videoOnly.videoPosts.single.coverAssetPath, publicMemoryPlaceholderAsset);
  });

  test('startup manifest loading supplies both gallery and editor lookups', () async {
    final before = Map<String, GalleryTripCollection>.of(tripCollections);
    addTearDown(() => tripCollections
      ..clear()
      ..addAll(before));
    const photo = 'assets/memories/spain-2026/my-photo.jpeg';
    await loadTripCollections(bundle: _ManifestBundle(<String>[photo]));
    final trip = tripGalleryItems.first;
    expect(galleryPhotoChoicesFor(trip), <String>[photo]);
    expect(defaultGalleryMediaFor(trip, 0, portrait: false).single.assetPath, photo);
    expect(galleryVideoPostsFor(trip.slug), isEmpty);
    // A subsequent asset manifest replaces old selections, rather than appending them.
    await loadTripCollections(bundle: _ManifestBundle(<String>[
      'assets/memories/spain-2026/new-photo.jpeg',
    ]));
    expect(galleryPhotoChoicesFor(trip), <String>[
      'assets/memories/spain-2026/new-photo.jpeg',
    ]);
  });
}
