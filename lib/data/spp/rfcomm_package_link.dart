import 'dart:typed_data';

import 'package:bluetooth_rfcomm/bluetooth_rfcomm.dart';

import '../../domain/entities/bluetooth_access_denied.dart';
import 'rcsp_spp_session.dart';

/// [SppLink] over `bluetooth_rfcomm`, for Android and Windows. Not for Linux:
/// there it adopts the BlueZ fd with `ResourceHandle.toSocket()`, which the
/// Dart VM rejects for AF_BLUETOOTH (odd/tasks/carol-pro-bluetooth.md L13).
class RfcommPackageLink implements SppLink {
  RfcommPackageLink._(this._connection);

  final BluetoothConnection _connection;

  static Future<RfcommPackageLink> connect(
    BluetoothRfcomm bluetooth,
    String address, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    try {
      return RfcommPackageLink._(
        await bluetooth.connect(
          BluetoothDevice(id: DeviceId.address(address)),
          serviceUuid: Uuid.spp,
          timeout: timeout,
        ),
      );
    } on BluetoothPermissionException {
      throw const BluetoothAccessDenied();
    }
  }

  @override
  Stream<List<int>> get incoming => _connection.input;

  @override
  Future<void> write(List<int> bytes) =>
      _connection.write(Uint8List.fromList(bytes));

  @override
  Future<void> close() => _connection.close();
}
