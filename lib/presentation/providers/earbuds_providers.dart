import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/capabilities/capability.dart';
import '../../domain/catalog/earbuds_catalog.dart';
import '../../domain/catalog/earbuds_model.dart';
import '../../domain/entities/anc_mode.dart';
import '../../domain/entities/battery_status.dart';
import '../../domain/entities/bluetooth_access_denied.dart';
import '../../domain/entities/bluetooth_off.dart';
import '../../domain/entities/earbuds_identity.dart';
import '../../domain/entities/link_state.dart';
import '../../domain/ports/earbuds_port.dart';

/// Overridden in the composition root (`main.dart`) with a concrete adapter.
final earbudsPortProvider = Provider<EarbudsPort>(
  (ref) => throw UnimplementedError('earbudsPortProvider must be overridden'),
);

/// Why the last connect attempt could not even start, when the user can fix
/// it; null otherwise.
enum ConnectIssue { accessDenied, bluetoothOff }

/// Reconnects the earbuds and keeps the [ConnectIssue] of the last attempt.
/// Other failures are rethrown. Any connection, from here or from the OS
/// supervisor, clears the issue.
class ReconnectNotifier extends Notifier<ConnectIssue?> {
  @override
  ConnectIssue? build() {
    ref.listen(connectionProvider, (_, next) {
      if (next.value == LinkState.connected) state = null;
    });
    return null;
  }

  Future<void> reconnect() async {
    state = null;
    try {
      await ref.read(earbudsPortProvider).connect();
    } on BluetoothAccessDenied {
      state = ConnectIssue.accessDenied;
    } on BluetoothOff {
      state = ConnectIssue.bluetoothOff;
    }
  }
}

final reconnectProvider = NotifierProvider<ReconnectNotifier, ConnectIssue?>(
  ReconnectNotifier.new,
);

final connectionProvider = StreamProvider<LinkState>(
  (ref) => ref.watch(earbudsPortProvider).watchConnection(),
);

final batteryProvider = StreamProvider<BatteryStatus>(
  (ref) => ref.watch(earbudsPortProvider).watchBattery(),
);

/// Read again on every link change: a real device only knows its
/// capabilities once connected.
final capabilitiesProvider = FutureProvider<Set<Capability>>((ref) {
  ref.watch(connectionProvider);
  return ref.watch(earbudsPortProvider).capabilities();
});

/// Read again on every link change, like [capabilitiesProvider].
final identityProvider = FutureProvider<EarbudsIdentity?>((ref) {
  ref.watch(connectionProvider);
  return ref.watch(earbudsPortProvider).identity();
});

/// The known model behind the identity, for appearance only.
final earbudsModelProvider = Provider<EarbudsModel?>((ref) {
  final identity = ref.watch(identityProvider).value;
  return identity == null ? null : EarbudsCatalog.match(identity);
});

final ancModeProvider = StreamProvider<AncMode>(
  (ref) => ref.watch(earbudsPortProvider).watchAncMode(),
);
