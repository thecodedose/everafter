import 'package:everafter/data/gallery_layout.dart';
import 'package:everafter/data/trip_catalog.dart';
import 'package:everafter/widgets/trip_journey.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'gallery_fixtures.dart';

void main() {
  setUp(installGalleryFixtures);
  galleryTest('every trip gallery begins with its title centered', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final trip in tripGalleryItems) {
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 1280,
            height: 800,
            child: TripJourney(trip: trip),
          ),
        ),
      );
      await tester.pump();

      final titleRect = tester.getRect(
        find.byKey(ValueKey<String>('gallery-editorial-title-${trip.slug}-0')),
      );
      expect(
        titleRect.center.dx,
        closeTo(640, 0.1),
        reason: '${trip.name} should reveal with its title in the center',
      );
    }
  });

  galleryTest('gallery slideshows advance on staggered schedules', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 1280,
          height: 800,
          child: TripJourney(
            trip: tripGalleryItems.first,
          ),
        ),
      ),
    );
    await tester.pump();

    final gallerySwitchers = find.byWidgetPredicate((widget) {
      final key = widget.key;
      return widget is AnimatedSwitcher &&
          key is ValueKey<String> &&
          key.value.startsWith('gallery-memory-switcher-');
    });

    List<String> visibleMediaKeys() =>
        gallerySwitchers.evaluate().map((element) {
          final switcher = element.widget as AnimatedSwitcher;
          return (switcher.child!.key! as ValueKey<String>).value;
        }).toList();

    final before = visibleMediaKeys();
    expect(before, hasLength(24));
    expect(before.take(12), orderedEquals(before.skip(12)));

    await tester.pump(const Duration(seconds: 1));
    final after = visibleMediaKeys();
    final changedFrames = List<int>.generate(
      12,
      (index) => index,
    ).where((index) => before[index] != after[index]).length;

    expect(changedFrames, greaterThan(0));
    expect(changedFrames, lessThan(12));
    expect(after.take(12), orderedEquals(after.skip(12)));

    final transitioningPhotos = find.descendant(
      of: gallerySwitchers,
      matching: find.byType(FadeTransition),
    );
    expect(transitioningPhotos, findsAtLeastNWidgets(25));

    await tester.pump(const Duration(milliseconds: 300));
    final fadeOpacities = tester
        .widgetList<FadeTransition>(transitioningPhotos)
        .map((transition) => transition.opacity.value);
    expect(fadeOpacities.any((opacity) => opacity > 0 && opacity < 1), isTrue);
  });

  galleryTest(
    'in-trip gallery wall follows a mouse drag and resumes drifting',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 1280,
            height: 800,
            child: TripJourney(
              trip: tripGalleryItems.first,
            ),
          ),
        ),
      );
      await tester.pump();

      double galleryOffset() => tester
          .widget<Transform>(
            find.byKey(const ValueKey('gallery-drift-transform')),
          )
          .transform
          .entry(0, 3);

      final beforeDrag = galleryOffset();
      final drag = await tester.startGesture(
        tester.getCenter(
          find.byKey(const ValueKey('trip-memory-gallery-drag-area')),
        ),
        kind: PointerDeviceKind.mouse,
      );
      await drag.moveBy(const Offset(-20, 0));
      await drag.moveBy(const Offset(-300, 0));
      await tester.pump();

      final duringDrag = galleryOffset();
      final stripWidth = GalleryLayoutStore.instance
          .layoutFor('spain-2026')
          .stripWidth;
      final draggedDistance = (beforeDrag - duringDrag) % stripWidth;
      expect(draggedDistance, greaterThan(280));
      expect(draggedDistance, lessThanOrEqualTo(320));
      expect(
        find.byKey(const ValueKey('focused-memory-overlay')),
        findsNothing,
      );

      await drag.up();
      await tester.pump();
      final afterRelease = galleryOffset();
      await tester.pump(const Duration(milliseconds: 500));

      final afterDrift = galleryOffset();
      expect(afterDrift, lessThan(afterRelease));
      expect(
        afterRelease - afterDrift,
        closeTo(6, 0.2),
        reason: 'The gallery should drift at a calm 12 pixels per second',
      );
    },
  );

  galleryTest('video frames still open inline playback and sound controls', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: TripJourney(trip: tripGalleryItems.first))));
    await tester.pump();
    final videos = find.byKey(const ValueKey('gallery-instagram-post-frame')).hitTestable();
    expect(videos, findsWidgets);
    await tester.tap(videos.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1300));
    expect(find.byKey(const ValueKey('focused-instagram-post')), findsOneWidget);
    expect(find.byKey(const ValueKey('memory-video-sound')), findsOneWidget);
    expect(find.textContaining('TASTE OF'), findsNothing);
  });
}
