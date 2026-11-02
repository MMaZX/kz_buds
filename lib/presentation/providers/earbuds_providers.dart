import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/capabilities/capability.dart';
import '../../domain/entities/anc_mode.dart';
import '../../domain/entities/battery_status.dart';
import '../../domain/entities/link_state.dart';
import '../../domain/ports/earbuds_port.dart';

/// Overridden in the composition root (`main.dart`) with a concrete adapter.
final earbudsPortProvider = Provider<EarbudsPort>(
  (ref) => throw UnimplementedError('earbudsPortProvider must be overridden'),
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

final ancModeProvider = StreamProvider<AncMode>(
  (ref) => ref.watch(earbudsPortProvider).watchAncMode(),
);
