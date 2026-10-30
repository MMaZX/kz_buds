import 'package:flutter/widgets.dart';

import '../theme/kz_colors.dart';
import '../theme/kz_icons.dart';
import '../theme/kz_metrics.dart';
import '../theme/kz_theme.dart';

/// Label, level and a thin bar. A `null` level means the device does not
/// report it, so nothing is drawn (AGENTS rule 4). Critical and charging
/// states always carry an icon, never color alone.
class KzBatteryIndicator extends StatelessWidget {
  const KzBatteryIndicator({
    required this.label,
    this.level,
    this.charging = false,
    super.key,
  });

  final String label;
  final int? level;
  final bool charging;

  @override
  Widget build(BuildContext context) {
    final value = level;
    if (value == null) return const SizedBox.shrink();

    final theme = KzTheme.of(context);
    final colors = theme.colors;
    final percent = value.clamp(0, 100);
    final critical = percent <= KzColors.criticalMaxLevel;
    final levelColor = colors.battery(percent);
    final barColor = charging ? colors.success : levelColor;
    final status = charging ? ', charging' : (critical ? ', low' : '');

    return Semantics(
      label: '$label battery $percent%$status',
      excludeSemantics: true,
      child: IntrinsicWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: theme.typography.overline.copyWith(
                    color: theme.scheme.mutedForeground,
                  ),
                ),
                if (charging) ...[
                  const SizedBox(width: KzSpace.s4),
                  KzIcon(
                    KzIcons.batteryCharging,
                    size: 14,
                    color: colors.success,
                  ),
                ] else if (critical) ...[
                  const SizedBox(width: KzSpace.s4),
                  KzIcon(
                    KzIcons.batteryLow,
                    size: 14,
                    color: colors.batteryCritical,
                  ),
                ],
              ],
            ),
            Text(
              '$percent%',
              style: theme.typography.numeralL.copyWith(color: levelColor),
            ),
            const SizedBox(height: KzSpace.s4),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.batteryTrack,
                borderRadius: BorderRadius.circular(KzRadii.pill),
              ),
              child: SizedBox(
                height: KzStroke.batteryBar,
                width: double.infinity,
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: percent / 100,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: barColor,
                      borderRadius: BorderRadius.circular(KzRadii.pill),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
