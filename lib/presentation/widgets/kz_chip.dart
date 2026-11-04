import 'package:flutter/widgets.dart';

import '../theme/kz_metrics.dart';
import '../theme/kz_theme.dart';
import 'kz_pressable.dart';

/// Pill. Selected is the solid primary; unselected is a hairline outline.
class KzChip extends StatelessWidget {
  const KzChip({
    required this.label,
    required this.selected,
    this.onPressed,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback? onPressed;

  static final _radius = BorderRadius.circular(KzRadii.pill);

  @override
  Widget build(BuildContext context) {
    final theme = KzTheme.of(context);
    final scheme = theme.scheme;
    final text = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: KzSpace.s16,
        vertical: KzSpace.s8,
      ),
      child: Text(
        label,
        style: theme.typography.label.copyWith(
          color: selected ? scheme.primaryForeground : scheme.foreground,
        ),
      ),
    );

    return KzPressable(
      borderRadius: _radius,
      onPressed: onPressed,
      selected: selected,
      child: DecoratedBox(
        decoration: selected
            ? BoxDecoration(color: scheme.primary, borderRadius: _radius)
            : BoxDecoration(
                borderRadius: _radius,
                border: Border.all(
                  color: scheme.border,
                  width: KzStroke.hairline,
                ),
              ),
        child: text,
      ),
    );
  }
}
