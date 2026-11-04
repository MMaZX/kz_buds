/// JieLi's Bluetooth SIG company id (seen in the Carol Pro's modalias and in
/// its ADV and C2 blocks).
const jieliVendorId = 0x05d6;

const sppUuid = '00001101-0000-1000-8000-00805f9b34fb';

final _bluetoothModalias = RegExp(r'^bluetooth:v([0-9A-Fa-f]{4})p');

/// Vendor id of a BlueZ `Modalias` from the Device ID profile. Only the
/// Bluetooth SIG source counts: a `usb:` modalias carries USB-IF ids.
int? bluetoothVendorId(String modalias) {
  final match = _bluetoothModalias.firstMatch(modalias);
  return match == null ? null : int.parse(match.group(1)!, radix: 16);
}

/// A paired device that may speak RCSP: JieLi vendor and an SPP service.
/// Only a successful RCSP handshake proves it.
bool isJieliRcspCandidate({
  required String modalias,
  required Iterable<String> uuids,
}) =>
    bluetoothVendorId(modalias) == jieliVendorId &&
    uuids.any((u) => u.toLowerCase() == sppUuid);
