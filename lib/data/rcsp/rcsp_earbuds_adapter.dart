import 'dart:async';

import '../../core/debug_log.dart';
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
/// (docs/protocol/capability-matrix.md): find buds, and ANC when the device
/// also has a noise mode table (sys info attr 14).
class RcspEarbudsAdapter implements EarbudsPort {
  RcspEarbudsAdapter(
    this._openSession, {
    this.batteryPoll = const Duration(seconds: 60),
  });

  static const _ancLog = DebugLog('anc');
  static const _deviceLog = DebugLog('device');

  final Future<RcspSppSession> Function() _openSession;
  final Duration batteryPoll;

  LinkState _link = LinkState.disconnected;
  BatteryStatus? _battery;
  RcspSupport? _support;
  EarbudsIdentity? _identity;
  List<RcspNoise> _noiseTable = const [];
  AncMode? _ancMode;
  RcspSppSession? _session;
  StreamSubscription<RcspFrame>? _deviceCommands;
  Timer? _poll;

  final _linkController = StreamController<LinkState>.broadcast();
  final _batteryController = StreamController<BatteryStatus>.broadcast();
  final _ancController = StreamController<AncMode>.broadcast();

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
    if (_support?.anc ?? false) await _readNoise(session);
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
    if (_session != null && (_support?.anc ?? false) && _noiseTable.isNotEmpty)
      Capability.anc,
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

  /// Starts from the live attribute read on connect, then follows the
  /// modes this app sets. The firmware may not report a mode changed with
  /// the earbud's own touch control (capability-matrix.md).
  @override
  Stream<AncMode> watchAncMode() =>
      _currentThenChanges(_ancMode, _ancController.stream);

  /// Sends the device's own table entry for [mode], as the KZ app does.
  @override
  Future<void> setAncMode(AncMode mode) async {
    final session = _session;
    if (session == null || !(await capabilities()).contains(Capability.anc)) {
      throw UnsupportedError('Device does not report Capability.anc');
    }
    final code = _noiseCode(mode);
    final entry = _noiseTable.where((e) => e.mode == code).firstOrNull;
    if (entry == null) {
      _ancLog('set ${mode.name}: mode $code not in the device table');
      throw UnsupportedError('Device has no noise mode $code');
    }
    final request = RcspCommands.setNoise(entry);
    _ancLog('set ${mode.name}: payload ${_hex(request.payload)}');
    try {
      final response = await session.protocol.send(request);
      _ancLog('set ${mode.name}: answered status ${response.status}');
    } on Object catch (error) {
      _ancLog('set ${mode.name}: failed: $error');
      rethrow;
    }
    _setAncMode(mode);
  }

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
    await _ancController.close();
  }

  Future<void> _readNoise(RcspSppSession session) async {
    try {
      final response = await session.protocol.send(
        RcspCommands.getSysInfo(
          function: RcspSysFunction.public,
          mask: RcspSysAttr.maskOf([
            RcspSysAttr.noiseLive,
            RcspSysAttr.noiseTable,
          ]),
        ),
      );
      final info = RcspSysInfo.parse(response.payload);
      _noiseTable = info.noiseTable ?? const [];
      final live = info.noise;
      _ancLog('noise live $live, table $_noiseTable');
      final mode = live == null ? null : _ancOf(live.mode);
      if (mode != null) _setAncMode(mode);
    } on Object catch (error) {
      // No table, no ANC: report nothing rather than guess.
      _noiseTable = const [];
      _ancLog('noise read failed: $error');
    }
  }

  static int _noiseCode(AncMode mode) => switch (mode) {
    AncMode.off => RcspNoise.off,
    AncMode.noiseCancelling => RcspNoise.anc,
    AncMode.ambient => RcspNoise.transparency,
  };

  static AncMode? _ancOf(int code) => switch (code) {
    RcspNoise.off => AncMode.off,
    RcspNoise.anc => AncMode.noiseCancelling,
    RcspNoise.transparency => AncMode.ambient,
    _ => null,
  };

  static String _hex(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');

  void _setAncMode(AncMode mode) {
    if (mode == _ancMode) return;
    _ancMode = mode;
    if (!_ancController.isClosed) _ancController.add(mode);
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
    // Diagnostic: shows whether the firmware reports changes made on the
    // earbuds themselves (for example the noise mode set by touch).
    _deviceLog(
      'push op ${frame.opcode.toRadixString(16).padLeft(2, '0')}: '
      '${_hex(frame.payload)}',
    );
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
    _noiseTable = const [];
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
