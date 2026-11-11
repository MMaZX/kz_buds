import 'dart:async';
import 'dart:io';

import 'package:bluetooth_rfcomm/bluetooth_rfcomm.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'core/debug_log.dart';
import 'data/fake/fake_earbuds_adapter.dart';
import 'data/rcsp/rcsp_earbuds_adapter.dart';
import 'data/rcsp/reconnect_supervisor.dart';
import 'data/spp/android/android_bluetooth_access.dart';
import 'data/spp/android/android_connected_audio.dart';
import 'data/spp/android/android_rcsp_candidates.dart';
import 'data/spp/android/android_rcsp_session.dart';
import 'data/spp/android/rfcomm_earbuds_discovery.dart';
import 'data/spp/bluez_earbuds_discovery.dart';
import 'data/spp/linux/linux_rcsp_session.dart';
import 'data/spp/linux/linux_rfcomm_link.dart';
import 'data/spp/rfcomm_package_link.dart';
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
  final port = _earbudsPort();
  runApp(
    ProviderScope(
      overrides: [earbudsPortProvider.overrideWithValue(port)],
      child: const KzBudsApp(),
    ),
  );
  if (port is RcspEarbudsAdapter && Platform.isAndroid) {
    // After the first frame, so the permission dialog has an activity. This
    // first attempt is the one that asks for access; the supervisor never
    // tries while the OS cannot tell what is connected.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        port.connect().catchError(
          (Object error) => _reconnectLog('connect failed: $error'),
        ),
      );
      _superviseAndroid(port);
    });
  }
}

EarbudsPort _earbudsPort() {
  if (!_useFake && Platform.isAndroid) return _androidAdapter();
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
      log: _reconnectLog.call,
    ),
  );
  unawaited(_superviseLinux(adapter));
  return adapter;
}

final _androidCandidates = AndroidRcspCandidates();

/// Android keeps the audio profiles up on its own; we only open SPP.
RcspEarbudsAdapter _androidAdapter() {
  final bluetooth = BluetoothRfcomm.instance;
  final discovery = RfcommEarbudsDiscovery(
    bluetooth,
    connectedAddresses: () async {
      final connected = await androidConnectedAudioAddresses();
      _androidCandidates.update(connected);
      return connected;
    },
    log: _reconnectLog.call,
  );
  return RcspEarbudsAdapter(
    () => openAndroidRcspSession(
      requestAccess: requestBluetoothConnect,
      discover: () async =>
          _androidCandidates.prioritize(await discovery.pairedEarbuds()),
      // Short: each wrong candidate costs this much before the next one.
      openLink: (id) => RfcommPackageLink.connect(
        bluetooth,
        id,
        timeout: const Duration(seconds: 6),
      ),
      onProven: _androidCandidates.proven,
      onFailed: _androidCandidates.failed,
      log: _reconnectLog.call,
    ),
  );
}

/// Event-driven reconnect: Android signals each audio connection change, and
/// the control session is kept up while a connected device is worth trying.
/// Needs the Flutter binding, so it starts after `runApp`.
void _superviseAndroid(RcspEarbudsAdapter adapter) {
  androidConnectedAudioChanges().listen(
    _androidCandidates.update,
    onError: (Object error) => _reconnectLog('audio link watch failed: $error'),
  );
  ReconnectSupervisor(
    osLink: _androidCandidates.worthTryingChanges,
    session: adapter.watchConnection(),
    connect: adapter.connect,
    log: _reconnectLog.call,
  ).start();
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
    log: _reconnectLog.call,
  ).start();
}

const _reconnectLog = DebugLog('reconnect');

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
