import 'package:flutter/widgets.dart';

import '../theme/kz_ambient_background.dart';
import '../theme/kz_metrics.dart';
import '../theme/kz_motion.dart';

/// Page shell: ambient background, safe area and keyboard insets. Replaces
/// Scaffold for our own screens.
class KzPage extends StatelessWidget {
  const KzPage({
    required this.child,
    this.ambient = true,
    this.padding = const EdgeInsets.symmetric(horizontal: KzSpace.s20),
    super.key,
  });

  final Widget child;
  final bool ambient;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final motion = KzMotion.of(context);

    final content = SafeArea(
      child: AnimatedPadding(
        duration: motion.fast,
        curve: KzMotion.fastCurve,
        padding: padding.copyWith(bottom: padding.bottom + keyboard),
        child: child,
      ),
    );

    return ambient ? KzAmbientBackground(child: content) : content;
  }
}
