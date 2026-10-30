import 'package:flutter/widgets.dart';

import '../theme/kz_metrics.dart';
import '../theme/kz_motion.dart';

/// Page shell: safe area and keyboard insets over the flat app background.
/// Replaces Scaffold for our own screens.
class KzPage extends StatelessWidget {
  const KzPage({
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: KzSpace.s20),
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final motion = KzMotion.of(context);

    return SafeArea(
      child: AnimatedPadding(
        duration: motion.fast,
        curve: KzMotion.fastCurve,
        padding: padding.copyWith(bottom: padding.bottom + keyboard),
        child: child,
      ),
    );
  }
}
