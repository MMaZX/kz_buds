import 'dart:typed_data';

class SdpException implements Exception {
  const SdpException(this.code);

  /// SDP ErrorCode from an SDP_ErrorResponse PDU.
  final int code;

  @override
  String toString() => 'SdpException: error code $code';
}

class SdpAttributeResponse {
  SdpAttributeResponse(List<int> attributeBytes, List<int> continuation)
    : attributeBytes = Uint8List.fromList(attributeBytes),
      continuation = Uint8List.fromList(continuation);

  /// This PDU's slice of the AttributeLists; slices concatenate.
  final Uint8List attributeBytes;

  /// Empty when the server has sent everything.
  final Uint8List continuation;
}

/// Minimal SDP client codec (Bluetooth Core, Vol 3 Part B): one
/// ServiceSearchAttribute exchange, enough to find an RFCOMM channel.
abstract final class Sdp {
  static const serialPortUuid = 0x1101;
  static const protocolDescriptorListAttr = 0x0004;

  static const _errorResponse = 0x01;
  static const _searchAttributeRequest = 0x06;
  static const _searchAttributeResponse = 0x07;
  static const _maxAttributeBytes = 0x03f0;
  static const _rfcommUuid = 0x0003;

  /// Base UUID tail shared by the 128-bit forms of 16-bit UUIDs.
  static const _baseUuidTail = [
    0x00, 0x00, 0x10, 0x00, 0x80, 0x00, 0x00, 0x80, //
    0x5f, 0x9b, 0x34, 0xfb,
  ];

  static Uint8List serviceSearchAttributeRequest({
    required int transactionId,
    required int uuid16,
    required int attributeId,
    List<int> continuation = const [],
  }) {
    final params = [
      0x35, 0x03, 0x19, ..._u16(uuid16), //
      ..._u16(_maxAttributeBytes),
      0x35, 0x03, 0x09, ..._u16(attributeId),
      continuation.length,
      ...continuation,
    ];
    return Uint8List.fromList([
      _searchAttributeRequest,
      ..._u16(transactionId),
      ..._u16(params.length),
      ...params,
    ]);
  }

  static SdpAttributeResponse parseServiceSearchAttributeResponse(
    List<int> pdu, {
    required int transactionId,
  }) {
    if (pdu.length < 5) throw const FormatException('SDP PDU too short');
    final params = (pdu[3] << 8) | pdu[4];
    if (pdu.length != 5 + params) {
      throw FormatException('SDP PDU length $params does not match', pdu);
    }
    if (((pdu[1] << 8) | pdu[2]) != transactionId) {
      throw const FormatException('SDP response to another transaction');
    }
    if (pdu[0] == _errorResponse && params >= 2) {
      throw SdpException((pdu[5] << 8) | pdu[6]);
    }
    if (pdu[0] != _searchAttributeResponse || params < 3) {
      throw FormatException('Unexpected SDP PDU 0x${pdu[0].toRadixString(16)}');
    }
    final count = (pdu[5] << 8) | pdu[6];
    final stateAt = 7 + count;
    if (stateAt >= pdu.length || stateAt + 1 + pdu[stateAt] != pdu.length) {
      throw const FormatException('SDP continuation state is malformed');
    }
    return SdpAttributeResponse(
      pdu.sublist(7, stateAt),
      pdu.sublist(stateAt + 1),
    );
  }

  /// First RFCOMM server channel in complete AttributeLists bytes, or null.
  static int? rfcommChannel(List<int> attributeLists) {
    final (root, end) = _parse(attributeLists, 0);
    if (end != attributeLists.length) {
      throw const FormatException('Trailing bytes after SDP attribute lists');
    }
    return _findChannel(root);
  }

  static int? _findChannel(Object? element) {
    if (element is! List<Object?>) return null;
    for (var i = 0; i + 1 < element.length; i++) {
      if (_isRfcommUuid(element[i]) && element[i + 1] is int) {
        return element[i + 1]! as int;
      }
    }
    for (final child in element) {
      final channel = _findChannel(child);
      if (channel != null) return channel;
    }
    return null;
  }

  static bool _isRfcommUuid(Object? element) {
    if (element is! _Uuid) return false;
    final b = element.bytes;
    if (b.length == 2 || b.length == 4) {
      return b.fold(0, (v, x) => (v << 8) | x) == _rfcommUuid;
    }
    return b.length == 16 &&
        b[0] == 0 &&
        b[1] == 0 &&
        ((b[2] << 8) | b[3]) == _rfcommUuid &&
        _sameTail(b.sublist(4));
  }

  static bool _sameTail(List<int> tail) {
    for (var i = 0; i < _baseUuidTail.length; i++) {
      if (tail[i] != _baseUuidTail[i]) return false;
    }
    return true;
  }

  /// Decodes one data element: a sequence or alternative becomes a list,
  /// an unsigned integer an int, a UUID a [_Uuid], anything else raw bytes.
  static (Object?, int) _parse(List<int> bytes, int at) {
    if (at >= bytes.length) throw const FormatException('SDP element missing');
    final header = bytes[at];
    final type = header >> 3;
    final sizeIndex = header & 0x07;
    var start = at + 1;
    int size;
    if (type == 0) {
      return (null, start);
    } else if (sizeIndex < 5) {
      size = 1 << sizeIndex;
    } else {
      final lengthBytes = 1 << (sizeIndex - 5);
      if (start + lengthBytes > bytes.length) {
        throw const FormatException('SDP element length runs past the end');
      }
      size = bytes
          .sublist(start, start + lengthBytes)
          .fold(0, (v, x) => (v << 8) | x);
      start += lengthBytes;
    }
    final end = start + size;
    if (end > bytes.length) {
      throw const FormatException('SDP element runs past the end');
    }
    final body = bytes.sublist(start, end);
    switch (type) {
      case 1:
        return (body.fold<int>(0, (v, x) => (v << 8) | x), end);
      case 3:
        return (_Uuid(body), end);
      case 6:
      case 7:
        final children = <Object?>[];
        var i = start;
        while (i < end) {
          final (child, next) = _parse(bytes.sublist(0, end), i);
          children.add(child);
          i = next;
        }
        return (children, end);
      default:
        return (body, end);
    }
  }

  static List<int> _u16(int v) => [(v >> 8) & 0xff, v & 0xff];
}

class _Uuid {
  const _Uuid(this.bytes);

  final List<int> bytes;
}
