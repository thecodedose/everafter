import 'dart:math' as math;

import 'package:everafter/data/gallery_layout.dart';
import 'package:everafter/data/gallery_memory_content.dart';
import 'package:everafter/theme/everafter_theme.dart';
import 'package:everafter/widgets/gallery_trinket_image.dart';
import 'package:everafter/data/trip_catalog.dart';
import 'package:everafter/data/photo_metadata.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class GalleryAdminScreen extends StatefulWidget {
  const GalleryAdminScreen({super.key});

  @override
  State<GalleryAdminScreen> createState() => _GalleryAdminScreenState();
}

class _GalleryAdminScreenState extends State<GalleryAdminScreen> {
  static const double _defaultCanvasScale = 0.14;
  static const double _minimumCanvasScale = 0.08;
  static const double _maximumCanvasScale = 0.50;
  static const double _frameScale = 2.3;

  final GalleryLayoutStore _store = GalleryLayoutStore.instance;
  String _tripSlug = tripGalleryItems.first.slug;
  _SelectedGalleryItem? _selection;
  _SelectedGalleryItem? _activeResize;
  double _canvasScale = _defaultCanvasScale;

  TripGalleryItem get _trip =>
      tripGalleryItems.firstWhere((trip) => trip.slug == _tripSlug);

