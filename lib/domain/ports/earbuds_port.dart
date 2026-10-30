import '../capabilities/capability.dart';
import '../entities/anc_mode.dart';
import '../entities/battery_status.dart';
import '../entities/connection_state.dart';

abstract class EarbudsPort {
  Stream<ConnectionState> watchConnection();

  Future<Set<Capability>> capabilities();

  Stream<BatteryStatus> watchBattery();

  /// Throws [UnsupportedError] if [Capability.anc] is not reported.
  Future<void> setAncMode(AncMode mode);
}
