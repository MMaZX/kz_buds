import 'package:flutter/widgets.dart';

import 'kz_glass_theme.dart';
import 'kz_motion.dart';
import 'kz_palette.dart';
import 'kz_theme.dart';

/// The field glass sits on: a vertical gradient with two soft glows. Painted
/// once inside a [RepaintBoundary], so blur samples a cached layer.
class KzAmbientBackground extends StatelessWidget {
  const KzAmbientBackground({
    required this.child,
    this.glowScale = 1,
    super.key,
  });

  final Widget child;

  /// 1 is neutral. Below 1 tightens the glows, above 1 widens them.
  final double glowScale;

  @override
  Widget build(BuildContext context) {
    final ambient = KzTheme.of(context).ambient;
    final motion = KzMotion.of(context);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: glowScale),
      duration: motion.ambient,
      curve: KzMotion.ambientCurve,
      child: child,
      builder: (context, scale, child) => Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: CustomPaint(painter: _AmbientPainter(ambient, scale)),
          ),
          child!,
        ],
      ),
    );
  }
}

class _AmbientPainter extends CustomPainter {
  const _AmbientPainter(this.ambient, this.scale);

  final KzAmbientTheme ambient;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [ambient.top, ambient.bottom],
        ).createShader(rect),
    );
    _glow(canvas, rect, Offset(size.width, 0), 0.9, ambient.copperGlow);
    _glow(canvas, rect, Offset(0, size.height), 1.1, ambient.steelGlow);
  }

  void _glow(Canvas canvas, Rect rect, Offset center, double k, Color color) {
    final radius = rect.shortestSide * k * scale;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(colors: [color, KzPalette.transparent])
            .createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(_AmbientPainter old) =>
      old.scale != scale || old.ambient != ambient;
}
