import 'package:flutter/widgets.dart';

import '../theme/kz_metrics.dart';
import '../theme/kz_motion.dart';
import '../theme/kz_theme.dart';

/// Read-only capsule that shows a value and where it sits in its range:
/// tinted up to a red marker line at [fraction], with the [label] centered.
/// A new [fraction] glides there; only the painter repaints on each tick.
class KzReadoutPill extends StatefulWidget {
  const KzReadoutPill({required this.label, required this.fraction, super.key});

  final String label;

  /// 0 to 1; values outside are clamped.
  final double fraction;

  static const height = 56.0;

  double get marker => fraction.clamp(0.0, 1.0);

  @override
  State<KzReadoutPill> createState() => _KzReadoutPillState();
}

class _KzReadoutPillState extends State<KzReadoutPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glide = AnimationController(vsync: this)
    ..value = 1;
  late double _from = widget.marker;
  late double _to = widget.marker;

  double get _shown =>
      _from + (_to - _from) * KzMotion.valueCurve.transform(_glide.value);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _glide.duration = KzMotion.of(context).value;
  }

  @override
  void didUpdateWidget(KzReadoutPill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.marker == _to) return;
    _from = _shown;
    _to = widget.marker;
    _glide.forward(from: 0);
  }

  @override
  void dispose() {
    _glide.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = KzTheme.of(context);
    final scheme = theme.scheme;

    return Semantics(
      container: true,
      readOnly: true,
      label: widget.label,
      child: ExcludeSemantics(
        child: SizedBox(
          height: KzReadoutPill.height,
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _ReadoutPainter(
                shown: () => _shown,
                glide: _glide,
                track: scheme.secondary,
                tint: theme.colors.brand.withValues(alpha: 0.18),
                line: theme.colors.brand,
                tick: scheme.border,
              ),
              child: Center(
                child: Text(
                  widget.label,
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
      ),
    );
  }
}

class _ReadoutPainter extends CustomPainter {
  _ReadoutPainter({
    required this.shown,
    required Listenable glide,
    required this.track,
    required this.tint,
    required this.line,
    required this.tick,
  }) : super(repaint: glide);

  final ValueGetter<double> shown;
  final Color track;
  final Color tint;
  final Color line;
  final Color tick;

  static const _tickInset = 0.12;

  /// Where the marker is drawn right now.
  double get marker => shown();

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
      old.track != track ||
      old.tint != tint ||
      old.line != line ||
      old.tick != tick ||
      old.marker != marker;
}
