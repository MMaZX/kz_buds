import 'package:flutter/widgets.dart';

import '../theme/kz_metrics.dart';
import '../theme/kz_motion.dart';
import '../theme/kz_theme.dart';
import 'kz_pressable.dart';

class KzSegment<T> {
  const KzSegment({
    required this.value,
    required this.label,
    required this.iconBuilder,
  });

  final T value;
  final String label;

  /// Builds the segment glyph in the color that contrasts with its fill.
  final Widget Function(Color color) iconBuilder;
}

/// Pill track holding one glyph per option; a light thumb slides under the
/// selected one. Labels sit below the track, one per segment.
class KzSegmentedSwitch<T> extends StatelessWidget {
  const KzSegmentedSwitch({
    required this.segments,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final List<KzSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onSelected;

  static const trackHeight = 72.0;
  static const _inset = 6.0;

  @override
  Widget build(BuildContext context) {
    final theme = KzTheme.of(context);
    final scheme = theme.scheme;
    final motion = KzMotion.of(context);
    final count = segments.length;
    final index = segments.indexWhere((s) => s.value == selected);
    final radius = BorderRadius.circular(KzRadii.pill);

    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: KzSpace.s16,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.background,
            borderRadius: radius,
          ),
          child: SizedBox(
            height: trackHeight,
            child: Padding(
              padding: const EdgeInsets.all(_inset),
              child: Stack(
                children: [
                  if (index >= 0)
                    AnimatedAlign(
                      duration: motion.base,
                      curve: KzMotion.baseCurve,
                      alignment: Alignment(
                        count == 1 ? 0 : -1 + 2 * index / (count - 1),
                        0,
                      ),
                      child: FractionallySizedBox(
                        widthFactor: 1 / count,
                        heightFactor: 1,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: scheme.foreground,
                            borderRadius: radius,
                          ),
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      for (final (i, segment) in segments.indexed)
                        Expanded(
                          child: KzPressable(
                            borderRadius: radius,
                            semanticsLabel: segment.label,
                            selected: i == index,
                            onPressed: () => onSelected(segment.value),
                            child: Center(
                              child: ExcludeSemantics(
                                child: segment.iconBuilder(
                                  i == index
                                      ? scheme.background
                                      : scheme.mutedForeground,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        ExcludeSemantics(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, segment) in segments.indexed)
                Expanded(
                  child: Text(
                    segment.label.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: theme.typography.label.copyWith(
                      color: i == index
                          ? scheme.foreground
                          : scheme.mutedForeground,
                      letterSpacing: 2,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