  double get _stripWidth => _store.layoutFor(_tripSlug).stripWidth;
  double get _leadingTrim => _store.layoutFor(_tripSlug).leadingTrim;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _adminTheme(Theme.of(context)),
      child: Scaffold(
        key: const ValueKey('gallery-admin-screen'),
        backgroundColor: const Color(0xFF17100E),
        body: SafeArea(
          child: AnimatedBuilder(
            animation: _store,
            builder: (context, _) {
              final layout = _store.layoutFor(_tripSlug);
              return LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 900) {
                    return DefaultTabController(
                      length: 2,
                      child: Column(
                        children: <Widget>[
                          _buildHeader(),
                          const TabBar(
                            tabs: <Widget>[
                              Tab(text: 'Canvas'),
                              Tab(text: 'Inspector'),
                            ],
                          ),
                          Expanded(
                            child: TabBarView(
                              children: <Widget>[
                                _buildCanvas(layout),
                                _buildInspector(layout),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return Column(
                    children: <Widget>[
                      _buildHeader(),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Expanded(child: _buildCanvas(layout)),
                            SizedBox(
                              width: 310,
                              child: _buildInspector(layout),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        color: Color(0xFF231815),
        border: Border(bottom: BorderSide(color: Color(0xFF513B33))),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          IconButton(
            tooltip: 'Back to Trip Highlights',
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.arrow_back),
          ),
          const Text(
            'GALLERY ADMIN',
            style: TextStyle(
              color: EverAfterColors.agedPaper,
              fontFamily: 'Georgia',
              fontSize: 19,
              letterSpacing: 2.2,
            ),
          ),
          SizedBox(
            width: 180,
            child: DropdownButtonFormField<String>(
              key: const ValueKey('admin-trip-selector'),
              initialValue: _tripSlug,
              isExpanded: true,
              dropdownColor: const Color(0xFF352520),
              decoration: _fieldDecoration('Trip'),
              items: <DropdownMenuItem<String>>[
                for (final trip in tripGalleryItemsByYear)
                  DropdownMenuItem(value: trip.slug, child: Text(trip.name)),
              ],
              onChanged: (slug) {
                if (slug == null) return;
                setState(() {
                  _tripSlug = slug;
                  _selection = null;
                });
              },
            ),
          ),
          TextButton.icon(
            key: const ValueKey('admin-travel-dates'),
            onPressed: _editTravelDates,
            icon: const Icon(Icons.date_range_outlined, size: 18),
            label: const Text('Travel dates'),
          ),
          OutlinedButton.icon(
            key: const ValueKey('admin-reset-layout'),
            onPressed: _confirmReset,
            icon: const Icon(Icons.restart_alt),
            label: const Text('Reset'),
          ),
          FilledButton.icon(
            key: const ValueKey('admin-save-layout'),
            onPressed: _store.hasUnsavedChanges ? _save : null,
            icon: const Icon(Icons.save_outlined),
            label: Text(_store.hasUnsavedChanges ? 'Export layout' : 'Saved'),
          ),
          const Text('GLOBAL LAYOUT', key: ValueKey('admin-layout-scope')),
        ],
      ),
    );
  }

  Widget _buildCanvas(GalleryTripLayout layout) {
    return Container(
      margin: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0908),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF4C3931)),
      ),
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              runSpacing: 4,
              children: <Widget>[
                const Icon(Icons.open_with, size: 16, color: Color(0xFFD4BFAF)),
                const SizedBox(width: 8),
                const SizedBox(
                  width: 190,
                  child: Text(
                    'Drag an item to move it. Select it, then drag its corner '
                    'to resize.',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Color(0xFFD4BFAF), fontSize: 12),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  key: const ValueKey('admin-zoom-out'),
                  tooltip: 'Zoom out',
                  visualDensity: VisualDensity.compact,
                  onPressed: _canvasScale <= _minimumCanvasScale
                      ? null
                      : () => _setCanvasScale(_canvasScale - 0.03),
                  icon: const Icon(Icons.remove_circle_outline, size: 18),
                  color: const Color(0xFFD7B27C),
                ),
                TextButton(
                  key: const ValueKey('admin-zoom-reset'),
                  onPressed: () => _setCanvasScale(_defaultCanvasScale),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFD4BFAF),
                    minimumSize: const Size(48, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                  ),
                  child: Text('${(_canvasScale * 100).round()}%'),
                ),
                IconButton(
                  key: const ValueKey('admin-zoom-in'),
                  tooltip: 'Zoom in',
                  visualDensity: VisualDensity.compact,
                  onPressed: _canvasScale >= _maximumCanvasScale
                      ? null
                      : () => _setCanvasScale(_canvasScale + 0.03),
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  color: const Color(0xFFD7B27C),
                ),
                PopupMenuButton<_AddGalleryItemType>(
                  key: const ValueKey('admin-add-item'),
                  tooltip: 'Add to gallery',
                  color: const Color(0xFF352520),
                  onSelected: (type) {
                    switch (type) {
                      case _AddGalleryItemType.frame:
                        _addFrame();
                      case _AddGalleryItemType.trinket:
                        _addTrinket();
                    }
                  },
                  itemBuilder: (context) =>
                      const <PopupMenuEntry<_AddGalleryItemType>>[
                        PopupMenuItem(
                          value: _AddGalleryItemType.frame,
                          child: ListTile(
                            leading: Icon(Icons.filter_frames_outlined),
                            title: Text('Frame with photo'),
                          ),
                        ),
                        PopupMenuItem(
                          value: _AddGalleryItemType.trinket,
                          child: ListTile(
                            leading: Icon(Icons.auto_awesome_outlined),
                            title: Text('Trinket'),
                          ),
                        ),
                      ],
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 7, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          Icons.add_circle_outline,
                          color: Color(0xFFD7B27C),
                          size: 17,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Add',
                          style: TextStyle(
                            color: Color(0xFFD7B27C),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                TextButton.icon(
                  key: const ValueKey('admin-fit-gallery'),
                  onPressed: () => _store.fitTripToContents(_tripSlug),
                  icon: const Icon(Icons.fit_screen, size: 16),
                  label: const Text('Fit gallery'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFD7B27C),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(9),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    key: const ValueKey('admin-gallery-canvas'),
                    width: _stripWidth * _canvasScale,
                    height: 800 * _canvasScale,
                    child: Stack(
                      clipBehavior: Clip.hardEdge,
                      children: <Widget>[
                        Positioned.fill(
                          child: Image.asset(
                            'assets/textures/red_damask_gallery_wall.jpeg',
                            fit: BoxFit.cover,
                            repeat: ImageRepeat.repeat,
                          ),
                        ),
                        const Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: <Color>[
                                  Color(0x24000000),
                                  Colors.transparent,
                                  Color(0x8F090100),
                                ],
                              ),
                            ),
                          ),
                        ),
                        for (final frame in layout.frames)
                          if (frame.visible) _buildFrame(frame),
                        for (final trinket in layout.trinkets)
                          if (trinket.visible) _buildTrinket(trinket),
                        for (final instagramPost in layout.instagramPosts)
                          if (instagramPost.visible)
                            _buildInstagramPost(instagramPost),
                        _buildEditorialTitle(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _setCanvasScale(double scale) {
    setState(() {
      _canvasScale = scale.clamp(_minimumCanvasScale, _maximumCanvasScale);
    });
  }

  Size _uniformlyResizedSize({
    required double width,
    required double height,
    required Offset screenDelta,
    required double pixelsPerUnit,
  }) {
    final aspectRatio = width / height;
    final horizontalDelta = screenDelta.dx / pixelsPerUnit;
    final verticalDelta = screenDelta.dy / pixelsPerUnit;
    final inverseAspectRatio = 1 / aspectRatio;
    final widthDelta =
        (horizontalDelta + verticalDelta * inverseAspectRatio) /
        (1 + inverseAspectRatio * inverseAspectRatio);
    final minimumWidth = math.max(40.0, 40 * aspectRatio);
    final resizedWidth = math.max(minimumWidth, width + widthDelta);
    return Size(resizedWidth, resizedWidth / aspectRatio);
  }

  void _resizeFrame(GalleryFramePlacement frame, Offset screenDelta) {
    final effectiveScale = _frameScale * frame.scale;
    final pixelsPerUnit = _canvasScale * effectiveScale;
    final Size resizedSize;
    if (frame.lockAspectRatio) {
      resizedSize = _uniformlyResizedSize(
        width: frame.width,
        height: frame.height,
        screenDelta: screenDelta,
        pixelsPerUnit: pixelsPerUnit,
      );
    } else {
      resizedSize = Size(
        math.max(40, frame.width + screenDelta.dx / pixelsPerUnit),
        math.max(40, frame.height + screenDelta.dy / pixelsPerUnit),
      );
    }
    final widthChange = resizedSize.width - frame.width;
    final heightChange = resizedSize.height - frame.height;
    _store.updateFrame(
      _tripSlug,
      frame.copyWith(
        left: frame.left + (effectiveScale - 1) * widthChange / 2,
        top: frame.top + (effectiveScale - 1) * heightChange / 2,
        width: resizedSize.width,
        height: resizedSize.height,
      ),
    );
  }

  void _resizeTrinket(GalleryTrinketPlacement trinket, Offset screenDelta) {
    final resizedSize = _uniformlyResizedSize(
      width: trinket.width,
      height: trinket.height,
      screenDelta: screenDelta,
      pixelsPerUnit: _canvasScale,
    );
    _store.updateTrinket(
      _tripSlug,
      trinket.copyWith(width: resizedSize.width, height: resizedSize.height),
    );
  }

  Widget _resizeHandle({
    required Key key,
    required _SelectedGalleryItem target,
    required ValueChanged<Offset> onDrag,
  }) {
    return Positioned(
      right: 0,
      bottom: 0,
      width: 30,
      height: 30,
      child: Listener(
        key: key,
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => _activeResize = target,
        onPointerMove: (event) {
          if (event.buttons != 0) {
            onDrag(event.delta);
          }
        },
        onPointerUp: (_) => _activeResize = null,
        onPointerCancel: (_) => _activeResize = null,
        child: MouseRegion(
          cursor: SystemMouseCursors.resizeUpLeftDownRight,
          child: Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFFFE3A6),
                border: Border.all(color: const Color(0xFF4A2F22), width: 2),
                borderRadius: BorderRadius.circular(4),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x99000000),
                    blurRadius: 5,
                    offset: Offset(1, 2),
                  ),
                ],
              ),
              child: const SizedBox(
                width: 15,
                height: 15,
                child: Icon(
                  Icons.open_in_full,
                  size: 10,
                  color: Color(0xFF4A2F22),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<T?> _showAdminDialog<T>({required WidgetBuilder builder}) {
    return showDialog<T>(
      context: context,
      builder: (dialogContext) => Theme(
        data: _adminTheme(Theme.of(dialogContext)),
        child: Builder(builder: builder),
      ),
    );
  }

  Future<void> _editTravelDates() async {
    final layout = _store.layoutFor(_tripSlug);
    var start =
        layout.travelStart ?? _parseGalleryTravelDate(_trip.startDateLabel);
    var end = layout.travelEnd ?? _parseGalleryTravelDate(_trip.endDateLabel);
    final result = await _showAdminDialog<({DateTime? start, DateTime? end})>(
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          scrollable: true,
          key: const ValueKey('admin-travel-dates-dialog'),
          title: Text('${_trip.name} travel dates'),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _TravelDateButton(
                  key: const ValueKey('admin-travel-start-date'),
                  label: 'Arrival',
                  date: start,
                  onPressed: () async {
                    final selected = await showDatePicker(
                      context: context,
                      initialDate: start ?? DateTime.now(),
                      firstDate: DateTime(1990),
                      lastDate: DateTime(2100),
                    );
                    if (selected == null) return;
                    setDialogState(() {
                      start = selected;
                      if (end != null && end!.isBefore(selected)) {
                        end = selected;
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
                _TravelDateButton(
                  key: const ValueKey('admin-travel-end-date'),
                  label: 'Departure',
                  date: end,
                  onPressed: () async {
                    final selected = await showDatePicker(
                      context: context,
                      initialDate: end ?? start ?? DateTime.now(),
                      firstDate: start ?? DateTime(1990),
                      lastDate: DateTime(2100),
                    );
                    if (selected == null) return;
                    setDialogState(() => end = selected);
                  },
                ),
                if (start != null && end != null) ...<Widget>[
                  const SizedBox(height: 16),
                  Text(
                    '${end!.difference(start!).inDays + 1} travel days',
                    key: const ValueKey('admin-travel-duration'),
                    style: const TextStyle(color: Color(0xFFC9B8AD)),
                  ),
                ],
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, (start: null, end: null)),
              child: const Text('Use original dates'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: start == null || end == null
                  ? null
                  : () => Navigator.pop(context, (start: start, end: end)),
              child: const Text('Apply dates'),
            ),
          ],
        ),
      ),
    );
    if (result == null) return;
    _store.updateTravelDates(_tripSlug, start: result.start, end: result.end);
  }

  Future<void> _addFrame() async {
    final frame = _store.addFrame(_tripSlug);
    setState(() {
      _selection = _SelectedGalleryItem(_GalleryItemType.frame, frame.id);
    });
    await _chooseFramePhotos(frame, startInAddMode: true);
  }

  Future<void> _addTrinket() async {
    final selection = await _showAdminDialog<_TrinketSelection>(
      builder: (context) => AlertDialog(
        insetPadding: const EdgeInsets.all(16),
        contentPadding: const EdgeInsets.all(16),
        key: const ValueKey('admin-trinket-picker'),
        backgroundColor: const Color(0xFF251915),
        title: const Text('Add a trinket'),
        content: SizedBox(
          width: 680,
          height:
              (MediaQuery.sizeOf(context).height -
                      MediaQuery.viewInsetsOf(context).bottom -
                      200)
                  .clamp(180.0, 430.0)
                  .toDouble(),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                SizedBox(
                  height: 240,
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 1.15,
                        ),
                    itemCount: galleryTrinketAssetChoices.length,
                    itemBuilder: (context, index) {
                      final asset = galleryTrinketAssetChoices[index];
                      return InkWell(
                        key: ValueKey('admin-trinket-choice-$index'),
                        onTap: () => Navigator.pop(
                          context,
                          _TrinketSelection(
                            source: asset,
                            label: _trinketLabel(asset),
                          ),
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(0xFF130D0B),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF5B443A)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Image.asset(asset, fit: BoxFit.contain),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  key: const ValueKey('admin-trinket-source-guidance'),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1210),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF5B443A)),
                  ),
                  child: const Text(
                    'To add more trinkets, place PNG, JPEG, or WebP files in '
                    'assets/images/experience/, add their asset paths to '
                    'galleryTrinketAssetChoices in '
                    'lib/data/gallery_memory_content.dart, then rebuild Trip Highlights.',
                    style: TextStyle(color: Color(0xFFD4BFAF), height: 1.35),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    if (selection == null) return;
    final trinket = _store.addTrinket(
      _tripSlug,
      assetName: selection.source,
      label: selection.label,
    );
    setState(() {
      _selection = _SelectedGalleryItem(_GalleryItemType.trinket, trinket.id);
    });
  }


  Widget _buildEditorialTitle() {
    final left = _store.layoutFor(_tripSlug).editorialTitleLeft;
    final dateRangeLabel = _store
        .layoutFor(_tripSlug)
        .effectiveDateRangeLabel(_trip.dateRangeLabel);
    return Positioned(
      key: const ValueKey('admin-gallery-editorial-title'),
      left: (left - _leadingTrim) * _canvasScale,
      top: 310 * _canvasScale,
      width: 340 * _canvasScale,
      height: 190 * _canvasScale,
      child: IgnorePointer(
        child: FittedBox(
          fit: BoxFit.fill,
          child: SizedBox(
            width: 340,
            height: 190,
            child: Row(
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
                          _trip.name.toUpperCase(),
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
          ),
        ),
      ),
    );
  }

  Widget _buildFrame(GalleryFramePlacement frame) {
    final effectiveScale = _frameScale * frame.scale;
    final width = frame.width * effectiveScale * _canvasScale;
    final height = frame.height * effectiveScale * _canvasScale;
    final left =
        (frame.left -
            _leadingTrim -
            (frame.width * effectiveScale - frame.width) / 2) *
        _canvasScale;
    final top =
        (frame.top - (frame.height * effectiveScale - frame.height) / 2) *
        _canvasScale;
    final selected =
        _selection == _SelectedGalleryItem(_GalleryItemType.frame, frame.id);
    final defaultMedia = defaultGalleryMediaFor(
      _trip,
      frame.memoryIndex,
      portrait: frame.portrait,
    );
    final previewEdit = frame.effectivePhotoEdits.isNotEmpty
        ? frame.effectivePhotoEdits.first
        : GalleryPhotoEdit(
            assetPath: defaultMedia.first.displayAssetPath,
            alignmentX: frame.alignmentX,
            alignmentY: frame.alignmentY,
          );
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: Transform.rotate(
        angle: frame.angle,
        child: Listener(
          onPointerMove: (event) {
            if (event.buttons == 0 ||
                _activeResize ==
                    _SelectedGalleryItem(_GalleryItemType.frame, frame.id)) {
              return;
            }
            _store.updateFrame(
              _tripSlug,
              frame.copyWith(
                left: frame.left + event.delta.dx / _canvasScale,
                top: frame.top + event.delta.dy / _canvasScale,
              ),
            );
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned.fill(
                child: GestureDetector(
                  key: ValueKey('admin-frame-${frame.id}'),
                  onTap: () => setState(
                    () => _selection = _SelectedGalleryItem(
                      _GalleryItemType.frame,
                      frame.id,
                    ),
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: selected
                            ? const Color(0xFFFFE3A6)
                            : Colors.transparent,
                        width: selected ? 3 : 0,
                      ),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(
                          color: Color(0x99000000),
                          blurRadius: 8,
                          offset: Offset(3, 5),
                        ),
                      ],
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.all(math.max(5, width * 0.14)),
                          child: Transform.scale(
                            scale: previewEdit.zoom,
                            child: Image.asset(
                              previewEdit.assetPath,
                              fit: BoxFit.cover,
                              alignment: Alignment(
                                previewEdit.alignmentX,
                                previewEdit.alignmentY,
                              ),
                            ),
                          ),
                        ),
                        _adminFrameImage(frame.style),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            color: const Color(0xC417100E),
                            child: Text(
                              '${frame.memoryIndex + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (selected)
                _resizeHandle(
                  key: ValueKey('admin-frame-resize-${frame.id}'),
                  target: _SelectedGalleryItem(
                    _GalleryItemType.frame,
                    frame.id,
                  ),
                  onDrag: (delta) => _resizeFrame(frame, delta),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrinket(GalleryTrinketPlacement trinket) {
    final selected =
        _selection ==
        _SelectedGalleryItem(_GalleryItemType.trinket, trinket.id);
    return Positioned(
      left: (trinket.left - _leadingTrim) * _canvasScale,
      top: trinket.top * _canvasScale,
      width: trinket.width * _canvasScale,
      height: trinket.height * _canvasScale,
      child: Transform.rotate(
        angle: trinket.angle,
        child: Listener(
          onPointerMove: (event) {
            if (event.buttons == 0 ||
                _activeResize ==
                    _SelectedGalleryItem(
                      _GalleryItemType.trinket,
                      trinket.id,
                    )) {
              return;
            }
            _store.updateTrinket(
              _tripSlug,
              trinket.copyWith(
                left: trinket.left + event.delta.dx / _canvasScale,
                top: trinket.top + event.delta.dy / _canvasScale,
              ),
            );
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned.fill(
                child: GestureDetector(
                  key: ValueKey('admin-trinket-${trinket.id}'),
                  onTap: () => setState(
                    () => _selection = _SelectedGalleryItem(
                      _GalleryItemType.trinket,
                      trinket.id,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: selected
                            ? const Color(0xFFFFE3A6)
                            : Colors.transparent,
                        width: selected ? 3 : 0,
                      ),
                    ),
                    child: GalleryTrinketImage(
                      source: trinket.assetName,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              if (selected)
                _resizeHandle(
                  key: ValueKey('admin-trinket-resize-${trinket.id}'),
                  target: _SelectedGalleryItem(
                    _GalleryItemType.trinket,
                    trinket.id,
                  ),
                  onDrag: (delta) => _resizeTrinket(trinket, delta),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstagramPost(GalleryInstagramPlacement placement) {
    final post = galleryVideoPostFor(_tripSlug, placement.postIndex);
    if (post == null) return const SizedBox.shrink();
    final scaledWidth = placement.width * placement.scale;
    final scaledHeight = placement.height * placement.scale;
    final selected =
        _selection ==
        _SelectedGalleryItem(_GalleryItemType.instagram, placement.id);
    return Positioned(
      left:
          (placement.left -
              _leadingTrim -
              (scaledWidth - placement.width) / 2) *
          _canvasScale,
      top:
          (placement.top - (scaledHeight - placement.height) / 2) *
          _canvasScale,
      width: scaledWidth * _canvasScale,
      height: scaledHeight * _canvasScale,
      child: Transform.rotate(
        angle: 0,
        child: Listener(
          onPointerMove: (event) {
            if (event.buttons == 0) return;
            _store.updateInstagramPost(
              _tripSlug,
              placement.copyWith(
                left: placement.left + event.delta.dx / _canvasScale,
                top: placement.top + event.delta.dy / _canvasScale,
              ),
            );
          },
          child: GestureDetector(
            key: ValueKey('admin-instagram-${placement.id}'),
            onTap: () => setState(
              () => _selection = _SelectedGalleryItem(
                _GalleryItemType.instagram,
                placement.id,
              ),
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: selected
                      ? const Color(0xFFFFE3A6)
                      : Colors.transparent,
                  width: selected ? 3 : 0,
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final photoRect = _framePhotoRect(
                    placement.style,
                    constraints.biggest,
                  );
                  final photo = Image.asset(
                    post.coverAssetPath,
                    fit: BoxFit.cover,
                  );
                  return Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      Positioned.fromRect(
                        rect: photoRect,
                        child:
                            placement.style == GalleryFrameStyle.oval ||
                                placement.style == GalleryFrameStyle.circular ||
                                placement.style ==
                                    GalleryFrameStyle.horizontalOval
                            ? ClipOval(child: photo)
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: photo,
                              ),
                      ),
                      _adminFrameImage(placement.style),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInspector(GalleryTripLayout layout) {
    final selection = _selection;
    final selectedValue = selection == null
        ? null
        : '${selection.type.name}:${selection.id}';
    final selector = Material(
      color: const Color(0xFF1A1210),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 10, 12),
        child: Row(
          children: <Widget>[
            Expanded(
              child: DropdownButtonFormField<String>(
                key: ValueKey('admin-item-selector-$_tripSlug-$selectedValue'),
                initialValue: selectedValue,
                isExpanded: true,
                dropdownColor: const Color(0xFF352520),
                style: const TextStyle(color: EverAfterColors.paper),
                decoration: _fieldDecoration('Select an item'),
                items: <DropdownMenuItem<String>>[
                  for (final frame in layout.frames)
                    DropdownMenuItem(
                      value: '${_GalleryItemType.frame.name}:${frame.id}',
                      child: Text(
                        'Frame ${frame.memoryIndex + 1}'
                        '${frame.visible ? '' : ' (hidden)'}',
                      ),
                    ),
                  for (final trinket in layout.trinkets)
                    DropdownMenuItem(
                      value: '${_GalleryItemType.trinket.name}:${trinket.id}',
                      child: Text(
                        '${trinket.label}'
                        '${trinket.visible ? '' : ' (hidden)'}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  for (final instagramPost in layout.instagramPosts)
                    DropdownMenuItem(
                      value:
                          '${_GalleryItemType.instagram.name}:'
                          '${instagramPost.id}',
                      child: Text(
                        'Video ${instagramPost.postIndex + 1}'
                        '${instagramPost.visible ? '' : ' (hidden)'}',
                      ),
                    ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  final separator = value.indexOf(':');
                  setState(() {
                    _selection = _SelectedGalleryItem(
                      _GalleryItemType.values.byName(
                        value.substring(0, separator),
                      ),
                      value.substring(separator + 1),
                    );
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
    final Widget detail;
    if (selection == null) {
      detail = _emptyInspector();
    } else if (selection.type == _GalleryItemType.frame) {
      final frame = layout.frames.where((item) => item.id == selection.id);
      detail = frame.isEmpty ? _emptyInspector() : _frameInspector(frame.first);
    } else if (selection.type == _GalleryItemType.trinket) {
      final trinket = layout.trinkets.where((item) => item.id == selection.id);
      detail = trinket.isEmpty
          ? _emptyInspector()
          : _trinketInspector(trinket.first);
    } else if (selection.type == _GalleryItemType.instagram) {
      final instagramPost = layout.instagramPosts.where(
        (item) => item.id == selection.id,
      );
      detail = instagramPost.isEmpty
          ? _emptyInspector()
          : _instagramInspector(instagramPost.first);
    } else {
      detail = _emptyInspector();
    }
    return Column(
      children: <Widget>[
        selector,
        Expanded(child: detail),
      ],
    );
  }

  Widget _emptyInspector() {
    return Container(
      color: const Color(0xFF211714),
      child: const SingleChildScrollView(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.touch_app, color: Color(0xFF8F786B), size: 42),
            SizedBox(height: 14),
            Text(
              'Select a frame, trinket, Video, or menu',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: EverAfterColors.agedPaper,
                fontFamily: 'Georgia',
                fontSize: 18,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Its position, size, rotation, and display options will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFFAD998D), height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _frameInspector(GalleryFramePlacement frame) {
    final memoryLocation = galleryMemoryLocationFor(
      _tripSlug,
      frame.memoryIndex,
    );
    final defaultTitle =
        memoryLocation?.label ??
        '${_trip.name} memory ${frame.memoryIndex + 1}';
    final defaultMedia = defaultGalleryMediaFor(
      _trip,
      frame.memoryIndex,
      portrait: frame.portrait,
    );
    final effectivePhotoPaths = frame.photoAssetPaths.isNotEmpty
        ? frame.photoAssetPaths
        : <String>[for (final media in defaultMedia) media.displayAssetPath];
    return _inspectorShell(
      title: 'Frame ${frame.memoryIndex + 1}',
      subtitle: 'Photo memory',
      visible: frame.visible,
      onVisibleChanged: (visible) =>
          _store.updateFrame(_tripSlug, frame.copyWith(visible: visible)),
      children: <Widget>[
        _TextValueField(
          label: 'Frame title',
          value: frame.title ?? defaultTitle,
          onChanged: (value) => _store.updateFrame(
            _tripSlug,
            frame.copyWith(title: value.trim()),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            const Expanded(
              child: Text(
                'PHOTOS IN FRAME',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color(0xFFB58A54),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.3,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              frame.photoAssetPaths.isEmpty
                  ? '${effectivePhotoPaths.length} original'
                  : '${effectivePhotoPaths.length} selected',
              style: const TextStyle(color: Color(0xFFAA968A), fontSize: 10),
            ),
          ],
        ),
        const SizedBox(height: 9),
        SizedBox(
          height: 64,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: math.min(effectivePhotoPaths.length, 5),
            separatorBuilder: (_, _) => const SizedBox(width: 7),
            itemBuilder: (context, index) => ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: SizedBox(
                width: 54,
                child: Image.asset(
                  effectivePhotoPaths[index],
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            key: ValueKey('admin-edit-frame-photos-${frame.id}'),
            onPressed: () => _chooseFramePhotos(frame),
            icon: const Icon(Icons.edit_outlined, size: 17),
            label: const Text('Edit photos'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFE7C7B3),
              side: const BorderSide(color: Color(0xFF785C50)),
            ),
          ),
        ),
        const Divider(color: Color(0xFF4A3730), height: 30),
        DropdownButtonFormField<GalleryFrameStyle>(
          key: ValueKey('admin-frame-style-${frame.id}-${frame.style.name}'),
          initialValue: frame.style,
          dropdownColor: const Color(0xFF352520),
          style: const TextStyle(color: EverAfterColors.paper),
          decoration: _fieldDecoration('Frame style'),
          items: <DropdownMenuItem<GalleryFrameStyle>>[
            for (final style in GalleryFrameStyle.values)
              DropdownMenuItem(
                value: style,
                child: Text(_friendlyStyleName(style)),
              ),
          ],
          onChanged: (style) {
            if (style != null) {
              final wasHorizontal = _isHorizontalFrameStyle(frame.style);
              final becomesHorizontal = _isHorizontalFrameStyle(style);
              final becomesCircular = style == GalleryFrameStyle.circular;
              final circularSize = math.min(frame.width, frame.height);
              final updatedFrame = frame
                  .copyWith(
                    style: style,
                    width: becomesCircular
                        ? circularSize
                        : wasHorizontal == becomesHorizontal
                        ? frame.width
                        : frame.height,
                    height: becomesCircular
                        ? circularSize
                        : wasHorizontal == becomesHorizontal
                        ? frame.height
                        : frame.width,
                    portrait: !becomesHorizontal && !becomesCircular,
                  )
                  .normalizedArtworkAspectRatio();
              _store.updateFrame(_tripSlug, updatedFrame);
            }
          },
        ),
        const SizedBox(height: 14),
        SwitchListTile(
          key: const ValueKey('admin-lock-aspect-ratio'),
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Lock aspect ratio',
            style: TextStyle(color: Color(0xFFE2D3C9), fontSize: 13),
          ),
          subtitle: Text(
            frame.lockAspectRatio
                ? 'Width and height resize together'
                : 'Width and height resize independently',
            style: const TextStyle(color: Color(0xFF9E887B), fontSize: 10),
          ),
          value: frame.lockAspectRatio,
          activeTrackColor: const Color(0xFFB58A54),
          onChanged: (locked) => _store.updateFrame(
            _tripSlug,
            frame.copyWith(lockAspectRatio: locked),
          ),
        ),
        const SizedBox(height: 6),
        _coordinateFields(
          left: frame.left,
          top: frame.top,
          width: frame.width,
          height: frame.height,
          angle: frame.angle,
          scale: frame.scale,
          onChanged:
              ({
                double? left,
                double? top,
                double? width,
                double? height,
                double? angle,
                double? scale,
              }) {
                final resizedFrame = frame.resized(
                  width: width,
                  height: height,
                );
                _store.updateFrame(
                  _tripSlug,
                  resizedFrame.copyWith(
                    left: left,
                    top: top,
                    angle: angle,
                    scale: scale,
                  ),
                );
              },
        ),
        if (frame.isCustom) ...<Widget>[
          const Divider(color: Color(0xFF4A3730), height: 30),
          _RemoveCustomItemButton(
            label: 'Remove frame',
            onPressed: () => _removeCustomFrame(frame),
          ),
        ],
      ],
    );
  }

  Future<void> _chooseFramePhotos(
    GalleryFramePlacement frame, {
    bool startInAddMode = false,
  }) async {
    final choices = galleryPhotoChoicesFor(_trip);
    final originalMedia = defaultGalleryMediaFor(
      _trip,
      frame.memoryIndex,
      portrait: frame.portrait,
    );
    final edits = <String, GalleryPhotoEdit>{
      if (frame.effectivePhotoEdits.isNotEmpty)
        for (final edit in frame.effectivePhotoEdits.take(1)) edit.assetPath: edit
      else if (!frame.isCustom)
        for (final media in originalMedia.take(1))
          if (!media.isVideo)
            media.assetPath: GalleryPhotoEdit(
              assetPath: media.assetPath,
              alignmentX: frame.alignmentX,
              alignmentY: frame.alignmentY,
            ),
    };
    String? activeAssetPath = edits.keys.firstOrNull;
    var showPhotoLibrary = startInAddMode;
    final result = await _showAdminDialog<_PhotoSelectionResult>(
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final displayedChoices = showPhotoLibrary
              ? choices
              : edits.keys.toList(growable: false);
          return AlertDialog(
            insetPadding: const EdgeInsets.all(16),
            contentPadding: const EdgeInsets.all(16),
            key: const ValueKey('admin-photo-picker'),
            backgroundColor: const Color(0xFF251915),
            title: Text('Photo in frame ${frame.memoryIndex + 1}'),
            content: SizedBox(
              width: 960,
              height:
                  (MediaQuery.sizeOf(context).height -
                          MediaQuery.viewInsetsOf(context).bottom -
                          200)
                      .clamp(100.0, 520.0)
                      .toDouble(),
              child: _ResponsivePhotoPicker(
                crop: KeyedSubtree(
                  key: const ValueKey('admin-photo-reposition-column'),
                  child: activeAssetPath != null
                      ? _PhotoCropEditor(
                          key: ValueKey('admin-photo-crop-$activeAssetPath'),
                          frameStyle: frame.style,
                          frameAspectRatio: frame.width / frame.height,
                          edit: edits[activeAssetPath]!,
                          onChanged: (edit) {
                            setDialogState(
                              () => edits[activeAssetPath!] = edit,
                            );
                          },
                        )
                      : const DecoratedBox(
                          decoration: BoxDecoration(
                            color: Color(0xFF160F0D),
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                            border: Border.fromBorderSide(
                              BorderSide(color: Color(0xFF5B443A)),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Select a photo to reposition it',
                              style: TextStyle(color: Color(0xFFB9A69B)),
                            ),
                          ),
                        ),
                ),
                library: KeyedSubtree(
                  key: const ValueKey('admin-photo-gallery-column'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              showPhotoLibrary
                                  ? '${edits.length} selected · '
                                        '${choices.length} available for '
                                        '${_trip.name}'
                                  : '${edits.length} photo'
                                        '${edits.length == 1 ? '' : 's'} '
                                        'in this frame',
                              style: const TextStyle(color: Color(0xFFB9A69B)),
                            ),
                          ),
                          TextButton.icon(
                            key: const ValueKey('admin-add-frame-photos'),
                            onPressed: () => setDialogState(
                              () => showPhotoLibrary = !showPhotoLibrary,
                            ),
                            icon: Icon(
                              showPhotoLibrary
                                  ? Icons.check
                                  : Icons.add_photo_alternate_outlined,
                              size: 17,
                            ),
                            label: Text(
                              showPhotoLibrary ? 'Done choosing' : 'Choose photo',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: displayedChoices.isEmpty
                            ? const Center(
                                child: Text(
                                  'No photos in this frame yet.\n'
                                  'Choose a photo for this frame.',
                                  key: ValueKey('admin-empty-frame-photos'),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Color(0xFFB9A69B)),
                                ),
                              )
                            : GridView.builder(
                                key: ValueKey(
                                  showPhotoLibrary
                                      ? 'admin-photo-library'
                                      : 'admin-applied-photos',
                                ),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      mainAxisSpacing: 10,
                                      crossAxisSpacing: 10,
                                      childAspectRatio: 1.08,
                                    ),
                                itemCount: displayedChoices.length,
                                itemBuilder: (context, index) {
                                  final assetPath = displayedChoices[index];
                                  final libraryIndex = choices.indexOf(
                                    assetPath,
                                  );
                                  final isSelected = edits.containsKey(
                                    assetPath,
                                  );
                                  final isActive = activeAssetPath == assetPath;
                                  return InkWell(
                                    key: ValueKey(
                                      'admin-photo-choice-$libraryIndex',
                                    ),
                                    onTap: () {
                                      setDialogState(() {
                                        if (!isSelected) {
                                          edits.clear();
                                          edits[assetPath] = GalleryPhotoEdit(
                                            assetPath: assetPath,
                                            alignmentX: frame.alignmentX,
                                            alignmentY: frame.alignmentY,
                                          );
                                        }
                                        activeAssetPath = assetPath;
                                      });
                                    },
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: <Widget>[
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          child: Image.asset(
                                            assetPath,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        DecoratedBox(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            border: Border.all(
                                              color: isSelected
                                                  ? isActive
                                                        ? const Color(
                                                            0xFFFFD98B,
                                                          )
                                                        : const Color(
                                                            0xFFB58A54,
                                                          )
                                                  : const Color(0x665C493F),
                                              width: isSelected ? 3 : 1,
                                            ),
                                          ),
                                        ),
                                        if (isSelected)
                                          Positioned(
                                            top: 4,
                                            right: 4,
                                            child: GestureDetector(
                                              key: ValueKey(
                                                'admin-remove-photo-$libraryIndex',
                                              ),
                                              onTap: () {
                                                setDialogState(() {
                                                  edits.remove(assetPath);
                                                  if (activeAssetPath ==
                                                      assetPath) {
                                                    activeAssetPath =
                                                        edits.keys.firstOrNull;
                                                  }
                                                });
                                              },
                                              child: const DecoratedBox(
                                                decoration: BoxDecoration(
                                                  color: Color(0xCC231511),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Padding(
                                                  padding: EdgeInsets.all(3),
                                                  child: Icon(
                                                    Icons.close,
                                                    color: Colors.white,
                                                    size: 17,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(
                  context,
                  const _PhotoSelectionResult(useOriginal: true),
                ),
                child: const Text('Use original photo'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: edits.isEmpty
                    ? null
                    : () => Navigator.pop(
                        context,
                        _PhotoSelectionResult(
                          photoEdits: edits.values.toList(growable: false),
                        ),
                      ),
                child: const Text('Apply photo'),
              ),
            ],
          );
        },
      ),
    );
    if (result == null) return;
    var updated = frame.copyWith(
      photoAssetPaths: result.useOriginal
          ? const <String>[]
          : <String>[for (final edit in result.photoEdits) edit.assetPath],
      photoEdits: result.useOriginal ? const <GalleryPhotoEdit>[] : result.photoEdits,
    );
    final selectedPath = result.useOriginal
        ? originalMedia.firstOrNull?.assetPath
        : result.photoEdits.firstOrNull?.assetPath;
    final ratio = galleryPhotoAspectRatios[selectedPath];
    if (ratio != null && (updated.style == GalleryFrameStyle.landscape ||
        updated.style == GalleryFrameStyle.portrait)) {
      final landscape = ratio >= 1;
      updated = updated.copyWith(
        width: updated.height * photoFrameAspectRatio(ratio, landscape: landscape),
        style: landscape ? GalleryFrameStyle.landscape : GalleryFrameStyle.portrait,
        portrait: !landscape,
      );
    }
    _store.updateFrame(_tripSlug, updated);
  }

  Widget _trinketInspector(GalleryTrinketPlacement trinket) {
    return _inspectorShell(
      title: trinket.label,
      subtitle: 'Trinket',
      visible: trinket.visible,
      onVisibleChanged: (visible) =>
          _store.updateTrinket(_tripSlug, trinket.copyWith(visible: visible)),
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 118,
            color: const Color(0xFF170F0D),
            padding: const EdgeInsets.all(12),
            child: GalleryTrinketImage(
              source: trinket.assetName,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _coordinateFields(
          left: trinket.left,
          top: trinket.top,
          width: trinket.width,
          height: trinket.height,
          angle: trinket.angle,
          onChanged:
              ({
                double? left,
                double? top,
                double? width,
                double? height,
                double? angle,
                double? scale,
              }) {
                _store.updateTrinket(
                  _tripSlug,
                  trinket.copyWith(
                    left: left,
                    top: top,
                    width: width,
                    height: height,
                    angle: angle,
                  ),
                );
              },
        ),
        if (trinket.isCustom) ...<Widget>[
          const Divider(color: Color(0xFF4A3730), height: 30),
          _RemoveCustomItemButton(
            label: 'Remove trinket',
            onPressed: () => _removeCustomTrinket(trinket),
          ),
        ],
      ],
    );
  }

  Widget _instagramInspector(GalleryInstagramPlacement placement) {
    final post = galleryVideoPostFor(_tripSlug, placement.postIndex);
    if (post == null) return _emptyInspector();
    return _inspectorShell(
      title: 'Video ${placement.postIndex + 1}',
      subtitle: '${_trip.name} video',
      visible: placement.visible,
      onVisibleChanged: (visible) => _store.updateInstagramPost(
        _tripSlug,
        placement.copyWith(visible: visible),
      ),
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 150,
            child: Image.asset(post.coverAssetPath, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 16),
        _coordinateFields(
          left: placement.left,
          top: placement.top,
          width: placement.width,
          height: placement.height,
          angle: 0,
          scale: placement.scale,
          showAngle: false,
          onChanged:
              ({
                double? left,
                double? top,
                double? width,
                double? height,
                double? angle,
                double? scale,
              }) {
                _store.updateInstagramPost(
                  _tripSlug,
                  placement.copyWith(
                    left: left,
                    top: top,
                    width: width,
                    height: height,
                    scale: scale,
                  ),
                );
              },
        ),
      ],
    );
  }

  Future<void> _removeCustomFrame(GalleryFramePlacement frame) async {
    if (!await _confirmRemove('Remove this frame and its photo selection?')) {
      return;
    }
    _store.removeFrame(_tripSlug, frame.id);
    setState(() => _selection = null);
  }

  Future<void> _removeCustomTrinket(GalleryTrinketPlacement trinket) async {
    if (!await _confirmRemove('Remove this trinket from the gallery?')) {
      return;
    }
    _store.removeTrinket(_tripSlug, trinket.id);
    setState(() => _selection = null);
  }

  Future<bool> _confirmRemove(String message) async {
    return await _showAdminDialog<bool>(
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF2B1D19),
            title: const Text('Remove added item?'),
            content: Text(message),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Remove'),
              ),
            ],
          ),
        ) ??
        false;
  }


  Widget _inspectorShell({
    required String title,
    required String subtitle,
    required bool visible,
    required ValueChanged<bool> onVisibleChanged,
    required List<Widget> children,
    bool showVisibility = true,
  }) {
    return Material(
      color: const Color(0xFF211714),
      child: ListView(
        key: const ValueKey('admin-inspector-scroll'),
        padding: const EdgeInsets.all(22),
        children: <Widget>[
          Text(
            subtitle.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFFB58A54),
              letterSpacing: 1.5,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              color: EverAfterColors.agedPaper,
              fontFamily: 'Georgia',
              fontSize: 20,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          if (showVisibility)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Visible in gallery',
                style: TextStyle(color: Color(0xFFE2D3C9), fontSize: 13),
              ),
              value: visible,
              activeTrackColor: const Color(0xFFB58A54),
              onChanged: onVisibleChanged,
            ),
          const Divider(color: Color(0xFF4A3730), height: 28),
          ...children,
        ],
      ),
    );
  }

  Widget _coordinateFields({
    required double left,
    required double top,
    required double width,
    required double height,
    required double angle,
    double? scale,
    bool showAngle = true,
    required void Function({
      double? left,
      double? top,
      double? width,
      double? height,
      double? angle,
      double? scale,
    })
    onChanged,
  }) {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _NumberField(
                label: 'X',
                value: left,
                onChanged: (value) => onChanged(left: value),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _NumberField(
                label: 'Y',
                value: top,
                onChanged: (value) => onChanged(top: value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: _NumberField(
                label: 'Width',
                value: width,
                minimum: 40,
                onChanged: (value) => onChanged(width: value),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _NumberField(
                label: 'Height',
                value: height,
                minimum: 40,
                onChanged: (value) => onChanged(height: value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (showAngle || scale != null)
          Row(
            children: <Widget>[
              if (showAngle)
                Expanded(
                  child: _NumberField(
                    label: 'Rotation °',
                    value: angle * 180 / math.pi,
                    onChanged: (value) =>
                        onChanged(angle: value * math.pi / 180),
                  ),
                ),
              if (showAngle && scale != null) const SizedBox(width: 10),
              if (scale != null)
                Expanded(
                  child: _NumberField(
                    label: 'Scale',
                    value: scale,
                    minimum: 0.35,
                    onChanged: (value) => onChanged(scale: value),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Future<void> _save() async {
    try {
      await _store.save();
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Layout export cancelled or failed. $error'),
          backgroundColor: const Color(0xFF8A2F2F),
        ),
      );
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Layout export requested. Replace the source JSON and redeploy to share changes.',
        ),
      ),
    );
  }

  Future<void> _confirmReset() async {
    final reset = await _showAdminDialog<bool>(
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2B1D19),
        title: Text('Reset ${_trip.name}?'),
        content: Text(
          _store.editsGlobalLayout
              ? 'This restores this trip from the bundled global layout. '
                    'Save global afterward to update the JSON file.'
              : 'This removes this trip\'s device-specific changes and '
                    'restores the global layout. Save this device afterward.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset layout'),
          ),
        ],
      ),
    );
    if (reset == true) {
      await _store.resetTrip(_tripSlug);
      setState(() => _selection = null);
    }
  }
}

class _NumberField extends StatefulWidget {
  const _NumberField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.minimum,
  });

  final String label;
  final double value;
  final double? minimum;
  final ValueChanged<double> onChanged;

  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  late final TextEditingController _controller = TextEditingController(
    text: _displayValue(widget.value),
  );
  late final FocusNode _focusNode = FocusNode()..addListener(_handleFocus);

  @override
  void didUpdateWidget(covariant _NumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus && oldWidget.value != widget.value) {
      _controller.text = _displayValue(widget.value);
    }
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocus)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocus() {
    if (!_focusNode.hasFocus) {
      _commit();
    }
  }

  void _commit() {
    final parsed = double.tryParse(_controller.text);
    if (parsed == null) {
      _controller.text = _displayValue(widget.value);
      return;
    }
    final value = widget.minimum == null
        ? parsed
        : math.max(widget.minimum!, parsed);
    _controller.text = _displayValue(value);
    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
      style: const TextStyle(color: EverAfterColors.paper, fontSize: 13),
      decoration: _fieldDecoration(widget.label),
      onSubmitted: (_) => _commit(),
    );
  }
}

String _displayValue(double value) =>
    value.toStringAsFixed(value == value.roundToDouble() ? 0 : 2);

class _TextValueField extends StatefulWidget {
  const _TextValueField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<_TextValueField> createState() => _TextValueFieldState();
}

class _TextValueFieldState extends State<_TextValueField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );
  late final FocusNode _focusNode = FocusNode()..addListener(_handleFocus);

  @override
  void didUpdateWidget(covariant _TextValueField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus && oldWidget.value != widget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocus)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocus() {
    if (!_focusNode.hasFocus) {
      widget.onChanged(_controller.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const ValueKey('admin-frame-title-field'),
      controller: _controller,
      focusNode: _focusNode,
      style: const TextStyle(color: EverAfterColors.paper, fontSize: 13),
      decoration: _fieldDecoration(widget.label),
      textInputAction: TextInputAction.done,
      onSubmitted: widget.onChanged,
    );
  }
}

@immutable
class _PhotoSelectionResult {
  const _PhotoSelectionResult({
    this.photoEdits = const <GalleryPhotoEdit>[],
    this.useOriginal = false,
  });

  final List<GalleryPhotoEdit> photoEdits;
  final bool useOriginal;
}

@immutable
class _TrinketSelection {
  const _TrinketSelection({required this.source, required this.label});

  final String source;
  final String label;
}

class _TravelDateButton extends StatelessWidget {
  const _TravelDateButton({
    required this.label,
    required this.date,
    required this.onPressed,
    super.key,
  });

  final String label;
  final DateTime? date;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.calendar_month_outlined, size: 19),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFFC9B8AD),
                    fontSize: 10,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  date == null ? 'Choose date' : formatGalleryTravelDate(date!),
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 18),
        ],
      ),
    );
  }
}

class _ResponsivePhotoPicker extends StatelessWidget {
  const _ResponsivePhotoPicker({required this.crop, required this.library});

  final Widget crop;
  final Widget library;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 700) {
          return DefaultTabController(
            length: 2,
            child: Column(
              children: <Widget>[
                const TabBar(
                  tabs: <Widget>[
                    Tab(text: 'Crop'),
                    Tab(text: 'Photos'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: <Widget>[
                      SingleChildScrollView(
                        child: SizedBox(height: 360, child: crop),
                      ),
                      library,
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(flex: 11, child: crop),
            const SizedBox(width: 18),
            const VerticalDivider(color: Color(0xFF4A3730), width: 1),
            const SizedBox(width: 18),
            Expanded(flex: 9, child: library),
          ],
        );
      },
    );
  }
}

class _PhotoCropEditor extends StatelessWidget {
  const _PhotoCropEditor({
    required this.frameStyle,
    required this.frameAspectRatio,
    required this.edit,
    required this.onChanged,
    super.key,
  });

  final GalleryFrameStyle frameStyle;
  final double frameAspectRatio;
  final GalleryPhotoEdit edit;
  final ValueChanged<GalleryPhotoEdit> onChanged;

  bool get _isOval =>
      frameStyle == GalleryFrameStyle.oval ||
      frameStyle == GalleryFrameStyle.circular ||
      frameStyle == GalleryFrameStyle.horizontalOval;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF160F0D),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF5B443A)),
      ),
      child: Column(
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SizedBox.expand(
                    child: DecoratedBox(
                      decoration: const BoxDecoration(color: Color(0xFF070605)),
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: frameAspectRatio,
                          child: LayoutBuilder(
                            builder: (context, frameConstraints) {
                              final frameSize = frameConstraints.biggest;
                              final photoRect = _framePhotoRect(
                                frameStyle,
                                frameSize,
                              );
                              final preview = GestureDetector(
                                key: const ValueKey('admin-photo-crop-preview'),
                                behavior: HitTestBehavior.opaque,
                                onPanUpdate: (details) {
                                  onChanged(
                                    edit.copyWith(
                                      alignmentX:
                                          (edit.alignmentX -
                                                  details.delta.dx /
                                                      photoRect.width *
                                                      2)
                                              .clamp(-1.0, 1.0),
                                      alignmentY:
                                          (edit.alignmentY -
                                                  details.delta.dy /
                                                      photoRect.height *
                                                      2)
                                              .clamp(-1.0, 1.0),
                                    ),
                                  );
                                },
                                child: Transform.scale(
                                  scale: edit.zoom,
                                  child: Image.asset(
                                    edit.assetPath,
                                    fit: BoxFit.cover,
                                    alignment: Alignment(
                                      edit.alignmentX,
                                      edit.alignmentY,
                                    ),
                                  ),
                                ),
                              );
                              return Stack(
                                fit: StackFit.expand,
                                children: <Widget>[
                                  Positioned.fromRect(
                                    rect: photoRect,
                                    child: ColoredBox(
                                      color: const Color(0xFF171513),
                                      child: _isOval
                                          ? ClipOval(child: preview)
                                          : ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                              child: preview,
                                            ),
                                    ),
                                  ),
                                  Positioned.fill(
                                    child: IgnorePointer(
                                      child: KeyedSubtree(
                                        key: ValueKey(
                                          'admin-photo-frame-outline-'
                                          '${frameStyle.name}',
                                        ),
                                        child: _adminFrameImage(frameStyle),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'DRAG TO REPOSITION',
                  style: TextStyle(
                    color: Color(0xFFB58A54),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.zoom_out,
                      color: Color(0xFFD4BFAF),
                      size: 18,
                    ),
                    Expanded(
                      child: Slider(
                        key: const ValueKey('admin-photo-zoom-slider'),
                        value: edit.zoom,
                        min: 1,
                        max: 3,
                        divisions: 40,
                        activeColor: const Color(0xFFB58A54),
                        onChanged: (zoom) =>
                            onChanged(edit.copyWith(zoom: zoom)),
                      ),
                    ),
                    const Icon(
                      Icons.zoom_in,
                      color: Color(0xFFD4BFAF),
                      size: 18,
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    Text(
                      'Zoom ${edit.zoom.toStringAsFixed(2)}×',
                      style: const TextStyle(
                        color: Color(0xFFB9A69B),
                        fontSize: 11,
                      ),
                    ),
                    TextButton(
                      key: const ValueKey('admin-reset-photo-crop'),
                      style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 4,
                        ),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => onChanged(
                        GalleryPhotoEdit(assetPath: edit.assetPath),
                      ),
                      child: const Text('Reset crop'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RemoveCustomItemButton extends StatelessWidget {
  const _RemoveCustomItemButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.delete_outline, size: 17),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFE5A29B),
          side: const BorderSide(color: Color(0xFF804A45)),
        ),
      ),
    );
  }
}

enum _GalleryItemType { frame, trinket, instagram }

enum _AddGalleryItemType { frame, trinket }

@immutable
class _SelectedGalleryItem {
  const _SelectedGalleryItem(this.type, this.id);

  final _GalleryItemType type;
  final String id;

  @override
  bool operator ==(Object other) =>
      other is _SelectedGalleryItem && other.type == type && other.id == id;

  @override
  int get hashCode => Object.hash(type, id);
}

ThemeData _adminTheme(ThemeData base) {
  const foreground = Color(0xFFF4E8DF);
  const mutedForeground = Color(0xFFC9B8AD);
  const accent = Color(0xFFE0B878);
  const surface = Color(0xFF251915);
  const disabled = Color(0xFF9F8E84);
  final colorScheme = const ColorScheme.dark(
    primary: accent,
    onPrimary: Color(0xFF24160E),
    secondary: Color(0xFFE7C7B3),
    onSecondary: Color(0xFF24160E),
    surface: surface,
    onSurface: foreground,
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
  );
  final buttonForeground = WidgetStateProperty.resolveWith<Color?>(
    (states) => states.contains(WidgetState.disabled) ? disabled : foreground,
  );
  return base.copyWith(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: const Color(0xFF17100E),
    canvasColor: surface,
    textTheme: base.textTheme.apply(
      bodyColor: foreground,
      displayColor: foreground,
    ),
    primaryTextTheme: base.primaryTextTheme.apply(
      bodyColor: foreground,
      displayColor: foreground,
    ),
    iconTheme: const IconThemeData(color: foreground),
    dialogTheme: const DialogThemeData(
      backgroundColor: surface,
      titleTextStyle: TextStyle(
        color: foreground,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      contentTextStyle: TextStyle(color: mutedForeground, fontSize: 14),
    ),
    popupMenuTheme: const PopupMenuThemeData(
      color: Color(0xFF352520),
      textStyle: TextStyle(color: foreground),
      labelTextStyle: WidgetStatePropertyAll(TextStyle(color: foreground)),
    ),
    listTileTheme: const ListTileThemeData(
      textColor: foreground,
      iconColor: accent,
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(foregroundColor: buttonForeground),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: buttonForeground,
        side: WidgetStateProperty.resolveWith<BorderSide>(
          (states) => BorderSide(
            color: states.contains(WidgetState.disabled)
                ? const Color(0xFF665850)
                : const Color(0xFF9A7765),
          ),
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith<Color?>(
          (states) => states.contains(WidgetState.disabled)
              ? const Color(0xFFC1B4AC)
              : const Color(0xFF24160E),
        ),
        backgroundColor: WidgetStateProperty.resolveWith<Color?>(
          (states) => states.contains(WidgetState.disabled)
              ? const Color(0xFF554943)
              : accent,
        ),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      labelStyle: TextStyle(color: mutedForeground),
      hintStyle: TextStyle(color: disabled),
      helperStyle: TextStyle(color: mutedForeground),
      errorStyle: TextStyle(color: Color(0xFFFFB4AB)),
    ),
    sliderTheme: base.sliderTheme.copyWith(
      activeTrackColor: accent,
      inactiveTrackColor: const Color(0xFF75635A),
      thumbColor: accent,
      overlayColor: accent.withValues(alpha: 0.16),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Color(0xFF3A2923),
      contentTextStyle: TextStyle(color: foreground),
    ),
  );
}

InputDecoration _fieldDecoration(String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Color(0xFFB7A399), fontSize: 12),
    filled: true,
    fillColor: const Color(0xFF30221E),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(7),
      borderSide: const BorderSide(color: Color(0xFF5E483F)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(7),
      borderSide: const BorderSide(color: Color(0xFF5E483F)),
    ),
  );
}

String _friendlyStyleName(GalleryFrameStyle style) => switch (style) {
  GalleryFrameStyle.oval => 'Oval',
  GalleryFrameStyle.circular => 'Circular',
  GalleryFrameStyle.portrait => 'Portrait',
  GalleryFrameStyle.landscape => 'Landscape',
  GalleryFrameStyle.horizontalOval => 'Horizontal oval',
};

String _trinketLabel(String assetPath) {
  final name = assetPath.split('/').last.split('.').first;
  return name
      .split('-')
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
}

DateTime? _parseGalleryTravelDate(String? label) {
  if (label == null) return null;
  const months = <String, int>{
    'JAN': 1,
    'FEB': 2,
    'MAR': 3,
    'APR': 4,
    'MAY': 5,
    'JUN': 6,
    'JUL': 7,
    'AUG': 8,
    'SEP': 9,
    'OCT': 10,
    'NOV': 11,
    'DEC': 12,
  };
  final match = RegExp(r'^([A-Z]{3}) (\d{2}), (\d{4})$').firstMatch(label);
  if (match == null) return null;
  final month = months[match.group(1)];
  if (month == null) return null;
  return DateTime(
    int.parse(match.group(3)!),
    month,
    int.parse(match.group(2)!),
  );
}

bool _isHorizontalFrameStyle(GalleryFrameStyle style) =>
    style == GalleryFrameStyle.landscape ||
    style == GalleryFrameStyle.horizontalOval;

Rect _framePhotoRect(GalleryFrameStyle style, Size size) => switch (style) {
  GalleryFrameStyle.oval => Rect.fromLTWH(
    size.width * 0.2036,
    size.height * 0.2372,
    size.width * 0.5899,
    size.height * 0.5845,
  ),
  GalleryFrameStyle.circular => Rect.fromLTWH(
    size.width * 0.229,
    size.height * 0.228,
    size.width * 0.54,
    size.height * 0.54,
  ),
  GalleryFrameStyle.horizontalOval => Rect.fromLTWH(
    size.width * 0.1366,
    size.height * 0.2243,
    size.width * 0.7261,
    size.height * 0.6036,
  ),
  GalleryFrameStyle.portrait => Rect.fromLTWH(
    size.width * 0.2317,
    size.height * 0.1941,
    size.width * 0.5408,
    size.height * 0.6755,
  ),
  GalleryFrameStyle.landscape => Rect.fromLTWH(
    size.width * 0.1324,
    size.height * 0.1709,
    size.width * 0.7336,
    size.height * 0.6667,
  ),
};

Widget _adminFrameImage(GalleryFrameStyle style) {
  return Image.asset(
    _frameAsset(style),
    key: style == GalleryFrameStyle.horizontalOval
        ? const ValueKey('admin-horizontal-oval-frame')
        : null,
    fit: BoxFit.fill,
    filterQuality: FilterQuality.medium,
  );
}

String _frameAsset(GalleryFrameStyle style) => switch (style) {
  GalleryFrameStyle.oval =>
    'assets/images/experience/baroque-frame-oval-hd.png',
  GalleryFrameStyle.circular =>
    'assets/images/experience/baroque-frame-circular-hd.png',
  GalleryFrameStyle.portrait =>
    'assets/images/experience/baroque-frame-portrait-hd.png',
  GalleryFrameStyle.horizontalOval =>
    'assets/images/experience/baroque-frame-horizontal-oval-hd.png',
  GalleryFrameStyle.landscape =>
    'assets/images/experience/baroque-frame-landscape-hd.png',
};
