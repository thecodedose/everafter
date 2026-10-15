import 'dart:convert';
import 'dart:math' as math;

import 'package:everafter/services/global_gallery_layout_file.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum GalleryFrameStyle { oval, circular, portrait, landscape, horizontalOval }

const double horizontalOvalFrameAspectRatio = 25 / 17;
const double circularFrameAspectRatio = 1;
const double featuredCircularFrameSize = 220;

const double galleryEditorialTitleLeft = 4348;
const double landscapeApertureWidth = 0.7336;
const double landscapeApertureHeight = 0.6667;
const double portraitApertureWidth = 0.5408;
const double portraitApertureHeight = 0.6755;

double photoFrameAspectRatio(double photoAspectRatio, {required bool landscape}) =>
    photoAspectRatio * (landscape
        ? landscapeApertureHeight / landscapeApertureWidth
        : portraitApertureHeight / portraitApertureWidth);

@immutable
class GalleryPhotoEdit {
  const GalleryPhotoEdit({
    required this.assetPath,
    this.alignmentX = 0,
    this.alignmentY = 0,
    this.zoom = 1,
  });

  final String assetPath;
  final double alignmentX;
  final double alignmentY;
  final double zoom;

  GalleryPhotoEdit copyWith({
    double? alignmentX,
    double? alignmentY,
    double? zoom,
  }) {
    return GalleryPhotoEdit(
      assetPath: assetPath,
      alignmentX: alignmentX ?? this.alignmentX,
      alignmentY: alignmentY ?? this.alignmentY,
      zoom: zoom ?? this.zoom,
    );
  }

  Map<String, Object> toJson() => <String, Object>{
    'assetPath': assetPath,
    'alignmentX': alignmentX,
    'alignmentY': alignmentY,
    'zoom': zoom,
  };

  factory GalleryPhotoEdit.fromJson(Map<String, dynamic> json) {
    return GalleryPhotoEdit(
      assetPath: json['assetPath'] as String,
      alignmentX: (json['alignmentX'] as num?)?.toDouble() ?? 0,
      alignmentY: (json['alignmentY'] as num?)?.toDouble() ?? 0,
      zoom: (json['zoom'] as num?)?.toDouble() ?? 1,
    );
  }
}

@immutable
class GalleryFramePlacement {
  const GalleryFramePlacement({
    required this.id,
    required this.memoryIndex,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.style,
    required this.alignmentX,
    required this.alignmentY,
    this.scale = 1,
    this.angle = 0,
    this.portrait = false,
    this.visible = true,
    this.title,
    this.photoAssetPaths = const <String>[],
    this.photoEdits = const <GalleryPhotoEdit>[],
    this.lockAspectRatio = true,
    this.isCustom = false,
  });

  final String id;
  final int memoryIndex;
  final double left;
  final double top;
  final double width;
  final double height;
  final GalleryFrameStyle style;
  final double alignmentX;
  final double alignmentY;
  final double scale;
  final double angle;
  final bool portrait;
  final bool visible;
  final String? title;
  final List<String> photoAssetPaths;
  final List<GalleryPhotoEdit> photoEdits;
  final bool lockAspectRatio;
  final bool isCustom;

  List<GalleryPhotoEdit> get effectivePhotoEdits => photoEdits.isNotEmpty
      ? photoEdits
      : <GalleryPhotoEdit>[
          for (final assetPath in photoAssetPaths)
            GalleryPhotoEdit(assetPath: assetPath),
        ];

