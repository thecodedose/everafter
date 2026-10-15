import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:everafter/data/gallery_layout.dart';
import 'package:everafter/data/gallery_memory_content.dart';
import 'package:everafter/theme/everafter_theme.dart';
import 'package:everafter/widgets/gallery_trinket_image.dart';
import 'package:everafter/widgets/memory_video_surface_stub.dart'
    if (dart.library.js_interop) 'package:everafter/widgets/memory_video_surface_web.dart';
import 'package:everafter/widgets/museum_widgets.dart';
import 'package:everafter/data/trip_catalog.dart';
import 'package:everafter/models/gallery_media.dart';
import 'package:flutter/material.dart';

const double _spotlightStartProgress = 0.58;
const double _instagramReelAspectRatio = 9 / 16;

double _galleryEditorialTitleLeft(TripGalleryItem trip) =>
    galleryEditorialTitleLeft;

bool galleryAutoplaysVideosFor(TripGalleryItem _) => false;

bool memoryMediaUsesColorTreatment({
  required bool isVideo,
  required bool isPlaying,
}) => !(isVideo && isPlaying);

class TripJourney extends StatefulWidget {
  const TripJourney({required this.trip, required this.onTasteTap, super.key});

  final TripGalleryItem trip;
  final Future<void> Function() onTasteTap;

  @override
  State<TripJourney> createState() => TripJourneyState();
}

