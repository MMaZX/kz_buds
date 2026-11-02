import 'package:flutter/widgets.dart';

import '../theme/kz_icons.dart';
import '../theme/kz_metrics.dart';
import '../theme/kz_theme.dart';
import 'kz_pressable.dart';

/// A bar with the back arrow on the left and the more button on the right,
/// then the title below it, aligned left. The bar exists only when it holds
/// an action; the more button only when [onMore] is given.
class KzPageHeader extends StatelessWidget {
  const KzPageHeader({
    required this.title,
    this.onBack,
    this.onMore,
    super.key,
  });

  final String title;
  final VoidCallback? onBack;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final theme = KzTheme.of(context);
    final back = onBack;
    final more = onMore;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (back != null || more != null) ...[
          Row(
            children: [
              if (back != null)
                _BarButton(icon: KzIcons.back, label: 'Back', onPressed: back),
              const Spacer(),
              if (more != null)
                _BarButton(
                  icon: KzIcons.more,
                  label: 'More options',
                  onPressed: more,
                ),
            ],
          ),
          const SizedBox(height: KzSpace.s16),
        ],
        Text(
          title,
          style: theme.typography.h1.copyWith(color: theme.scheme.foreground),
        ),
      ],
    );
  }
}

/// Bare icon: the arrow aligns with the title's left edge, so it carries no
/// leading padding.
class _BarButton extends StatelessWidget {
  const _BarButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final KzIconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => KzPressable(
    borderRadius: BorderRadius.circular(KzRadii.pill),
    semanticsLabel: label,
    onPressed: onPressed,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: KzSpace.s8),
      child: KzIcon(icon, size: 24),
    ),
  );
}
