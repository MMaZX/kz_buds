import 'package:flutter/widgets.dart';

import '../theme/kz_motion.dart';
import '../theme/kz_theme.dart';

/// Slides in from the right over an opaque page. No fade: pages have no
/// background of their own, so a fade would show the page underneath through
/// the new one. Durations collapse with reduced motion.
PageRoute<T> kzRoute<T>(BuildContext context, WidgetBuilder builder) {
  final motion = KzMotion.of(context);
  final background = KzTheme.of(context).scheme.background;

  return PageRouteBuilder<T>(
    transitionDuration: motion.slow,
    reverseTransitionDuration: motion.base,
    pageBuilder: (context, _, _) =>
        ColoredBox(color: background, child: builder(context)),
    transitionsBuilder: (context, animation, _, child) => SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: KzMotion.slowCurve)),
      child: child,
    ),
  );
}
