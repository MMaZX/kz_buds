import 'package:bluez/bluez.dart';

import '../../domain/entities/detected_earbuds.dart';
import '../../domain/ports/earbuds_discovery_port.dart';
import 'jieli_detection.dart';

/// Linux: reads paired devices from BlueZ over D-Bus. BlueZ exposes the
/// Device ID modalias, which the other platforms' SPP APIs do not.
class BluezEarbudsDiscovery implements EarbudsDiscoveryPort {
  @override
  Future<List<DetectedEarbuds>> pairedEarbuds() async {
    final client = BlueZClient();
    try {
      await client.connect();
      return [
        for (final device in client.devices)
          if (device.paired &&
              isJieliRcspCandidate(
                modalias: device.modalias,
                uuids: device.uuids.map((u) => u.toString()),
              ))
            DetectedEarbuds(
              id: device.address,
              name: device.alias.isNotEmpty ? device.alias : device.name,
            ),
      ];
    } finally {
      await client.close();
    }
  }
}
