import 'package:flutter/widgets.dart';

import '../theme/kz_metrics.dart';
import '../theme/kz_theme.dart';

/// Battery with a continuous fill proportional to [level]. Critical levels and
/// charging use their own colors; charging also draws a bolt, so color is never
/// the only cue.
class KzBatteryGlyph extends StatelessWidget {
  const KzBatteryGlyph({
    required this.level,
    this.charging = false,
    this.width = 28,
    super.key,
  });

  final int level;
  final bool charging;
  final double width;

  @override
  Widget build(BuildContext context) {
    final theme = KzTheme.of(context);
    final clamped = level.clamp(0, 100);
    final label = charging
        ? 'Battery $clamped%, charging'
        : 'Battery $clamped%';

    return Semantics(
      label: label,
      excludeSemantics: true,
      child: CustomPaint(
        size: Size(width, width * 0.5),
        painter: KzBatteryPainter(
          fraction: clamped / 100,
          fill: charging ? theme.colors.success : theme.colors.battery(clamped),
          outline: theme.scheme.mutedForeground,
          boltColor: theme.scheme.background,
          charging: charging,
        ),
      ),
    );
  }
}

class KzBatteryPainter extends CustomPainter {
  const KzBatteryPainter({
    required this.fraction,
    required this.fill,
    required this.outline,
    required this.boltColor,
    required this.charging,
  });

  final double fraction;
  final Color fill;
  final Color outline;
  final Color boltColor;
  final bool charging;

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final nubW = h * 0.14;
    final bodyW = size.width - nubW;
    final stroke = KzStroke.icon;
    final radius = Radius.circular(h * 0.3);

    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(stroke / 2, stroke / 2, bodyW - stroke, h - stroke),
      radius,
    );
    canvas.drawRRect(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = outline,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(bodyW + nubW * 0.2, h * 0.32, nubW * 0.8, h * 0.36),
        Radius.circular(nubW),
      ),
      Paint()..color = outline,
    );

    final inset = stroke + 1.5;
    final innerW = bodyW - inset * 2;
    if (fraction > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(inset, inset, innerW * fraction, h - inset * 2),
          Radius.circular(h * 0.18),
        ),
        Paint()..color = fill,
      );
    }

    if (charging) {
      final cx = bodyW / 2;
      final cy = h / 2;
      final bolt = Path()
        ..moveTo(cx + h * 0.06, cy - h * 0.3)
        ..lineTo(cx - h * 0.16, cy + h * 0.04)
        ..lineTo(cx - h * 0.01, cy + h * 0.04)
        ..lineTo(cx - h * 0.06, cy + h * 0.3)
        ..lineTo(cx + h * 0.16, cy - h * 0.06)
        ..lineTo(cx + h * 0.01, cy - h * 0.06)
        ..close();
      canvas.drawPath(bolt, Paint()..color = boltColor);
    }
  }

  @override
  bool shouldRepaint(KzBatteryPainter old) =>
      old.fraction != fraction ||
      old.fill != fill ||
      old.outline != outline ||
      old.boltColor != boltColor ||
      old.charging != charging;
}
