import 'dart:async';

import '../../domain/capabilities/capability.dart';
import '../../domain/entities/anc_mode.dart';
import '../../domain/entities/battery_status.dart';
import '../../domain/entities/earbuds_identity.dart';
import '../../domain/entities/eq_settings.dart';
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
    this.connectError,
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
  final _eqController = StreamController<EqSettings>.broadcast();
  EqSettings _eq = EqSettings(mode: 0, gains: List.filled(10, 0));

  /// Dev profile: ISO bands, three named presets and a custom slot.
  static final eqDevProfile = EqProfile(
    frequencies: const [31, 62, 125, 250, 500, 1000, 2000, 4000, 8000, 16000],
    presets: [
      EqPresetData(mode: 0, gains: List.filled(10, 0), name: 'Flat'),
      const EqPresetData(
        mode: 1,
        gains: [6, 5, 4, 2, 0, 0, 0, 0, 0, 0],
        name: 'Bass',
      ),
      const EqPresetData(
        mode: 2,
        gains: [-2, -1, 0, 1, 3, 4, 3, 1, 0, -1],
        name: 'Vocal',
      ),
      EqPresetData(mode: 6, gains: List.filled(10, 0)),
    ],
    customMode: 6,
    minGain: -12,
    maxGain: 12,
  );
  final _batteryController = StreamController<BatteryStatus>.broadcast();
  final _linkController = StreamController<LinkState>.broadcast();

  int _connectCalls = 0;

  /// Thrown by [connect], after a brief connecting state, when set.
  Object? connectError;

  AncMode get ancMode => _ancMode;

  /// How many times [connect] was called.
  int get connectCalls => _connectCalls;

  @override
  Future<void> connect() async {
    _connectCalls++;
    if (_link != LinkState.disconnected) return;
    updateLinkState(LinkState.connecting);
    await Future<void>.delayed(Duration.zero);
    final error = connectError;
    if (error != null) {
      updateLinkState(LinkState.disconnected);
      throw error;
    }
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
  Future<EqProfile?> eqProfile() async =>
      _capabilities.contains(Capability.eq) ? eqDevProfile : null;

  /// Current settings at subscription time, then every change; subscribes
  /// at once, so a change right after `listen` is never lost.
  @override
  Stream<EqSettings> watchEq() => Stream.multi((controller) {
    controller.add(_eq);
    final sub = _eqController.stream.listen(controller.add);
    controller.onCancel = sub.cancel;
  });

  @override
  Future<void> setEq(EqSettings settings) async {
    if (!_capabilities.contains(Capability.eq)) {
      throw UnsupportedError('Device does not report Capability.eq');
    }
    _eq = settings;
    _eqController.add(settings);
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
    await _eqController.close();
    await _batteryController.close();
    await _linkController.close();
  }
}
