import '../../../domain/entities/bluetooth_access_denied.dart';
import '../../../domain/entities/detected_earbuds.dart';
import '../rcsp_spp_session.dart';

/// Opens an RCSP session on Android to the first candidate that completes the
/// handshake.
///
/// Android reports no Device ID or service list for bonded devices, so the
/// candidates are only the devices it has connected and the handshake is the
/// proof. The OS keeps the audio profiles up on its own; we only open the SPP
/// channel.
///
/// [onProven] gets the candidate that completed the handshake and [onFailed]
/// each one that did not, so the caller can stop retrying a hopeless device.
Future<RcspSppSession> openAndroidRcspSession({
  required Future<bool> Function() requestAccess,
  required Future<List<DetectedEarbuds>> Function() discover,
  required Future<SppLink> Function(String id) openLink,
  void Function(String id)? onProven,
  void Function(String id)? onFailed,
  void Function(String message)? log,
  int emptyRetries = 3,
  Duration emptyRetryDelay = const Duration(milliseconds: 500),
}) async {
  if (!await requestAccess()) throw const BluetoothAccessDenied();
  var found = await discover();
  // Right after launch the OS Bluetooth service may not be bound to the
  // process yet, and the bonded list comes back empty.
  for (var i = 0; found.isEmpty && i < emptyRetries; i++) {
    await Future<void>.delayed(emptyRetryDelay);
    found = await discover();
  }
  if (found.isEmpty) throw StateError('No connected earbuds found');
  log?.call('candidates: ${found.map((e) => e.name).join(', ')}');
  late Object lastError;
  late StackTrace lastStack;
  for (final earbuds in found) {
    log?.call('RFCOMM connect and RCSP auth: ${earbuds.name}');
    try {
      final session = await RcspSppSession.open(
        () => openLink(earbuds.id),
        osName: earbuds.name.isEmpty ? null : earbuds.name,
      );
      onProven?.call(earbuds.id);
      return session;
    } on BluetoothAccessDenied {
      rethrow;
    } catch (error, stack) {
      onFailed?.call(earbuds.id);
      log?.call('no RCSP on ${earbuds.name}: $error');
      lastError = error;
      lastStack = stack;
    }
  }
  Error.throwWithStackTrace(lastError, lastStack);
}
