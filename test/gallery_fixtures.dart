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
      tastes: trip.slug == 'spain-2026'
          ? galleryFoodFixtures
          : const <TasteMemory>[],
    );
  }
}

const List<TasteMemory> galleryFoodFixtures = <TasteMemory>[
  TasteMemory(
    place: 'Conveyor-belt Sushi',
    city: 'Tokyo',
    dish: 'Nigiri & spicy noodles',
    note:
        'Colourful plates of nigiri beside a steaming bowl.\nOur Tokyo table, exactly as we remember it.',
    detail:
        'Tuna, salmon, ginger, and a hot bowl of spicy noodles gathered around the conveyor-belt counter.',
    assetPath: publicMemoryPlaceholderAsset,
    accessionNumber: 'EA-JP-001',
  ),
  TasteMemory(
    place: 'Soba Counter',
    city: 'Tokyo',
    dish: 'Tempura soba set',
    note:
        'Crisp tempura, cool soba, and a giant kakiage.\nA whole lunch arranged on one tray.',
    detail:
        'A generous soba set with dipping sauce, shredded vegetables, tempura, and a golden vegetable fritter.',
    assetPath: publicMemoryPlaceholderAsset,
    accessionNumber: 'EA-JP-002',
  ),
  TasteMemory(
    place: 'Street Snack Stand',
    city: 'Tokyo',
    dish: 'Spiral potato',
    note:
        'A paper cup, a long skewer, and a tower of crisp potato.\nThe perfect walking snack.',
    detail:
        'Thin potato spirals fried until golden and dusted with seasoning, photographed just before the first bite.',
    assetPath: publicMemoryPlaceholderAsset,
    accessionNumber: 'EA-JP-003',
  ),
  TasteMemory(
    place: 'Kyoto Street Stall',
    city: 'Kyoto',
    dish: 'Taiyaki',
    note:
        'Still warm and wrapped in paper.\nA fish-shaped sweet carried through Kyoto.',
    detail:
        'A freshly baked taiyaki, held in one hand while the street blurred softly behind it.',
    assetPath: publicMemoryPlaceholderAsset,
    accessionNumber: 'EA-JP-004',
  ),
  TasteMemory(
    place: 'Matcha Stop',
    city: 'Kyoto',
    dish: 'Matcha soft serve',
    note:
        'Deep green soft serve with a crisp cone.\nA cool pause between Kyoto streets.',
    detail:
        'A tall swirl of matcha ice cream photographed against the warm wood of the shopfront.',
    assetPath: publicMemoryPlaceholderAsset,
    accessionNumber: 'EA-JP-005',
  ),
  TasteMemory(
    place: 'Matcha Republic',
    city: 'Uji',
    dish: 'Layered matcha drink',
    note:
        'Cream, milk, and matcha stacked in soft layers.\nAlmost too pretty to stir.',
    detail:
        'A chilled matcha drink from Uji, with a vivid green base fading upward through milk and cream.',
    assetPath: publicMemoryPlaceholderAsset,
    accessionNumber: 'EA-JP-006',
  ),
  TasteMemory(
    place: 'Kyoto Patisserie',
    city: 'Kyoto',
    dish: 'Strawberry shortcake',
    note:
        'Soft sponge, fresh cream, and bright strawberries.\nA small, immaculate slice.',
    detail:
        'The classic strawberry cake arrived as a neat wedge, topped with cream and one glossy berry.',
    assetPath: publicMemoryPlaceholderAsset,
    accessionNumber: 'EA-JP-007',
  ),
  TasteMemory(
    place: 'Kyoto Patisserie',
    city: 'Kyoto',
    dish: 'Blueberry tart',
    note:
        'A tiny tart crowded with blueberries.\nGlossy fruit over a crisp pastry shell.',
    detail:
        'A berry-covered tart with custard beneath, photographed on the café table before we shared it.',
    assetPath: publicMemoryPlaceholderAsset,
    accessionNumber: 'EA-JP-008',
  ),
  TasteMemory(
    place: 'Pancake Café',
    city: 'Kyoto',
    dish: 'Strawberry soufflé pancakes',
    note:
        'Pillowy pancakes under strawberries and cream.\nDessert with impossible height.',
    detail:
        'Two airy pancakes topped with fresh strawberries, whipped cream, sauce, and a dusting of sugar.',
    assetPath: publicMemoryPlaceholderAsset,
    accessionNumber: 'EA-JP-009',
  ),
  TasteMemory(
    place: 'Dinner Table',
    city: 'Kyoto',
    dish: 'Kimchi pancake',
    note:
        'Crisp edges and a soft, savoury centre.\nOne evening, one shared plate.',
    detail:
        'A hot kimchi pancake cut into wedges and photographed at the table before everyone reached in.',
    assetPath: publicMemoryPlaceholderAsset,
    accessionNumber: 'EA-JP-010',
  ),
  TasteMemory(
    place: 'Hanami Snack Stall',
    city: 'Kyoto',
    dish: 'Hanami dango',
    note:
        'Pink, white, and green on one skewer.\nA springtime sweet made for wandering.',
    detail:
        'Three soft rice dumplings in the colours of blossom season, held up against the Kyoto street.',
    assetPath: publicMemoryPlaceholderAsset,
    accessionNumber: 'EA-JP-011',
  ),
  TasteMemory(
    place: 'Udon Counter',
    city: 'Osaka',
    dish: 'Udon',
    note:
        'Thick noodles, a bright egg yolk, and scallions.\nSimple, glossy, satisfying.',
    detail:
        'A bowl of springy udon dressed with egg, greens, sesame, and crisp tempura crumbs.',
    assetPath: publicMemoryPlaceholderAsset,
    accessionNumber: 'EA-JP-012',
  ),
  TasteMemory(
    place: 'Osaka Sweet Shop',
    city: 'Osaka',
    dish: 'Strawberry daifuku',
    note:
        'A whole strawberry tucked into soft mochi.\nSweet, chewy, and gone too quickly.',
    detail:
        'The daifuku was split open to reveal bright fruit, red bean filling, and a delicate mochi shell.',
    assetPath: publicMemoryPlaceholderAsset,
    accessionNumber: 'EA-JP-013',
  ),
  TasteMemory(
    place: 'Nara Café',
    city: 'Nara',
    dish: 'Berry soda & macarons',
    note:
        'A sparkling berry drink with two tiny companions.\nThe most playful café table of the trip.',
    detail:
        'A ruby soda crowned with berries, served beside two character-shaped macarons on a wooden tray.',
    assetPath: publicMemoryPlaceholderAsset,
    accessionNumber: 'EA-JP-014',
  ),
  TasteMemory(
    place: 'Curry House',
    city: 'Nara',
    dish: 'Vegetable curry',
    note:
        'Rice, roasted vegetables, and two curries.\nA colourful plate after a long walk.',
    detail:
        'A generous curry plate with grains, greens, roasted vegetables, pickles, and contrasting sauces.',
    assetPath: publicMemoryPlaceholderAsset,
    accessionNumber: 'EA-JP-015',
  ),
  TasteMemory(
    place: 'Nara Bakery',
    city: 'Nara',
    dish: 'Strawberry cream buns',
    note:
        'Golden buns filled with cream and berries.\nA bakery-window choice with no regrets.',
    detail:
        'Two soft pastries filled with whipped cream and fresh strawberries, dusted lightly with sugar.',
    assetPath: publicMemoryPlaceholderAsset,
    accessionNumber: 'EA-JP-016',
  ),
];

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
