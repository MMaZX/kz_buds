import 'package:bluetooth_rfcomm/bluetooth_rfcomm.dart';

import '../../../domain/entities/bluetooth_access_denied.dart';
import '../../../domain/entities/detected_earbuds.dart';
import '../../../domain/ports/earbuds_discovery_port.dart';

/// Android: reads bonded devices through `bluetooth_rfcomm` and keeps the
/// ones the OS has connected.
class RfcommEarbudsDiscovery implements EarbudsDiscoveryPort {
  RfcommEarbudsDiscovery(this._bluetooth, {this.connectedAddresses, this.log});

  final BluetoothRfcomm _bluetooth;

  /// Addresses the OS has connected right now, or null when it cannot tell.
  final Future<Set<String>?> Function()? connectedAddresses;
  final void Function(String message)? log;

  @override
  Future<List<DetectedEarbuds>> pairedEarbuds() async {
    final List<BluetoothDevice> bonded;
    try {
      bonded = await _bluetooth.bondedDevices();
    } on BluetoothPermissionException {
      throw const BluetoothAccessDenied();
    }
    for (final device in bonded) {
      final cod = device.deviceClass;
      log?.call(
        'bonded: ${device.name ?? '?'} class='
        '${cod == null ? '?' : '0x${cod.toRadixString(16)}'}',
      );
    }
    final connected = await connectedAddresses?.call();
    log?.call(
      connected == null
          ? 'connected devices unknown: trying every bonded device'
          : 'connected: ${connected.isEmpty ? 'none' : connected.join(', ')}',
    );
    return rfcommEarbudsCandidates(bonded, connected: connected);
  }
}

/// Major device class "Audio/Video" in a Class of Device (bits 8-12).
const _audioMajorClass = 0x04;

/// Bonded devices with an address: audio first, then unknown class, then any
/// other class. Nothing is dropped by class: some earbuds report one that is
/// not Audio/Video. Unlike BlueZ, Android exposes no modalias here, so the
/// JieLi vendor cannot be checked before connecting.
///
/// With [connected] (addresses the OS has connected), only those are kept:
/// paging a bonded device that is off costs seconds per attempt. Null means
/// the OS could not tell, and every bonded device stays a candidate.
List<DetectedEarbuds> rfcommEarbudsCandidates(
  Iterable<BluetoothDevice> bonded, {
  Set<String>? connected,
}) {
  final wanted = connected?.map((address) => address.toUpperCase()).toSet();
  final audio = <DetectedEarbuds>[];
  final unknown = <DetectedEarbuds>[];
  final other = <DetectedEarbuds>[];
  for (final device in bonded) {
    if (!device.hasAddress) continue;
    if (wanted != null && !wanted.contains(device.address.toUpperCase())) {
      continue;
    }
    final earbuds = DetectedEarbuds(
      id: device.address,
      name: device.name ?? '',
    );
    final cod = device.deviceClass;
    if (cod == null) {
      unknown.add(earbuds);
    } else if ((cod >> 8) & 0x1f == _audioMajorClass) {
      audio.add(earbuds);
    } else {
      other.add(earbuds);
    }
  }
  return [...audio, ...unknown, ...other];
}
