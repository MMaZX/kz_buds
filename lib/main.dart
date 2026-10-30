import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/fake/fake_earbuds_adapter.dart';
import 'presentation/pages/device_home_page.dart';
import 'presentation/providers/earbuds_providers.dart';
import 'presentation/theme/kz_licenses.dart';
import 'presentation/theme/kz_palette.dart';

void main() {
  registerKzLicenses();
  runApp(
    ProviderScope(
      overrides: [earbudsPortProvider.overrideWithValue(FakeEarbudsAdapter())],
      child: const KzBudsApp(),
    ),
  );
}

class KzBudsApp extends StatelessWidget {
  const KzBudsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      title: 'KZ Buds',
      color: KzPalette.ink950,
      textStyle: const TextStyle(color: KzPalette.paper, fontSize: 16),
      home: const DeviceHomePage(),
      pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) =>
          PageRouteBuilder<T>(
            settings: settings,
            pageBuilder: (context, _, _) => builder(context),
          ),
    );
  }
}
