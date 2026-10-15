import 'package:everafter/data/trip_catalog.dart';
import 'package:everafter/data/trip_collections.dart';
import 'package:everafter/models/gallery_media.dart';

GalleryMemoryLocation? galleryMemoryLocationFor(
  String tripSlug,
  int memoryIndex,
) {
  final locations = galleryMemoryLocationsFor(tripSlug);
  return locations.isEmpty ? null : locations[memoryIndex % locations.length];
}

List<GalleryMemoryLocation> galleryMemoryLocationsFor(String tripSlug) =>
    tripCollections[tripSlug]?.locations ?? const <GalleryMemoryLocation>[];

List<GalleryMemoryAsset> defaultGalleryMediaFor(
  TripGalleryItem trip,
  int memoryIndex, {
  required bool portrait,
}) {
  final media = galleryMemoryLocationFor(trip.slug, memoryIndex)?.media;
  if (media != null && media.isNotEmpty) return media;
  return <GalleryMemoryAsset>[
    GalleryMemoryAsset(
      assetPath: portrait ? trip.portraitAssetPath : trip.assetPath,
      kind: GalleryMemoryKind.photo,
    ),
  ];
}

List<String> galleryPhotoChoicesFor(TripGalleryItem trip) {
  final choices = <String>{
    for (final location in galleryMemoryLocationsFor(trip.slug))
      for (final media in location.media)
        if (!media.isVideo) media.assetPath,
  };
  if (choices.isEmpty) choices.add(trip.assetPath);
  return choices.toList(growable: false);
}

List<GalleryVideoPost> galleryVideoPostsFor(String tripSlug) =>
    tripCollections[tripSlug]?.videoPosts ?? const <GalleryVideoPost>[];

GalleryVideoPost? galleryVideoPostFor(String tripSlug, int index) {
  final posts = galleryVideoPostsFor(tripSlug);
  return index >= 0 && index < posts.length ? posts[index] : null;
}

// Existing bundled decoration choices. These are artwork, not NFC integrations.
const List<String> galleryTrinketAssetChoices = <String>[
  'assets/images/experience/china-nfc-magnet-reveal.png',
  'assets/images/experience/hong-kong-nfc-magnet-reveal.png',
  'assets/images/experience/japan-nfc-magnet-reveal-fox.png',
  'assets/images/experience/taiwan-nfc-magnet-reveal-bubble-tea.png',
  'assets/images/experience/vietnam-nfc-magnet-reveal-lotus.png',
];
