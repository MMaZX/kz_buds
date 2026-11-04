import 'package:flutter/widgets.dart';

import '../theme/kz_icons.dart';
import '../theme/kz_metrics.dart';
import '../theme/kz_motion.dart';
import '../theme/kz_theme.dart';
import 'kz_pressable.dart';

/// ON/OFF toggle: a pill holding its state label and a knob with a power glyph.
class KzPowerPill extends StatelessWidget {
  const KzPowerPill({required this.value, required this.onChanged, super.key});

  final bool value;
  final ValueChanged<bool>? onChanged;

  static const _width = 76.0;
  static const _height = 36.0;
  static const _knob = 28.0;

  @override
  Widget build(BuildContext context) {
    final theme = KzTheme.of(context);
    final scheme = theme.scheme;
    final motion = KzMotion.of(context);
    final radius = BorderRadius.circular(KzRadii.pill);
    final callback = onChanged;

    return KzPressable(
      borderRadius: radius,
      toggled: value,
      semanticsLabel: 'Power',
      onPressed: callback == null ? null : () => callback(!value),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.secondary,
          borderRadius: radius,
        ),
        child: SizedBox(
          width: _width,
          height: _height,
          child: Padding(
            padding: const EdgeInsets.all(KzSpace.s4),
            child: Stack(
              children: [
                Align(
                  alignment: value
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: KzSpace.s8),
                    child: Text(
                      value ? 'ON' : 'OFF',
                      style: theme.typography.overline.copyWith(
                        color: scheme.foreground,
                      ),
                    ),
                  ),
                ),
                AnimatedAlign(
                  alignment: value
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  duration: motion.fast,
                  curve: KzMotion.fastCurve,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: value ? scheme.primary : scheme.muted,
                      shape: BoxShape.circle,
                    ),
                    child: SizedBox.square(
                      dimension: _knob,
                      child: Center(
                        child: KzIcon(
                          KzIcons.power,
                          size: 16,
                          color: value
                              ? scheme.primaryForeground
                              : scheme.mutedForeground,
                        ),
                      ),
                    ),
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
