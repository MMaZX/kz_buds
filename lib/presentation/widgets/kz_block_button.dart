import 'package:flutter/widgets.dart';

import '../theme/kz_metrics.dart';
import '../theme/kz_theme.dart';
import 'kz_pressable.dart';

/// Solid red block for the one primary or destructive action of a screen.
/// Use it once per screen at most: it is the loudest thing on it.
class KzBlockButton extends StatelessWidget {
  const KzBlockButton({required this.label, this.onPressed, super.key});

  final String label;
  final VoidCallback? onPressed;

  static const minSize = 72.0;

  @override
  Widget build(BuildContext context) {
    final theme = KzTheme.of(context);
    final colors = theme.colors;
    final radius = BorderRadius.circular(KzRadii.md);

    return KzPressable(
      borderRadius: radius,
      onPressed: onPressed,
      semanticsLabel: label,
      child: DecoratedBox(
        key: const ValueKey('kz-block-button-fill'),
        decoration: BoxDecoration(color: colors.brand, borderRadius: radius),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: minSize,
            minHeight: minSize,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: KzSpace.s20),
            child: Center(
              widthFactor: 1,
              child: ExcludeSemantics(
                child: Text(
                  label.toUpperCase(),
                  style: theme.typography.overline.copyWith(
                    color: colors.brandForeground,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
