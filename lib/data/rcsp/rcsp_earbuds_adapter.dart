import 'dart:async';

import '../../domain/capabilities/capability.dart';
import '../../domain/entities/anc_mode.dart';
import '../../domain/entities/battery_status.dart';
import '../../domain/entities/bud.dart';
import '../../domain/entities/link_state.dart';
import '../../domain/ports/earbuds_port.dart';
import '../protocol/rcsp_commands.dart';
import '../protocol/rcsp_frame.dart';
import '../spp/rcsp_spp_session.dart';

/// [EarbudsPort] for JieLi RCSP earbuds over an authenticated session.
///
/// Capabilities stay empty until each feature is proven on hardware
/// (docs/protocol/capability-matrix.md); only the battery is proven today.
class RcspEarbudsAdapter implements EarbudsPort {
  RcspEarbudsAdapter(
    this._openSession, {
    this.batteryPoll = const Duration(seconds: 60),
  });

  final Future<RcspSppSession> Function() _openSession;
  final Duration batteryPoll;

  LinkState _link = LinkState.disconnected;
  BatteryStatus? _battery;
  RcspSppSession? _session;
  StreamSubscription<RcspFrame>? _deviceCommands;
  Timer? _poll;

  final _linkController = StreamController<LinkState>.broadcast();
  final _batteryController = StreamController<BatteryStatus>.broadcast();

  /// Opens the session and starts tracking the battery. Throws what the
  /// session throws (connect errors, auth failures) after reporting
  /// [LinkState.disconnected].
  @override
  Future<void> connect() async {
    if (_link != LinkState.disconnected) return;
    _setLink(LinkState.connecting);
    final RcspSppSession session;
    try {
      session = await _openSession();
    } catch (_) {
      _setLink(LinkState.disconnected);
      rethrow;
    }
    _session = session;
    _deviceCommands = session.protocol.deviceCommands.listen(_onDeviceCommand);
    unawaited(session.protocol.closed.then((_) => _onLinkEnded(session)));
    _setLink(LinkState.connected);
    await _refreshBattery();
    _poll = Timer.periodic(batteryPoll, (_) => unawaited(_refreshBattery()));
  }

  @override
  Stream<LinkState> watchConnection() =>
      _currentThenChanges(_link, _linkController.stream);

  @override
  Future<Set<Capability>> capabilities() async => const {};

  @override
  Stream<BatteryStatus> watchBattery() =>
      _currentThenChanges(_battery, _batteryController.stream);

  /// Emits [current] at subscription time (not a microtask later, so a
  /// change right after `listen` is never lost), then every change.
  static Stream<T> _currentThenChanges<T extends Object>(
    T? current,
    Stream<T> changes,
  ) => Stream.multi((controller) {
    if (current != null) controller.add(current);
    final sub = changes.listen(
      controller.add,
      onError: controller.addError,
      onDone: controller.close,
    );
    controller.onCancel = sub.cancel;
  });

  @override
  Stream<AncMode> watchAncMode() => const Stream.empty();

  @override
  Future<void> setAncMode(AncMode mode) async =>
      throw UnsupportedError('Device does not report Capability.anc');

  @override
  Future<void> playFindSound(Bud bud) async =>
      throw UnsupportedError('Device does not report Capability.findBuds');

  @override
  Future<void> stopFindSound() async {}

  Future<void> dispose() async {
    final session = _session;
    _teardown();
    if (session != null) await session.close();
    await _linkController.close();
    await _batteryController.close();
  }

  Future<void> _refreshBattery() async {
    final session = _session;
    if (session == null) return;
    try {
      final response = await session.protocol.send(RcspCommands.advGetInfo());
      _setBattery(RcspAdvInfo.parse(response.payload).battery);
    } on Object {
      // A missed poll is retried on the next tick; a dead link ends through
      // `closed`.
    }
  }

  void _onDeviceCommand(RcspFrame frame) {
    if (frame.opcode != RcspOpcode.advStatus) return;
    try {
      _setBattery(RcspDeviceStatus.parse(frame.payload).battery);
    } on FormatException {
      // Ignore a malformed status block; the next poll corrects the level.
    }
  }

  void _onLinkEnded(RcspSppSession session) {
    if (!identical(session, _session)) return;
    _teardown();
    unawaited(session.close());
  }

  void _teardown() {
    _poll?.cancel();
    _poll = null;
    unawaited(_deviceCommands?.cancel());
    _deviceCommands = null;
    _session = null;
    _setLink(LinkState.disconnected);
  }

  void _setBattery(RcspBattery battery) {
    final status = BatteryStatus(
      left: battery.left?.percent,
      right: battery.right?.percent,
      caseLevel: battery.chargingCase?.percent,
    );
    if (status == _battery) return;
    _battery = status;
    if (!_batteryController.isClosed) _batteryController.add(status);
  }

  void _setLink(LinkState state) {
    if (state == _link) return;
    _link = state;
    if (!_linkController.isClosed) _linkController.add(state);
  }
}
