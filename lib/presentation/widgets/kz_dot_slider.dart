import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../theme/kz_theme.dart';

/// Vertical slider on a dotted track. The span from zero to the value fills
/// with the accent, and the thumb turns red once it leaves zero. Takes the
/// height of its parent.
class KzDotSlider extends StatelessWidget {
  const KzDotSlider({
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
    this.semanticsLabel,
    this.semanticsValue,
    super.key,
  }) : assert(min < max, 'min must be below max'),
       assert(step > 0, 'step must be positive');

  final double value;
  final double min;
  final double max;
  final double step;
  final ValueChanged<double>? onChanged;
  final String? semanticsLabel;

  /// Spoken value; defaults to the number without a trailing `.0`.
  final String? semanticsValue;

  static const width = 24.0;
  static const thumbSize = 18.0;
  static const dotSpacing = 16.0;
  static const _fillAlpha = 0.35;

  /// Where the fill starts: zero when the range spans it, else the bottom.
  double get _zero => min <= 0 && max >= 0 ? 0 : min;

  double _snap(double raw) =>
      ((raw.clamp(min, max) - min) / step).round() * step + min;

  static String _format(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  void _emit(double raw) {
    final next = _snap(raw).clamp(min, max);
    if (next != value) onChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = KzTheme.of(context);
    final scheme = theme.scheme;
    final brand = theme.colors.brand;
    final enabled = onChanged != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final usable = math.max(0.0, height - thumbSize);

        double valueAt(double dy) {
          final fraction = 1 - ((dy - thumbSize / 2) / usable).clamp(0.0, 1.0);
          return min + fraction * (max - min);
        }

        return Semantics(
          container: true,
          slider: true,
          enabled: enabled,
          label: semanticsLabel,
          value: semanticsValue ?? _format(value),
          increasedValue: _format(_snap(value + step).clamp(min, max)),
          decreasedValue: _format(_snap(value - step).clamp(min, max)),
          onIncrease: enabled ? () => _emit(value + step) : null,
          onDecrease: enabled ? () => _emit(value - step) : null,
          child: Focus(
            canRequestFocus: enabled,
            onKeyEvent: (node, event) {
              if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
                return KeyEventResult.ignored;
              }
              if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                _emit(value + step);
                return KeyEventResult.handled;
              }
              if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                _emit(value - step);
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: enabled
                  ? (details) => _emit(valueAt(details.localPosition.dy))
                  : null,
              onVerticalDragUpdate: enabled
                  ? (details) => _emit(valueAt(details.localPosition.dy))
                  : null,
              child: CustomPaint(
                size: Size(width, height),
                painter: KzDotSliderPainter(
                  fraction: (value.clamp(min, max) - min) / (max - min),
                  zeroFraction: (_zero - min) / (max - min),
                  dotCount: math.max(2, (usable / dotSpacing).floor() + 1),
                  track: scheme.secondary,
                  dot: scheme.border,
                  fill: brand.withValues(alpha: _fillAlpha),
                  thumb: value == _zero ? scheme.foreground : brand,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class KzDotSliderPainter extends CustomPainter {
  const KzDotSliderPainter({
    required this.fraction,
    required this.zeroFraction,
    required this.dotCount,
    required this.track,
    required this.dot,
    required this.fill,
    required this.thumb,
  });

  /// Position of the value from the bottom, 0 to 1.
  final double fraction;
  final double zeroFraction;
  final int dotCount;
  final Color track;
  final Color dot;
  final Color fill;
  final Color thumb;

  static const _dotRadius = 1.5;
  static const _fillInset = 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    const inset = KzDotSlider.thumbSize / 2;
    final usable = size.height - KzDotSlider.thumbSize;
    final centerX = size.width / 2;
    double yOf(double f) => inset + (1 - f) * usable;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(size.width / 2),
      ),
      Paint()..color = track,
    );

    final dotPaint = Paint()..color = dot;
    for (var i = 0; i < dotCount; i++) {
      final f = dotCount == 1 ? 0.5 : i / (dotCount - 1);
      canvas.drawCircle(Offset(centerX, yOf(f)), _dotRadius, dotPaint);
    }

    final valueY = yOf(fraction);
    final zeroY = yOf(zeroFraction);
    if (valueY != zeroY) {
      canvas.drawRRect(
        RRect.fromLTRBR(
          _fillInset,
          math.min(valueY, zeroY),
          size.width - _fillInset,
          math.max(valueY, zeroY),
          Radius.circular((size.width - _fillInset * 2) / 2),
        ),
        Paint()..color = fill,
      );
    }

    canvas.drawCircle(
      Offset(centerX, valueY),
      KzDotSlider.thumbSize / 2,
      Paint()..color = thumb,
    );
  }

  @override
  bool shouldRepaint(KzDotSliderPainter oldDelegate) =>
      fraction != oldDelegate.fraction ||
      zeroFraction != oldDelegate.zeroFraction ||
      dotCount != oldDelegate.dotCount ||
      track != oldDelegate.track ||
      dot != oldDelegate.dot ||
      fill != oldDelegate.fill ||
      thumb != oldDelegate.thumb;
}
