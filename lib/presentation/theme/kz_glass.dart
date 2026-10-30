import 'dart:ui' show ImageFilter;

import 'package:flutter/widgets.dart';

import 'kz_glass_theme.dart';
import 'kz_metrics.dart';
import 'kz_theme.dart';

/// Frosted surface. Use only over the ambient background: never on list rows,
/// never nested, and keep at most two blurred regions on screen.
class KzGlass extends StatelessWidget {
  const KzGlass({
    required this.level,
    required this.borderRadius,
    required this.child,
    super.key,
  });

  final KzGlassLevel level;
  final BorderRadius borderRadius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = KzTheme.of(context);
    final style = theme.glass.of(level);
    final reduced =
        KzTheme.reduceTransparencyOf(context) ||
        MediaQuery.highContrastOf(context);

    if (reduced) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: style.fallbackFill,
          borderRadius: borderRadius,
          border: Border.all(
            color: theme.scheme.border,
            width: KzStroke.hairline,
          ),
          boxShadow: style.fallbackShadows,
        ),
        child: ClipRRect(borderRadius: borderRadius, child: child),
      );
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: style.sigma,
          sigmaY: style.sigma,
          tileMode: TileMode.clamp,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: style.fill,
            borderRadius: borderRadius,
            border: Border.all(
              color: theme.glass.border,
              width: KzStroke.hairline,
            ),
          ),
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              child,
              Positioned(
                top: 0,
                left: borderRadius.topLeft.x,
                right: borderRadius.topRight.x,
                height: KzStroke.hairline,
                child: IgnorePointer(
                  child: ColoredBox(color: theme.glass.highlight),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
