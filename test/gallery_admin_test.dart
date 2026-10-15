import 'gallery_fixtures.dart';
import 'dart:math' as math;

import 'package:everafter/data/gallery_layout.dart';
import 'package:everafter/data/gallery_memory_content.dart';
import 'package:everafter/screens/gallery_admin_screen.dart';
import 'package:everafter/widgets/gallery_trinket_image.dart';
import 'package:everafter/data/trip_catalog.dart';
import 'package:everafter/widgets/trip_journey.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(installGalleryFixtures);
  galleryTest('selected frames and trinkets resize from a drag handle', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store = GalleryLayoutStore.instance;
    addTearDown(() => store.resetTrip('spain-2026'));
    final trinket = store.addTrinket(
      'spain-2026',
      assetName: galleryTrinketAssetChoices.first,
      label: 'Resize test trinket',
    );
    store.updateTrinket(
      'spain-2026',
      trinket.copyWith(left: 760, top: 40, width: 180, height: 120),
    );

    await tester.pumpWidget(const MaterialApp(home: GalleryAdminScreen()));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('admin-frame-frame-0')));
    await tester.pump();
    final frameBefore = store.layoutFor('spain-2026').frames.first;
    final frameAspectRatio = frameBefore.width / frameBefore.height;
    await tester.drag(
      find.byKey(const ValueKey('admin-frame-resize-frame-0')),
      const Offset(24, 24),
    );
    await tester.pump();
    final frameAfter = store.layoutFor('spain-2026').frames.first;
    expect(frameAfter.width, greaterThan(frameBefore.width));
    expect(frameAfter.height, greaterThan(frameBefore.height));
    expect(
      frameAfter.width / frameAfter.height,
      closeTo(frameAspectRatio, 0.001),
    );

    await tester.tap(
      find.byKey(
        const ValueKey('admin-item-selector-spain-2026-frame:frame-0'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Resize test trinket').last);
    await tester.pumpAndSettle();
    final trinketBefore = store
        .layoutFor('spain-2026')
        .trinkets
        .firstWhere((item) => item.id == trinket.id);
    final trinketAspectRatio = trinketBefore.width / trinketBefore.height;
    await tester.drag(
      find.byKey(ValueKey('admin-trinket-resize-${trinket.id}')),
      const Offset(24, 24),
    );
    await tester.pump();
    final trinketAfter = store
        .layoutFor('spain-2026')
        .trinkets
        .firstWhere((item) => item.id == trinket.id);
    expect(trinketAfter.width, greaterThan(trinketBefore.width));
    expect(trinketAfter.height, greaterThan(trinketBefore.height));
    expect(
      trinketAfter.width / trinketAfter.height,
      closeTo(trinketAspectRatio, 0.001),
    );
  });

  galleryTest('admin shows editable frames and tracks local changes', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    addTearDown(() => GalleryLayoutStore.instance.resetTrip('spain-2026'));
    await tester.pumpWidget(const MaterialApp(home: GalleryAdminScreen()));
    await tester.pump();

    expect(find.byKey(const ValueKey('gallery-admin-screen')), findsOneWidget);
    expect(find.byKey(const ValueKey('admin-frame-frame-0')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('admin-gallery-editorial-title')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('admin-instagram-instagram-0')),
      findsOneWidget,
    );
    expect(find.text('MEMORIES OF'), findsOneWidget);
    expect(find.text('SPAIN 2026'), findsOneWidget);
    expect(find.text('IN MOTION'), findsOneWidget);
    expect(find.textContaining('Drag an item to move it.'), findsOneWidget);
    expect(find.byKey(const ValueKey('admin-fit-gallery')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('admin-gallery-canvas'))).height,
      closeTo(112, 0.01),
    );
    await tester.tap(find.byKey(const ValueKey('admin-zoom-in')));
    await tester.pump();
    expect(find.text('17%'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('admin-gallery-canvas'))).height,
      closeTo(136, 0.01),
    );
    await tester.tap(find.byKey(const ValueKey('admin-zoom-reset')));
    await tester.pump();
    expect(find.text('14%'), findsOneWidget);

    final instagramLeftBefore = GalleryLayoutStore.instance
        .layoutFor('spain-2026')
        .instagramPosts
        .first
        .left;
    await tester.tap(
      find.byKey(const ValueKey('admin-item-selector-spain-2026-null')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Video 1').last);
    await tester.pumpAndSettle();
    expect(find.text('SPAIN 2026 VIDEO'), findsOneWidget);
    expect(find.text('Video 1'), findsWidgets);
    await tester.drag(
      find.byKey(const ValueKey('admin-instagram-instagram-0')),
      const Offset(14, 0),
    );
    await tester.pump();
    expect(
      GalleryLayoutStore.instance
          .layoutFor('spain-2026')
          .instagramPosts
          .first
          .left,
      greaterThan(instagramLeftBefore),
    );


    await tester.tap(find.byKey(const ValueKey('admin-frame-frame-0')));
    await tester.pump();
    expect(find.text('Frame 1'), findsWidgets);
    expect(
      find.byKey(const ValueKey('admin-lock-aspect-ratio')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('admin-frame-style-frame-0-oval')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Horizontal oval').last);
    await tester.pumpAndSettle();
    final horizontalFrame = GalleryLayoutStore.instance
        .layoutFor('spain-2026')
        .frames
        .first;
    expect(horizontalFrame.style, GalleryFrameStyle.horizontalOval);
    expect(horizontalFrame.width, greaterThan(horizontalFrame.height));
    expect(
      find.byKey(const ValueKey('admin-horizontal-oval-frame')),
      findsWidgets,
    );
    expect(
      find.byKey(const ValueKey('admin-frame-title-field')),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const ValueKey('admin-frame-title-field')),
      'Tokyo nights',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(
      GalleryLayoutStore.instance.layoutFor('spain-2026').frames.first.title,
      'Tokyo nights',
    );

    final frameBeforePhotoEdit = GalleryLayoutStore.instance
        .layoutFor('spain-2026')
        .frames
        .first;
    final japanTrip = tripGalleryItems.firstWhere(
      (trip) => trip.slug == 'spain-2026',
    );
    final allPhotoChoices = galleryPhotoChoicesFor(japanTrip);
    final appliedPhotoPaths = defaultGalleryMediaFor(
      japanTrip,
      frameBeforePhotoEdit.memoryIndex,
      portrait: frameBeforePhotoEdit.portrait,
    ).where((media) => !media.isVideo).map((media) => media.assetPath).toList();
    final unappliedPhotoIndex = allPhotoChoices.indexWhere(
      (assetPath) => !appliedPhotoPaths.contains(assetPath),
    );
    final appliedPhotoIndex = allPhotoChoices.indexOf(appliedPhotoPaths.first);

    await tester.tap(
      find.byKey(const ValueKey('admin-edit-frame-photos-frame-0')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('admin-photo-picker')), findsOneWidget);
    final repositionColumn = tester.getRect(
      find.byKey(const ValueKey('admin-photo-reposition-column')),
    );
    final galleryColumn = tester.getRect(
      find.byKey(const ValueKey('admin-photo-gallery-column')),
    );
    expect(repositionColumn.right, lessThan(galleryColumn.left));
    expect(
      find.byKey(ValueKey('admin-photo-choice-$unappliedPhotoIndex')),
      findsNothing,
    );
    expect(find.text('Choose photo'), findsOneWidget);
    final dialogTheme = Theme.of(
      tester.element(find.byKey(const ValueKey('admin-add-frame-photos'))),
    );
    final defaultButtonText = dialogTheme
        .textButtonTheme
        .style!
        .foregroundColor!
        .resolve(<WidgetState>{})!;
    expect(
      _contrastRatio(defaultButtonText, const Color(0xFF251915)),
      greaterThan(4.5),
    );
    expect(
      find.byKey(const ValueKey('admin-photo-crop-preview')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('admin-photo-frame-outline-horizontalOval')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('admin-add-frame-photos')));
    await tester.pump();
    expect(find.byKey(const ValueKey('admin-photo-library')), findsOneWidget);
    await tester.tap(
      find.byKey(ValueKey('admin-remove-photo-$appliedPhotoIndex')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(ValueKey('admin-photo-choice-$appliedPhotoIndex')),
    );
    await tester.pump();
    await tester.drag(
      find.byKey(const ValueKey('admin-photo-crop-preview')),
      const Offset(20, -10),
    );
    await tester.drag(
      find.byKey(const ValueKey('admin-photo-zoom-slider')),
      const Offset(45, 0),
    );
    await tester.tap(find.text('Apply photo'));
    await tester.pumpAndSettle();
    final editedPhotos = GalleryLayoutStore.instance
        .layoutFor('spain-2026')
        .frames
        .first
        .effectivePhotoEdits;
    expect(editedPhotos, isNotEmpty);
    expect(
      editedPhotos.any(
        (edit) =>
            edit.zoom > 1 ||
            edit.alignmentX != horizontalFrame.alignmentX ||
            edit.alignmentY != horizontalFrame.alignmentY,
      ),
      isTrue,
    );

    final before = GalleryLayoutStore.instance
        .layoutFor('spain-2026')
        .frames
        .first
        .left;
    await tester.drag(
      find.byKey(const ValueKey('admin-frame-frame-0')),
      const Offset(14, 0),
    );
    await tester.pump();
    expect(
      GalleryLayoutStore.instance.layoutFor('spain-2026').frames.first.left,
      greaterThan(before),
    );
    expect(find.byKey(const ValueKey('admin-save-layout')), findsOneWidget);
  });

  galleryTest('gallery uses a frame title and selected photo override', (
    tester,
  ) async {
    final store = GalleryLayoutStore.instance;
    addTearDown(() => store.resetTrip('spain-2026'));
    final trip = tripGalleryItems.first;
    final frame = store.layoutFor('spain-2026').frames.first;
    final photoPath = galleryPhotoChoicesFor(trip).last;
    store.updateFrame(
      'spain-2026',
      frame.copyWith(
        title: 'Tokyo nights',
        photoAssetPaths: <String>[photoPath],
        photoEdits: <GalleryPhotoEdit>[
          GalleryPhotoEdit(
            assetPath: photoPath,
            alignmentX: 0.7,
            alignmentY: -0.4,
            zoom: 1.6,
          ),
        ],
      ),
    );
    store.updateTravelDates(
      'spain-2026',
      start: DateTime(2025, 1, 2),
      end: DateTime(2025, 1, 5),
    );

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

    expect(find.text('TOKYO NIGHTS'), findsNWidgets(2));
    expect(find.text('JAN 02, 2025  →  JAN 05, 2025'), findsNWidgets(2));
    expect(
      find.descendant(
        of: find.byWidgetPredicate(
          (widget) =>
              widget.key is ValueKey<String> &&
              (widget.key! as ValueKey<String>).value.startsWith(
                'gallery-memory-layout-spain-2026-0-',
              ),
        ),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName == photoPath,
        ),
      ),
      findsNWidgets(2),
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName == photoPath &&
            widget.alignment == const Alignment(0.7, -0.4),
      ),
      findsNWidgets(2),
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Transform &&
            (widget.transform.getMaxScaleOnAxis() - 1.6).abs() < 0.001,
      ),
      findsNWidgets(2),
    );
  });

  galleryTest('admin edits the trip travel dates', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store = GalleryLayoutStore.instance;
    addTearDown(() => store.resetTrip('spain-2026'));

    await tester.pumpWidget(const MaterialApp(home: GalleryAdminScreen()));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('admin-travel-dates')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('admin-travel-dates-dialog')),
      findsOneWidget,
    );
    expect(find.text('Choose date'), findsNWidgets(2));
    expect(find.byKey(const ValueKey('admin-travel-duration')), findsNothing);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    store.updateTravelDates(
      'spain-2026',
      start: DateTime(2025, 1, 2),
      end: DateTime(2025, 1, 5),
    );
    await tester.pump();

    final layout = store.layoutFor('spain-2026');
    expect(
      layout.effectiveDateRangeLabel('fallback'),
      'JAN 02, 2025  →  JAN 05, 2025',
    );
    expect(layout.effectiveDurationLabel(12), '4 DAYS');
    expect(find.text('JAN 02, 2025  →  JAN 05, 2025'), findsOneWidget);
  });

  galleryTest('admin replaces the selected photo and adds bundled trinkets', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store = GalleryLayoutStore.instance;
    addTearDown(() => store.resetTrip('spain-2026'));
    final initialLayout = store.layoutFor('spain-2026');

    await tester.pumpWidget(const MaterialApp(home: GalleryAdminScreen()));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('admin-add-item')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Frame with photo'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('admin-photo-picker')), findsOneWidget);
    expect(find.textContaining('0 selected'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('admin-photo-choice-0')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('admin-photo-choice-1')));
    await tester.pump();
    await tester.tap(find.text('Apply photo'));
    await tester.pumpAndSettle();

    final layoutWithFrame = store.layoutFor('spain-2026');
    expect(layoutWithFrame.frames, hasLength(initialLayout.frames.length + 1));
    expect(layoutWithFrame.frames.last.isCustom, isTrue);
    expect(layoutWithFrame.frames.last.effectivePhotoEdits, hasLength(1));
    expect(
      find.byKey(ValueKey('admin-frame-${layoutWithFrame.frames.last.id}')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('admin-add-item')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Trinket'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('admin-trinket-picker')), findsOneWidget);
    expect(find.byKey(const ValueKey('admin-upload-trinket')), findsNothing);
    expect(
      find.byKey(const ValueKey('admin-trinket-source-guidance')),
      findsOneWidget,
    );
    expect(find.textContaining('assets/images/experience/'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('admin-trinket-choice-0')));
    await tester.pumpAndSettle();

    final layoutWithTrinket = store.layoutFor('spain-2026');
    expect(
      layoutWithTrinket.trinkets,
      hasLength(initialLayout.trinkets.length + 1),
    );
    expect(layoutWithTrinket.trinkets.last.isCustom, isTrue);
    expect(
      find.byKey(
        ValueKey('admin-trinket-${layoutWithTrinket.trinkets.last.id}'),
      ),
      findsOneWidget,
    );
  });

  test('fit gallery trims unused space from both strip ends', () {
    final store = GalleryLayoutStore.instance;
    addTearDown(() => store.resetTrip('china'));
    final layout = store.layoutFor('china');
    store.updateFrame('china', layout.frames.first.copyWith(visible: false));
    for (final frame in layout.frames.skip(8)) {
      store.updateFrame('china', frame.copyWith(visible: false));
    }

    store.fitTripToContents('china');

    final fitted = store.layoutFor('china');
    expect(fitted.leadingTrim, greaterThan(0));
    expect(fitted.stripWidth, lessThan(layout.stripWidth));
  });

  test('saved horizontal ovals repair orientation and artwork ratio', () {
    final frame = GalleryFramePlacement.fromJson(<String, dynamic>{
      'id': 'frame-0',
      'memoryIndex': 0,
      'left': 100,
      'top': 100,
      'width': 180,
      'height': 260,
      'style': 'horizontalOval',
      'alignmentX': 0,
      'alignmentY': 0,
    });

    expect(frame.style, GalleryFrameStyle.horizontalOval);
    expect(frame.width / frame.height, closeTo(25 / 17, 0.001));
    expect(frame.width, 260);
    expect(frame.top + frame.height / 2, closeTo(190, 0.001));
  });

  test('default horizontal ovals match the generated artwork ratio', () {
    final horizontalFrames = defaultGalleryLayoutFor(
      'spain-2026',
    ).frames.where((frame) => frame.style == GalleryFrameStyle.horizontalOval);

    expect(horizontalFrames, isNotEmpty);
    expect(
      horizontalFrames,
      everyElement(
        predicate<GalleryFramePlacement>(
          (frame) =>
              (frame.width / frame.height - horizontalOvalFrameAspectRatio)
                  .abs() <
              0.001,
        ),
      ),
    );
  });

  test('default circular frames are square and use the circular artwork', () {
    final circularFrames = defaultGalleryLayoutFor(
      'spain-2026',
    ).frames.where((frame) => frame.style == GalleryFrameStyle.circular);

    expect(circularFrames, isNotEmpty);
    expect(
      circularFrames,
      everyElement(
        predicate<GalleryFramePlacement>(
          (frame) =>
              (frame.width / frame.height - circularFrameAspectRatio).abs() <
                  0.001 &&
              frame.width == featuredCircularFrameSize,
        ),
      ),
    );
  });

  test('locked frame resizing preserves its current aspect ratio', () {
    final frame = defaultGalleryLayoutFor('spain-2026').frames.first;
    final resized = frame.resized(width: 380);

    expect(frame.lockAspectRatio, isTrue);
    expect(resized.width, 380);
    expect(resized.height, closeTo(544, 0.001));

    final unlocked = frame.copyWith(lockAspectRatio: false).resized(width: 380);
    expect(unlocked.width, 380);
    expect(unlocked.height, frame.height);
  });

  test('legacy saved video layouts migrate without losing placement edits', () {
    final json = <String, dynamic>{
      'frames': <Map<String, Object?>>[
        GalleryFramePlacement(
          id: 'frame-1',
          memoryIndex: 1,
          left: 1193,
          top: 278,
          width: 178,
          height: 254,
          style: GalleryFrameStyle.portrait,
          alignmentX: 0,
          alignmentY: 0,
        ).toJson(),
      ],
      'trinkets': <Map<String, Object>>[],
      'stripWidth': 9180,
      'instagramPosts': <Map<String, Object>>[
        for (final (index, left, style) in <(int, double, GalleryFrameStyle)>[
          (0, 470, GalleryFrameStyle.oval),
          (1, 1545, GalleryFrameStyle.portrait),
          (2, 2255, GalleryFrameStyle.horizontalOval),
          (3, 3335, GalleryFrameStyle.circular),
          (4, 4455, GalleryFrameStyle.portrait),
          (5, 5970, GalleryFrameStyle.horizontalOval),
          (6, 7295, GalleryFrameStyle.circular),
        ])
          GalleryInstagramPlacement(
            id: 'instagram-$index',
            postIndex: index,
            left: left,
            top:
                style == GalleryFrameStyle.oval ||
                    style == GalleryFrameStyle.portrait
                ? 205
                : 269,
            width: style == GalleryFrameStyle.horizontalOval ? 400 : 272,
            height:
                style == GalleryFrameStyle.oval ||
                    style == GalleryFrameStyle.portrait
                ? 400
                : 272,
            style: style,
            angle: 0,
          ).toJson(),
      ],
    };

    final migrated = GalleryTripLayout.fromJson(
      json,
      tripSlug: 'spain-2026',
      fallbackStripWidth: defaultGalleryStripWidthFor('spain-2026'),
    );

    expect(migrated.instagramPosts, hasLength(7));
    expect(migrated.instagramPosts.first.id, 'instagram-0');
    expect(migrated.instagramPosts.first.scale, 1.5);
    expect(migrated.instagramPosts.first.left, 538);
    expect(migrated.frames.first.left, 1329);
    expect(migrated.stripWidth, 10260);
    expect(migrated.layoutVersion, 4);
    expect(
      migrated.instagramPosts
          .firstWhere((post) => post.id == 'instagram-3')
          .style,
      GalleryFrameStyle.circular,
    );
    expect(migrated.travelStartDate, isNull);
    expect(migrated.travelEndDate, isNull);
  });

  test('social media frames are level in defaults and saved layouts', () {
    expect(
      defaultGalleryLayoutFor(
        'spain-2026',
      ).instagramPosts.map((post) => post.angle),
      everyElement(0),
    );

    final restored = GalleryInstagramPlacement.fromJson(<String, dynamic>{
      'id': 'instagram-0',
      'postIndex': 0,
      'left': 470,
      'top': 205,
      'width': 272,
      'height': 400,
      'style': 'oval',
      'angle': -0.035,
    });

    expect(restored.angle, 0);
  });

  test('travel date overrides survive saved layout serialization', () {
    final datedLayout = defaultGalleryLayoutFor(
      'spain-2026',
    ).copyWith(travelStartDate: '2025-01-02', travelEndDate: '2025-01-05');

    final restored = GalleryTripLayout.fromJson(
      datedLayout.toJson(),
      tripSlug: 'spain-2026',
      fallbackStripWidth: defaultGalleryStripWidthFor('spain-2026'),
    );

    expect(restored.travelStartDate, '2025-01-02');
    expect(restored.travelEndDate, '2025-01-05');
    expect(restored.effectiveDurationLabel(12), '4 DAYS');
  });

  galleryTest('previously embedded trinket data remains readable', (
    tester,
  ) async {
    const onePixelPng =
        'data:image/png;base64,'
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJ'
        'AAAADUlEQVR42mNk+M/wHwAF/gL+XKzLAAAAAElFTkSuQmCC';

    await tester.pumpWidget(
      const MaterialApp(home: GalleryTrinketImage(source: onePixelPng)),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<MemoryImage>());
  });
}

double _contrastRatio(Color foreground, Color background) {
  final lighter = math.max(
    foreground.computeLuminance(),
    background.computeLuminance(),
  );
  final darker = math.min(
    foreground.computeLuminance(),
    background.computeLuminance(),
  );
  return (lighter + 0.05) / (darker + 0.05);
}
