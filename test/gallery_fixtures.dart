import 'package:everafter/data/gallery_memory_content.dart';
import 'package:everafter/data/public_demo_assets.dart';
import 'package:everafter/data/trip_catalog.dart';
import 'package:everafter/data/trip_collections.dart';
import 'package:everafter/models/gallery_media.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

/// Public artwork and original food-demo records used only by interaction tests.
/// These are not the user's trip media and are never runtime catalog entries.
void installGalleryFixtures() {
  final original = Map<String, GalleryTripCollection>.of(tripCollections);
  addTearDown(
    () => tripCollections
      ..clear()
      ..addAll(original),
  );
  final art = galleryTrinketAssetChoices;
  for (final trip in tripGalleryItems) {
    tripCollections[trip.slug] = tripCollections[trip.slug]!.copyWith(
      locations: <GalleryMemoryLocation>[
        GalleryMemoryLocation(
          slug: 'fixture-a',
          label: 'Fixture A',
          assetPaths: <String>[
            publicMemoryPlaceholderAsset,
            art[0],
            publicDemoVideoAsset,
          ],
          videoPosterPaths: const <String, String>{
            publicDemoVideoAsset: publicMemoryPlaceholderAsset,
          },
        ),
        GalleryMemoryLocation(
          slug: 'fixture-b',
          label: 'Fixture B',
          assetPaths: <String>[art[1], art[2]],
        ),
      ],
      videoPosts: <GalleryVideoPost>[
        for (var index = 0; index < 7; index++)
          GalleryVideoPost(
            shortcode: '${trip.slug}-fixture-${index + 1}',
            permalink: '',
            coverAssetPath: publicMemoryPlaceholderAsset,
            videoAssetPath: publicDemoVideoAsset,
          ),
      ],
    );
  }
}

void galleryTest(String description, WidgetTesterCallback callback) {
  testWidgets(description, (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() async {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await tester.binding.setSurfaceSize(null);
    });
    await callback(tester);
  });
}
