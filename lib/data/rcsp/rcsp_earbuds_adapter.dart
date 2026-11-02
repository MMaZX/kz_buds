import 'dart:async';

import '../../domain/capabilities/capability.dart';
import '../../domain/entities/anc_mode.dart';
import '../../domain/entities/battery_status.dart';
import '../../domain/entities/earbuds_identity.dart';
import '../../domain/entities/find_target.dart';
import '../../domain/entities/link_state.dart';
import '../../domain/ports/earbuds_port.dart';
import '../protocol/rcsp_commands.dart';
import '../protocol/rcsp_frame.dart';
import '../spp/rcsp_spp_session.dart';

/// [EarbudsPort] for JieLi RCSP earbuds over an authenticated session.
///
/// A capability is reported only when the device flags it (target info
/// TLV 19) and the feature is proven on hardware
/// (docs/protocol/capability-matrix.md): today, find buds.
class RcspEarbudsAdapter implements EarbudsPort {
  RcspEarbudsAdapter(
    this._openSession, {
    this.batteryPoll = const Duration(seconds: 60),
  });

  final Future<RcspSppSession> Function() _openSession;
  final Duration batteryPoll;

  LinkState _link = LinkState.disconnected;
  BatteryStatus? _battery;
  RcspSupport? _support;
  EarbudsIdentity? _identity;
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
    // Before reporting connected, so a capability read on that event sees it.
    final target = await _readTargetInfo(session);
    _support = target?.support;
    final name = target?.name ?? session.osName;
    if (name != null) {
      _identity = EarbudsIdentity(
        name: name,
        vendorId: target?.vendorId,
        productId: target?.productId,
      );
    }
    _setLink(LinkState.connected);
    await _refreshBattery();
    _poll = Timer.periodic(batteryPoll, (_) => unawaited(_refreshBattery()));
  }

  @override
  Stream<LinkState> watchConnection() =>
      _currentThenChanges(_link, _linkController.stream);

  @override
  Future<Set<Capability>> capabilities() async => {
    if (_session != null && (_support?.searchDevice ?? false))
      Capability.findBuds,
  };

  /// Kept after a drop, so the app still shows which earbuds these are.
  @override
  Future<EarbudsIdentity?> identity() async => _identity;

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
  Future<void> playFindSound(FindTarget target) async {
    final session = _session;
    if (session == null ||
        !(await capabilities()).contains(Capability.findBuds)) {
      throw UnsupportedError('Device does not report Capability.findBuds');
    }
    await session.protocol.send(
      RcspCommands.searchDevice(
        start: true,
        timeoutSeconds: findTimeoutSeconds,
        // way 0 both, 1 left, 2 right. Firmware limit (L36): a single side
        // only rings on the earbud that holds the link; asked for the other
        // one, the firmware mutes the media and plays nothing.
        side: switch (target) {
          FindTarget.both => 0,
          FindTarget.left => 1,
          FindTarget.right => 2,
        },
        // RING_PLAYER_DEVICE: the earbud plays the sound. Player 0 (what the
        // KZ app sends) leaves the earbuds silent (L30).
        player: 1,
      ),
    );
  }

  @override
  Future<void> stopFindSound() async {
    await _session?.protocol.send(RcspCommands.searchDevice(start: false));
  }

  /// The earbuds stop ringing on their own after this, as a safety net.
  static const findTimeoutSeconds = 60;

  Future<void> dispose() async {
    final session = _session;
    _teardown();
    if (session != null) await session.close();
    await _linkController.close();
    await _batteryController.close();
  }

  Future<RcspTargetInfo?> _readTargetInfo(RcspSppSession session) async {
    try {
      final response = await session.protocol.send(
        RcspCommands.getTargetInfo(),
      );
      return RcspTargetInfo.parse(response.payload);
    } on Object {
      // Unknown support and identity: report nothing rather than guess.
      return null;
    }
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
    _support = null;
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
