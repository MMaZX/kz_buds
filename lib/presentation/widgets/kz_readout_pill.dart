import 'package:flutter/widgets.dart';

import '../theme/kz_metrics.dart';
import '../theme/kz_theme.dart';

/// Read-only capsule that shows a value and where it sits in its range:
/// tinted up to a red marker line at [fraction], with the [label] centered.
class KzReadoutPill extends StatelessWidget {
  const KzReadoutPill({required this.label, required this.fraction, super.key});

  final String label;

  /// 0 to 1; values outside are clamped.
  final double fraction;

  static const height = 56.0;

  double get marker => fraction.clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final theme = KzTheme.of(context);
    final scheme = theme.scheme;

    return Semantics(
      container: true,
      readOnly: true,
      label: label,
      child: ExcludeSemantics(
        child: SizedBox(
          height: height,
          child: CustomPaint(
            painter: _ReadoutPainter(
              marker: marker,
              track: scheme.secondary,
              tint: theme.colors.brand.withValues(alpha: 0.18),
              line: theme.colors.brand,
              tick: scheme.border,
            ),
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.typography.bodyStrong.copyWith(
                  color: scheme.foreground,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReadoutPainter extends CustomPainter {
  const _ReadoutPainter({
    required this.marker,
    required this.track,
    required this.tint,
    required this.line,
    required this.tick,
  });

  final double marker;
  final Color track;
  final Color tint;
  final Color line;
  final Color tick;

  static const _tickInset = 0.12;

  @override
  void paint(Canvas canvas, Size size) {
    final pill = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.height / 2),
    );
    final x = marker * size.width;
    canvas
      ..save()
      ..clipRRect(pill)
      ..drawRRect(pill, Paint()..color = track)
      ..drawRect(Rect.fromLTRB(0, 0, x, size.height), Paint()..color = tint)
      ..restore();

    final tickPaint = Paint()
      ..color = tick
      ..strokeWidth = KzStroke.icon;
    for (final f in const [_tickInset, 1 - _tickInset]) {
      final tx = f * size.width;
      canvas.drawLine(
        Offset(tx, size.height * 0.4),
        Offset(tx, size.height * 0.6),
        tickPaint,
      );
    }
    canvas.drawLine(
      Offset(x, 0),
      Offset(x, size.height),
      Paint()
        ..color = line
        ..strokeWidth = KzStroke.iconEmphasis,
    );
  }

  @override
  bool shouldRepaint(_ReadoutPainter old) =>
      old.marker != marker ||
      old.track != track ||
      old.tint != tint ||
      old.line != line ||
      old.tick != tick;
}
