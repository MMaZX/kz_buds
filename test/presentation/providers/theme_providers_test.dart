import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_buds/presentation/providers/theme_providers.dart';
import 'package:kz_buds/presentation/theme/kz_theme_preference.dart';

void main() {
  test('defaults to following the system', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(themePreferenceProvider), KzThemePreference.system);
  });

  test('can be set to light, dark and back to system', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(themePreferenceProvider.notifier);
    notifier.set(KzThemePreference.light);
    expect(container.read(themePreferenceProvider), KzThemePreference.light);
    notifier.set(KzThemePreference.dark);
    expect(container.read(themePreferenceProvider), KzThemePreference.dark);
    notifier.set(KzThemePreference.system);
    expect(container.read(themePreferenceProvider), KzThemePreference.system);
  });
}
