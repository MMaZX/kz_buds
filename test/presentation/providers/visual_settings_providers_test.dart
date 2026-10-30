import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_buds/presentation/providers/visual_settings_providers.dart';

void main() {
  test('reduce transparency is off by default and can be toggled', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(visualSettingsProvider).reduceTransparency, isFalse);

    container.read(visualSettingsProvider.notifier).setReduceTransparency(true);
    expect(container.read(visualSettingsProvider).reduceTransparency, isTrue);
  });
}