  GalleryFramePlacement copyWith({
    double? left,
    double? top,
    double? width,
    double? height,
    GalleryFrameStyle? style,
    double? alignmentX,
    double? alignmentY,
    double? scale,
    double? angle,
    bool? portrait,
    bool? visible,
    String? title,
    List<String>? photoAssetPaths,
    List<GalleryPhotoEdit>? photoEdits,
    bool? lockAspectRatio,
    bool? isCustom,
  }) {
    final nextPhotoAssetPaths = photoAssetPaths ?? this.photoAssetPaths;
    return GalleryFramePlacement(
      id: id,
      memoryIndex: memoryIndex,
      left: left ?? this.left,
      top: top ?? this.top,
      width: width ?? this.width,
      height: height ?? this.height,
      style: style ?? this.style,
      alignmentX: alignmentX ?? this.alignmentX,
      alignmentY: alignmentY ?? this.alignmentY,
      scale: scale ?? this.scale,
      angle: angle ?? this.angle,
      portrait: portrait ?? this.portrait,
      visible: visible ?? this.visible,
      title: title ?? this.title,
      photoAssetPaths: nextPhotoAssetPaths,
      photoEdits:
          photoEdits ??
          (photoAssetPaths == null
              ? this.photoEdits
              : <GalleryPhotoEdit>[
                  for (final assetPath in nextPhotoAssetPaths)
                    GalleryPhotoEdit(assetPath: assetPath),
                ]),
      lockAspectRatio: lockAspectRatio ?? this.lockAspectRatio,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  Map<String, Object> toJson() => <String, Object>{
    'id': id,
    'memoryIndex': memoryIndex,
    'left': left,
    'top': top,
    'width': width,
    'height': height,
    'style': style.name,
    'alignmentX': alignmentX,
    'alignmentY': alignmentY,
    'scale': scale,
    'angle': angle,
    'portrait': portrait,
    'visible': visible,
    'title': title ?? '',
    'photoAssetPaths': photoAssetPaths,
    'photoEdits': photoEdits.map((edit) => edit.toJson()).toList(),
    'lockAspectRatio': lockAspectRatio,
    'isCustom': isCustom,
  };

  GalleryFramePlacement normalizedOrientation() {
    if (style == GalleryFrameStyle.circular) {
      return this;
    }
    final shouldBeHorizontal =
        style == GalleryFrameStyle.landscape ||
        style == GalleryFrameStyle.horizontalOval;
    final isHorizontal = width >= height;
    if (shouldBeHorizontal == isHorizontal) {
      return this;
    }
    return copyWith(
      width: height,
      height: width,
      portrait: !shouldBeHorizontal,
    );
  }

  GalleryFramePlacement normalizedArtworkAspectRatio() {
    final oriented = normalizedOrientation();
    final targetAspectRatio = switch (oriented.style) {
      GalleryFrameStyle.horizontalOval => horizontalOvalFrameAspectRatio,
      GalleryFrameStyle.circular => circularFrameAspectRatio,
      _ => null,
    };
    if (targetAspectRatio == null ||
        (oriented.width / oriented.height - targetAspectRatio).abs() < 0.001) {
      return oriented;
    }
    final centerY = oriented.top + oriented.height / 2;
    final correctedHeight = oriented.width / targetAspectRatio;
    return oriented.copyWith(
      top: centerY - correctedHeight / 2,
      height: correctedHeight,
      portrait: false,
    );
  }

  factory GalleryFramePlacement.fromJson(Map<String, dynamic> json) {
    return GalleryFramePlacement(
      id: json['id'] as String,
      memoryIndex: json['memoryIndex'] as int,
      left: (json['left'] as num).toDouble(),
      top: (json['top'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      style: GalleryFrameStyle.values.byName(json['style'] as String),
      alignmentX: (json['alignmentX'] as num).toDouble(),
      alignmentY: (json['alignmentY'] as num).toDouble(),
      scale: (json['scale'] as num?)?.toDouble() ?? 1,
      angle: (json['angle'] as num?)?.toDouble() ?? 0,
      portrait: json['portrait'] as bool? ?? false,
      visible: json['visible'] as bool? ?? true,
      title: switch (json['title']) {
        final String value when value.isNotEmpty => value,
        _ => null,
      },
      photoAssetPaths:
          (json['photoAssetPaths'] as List<dynamic>? ?? <dynamic>[])
              .cast<String>(),
      photoEdits: (json['photoEdits'] as List<dynamic>? ?? <dynamic>[])
          .map(
            (item) => GalleryPhotoEdit.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      lockAspectRatio: json['lockAspectRatio'] as bool? ?? true,
      isCustom: json['isCustom'] as bool? ?? false,
    ).normalizedArtworkAspectRatio();
  }

  GalleryFramePlacement resized({double? width, double? height}) {
    if (!lockAspectRatio || (width == null && height == null)) {
      return copyWith(width: width, height: height);
    }
    final aspectRatio = this.width / this.height;
    if (width != null) {
      return copyWith(width: width, height: width / aspectRatio);
    }
    return copyWith(width: height! * aspectRatio, height: height);
  }
}

@immutable
class GalleryTrinketPlacement {
  const GalleryTrinketPlacement({
    required this.id,
    required this.assetName,
    required this.label,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    this.angle = 0,
    this.visible = true,
    this.isCustom = false,
  });

  final String id;
  final String assetName;
  final String label;
  final double left;
  final double top;
  final double width;
  final double height;
  final double angle;
  final bool visible;
  final bool isCustom;

  GalleryTrinketPlacement copyWith({
    String? assetName,
    double? left,
    double? top,
    double? width,
    double? height,
    double? angle,
    bool? visible,
    bool? isCustom,
  }) {
    return GalleryTrinketPlacement(
      id: id,
      assetName: assetName ?? this.assetName,
      label: label,
      left: left ?? this.left,
      top: top ?? this.top,
      width: width ?? this.width,
      height: height ?? this.height,
      angle: angle ?? this.angle,
      visible: visible ?? this.visible,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'assetName': assetName,
    'label': label,
    'left': left,
    'top': top,
    'width': width,
    'height': height,
    'angle': angle,
    'visible': visible,
    'isCustom': isCustom,
  };

  factory GalleryTrinketPlacement.fromJson(Map<String, dynamic> json) {
    return GalleryTrinketPlacement(
      id: json['id'] as String,
      assetName: json['assetName'] as String,
      label: json['label'] as String,
      left: (json['left'] as num).toDouble(),
      top: (json['top'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      angle: (json['angle'] as num?)?.toDouble() ?? 0,
      visible: json['visible'] as bool? ?? true,
      isCustom: json['isCustom'] as bool? ?? false,
    );
  }
}

@immutable
class GalleryInstagramPlacement {
  const GalleryInstagramPlacement({
    required this.id,
    required this.postIndex,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.style,
    required this.angle,
    this.scale = 1.5,
    this.visible = true,
  });

  final String id;
  final int postIndex;
  final double left;
  final double top;
  final double width;
  final double height;
  final GalleryFrameStyle style;
  final double angle;
  final double scale;
  final bool visible;

  GalleryInstagramPlacement copyWith({
    double? left,
    double? top,
    double? width,
    double? height,
    GalleryFrameStyle? style,
    double? angle,
    double? scale,
    bool? visible,
  }) {
    return GalleryInstagramPlacement(
      id: id,
      postIndex: postIndex,
      left: left ?? this.left,
      top: top ?? this.top,
      width: width ?? this.width,
      height: height ?? this.height,
      style: style ?? this.style,
      angle: angle ?? this.angle,
      scale: scale ?? this.scale,
      visible: visible ?? this.visible,
    );
  }

  Map<String, Object> toJson() => <String, Object>{
    'id': id,
    'postIndex': postIndex,
    'left': left,
    'top': top,
    'width': width,
    'height': height,
    'style': style.name,
    'angle': angle,
    'scale': scale,
    'visible': visible,
  };

  factory GalleryInstagramPlacement.fromJson(Map<String, dynamic> json) {
    return GalleryInstagramPlacement(
      id: json['id'] as String,
      postIndex: json['postIndex'] as int,
      left: (json['left'] as num).toDouble(),
      top: (json['top'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      style: GalleryFrameStyle.values.byName(json['style'] as String),
      angle: 0,
      scale: (json['scale'] as num?)?.toDouble() ?? 1.5,
      visible: json['visible'] as bool? ?? true,
    );
  }
}

@immutable
class GalleryTripLayout {
  const GalleryTripLayout({
    required this.frames,
    required this.trinkets,
    required this.instagramPosts,
    required this.stripWidth,
    this.leadingTrim = 0,
    this.travelStartDate,
    this.travelEndDate,
    this.layoutVersion = 2,
    this.mediaLayoutVersion = 0,
    this.editorialTitleLeft = galleryEditorialTitleLeft,
  });

  final List<GalleryFramePlacement> frames;
  final List<GalleryTrinketPlacement> trinkets;
  final List<GalleryInstagramPlacement> instagramPosts;
  final double stripWidth;
  final double leadingTrim;
  final String? travelStartDate;
  final String? travelEndDate;
  final int layoutVersion;
  final int mediaLayoutVersion;
  final double editorialTitleLeft;

  DateTime? get travelStart => DateTime.tryParse(travelStartDate ?? '');
  DateTime? get travelEnd => DateTime.tryParse(travelEndDate ?? '');

  String? effectiveStartDateLabel(String? fallback) {
    final date = travelStart;
    return date == null ? fallback : formatGalleryTravelDate(date);
  }

  String? effectiveEndDateLabel(String? fallback) {
    final date = travelEnd;
    return date == null ? fallback : formatGalleryTravelDate(date);
  }

  String effectiveDateRangeLabel(String fallback) {
    final start = travelStart;
    final end = travelEnd;
    return start != null && end != null
        ? '${formatGalleryTravelDate(start)}  →  '
              '${formatGalleryTravelDate(end)}'
        : fallback;
  }

  String? effectiveDurationLabel(int? fallbackDays) {
    final start = travelStart;
    final end = travelEnd;
    if (start != null && end != null) {
      return '${end.difference(start).inDays + 1} DAYS';
    }
    return fallbackDays == null ? null : '$fallbackDays DAYS';
  }

  GalleryTripLayout copyWith({
    List<GalleryFramePlacement>? frames,
    List<GalleryTrinketPlacement>? trinkets,
    List<GalleryInstagramPlacement>? instagramPosts,
    double? stripWidth,
    double? leadingTrim,
    String? travelStartDate,
    String? travelEndDate,
    int? layoutVersion,
    int? mediaLayoutVersion,
    double? editorialTitleLeft,
    bool clearTravelDates = false,
  }) {
    return GalleryTripLayout(
      frames: frames ?? this.frames,
      trinkets: trinkets ?? this.trinkets,
      instagramPosts: instagramPosts ?? this.instagramPosts,
      stripWidth: stripWidth ?? this.stripWidth,
      leadingTrim: leadingTrim ?? this.leadingTrim,
      travelStartDate: clearTravelDates
          ? null
          : travelStartDate ?? this.travelStartDate,
      travelEndDate: clearTravelDates
          ? null
          : travelEndDate ?? this.travelEndDate,
      layoutVersion: layoutVersion ?? this.layoutVersion,
      mediaLayoutVersion: mediaLayoutVersion ?? this.mediaLayoutVersion,
      editorialTitleLeft: editorialTitleLeft ?? this.editorialTitleLeft,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'frames': frames.map((frame) => frame.toJson()).toList(),
    'trinkets': trinkets.map((trinket) => trinket.toJson()).toList(),
    'instagramPosts': instagramPosts.map((post) => post.toJson()).toList(),
    'stripWidth': stripWidth,
    'leadingTrim': leadingTrim,
    'travelStartDate': travelStartDate,
    'travelEndDate': travelEndDate,
    'layoutVersion': layoutVersion,
    'mediaLayoutVersion': mediaLayoutVersion,
    'editorialTitleLeft': editorialTitleLeft,
  };

  factory GalleryTripLayout.fromJson(
    Map<String, dynamic> json, {
    required String tripSlug,
    required double fallbackStripWidth,
  }) {
    final layout = GalleryTripLayout(
      frames: (json['frames'] as List<dynamic>)
          .map(
            (item) =>
                GalleryFramePlacement.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      stripWidth:
          (json['stripWidth'] as num?)?.toDouble() ?? fallbackStripWidth,
      trinkets: (json['trinkets'] as List<dynamic>? ?? <dynamic>[])
          .map(
            (item) =>
                GalleryTrinketPlacement.fromJson(item as Map<String, dynamic>),
          )
          .where((item) => _isLocalTrinketSource(item.assetName))
          .toList(),
      instagramPosts:
          (json['instagramPosts'] as List<dynamic>?)
              ?.map(
                (item) => GalleryInstagramPlacement.fromJson(
                  item as Map<String, dynamic>,
                ),
              )
              .toList() ??
          defaultInstagramPlacementsFor(tripSlug),
      leadingTrim: (json['leadingTrim'] as num?)?.toDouble() ?? 0,
      travelStartDate: json['travelStartDate'] as String?,
      travelEndDate: json['travelEndDate'] as String?,
      layoutVersion: (json['layoutVersion'] as num?)?.toInt() ?? 1,
      mediaLayoutVersion: (json['mediaLayoutVersion'] as num?)?.toInt() ?? 0,
      editorialTitleLeft:
          (json['editorialTitleLeft'] as num?)?.toDouble() ?? galleryEditorialTitleLeft,
    );
    final instagramUpgraded = layout.layoutVersion < 2
        ? _upgradeVideoPostFrameScale(layout)
        : layout;
    final circularUpgraded = instagramUpgraded.layoutVersion < 3
        ? _upgradeCircularFrameMix(instagramUpgraded)
        : instagramUpgraded;
    return circularUpgraded.layoutVersion < 4
        ? _upgradeFeaturedCircularFrameSize(circularUpgraded)
        : circularUpgraded;
  }
}

GalleryTripLayout _upgradeVideoPostFrameScale(GalleryTripLayout layout) {
  final posts = layout.instagramPosts;

  double addedWidth(GalleryInstagramPlacement post) =>
      post.width * (post.scale - 1);

  double shiftBefore(double left) => posts
      .where((post) => post.left < left)
      .fold(0, (shift, post) => shift + addedWidth(post));

  final totalAddedWidth = posts.fold(
    0.0,
    (shift, post) => shift + addedWidth(post),
  );

  return layout.copyWith(
    frames: <GalleryFramePlacement>[
      for (final frame in layout.frames)
        frame.copyWith(left: frame.left + shiftBefore(frame.left)),
    ],
    trinkets: <GalleryTrinketPlacement>[
      for (final trinket in layout.trinkets)
        trinket.copyWith(left: trinket.left + shiftBefore(trinket.left)),
    ],
    instagramPosts: <GalleryInstagramPlacement>[
      for (final post in posts)
        post.copyWith(
          left: post.left + shiftBefore(post.left) + addedWidth(post) / 2,
        ),
    ],
    stripWidth: layout.stripWidth + totalAddedWidth,
    layoutVersion: 2,
  );
}

GalleryTripLayout _upgradeCircularFrameMix(GalleryTripLayout layout) {
  GalleryFramePlacement circularFrame(GalleryFramePlacement frame) {
    if (frame.id != 'frame-2' && frame.id != 'frame-8') {
      return frame;
    }
    final size = math.min(frame.width, frame.height);
    final centerY = frame.top + frame.height / 2;
    return frame.copyWith(
      top: centerY - size / 2,
      width: size,
      height: size,
      style: GalleryFrameStyle.circular,
      portrait: false,
    );
  }

  GalleryInstagramPlacement circularPost(GalleryInstagramPlacement post) {
    if (post.id != 'instagram-3' && post.id != 'instagram-6') {
      return post;
    }
    final size = math.min(post.width, post.height);
    final centerY = post.top + post.height / 2;
    return post.copyWith(
      top: centerY - size / 2,
      width: size,
      height: size,
      style: GalleryFrameStyle.circular,
    );
  }

  return layout.copyWith(
    frames: layout.frames.map(circularFrame).toList(growable: false),
    instagramPosts: layout.instagramPosts
        .map(circularPost)
        .toList(growable: false),
    layoutVersion: 3,
  );
}

GalleryTripLayout _upgradeFeaturedCircularFrameSize(GalleryTripLayout layout) {
  final firstCircle = layout.frames
      .where((frame) => frame.id == 'frame-2')
      .firstOrNull;
  final secondCircle = layout.frames
      .where((frame) => frame.id == 'frame-8')
      .firstOrNull;
  final reflowVideoWall =
      layout.instagramPosts.isNotEmpty &&
      firstCircle != null &&
      secondCircle != null;

  double reflowOffset(double left) {
    if (!reflowVideoWall) {
      return 0;
    }
    var offset = 0.0;
    if (left > firstCircle.left) {
      offset += 105;
    }
    if (left > secondCircle.left) {
      offset += 130;
    }
    return offset;
  }

  GalleryFramePlacement enlargeFeaturedCircle(GalleryFramePlacement frame) {
    if ((frame.id != 'frame-2' && frame.id != 'frame-8') ||
        frame.style != GalleryFrameStyle.circular) {
      return frame;
    }
    final centerX = frame.left + frame.width / 2;
    final centerY = frame.top + frame.height / 2;
    final horizontalNudge = layout.instagramPosts.isEmpty
        ? 0.0
        : frame.id == 'frame-8'
        ? 40.0
        : 24.0;
    return frame.copyWith(
      left:
          centerX -
          featuredCircularFrameSize / 2 +
          horizontalNudge +
          reflowOffset(frame.left),
      top: centerY - featuredCircularFrameSize / 2,
      width: featuredCircularFrameSize,
      height: featuredCircularFrameSize,
    );
  }

  return layout.copyWith(
    frames: <GalleryFramePlacement>[
      for (final frame in layout.frames)
        if (frame.id == 'frame-2' || frame.id == 'frame-8')
          enlargeFeaturedCircle(frame)
        else
          frame.copyWith(left: frame.left + reflowOffset(frame.left)),
    ],
    trinkets: <GalleryTrinketPlacement>[
      for (final trinket in layout.trinkets)
        trinket.copyWith(left: trinket.left + reflowOffset(trinket.left)),
    ],
    instagramPosts: <GalleryInstagramPlacement>[
      for (final post in layout.instagramPosts)
        post.copyWith(left: post.left + reflowOffset(post.left)),
    ],
    stripWidth: layout.stripWidth + (reflowVideoWall ? 235 : 0),
    layoutVersion: 4,
  );
}

class GalleryLayoutStore extends ChangeNotifier {
  @visibleForTesting
  GalleryLayoutStore.forTesting(this._globalFile);
  GalleryLayoutStore._() : _globalFile = createGlobalGalleryLayoutFile();

  static final GalleryLayoutStore instance = GalleryLayoutStore._();
  static const String bundledGlobalLayoutPath =
      'assets/data/gallery_layouts.json';

  final GlobalGalleryLayoutFile _globalFile;
  Map<String, GalleryTripLayout> _bundledLayouts =
      <String, GalleryTripLayout>{};
  Map<String, GalleryTripLayout> _layouts = <String, GalleryTripLayout>{};
  bool _hasUnsavedChanges = false;

  bool get hasUnsavedChanges => _hasUnsavedChanges;
  bool get editsGlobalLayout => true;
  String? get globalSourceFileName => _globalFile.fileName;

  GalleryTripLayout layoutFor(String tripSlug) =>
      _layouts[tripSlug] ?? defaultGalleryLayoutFor(tripSlug);

  Future<void> load() async {
    await _loadBundledGlobalLayouts();
    _layouts = Map<String, GalleryTripLayout>.of(_bundledLayouts);
    _hasUnsavedChanges = false;
    notifyListeners();
  }

  /// Establish a reset/export baseline with one distinct photo in each frame.
  /// Called once after the asset manifest and saved layout are loaded.
  void bindTripMedia(
    Map<String, List<String>> photosByTrip, {
    Map<String, int> videoCountsByTrip = const <String, int>{},
    Map<String, double> photoAspectRatios = const <String, double>{},
  }) {
    for (final entry in photosByTrip.entries) {
      final layout = singlePhotoLayoutFor(
        layoutFor(entry.key),
        entry.value,
        videoCount: videoCountsByTrip[entry.key] ?? 0,
        photoAspectRatios: photoAspectRatios,
      );
      _layouts[entry.key] = layout;
      _bundledLayouts[entry.key] = layout;
    }
    _hasUnsavedChanges = false;
    notifyListeners();
  }

  void updateFrame(String tripSlug, GalleryFramePlacement frame) {
    final layout = layoutFor(tripSlug);
    _layouts = <String, GalleryTripLayout>{
      ..._layouts,
      tripSlug: layout.copyWith(
        frames: <GalleryFramePlacement>[
          for (final current in layout.frames)
            if (current.id == frame.id) frame else current,
        ],
      ),
    };
    _markChanged();
  }

  GalleryFramePlacement addFrame(String tripSlug) {
    final layout = layoutFor(tripSlug);
    final frame = GalleryFramePlacement(
      id: _nextCustomId('custom-frame', layout.frames.map((item) => item.id)),
      memoryIndex:
          layout.frames.map((item) => item.memoryIndex).fold(0, math.max) + 1,
      left: layout.leadingTrim + 640,
      top: 269,
      width: 190,
      height: 272,
      style: GalleryFrameStyle.oval,
      alignmentX: 0,
      alignmentY: 0,
      portrait: true,
      title: 'Untitled memory',
      isCustom: true,
    );
    _layouts = <String, GalleryTripLayout>{
      ..._layouts,
      tripSlug: layout.copyWith(
        frames: <GalleryFramePlacement>[...layout.frames, frame],
      ),
    };
    _markChanged();
    return frame;
  }

  void removeFrame(String tripSlug, String frameId) {
    final layout = layoutFor(tripSlug);
    _layouts = <String, GalleryTripLayout>{
      ..._layouts,
      tripSlug: layout.copyWith(
        frames: layout.frames
            .where((item) => item.id != frameId)
            .toList(growable: false),
      ),
    };
    _markChanged();
  }

  void updateTrinket(String tripSlug, GalleryTrinketPlacement trinket) {
    final layout = layoutFor(tripSlug);
    _layouts = <String, GalleryTripLayout>{
      ..._layouts,
      tripSlug: layout.copyWith(
        trinkets: <GalleryTrinketPlacement>[
          for (final current in layout.trinkets)
            if (current.id == trinket.id) trinket else current,
        ],
      ),
    };
    _markChanged();
  }

  GalleryTrinketPlacement addTrinket(
    String tripSlug, {
    required String assetName,
    required String label,
  }) {
    final layout = layoutFor(tripSlug);
    final trinket = GalleryTrinketPlacement(
      id: _nextCustomId(
        'custom-trinket',
        layout.trinkets.map((item) => item.id),
      ),
      assetName: assetName,
      label: label,
      left: layout.leadingTrim + 510,
      top: 230,
      width: 300,
      height: 340,
      isCustom: true,
    );
    _layouts = <String, GalleryTripLayout>{
      ..._layouts,
      tripSlug: layout.copyWith(
        trinkets: <GalleryTrinketPlacement>[...layout.trinkets, trinket],
      ),
    };
    _markChanged();
    return trinket;
  }

  void removeTrinket(String tripSlug, String trinketId) {
    final layout = layoutFor(tripSlug);
    _layouts = <String, GalleryTripLayout>{
      ..._layouts,
      tripSlug: layout.copyWith(
        trinkets: layout.trinkets
            .where((item) => item.id != trinketId)
            .toList(growable: false),
      ),
    };
    _markChanged();
  }

  void updateInstagramPost(
    String tripSlug,
    GalleryInstagramPlacement instagramPost,
  ) {
    final layout = layoutFor(tripSlug);
    _layouts = <String, GalleryTripLayout>{
      ..._layouts,
      tripSlug: layout.copyWith(
        instagramPosts: <GalleryInstagramPlacement>[
          for (final current in layout.instagramPosts)
            if (current.id == instagramPost.id)
              instagramPost.copyWith(angle: 0)
            else
              current,
        ],
      ),
    };
    _markChanged();
  }

  void updateTravelDates(
    String tripSlug, {
    required DateTime? start,
    required DateTime? end,
  }) {
    final layout = layoutFor(tripSlug);
    _layouts = <String, GalleryTripLayout>{
      ..._layouts,
      tripSlug: layout.copyWith(
        travelStartDate: start == null ? null : _dateOnlyIso(start),
        travelEndDate: end == null ? null : _dateOnlyIso(end),
        clearTravelDates: start == null || end == null,
      ),
    };
    _markChanged();
  }

  void fitTripToContents(String tripSlug) {
    final layout = layoutFor(tripSlug);
    const gutter = 50.0;
    var leftEdge = layout.editorialTitleLeft;
    var rightEdge = leftEdge + 340;
    for (final frame in layout.frames.where((item) => item.visible)) {
      final renderedWidth = frame.width * 2.3 * frame.scale;
      leftEdge = math.min(
        leftEdge,
        frame.left - (renderedWidth - frame.width) / 2,
      );
      rightEdge = math.max(
        rightEdge,
        frame.left + (renderedWidth + frame.width) / 2,
      );
    }
    for (final trinket in layout.trinkets.where((item) => item.visible)) {
      leftEdge = math.min(leftEdge, trinket.left);
      rightEdge = math.max(rightEdge, trinket.left + trinket.width);
    }
    for (final post in layout.instagramPosts.where((item) => item.visible)) {
      final renderedWidth = post.width * post.scale;
      leftEdge = math.min(
        leftEdge,
        post.left - (renderedWidth - post.width) / 2,
      );
      rightEdge = math.max(
        rightEdge,
        post.left + (renderedWidth + post.width) / 2,
      );
    }
    _layouts = <String, GalleryTripLayout>{
      ..._layouts,
      tripSlug: layout.copyWith(
        leadingTrim: leftEdge - gutter,
        stripWidth: rightEdge - leftEdge + gutter * 2,
      ),
    };
    _markChanged();
  }

  Future<void> save() async {
    await _globalFile.save(encodeGlobalGalleryLayoutDocument(_layouts));
    _hasUnsavedChanges = false;
    notifyListeners();
  }

  Future<void> resetTrip(String tripSlug) async {
    _layouts = <String, GalleryTripLayout>{
      ..._layouts,
      tripSlug: _bundledLayouts[tripSlug] ?? defaultGalleryLayoutFor(tripSlug),
    };
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  Future<void> _loadBundledGlobalLayouts() async {
    try {
      final contents = await rootBundle.loadString(bundledGlobalLayoutPath);
      _bundledLayouts = decodeGlobalGalleryLayoutDocument(contents);
    } on Object {
      _bundledLayouts = <String, GalleryTripLayout>{};
    }
  }

  void _markChanged() {
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  String _nextCustomId(String prefix, Iterable<String> existingIds) {
    final existing = existingIds.toSet();
    var index = 1;
    while (existing.contains('$prefix-$index')) {
      index += 1;
    }
    return '$prefix-$index';
  }
}

/// Reuse existing frame styles/positions, then extend the same wall for extra
/// media. Explicit single-photo crops survive; multi-photo selections become
/// separate frames instead of a slideshow. No source JSON is overwritten.
GalleryTripLayout singlePhotoLayoutFor(
  GalleryTripLayout layout,
  List<String> photoPaths, {
  int videoCount = 0,
  Map<String, double> photoAspectRatios = const <String, double>{},
}) {
  final photos = photoPaths.toSet().toList(growable: false);
  final templates = layout.frames.isNotEmpty
      ? layout.frames
      : defaultGalleryLayoutFor('spain-2026').frames;
  final unassigned = layout.frames
      .where((frame) => frame.effectivePhotoEdits.isEmpty)
      .toList();
  final usedIds = <String>{};
  var cursor = layout.stripWidth + layout.leadingTrim;
  final frames = <GalleryFramePlacement>[];
  for (var index = 0; index < photos.length; index++) {
    final path = photos[index];
    GalleryFramePlacement? original;
    GalleryPhotoEdit? crop;
    for (final frame in layout.frames) {
      if (usedIds.contains(frame.id)) continue;
      final matching = frame.effectivePhotoEdits
          .where((edit) => edit.assetPath == path)
          .firstOrNull;
      if (matching != null) {
        original = frame;
        crop = matching;
        break;
      }
    }
    if (original == null && unassigned.isNotEmpty) {
      original = unassigned.removeAt(0);
    }
    if (original != null) {
      crop ??= GalleryPhotoEdit(
        assetPath: path,
        alignmentX: original.alignmentX,
        alignmentY: original.alignmentY,
      );
      usedIds.add(original.id);
      frames.add(original.copyWith(
        photoAssetPaths: <String>[path],
        photoEdits: <GalleryPhotoEdit>[crop],
      ));
      continue;
    }
    var template = templates[index % templates.length];
    final aspectRatio = photoAspectRatios[path];
    if (aspectRatio != null) {
      final landscape = aspectRatio >= 1;
      final height = landscape ? 181.0 : 254.0;
      template = template.copyWith(
        width: height * photoFrameAspectRatio(aspectRatio, landscape: landscape),
        height: height,
        top: 405 - height / 2,
        style: landscape ? GalleryFrameStyle.landscape : GalleryFrameStyle.portrait,
        portrait: !landscape,
        scale: 560 / (2.3 * height),
        angle: 0,
      );
    }
    var id = 'auto-photo-$index';
    while (usedIds.contains(id) || layout.frames.any((frame) => frame.id == id)) {
      id = '$id-extra';
    }
    final renderedWidth = template.width * 2.3 * template.scale;
    frames.add(GalleryFramePlacement(
      id: id,
      memoryIndex: index,
      left: cursor + (renderedWidth - template.width) / 2,
      top: template.top,
      width: template.width,
      height: template.height,
      style: template.style,
      alignmentX: template.alignmentX,
      alignmentY: template.alignmentY,
      scale: template.scale,
      angle: template.angle,
      portrait: template.portrait,
      photoAssetPaths: <String>[path],
      photoEdits: <GalleryPhotoEdit>[
        GalleryPhotoEdit(
          assetPath: path,
          alignmentX: template.alignmentX,
          alignmentY: template.alignmentY,
        ),
      ],
    ));
    usedIds.add(id);
    cursor += renderedWidth + 80;
  }
  final videoTemplates = layout.instagramPosts.isNotEmpty
      ? layout.instagramPosts
      : defaultInstagramPlacementsFor('spain-2026');
  final posts = <GalleryInstagramPlacement>[];
  for (var index = 0; index < videoCount; index++) {
    if (index < layout.instagramPosts.length) {
      posts.add(layout.instagramPosts[index]);
      continue;
    }
    final template = videoTemplates[index % videoTemplates.length];
    final renderedWidth = template.width * template.scale;
    posts.add(GalleryInstagramPlacement(
      id: 'auto-video-$index',
      postIndex: index,
      left: cursor + (renderedWidth - template.width) / 2,
      top: template.top,
      width: template.width,
      height: template.height,
      style: template.style,
      scale: template.scale,
      angle: 0,
    ));
    cursor += renderedWidth + 80;
  }
  var rightEdge = layout.editorialTitleLeft + 340;
  for (final frame in frames) {
    final renderedWidth = frame.width * 2.3 * frame.scale;
    rightEdge = math.max(rightEdge, frame.left + (renderedWidth + frame.width) / 2);
  }
  for (final post in posts) {
    final renderedWidth = post.width * post.scale;
    rightEdge = math.max(rightEdge, post.left + (renderedWidth + post.width) / 2);
  }
  for (final trinket in layout.trinkets) {
    rightEdge = math.max(rightEdge, trinket.left + trinket.width);
  }
  final bound = layout.copyWith(
    frames: frames,
    instagramPosts: posts,
    stripWidth: math.max(layout.stripWidth, rightEdge - layout.leadingTrim + 80),
  );
  // Reflow the old demonstration layout once. An exported layout carries the
  // marker so later editor positioning, sizing and spacing remain editable.
  if (layout.mediaLayoutVersion >= 2) return bound;
  const gap = 80.0;
  const renderedHeight = 560.0;
  const titleLeft = 72.0;
  var nextLeft = titleLeft + 340 + gap;
  final orientedFrames = <GalleryFramePlacement>[];
  for (final frame in bound.frames) {
    final path = frame.effectivePhotoEdits.single.assetPath;
    final aspectRatio = photoAspectRatios[path];
    final landscape = aspectRatio != null
        ? aspectRatio >= 1
        : frame.width >= frame.height;
    final height = landscape ? 181.0 : 254.0;
    final width = aspectRatio == null
        ? (landscape ? 226.0 : 178.0)
        : height * photoFrameAspectRatio(aspectRatio, landscape: landscape);
    final scale = renderedHeight / (2.3 * height);
    final renderedWidth = width * 2.3 * scale;
    orientedFrames.add(frame.copyWith(
      left: nextLeft + (renderedWidth - width) / 2,
      top: 405 - height / 2,
      width: width,
      height: height,
      scale: scale,
      style: landscape ? GalleryFrameStyle.landscape : GalleryFrameStyle.portrait,
      portrait: !landscape,
      angle: 0,
    ));
    nextLeft += renderedWidth + gap;
  }
  final videoPlacements = <GalleryInstagramPlacement>[];
  for (final post in bound.instagramPosts) {
    final scale = renderedHeight / post.height;
    final renderedWidth = post.width * scale;
    videoPlacements.add(post.copyWith(
      left: nextLeft + (renderedWidth - post.width) / 2,
      top: 405 - post.height / 2,
      scale: scale,
      angle: 0,
    ));
    nextLeft += renderedWidth + gap;
  }
  final trinkets = <GalleryTrinketPlacement>[];
  for (final trinket in bound.trinkets) {
    trinkets.add(trinket.copyWith(left: nextLeft));
    nextLeft += trinket.width + gap;
  }
  return bound.copyWith(
    frames: orientedFrames,
    instagramPosts: videoPlacements,
    trinkets: trinkets,
    editorialTitleLeft: titleLeft,
    leadingTrim: 0,
    stripWidth: nextLeft - gap + 80,
    mediaLayoutVersion: 2,
  );
}

Map<String, GalleryTripLayout> decodeGlobalGalleryLayoutDocument(
  String contents,
) {
  final document = jsonDecode(contents);
  if (document is! Map<String, dynamic>) {
    throw const FormatException('Global gallery layout must be a JSON object.');
  }
  if (document['schemaVersion'] != 1) {
    throw const FormatException('Unsupported global gallery layout schema.');
  }
  final encodedLayouts = document['layouts'];
  if (encodedLayouts is! Map) {
    throw const FormatException('Global gallery layout is missing layouts.');
  }
  return <String, GalleryTripLayout>{
    for (final entry in encodedLayouts.entries)
      entry.key as String: GalleryTripLayout.fromJson(
        Map<String, dynamic>.from(entry.value as Map),
        tripSlug: entry.key as String,
        fallbackStripWidth: defaultGalleryStripWidthFor(entry.key as String),
      ),
  };
}

String encodeGlobalGalleryLayoutDocument(
  Map<String, GalleryTripLayout> layouts,
) {
  return '${const JsonEncoder.withIndent('  ').convert(<String, Object?>{
    'schemaVersion': 1,
    'layouts': <String, Object?>{for (final entry in layouts.entries) entry.key: entry.value.toJson()},
  })}\n';
}

bool _isLocalTrinketSource(String source) =>
    source.startsWith('assets/') ||
    source.startsWith('data:image/png;base64,') ||
    source.startsWith('data:image/jpeg;base64,') ||
    source.startsWith('data:image/webp;base64,');

const Map<String, dynamic> _galleryWallTemplate = {
  "frames": [
    {
      "id": "frame-0",
      "memoryIndex": 0,
      "left": 135.0,
      "top": 269.0,
      "width": 190.0,
      "height": 272.0,
      "style": "oval",
      "alignmentX": 0.15,
      "alignmentY": -0.2,
      "scale": 0.9900000000000001,
      "angle": -0.012,
      "portrait": true,
      "visible": true,
      "title": "",
      "photoAssetPaths": [],
      "photoEdits": [],
      "lockAspectRatio": true,
      "isCustom": false,
    },
    {
      "id": "frame-1",
      "memoryIndex": 1,
      "left": 1329.0,
      "top": 278.0,
      "width": 178.0,
      "height": 254.0,
      "style": "portrait",
      "alignmentX": -0.22,
      "alignmentY": -0.05,
      "scale": 1.1880000000000002,
      "angle": 0.014,
      "portrait": true,
      "visible": true,
      "title": "",
      "photoAssetPaths": [],
      "photoEdits": [],
      "lockAspectRatio": true,
      "isCustom": false,
    },
    {
      "id": "frame-2",
      "memoryIndex": 2,
      "left": 2243.0,
      "top": 295.0,
      "width": 220.0,
      "height": 220.0,
      "style": "circular",
      "alignmentX": 0.28,
      "alignmentY": -0.18,
      "scale": 1.0120000000000002,
      "angle": -0.01,
      "portrait": false,
      "visible": true,
      "title": "",
      "photoAssetPaths": [],
      "photoEdits": [],
      "lockAspectRatio": true,
      "isCustom": false,
    },
    {
      "id": "frame-3",
      "memoryIndex": 3,
      "left": 3454.0,
      "top": 326.12,
      "width": 232.0,
      "height": 157.76,
      "style": "horizontalOval",
      "alignmentX": 0.2,
      "alignmentY": 0.08,
      "scale": 1.1770000000000003,
      "angle": 0.01,
      "portrait": false,
      "visible": true,
      "title": "",
      "photoAssetPaths": [],
      "photoEdits": [],
      "lockAspectRatio": true,
      "isCustom": false,
    },
    {
      "id": "frame-4",
      "memoryIndex": 4,
      "left": 4838.0,
      "top": 276.5,
      "width": 180.0,
      "height": 257.0,
      "style": "portrait",
      "alignmentX": -0.28,
      "alignmentY": 0.08,
      "scale": 1.056,
      "angle": 0.012,
      "portrait": true,
      "visible": true,
      "title": "",
      "photoAssetPaths": [],
      "photoEdits": [],
      "lockAspectRatio": true,
      "isCustom": false,
    },
    {
      "id": "frame-5",
      "memoryIndex": 5,
      "left": 5780.0,
      "top": 314.5,
      "width": 226.0,
      "height": 181.0,
      "style": "landscape",
      "alignmentX": 0.26,
      "alignmentY": -0.08,
      "scale": 1.1440000000000001,
      "angle": -0.008,
      "portrait": false,
      "visible": true,
      "title": "",
      "photoAssetPaths": [],
      "photoEdits": [],
      "lockAspectRatio": true,
      "isCustom": false,
    },
    {
      "id": "frame-6",
      "memoryIndex": 6,
      "left": 6388.0,
      "top": 314.5,
      "width": 226.0,
      "height": 181.0,
      "style": "landscape",
      "alignmentX": -0.18,
      "alignmentY": 0.14,
      "scale": 1.122,
      "angle": 0.009,
      "portrait": false,
      "visible": true,
      "title": "",
      "photoAssetPaths": [],
      "photoEdits": [],
      "lockAspectRatio": true,
      "isCustom": false,
    },
    {
      "id": "frame-7",
      "memoryIndex": 7,
      "left": 7560.0,
      "top": 278.0,
      "width": 178.0,
      "height": 254.0,
      "style": "portrait",
      "alignmentX": 0.2,
      "alignmentY": -0.12,
      "scale": 1.0120000000000002,
      "angle": -0.013,
      "portrait": true,
      "visible": true,
      "title": "",
      "photoAssetPaths": [],
      "photoEdits": [],
      "lockAspectRatio": true,
      "isCustom": false,
    },
    {
      "id": "frame-8",
      "memoryIndex": 8,
      "left": 8057.0,
      "top": 295.0,
      "width": 220.0,
      "height": 220.0,
      "style": "circular",
      "alignmentX": -0.2,
      "alignmentY": 0.12,
      "scale": 1.1880000000000002,
      "angle": 0.008,
      "portrait": false,
      "visible": true,
      "title": "",
      "photoAssetPaths": [],
      "photoEdits": [],
      "lockAspectRatio": true,
      "isCustom": false,
    },
    {
      "id": "frame-9",
      "memoryIndex": 9,
      "left": 9083.0,
      "top": 329.52,
      "width": 222.0,
      "height": 150.95999999999998,
      "style": "horizontalOval",
      "alignmentX": 0.18,
      "alignmentY": 0.12,
      "scale": 1.1440000000000001,
      "angle": -0.008,
      "portrait": false,
      "visible": true,
      "title": "",
      "photoAssetPaths": [],
      "photoEdits": [],
      "lockAspectRatio": true,
      "isCustom": false,
    },
    {
      "id": "frame-10",
      "memoryIndex": 10,
      "left": 9629.0,
      "top": 276.5,
      "width": 180.0,
      "height": 257.0,
      "style": "oval",
      "alignmentX": 0.08,
      "alignmentY": -0.16,
      "scale": 1.034,
      "angle": 0.011,
      "portrait": true,
      "visible": true,
      "title": "",
      "photoAssetPaths": [],
      "photoEdits": [],
      "lockAspectRatio": true,
      "isCustom": false,
    },
    {
      "id": "frame-11",
      "memoryIndex": 11,
      "left": 10099.0,
      "top": 279.5,
      "width": 176.0,
      "height": 251.0,
      "style": "portrait",
      "alignmentX": 0.22,
      "alignmentY": 0.04,
      "scale": 1.1770000000000003,
      "angle": -0.01,
      "portrait": true,
      "visible": true,
      "title": "",
      "photoAssetPaths": [],
      "photoEdits": [],
      "lockAspectRatio": true,
      "isCustom": false,
    },
  ],
  "trinkets": [],
  "instagramPosts": [
    {
      "id": "instagram-0",
      "postIndex": 0,
      "left": 538.0,
      "top": 205.0,
      "width": 272.0,
      "height": 400.0,
      "style": "oval",
      "angle": 0.0,
      "scale": 1.5,
      "visible": true,
    },
    {
      "id": "instagram-1",
      "postIndex": 1,
      "left": 1749.0,
      "top": 205.0,
      "width": 272.0,
      "height": 400.0,
      "style": "portrait",
      "angle": 0.0,
      "scale": 1.5,
      "visible": true,
    },
    {
      "id": "instagram-2",
      "postIndex": 2,
      "left": 2732.0,
      "top": 269.0,
      "width": 400.0,
      "height": 272.0,
      "style": "horizontalOval",
      "angle": 0.0,
      "scale": 1.5,
      "visible": true,
    },
    {
      "id": "instagram-3",
      "postIndex": 3,
      "left": 3980.0,
      "top": 269.0,
      "width": 272.0,
      "height": 272.0,
      "style": "circular",
      "angle": 0.0,
      "scale": 1.5,
      "visible": true,
    },
    {
      "id": "instagram-4",
      "postIndex": 4,
      "left": 5236.0,
      "top": 205.0,
      "width": 272.0,
      "height": 400.0,
      "style": "portrait",
      "angle": 0.0,
      "scale": 1.5,
      "visible": true,
    },
    {
      "id": "instagram-5",
      "postIndex": 5,
      "left": 6919.0,
      "top": 269.0,
      "width": 400.0,
      "height": 272.0,
      "style": "horizontalOval",
      "angle": 0.0,
      "scale": 1.5,
      "visible": true,
    },
    {
      "id": "instagram-6",
      "postIndex": 6,
      "left": 8542.0,
      "top": 269.0,
      "width": 272.0,
      "height": 272.0,
      "style": "circular",
      "angle": 0.0,
      "scale": 1.5,
      "visible": true,
    },
  ],
  "stripWidth": 10495.0,
  "leadingTrim": 0.0,
  "travelStartDate": null,
  "travelEndDate": null,
  "layoutVersion": 4,
};

GalleryTripLayout defaultGalleryLayoutFor(String tripSlug) =>
    GalleryTripLayout.fromJson(
      Map<String, dynamic>.from(_galleryWallTemplate),
      tripSlug: tripSlug,
      fallbackStripWidth: defaultGalleryStripWidthFor(tripSlug),
    );

List<GalleryInstagramPlacement> defaultInstagramPlacementsFor(
  String tripSlug,
) => <GalleryInstagramPlacement>[
  for (final item in _galleryWallTemplate['instagramPosts'] as List)
    GalleryInstagramPlacement.fromJson(Map<String, dynamic>.from(item as Map)),
];

double defaultGalleryStripWidthFor(String tripSlug) =>
    (_galleryWallTemplate['stripWidth'] as num).toDouble();

String formatGalleryTravelDate(DateTime date) {
  const months = <String>[
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
  ];
  return '${months[date.month - 1]} '
      '${date.day.toString().padLeft(2, '0')}, ${date.year}';
}

String _dateOnlyIso(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
