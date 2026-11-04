import 'package:flutter/widgets.dart';

import '../theme/kz_metrics.dart';
import '../theme/kz_theme.dart';
import 'kz_pressable.dart';

/// Wide pill with an uppercase label: outlined for secondary actions,
/// filled for the one the screen leads with. It stretches to its parent.
class KzPillButton extends StatelessWidget {
  const KzPillButton({
    required this.label,
    this.onPressed,
    this.leading,
    this.filled = false,
    this.semanticsLabel,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? leading;
  final bool filled;
  final String? semanticsLabel;

  static const height = 56.0;

  @override
  Widget build(BuildContext context) {
    final theme = KzTheme.of(context);
    final scheme = theme.scheme;
    final radius = BorderRadius.circular(KzRadii.pill);

    return KzPressable(
      borderRadius: radius,
      onPressed: onPressed,
      semanticsLabel: semanticsLabel ?? label,
      child: DecoratedBox(
        decoration: filled
            ? BoxDecoration(color: scheme.secondary, borderRadius: radius)
            : BoxDecoration(
                borderRadius: radius,
                border: Border.all(
                  color: scheme.border,
                  width: KzStroke.hairline,
                ),
              ),
        child: SizedBox(
          height: height,
          child: ExcludeSemantics(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: KzSpace.s12,
              children: [
                ?leading,
                Text(
                  label.toUpperCase(),
                  style: theme.typography.overline.copyWith(
                    color: filled
                        ? scheme.secondaryForeground
                        : scheme.foreground,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
