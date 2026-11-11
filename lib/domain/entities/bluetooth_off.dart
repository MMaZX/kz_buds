/// The Bluetooth radio is off, so nothing can be listed or connected until
/// the user turns it on.
class BluetoothOff implements Exception {
  const BluetoothOff();

  @override
  String toString() => 'BluetoothOff';
}
