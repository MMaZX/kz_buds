import 'package:flutter/widgets.dart';

import '../theme/kz_icons.dart';
import '../theme/kz_metrics.dart';
import '../theme/kz_theme.dart';
import 'kz_pressable.dart';

class KzListRow extends StatelessWidget {
  const KzListRow({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    super.key,
  });

  final String title;
  final String? subtitle;
  final KzIconData? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = KzTheme.of(context);
    final scheme = theme.scheme;
    final lead = leading;
    final sub = subtitle;
    final end = trailing;

    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: KzSpace.s12),
      child: Row(
        children: [
          if (lead != null) ...[
            KzIcon(lead, color: scheme.mutedForeground),
            const SizedBox(width: KzSpace.s12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.typography.bodyStrong.copyWith(
                    color: scheme.foreground,
                  ),
                ),
                if (sub != null)
                  Text(
                    sub,
                    style: theme.typography.caption.copyWith(
                      color: scheme.mutedForeground,
                    ),
                  ),
              ],
            ),
          ),
          if (end != null) ...[const SizedBox(width: KzSpace.s12), end],
        ],
      ),
    );

    if (onTap == null) return row;
    return KzPressable(
      borderRadius: BorderRadius.circular(KzRadii.md),
      onPressed: onTap,
      child: row,
    );
  }
}