class TripJourneyState extends State<TripJourney>
    with TickerProviderStateMixin {
  static const _focusCurve = Cubic(0.65, 0, 0.35, 1);
  static const Duration _slideshowInterval = Duration(seconds: 1);
  static const _spotlightAsset =
      'assets/images/experience/museum-spotlight-overlay.png';

  final GlobalKey _journeySurfaceKey = GlobalKey();
  late final AnimationController _galleryDriftController;
  late final AnimationController _focusController;
  final TransformationController _focusedMediaTransformationController =
      TransformationController();
  Timer? _slideshowTimer;
  int _slideshowTick = 0;
  _FocusedMemory? _focusedMemory;
  int? _focusedMediaIndex;
  int _focusedLastAdvanceTick = 0;
  Rect? _focusedMemorySourceRect;
  bool _isDismissingMemory = false;
  bool _isGalleryDragging = false;
  double _galleryDragOffset = 0;
  bool _didPrecacheSpotlight = false;
  double _wallScale = 1;
  bool _videoMuted = true;

  @override
  void initState() {
    super.initState();
    _galleryDriftController = AnimationController(
      vsync: this,
      duration: _BaroqueGalleryWall.driftDurationFor(widget.trip),
      value: 0,
    )..repeat();
    _focusController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1250),
      reverseDuration: const Duration(milliseconds: 700),
    );
    _startSlideshowTimer();
  }

  @override
  void didUpdateWidget(covariant TripJourney oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trip.slug == widget.trip.slug) {
      return;
    }
    _galleryDriftController
      ..duration = _BaroqueGalleryWall.driftDurationFor(widget.trip)
      ..value = 0;
    if (_focusedMemory == null && !_isGalleryDragging) {
      _galleryDriftController.repeat();
    }
  }

  void _startSlideshowTimer() {
    _slideshowTimer?.cancel();
    _slideshowTimer = Timer.periodic(_slideshowInterval, (_) {
      if (mounted) {
        setState(() {
          _slideshowTick += 1;
          final memory = _focusedMemory;
          if (memory != null &&
              _slideshowTick - _focusedLastAdvanceTick >=
                  memory.slideshowPeriod) {
            _resetFocusedMediaZoom();
            _focusedMediaIndex =
                ((_focusedMediaIndex ?? 0) + 1) % memory.media.length;
            _focusedLastAdvanceTick = _slideshowTick;
          }
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPrecacheSpotlight) {
      return;
    }
    _didPrecacheSpotlight = true;
    for (final asset in <String>[
      _spotlightAsset,
      'assets/images/experience/baroque-frame-oval-hd.png',
      'assets/images/experience/baroque-frame-circular-hd.png',
      'assets/images/experience/baroque-frame-horizontal-oval-hd.png',
      'assets/images/experience/baroque-frame-portrait-hd.png',
      'assets/images/experience/baroque-frame-landscape-hd.png',
    ]) {
      precacheImage(AssetImage(asset), context);
    }
  }

  @override
  void dispose() {
    _slideshowTimer?.cancel();
    _galleryDriftController.dispose();
    _focusController.dispose();
    _focusedMediaTransformationController.dispose();
    super.dispose();
  }

  void _resetFocusedMediaZoom() {
    _focusedMediaTransformationController.value = Matrix4.identity();
    _videoMuted = true;
  }

  void _focusMemory(_FocusedMemory memory, Rect globalFrameRect) {
    final journeyBox =
        _journeySurfaceKey.currentContext?.findRenderObject() as RenderBox?;
    if (journeyBox == null) {
      return;
    }
    final localFrameRect = Rect.fromPoints(
      journeyBox.globalToLocal(globalFrameRect.topLeft),
      journeyBox.globalToLocal(globalFrameRect.bottomRight),
    );
    _galleryDriftController.stop();
    _resetFocusedMediaZoom();
    setState(() {
      _focusedMemory = memory;
      _focusedMediaIndex = _scheduledSlideshowIndex(memory, _slideshowTick);
      _focusedLastAdvanceTick = _slideshowTick;
      _focusedMemorySourceRect = localFrameRect;
      _isDismissingMemory = false;
    });
    _focusController.forward(from: 0);
  }

  Future<void> _dismissFocusedMemory() async {
    if (_isDismissingMemory || _focusedMemory == null) {
      return;
    }
    _isDismissingMemory = true;
    await _focusController.reverse();
    if (!mounted) {
      return;
    }
    _resetFocusedMediaZoom();
    setState(() {
      _focusedMemory = null;
      _focusedMediaIndex = null;
      _focusedMemorySourceRect = null;
      _isDismissingMemory = false;
    });
    _galleryDriftController.repeat();
  }

  Future<bool> dismissFocusedMemoryIfNeeded() async {
    if (_focusedMemory == null) {
      return false;
    }
    await _dismissFocusedMemory();
    return true;
  }

  void _advanceFocusedMemory() {
    if (_focusedMemory == null || _isDismissingMemory) {
      return;
    }
    final memory = _focusedMemory!;
    _resetFocusedMediaZoom();
    setState(() {
      _focusedMediaIndex =
          ((_focusedMediaIndex ?? 0) + 1) % memory.media.length;
      _focusedLastAdvanceTick = _slideshowTick;
    });
  }

  void _retreatFocusedMemory() {
    if (_focusedMemory == null || _isDismissingMemory) {
      return;
    }
    final memory = _focusedMemory!;
    _resetFocusedMediaZoom();
    setState(() {
      _focusedMediaIndex =
          ((_focusedMediaIndex ?? 0) - 1 + memory.media.length) %
          memory.media.length;
      _focusedLastAdvanceTick = _slideshowTick;
    });
  }

  void _startGalleryDrag(DragStartDetails details) {
    _galleryDriftController.stop();
    setState(() => _isGalleryDragging = true);
  }

  void _updateGalleryDrag(DragUpdateDetails details) {
    setState(() {
      _galleryDragOffset =
          (_galleryDragOffset - details.delta.dx / _wallScale) %
          _BaroqueGalleryWall.stripWidthFor(widget.trip);
    });
  }

  void _finishGalleryDrag() {
    if (!_isGalleryDragging) {
      return;
    }
    setState(() => _isGalleryDragging = false);
    if (_focusedMemory == null) {
      _galleryDriftController.repeat();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = constraints.biggest;
        _wallScale = viewport.height / 800;
        final sceneWidth = viewport.width / _wallScale;
        return AnimatedBuilder(
          animation: Listenable.merge(<Listenable>[
            _focusController,
            GalleryLayoutStore.instance,
          ]),
          builder: (context, child) {
            final focusProgress =
                _focusController.status == AnimationStatus.reverse
                ? Curves.easeInCubic.transform(_focusController.value)
                : _focusCurve.transform(_focusController.value);
            final focusGeometry = _focusGeometry(viewport, focusProgress);
            return Stack(
              key: _journeySurfaceKey,
              fit: StackFit.expand,
              children: <Widget>[
                const ColoredBox(color: Color(0xFF171716)),
                if (_focusedMemory == null)
                  MouseRegion(
                    cursor: _isGalleryDragging
                        ? SystemMouseCursors.grabbing
                        : SystemMouseCursors.grab,
                    child: GestureDetector(
                      key: const ValueKey('trip-memory-gallery-drag-area'),
                      behavior: HitTestBehavior.opaque,
                      onHorizontalDragStart: _startGalleryDrag,
                      onHorizontalDragUpdate: _updateGalleryDrag,
                      onHorizontalDragEnd: (_) => _finishGalleryDrag(),
                      onHorizontalDragCancel: _finishGalleryDrag,
                      child: ClipRect(
                        child: SizedBox.expand(
                          child: FittedBox(
                            fit: BoxFit.fill,
                            alignment: Alignment.topLeft,
                            child: SizedBox(
                              width: sceneWidth,
                              height: 800,
                              child: _BaroqueGalleryWall(
                                key: const ValueKey('trip-memory-gallery'),
                                trip: widget.trip,
                                viewportWidth: sceneWidth,
                                drift: _galleryDriftController,
                                dragOffset: _galleryDragOffset,
                                slideshowTick: _slideshowTick,
                                autoplayVideos: galleryAutoplaysVideosFor(
                                  widget.trip,
                                ),
                                onMemoryTap: _focusMemory,
                                onTasteTap: widget.onTasteTap,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_focusedMemory case final memory?)
                  _FocusedMemoryOverlay(
                    key: ValueKey('focused-memory-${memory.id}'),
                    memory: memory,
                    sourceRect: _focusedMemorySourceRect!,
                    cameraScale: focusGeometry.scale,
                    cameraTranslation: focusGeometry.translation,
                    progress: focusProgress,
                    slideshowIndex: _focusedMediaIndex!,
                    spotlightAsset: _spotlightAsset,
                    transformationController:
                        _focusedMediaTransformationController,
                    videoMuted: _videoMuted,
                    onToggleVideoSound: () =>
                        setState(() => _videoMuted = !_videoMuted),
                    onPreviousRequested: _retreatFocusedMemory,
                    onNextRequested: _advanceFocusedMemory,
                    onDismissRequested: _dismissFocusedMemory,
                  ),
              ],
            );
          },
        );
      },
    );
  }

  _FocusGeometry _focusGeometry(Size viewport, double progress) {
    final sourceRect = _focusedMemorySourceRect;
    final memory = _focusedMemory;
    if (sourceRect == null || memory == null) {
      return const _FocusGeometry(
        scale: 1,
        translation: Offset.zero,
        frameRect: Rect.zero,
      );
    }

    final compact = viewport.width < 600;
    final targetScale = math.min(
      viewport.width * 0.92 / sourceRect.width,
      viewport.height * (compact ? 0.65 : 0.9) / sourceRect.height,
    );
    final targetCenter = Offset(
      viewport.width / 2,
      viewport.height * (compact ? 0.42 : 0.5),
    );
    final scale = 1 + (targetScale - 1) * progress;
    final targetTranslation = targetCenter - sourceRect.center * targetScale;

    final translation = targetTranslation * progress;
    final frameRect = Rect.fromLTWH(
      sourceRect.left * scale + translation.dx,
      sourceRect.top * scale + translation.dy,
      sourceRect.width * scale,
      sourceRect.height * scale,
    );
    return _FocusGeometry(
      scale: scale,
      translation: translation,
      frameRect: frameRect,
    );
  }
}

class _FocusGeometry {
  const _FocusGeometry({
    required this.scale,
    required this.translation,
    required this.frameRect,
  });

  final double scale;
  final Offset translation;
  final Rect frameRect;
}

class _BaroqueGalleryWall extends StatelessWidget {
  const _BaroqueGalleryWall({
    required this.trip,
    required this.viewportWidth,
    required this.drift,
    required this.dragOffset,
    required this.slideshowTick,
    required this.autoplayVideos,
    required this.onMemoryTap,
    required this.onTasteTap,
    super.key,
  });

  static const double _driftPixelsPerSecond = 12;

  static double stripWidthFor(TripGalleryItem trip) =>
      GalleryLayoutStore.instance.layoutFor(trip.slug).stripWidth;

  static Duration driftDurationFor(TripGalleryItem trip) => Duration(
    milliseconds: (stripWidthFor(trip) / _driftPixelsPerSecond * 1000).round(),
  );

  static double initialDriftValueFor(
    TripGalleryItem trip, {
    required double viewportWidth,
  }) {
    const titleWidth = 340.0;
    final layout = GalleryLayoutStore.instance.layoutFor(trip.slug);
    final titleCenter =
        _galleryEditorialTitleLeft(trip) - layout.leadingTrim + titleWidth / 2;
    return (titleCenter - viewportWidth / 2) / stripWidthFor(trip);
  }

  final TripGalleryItem trip;
  final double viewportWidth;
  final Animation<double> drift;
  final double dragOffset;
  final int slideshowTick;
  final bool autoplayVideos;
  final void Function(_FocusedMemory memory, Rect globalFrameRect) onMemoryTap;
  final Future<void> Function() onTasteTap;

  @override
  Widget build(BuildContext context) {
    final stripWidth = stripWidthFor(trip);
    const wallpaperTileWidth = 575.0;
    final wallpaperScale = 675 / wallpaperTileWidth;
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const ColoredBox(color: Color(0xFF5B100B)),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: stripWidth * 2,
            child: AnimatedBuilder(
              animation: drift,
              builder: (context, child) {
                final scrollPhase =
                    (drift.value * stripWidth +
                        dragOffset +
                        initialDriftValueFor(
                              trip,
                              viewportWidth: viewportWidth,
                            ) *
                            stripWidth) %
                    stripWidth;
                return Transform.translate(
                  key: const ValueKey('gallery-drift-transform'),
                  offset: Offset(-scrollPhase, 0),
                  child: child,
                );
              },
              child: AnimatedBuilder(
                animation: GalleryLayoutStore.instance,
                builder: (context, _) {
                  final layout = GalleryLayoutStore.instance.layoutFor(
                    trip.slug,
                  );
                  return SizedBox(
                    width: stripWidth * 2,
                    child: Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        Image.asset(
                          'assets/textures/red_damask_gallery_wall.jpeg',
                          key: const ValueKey('gallery-repeating-wallpaper'),
                          scale: wallpaperScale,
                          fit: BoxFit.none,
                          alignment: Alignment.topLeft,
                          repeat: ImageRepeat.repeat,
                          filterQuality: FilterQuality.high,
                        ),
                        const Positioned.fill(
                          child: IgnorePointer(
                            child: DecoratedBox(
                              key: ValueKey(
                                'gallery-wallpaper-bottom-vignette',
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: <Color>[
                                    Colors.transparent,
                                    Color(0x180D0200),
                                    Color(0x8F090100),
                                  ],
                                  stops: <double>[0.54, 0.76, 1],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Row(
                          children: <Widget>[
                            for (var copyIndex = 0; copyIndex < 2; copyIndex++)
                              SizedBox(
                                width: stripWidth,
                                child: _GalleryStrip(
                                  trip: trip,
                                  layout: layout,
                                  slideshowTick: slideshowTick,
                                  autoplayVideos: autoplayVideos,
                                  onMemoryTap: onMemoryTap,
                                  onTasteTap: onTasteTap,
                                  copyIndex: copyIndex,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GalleryStrip extends StatelessWidget {
  const _GalleryStrip({
    required this.trip,
    required this.layout,
    required this.slideshowTick,
    required this.autoplayVideos,
    required this.onMemoryTap,
    required this.onTasteTap,
    required this.copyIndex,
  });

  static const double _frameScale = 2.3;
  static const double _rowCenterY = 405;

  final TripGalleryItem trip;
  final GalleryTripLayout layout;
  final int slideshowTick;
  final bool autoplayVideos;
  final void Function(_FocusedMemory memory, Rect globalFrameRect) onMemoryTap;
  final Future<void> Function() onTasteTap;
  final int copyIndex;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(-layout.leadingTrim, 0),
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned(
            left: 72,
            top: 32,
            child: Text(
              'EVERAFTER  /  TRIP ${trip.number.toString().padLeft(2, '0')}',
              style: const TextStyle(
                fontFamily: 'Georgia',
                color: EverAfterColors.agedPaper,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.6,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          for (final trinket in layout.trinkets)
            if (trinket.visible)
              _keepsake(
                assetName: trinket.assetName,
                label: trinket.label,
                left: trinket.left,
                top: trinket.top,
                width: trinket.width,
                height: trinket.height,
                angle: trinket.angle,
              ),
          for (final frame in layout.frames)
            if (frame.visible) _memoryFromPlacement(frame),
          Positioned(
            left: layout.foodMenu.left,
            top: layout.foodMenu.top,
            width: layout.foodMenu.width,
            height: layout.foodMenu.height,
            child: Transform.rotate(
              angle: layout.foodMenu.angle,
              child: _TripTasteGalleryMenu(
                key: ValueKey('taste-of-${trip.slug}-menu-$copyIndex'),
                trip: trip,
                onTap: onTasteTap,
              ),
            ),
          ),
          _EditorialGalleryTitle(
            trip: trip,
            dateRangeLabel: layout.effectiveDateRangeLabel(trip.dateRangeLabel),
            copyIndex: copyIndex,
            left: _galleryEditorialTitleLeft(trip),
            top: _rowCenterY - 95,
          ),
          for (final instagramPost in layout.instagramPosts)
            if (instagramPost.visible) _instagramPost(instagramPost),
        ],
      ),
    );
  }

  Widget _keepsake({
    required String assetName,
    required String label,
    required double left,
    required double top,
    required double width,
    required double height,
    required double angle,
  }) {
    final keepsakeName = assetName.split('/').last.split('.').first;
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: _OrganicGalleryKeepsake(
        key: ValueKey<String>(
          'gallery-keepsake-${trip.slug}-$keepsakeName-$copyIndex',
        ),
        assetName: assetName,
        label: label,
        angle: angle,
      ),
    );
  }

  Widget _instagramPost(GalleryInstagramPlacement placement) {
    final post = galleryVideoPostFor(trip.slug, placement.postIndex);
    if (post == null) return const SizedBox.shrink();
    final scaledWidth = placement.width * placement.scale;
    final scaledHeight = placement.height * placement.scale;
    final frameKind = switch (placement.style) {
      GalleryFrameStyle.oval => _FrameKind.oval,
      GalleryFrameStyle.circular => _FrameKind.circular,
      GalleryFrameStyle.portrait => _FrameKind.portrait,
      GalleryFrameStyle.landscape => _FrameKind.landscape,
      GalleryFrameStyle.horizontalOval => _FrameKind.horizontalOval,
    };
    return Positioned(
      left: placement.left - (scaledWidth - placement.width) / 2,
      top: placement.top - (scaledHeight - placement.height) / 2,
      width: scaledWidth,
      height: scaledHeight,
      child: Transform.rotate(
        angle: 0,
        child: _TappableInstagramPostFrame(
          tripName: trip.name,
          key: ValueKey<String>(
            'gallery-video-post-${trip.slug}-${post.shortcode}-$copyIndex',
          ),
          post: post,
          postNumber: placement.postIndex + 1,
          frameKind: frameKind,
          autoplayVideo: autoplayVideos,
          onTap: onMemoryTap,
        ),
      ),
    );
  }

  Widget _memoryFromPlacement(GalleryFramePlacement frame) {
    final kind = switch (frame.style) {
      GalleryFrameStyle.oval => _FrameKind.oval,
      GalleryFrameStyle.circular => _FrameKind.circular,
      GalleryFrameStyle.portrait => _FrameKind.portrait,
      GalleryFrameStyle.landscape => _FrameKind.landscape,
      GalleryFrameStyle.horizontalOval => _FrameKind.horizontalOval,
    };
    return _memory(
      memoryIndex: frame.memoryIndex,
      left: frame.left,
      top: frame.top,
      width: frame.width,
      height: frame.height,
      kind: kind,
      alignment: Alignment(frame.alignmentX, frame.alignmentY),
      scale: frame.scale,
      angle: frame.angle,
      portrait: frame.portrait,
      title: frame.title,
      photoEdits: frame.effectivePhotoEdits,
    );
  }

  Widget _memory({
    required int memoryIndex,
    required double left,
    required double top,
    required double width,
    required double height,
    required _FrameKind kind,
    required Alignment alignment,
    double scale = 1,
    double angle = 0,
    bool portrait = false,
    String? title,
    List<GalleryPhotoEdit> photoEdits = const <GalleryPhotoEdit>[],
  }) {
    final position = Offset(left, top);
    final memoryLocation = galleryMemoryLocationFor(trip.slug, memoryIndex);
    final media = photoEdits.isEmpty
        ? defaultGalleryMediaFor(trip, memoryIndex, portrait: portrait)
        : <GalleryMemoryAsset>[
            for (final edit in photoEdits)
              GalleryMemoryAsset(
                assetPath: edit.assetPath,
                kind: GalleryMemoryKind.photo,
                alignmentX: edit.alignmentX,
                alignmentY: edit.alignmentY,
                zoom: edit.zoom,
              ),
          ];
    final locationLabel = title ?? memoryLocation?.label;
    final scheduleSeed = (trip.number * 37) + (memoryIndex * 17) + 11;
    final slideshowPeriod = 4 + (scheduleSeed % 5);
    final slideshowPhase = (scheduleSeed ~/ 5) % slideshowPeriod;
    final effectiveScale = _frameScale * scale;
    final scaledWidth = width * effectiveScale;
    final scaledHeight = height * effectiveScale;
    return Positioned(
      left: position.dx - (scaledWidth - width) / 2,
      top: position.dy - (scaledHeight - height) / 2,
      width: scaledWidth,
      height: scaledHeight,
      child: Transform.rotate(
        angle: angle,
        child: _TappableMemoryFrame(
          key: ValueKey<String>(
            'gallery-memory-layout-${trip.slug}-$memoryIndex-$copyIndex',
          ),
          memory: _FocusedMemory(
            id: '${memoryLocation?.slug ?? kind.name}-${position.dx.round()}-${position.dy.round()}',
            kind: kind,
            media: media,
            alignment: alignment,
            semanticsLabel: locationLabel == null
                ? '${trip.name} trip memory'
                : '$locationLabel slideshow, ${media.length} items',
            locationLabel: locationLabel,
            slideshowOffset: memoryIndex,
            slideshowPeriod: slideshowPeriod,
            slideshowPhase: slideshowPhase,
          ),
          slideshowTick: slideshowTick,
          autoplayVideos: autoplayVideos,
          onTap: onMemoryTap,
        ),
      ),
    );
  }
}

class _OrganicGalleryKeepsake extends StatelessWidget {
  const _OrganicGalleryKeepsake({
    required this.assetName,
    required this.label,
    required this.angle,
    super.key,
  });

  final String assetName;
  final String label;
  final double angle;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Semantics(
        image: true,
        label: label,
        child: Transform.rotate(
          angle: angle,
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned.fill(
                child: Transform.translate(
                  offset: const Offset(7, 10),
                  child: ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(sigmaX: 7, sigmaY: 9),
                    child: ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                        Color(0xB8000000),
                        BlendMode.srcIn,
                      ),
                      child: GalleryTrinketImage(
                        source: assetName,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        excludeFromSemantics: true,
                      ),
                    ),
                  ),
                ),
              ),
              GalleryTrinketImage(
                source: assetName,
                key: ValueKey<String>('unframed-keepsake-$assetName'),
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                isAntiAlias: true,
                excludeFromSemantics: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TripTasteGalleryMenu extends StatefulWidget {
  const _TripTasteGalleryMenu({
    required this.trip,
    required this.onTap,
    super.key,
  });

  final TripGalleryItem trip;
  final Future<void> Function() onTap;

  @override
  State<_TripTasteGalleryMenu> createState() => _TripTasteGalleryMenuState();
}

class _TripTasteGalleryMenuState extends State<_TripTasteGalleryMenu>
    with TickerProviderStateMixin {
  late final AnimationController _liftController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 80),
    reverseDuration: const Duration(milliseconds: 130),
  );
  late final AnimationController _openController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
    reverseDuration: const Duration(milliseconds: 480),
  );
  late final AnimationController _pageSettleController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
  );
  late final AnimationController _pageZoomController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
    reverseDuration: const Duration(milliseconds: 540),
  );
  late final AnimationController _textureSettleController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );
  OverlayEntry? _pageOverlay;
  bool _opening = false;
  bool _landing = false;

  @override
  void dispose() {
    _removePageOverlay();
    _textureSettleController.dispose();
    _pageZoomController.dispose();
    _pageSettleController.dispose();
    _openController.dispose();
    _liftController.dispose();
    super.dispose();
  }

  Rect? _pageRectInOverlay(OverlayState overlay) {
    final menuBox = context.findRenderObject() as RenderBox?;
    final overlayBox = overlay.context.findRenderObject() as RenderBox?;
    if (menuBox == null || overlayBox == null || !menuBox.hasSize) {
      return null;
    }
    return MatrixUtils.transformRect(
      menuBox.getTransformTo(overlayBox),
      Offset.zero & menuBox.size,
    );
  }

  void _showPageOverlay({required bool expanded}) {
    _removePageOverlay();
    final overlay = Overlay.of(context, rootOverlay: true);
    _pageZoomController.value = expanded ? 1 : 0;
    _textureSettleController.value = expanded ? 1 : 0;
    _pageOverlay = OverlayEntry(
      builder: (context) {
        return AnimatedBuilder(
          animation: Listenable.merge(<Listenable>[
            _pageZoomController,
            _textureSettleController,
          ]),
          builder: (context, child) {
            final sourceRect = _pageRectInOverlay(overlay);
            final overlayBox = overlay.context.findRenderObject() as RenderBox?;
            if (sourceRect == null || overlayBox == null) {
              return const SizedBox.shrink();
            }
            final progress = Curves.easeInOutCubic.transform(
              _pageZoomController.value,
            );
            final viewportRect = Offset.zero & overlayBox.size;
            final targetScale = math.max(
              viewportRect.width / sourceRect.width,
              viewportRect.height / sourceRect.height,
            );
            final cameraScale = ui.lerpDouble(1, targetScale, progress)!;
            final pageRect = Rect.fromCenter(
              center: Offset.lerp(
                sourceRect.center,
                viewportRect.center,
                progress,
              )!,
              width: sourceRect.width * cameraScale,
              height: sourceRect.height * cameraScale,
            );
            final coverRect = Rect.fromLTWH(
              pageRect.left - (pageRect.width * 0.965),
              pageRect.top,
              pageRect.width,
              pageRect.height,
            );
            final spineWidth = math.max(3.0, pageRect.width * 0.025);
            final textureCameraScale =
                (sourceRect.height * targetScale) / viewportRect.height;
            final textureSettleProgress = Curves.easeOutCubic.transform(
              _textureSettleController.value,
            );
            final textureScale = ui.lerpDouble(
              textureCameraScale,
              1,
              textureSettleProgress,
            )!;
            final textureOpacity = const Interval(
              0,
              0.08,
              curve: Curves.easeOut,
            ).transform(_textureSettleController.value);
            return IgnorePointer(
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Positioned.fill(
                    child: BackdropFilter(
                      key: const ValueKey('taste-page-backdrop-blur'),
                      filter: ui.ImageFilter.blur(
                        sigmaX: 3.5 * progress,
                        sigmaY: 3.5 * progress,
                      ),
                      child: ColoredBox(
                        color: Color.fromRGBO(24, 16, 10, 0.08 * progress),
                      ),
                    ),
                  ),
                  Positioned.fromRect(
                    rect: coverRect,
                    child: KeyedSubtree(
                      key: const ValueKey('taste-attached-open-cover'),
                      child: Transform.rotate(
                        alignment: Alignment.centerRight,
                        angle: 0.012 * (1 - progress),
                        child: const _TasteMenuCoverInside(),
                      ),
                    ),
                  ),
                  Positioned.fromRect(
                    rect: pageRect,
                    child: KeyedSubtree(
                      key: const ValueKey('taste-page-zoom-overlay'),
                      child: Transform.rotate(
                        angle: -0.018 * (1 - progress),
                        child: _TasteBlankPage(
                          borderRadius: 2 * (1 - progress),
                          elevationProgress: 1 - progress,
                        ),
                      ),
                    ),
                  ),
                  Positioned.fromRect(
                    rect: Rect.fromLTWH(
                      pageRect.left - (spineWidth * 0.55),
                      pageRect.top,
                      spineWidth,
                      pageRect.height,
                    ),
                    child: const KeyedSubtree(
                      key: ValueKey('taste-attached-book-spine'),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: <Color>[
                              Color(0x66180E08),
                              Color(0xAA3A2717),
                              Color(0x557A5A34),
                              Color(0x00180E08),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Opacity(
                      key: const ValueKey('taste-texture-settle-opacity'),
                      opacity: textureOpacity,
                      child: Transform.scale(
                        key: const ValueKey('taste-texture-settle-scale'),
                        scale: textureScale,
                        alignment: Alignment.center,
                        child: const WarmLinenTexture(),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    overlay.insert(_pageOverlay!);
  }

  void _removePageOverlay() {
    _pageOverlay?.remove();
    _pageOverlay = null;
  }

  Future<void> _openMenu() async {
    if (_opening) return;
    setState(() => _opening = true);
    await _liftController.forward(from: 0);
    if (!mounted) return;
    await _openController.forward(from: 0);
    if (!mounted) return;
    await _pageSettleController.forward(from: 0);
    if (!mounted) return;

    try {
      _showPageOverlay(expanded: false);
      await Future<void>.delayed(const Duration(milliseconds: 90));
      if (!mounted) return;
      await _pageZoomController.forward();
      if (!mounted) return;

      await _textureSettleController.forward();
      if (!mounted) return;
      final route = widget.onTap();
      await Future<void>.delayed(const Duration(milliseconds: 80));
      _removePageOverlay();
      await route;

      if (!mounted) return;
      _showPageOverlay(expanded: true);
      await _textureSettleController.reverse();
      await _pageZoomController.reverse();
      _removePageOverlay();
    } finally {
      _removePageOverlay();
      if (mounted) {
        await _openController.reverse();
      }
      if (mounted) {
        _landing = true;
        await _liftController.reverse();
        _landing = false;
        _pageSettleController.value = 0;
      }
      if (mounted) {
        setState(() => _opening = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _liftController,
      builder: (context, child) {
        final lift = Curves.easeOutCubic.transform(_liftController.value);
        final landingProgress = 1 - _liftController.value;
        final landingOffset = _landing
            ? math.sin(math.pi * landingProgress) * 1.2
            : 0.0;
        return Transform.translate(
          key: const ValueKey('taste-menu-lift'),
          offset: Offset(0, (-4 * lift) + landingOffset),
          child: Transform.scale(
            scale: 1 + (0.012 * lift),
            child: Transform.rotate(
              angle: -0.018 + (0.006 * lift),
              child: child,
            ),
          ),
        );
      },
      child: Semantics(
        button: true,
        label: 'Open Taste of ${widget.trip.name} tasting menu',
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _openMenu,
              borderRadius: BorderRadius.circular(2),
              child: AnimatedBuilder(
                animation: Listenable.merge(<Listenable>[
                  _openController,
                  _pageSettleController,
                ]),
                builder: (context, child) {
                  final progress = const Cubic(
                    0.65,
                    0,
                    0.35,
                    1,
                  ).transform(_openController.value);
                  final angle = math.pi * 0.92 * progress;
                  final movingLight = math.sin(math.pi * progress).clamp(0, 1);
                  final hingeShadow = progress * (0.18 + 0.5 * movingLight);
                  final settledScale =
                      TweenSequence<double>(<TweenSequenceItem<double>>[
                        TweenSequenceItem<double>(
                          tween: Tween<double>(begin: 0.985, end: 1.012),
                          weight: 68,
                        ),
                        TweenSequenceItem<double>(
                          tween: Tween<double>(begin: 1.012, end: 1),
                          weight: 32,
                        ),
                      ]).transform(_pageSettleController.value);
                  return Stack(
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      Positioned.fill(
                        child: Opacity(
                          key: const ValueKey('taste-menu-inside-reveal'),
                          opacity: const Interval(
                            0.08,
                            0.62,
                            curve: Curves.easeOut,
                          ).transform(progress),
                          child: Transform.scale(
                            key: const ValueKey('taste-menu-page-settle'),
                            alignment: Alignment.centerLeft,
                            scale: settledScale,
                            child: const _TasteMenuInside(),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        width: 24,
                        child: IgnorePointer(
                          child: Opacity(
                            key: const ValueKey('taste-menu-hinge-shadow'),
                            opacity: hingeShadow.clamp(0, 0.72),
                            child: const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: <Color>[
                                    Color(0x880D0805),
                                    Color(0x281D120B),
                                    Color(0x001D120B),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: Transform(
                          key: const ValueKey('taste-menu-cover-flip'),
                          alignment: Alignment.centerLeft,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.0018)
                            ..rotateY(-angle),
                          child: Stack(
                            fit: StackFit.expand,
                            children: <Widget>[
                              if (angle <= math.pi / 2)
                                child!
                              else
                                Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.rotationY(math.pi),
                                  child: const _TasteMenuCoverInside(),
                                ),
                              IgnorePointer(
                                child: Opacity(
                                  key: const ValueKey(
                                    'taste-menu-cover-highlight',
                                  ),
                                  opacity: 0.28 * movingLight,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment(
                                          -1.8 + (2.4 * progress),
                                          -0.2,
                                        ),
                                        end: Alignment(
                                          -0.6 + (2.4 * progress),
                                          0.2,
                                        ),
                                        colors: const <Color>[
                                          Color(0x00FFF8E8),
                                          Color(0xAAFFF8E8),
                                          Color(0x00FFF8E8),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
                child: _TasteLaceMenuCover(trip: widget.trip),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TasteLaceMenuCover extends StatelessWidget {
  const _TasteLaceMenuCover({required this.trip});

  final TripGalleryItem trip;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: EverAfterColors.agedPaper,
        border: Border.all(color: const Color(0xFFB19369), width: 2),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x99000000),
            blurRadius: 14,
            offset: Offset(5, 8),
          ),
          BoxShadow(
            color: Color(0x552D1A0D),
            blurRadius: 2,
            offset: Offset(1, 2),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Opacity(
            opacity: 0.2,
            child: Image.asset(
              'assets/textures/warm_linen_canvas_visible.jpg',
              fit: BoxFit.cover,
              color: const Color(0xFFE1C894),
              colorBlendMode: BlendMode.multiply,
              excludeFromSemantics: true,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: EverAfterColors.ink.withValues(alpha: 0.48),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 10, 8, 9),
                child: Column(
                  children: <Widget>[
                    Text(
                      'EVERAFTER · MENU ${trip.number.toString().padLeft(2, '0')}',
                      maxLines: 1,
                      style: const TextStyle(
                        fontFamily: 'Georgia',
                        color: EverAfterColors.ink,
                        fontSize: 6.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.9,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: const Color(0xFFB73B2E),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF87251F)),
                      ),
                      child: Center(
                        child: Text(
                          trip.location.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFFF4E6CB),
                            fontSize: 16,
                            height: 1,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 7),
                    SizedBox(
                      height: 36,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'TASTE OF\n${trip.name.toUpperCase()}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Georgia',
                            color: EverAfterColors.ink,
                            fontSize: 23,
                            height: 0.91,
                            letterSpacing: 1.2,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Container(
                      width: 28,
                      height: 1,
                      color: EverAfterColors.ink.withValues(alpha: 0.42),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'CAFÉS · MARKETS · MEALS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        color: EverAfterColors.warmBrown,
                        fontSize: 6.4,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'TAP TO OPEN',
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        color: EverAfterColors.ink,
                        fontSize: 7,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.15,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TasteMenuInside extends StatelessWidget {
  const _TasteMenuInside();

  @override
  Widget build(BuildContext context) {
    return const _TasteBlankPage(borderRadius: 0, elevationProgress: 1);
  }
}

class _TasteBlankPage extends StatelessWidget {
  const _TasteBlankPage({
    required this.borderRadius,
    required this.elevationProgress,
  });

  final double borderRadius;
  final double elevationProgress;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFE8D5A9),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: Color.lerp(
            const Color(0xFFA17D50),
            const Color(0x00A17D50),
            1 - elevationProgress,
          )!,
          width: 2,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Color.fromRGBO(29, 16, 8, 0.62 * elevationProgress),
            blurRadius: 22 * elevationProgress,
            offset: Offset(8 * elevationProgress, 12 * elevationProgress),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: const WarmLinenTexture(),
      ),
    );
  }
}

class _TasteMenuCoverInside extends StatelessWidget {
  const _TasteMenuCoverInside();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFDCC28D),
        border: Border.all(color: const Color(0xFFA17D50), width: 2),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x7723150B),
            blurRadius: 12,
            offset: Offset(-5, 5),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Opacity(
            opacity: 0.2,
            child: Image.asset(
              'assets/textures/warm_linen_canvas_visible.jpg',
              fit: BoxFit.cover,
              color: const Color(0xFFD4B577),
              colorBlendMode: BlendMode.multiply,
              excludeFromSemantics: true,
            ),
          ),
          Center(
            child: Transform.rotate(
              angle: -0.08,
              child: const Text(
                'いただきます',
                style: TextStyle(
                  color: Color(0x66745A3A),
                  fontSize: 12,
                  letterSpacing: 2,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FocusedMemory {
  const _FocusedMemory({
    required this.id,
    required this.kind,
    required this.media,
    required this.alignment,
    required this.semanticsLabel,
    required this.locationLabel,
    required this.slideshowOffset,
    required this.slideshowPeriod,
    required this.slideshowPhase,
    this.instagramPost,
  });

  final String id;
  final _FrameKind kind;
  final List<GalleryMemoryAsset> media;
  final Alignment alignment;
  final String semanticsLabel;
  final String? locationLabel;
  final int slideshowOffset;
  final int slideshowPeriod;
  final int slideshowPhase;
  final GalleryVideoPost? instagramPost;
}

int _scheduledSlideshowIndex(_FocusedMemory memory, int tick) {
  if (memory.media.length <= 1) {
    return 0;
  }
  final scheduledStep =
      (tick + memory.slideshowPhase) ~/ memory.slideshowPeriod;
  return (scheduledStep + memory.slideshowOffset) % memory.media.length;
}

class _TappableMemoryFrame extends StatefulWidget {
  const _TappableMemoryFrame({
    required this.memory,
    required this.slideshowTick,
    required this.autoplayVideos,
    required this.onTap,
    super.key,
  });

  final _FocusedMemory memory;
  final int slideshowTick;
  final bool autoplayVideos;
  final void Function(_FocusedMemory memory, Rect globalFrameRect) onTap;

  @override
  State<_TappableMemoryFrame> createState() => _TappableMemoryFrameState();
}

class _TappableMemoryFrameState extends State<_TappableMemoryFrame> {
  final GlobalKey _frameKey = GlobalKey();

  void _handleTap() {
    final frameBox = _frameKey.currentContext?.findRenderObject() as RenderBox?;
    if (frameBox == null) {
      return;
    }
    final frameRect = MatrixUtils.transformRect(
      frameBox.getTransformTo(null),
      Offset.zero & frameBox.size,
    );
    widget.onTap(widget.memory, frameRect);
  }

  @override
  Widget build(BuildContext context) {
    final mediaIndex = _scheduledSlideshowIndex(
      widget.memory,
      widget.slideshowTick,
    );
    return Semantics(
      button: true,
      label: 'Open ${widget.memory.semanticsLabel}',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          key: const ValueKey('gallery-memory-frame'),
          behavior: HitTestBehavior.opaque,
          onTap: _handleTap,
          child: SizedBox.expand(
            key: _frameKey,
            child: _BaroqueMemoryFrame(
              kind: widget.memory.kind,
              media: widget.memory.media,
              alignment: widget.memory.alignment,
              semanticsLabel: widget.memory.semanticsLabel,
              locationLabel: widget.memory.locationLabel,
              mediaIndex: mediaIndex,
              playVideos: widget.autoplayVideos,
              slideshowId: widget.memory.id,
            ),
          ),
        ),
      ),
    );
  }
}

class _TappableInstagramPostFrame extends StatefulWidget {
  const _TappableInstagramPostFrame({
    required this.post,
    required this.tripName,
    required this.postNumber,
    required this.frameKind,
    required this.autoplayVideo,
    required this.onTap,
    super.key,
  });

  final GalleryVideoPost post;
  final String tripName;
  final int postNumber;
  final _FrameKind frameKind;
  final bool autoplayVideo;
  final void Function(_FocusedMemory memory, Rect globalFrameRect) onTap;

  @override
  State<_TappableInstagramPostFrame> createState() =>
      _TappableInstagramPostFrameState();
}

class _TappableInstagramPostFrameState
    extends State<_TappableInstagramPostFrame> {
  final GlobalKey _frameKey = GlobalKey();
  Offset? _pointerDownPosition;

  void _handleTap() {
    final frameBox = _frameKey.currentContext?.findRenderObject() as RenderBox?;
    if (frameBox == null) {
      return;
    }
    final frameRect = MatrixUtils.transformRect(
      frameBox.getTransformTo(null),
      Offset.zero & frameBox.size,
    );
    widget.onTap(
      _FocusedMemory(
        id: 'instagram-${widget.post.shortcode}',
        kind: widget.frameKind,
        media: <GalleryMemoryAsset>[
          GalleryMemoryAsset(
            assetPath: widget.post.videoAssetPath,
            kind: GalleryMemoryKind.video,
            posterAssetPath: widget.post.coverAssetPath,
          ),
        ],
        alignment: Alignment.center,
        semanticsLabel: 'Video ${widget.postNumber} from ${widget.tripName}',
        locationLabel: null,
        slideshowOffset: 0,
        slideshowPeriod: 6,
        slideshowPhase: 0,
        instagramPost: widget.post,
      ),
      frameRect,
    );
  }

  void _handlePointerUp(PointerUpEvent event) {
    final pointerDownPosition = _pointerDownPosition;
    _pointerDownPosition = null;
    if (pointerDownPosition != null &&
        (event.position - pointerDownPosition).distance < 8) {
      _handleTap();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Open video ${widget.postNumber} from ${widget.tripName}',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Listener(
          key: const ValueKey('gallery-instagram-post-frame'),
          behavior: HitTestBehavior.opaque,
          onPointerDown: (event) => _pointerDownPosition = event.position,
          onPointerUp: _handlePointerUp,
          onPointerCancel: (_) => _pointerDownPosition = null,
          child: SizedBox.expand(
            key: _frameKey,
            child: _BaroqueInstagramPostFrame(
              post: widget.post,
              kind: widget.frameKind,
              playVideo: widget.autoplayVideo,
            ),
          ),
        ),
      ),
    );
  }
}

class _BaroqueInstagramPostFrame extends StatelessWidget {
  const _BaroqueInstagramPostFrame({
    required this.post,
    required this.kind,
    required this.playVideo,
  });

  final GalleryVideoPost post;
  final _FrameKind kind;
  final bool playVideo;

  String get _frameAsset => switch (kind) {
    _FrameKind.oval => 'assets/images/experience/baroque-frame-oval-hd.png',
    _FrameKind.circular =>
      'assets/images/experience/baroque-frame-circular-hd.png',
    _FrameKind.horizontalOval =>
      'assets/images/experience/baroque-frame-horizontal-oval-hd.png',
    _FrameKind.portrait =>
      'assets/images/experience/baroque-frame-portrait-hd.png',
    _FrameKind.landscape =>
      'assets/images/experience/baroque-frame-landscape-hd.png',
  };

  Widget _frameImage({Key? key}) {
    return Image.asset(
      _frameAsset,
      key: key,
      fit: BoxFit.fill,
      filterQuality: FilterQuality.high,
      isAntiAlias: true,
      excludeFromSemantics: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final postRect = _baroqueFramePhotoRect(kind, size);

        final postCard = _InstagramPostFrame(post: post, playVideo: playVideo);

        return Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Positioned.fill(
              child: IgnorePointer(
                child: Transform.translate(
                  offset: Offset(0, size.height * 0.035),
                  child: ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(sigmaX: 7, sigmaY: 9),
                    child: ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                        Color(0xA61A0800),
                        BlendMode.srcIn,
                      ),
                      child: _frameImage(),
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fromRect(
              rect: postRect,
              child:
                  kind == _FrameKind.oval ||
                      kind == _FrameKind.circular ||
                      kind == _FrameKind.horizontalOval
                  ? ClipOval(
                      key: ValueKey<String>(
                        'gallery-instagram-${kind.name}-media-mask',
                      ),
                      child: ColoredBox(
                        color: const Color(0xFF171513),
                        child: postCard,
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: ColoredBox(
                        color: const Color(0xFF171513),
                        child: postCard,
                      ),
                    ),
            ),
            Positioned.fill(
              child: _frameImage(
                key: ValueKey<String>(
                  'gallery-instagram-${kind.name}-baroque-frame',
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _InstagramPostFrame extends StatelessWidget {
  const _InstagramPostFrame({
    required this.post,
    this.focused = false,
    this.playVideo = false,
    this.muted = true,
  });

  final GalleryVideoPost post;
  final bool focused;
  final bool playVideo;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      key: focused
          ? const ValueKey('focused-instagram-post')
          : const ValueKey('instagram-post-frame'),
      borderRadius: BorderRadius.circular(focused ? 3.5 : 2),
      child: ColoredBox(
        key: focused ? const ValueKey('focused-instagram-reel-viewport') : null,
        color: const Color(0xFF171513),
        child: playVideo
            ? _LoopingMemoryVideo(
                assetPath: post.videoAssetPath,
                posterAssetPath: post.coverAssetPath,
                alignment: Alignment.center,
                muted: muted,
              )
            : Image.asset(
                post.coverAssetPath,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                filterQuality: FilterQuality.high,
                excludeFromSemantics: true,
              ),
      ),
    );
  }
}

class _FocusedInstagramPostFrame extends StatelessWidget {
  const _FocusedInstagramPostFrame({
    required this.post,
    required this.progress,
    required this.playVideo,
    this.muted = true,
  });

  final GalleryVideoPost post;
  final double progress;
  final bool playVideo;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final targetWidth = math.min(
          constraints.maxWidth,
          constraints.maxHeight * _instagramReelAspectRatio,
        );
        final animatedWidth = ui.lerpDouble(
          constraints.maxWidth,
          targetWidth,
          Curves.easeInOutCubic.transform(progress.clamp(0.0, 1.0)),
        )!;

        return Align(
          alignment: Alignment.center,
          child: SizedBox(
            width: animatedWidth,
            height: constraints.maxHeight,
            child: _InstagramPostFrame(
              post: post,
              focused: true,
              playVideo: playVideo,
              muted: muted,
            ),
          ),
        );
      },
    );
  }
}

class _FocusedMemoryOverlay extends StatelessWidget {
  const _FocusedMemoryOverlay({
    required this.memory,
    required this.videoMuted,
    required this.onToggleVideoSound,
    required this.sourceRect,
    required this.cameraScale,
    required this.cameraTranslation,
    required this.progress,
    required this.slideshowIndex,
    required this.spotlightAsset,
    required this.transformationController,
    required this.onPreviousRequested,
    required this.onNextRequested,
    required this.onDismissRequested,
    super.key,
  });

  final _FocusedMemory memory;
  final bool videoMuted;
  final VoidCallback onToggleVideoSound;
  final Rect sourceRect;
  final double cameraScale;
  final Offset cameraTranslation;
  final double progress;
  final int slideshowIndex;
  final String spotlightAsset;
  final TransformationController transformationController;
  final VoidCallback onPreviousRequested;
  final VoidCallback onNextRequested;
  final VoidCallback onDismissRequested;

  @override
  Widget build(BuildContext context) {
    final frameDissolveProgress = _interval(
      progress,
      begin: 0.34,
      end: 0.84,
      curve: Curves.easeInOutCubic,
    );
    final blackoutProgress = _interval(
      progress,
      begin: 0.5,
      end: 0.88,
      curve: Curves.easeOutCubic,
    );
    final spotlightProgress = _interval(
      progress,
      begin: _spotlightStartProgress,
      end: 1,
      curve: Curves.easeOutCubic,
    );
    final canAdvance = memory.media.length > 1;
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = constraints.biggest;
        final focusedFrameRect = Rect.fromLTWH(
          sourceRect.left * cameraScale + cameraTranslation.dx,
          sourceRect.top * cameraScale + cameraTranslation.dy,
          sourceRect.width * cameraScale,
          sourceRect.height * cameraScale,
        );
        final placardRect = _focusedLocationPlacardRect(
          viewport: viewport,
          frameRect: focusedFrameRect,
        );
        final placardProgress = _interval(
          progress,
          begin: 0.68,
          end: 0.94,
          curve: Curves.easeOutCubic,
        );
        final focusedMedia = memory.instagramPost != null
            ? _FocusedInstagramPostFrame(
                post: memory.instagramPost!,
                muted: videoMuted,
                progress: progress,
                playVideo: progress >= 0.98,
              )
            : _BaroqueMemoryFrame(
                kind: memory.kind,
                media: memory.media,
                alignment: memory.alignment,
                semanticsLabel: 'Enlarged ${memory.semanticsLabel}',
                muted: videoMuted,
                locationLabel: memory.locationLabel,
                mediaIndex: slideshowIndex,
                imageViewportKey: const ValueKey('focused-memory-image'),
                playVideos: progress >= 0.98,
                showFrame: false,
              );
        final transitionFrame = memory.instagramPost != null
            ? _BaroqueInstagramPostFrame(
                post: memory.instagramPost!,
                kind: memory.kind,
                playVideo: false,
              )
            : _BaroqueMemoryFrame(
                kind: memory.kind,
                media: memory.media,
                alignment: memory.alignment,
                semanticsLabel: memory.semanticsLabel,
                locationLabel: memory.locationLabel,
                mediaIndex: slideshowIndex,
                playVideos: false,
              );

        return Stack(
          key: const ValueKey('focused-memory-overlay'),
          fit: StackFit.expand,
          children: <Widget>[
            GestureDetector(
              key: const ValueKey('focused-memory-backdrop'),
              behavior: HitTestBehavior.opaque,
              onTap: onDismissRequested,
              child: Semantics(
                button: true,
                label: 'Close enlarged memory',
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    ColoredBox(
                      key: const ValueKey('focused-memory-blackout'),
                      color: Color.lerp(
                        Colors.transparent,
                        const Color(0xE6030201),
                        blackoutProgress,
                      )!,
                    ),
                    Opacity(
                      key: const ValueKey('focused-memory-spotlight'),
                      opacity: spotlightProgress * 0.94,
                      child: Image.asset(
                        spotlightAsset,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.high,
                        excludeFromSemantics: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned.fill(
              child: Transform.translate(
                key: const ValueKey('focused-memory-camera-translation'),
                offset: cameraTranslation,
                child: Transform.scale(
                  key: const ValueKey('focused-memory-camera-scale'),
                  alignment: Alignment.topLeft,
                  scale: cameraScale,
                  child: Stack(
                    key: const ValueKey('focused-memory-camera-plane'),
                    fit: StackFit.expand,
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      Positioned.fromRect(
                        rect: sourceRect,
                        child: Semantics(
                          button: canAdvance,
                          label: canAdvance
                              ? 'Tap left for previous or right for next in '
                                    '${memory.semanticsLabel}'
                              : 'Enlarged ${memory.semanticsLabel}',
                          child: MouseRegion(
                            cursor: canAdvance
                                ? SystemMouseCursors.click
                                : MouseCursor.defer,
                            child: GestureDetector(
                              key: const ValueKey(
                                'focused-memory-touch-surface-container',
                              ),
                              behavior: HitTestBehavior.opaque,
                              child: DecoratedBox(
                                key: const ValueKey('focused-memory-frame'),
                                decoration: BoxDecoration(
                                  boxShadow: <BoxShadow>[
                                    BoxShadow(
                                      color: EverAfterColors.brass.withValues(
                                        alpha: 0.46 * spotlightProgress,
                                      ),
                                      blurRadius: 54 * spotlightProgress,
                                      spreadRadius: 5 * spotlightProgress,
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.85 * spotlightProgress,
                                      ),
                                      blurRadius: 38 * spotlightProgress,
                                      offset: Offset(0, 14 * spotlightProgress),
                                    ),
                                  ],
                                ),
                                child: InteractiveViewer(
                                  key: const ValueKey(
                                    'focused-memory-interactive-viewer',
                                  ),
                                  transformationController:
                                      transformationController,
                                  minScale: 1,
                                  maxScale: 4,
                                  panEnabled: progress >= 0.98,
                                  scaleEnabled: progress >= 0.98,
                                  trackpadScrollCausesScale: true,
                                  child: Stack(
                                    key: const ValueKey(
                                      'focused-memory-next-photo',
                                    ),
                                    fit: StackFit.expand,
                                    children: <Widget>[
                                      if (frameDissolveProgress >= 1)
                                        focusedMedia
                                      else
                                        Opacity(
                                          key: const ValueKey(
                                            'focused-memory-media-opacity',
                                          ),
                                          opacity: frameDissolveProgress,
                                          child: focusedMedia,
                                        ),
                                      if (frameDissolveProgress < 1)
                                        IgnorePointer(
                                          child: Opacity(
                                            key: const ValueKey(
                                              'focused-memory-transition-frame-opacity',
                                            ),
                                            opacity: 1 - frameDissolveProgress,
                                            child: transitionFrame,
                                          ),
                                        ),
                                      if (progress >= 0.98 && canAdvance)
                                        Positioned.fill(
                                          child: Row(
                                            children: <Widget>[
                                              Expanded(
                                                child: GestureDetector(
                                                  key: const ValueKey(
                                                    'focused-memory-previous',
                                                  ),
                                                  behavior:
                                                      HitTestBehavior.opaque,
                                                  onTap: onPreviousRequested,
                                                  child:
                                                      const SizedBox.expand(),
                                                ),
                                              ),
                                              Expanded(
                                                child: GestureDetector(
                                                  key: const ValueKey(
                                                    'focused-memory-next',
                                                  ),
                                                  behavior:
                                                      HitTestBehavior.opaque,
                                                  onTap: onNextRequested,
                                                  child:
                                                      const SizedBox.expand(),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (memory.locationLabel case final label?)
              Positioned.fromRect(
                key: const ValueKey('focused-memory-location-note-position'),
                rect: placardRect,
                child: IgnorePointer(
                  child: Transform.translate(
                    offset: Offset(-18 * (1 - placardProgress), 0),
                    child: Opacity(
                      opacity: placardProgress,
                      child: _FocusedLocationPlacard(label: label),
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.paddingOf(context).bottom + 20,
              child: IgnorePointer(
                child: Opacity(
                  opacity: _interval(
                    progress,
                    begin: 0.72,
                    end: 1,
                    curve: Curves.easeOut,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        if (memory.locationLabel != null) ...<Widget>[
                          Text(
                            key: const ValueKey(
                              'focused-memory-slideshow-counter',
                            ),
                            '${slideshowIndex + 1}'
                            ' / ${memory.media.length}',
                            style: const TextStyle(
                              fontFamily: 'Georgia',
                              color: Color(0x99DCCEB7),
                              fontSize: 8,
                              letterSpacing: 1.4,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        Text(
                          canAdvance
                              ? 'TAP LEFT / RIGHT FOR PREVIOUS / NEXT'
                                    '  ·  PINCH TO ZOOM'
                                    '  ·  TAP OUTSIDE TO RETURN'
                              : 'TAP OUTSIDE TO RETURN',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            color: Color(0xBFDCCEB7),
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2.4,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (progress >= 0.98 &&
                (memory.instagramPost != null ||
                    memory.media[slideshowIndex].isVideo))
              Positioned(
                top: MediaQuery.paddingOf(context).top + 64,
                right: 16,
                child: IconButton.filledTonal(
                  key: const ValueKey('memory-video-sound'),
                  tooltip: videoMuted ? 'Turn video sound on' : 'Mute video',
                  onPressed: onToggleVideoSound,
                  icon: Icon(videoMuted ? Icons.volume_off : Icons.volume_up),
                ),
              ),
          ],
        );
      },
    );
  }
}

Rect _focusedLocationPlacardRect({
  required Size viewport,
  required Rect frameRect,
}) {
  if (viewport.width < 600) {
    final width = math.min(168.0, viewport.width - 32);
    final height = width * 0.72;
    final maxTop = math.max(16.0, viewport.height - height - 80);
    return Rect.fromLTWH(
      (viewport.width - width) / 2,
      (frameRect.bottom + 12).clamp(16.0, maxTop),
      width,
      height,
    );
  }

  final width = (viewport.width * 0.15).clamp(128.0, 168.0);
  final height = width * 0.72;
  final horizontalMargin = (viewport.width * 0.025).clamp(18.0, 32.0);
  final availableLeft = frameRect.left - width - horizontalMargin;
  final left = math.max(24.0, availableLeft);
  final desiredTop =
      frameRect.center.dy +
      math.min(frameRect.height * 0.12, 64.0) -
      height / 2;
  final maxTop = math.max(24.0, viewport.height - height - 58.0);
  final top = desiredTop.clamp(24.0, maxTop);
  return Rect.fromLTWH(left, top, width, height);
}

class _FocusedLocationPlacard extends StatelessWidget {
  const _FocusedLocationPlacard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const ValueKey('focused-memory-location-note'),
      container: true,
      label: 'Location: $label',
      child: Transform.rotate(
        angle: -0.012,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFF1EBDD),
            border: Border.all(color: const Color(0x33755B3C), width: 0.7),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x80000000),
                blurRadius: 13,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Opacity(
                opacity: 0.2,
                child: Image.asset(
                  'assets/textures/texturelabs_paper_320.jpg',
                  fit: BoxFit.cover,
                  color: const Color(0xFFE8DDCA),
                  colorBlendMode: BlendMode.modulate,
                  filterQuality: FilterQuality.high,
                  excludeFromSemantics: true,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
                child: ExcludeSemantics(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Text(
                        'LOCATION',
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          color: Color(0xFF6B5744),
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2.2,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const SizedBox(
                        width: 28,
                        child: Divider(
                          height: 1,
                          thickness: 0.7,
                          color: Color(0x88755B3C),
                        ),
                      ),
                      const SizedBox(height: 10),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          label.toUpperCase(),
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Georgia',
                            color: Color(0xFF322A23),
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.1,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 7),
                      const Text(
                        'TRAVEL MEMORY',
                        style: TextStyle(
                          fontFamily: 'Times New Roman',
                          color: Color(0xFF776958),
                          fontSize: 7,
                          letterSpacing: 1.35,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditorialGalleryTitle extends StatelessWidget {
  const _EditorialGalleryTitle({
    required this.trip,
    required this.dateRangeLabel,
    required this.copyIndex,
    this.left = 760,
    this.top = 284,
  });

  final TripGalleryItem trip;
  final String dateRangeLabel;
  final int copyIndex;
  final double left;
  final double top;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      width: 340,
      height: 190,
      child: Row(
        key: ValueKey<String>(
          'gallery-editorial-title-${trip.slug}-$copyIndex',
        ),
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          RotatedBox(
            quarterTurns: 3,
            child: Text(
              dateRangeLabel,
              style: const TextStyle(
                fontFamily: 'Georgia',
                color: Color(0xBFDCCEB7),
                fontSize: 9,
                letterSpacing: 1.2,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text(
                  'MEMORIES OF',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    color: EverAfterColors.brass,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.3,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 12),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    trip.name.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Georgia',
                      color: EverAfterColors.agedPaper,
                      fontSize: 48,
                      height: 0.92,
                      letterSpacing: 3.6,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'IN MOTION',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    color: EverAfterColors.agedPaper,
                    fontSize: 22,
                    letterSpacing: 4.4,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _FrameKind { oval, circular, horizontalOval, portrait, landscape }

Rect _baroqueFramePhotoRect(_FrameKind kind, Size size) {
  final normalizedRect = switch (kind) {
    _FrameKind.oval => const Rect.fromLTWH(0.2036, 0.2372, 0.5899, 0.5845),
    _FrameKind.circular => const Rect.fromLTWH(0.229, 0.228, 0.54, 0.54),
    _FrameKind.horizontalOval => const Rect.fromLTWH(
      0.1366,
      0.2243,
      0.7261,
      0.6036,
    ),
    _FrameKind.portrait => const Rect.fromLTWH(0.2317, 0.1941, 0.5408, 0.6755),
    _FrameKind.landscape => const Rect.fromLTWH(0.1324, 0.1709, 0.7336, 0.6667),
  };
  return Rect.fromLTWH(
    normalizedRect.left * size.width,
    normalizedRect.top * size.height,
    normalizedRect.width * size.width,
    normalizedRect.height * size.height,
  );
}

class _BaroqueMemoryFrame extends StatelessWidget {
  const _BaroqueMemoryFrame({
    required this.kind,
    required this.media,
    required this.alignment,
    required this.semanticsLabel,
    required this.locationLabel,
    required this.mediaIndex,
    this.imageViewportKey,
    this.playVideos = false,
    this.slideshowId,
    this.showFrame = true,
    this.muted = true,
  });

  final _FrameKind kind;
  final List<GalleryMemoryAsset> media;
  final Alignment alignment;
  final String semanticsLabel;
  final String? locationLabel;
  final int mediaIndex;
  final Key? imageViewportKey;
  final bool playVideos;
  final String? slideshowId;
  final bool showFrame;
  final bool muted;

  String get _frameAsset => switch (kind) {
    _FrameKind.oval => 'assets/images/experience/baroque-frame-oval-hd.png',
    _FrameKind.circular =>
      'assets/images/experience/baroque-frame-circular-hd.png',
    _FrameKind.horizontalOval =>
      'assets/images/experience/baroque-frame-horizontal-oval-hd.png',
    _FrameKind.portrait =>
      'assets/images/experience/baroque-frame-portrait-hd.png',
    _FrameKind.landscape =>
      'assets/images/experience/baroque-frame-landscape-hd.png',
  };

  Widget _frameImage({Key? key}) {
    return Image.asset(
      _frameAsset,
      key: key,
      fit: BoxFit.fill,
      filterQuality: FilterQuality.high,
      isAntiAlias: true,
      excludeFromSemantics: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: semanticsLabel,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          final selectedMedia = media[mediaIndex];
          final mediaAlignment = Alignment(
            selectedMedia.alignmentX ?? alignment.x,
            selectedMedia.alignmentY ?? alignment.y,
          );
          final imageRect = _baroqueFramePhotoRect(kind, size);

          final mediaStack = Stack(
            key: ValueKey<String>('${selectedMedia.assetPath}-$playVideos'),
            fit: StackFit.expand,
            children: <Widget>[
              if (selectedMedia.isVideo && playVideos)
                _LoopingMemoryVideo(
                  muted: muted,
                  assetPath: selectedMedia.assetPath,
                  posterAssetPath: selectedMedia.displayAssetPath,
                  alignment: mediaAlignment,
                )
              else
                Transform.scale(
                  scale: selectedMedia.zoom,
                  child: Image.asset(
                    selectedMedia.displayAssetPath,
                    fit: BoxFit.cover,
                    alignment: mediaAlignment,
                    filterQuality: FilterQuality.high,
                    excludeFromSemantics: true,
                  ),
                ),
              if (selectedMedia.isVideo && !playVideos)
                const Center(child: _VideoMemoryBadge()),
            ],
          );
          final mediaSwitcher = selectedMedia.isVideo && playVideos
              ? KeyedSubtree(
                  key: const ValueKey('playing-memory-video-surface'),
                  child: mediaStack,
                )
              : AnimatedSwitcher(
                  key: slideshowId == null
                      ? null
                      : ValueKey<String>(
                          'gallery-memory-switcher-$slideshowId',
                        ),
                  duration: const Duration(milliseconds: 850),
                  switchInCurve: Curves.easeInOutCubic,
                  switchOutCurve: Curves.easeInOutCubic,
                  transitionBuilder: (child, animation) =>
                      FadeTransition(opacity: animation, child: child),
                  layoutBuilder: (currentChild, previousChildren) => Stack(
                    fit: StackFit.expand,
                    children: <Widget>[...previousChildren, ?currentChild],
                  ),
                  child: mediaStack,
                );
          final memory =
              memoryMediaUsesColorTreatment(
                isVideo: selectedMedia.isVideo,
                isPlaying: playVideos,
              )
              ? ColorFiltered(
                  key: const ValueKey('memory-media-color-treatment'),
                  colorFilter: const ColorFilter.mode(
                    Color(0x22051A2B),
                    BlendMode.multiply,
                  ),
                  child: mediaSwitcher,
                )
              : KeyedSubtree(
                  key: const ValueKey('playing-video-without-color-treatment'),
                  child: mediaSwitcher,
                );

          if (!showFrame) {
            final clippedMemory = ClipRRect(
              key: const ValueKey('focused-memory-media-only'),
              borderRadius: BorderRadius.circular(3),
              child: memory,
            );
            return KeyedSubtree(
              key: imageViewportKey,
              child: Align(
                alignment: Alignment.center,
                child: SizedBox(
                  width: selectedMedia.isVideo
                      ? math.min(
                          size.width,
                          size.height * _instagramReelAspectRatio,
                        )
                      : size.width,
                  height: size.height,
                  child: clippedMemory,
                ),
              ),
            );
          }

          return Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned.fill(
                child: IgnorePointer(
                  child: Transform.translate(
                    offset: Offset(0, size.height * 0.035),
                    child: ImageFiltered(
                      imageFilter: ui.ImageFilter.blur(sigmaX: 7, sigmaY: 9),
                      child: ColorFiltered(
                        colorFilter: const ColorFilter.mode(
                          Color(0xA61A0800),
                          BlendMode.srcIn,
                        ),
                        child: _frameImage(
                          key: const ValueKey('gallery-baroque-frame-shadow'),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fromRect(
                rect: imageRect,
                child: KeyedSubtree(
                  key: imageViewportKey,
                  child:
                      kind == _FrameKind.oval ||
                          kind == _FrameKind.circular ||
                          kind == _FrameKind.horizontalOval
                      ? ClipOval(
                          key: ValueKey<String>(
                            'gallery-${kind.name}-media-mask',
                          ),
                          child: ColoredBox(
                            color: const Color(0xFF171513),
                            child: memory,
                          ),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: ColoredBox(
                            color: const Color(0xFF171513),
                            child: memory,
                          ),
                        ),
                ),
              ),
              Positioned.fill(
                child: _frameImage(
                  key: ValueKey<String>('gallery-${kind.name}-baroque-frame'),
                ),
              ),
              if (locationLabel case final label?)
                Positioned(
                  left: size.width * 0.17,
                  right: size.width * 0.17,
                  bottom: -4,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xF20D1D2A),
                      border: Border.all(
                        color: EverAfterColors.brass.withValues(alpha: 0.78),
                        width: 0.8,
                      ),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(
                          color: Color(0x99000000),
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 3,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          label.toUpperCase(),
                          maxLines: 1,
                          style: const TextStyle(
                            fontFamily: 'Georgia',
                            color: Color(0xFFE7D9B8),
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _VideoMemoryBadge extends StatelessWidget {
  const _VideoMemoryBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const ValueKey('video-memory-badge'),
      decoration: BoxDecoration(
        color: const Color(0xB30D1D2A),
        shape: BoxShape.circle,
        border: Border.all(
          color: EverAfterColors.brass.withValues(alpha: 0.86),
          width: 1.2,
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x99000000), blurRadius: 8),
        ],
      ),
      child: const Padding(
        padding: EdgeInsets.all(7),
        child: Icon(
          Icons.play_arrow_rounded,
          color: Color(0xFFF2E4C4),
          size: 18,
        ),
      ),
    );
  }
}

class _LoopingMemoryVideo extends StatelessWidget {
  const _LoopingMemoryVideo({
    required this.assetPath,
    required this.posterAssetPath,
    required this.alignment,
    this.muted = true,
  });

  final String assetPath;
  final String posterAssetPath;
  final Alignment alignment;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Image.asset(
          posterAssetPath,
          fit: BoxFit.cover,
          alignment: alignment,
          filterQuality: FilterQuality.high,
          excludeFromSemantics: true,
        ),
        WebMemoryVideoSurface(assetPath: assetPath, muted: muted),
      ],
    );
  }
}

double _interval(
  double progress, {
  required double begin,
  required double end,
  Curve curve = Curves.linear,
}) {
  if (progress <= begin) {
    return 0;
  }
  if (progress >= end) {
    return 1;
  }
  return curve.transform((progress - begin) / (end - begin));
}
