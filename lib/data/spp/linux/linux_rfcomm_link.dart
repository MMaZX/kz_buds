import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import '../../protocol/sdp.dart';
import '../rcsp_spp_session.dart';

/// Little-endian `bdaddr_t` bytes for an `AA:BB:CC:DD:EE:FF` address.
List<int> bdaddrBytes(String address) {
  final parts = address.split(':');
  if (parts.length != 6 ||
      parts.any((p) => !RegExp(r'^[0-9A-Fa-f]{2}$').hasMatch(p))) {
    throw ArgumentError.value(address, 'address', 'not a Bluetooth address');
  }
  return [for (final p in parts.reversed) int.parse(p, radix: 16)];
}

class LinuxBluetoothException implements Exception {
  const LinuxBluetoothException(this.operation, this.errno);

  final String operation;
  final int errno;

  @override
  String toString() =>
      'LinuxBluetoothException: $operation failed (errno $errno)';
}

/// [SppLink] on Linux through raw AF_BLUETOOTH sockets (libc via FFI).
///
/// `dart:io` cannot adopt Bluetooth sockets, and the BlueZ Profile1 route
/// hands one over, so this opens its own: an SDP query over L2CAP finds the
/// SPP channel, then an RFCOMM socket connects to it. Blocking calls run on
/// helper isolates.
class LinuxRfcommLink implements SppLink {
  LinuxRfcommLink._(this._fd, this._port) {
    _port.listen((message) {
      if (message is TransferableTypedData) {
        _incoming.add(message.materialize().asUint8List());
      } else {
        if (message is int && !_closing) {
          _incoming.addError(LinuxBluetoothException('read', message));
        }
        _readerDone.complete();
        _port.close();
        unawaited(_incoming.close());
      }
    });
  }

  final int _fd;
  final ReceivePort _port;
  final _incoming = StreamController<List<int>>();
  final _readerDone = Completer<void>();
  bool _closing = false;

