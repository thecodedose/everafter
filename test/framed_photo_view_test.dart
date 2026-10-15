import 'package:everafter/data/public_demo_assets.dart';
import 'package:everafter/data/trip_catalog.dart';
import 'package:everafter/data/trip_collections.dart';
import 'package:everafter/models/gallery_media.dart';
import 'package:everafter/widgets/trip_journey.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'gallery_fixtures.dart';

void main() {
  setUp(installGalleryFixtures);

  for (final size in <Size>[Size(128, 92), Size(84, 60)]) {
    testWidgets('caption fits $size with enlarged text', (tester) async {
      await tester.pumpWidget(MaterialApp(home: Center(
        child: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: SizedBox(width: size.width, height: size.height,
            child: const GalleryLocationPlacard(label: 'Georgia Aquarium 2026')),
        ),
      )));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }

  galleryTest('photo opens frameless at original resolution with save and close controls', (tester) async {
    tripCollections['spain-2026'] = const GalleryTripCollection(
      locations: <GalleryMemoryLocation>[
        GalleryMemoryLocation(slug: 'photo', label: 'Spain 2026',
          assetPaths: <String>[publicMemoryPlaceholderAsset]),
      ],
    );
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: TripJourney(trip: tripGalleryItems.first),
    )));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('gallery-memory-frame')).hitTestable().first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1300));
    final overlay = find.byKey(const ValueKey('focused-memory-overlay'));
    expect(overlay, findsOneWidget);
    expect(find.byKey(const ValueKey('save-memory-image')), findsOneWidget);
    expect(find.descendant(of: overlay, matching: find.byWidgetPredicate((widget) {
      final key = widget.key;
      return widget is Image && key is ValueKey<String> &&
        key.value.startsWith('gallery-') && key.value.endsWith('-baroque-frame');
    })), findsNothing);
    expect(find.byKey(const ValueKey('close-memory-image')), findsOneWidget);
    expect(find.descendant(of: overlay, matching: find.byWidgetPredicate((widget) =>
      widget is Image && widget.image is AssetImage &&
      (widget.image as AssetImage).assetName == publicMemoryPlaceholderAsset &&
      widget.fit == BoxFit.contain)), findsWidgets);
    final image = tester.widget<Image>(find.byKey(const ValueKey('focused-memory-image')));
    expect(image.image, isA<AssetImage>());
    await tester.tap(find.byKey(const ValueKey('close-memory-image')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 750));
    expect(find.byKey(const ValueKey('focused-memory-overlay')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
