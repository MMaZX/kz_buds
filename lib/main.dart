import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'data/fake/fake_earbuds_adapter.dart';
import 'presentation/pages/device_home_page.dart';
import 'presentation/providers/earbuds_providers.dart';
import 'presentation/providers/theme_providers.dart';
import 'presentation/providers/visual_settings_providers.dart';
import 'presentation/theme/kz_licenses.dart';
import 'presentation/theme/kz_palette.dart';
import 'presentation/theme/kz_theme_scope.dart';

void main() {
  registerKzLicenses();
  runApp(
    ProviderScope(
      overrides: [earbudsPortProvider.overrideWithValue(FakeEarbudsAdapter())],
      child: const KzBudsApp(),
    ),
  );
}

class KzBudsApp extends ConsumerWidget {
  const KzBudsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preference = ref.watch(themePreferenceProvider);
    final reduceTransparency = ref.watch(
      visualSettingsProvider.select((s) => s.reduceTransparency),
    );

    return WidgetsApp(
      title: 'KZ Buds',
      color: KzPalette.ink950,
      localizationsDelegates: const [
        GlobalShadLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      builder: (context, navigator) => KzThemeScope(
        preference: preference,
        reduceTransparency: reduceTransparency,
        child: navigator!,
      ),
      home: const DeviceHomePage(),
      pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) =>
          PageRouteBuilder<T>(
            settings: settings,
            pageBuilder: (context, _, _) => builder(context),
          ),
    );
  }
}
