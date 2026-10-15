import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

String _videoAssetUrl(String path) =>
    Uri.parse(web.document.baseURI).resolve('assets/$path').toString();

class WebMemoryVideoSurface extends StatefulWidget {
  const WebMemoryVideoSurface({
    required this.assetPath,
    required this.muted,
    super.key,
  });

  final String assetPath;
  final bool muted;

  @override
  State<WebMemoryVideoSurface> createState() => _WebMemoryVideoSurfaceState();
}

class _WebMemoryVideoSurfaceState extends State<WebMemoryVideoSurface> {
  static int _nextId = 0;

  late final String _viewType;
  web.HTMLVideoElement? _element;

  @override
  void initState() {
    super.initState();
    _viewType = 'everafter-memory-video-${_nextId++}';
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (viewId) {
      final element = web.HTMLVideoElement()
        ..src = _videoAssetUrl(widget.assetPath)
        ..autoplay = true
        ..loop = true
        ..muted = widget.muted
        ..controls = false
        ..preload = 'metadata'
        ..setAttribute('playsinline', 'true');
      element.style
        ..width = '100%'
        ..height = '100%'
        ..display = 'block'
        ..border = 'none'
        ..objectFit = 'cover'
        ..pointerEvents = 'none'
        ..background = 'transparent';
      _element = element;
      return element;
    });
  }

  @override
  void didUpdateWidget(WebMemoryVideoSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    final element = _element;
    if (element == null) {
      return;
    }
    if (oldWidget.assetPath != widget.assetPath) {
      element
        ..src = _videoAssetUrl(widget.assetPath)
        ..load();
    }
    if (oldWidget.muted != widget.muted) {
      element.muted = widget.muted;
    }
  }

  @override
  void dispose() {
    final element = _element;
    if (element != null) {
      element
        ..pause()
        ..removeAttribute('src')
        ..load();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(
      key: const ValueKey('web-memory-video-surface'),
      viewType: _viewType,
    );
  }
}
