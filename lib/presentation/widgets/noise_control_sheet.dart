import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../domain/entities/anc_mode.dart';
import '../providers/earbuds_providers.dart';
import '../theme/kz_metrics.dart';
import '../theme/kz_palette.dart';
import '../theme/kz_theme.dart';
import 'kz_anc_icon.dart';
import 'kz_segmented_switch.dart';

Future<void> showNoiseControlSheet(BuildContext context) => showShadSheet<void>(
  context: context,
  side: ShadSheetSide.bottom,
  builder: (_) => const NoiseControlSheet(),
);

/// Bottom sheet to pick the noise-control mode without leaving the home.
class NoiseControlSheet extends ConsumerWidget {
  const NoiseControlSheet({super.key});

  static const _modes = [AncMode.noiseCancelling, AncMode.ambient, AncMode.off];

  static const maxWidth = 460.0;
  static const _margin = KzSpace.s12;
  static const cardKey = ValueKey('noise-control-card');

  static const _handleWidth = 40.0;
  static const _handleHeight = 5.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = KzTheme.of(context);
    final scheme = theme.scheme;
    final mode = ref.watch(ancModeProvider).value ?? AncMode.off;

    return ShadSheet(
      closeIcon: const SizedBox.shrink(),
      expandCrossSide: false,
      constraints: const BoxConstraints(maxWidth: maxWidth + 2 * _margin),
      draggable: true,
      backgroundColor: KzPalette.transparent,
      border: const Border(),
      shadows: const [],
      radius: BorderRadius.zero,
      padding: EdgeInsets.zero,
      // The card floats inside the sheet so all four corners stay rounded.
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.all(_margin),
        child: DecoratedBox(
          key: cardKey,
          decoration: BoxDecoration(
            color: scheme.card,
            borderRadius: BorderRadius.circular(KzRadii.xl),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              KzSpace.s24,
              KzSpace.s12,
              KzSpace.s24,
              KzSpace.s40,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: KzSpace.s32,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.mutedForeground,
                    borderRadius: BorderRadius.circular(KzRadii.pill),
                  ),
                  child: const SizedBox(
                    width: _handleWidth,
                    height: _handleHeight,
                  ),
                ),
                Text(
                  'NOISE CONTROL',
                  textAlign: TextAlign.center,
                  style: theme.typography.h2.copyWith(
                    color: scheme.foreground,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
                KzSegmentedSwitch<AncMode>(
                  selected: mode,
                  onSelected: ref.read(earbudsPortProvider).setAncMode,
                  segments: [
                    for (final value in _modes)
                      KzSegment(
                        value: value,
                        label: KzAncIcon.labelFor(value),
                        iconBuilder: (color) =>
                            KzAncIcon(mode: value, size: 28, color: color),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
