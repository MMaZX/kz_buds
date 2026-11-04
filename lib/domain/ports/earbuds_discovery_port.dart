import '../entities/detected_earbuds.dart';

abstract class EarbudsDiscoveryPort {
  /// Paired earbuds that look supported, without connecting to them.
  Future<List<DetectedEarbuds>> pairedEarbuds();
}
