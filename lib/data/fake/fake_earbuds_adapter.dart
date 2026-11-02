import 'dart:async';

import '../../domain/capabilities/capability.dart';
import '../../domain/entities/anc_mode.dart';
import '../../domain/entities/battery_status.dart';
import '../../domain/entities/earbuds_identity.dart';
import '../../domain/entities/find_target.dart';
import '../../domain/entities/link_state.dart';
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
    LinkState initialLinkState = LinkState.connected,
    this._identity,
  }) : _capabilities = Set.unmodifiable(capabilities),
       _battery = initialBattery,
       _link = initialLinkState;

  final Set<Capability> _capabilities;
  final EarbudsIdentity? _identity;
  BatteryStatus _battery;
  LinkState _link;
  AncMode _ancMode = AncMode.off;
  FindTarget? _findSoundTarget;

  final _ancController = StreamController<AncMode>.broadcast();
  final _batteryController = StreamController<BatteryStatus>.broadcast();
  final _linkController = StreamController<LinkState>.broadcast();

  int _connectCalls = 0;

  AncMode get ancMode => _ancMode;

  /// How many times [connect] was called.
  int get connectCalls => _connectCalls;

  @override
  Future<void> connect() async {
    _connectCalls++;
    if (_link != LinkState.disconnected) return;
    updateLinkState(LinkState.connecting);
    await Future<void>.delayed(Duration.zero);
    updateLinkState(LinkState.connected);
  }

  /// What is currently playing the locating sound, if anything.
  FindTarget? get findSoundTarget => _findSoundTarget;

  void updateBattery(BatteryStatus battery) {
    _battery = battery;
    _batteryController.add(battery);
  }

  void updateLinkState(LinkState connection) {
    _link = connection;
    _linkController.add(connection);
  }

  @override
  Stream<LinkState> watchConnection() async* {
    yield _link;
    yield* _linkController.stream;
  }

  @override
  Future<Set<Capability>> capabilities() async => _capabilities;

  @override
  Future<EarbudsIdentity?> identity() async => _identity;

  @override
  Stream<BatteryStatus> watchBattery() async* {
    yield _battery;
    yield* _batteryController.stream;
  }

  @override
  Stream<AncMode> watchAncMode() async* {
    yield _ancMode;
    yield* _ancController.stream;
  }

  @override
  Future<void> setAncMode(AncMode mode) async {
    if (!_capabilities.contains(Capability.anc)) {
      throw UnsupportedError('Device does not report Capability.anc');
    }
    _ancMode = mode;
    _ancController.add(mode);
  }

  @override
  Future<void> playFindSound(FindTarget target) async {
    if (!_capabilities.contains(Capability.findBuds)) {
      throw UnsupportedError('Device does not report Capability.findBuds');
    }
    _findSoundTarget = target;
  }

  @override
  Future<void> stopFindSound() async => _findSoundTarget = null;

  Future<void> dispose() async {
    await _ancController.close();
    await _batteryController.close();
    await _linkController.close();
  }
}
