import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/eq_providers.dart';
import '../theme/kz_metrics.dart';
import '../theme/kz_theme.dart';
import '../widgets/kz_block_button.dart';
import '../widgets/kz_chip.dart';
import '../widgets/kz_dot_slider.dart';
import '../widgets/kz_page.dart';
import '../widgets/kz_page_header.dart';
import '../widgets/kz_section.dart';
import 'app_shell.dart';

class EqPage extends ConsumerWidget {
  const EqPage({super.key});

  static const _presetLabels = {
    EqPreset.flat: 'Flat',
    EqPreset.bass: 'Bass',
    EqPreset.vocal: 'Vocal',
    EqPreset.custom: 'Custom',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eq = ref.watch(eqProvider);
    final notifier = ref.read(eqProvider.notifier);

    return KzPage(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: KzSpace.s16),
            const KzPageHeader(title: 'Equalizer'),
            const SizedBox(height: KzSpace.s24),
            Wrap(
              spacing: KzSpace.s8,
              runSpacing: KzSpace.s8,
              children: [
                for (final entry in _presetLabels.entries)
                  KzChip(
                    label: entry.value,
                    selected: eq.preset == entry.key,
                    onPressed: () => notifier.selectPreset(entry.key),
                  ),
              ],
            ),
            const SizedBox(height: KzSpace.s24),
            KzSection(
              title: 'Bands (dB)',
              child: Row(
                children: [
                  for (var i = 0; i < eqBandLabels.length; i++)
                    Expanded(
                      child: _Band(
                        label: eqBandLabels[i],
                        gain: eq.gains[i],
                        onChanged: (value) => notifier.setGain(i, value),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: KzSpace.s16),
            Align(
              alignment: Alignment.centerLeft,
              child: KzBlockButton(label: 'Reset', onPressed: notifier.reset),
            ),
            const SizedBox(height: AppShell.navClearance),
          ],
        ),
      ),
    );
  }
}

class _Band extends StatelessWidget {
  const _Band({
    required this.label,
    required this.gain,
    required this.onChanged,
  });

  final String label;
  final double gain;
  final ValueChanged<double> onChanged;

  static const _trackLength = 180.0;

  @override
  Widget build(BuildContext context) {
    final theme = KzTheme.of(context);
    final scheme = theme.scheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          formatGain(gain),
          style: theme.typography.caption.copyWith(color: scheme.foreground),
        ),
        const SizedBox(height: KzSpace.s8),
        SizedBox(
          height: _trackLength,
          child: KzDotSlider(
            value: gain,
            min: eqMinGain,
            max: eqMaxGain,
            step: eqGainStep,
            semanticsLabel: label,
            semanticsValue: '${formatGain(gain)} dB',
            onChanged: onChanged,
          ),
        ),
        const SizedBox(height: KzSpace.s8),
        Text(
          label,
          style: theme.typography.caption.copyWith(
            color: scheme.mutedForeground,
          ),
        ),
      ],
    );
  }
}
