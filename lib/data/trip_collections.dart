import 'package:everafter/data/public_demo_assets.dart';
import 'package:everafter/data/trip_catalog.dart';
import 'package:everafter/models/gallery_media.dart';

/// Each entry is an independent trip. Preview media is not a travel archive.
/// Replace only the intended entry when approved media is available.
final Map<String, GalleryTripCollection> tripCollections =
    <String, GalleryTripCollection>{
      for (final trip in tripGalleryItems)
        trip.slug: GalleryTripCollection(
          locations: <GalleryMemoryLocation>[
            GalleryMemoryLocation(
              slug: '${trip.slug}-preview',
              label: '${trip.name} — gallery preview',
              assetPaths: const <String>[
                publicMemoryPlaceholderAsset,
                publicDemoVideoAsset,
              ],
              videoPosterPaths: const <String, String>{
                publicDemoVideoAsset: publicMemoryPlaceholderAsset,
              },
            ),
          ],
          videoPosts: <GalleryVideoPost>[
            for (var index = 0; index < 7; index++)
              GalleryVideoPost(
                shortcode: '${trip.slug}-preview-${index + 1}',
                permalink: '',
                coverAssetPath: publicMemoryPlaceholderAsset,
                videoAssetPath: publicDemoVideoAsset,
              ),
          ],
        ),
    };