  static Future<LinuxRfcommLink> connect(
    String address, {
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final bdaddr = bdaddrBytes(address);
    final seconds = timeout.inSeconds;
    final fd = await Isolate.run(() => _openSpp(bdaddr, seconds));
    final port = ReceivePort();
    await Isolate.spawn(_readLoop, (fd, port.sendPort));
    return LinuxRfcommLink._(fd, port);
  }

  @override
  Stream<List<int>> get incoming => _incoming.stream;

  @override
  Future<void> write(List<int> bytes) async {
    if (_closing) throw StateError('RFCOMM link closed');
    _writeAll(_fd, bytes);
  }

  @override
  Future<void> close() async {
    if (_closing) return;
    _closing = true;
    _libc.shutdown(_fd, _shutRdWr);
    await _readerDone.future.timeout(
      const Duration(seconds: 2),
      onTimeout: () {},
    );
    _libc.close(_fd);
  }
}

const _afBluetooth = 31;
const _sockStream = 1;
const _sockSeqpacket = 5;
const _btprotoL2cap = 0;
const _btprotoRfcomm = 3;
const _solSocket = 1;
const _soRcvtimeo = 20;
const _soSndtimeo = 21;
const _shutRdWr = 2;
const _eintr = 4;
const _sdpPsm = 1;

/// SDP lookup of the SPP channel, then an RFCOMM connect. Runs on an isolate.
int _openSpp(List<int> bdaddr, int timeoutSeconds) {
  final channel = _sppChannel(bdaddr, timeoutSeconds);
  final fd = _socket(_sockStream, _btprotoRfcomm);
  try {
    // struct sockaddr_rc { sa_family_t; bdaddr_t; uint8_t channel; }
    _connect(fd, [_afBluetooth, 0, ...bdaddr, channel, 0], timeoutSeconds);
    return fd;
  } catch (_) {
    _libc.close(fd);
    rethrow;
  }
}

int _sppChannel(List<int> bdaddr, int timeoutSeconds) {
  final fd = _socket(_sockSeqpacket, _btprotoL2cap);
  try {
    _setTimeouts(fd, timeoutSeconds);
    // struct sockaddr_l2 { family; le16 psm; bdaddr_t; le16 cid; u8 type; }
    _connect(fd, [
      _afBluetooth,
      0,
      _sdpPsm,
      0,
      ...bdaddr,
      0,
      0,
      0,
      0,
    ], timeoutSeconds);
    final lists = <int>[];
    var continuation = <int>[];
    for (var tid = 1; ; tid++) {
      _writeAll(
        fd,
        Sdp.serviceSearchAttributeRequest(
          transactionId: tid,
          uuid16: Sdp.serialPortUuid,
          attributeId: Sdp.protocolDescriptorListAttr,
          continuation: continuation,
        ),
      );
      final response = Sdp.parseServiceSearchAttributeResponse(
        _readOnce(fd, 1024),
        transactionId: tid,
      );
      lists.addAll(response.attributeBytes);
      continuation = response.continuation;
      if (continuation.isEmpty) break;
    }
    final channel = Sdp.rfcommChannel(lists);
    if (channel == null) {
      throw const LinuxBluetoothException('SDP: no SPP channel', 0);
    }
    return channel;
  } finally {
    _libc.close(fd);
  }
}

void _readLoop((int, SendPort) args) {
  final (fd, port) = args;
  final buffer = calloc<Uint8>(1024);
  try {
    while (true) {
      final n = _libc.read(fd, buffer, 1024);
      if (n > 0) {
        port.send(
          TransferableTypedData.fromList([
            Uint8List.fromList(buffer.asTypedList(n)),
          ]),
        );
      } else if (n == 0) {
        port.send(null);
        return;
      } else if (_errno() != _eintr) {
        port.send(_errno());
        return;
      }
    }
  } finally {
    calloc.free(buffer);
  }
}

int _socket(int type, int protocol) {
  final fd = _libc.socket(_afBluetooth, type, protocol);
  if (fd < 0) throw LinuxBluetoothException('socket', _errno());
  return fd;
}

const _einprogress = 115;
const _etimedout = 110;
const _econnreset = 104;
const _soError = 4;
const _pollOut = 0x004;

/// Drives a blocking `connect()` to its outcome. Both callbacks return 0 or
/// an errno.
///
/// In a Flutter debug process the VM profiler's signals interrupt connect()
/// with EINTR while the kernel keeps connecting. Unlike TCP, a Bluetooth
/// socket rejects a second connect() with EBADFD, so the outcome is awaited
/// with [awaitOutcome] instead of calling connect() again.
void finishConnect({
  required int Function() connectOnce,
  required int Function() awaitOutcome,
}) {
  var result = connectOnce();
  if (result == _eintr || result == _einprogress) result = awaitOutcome();
  if (result != 0) throw LinuxBluetoothException('connect', result);
}

void _connect(int fd, List<int> sockaddr, int timeoutSeconds) {
  final addr = calloc<Uint8>(sockaddr.length);
  try {
    addr.asTypedList(sockaddr.length).setAll(0, sockaddr);
    finishConnect(
      connectOnce: () =>
          _libc.connect(fd, addr, sockaddr.length) < 0 ? _errno() : 0,
      awaitOutcome: () => _awaitConnected(fd, timeoutSeconds * 1000),
    );
  } finally {
    calloc.free(addr);
  }
}

/// Waits until [fd] is writable (connected) or failed; 0 or an errno.
int _awaitConnected(int fd, int timeoutMs) {
  // struct pollfd { int fd; short events; short revents; }
  final pfd = calloc<Int32>(2);
  final err = calloc<Int32>();
  final len = calloc<Uint32>()..value = 4;
  try {
    final deadline = DateTime.now().add(Duration(milliseconds: timeoutMs));
    while (true) {
      final left = deadline.difference(DateTime.now()).inMilliseconds;
      if (left <= 0) return _etimedout;
      pfd[0] = fd;
      pfd[1] = _pollOut;
      final n = _libc.poll(pfd.cast(), 1, left);
      if (n < 0) {
        if (_errno() == _eintr) continue;
        return _errno();
      }
      if (n == 0) return _etimedout;
      if (_libc.getsockopt(fd, _solSocket, _soError, err.cast(), len) < 0) {
        return _errno();
      }
      if (err.value != 0) return err.value;
      final revents = (pfd[1] >> 16) & 0xffff;
      return (revents & _pollOut) != 0 ? 0 : _econnreset;
    }
  } finally {
    calloc
      ..free(pfd)
      ..free(err)
      ..free(len);
  }
}

void _setTimeouts(int fd, int seconds) {
  // struct timeval { long tv_sec; long tv_usec; } on 64-bit Linux.
  final tv = calloc<Int64>(2)..[0] = seconds;
  try {
    for (final option in [_soRcvtimeo, _soSndtimeo]) {
      if (_libc.setsockopt(fd, _solSocket, option, tv.cast(), 16) < 0) {
        throw LinuxBluetoothException('setsockopt', _errno());
      }
    }
  } finally {
    calloc.free(tv);
  }
}

void _writeAll(int fd, List<int> bytes) {
  final buffer = calloc<Uint8>(bytes.length);
  try {
    buffer.asTypedList(bytes.length).setAll(0, bytes);
    var sent = 0;
    while (sent < bytes.length) {
      final n = _libc.write(fd, buffer + sent, bytes.length - sent);
      if (n < 0) {
        if (_errno() == _eintr) continue;
        throw LinuxBluetoothException('write', _errno());
      }
      sent += n;
    }
  } finally {
    calloc.free(buffer);
  }
}

Uint8List _readOnce(int fd, int max) {
  final buffer = calloc<Uint8>(max);
  try {
    while (true) {
      final n = _libc.read(fd, buffer, max);
      if (n >= 0) return Uint8List.fromList(buffer.asTypedList(n));
      if (_errno() != _eintr) throw LinuxBluetoothException('read', _errno());
    }
  } finally {
    calloc.free(buffer);
  }
}

int _errno() => _libc.errnoLocation().value;

final _libc = _Libc(DynamicLibrary.process());

class _Libc {
  _Libc(DynamicLibrary lib)
    : socket = lib
          .lookupFunction<
            Int32 Function(Int32, Int32, Int32),
            int Function(int, int, int)
          >('socket'),
      connect = lib
          .lookupFunction<
            Int32 Function(Int32, Pointer<Uint8>, Uint32),
            int Function(int, Pointer<Uint8>, int)
          >('connect'),
      setsockopt = lib
          .lookupFunction<
            Int32 Function(Int32, Int32, Int32, Pointer<Void>, Uint32),
            int Function(int, int, int, Pointer<Void>, int)
          >('setsockopt'),
      read = lib
          .lookupFunction<
            IntPtr Function(Int32, Pointer<Uint8>, Size),
            int Function(int, Pointer<Uint8>, int)
          >('read'),
      write = lib
          .lookupFunction<
            IntPtr Function(Int32, Pointer<Uint8>, Size),
            int Function(int, Pointer<Uint8>, int)
          >('write'),
      poll = lib
          .lookupFunction<
            Int32 Function(Pointer<Void>, Uint64, Int32),
            int Function(Pointer<Void>, int, int)
          >('poll'),
      getsockopt = lib
          .lookupFunction<
            Int32 Function(Int32, Int32, Int32, Pointer<Void>, Pointer<Uint32>),
            int Function(int, int, int, Pointer<Void>, Pointer<Uint32>)
          >('getsockopt'),
      shutdown = lib
          .lookupFunction<Int32 Function(Int32, Int32), int Function(int, int)>(
            'shutdown',
          ),
      close = lib.lookupFunction<Int32 Function(Int32), int Function(int)>(
        'close',
      ),
      errnoLocation = lib
          .lookupFunction<Pointer<Int32> Function(), Pointer<Int32> Function()>(
            '__errno_location',
          );

  final int Function(int, int, int) socket;
  final int Function(int, Pointer<Uint8>, int) connect;
  final int Function(int, int, int, Pointer<Void>, int) setsockopt;
  final int Function(int, Pointer<Uint8>, int) read;
  final int Function(int, Pointer<Uint8>, int) write;
  final int Function(Pointer<Void>, int, int) poll;
  final int Function(int, int, int, Pointer<Void>, Pointer<Uint32>) getsockopt;
  final int Function(int, int) shutdown;
  final int Function(int) close;
  final Pointer<Int32> Function() errnoLocation;
}
