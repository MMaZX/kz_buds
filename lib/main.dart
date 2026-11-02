import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'data/fake/fake_earbuds_adapter.dart';
import 'data/rcsp/rcsp_earbuds_adapter.dart';
import 'data/rcsp/reconnect_supervisor.dart';
import 'data/spp/bluez_earbuds_discovery.dart';
import 'data/spp/linux/linux_rcsp_session.dart';
import 'data/spp/linux/linux_rfcomm_link.dart';
import 'domain/capabilities/capability.dart';
import 'domain/entities/earbuds_identity.dart';
import 'domain/ports/earbuds_port.dart';
import 'presentation/pages/app_shell.dart';
import 'presentation/providers/earbuds_providers.dart';
import 'presentation/providers/theme_providers.dart';
import 'presentation/theme/kz_licenses.dart';
import 'presentation/theme/kz_palette.dart';
import 'presentation/theme/kz_theme_scope.dart';

/// `--dart-define=KZ_FAKE=true` keeps the simulated earbuds on every platform.
const _useFake = bool.fromEnvironment('KZ_FAKE');

void main() {
  registerKzLicenses();
  runApp(
    ProviderScope(
      overrides: [earbudsPortProvider.overrideWithValue(_earbudsPort())],
      child: const KzBudsApp(),
    ),
  );
}

EarbudsPort _earbudsPort() {
  if (_useFake || !Platform.isLinux) {
    return FakeEarbudsAdapter(
      capabilities: {Capability.anc, Capability.eq},
      identity: const EarbudsIdentity(name: 'KZ Carol Pro'),
    );
  }
  final adapter = RcspEarbudsAdapter(
    () => openLinuxRcspSession(
      discover: BluezEarbudsDiscovery().pairedEarbuds,
      connectOs: bluezConnectProfiles,
      openLink: LinuxRfcommLink.connect,
      log: _reconnectLog,
    ),
  );
  unawaited(_superviseLinux(adapter));
  return adapter;
}

/// Hybrid reconnect: follow the OS link of the first detected earbuds and
/// keep the control session up while the OS has them.
Future<void> _superviseLinux(RcspEarbudsAdapter adapter) async {
  final found = await BluezEarbudsDiscovery().pairedEarbuds();
  if (found.isEmpty) {
    _reconnectLog('no paired JieLi earbuds found');
    return;
  }
  _reconnectLog('watching ${found.first.name}');
  ReconnectSupervisor(
    osLink: bluezConnectedChanges(found.first.id),
    session: adapter.watchConnection(),
    connect: adapter.connect,
    log: _reconnectLog,
  ).start();
}

void _reconnectLog(String message) => debugPrint('[reconnect] $message');

class KzBudsApp extends ConsumerWidget {
  const KzBudsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preference = ref.watch(themePreferenceProvider);

    return WidgetsApp(
      title: 'KZ Buds',
      debugShowCheckedModeBanner: false,
      color: KzPalette.inkBg,
      localizationsDelegates: const [
        GlobalShadLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      builder: (context, navigator) =>
          KzThemeScope(preference: preference, child: navigator!),
      home: const AppShell(),
      pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) =>
          PageRouteBuilder<T>(
            settings: settings,
            pageBuilder: (context, _, _) => builder(context),
          ),
    );
  }
}
