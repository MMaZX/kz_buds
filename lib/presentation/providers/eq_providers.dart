import 'package:flutter_riverpod/flutter_riverpod.dart';

enum EqPreset { flat, bass, vocal, custom }

/// Band centers in Hz. Placeholder layout until Phase 2 reports what the
/// device actually exposes; the EQ state is UI-only until then.
const eqBandLabels = [
  '31',
  '62',
  '125',
  '250',
  '500',
  '1k',
  '2k',
  '4k',
  '8k',
  '16k',
];

const eqMinGain = -12.0;
const eqMaxGain = 12.0;
const eqGainStep = 0.5;

const _flat = <double>[0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
const _bass = <double>[6, 5, 4, 2, 0, 0, 0, 0, 0, 0];
const _vocal = <double>[-2, -1, 0, 1, 3, 4, 3, 1, 0, -1];

String formatGain(double gain) {
  final text = gain == gain.roundToDouble()
      ? gain.toStringAsFixed(0)
      : gain.toStringAsFixed(1);
  return gain > 0 ? '+$text' : text;
}

class EqState {
  const EqState({required this.preset, required this.gains});

  final EqPreset preset;
  final List<double> gains;
}

class EqNotifier extends Notifier<EqState> {
  @override
  EqState build() => const EqState(preset: EqPreset.flat, gains: _flat);

  void selectPreset(EqPreset preset) {
    state = switch (preset) {
      EqPreset.flat => const EqState(preset: EqPreset.flat, gains: _flat),
      EqPreset.bass => const EqState(preset: EqPreset.bass, gains: _bass),
      EqPreset.vocal => const EqState(preset: EqPreset.vocal, gains: _vocal),
      EqPreset.custom => EqState(preset: EqPreset.custom, gains: state.gains),
    };
  }

  void setGain(int band, double gain) {
    final snapped =
        (gain.clamp(eqMinGain, eqMaxGain) / eqGainStep).round() * eqGainStep;
    final gains = List<double>.of(state.gains)..[band] = snapped;
    state = EqState(preset: EqPreset.custom, gains: gains);
  }

  void reset() => selectPreset(EqPreset.flat);
}

final eqProvider = NotifierProvider<EqNotifier, EqState>(EqNotifier.new);
