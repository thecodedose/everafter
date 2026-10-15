import 'package:everafter/data/trip_catalog.dart';
import 'package:everafter/widgets/trip_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'gallery_fixtures.dart';

void main() {
  setUp(installGalleryFixtures);

  test('trip menus show newest years first and preserve every trip', () {
    expect(tripGalleryItemsByYear.map((trip) => trip.slug), <String>[
      'spain-2026',
      'paris-2026',
      'georgia-aquarium-2026',
      'royal-caribbean-2026',
      'universal-2026',
      'philippines-2025',
      'epic-universal-2025',
      'norwegian-2025',
      'new-york-2024',
      'carnival-2024',
      'royal-caribbean-2024',
      'washington-2022',
    ]);
    expect(tripGalleryItems.first.slug, 'spain-2026');
  });


  galleryTest('trip picker displays the catalog and selects a different destination', (tester) async {
    String? selected;
    await tester.pumpWidget(MaterialApp(home: Center(child: SizedBox(width: 340,
      child: TripSelector(trip: tripGalleryItems.first, onSelected: (slug) => selected = slug)))));
    await tester.tap(find.byKey(const ValueKey('gallery-trip-selector')));
    await tester.pumpAndSettle();
    expect(find.text("Monica's Travels"), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('choose-trip-paris-2026')));
    await tester.pumpAndSettle();
    expect(selected, 'paris-2026');
    expect(find.byKey(const ValueKey('trip-picker')), findsNothing);
  });

  galleryTest('closing the trip picker preserves the selected destination', (tester) async {
    String? selected;
    await tester.pumpWidget(MaterialApp(home: Center(child: SizedBox(width: 340,
      child: TripSelector(trip: tripGalleryItems.first, onSelected: (slug) => selected = slug)))));
    await tester.tap(find.byKey(const ValueKey('gallery-trip-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Close trip picker'));
    await tester.pumpAndSettle();
    expect(selected, isNull);
  });
}
