import 'dart:math' as math;

import 'package:everafter/theme/everafter_theme.dart';
import 'package:flutter/material.dart';

class PaperScaffold extends StatelessWidget {
  const PaperScaffold({
    required this.child,
    this.includeDust = false,
    this.backgroundAsset,
    super.key,
  });

  final Widget child;
  final bool includeDust;
  final String? backgroundAsset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const ColoredBox(color: EverAfterColors.paper),
          if (backgroundAsset case final asset?)
            asset == WarmLinenTexture.assetPath
                ? const WarmLinenTexture(
                    imageKey: ValueKey('warm-linen-background'),
                  )
                : ColorFiltered(
                    colorFilter: const ColorFilter.mode(
                      Color(0x18B98C48),
                      BlendMode.multiply,
                    ),
                    child: Image.asset(
                      asset,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.medium,
                    ),
                  )
          else
            const CustomPaint(painter: PaperTexturePainter()),
          if (includeDust) ...const <Widget>[AmbientLight(), AmbientDust()],
          SafeArea(child: child),
        ],
      ),
    );
  }
}

class WarmLinenTexture extends StatelessWidget {
  const WarmLinenTexture({this.imageKey, super.key});

  static const assetPath = 'assets/textures/warm_linen_canvas_visible.jpg';

  final Key? imageKey;

  @override
  Widget build(BuildContext context) {
    return ColorFiltered(
      colorFilter: const ColorFilter.mode(
        Color(0x18B98C48),
        BlendMode.multiply,
      ),
      child: Image.asset(
        assetPath,
        key: imageKey,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        filterQuality: FilterQuality.medium,
        excludeFromSemantics: true,
      ),
    );
  }
}

class PaperTexturePainter extends CustomPainter {
  const PaperTexturePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = EverAfterColors.catalogLine
      ..strokeWidth = 0.7;
    for (var y = 36.0; y < size.height; y += 38) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    final speckPaint = Paint()..color = const Color(0x182A2725);
    for (var i = 0; i < 150; i++) {
      final x = (i * 47 % math.max(size.width.floor(), 1)).toDouble();
      final y = (i * 89 % math.max(size.height.floor(), 1)).toDouble();
      final radius = 0.35 + (i % 3) * 0.22;
      canvas.drawCircle(Offset(x, y), radius, speckPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AmbientLight extends StatefulWidget {
  const AmbientLight({super.key});

  @override
  State<AmbientLight> createState() => _AmbientLightState();
}

class _AmbientLightState extends State<AmbientLight>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 22),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        painter: AmbientLightPainter(progress: _controller.value),
      ),
    );
  }
}

class AmbientLightPainter extends CustomPainter {
  const AmbientLightPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final phase = progress * math.pi * 2;
    final center = Offset(
      size.width * (0.46 + math.sin(phase) * 0.08),
      size.height * (0.42 + math.cos(phase * 0.7) * 0.05),
    );
    final radius = math.max(size.width, size.height) * 0.68;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          Colors.white.withValues(alpha: 0.24),
          EverAfterColors.brass.withValues(alpha: 0.055),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant AmbientLightPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class AmbientDust extends StatefulWidget {
  const AmbientDust({super.key});

  @override
  State<AmbientDust> createState() => _AmbientDustState();
}

class _AmbientDustState extends State<AmbientDust>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 16),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: AmbientDustPainter(progress: _controller.value),
        );
      },
    );
  }
}

class AmbientDustPainter extends CustomPainter {
  const AmbientDustPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x33B98C48);
    for (var i = 0; i < 34; i++) {
      final x = (i * 83 % math.max(size.width.floor(), 1)).toDouble();
      final baseY = (i * 61 % math.max(size.height.floor(), 1)).toDouble();
      final drift = math.sin(progress * math.pi * 2 + i) * 13;
      final y = (baseY + progress * 42 + drift) % size.height;
      canvas.drawCircle(Offset(x, y), 1 + (i % 4) * 0.3, paint);
    }
  }

  @override
  bool shouldRepaint(covariant AmbientDustPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
