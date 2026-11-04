import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_buds/data/fake/fake_earbuds_adapter.dart';
import 'package:kz_buds/domain/capabilities/capability.dart';
import 'package:kz_buds/domain/entities/eq_settings.dart';
import 'package:kz_buds/presentation/providers/earbuds_providers.dart';
import 'package:kz_buds/presentation/providers/eq_providers.dart';

void main() {
  ProviderContainer containerWith(FakeEarbudsAdapter fake) {
    final container = ProviderContainer(
      overrides: [earbudsPortProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);
    addTearDown(fake.dispose);
    return container;
  }

  test('reads the profile and the settings from the port', () async {
    final container = containerWith(
      FakeEarbudsAdapter(capabilities: {Capability.eq}),
    );

    // Riverpod pauses providers nobody listens to.
    container.listen(eqSettingsProvider, (_, _) {});
    final profile = await container.read(eqProfileProvider.future);
    expect(profile, same(FakeEarbudsAdapter.eqDevProfile));
    expect(
      await container.read(eqSettingsProvider.future),
      EqSettings(mode: 0, gains: List.filled(10, 0)),
    );
  });

  test('no profile without the EQ capability', () async {
    final container = containerWith(FakeEarbudsAdapter());

    expect(await container.read(eqProfileProvider.future), isNull);
  });

  test('labels a preset by name, else Custom or its number', () {
    const profile = EqProfile(
      frequencies: [1000],
      presets: [
        EqPresetData(mode: 0, gains: [0], name: 'Flat'),
        EqPresetData(mode: 1, gains: [0]),
        EqPresetData(mode: 6, gains: [0]),
      ],
      customMode: 6,
      minGain: -12,
      maxGain: 12,
    );

    expect(profile.presets.map((p) => eqPresetLabel(profile, p)), [
      'Flat',
      'Preset 2',
      'Custom',
    ]);
  });

  test('model names win over numbers but not over the preset own name', () {
    const profile = EqProfile(
      frequencies: [1000],
      presets: [
        EqPresetData(mode: 0, gains: [0], name: 'Own'),
        EqPresetData(mode: 1, gains: [0]),
        EqPresetData(mode: 2, gains: [0]),
        EqPresetData(mode: 6, gains: [0]),
      ],
      customMode: 6,
      minGain: -12,
      maxGain: 12,
    );
    const names = {0: 'Standard', 1: 'Bass Enhancement'};

    expect(
      profile.presets.map((p) => eqPresetLabel(profile, p, names: names)),
      ['Own', 'Bass Enhancement', 'Preset 3', 'Custom'],
    );
  });
}
