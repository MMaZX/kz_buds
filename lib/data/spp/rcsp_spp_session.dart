import '../protocol/rcsp_protocol.dart';

/// An open SPP (RFCOMM) byte link to the earbuds.
abstract interface class SppLink implements RcspTransport {
  Future<void> close();
}

/// An authenticated RCSP session over any [SppLink].
class RcspSppSession {
  RcspSppSession._(this._link, this.protocol);

  final SppLink _link;
  final RcspProtocol protocol;

  /// Opens a link with [connect] and runs the RCSP handshake on it. The link
  /// is closed again if the handshake fails.
  static Future<RcspSppSession> open(
    Future<SppLink> Function() connect, {
    Duration timeout = const Duration(seconds: 3),
  }) async {
    final link = await connect();
    final protocol = RcspProtocol(link, timeout: timeout);
    try {
      await protocol.authenticate();
    } catch (_) {
      await protocol.close();
      await link.close();
      rethrow;
    }
    return RcspSppSession._(link, protocol);
  }

  Future<void> close() async {
    await protocol.close();
    await _link.close();
  }
}
