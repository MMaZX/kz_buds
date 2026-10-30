import 'package:flutter/widgets.dart';

import '../theme/kz_glass.dart';
import '../theme/kz_glass_theme.dart';
import '../theme/kz_metrics.dart';
import '../theme/kz_theme.dart';
import 'kz_pressable.dart';

/// Pill. Selected is the solid primary; unselected is outlined, or subtle
/// glass when it sits on the ambient background ([glass]).
class KzChip extends StatelessWidget {
  const KzChip({
    required this.label,
    required this.selected,
    this.onPressed,
    this.glass = false,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback? onPressed;
  final bool glass;

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

    final Widget body;
    if (selected) {
      body = DecoratedBox(
        decoration: BoxDecoration(color: scheme.primary, borderRadius: _radius),
        child: text,
      );
    } else if (glass) {
      body = KzGlass(
        level: KzGlassLevel.subtle,
        borderRadius: _radius,
        child: text,
      );
    } else {
      body = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: _radius,
          border: Border.all(color: scheme.border, width: KzStroke.hairline),
        ),
        child: text,
      );
    }

    return KzPressable(
      borderRadius: _radius,
      onPressed: onPressed,
      selected: selected,
      child: body,
    );
  }
}
