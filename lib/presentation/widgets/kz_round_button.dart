import 'package:flutter/widgets.dart';

import '../theme/kz_icons.dart';
import '../theme/kz_metrics.dart';
import '../theme/kz_theme.dart';
import 'kz_pressable.dart';

/// 56 px circular button with an icon and an optional uppercase label below.
class KzRoundButton extends StatelessWidget {
  const KzRoundButton({
    required this.icon,
    this.label,
    this.onPressed,
    this.selected = false,
    super.key,
  });

  final KzIconData icon;
  final String? label;
  final VoidCallback? onPressed;
  final bool selected;

  static const size = 56.0;

  @override
  Widget build(BuildContext context) {
    final theme = KzTheme.of(context);
    final scheme = theme.scheme;
    final text = label;

    return KzPressable(
      borderRadius: BorderRadius.circular(KzRadii.xl),
      onPressed: onPressed,
      selected: selected,
      semanticsLabel: text,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            key: const ValueKey('kz-round-button-circle'),
            dimension: size,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: selected ? scheme.primary : scheme.secondary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: KzIcon(
                  icon,
                  size: 22,
                  emphasized: selected,
                  color: selected
                      ? scheme.primaryForeground
                      : scheme.foreground,
                ),
              ),
            ),
          ),
          if (text != null) ...[
            const SizedBox(height: KzSpace.s8),
            ExcludeSemantics(
              child: Text(
                text.toUpperCase(),
                style: theme.typography.overline.copyWith(
                  color: scheme.mutedForeground,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
