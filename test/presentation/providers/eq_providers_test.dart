import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_buds/presentation/providers/eq_providers.dart';

void main() {
  late ProviderContainer container;
  late EqNotifier notifier;

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
    notifier = container.read(eqProvider.notifier);
  });

  EqState state() => container.read(eqProvider);

  test('starts flat with ten bands at 0 dB', () {
    expect(state().preset, EqPreset.flat);
    expect(state().gains, List.filled(10, 0.0));
    expect(eqBandLabels.length, 10);
  });

  test('selecting a preset applies its gains', () {
    notifier.selectPreset(EqPreset.bass);
    expect(state().preset, EqPreset.bass);
    expect(state().gains.first, greaterThan(0));
    expect(state().gains.last, 0);
  });

  test('editing a band switches to custom and keeps the others', () {
    notifier.selectPreset(EqPreset.bass);
    final before = List<double>.of(state().gains);
    notifier.setGain(3, -4);
    expect(state().preset, EqPreset.custom);
    expect(state().gains[3], -4);
    expect(state().gains[0], before[0]);
  });

  test('gains are clamped and snapped to half dB', () {
    notifier.setGain(0, 99);
    expect(state().gains[0], eqMaxGain);
    notifier.setGain(0, -99);
    expect(state().gains[0], eqMinGain);
    notifier.setGain(0, 1.26);
    expect(state().gains[0], 1.5);
  });

  test('selecting custom keeps the current gains', () {
    notifier.selectPreset(EqPreset.vocal);
    final gains = List<double>.of(state().gains);
    notifier.selectPreset(EqPreset.custom);
    expect(state().preset, EqPreset.custom);
    expect(state().gains, gains);
  });

  test('reset goes back to flat', () {
    notifier.setGain(2, 5);
    notifier.reset();
    expect(state().preset, EqPreset.flat);
    expect(state().gains, List.filled(10, 0.0));
  });

  test('formats gains for display', () {
    expect(formatGain(6), '+6');
    expect(formatGain(-2), '-2');
    expect(formatGain(0), '0');
    expect(formatGain(1.5), '+1.5');
    expect(formatGain(-0.5), '-0.5');
  });
}
