import 'package:everafter/app.dart';
import 'package:everafter/data/trip_catalog.dart';
import 'package:everafter/data/trip_collections.dart';
import 'package:everafter/data/gallery_layout.dart';
import 'package:everafter/data/gallery_memory_content.dart';
import 'package:flutter/services.dart';
import 'package:everafter/routing/app_router.dart';
import 'package:everafter/widgets/trip_journey.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'gallery_fixtures.dart';

Future<ProviderContainer> _open(
  WidgetTester tester,
  String location,
  Size size,
) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  await tester.binding.setSurfaceSize(size);
  final container = ProviderContainer();
  final router = container.read(appRouterProvider);
  router.go(location);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    await tester.binding.setSurfaceSize(null);
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const EverAfterApp(),
    ),
  );
  await tester.pump();
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'catalog contains exactly the thirteen requested year-specific trips',
    () {
      expect(
        tripGalleryItems.map((trip) => trip.slug),
        orderedEquals(<String>[
          'spain-2026',
          'paris-2026',
          'georgia-aquarium-2026',
          'philippines-2025',
          'washington-2022',
          'new-york-2024',
          'carnival-2024',
          'royal-caribbean-2024',
          'msc-2025',
          'epic-universal-2025',
          'norwegian-2025',
          'royal-caribbean-2026',
          'universal-2026',
        ]),
      );
      expect(tripGalleryItems.map((trip) => trip.slug).toSet(), hasLength(13));
      expect(
        tripCollections.keys,
        unorderedEquals(tripGalleryItems.map((trip) => trip.slug)),
      );
      for (final trip in tripGalleryItems) {
        final media = galleryMemoryLocationsFor(
          trip.slug,
        ).expand((location) => location.media);
        expect(media.any((item) => item.isVideo), isTrue);
        expect(media.any((item) => !item.isVideo), isTrue);
        expect(galleryVideoPostsFor(trip.slug), hasLength(7));
      }
    },
  );

  test('bundled layouts are exactly the thirteen new trips', () async {
    final json = await rootBundle.loadString(
      GalleryLayoutStore.bundledGlobalLayoutPath,
    );
    final layouts = decodeGlobalGalleryLayoutDocument(json);
    expect(
      layouts.keys,
      unorderedEquals(tripGalleryItems.map((trip) => trip.slug)),
    );
    expect(layouts.values.every((layout) => layout.frames.isNotEmpty), isTrue);
  });

  for (final size in <Size>[
    Size(320, 568),
    Size(390, 844),
    Size(430, 932),
    Size(844, 390),
  ]) {
    testWidgets('root gallery fills $size immediately', (tester) async {
      await _open(tester, '/', size);
      expect(find.byKey(const ValueKey('trip-gallery-screen')), findsOneWidget);
      expect(
        tester.getSize(find.byKey(const ValueKey('trip-gallery-screen'))),
        size,
      );
      expect(find.byType(TripJourney), findsOneWidget);
      expect(find.byKey(const ValueKey('trip-memory-gallery')), findsOneWidget);
      expect(find.text('Start'), findsNothing);
    });

    testWidgets('curated food menu fits $size', (tester) async {
      installGalleryFixtures();
      await _open(tester, '/taste/spain-2026', size);
      await tester.pump(const Duration(milliseconds: 120));
      await tester.pump(const Duration(milliseconds: 600));
      expect(
        find.byKey(const ValueKey('taste-detail-EA-JP-001')),
        findsOneWidget,
      );
    });

    testWidgets('admin fits $size with all tools reachable', (tester) async {
      await _open(tester, '/admin/gallery', size);
      expect(
        find.byKey(const ValueKey('gallery-admin-screen')),
        findsOneWidget,
      );
      expect(find.text('Canvas'), findsOneWidget);
      expect(find.text('Inspector'), findsOneWidget);
      await tester.tap(find.text('Inspector'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('admin-item-selector-spain-2026-null')),
        findsOneWidget,
      );
    });
  }

  testWidgets('phone editor can crop and apply photos', (tester) async {
    await _open(tester, '/admin/gallery', const Size(320, 568));
    addTearDown(() => GalleryLayoutStore.instance.resetTrip('spain-2026'));
    await tester.tap(find.text('Inspector'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('admin-item-selector-spain-2026-null')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Frame 1').last);
    await tester.pumpAndSettle();
    final editButton = find.byKey(
      const ValueKey('admin-edit-frame-photos-frame-0'),
    );
    await tester.scrollUntilVisible(
      editButton,
      100,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('admin-inspector-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(editButton);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('admin-photo-picker')), findsOneWidget);
    expect(find.text('Crop'), findsOneWidget);
    await tester.tap(find.text('Photos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply photos'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('admin-photo-picker')), findsNothing);
    expect(
      GalleryLayoutStore.instance
          .layoutFor('spain-2026')
          .frames
          .first
          .effectivePhotoEdits,
      isNotEmpty,
    );
  });

  testWidgets('direct trip URLs select the requested gallery', (tester) async {
    final container = await _open(
      tester,
      '/trips/philippines-2025',
      const Size(390, 844),
    );
    expect(
      tester.widget<TripJourney>(find.byType(TripJourney)).trip.slug,
      'philippines-2025',
    );
    final router = container.read(appRouterProvider);
    router.go('/trips/spain-2026?source=nfc');
    await tester.pump();
    expect(
      tester.widget<TripJourney>(find.byType(TripJourney)).trip.slug,
      'spain-2026',
    );
    expect(
      router.routeInformationProvider.value.uri.queryParameters['source'],
      'nfc',
    );
  });

  for (final location in <String>[
    '/trips/italy',
    '/trips/no-such-trip',
    '/unknown',
    '/taste/unknown',
  ]) {
    testWidgets('$location shows recovery without a different trip', (
      tester,
    ) async {
      await _open(tester, location, const Size(390, 844));
      expect(find.byKey(const ValueKey('trip-not-found')), findsOneWidget);
      expect(find.byType(TripJourney), findsNothing);
      await tester.tap(find.text('Open gallery'));
      await tester.pump();
      expect(find.byType(TripJourney), findsOneWidget);
    });
  }

  for (final location in <String>[
    '/trip/philippines-2025',
    '/nfc/philippines-2025',
  ]) {
    testWidgets('legacy URL $location opens its gallery', (tester) async {
      final container = await _open(tester, location, const Size(390, 844));
      expect(
        container
            .read(appRouterProvider)
            .routeInformationProvider
            .value
            .uri
            .path,
        '/trips/philippines-2025',
      );
      expect(
        tester.widget<TripJourney>(find.byType(TripJourney)).trip.slug,
        'philippines-2025',
      );
    });
  }
}
