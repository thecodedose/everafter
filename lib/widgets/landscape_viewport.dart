import 'package:flutter/widgets.dart';

/// Keep every route and its navigator overlays in a horizontal layout.
/// RotatedBox swaps constraints before layout, so content is not clipped by
/// a paint-only rotation when a mobile browser remains in portrait mode.
class LandscapeViewport extends StatelessWidget {
  const LandscapeViewport({required this.child, super.key});

  final Widget child;

  EdgeInsets _rotateInsets(EdgeInsets value) => EdgeInsets.fromLTRB(
    value.top,
    value.right,
    value.bottom,
    value.left,
  );

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final physicalSize = constraints.biggest;
        final rotate = physicalSize.height > physicalSize.width;
        final logicalSize = rotate
            ? Size(physicalSize.height, physicalSize.width)
            : physicalSize;
        return RotatedBox(
          key: const ValueKey('landscape-viewport'),
          quarterTurns: rotate ? 1 : 0,
          child: MediaQuery(
            data: media.copyWith(
              size: logicalSize,
              padding: rotate ? _rotateInsets(media.padding) : media.padding,
              viewPadding: rotate
                  ? _rotateInsets(media.viewPadding)
                  : media.viewPadding,
              viewInsets: rotate
                  ? _rotateInsets(media.viewInsets)
                  : media.viewInsets,
              systemGestureInsets: rotate
                  ? _rotateInsets(media.systemGestureInsets)
                  : media.systemGestureInsets,
            ),
            child: child,
          ),
        );
      },
    );
  }
}
