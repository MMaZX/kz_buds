import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../theme/kz_icons.dart';
import '../theme/kz_metrics.dart';
import '../theme/kz_motion.dart';
import '../theme/kz_theme.dart';

/// One frame of [KzLoadingSkeleton]: which icon shows and how.
@immutable
class KzSkeletonFrame {
  const KzSkeletonFrame({
    required this.index,
    required this.opacity,
    required this.scale,
  });

  static const still = KzSkeletonFrame(index: 0, opacity: 1, scale: 1);

  final int index;
  final double opacity;
  final double scale;
}

/// The frame at [progress] (0..1 over a loop of [count] icons). Within its
/// slot an icon fades in, holds and fades out, while it shrinks from
/// [KzLoadingSkeleton.maxScale] to [KzLoadingSkeleton.minScale].
KzSkeletonFrame kzSkeletonFrame(double progress, int count) {
  final phase = (progress % 1) * count;
  final index = math.min(phase.floor(), count - 1);
  final t = phase - index;
  const fade = 0.3;
  const curve = KzMotion.baseCurve;
  final opacity = t < fade
      ? curve.transform(t / fade)
      : t > 1 - fade
      ? curve.transform((1 - t) / fade)
      : 1.0;
  final scale =
      KzLoadingSkeleton.maxScale -
      (KzLoadingSkeleton.maxScale - KzLoadingSkeleton.minScale) *
          curve.transform(t);
  return KzSkeletonFrame(index: index, opacity: opacity, scale: scale);
}

/// A loading placeholder: earbud icons take turns in a soft circle that
/// breathes from large to small, with [label] explaining the wait. Still
/// when the platform asks for reduced motion.
class KzLoadingSkeleton extends StatefulWidget {
  const KzLoadingSkeleton({required this.label, super.key});

  final String label;

  static const iconPeriod = Duration(milliseconds: 1500);
  static const maxScale = 1.08;
  static const minScale = 0.92;
  static const icons = [
    KzIcons.earbuds,
    KzIcons.headphones,
    KzIcons.headset,
    KzIcons.bluetoothSearch,
  ];

  static const _circle = 160.0;

  @override
  State<KzLoadingSkeleton> createState() => _KzLoadingSkeletonState();
}

class _KzLoadingSkeletonState extends State<KzLoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: KzLoadingSkeleton.iconPeriod * KzLoadingSkeleton.icons.length,
  );

  bool get _animate => KzMotion.of(context).enabled;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_animate) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = KzTheme.of(context);
    final scheme = theme.scheme;

    const circle = KzLoadingSkeleton._circle;

    // FittedBox, not LayoutBuilder: hosts such as the home hero measure
    // intrinsic sizes, which LayoutBuilder cannot report.
    return Semantics(
      label: widget.label,
      liveRegion: true,
      excludeSemantics: true,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: KzSpace.s16,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final frame = _animate
                    ? kzSkeletonFrame(
                        _controller.value,
                        KzLoadingSkeleton.icons.length,
                      )
                    : KzSkeletonFrame.still;
                return Transform.scale(
                  scale: frame.scale,
                  child: Container(
                    width: circle,
                    height: circle,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: scheme.muted,
                      shape: BoxShape.circle,
                    ),
                    child: Opacity(
                      opacity: frame.opacity,
                      child: KzIcon(
                        KzLoadingSkeleton.icons[frame.index],
                        size: circle * 0.45,
                        color: scheme.mutedForeground,
                      ),
                    ),
                  ),
                );
              },
            ),
            Text(
              widget.label,
              textAlign: TextAlign.center,
              style: theme.typography.caption.copyWith(
                color: scheme.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
