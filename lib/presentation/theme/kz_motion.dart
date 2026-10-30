import 'package:flutter/widgets.dart';

/// Durations and curves. Every duration collapses to zero when the platform
/// asks for reduced motion.
class KzMotion {
  const KzMotion({required this.enabled});

  factory KzMotion.of(BuildContext context) =>
      KzMotion(enabled: !MediaQuery.disableAnimationsOf(context));

  final bool enabled;

  Duration _d(int ms) => enabled ? Duration(milliseconds: ms) : Duration.zero;

  Duration get press => _d(100);
  Duration get fast => _d(150);
  Duration get base => _d(200);
  Duration get slow => _d(320);
  Duration get ambient => _d(480);

  static const Curve pressCurve = Curves.easeOut;
  static const Curve fastCurve = Curves.easeOutCubic;
  static const Curve baseCurve = Curves.easeInOutCubic;
  static const Curve slowCurve = Cubic(0.2, 0, 0, 1);
  static const Curve ambientCurve = Curves.easeInOutSine;
}
