/// The OS refused the app access to Bluetooth, such as the "Nearby devices"
/// permission on Android 12+. Only the user can grant it.
class BluetoothAccessDenied implements Exception {
  const BluetoothAccessDenied();

  @override
  String toString() => 'BluetoothAccessDenied';
}
