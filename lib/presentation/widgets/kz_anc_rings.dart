import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../domain/entities/anc_mode.dart';
import '../theme/kz_metrics.dart';
import '../theme/kz_theme.dart';

/// Noise-control mode as concentric arcs: none for off, two for noise
/// cancelling, three for ambient.
class KzAncRings extends StatelessWidget {
  const KzAncRings({required this.mode, this.size = 48, this.color, super.key});

  final AncMode mode;
  final double size;
  final Color? color;

  static int ringsFor(AncMode mode) => switch (mode) {
    AncMode.off => 0,
    AncMode.noiseCancelling => 2,
    AncMode.ambient => 3,
  };

  static String labelFor(AncMode mode) => switch (mode) {
    AncMode.off => 'Off',
    AncMode.noiseCancelling => 'Noise cancelling',
    AncMode.ambient => 'Ambient',
  };

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: labelFor(mode),
      excludeSemantics: true,
      child: CustomPaint(
        size: Size.square(size),
        painter: KzAncRingsPainter(
          ringCount: ringsFor(mode),
          color: color ?? KzTheme.of(context).scheme.foreground,
        ),
      ),
    );
  }
}

class KzAncRingsPainter extends CustomPainter {
  const KzAncRingsPainter({required this.ringCount, required this.color});

  final int ringCount;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final unit = size.shortestSide / 2 / 4;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = KzStroke.icon
      ..strokeCap = StrokeCap.round
      ..color = color;

    canvas.drawCircle(center, unit * 0.7, Paint()..color = color);

    const sweep = math.pi / 2.4;
    for (var i = 1; i <= ringCount; i++) {
      final rect = Rect.fromCircle(center: center, radius: unit * (1 + i));
      canvas
        ..drawArc(rect, -sweep / 2, sweep, false, paint)
        ..drawArc(rect, math.pi - sweep / 2, sweep, false, paint);
    }
  }

  @override
  bool shouldRepaint(KzAncRingsPainter old) =>
      old.ringCount != ringCount || old.color != color;
}
