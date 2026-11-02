import 'dart:async';
import 'dart:typed_data';

import 'rcsp_auth.dart';
import 'rcsp_commands.dart';
import 'rcsp_frame.dart';

/// Byte pipe to the earbuds (SPP socket or BLE AE01/AE02); one per link.
abstract interface class RcspTransport {
  /// Single-subscription stream of raw chunks as they arrive.
  Stream<List<int>> get incoming;

  Future<void> write(List<int> bytes);
}

class RcspAuthException implements Exception {
  const RcspAuthException(this.message);

  final String message;

  @override
  String toString() => 'RcspAuthException: $message';
}

class RcspCommandException implements Exception {
  const RcspCommandException(this.opcode, this.status);

  final int opcode;
  final int status;

  @override
  String toString() =>
      'RcspCommandException: opcode 0x${opcode.toRadixString(16)} '
      'failed with status $status';
}

/// Runs the auth handshake, then request/response over RCSP frames.
///
/// Auth messages are raw (not framed), so incoming bytes go to the auth
/// buffer while [authenticate] runs and to the frame reader otherwise.
class RcspProtocol {
  RcspProtocol(
    this._transport, {
    RcspAuth? auth,
    this.timeout = const Duration(seconds: 3),
    this.retries = defaultRetries,
  }) : _auth = auth ?? RcspAuth() {
    _subscription = _transport.incoming.listen(_onBytes);
  }

  static const defaultRetries = 2;

  final RcspTransport _transport;
  final RcspAuth _auth;
  final Duration timeout;
  final int retries;

  late final StreamSubscription<List<int>> _subscription;
  final _reader = RcspFrameReader();
  final _deviceCommands = StreamController<RcspFrame>.broadcast();
  final _pending = <int, _Pending>{};

  bool _authenticating = false;
  final _authBuffer = <int>[];
  Completer<void>? _authData;

  var _nextSn = 0;
  bool _closed = false;

  /// Commands the earbuds send on their own (0x09, 0xC2, 0xC4, ...).
  Stream<RcspFrame> get deviceCommands => _deviceCommands.stream;

  /// App challenge first, then the earbuds' challenge, as the KZ apps do.
  Future<void> authenticate() async {
    _checkOpen();
    _authenticating = true;
    _authBuffer.clear();
    try {
      final challenge = _auth.randomChallenge();
      await _transport.write(challenge);
      final reply = await _readAuthMessage(17);
      if (!_auth.verify(challenge, reply)) {
        throw const RcspAuthException('Earbuds answered our challenge wrong');
      }
      await _transport.write(RcspAuth.passMessage);

      final theirs = await _readAuthMessage(17);
      if (theirs[0] != RcspAuth.challengeFlag) {
        throw const RcspAuthException('Earbuds sent no challenge');
      }
      await _transport.write(_auth.answer(theirs));

      final verdict = await _readAuthMessage(RcspAuth.passMessage.length);
      if (!RcspAuth.isPass(verdict)) {
        throw const RcspAuthException('Earbuds rejected our answer');
      }
    } finally {
      _authenticating = false;
      final leftover = List.of(_authBuffer);
      _authBuffer.clear();
      if (leftover.isNotEmpty) _onFrameBytes(leftover);
    }
  }

  /// Sends [request] and returns its response, retrying on silence.
  ///
  /// Throws [TimeoutException] after `retries + 1` attempts and
  /// [RcspCommandException] when the response status is not 0.
  Future<RcspFrame> send(RcspRequest request) async {
    _checkOpen();
    final sn = _takeSn();
    final bytes = request.toFrame(sn: sn).encode();
    try {
      for (var attempt = 0; ; attempt++) {
        final pending = _Pending(request.opcode);
        _pending[sn] = pending;
        await _transport.write(bytes);
        try {
          final response = await pending.completer.future.timeout(timeout);
          if (response.status != 0) {
            throw RcspCommandException(request.opcode, response.status!);
          }
          return response;
        } on TimeoutException {
          if (attempt >= retries) rethrow;
        }
      }
    } finally {
      _pending.remove(sn);
    }
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _subscription.cancel();
    for (final p in _pending.values) {
      p.completer.completeError(StateError('RCSP protocol closed'));
    }
    _pending.clear();
    await _deviceCommands.close();
  }

  void _onBytes(List<int> chunk) {
    if (_authenticating) {
      _authBuffer.addAll(chunk);
      _authData?.complete();
      _authData = null;
    } else {
      _onFrameBytes(chunk);
    }
  }

  void _onFrameBytes(List<int> chunk) {
    for (final frame in _reader.add(chunk)) {
      if (frame.isCommand) {
        _deviceCommands.add(frame);
        continue;
      }
      final pending = _pending[frame.sn];
      if (pending != null &&
          pending.opcode == frame.opcode &&
          !pending.completer.isCompleted) {
        pending.completer.complete(frame);
      }
    }
  }

  Future<Uint8List> _readAuthMessage(int length) async {
    final deadline = DateTime.now().add(timeout);
    while (_authBuffer.length < length) {
      final left = deadline.difference(DateTime.now());
      if (left <= Duration.zero || _closed) {
        throw TimeoutException('No auth message from the earbuds', timeout);
      }
      final waiter = _authData = Completer<void>();
      await waiter.future.timeout(left, onTimeout: () {});
    }
    final message = Uint8List.fromList(_authBuffer.sublist(0, length));
    _authBuffer.removeRange(0, length);
    return message;
  }

  int _takeSn() {
    final sn = _nextSn;
    _nextSn = (_nextSn + 1) & 0xff;
    return sn;
  }

  void _checkOpen() {
    if (_closed) throw StateError('RCSP protocol closed');
  }
}

class _Pending {
  _Pending(this.opcode) {
    // close() may fail a request before send() listens again.
    completer.future.ignore();
  }

  final int opcode;
  final completer = Completer<RcspFrame>();
}
