import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/capabilities/capability.dart';
import '../../domain/entities/battery_status.dart';
import '../../domain/entities/connection_state.dart';
import '../../domain/ports/earbuds_port.dart';

/// Overridden in the composition root (`main.dart`) with a concrete adapter.
final earbudsPortProvider = Provider<EarbudsPort>(
  (ref) => throw UnimplementedError('earbudsPortProvider must be overridden'),
);

final connectionProvider = StreamProvider<ConnectionState>(
  (ref) => ref.watch(earbudsPortProvider).watchConnection(),
);

final batteryProvider = StreamProvider<BatteryStatus>(
  (ref) => ref.watch(earbudsPortProvider).watchBattery(),
);

final capabilitiesProvider = FutureProvider<Set<Capability>>(
  (ref) => ref.watch(earbudsPortProvider).capabilities(),
);
