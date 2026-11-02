import '../capabilities/capability.dart';
import '../entities/anc_mode.dart';
import '../entities/battery_status.dart';
import '../entities/find_target.dart';
import '../entities/link_state.dart';

abstract class EarbudsPort {
  Stream<LinkState> watchConnection();

  /// Connects, or reconnects after a drop. Does nothing while connecting or
  /// connected. On failure the link state is [LinkState.disconnected] and the
  /// error is rethrown.
  Future<void> connect();

  Future<Set<Capability>> capabilities();

  Stream<BatteryStatus> watchBattery();

  /// Current mode first, then every change. Only meaningful with
  /// [Capability.anc].
  Stream<AncMode> watchAncMode();

  /// Throws [UnsupportedError] if [Capability.anc] is not reported.
  Future<void> setAncMode(AncMode mode);

  /// Plays a locating sound on [target]. Throws [UnsupportedError] if
  /// [Capability.findBuds] is not reported. A single side may stay silent
  /// on some firmware (docs/protocol/capability-matrix.md).
  Future<void> playFindSound(FindTarget target);

  Future<void> stopFindSound();
}
