import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/kz_theme_preference.dart';

class ThemePreferenceNotifier extends Notifier<KzThemePreference> {
  @override
  KzThemePreference build() => KzThemePreference.system;

  void set(KzThemePreference preference) => state = preference;
}

/// In memory for now; persistence arrives later through a settings port.
final themePreferenceProvider =
    NotifierProvider<ThemePreferenceNotifier, KzThemePreference>(
      ThemePreferenceNotifier.new,
    );
