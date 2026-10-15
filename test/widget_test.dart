import 'dart:math' as math;
import 'package:everafter/app.dart';
import 'package:everafter/data/gallery_layout.dart';
import 'package:everafter/data/gallery_memory_content.dart';
import 'package:everafter/data/trip_catalog.dart';
import 'package:everafter/screens/taste_of_japan_screen.dart';
import 'package:everafter/widgets/trip_journey.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'gallery_fixtures.dart';

void main() {
  setUp(installGalleryFixtures);
  galleryTest('trip gallery menu opens and switches ledger memories', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: EverAfterApp()));
    await tester.pump();

    expect(find.text('TASTE OF\nSPAIN 2026'), findsWidgets);
    final menu = find.byKey(const ValueKey('taste-of-spain-2026-menu-0'));
    expect(menu, findsOneWidget);
    final menuRect = tester.getRect(menu);
    final viewportRect = tester.getRect(
      find.byKey(const ValueKey('trip-gallery-screen')),
    );
    final menuTapTarget = find.descendant(
      of: menu,
      matching: find.byType(InkWell),
    );
    expect(menuTapTarget, findsOneWidget);
    tester.widget<InkWell>(menuTapTarget).onTap!();
    await tester.pump();

    expect(find.text('TASTES OF SPAIN 2026'), findsNothing);
    await tester.pump(const Duration(milliseconds: 40));
    final liftedMenu = tester.widget<Transform>(
      find.descendant(
        of: find.byKey(const ValueKey('taste-of-spain-2026-menu-0')),
        matching: find.byKey(const ValueKey('taste-menu-lift')),
      ),
    );
    expect(liftedMenu.transform.entry(1, 3), lessThan(0));
    expect(liftedMenu.transform.entry(1, 3), greaterThan(-4.1));

    await tester.pump(const Duration(milliseconds: 41));
    await tester.pump(const Duration(milliseconds: 325));
    final flippingCover = find.descendant(
      of: find.byKey(const ValueKey('taste-of-spain-2026-menu-0')),
      matching: find.byKey(const ValueKey('taste-menu-cover-flip')),
    );
    final revealedInside = find.descendant(
      of: find.byKey(const ValueKey('taste-of-spain-2026-menu-0')),
      matching: find.byKey(const ValueKey('taste-menu-inside-reveal')),
    );
    final coverTransform = tester.widget<Transform>(flippingCover);
    final insideOpacity = tester.widget<Opacity>(revealedInside);
    expect(coverTransform.transform.entry(0, 0), lessThan(0.5));
    expect(insideOpacity.opacity, greaterThan(0.5));
    expect(
      tester
          .widget<Opacity>(
            find.descendant(
              of: find.byKey(const ValueKey('taste-of-spain-2026-menu-0')),
              matching: find.byKey(
                const ValueKey('taste-menu-cover-highlight'),
              ),
            ),
          )
          .opacity,
      greaterThan(0.15),
    );
    expect(
      tester
          .widget<Opacity>(
            find.descendant(
              of: find.byKey(const ValueKey('taste-of-spain-2026-menu-0')),
              matching: find.byKey(const ValueKey('taste-menu-hinge-shadow')),
            ),
          )
          .opacity,
      greaterThan(0.3),
    );
    expect(find.text('TASTES OF SPAIN 2026'), findsNothing);

    await tester.pump(const Duration(milliseconds: 326));
    await tester.pump(const Duration(milliseconds: 60));
    final settlingPage = tester.widget<Transform>(
      find.descendant(
        of: find.byKey(const ValueKey('taste-of-spain-2026-menu-0')),
        matching: find.byKey(const ValueKey('taste-menu-page-settle')),
      ),
    );
    expect(settlingPage.transform.entry(0, 0), greaterThan(1));
    await tester.pump(const Duration(milliseconds: 61));
    await tester.pump();
    final zoomingPage = find.byKey(const ValueKey('taste-page-zoom-overlay'));
    expect(zoomingPage, findsOneWidget);
    expect(tester.getRect(zoomingPage).width, closeTo(menuRect.width, 6));
    final attachedCover = find.byKey(
      const ValueKey('taste-attached-open-cover'),
    );
    expect(attachedCover, findsOneWidget);
    expect(
      find.byKey(const ValueKey('taste-attached-book-spine')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('taste-page-backdrop-blur')),
      findsOneWidget,
    );

    await tester.pump(const Duration(milliseconds: 91));
    await tester.pump(const Duration(milliseconds: 325));
    final openingPageRect = tester.getRect(zoomingPage);
    expect(openingPageRect.width, greaterThan(menuRect.width * 2));
    expect(openingPageRect.width, lessThan(viewportRect.width));
    expect(
      openingPageRect.width / openingPageRect.height,
      closeTo(menuRect.width / menuRect.height, 0.03),
    );
    final openingCoverRect = tester.getRect(attachedCover);
    expect(openingCoverRect.right, greaterThan(openingPageRect.left));
    expect(
      openingCoverRect.right,
      lessThan(openingPageRect.left + (openingPageRect.width * 0.08)),
    );

    await tester.pump(const Duration(milliseconds: 326));
    await tester.pump();
    expect(tester.getRect(zoomingPage).width, closeTo(viewportRect.width, 2));
    expect(
      tester.getRect(zoomingPage).height,
      greaterThan(viewportRect.height),
    );
    final settlingTexture = find.byKey(
      const ValueKey('taste-texture-settle-scale'),
    );
    final initialTextureScale = tester
        .widget<Transform>(settlingTexture)
        .transform
        .getMaxScaleOnAxis();
    expect(initialTextureScale, greaterThan(1.05));

    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 225));
    final midwayTextureScale = tester
        .widget<Transform>(settlingTexture)
        .transform
        .getMaxScaleOnAxis();
    expect(midwayTextureScale, greaterThan(1));
    expect(midwayTextureScale, lessThan(initialTextureScale));
    expect(zoomingPage, findsOneWidget);

    await tester.pump(const Duration(milliseconds: 226));
    await tester.pump();
    expect(zoomingPage, findsOneWidget);
    expect(
      tester.widget<Transform>(settlingTexture).transform.getMaxScaleOnAxis(),
      closeTo(1, 0.01),
    );
    await tester.pump(const Duration(milliseconds: 81));
    await tester.pump();
    expect(zoomingPage, findsNothing);
    await tester.pump(const Duration(milliseconds: 31));
    await tester.pump(const Duration(milliseconds: 260));
    final headerReveal = tester.widget<Opacity>(
      find
          .descendant(
            of: find.byKey(const ValueKey('taste-reveal-header')),
            matching: find.byType(Opacity),
          )
          .first,
    );
    final ledgerReveal = tester.widget<Opacity>(
      find
          .descendant(
            of: find.byKey(const ValueKey('taste-reveal-ledger')),
            matching: find.byType(Opacity),
          )
          .first,
    );
    expect(headerReveal.opacity, 1);
    expect(ledgerReveal.opacity, greaterThan(0));
    expect(ledgerReveal.opacity, lessThan(1));
    await tester.pump(const Duration(milliseconds: 261));
    final contentReveal = tester.widget<FadeTransition>(
      find.byKey(const ValueKey('taste-menu-content-reveal')),
    );
    expect(contentReveal.opacity.value, 1);

    expect(find.text('TASTES OF SPAIN 2026'), findsOneWidget);
    expect(find.byKey(const ValueKey('taste-ledger-list')), findsOneWidget);
    expect(find.byKey(const ValueKey('taste-image-EA-JP-001')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('taste-embossed-food-frame')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('taste-background-card-back')),
      findsNWidgets(2),
    );
    expect(
      find.byKey(const ValueKey('taste-background-card-middle')),
      findsNWidgets(2),
    );
    expect(
      find.byKey(const ValueKey('taste-select-a-memory-card')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('taste-ledger-item-3')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byKey(const ValueKey('taste-image-EA-JP-004')), findsOneWidget);
    expect(find.text('KYOTO STREET STALL'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('taste-back-to-gallery')));
    await tester.pump();

    await tester.pump(const Duration(milliseconds: 140));
    final clearingContent = tester.widget<FadeTransition>(
      find.byKey(const ValueKey('taste-menu-content-reveal')),
    );
    expect(clearingContent.opacity.value, greaterThan(0));
    expect(clearingContent.opacity.value, lessThan(1));

    await tester.pump(const Duration(milliseconds: 141));
    await tester.pump();
    await tester.pump();
    expect(find.text('TASTES OF SPAIN 2026'), findsNothing);
    expect(zoomingPage, findsOneWidget);
    final openDuringRouteReturn = tester.widget<Transform>(flippingCover);
    expect(openDuringRouteReturn.transform.entry(0, 0), lessThan(-0.9));
    expect(
      tester.widget<Transform>(settlingTexture).transform.getMaxScaleOnAxis(),
      closeTo(1, 0.01),
    );

    await tester.pump(const Duration(milliseconds: 225));
    final enlargingTextureScale = tester
        .widget<Transform>(settlingTexture)
        .transform
        .getMaxScaleOnAxis();
    expect(enlargingTextureScale, greaterThan(1));
    expect(enlargingTextureScale, lessThan(initialTextureScale));
    expect(tester.getRect(zoomingPage).width, closeTo(viewportRect.width, 2));

    await tester.pump(const Duration(milliseconds: 226));
    await tester.pump();

    await tester.pump(const Duration(milliseconds: 270));
    final closingPageRect = tester.getRect(zoomingPage);
    expect(closingPageRect.width, greaterThan(menuRect.width * 2));
    expect(closingPageRect.width, lessThan(viewportRect.width));
    expect(
      closingPageRect.width / closingPageRect.height,
      closeTo(menuRect.width / menuRect.height, 0.03),
    );
    expect(attachedCover, findsOneWidget);

    await tester.pump(const Duration(milliseconds: 271));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 240));
    final closingCover = tester.widget<Transform>(flippingCover);
    final closingInside = tester.widget<Opacity>(revealedInside);
    expect(closingCover.transform.entry(0, 0), greaterThan(0));
    expect(closingCover.transform.entry(0, 0), lessThan(0.5));
    expect(closingInside.opacity, greaterThan(0.5));

    await tester.pump(const Duration(milliseconds: 241));
    expect(find.byKey(const ValueKey('trip-memory-gallery')), findsOneWidget);
    expect(zoomingPage, findsNothing);
    final closedCover = tester.widget<Transform>(flippingCover);
    final closedInside = tester.widget<Opacity>(revealedInside);
    expect(closedCover.transform.entry(0, 0), closeTo(1, 0.01));
    expect(closedInside.opacity, 0);

    await tester.pump(const Duration(milliseconds: 65));
    final landingMenu = tester.widget<Transform>(
      find.descendant(
        of: find.byKey(const ValueKey('taste-of-spain-2026-menu-0')),
        matching: find.byKey(const ValueKey('taste-menu-lift')),
      ),
    );
    expect(landingMenu.transform.entry(1, 3), lessThan(0));
    await tester.pump(const Duration(milliseconds: 66));
    final landedMenu = tester.widget<Transform>(
      find.descendant(
        of: find.byKey(const ValueKey('taste-of-spain-2026-menu-0')),
        matching: find.byKey(const ValueKey('taste-menu-lift')),
      ),
    );
    expect(landedMenu.transform.entry(1, 3), closeTo(0, 0.01));
  });

  galleryTest('every trip gallery includes its destination menu', (
    tester,
  ) async {
    for (final trip in tripGalleryItems) {
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 1280,
            height: 800,
            child: TripJourney(trip: trip, onTasteTap: () async {}),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(ValueKey('taste-of-${trip.slug}-menu-0')),
        findsOneWidget,
        reason: '${trip.name} should include a menu in its gallery wall',
      );
      expect(
        find.text('TASTE OF\n${trip.name.toUpperCase()}'),
        findsNWidgets(2),
      );
    }
  });

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
            child: TripJourney(trip: trip, onTasteTap: () async {}),
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
            onTasteTap: () async {},
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
              onTasteTap: () async {},
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

  galleryTest('trip gallery interleaves tappable Instagram post frames', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 1280,
          height: 800,
          child: TripJourney(
            trip: tripGalleryItems.first,
            onTasteTap: () async {},
          ),
        ),
      ),
    );
    await tester.pump();

    final wallpaper = find.byKey(const ValueKey('gallery-repeating-wallpaper'));
    expect(wallpaper, findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('gallery-drift-transform')),
        matching: wallpaper,
      ),
      findsOneWidget,
    );
    final wallpaperImage = tester.widget<Image>(wallpaper);
    expect(wallpaperImage.fit, BoxFit.none);
    expect(wallpaperImage.repeat, ImageRepeat.repeat);
    expect(wallpaperImage.alignment, Alignment.topLeft);
    final vignette = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('gallery-wallpaper-bottom-vignette')),
    );
    final vignetteDecoration = vignette.decoration as BoxDecoration;
    final vignetteGradient = vignetteDecoration.gradient! as LinearGradient;
    expect(vignetteGradient.begin, Alignment.topCenter);
    expect(vignetteGradient.end, Alignment.bottomCenter);
    expect(vignetteGradient.colors.last, const Color(0x8F090100));
    final wallpaperProvider = wallpaperImage.image as ExactAssetImage;
    expect(
      wallpaperProvider.assetName,
      'assets/textures/red_damask_gallery_wall.jpeg',
    );
    expect(wallpaperProvider.scale, closeTo(675 / 575, 0.0001));
    expect(
      find.byKey(const ValueKey('gallery-instagram-post-frame')),
      findsNWidgets(14),
    );
    expect(
      tester.getSize(
        find.byKey(
          ValueKey<String>(
            'gallery-video-post-spain-2026-${galleryVideoPostsFor('spain-2026').first.shortcode}-0',
          ),
        ),
      ),
      const Size(408, 600),
    );
    expect(find.text('iihsavru'), findsNothing);
    expect(find.textContaining('REEL '), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('gallery-instagram-post-frame')),
        matching: find.byType(Icon),
      ),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('gallery-instagram-oval-baroque-frame')),
      findsNWidgets(2),
    );
    expect(
      find.byKey(const ValueKey('gallery-instagram-circular-baroque-frame')),
      findsNWidgets(4),
    );
    expect(
      find.byKey(const ValueKey('gallery-instagram-portrait-baroque-frame')),
      findsNWidgets(4),
    );
    expect(
      find.byKey(
        const ValueKey('gallery-instagram-horizontalOval-baroque-frame'),
      ),
      findsNWidgets(4),
    );
    expect(
      find.byKey(const ValueKey('gallery-horizontalOval-baroque-frame')),
      findsNWidgets(4),
    );
    final circularFrames = find.byKey(
      const ValueKey('gallery-circular-baroque-frame'),
    );
    expect(circularFrames, findsNWidgets(4));
    expect(
      tester.getSize(circularFrames.first).width,
      greaterThanOrEqualTo(500),
      reason: 'Circular frames should match the visual scale of nearby frames',
    );
    expect(
      find.byKey(const ValueKey('gallery-circular-media-mask')),
      findsNWidgets(4),
    );
    final horizontalOvalMemoryMasks = find.byKey(
      const ValueKey('gallery-horizontalOval-media-mask'),
    );
    final horizontalOvalInstagramMasks = find.byKey(
      const ValueKey('gallery-instagram-horizontalOval-media-mask'),
    );
    expect(horizontalOvalMemoryMasks, findsNWidgets(4));
    expect(horizontalOvalInstagramMasks, findsNWidgets(4));
    expect(
      tester.widget<ClipOval>(horizontalOvalMemoryMasks.first).child,
      isA<ColoredBox>(),
    );
    expect(
      tester.widget<ClipOval>(horizontalOvalInstagramMasks.first).child,
      isA<ColoredBox>(),
    );
    final postFrames = find.byKey(
      const ValueKey('gallery-instagram-post-frame'),
    );
    expect(postFrames, findsNWidgets(14));
    final coverPaths = galleryVideoPostsFor(
      'spain-2026',
    ).map((post) => post.coverAssetPath).toSet();
    for (final frame in postFrames.evaluate()) {
      expect(
        find.descendant(
          of: find.byWidget(frame.widget),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Image &&
                widget.image is AssetImage &&
                coverPaths.contains((widget.image as AssetImage).assetName),
          ),
        ),
        findsOneWidget,
      );
    }

    final visiblePosts = find
        .byKey(const ValueKey('gallery-instagram-post-frame'))
        .hitTestable();
    expect(visiblePosts, findsWidgets);
    await tester.tap(visiblePosts.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1250));

    expect(
      find.byKey(const ValueKey('focused-instagram-post')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('focused-instagram-post')),
        matching: find.byType(Icon),
      ),
      findsNothing,
    );
    final focusedReelSize = tester.getSize(
      find.byKey(const ValueKey('focused-instagram-reel-viewport')),
    );
    expect(focusedReelSize.aspectRatio, closeTo(9 / 16, 0.001));

    tester
        .widget<GestureDetector>(
          find.byKey(const ValueKey('focused-memory-backdrop')),
        )
        .onTap!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 710));
    await tester.pump();

    final japanWallItems = <Finder>[
      for (var copyIndex = 0; copyIndex < 2; copyIndex++) ...<Finder>[
        for (var memoryIndex = 0; memoryIndex < 12; memoryIndex++)
          find.byKey(
            ValueKey<String>(
              'gallery-memory-layout-spain-2026-$memoryIndex-$copyIndex',
            ),
          ),
        for (final post in galleryVideoPostsFor('spain-2026'))
          find.byKey(
            ValueKey<String>(
              'gallery-video-post-spain-2026-${post.shortcode}-$copyIndex',
            ),
          ),
        find.byKey(ValueKey<String>('taste-of-spain-2026-menu-$copyIndex')),
        find.byKey(
          ValueKey<String>('gallery-editorial-title-spain-2026-$copyIndex'),
        ),
      ],
    ];
    for (final finder in japanWallItems) {
      expect(finder, findsOneWidget, reason: finder.toString());
    }
    final japanWallBounds = <({String label, Rect rect})>[
      for (final finder in japanWallItems)
        (
          label: finder.toString(),
          rect: MatrixUtils.transformRect(
            tester.renderObject<RenderBox>(finder).getTransformTo(null),
            Offset.zero & tester.getSize(finder),
          ),
        ),
    ];

    Rect globalRect(Finder finder) => MatrixUtils.transformRect(
      tester.renderObject<RenderBox>(finder).getTransformTo(null),
      Offset.zero & tester.getSize(finder),
    );

    final firstCopyFrames = <Rect>[
      for (var memoryIndex = 0; memoryIndex < 12; memoryIndex++)
        globalRect(
          find.byKey(
            ValueKey<String>('gallery-memory-layout-spain-2026-$memoryIndex-0'),
          ),
        ),
    ];
    final firstCopyPosts = <Rect>[
      for (final post in galleryVideoPostsFor('spain-2026'))
        globalRect(
          find.byKey(
            ValueKey<String>(
              'gallery-video-post-spain-2026-${post.shortcode}-0',
            ),
          ),
        ),
    ];
    final titleRect = globalRect(
      find.byKey(const ValueKey('gallery-editorial-title-spain-2026-0')),
    );
    final menuRect = globalRect(
      find.byKey(const ValueKey('taste-of-spain-2026-menu-0')),
    );
    final rowItems = <Rect>[
      ...firstCopyFrames,
      ...firstCopyPosts,
      menuRect,
      titleRect,
    ];
    final rowCenters = rowItems.map((rect) => rect.center.dy).toList();
    expect(
      rowCenters.reduce(math.max) - rowCenters.reduce(math.min),
      lessThan(1),
      reason: 'Every frame, social post, menu, and title should share one row',
    );
    expect(firstCopyPosts.first.width, greaterThan(175));
    expect(firstCopyPosts.first.height, greaterThan(260));
    expect(menuRect.width, greaterThan(240));
    expect(menuRect.height, greaterThan(160));

    final frameAreaBands = firstCopyFrames
        .map((rect) => (rect.width * rect.height / 2000).round())
        .toSet();
    expect(
      frameAreaBands.length,
      greaterThanOrEqualTo(8),
      reason: 'The gallery wall should use subtly varied frame scales',
    );
    final firstCopyWallRects = <Rect>[
      ...firstCopyFrames,
      ...firstCopyPosts,
      menuRect,
      titleRect,
    ]..sort((a, b) => a.left.compareTo(b.left));
    var coverageFrontier = firstCopyWallRects.first.right;
    var largestHorizontalGap = 0.0;
    for (final rect in firstCopyWallRects.skip(1)) {
      largestHorizontalGap = math.max(
        largestHorizontalGap,
        rect.left - coverageFrontier,
      );
      coverageFrontier = math.max(coverageFrontier, rect.right);
    }
    expect(
      largestHorizontalGap,
      lessThan(64),
      reason: 'The salon wall should not leave broad empty vertical patches',
    );
    expect(
      coverageFrontier - firstCopyWallRects.first.left,
      greaterThan(6100),
      reason: 'The wall composition should stay balanced across the strip',
    );

    for (var first = 0; first < japanWallBounds.length; first++) {
      for (var second = first + 1; second < japanWallBounds.length; second++) {
        final overlap = japanWallBounds[first].rect.intersect(
          japanWallBounds[second].rect,
        );
        expect(
          overlap.width <= 0 || overlap.height <= 0,
          isTrue,
          reason:
              '${japanWallBounds[first].label} overlaps '
              '${japanWallBounds[second].label} by $overlap',
        );
      }
    }

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  galleryTest('an uncurated trip menu opens destination-specific content', (
    tester,
  ) async {
    final southKorea = tripGalleryItems.firstWhere(
      (trip) => trip.slug == 'philippines-2025',
    );
    await tester.pumpWidget(
      MaterialApp(home: TripTasteMenuScreen(trip: southKorea)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 111));
    await tester.pump(const Duration(milliseconds: 521));

    expect(find.text('TASTES OF PHILIPPINES 2025'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('taste-empty-philippines-2025')),
      findsOneWidget,
    );
    expect(find.text('MENU COLLECTION IN PROGRESS'), findsOneWidget);
  });
}
