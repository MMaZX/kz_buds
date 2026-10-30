import 'package:flutter/widgets.dart';

import '../theme/kz_metrics.dart';
import '../theme/kz_theme.dart';

/// Opaque panel with a hairline border. The default surface for grouped
/// content; glass is reserved for things that float over scrolling content.
class KzCard extends StatelessWidget {
  const KzCard({
    required this.child,
    this.radius = KzRadii.lg,
    this.padding = const EdgeInsets.all(KzSpace.s16),
    super.key,
  });

  final Widget child;
  final double radius;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final scheme = KzTheme.of(context).scheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.card,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: scheme.border, width: KzStroke.hairline),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
