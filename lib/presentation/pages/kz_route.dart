import 'package:flutter/widgets.dart';

import '../theme/kz_motion.dart';

/// Fade plus a small rise. Durations collapse with reduced motion.
PageRoute<T> kzRoute<T>(BuildContext context, WidgetBuilder builder) {
  final motion = KzMotion.of(context);
  return PageRouteBuilder<T>(
    transitionDuration: motion.slow,
    reverseTransitionDuration: motion.base,
    pageBuilder: (context, _, _) => builder(context),
    transitionsBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: KzMotion.slowCurve,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.02),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
