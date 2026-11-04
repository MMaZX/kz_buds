import 'package:flutter/widgets.dart';

import '../theme/kz_metrics.dart';
import '../theme/kz_theme.dart';
import 'kz_card.dart';

/// Overline header over an opaque card.
class KzSection extends StatelessWidget {
  const KzSection({required this.title, required this.child, super.key});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = KzTheme.of(context);
    final scheme = theme.scheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title.toUpperCase(),
          style: theme.typography.overline.copyWith(
            color: scheme.mutedForeground,
          ),
        ),
        const SizedBox(height: KzSpace.s8),
        KzCard(child: child),
      ],
    );
  }
}
