import 'package:permission_handler/permission_handler.dart';

/// Asks for "Nearby devices" (Android 12+): BLUETOOTH_CONNECT for bonded
/// listing and RFCOMM, and BLUETOOTH_SCAN because `bluetooth_rfcomm` calls
/// `cancelDiscovery()` before every connect, which throws without it. Both
/// share one system dialog. Below Android 12 the plugin reports them
/// granted: Bluetooth is an install-time permission there.
Future<bool> requestBluetoothConnect() async {
  final statuses = await [
    Permission.bluetoothConnect,
    Permission.bluetoothScan,
  ].request();
  return statuses.values.every((status) => status.isGranted);
}
