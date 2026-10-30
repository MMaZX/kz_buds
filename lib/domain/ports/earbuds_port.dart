import '../capabilities/capability.dart';
import '../entities/anc_mode.dart';
import '../entities/battery_status.dart';
import '../entities/link_state.dart';

abstract class EarbudsPort {
  Stream<LinkState> watchConnection();

  Future<Set<Capability>> capabilities();

  Stream<BatteryStatus> watchBattery();

  /// Current mode first, then every change. Only meaningful with
  /// [Capability.anc].
  Stream<AncMode> watchAncMode();

  /// Throws [UnsupportedError] if [Capability.anc] is not reported.
  Future<void> setAncMode(AncMode mode);
}
