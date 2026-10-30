import 'dart:async';

import '../../domain/capabilities/capability.dart';
import '../../domain/entities/anc_mode.dart';
import '../../domain/entities/battery_status.dart';
import '../../domain/entities/connection_state.dart';
import '../../domain/ports/earbuds_port.dart';

/// Simulated earbuds used for UI work and tests.
class FakeEarbudsAdapter implements EarbudsPort {
  FakeEarbudsAdapter({
    Set<Capability> capabilities = const {Capability.anc},
    BatteryStatus initialBattery = const BatteryStatus(
      left: 80,
      right: 78,
      caseLevel: 60,
    ),
    ConnectionState initialConnection = ConnectionState.connected,
  }) : _capabilities = Set.unmodifiable(capabilities),
       _battery = initialBattery,
       _connection = initialConnection;

  final Set<Capability> _capabilities;
  BatteryStatus _battery;
  ConnectionState _connection;
  AncMode _ancMode = AncMode.off;

  final _batteryController = StreamController<BatteryStatus>.broadcast();
  final _connectionController = StreamController<ConnectionState>.broadcast();

  AncMode get ancMode => _ancMode;

  void updateBattery(BatteryStatus battery) {
    _battery = battery;
    _batteryController.add(battery);
  }

  void updateConnection(ConnectionState connection) {
    _connection = connection;
    _connectionController.add(connection);
  }

  @override
  Stream<ConnectionState> watchConnection() async* {
    yield _connection;
    yield* _connectionController.stream;
  }

  @override
  Future<Set<Capability>> capabilities() async => _capabilities;

  @override
  Stream<BatteryStatus> watchBattery() async* {
    yield _battery;
    yield* _batteryController.stream;
  }

  @override
  Future<void> setAncMode(AncMode mode) async {
    if (!_capabilities.contains(Capability.anc)) {
      throw UnsupportedError('Device does not report Capability.anc');
    }
    _ancMode = mode;
  }

  Future<void> dispose() async {
    await _batteryController.close();
    await _connectionController.close();
  }
}
