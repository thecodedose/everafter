import 'package:flutter/widgets.dart';

class WebMemoryVideoSurface extends StatelessWidget {
  const WebMemoryVideoSurface({
    required this.assetPath,
    required this.muted,
    super.key,
  });

  final String assetPath;
  final bool muted;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
