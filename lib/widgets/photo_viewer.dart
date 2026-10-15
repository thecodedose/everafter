import 'dart:math' as math;

import 'package:everafter/services/photo_download.dart';
import 'package:flutter/material.dart';

/// Original-resolution photo, independently of the decorative wall frame.
class PhotoViewer extends StatelessWidget {
  const PhotoViewer({required this.assetPath, required this.aspectRatio,
    required this.label, required this.sourceRect, required this.progress,
    required this.transformationController, required this.onDismiss, super.key});

  final String assetPath;
  final double aspectRatio;
  final String label;
  final Rect sourceRect;
  final double progress;
  final TransformationController transformationController;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
    final area = Rect.fromLTWH(16, 56, math.max(1.0, constraints.maxWidth - 32),
      math.max(1.0, constraints.maxHeight - 80));
    final fitted = applyBoxFit(BoxFit.contain, Size(aspectRatio, 1), area.size).destination;
    final target = Rect.fromCenter(center: area.center, width: fitted.width, height: fitted.height);
    final photoRect = Rect.lerp(sourceRect, target, progress)!;
    return Stack(key: const ValueKey('focused-memory-overlay'), fit: StackFit.expand,
      children: <Widget>[
        GestureDetector(key: const ValueKey('focused-memory-backdrop'), onTap: onDismiss,
          behavior: HitTestBehavior.opaque,
          child: ColoredBox(color: Color.lerp(Colors.transparent, const Color(0xF2171716), progress)!)),
        Positioned.fromRect(rect: photoRect,
          child: InteractiveViewer(key: const ValueKey('focused-memory-interactive-viewer'),
            transformationController: transformationController,
            minScale: 1, maxScale: 6, panEnabled: progress >= 0.98,
            scaleEnabled: progress >= 0.98, trackpadScrollCausesScale: true,
            child: Image.asset(assetPath, key: const ValueKey('focused-memory-image'),
              fit: BoxFit.contain, filterQuality: FilterQuality.high))),
        if (progress >= 0.98)
          Positioned(left: 12, top: 4, right: 8,
            child: Row(children: <Widget>[
              Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFFE6D4B5), fontFamily: 'Georgia', fontSize: 14))),
              const SizedBox(width: 8),
              TextButton.icon(key: const ValueKey('save-memory-image'),
                style: TextButton.styleFrom(foregroundColor: const Color(0xFFE6D4B5)),
                icon: const Icon(Icons.download_outlined), label: const Text('Save image'),
                onPressed: () async {
                  try {
                    await saveGalleryPhoto(assetPath);
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                        const SnackBar(content: Text('The browser could not start the image download.')));
                    }
                  }
                }),
              IconButton(tooltip: 'Close photo', onPressed: onDismiss,
                key: const ValueKey('close-memory-image'),
                icon: const Icon(Icons.close, color: Color(0xFFE6D4B5))),
            ])),
      ]);
  });
}
