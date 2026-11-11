import 'dart:async';

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

/// Whether any BlueZ adapter is powered. False with no adapter at all.
Future<bool> bluezPoweredOn() async {
  final client = BlueZClient();
  try {
    await client.connect();
    return client.adapters.any((adapter) => adapter.powered);
  } finally {
    await client.close();
  }
}

/// Asks BlueZ to connect the device (`Device1.Connect`), which brings up its
/// auto-connect profiles such as A2DP and HFP. Runs even when the device is
/// already connected: a link opened by our RFCOMM socket alone has no audio.
Future<void> bluezConnectProfiles(String address) async {
  final client = BlueZClient();
  try {
    await client.connect();
    final device = client.devices.firstWhere(
      (d) => d.address.toUpperCase() == address.toUpperCase(),
      orElse: () => throw StateError('BlueZ does not know the earbuds'),
    );
    try {
      await device.connect();
    } on BlueZAlreadyConnectedException {
      // Every profile is already up.
    } on BlueZInProgressException {
      // The OS is connecting them right now.
    }
  } finally {
    await client.close();
  }
}

/// The device's `Connected` property: the current value on listen, then each
/// change (BlueZ PropertiesChanged). Emits false once if BlueZ does not know
/// the device. Closes its D-Bus client when the listener cancels.
Stream<bool> bluezConnectedChanges(String address) =>
    Stream.multi((controller) {
      final client = BlueZClient();
      StreamSubscription<List<String>>? changes;
      controller.onCancel = () async {
        await changes?.cancel();
        await client.close();
      };
      unawaited(() async {
        try {
          await client.connect();
          final device = client.devices
              .where((d) => d.address.toUpperCase() == address.toUpperCase())
              .firstOrNull;
          if (device == null) {
            controller.add(false);
            return;
          }
          controller.add(device.connected);
          changes = device.propertiesChanged.listen((names) {
            if (names.contains('Connected')) controller.add(device.connected);
          });
        } catch (error, stack) {
          controller.addError(error, stack);
        }
      }());
    });
