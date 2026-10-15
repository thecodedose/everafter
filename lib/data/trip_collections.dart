import 'package:everafter/data/public_demo_assets.dart';
import 'package:everafter/data/trip_catalog.dart';
import 'package:everafter/models/gallery_media.dart';
import 'package:flutter/services.dart';

/// Populated from Flutter's bundled assets before the gallery is opened.
/// Keep the map identity stable for the gallery and editor's shared lookups.
final Map<String, GalleryTripCollection> tripCollections =
    <String, GalleryTripCollection>{
      for (final trip in tripGalleryItems)
        trip.slug: const GalleryTripCollection(),
    };

/// Uses the supported manifest API on both the web and in Flutter tests.
Future<void> loadTripCollections({AssetBundle? bundle}) async {
  final manifest = await AssetManifest.loadFromAssetBundle(bundle ?? rootBundle);
  final collections = buildTripCollections(manifest.listAssets());
  tripCollections
    ..clear()
    ..addAll(collections);
}

const _photoExtensions = <String>{
  'jpg',
  'jpeg',
  'png',
  'webp',
  'gif',
  'avif',
  'bmp',
};
const _videoExtensions = <String>{'mp4', 'm4v', 'mov', 'webm', 'ogv'};

String _extension(String path) => path.split('.').last.toLowerCase();
String _stem(String path) => path.substring(0, path.lastIndexOf('.'));

/// Only a trip's own folder can supply that trip's photos and videos.
/// Sorting the logical asset keys keeps slideshow order deterministic.
Map<String, GalleryTripCollection> buildTripCollections(
  Iterable<String> assetPaths,
) {
  final assets = assetPaths.toSet().toList()..sort();
  return <String, GalleryTripCollection>{
    for (final trip in tripGalleryItems)
      trip.slug: _collectionFor(trip, assets),
  };
}

GalleryTripCollection _collectionFor(TripGalleryItem trip, List<String> assets) {
  final prefix = 'assets/memories/${trip.slug}/';
  final media = assets.where((path) {
    if (!path.startsWith(prefix)) return false;
    // Ignore Finder metadata and hidden files, including in nested folders.
    final parts = path.substring(prefix.length).split('/');
    if (parts.any((part) => part.startsWith('.'))) {
      return false;
    }
    final extension = _extension(path);
    return _photoExtensions.contains(extension) ||
        _videoExtensions.contains(extension);
  }).toList(growable: false);
  final photos = media
      .where((path) => _photoExtensions.contains(_extension(path)))
      .toList(growable: false);
  final videos = media
      .where((path) => _videoExtensions.contains(_extension(path)))
      .toList(growable: false);

  String posterFor(String video) {
    final stem = _stem(video);
    for (final photo in photos) {
      if (_stem(photo) == stem || _stem(photo) == '$stem.poster') return photo;
    }
    return photos.isNotEmpty ? photos.first : publicMemoryPlaceholderAsset;
  }

  final posters = <String, String>{
    for (final video in videos) video: posterFor(video),
  };
  return GalleryTripCollection(
    locations: <GalleryMemoryLocation>[
      for (var index = 0; index < photos.length; index++)
        GalleryMemoryLocation(
          slug: '${trip.slug}-photo-${index + 1}',
          label: trip.name,
          assetPaths: <String>[photos[index]],
        ),
    ],
    videoPosts: <GalleryVideoPost>[
      for (var index = 0; index < videos.length; index++)
        GalleryVideoPost(
          shortcode: '${trip.slug}-video-${index + 1}',
          permalink: '',
          coverAssetPath: posters[videos[index]]!,
          videoAssetPath: videos[index],
        ),
    ],
  );
}
