import 'dart:typed_data';

/// One JieLi RCSP frame:
/// `FE DC BA | flags | opcode | len u16 BE | [status] sn | payload | EF`.
///
/// Flags bit 7 marks a command (clear = response), bit 6 asks for a response.
/// `len` counts every byte between the length field and the terminator.
/// See docs/protocol/frame-format.md.
class RcspFrame {
  const RcspFrame._({
    required this.isCommand,
    required this.expectsResponse,
    required this.opcode,
    required this.sn,
    required this.status,
    required this.payload,
  });

  factory RcspFrame.command({
    required int opcode,
    required int sn,
    List<int> payload = const [],
    bool expectsResponse = true,
  }) => RcspFrame._(
    isCommand: true,
    expectsResponse: expectsResponse,
    opcode: _byte(opcode, 'opcode'),
    sn: _byte(sn, 'sn'),
    status: null,
    payload: Uint8List.fromList(payload),
  );

  factory RcspFrame.response({
    required int opcode,
    required int status,
    required int sn,
    List<int> payload = const [],
  }) => RcspFrame._(
    isCommand: false,
    expectsResponse: false,
    opcode: _byte(opcode, 'opcode'),
    sn: _byte(sn, 'sn'),
    status: _byte(status, 'status'),
    payload: Uint8List.fromList(payload),
  );

  static const magic = [0xfe, 0xdc, 0xba];
  static const terminator = 0xef;

  /// Magic, flags, opcode, length and terminator.
  static const overhead = 8;

  static const _commandBit = 0x80;
  static const _responseBit = 0x40;

  final bool isCommand;
  final bool expectsResponse;
  final int opcode;
  final int sn;

  /// Present only in responses; 0 means success.
  final int? status;
  final Uint8List payload;

  /// Parses exactly one frame. Throws [FormatException] on any mismatch.
  factory RcspFrame.decode(List<int> bytes) {
    if (bytes.length < overhead + 1) {
      throw const FormatException('RCSP frame too short');
    }
    for (var i = 0; i < magic.length; i++) {
      if (bytes[i] != magic[i]) {
        throw const FormatException('RCSP frame has a bad magic');
      }
    }
    if (bytes.last != terminator) {
      throw const FormatException('RCSP frame has no terminator');
    }
    final length = (bytes[5] << 8) | bytes[6];
    if (length != bytes.length - overhead) {
      throw FormatException(
        'RCSP length $length does not match ${bytes.length - overhead} bytes',
      );
    }
    final flags = bytes[3];
    final opcode = bytes[4];
    final body = bytes.sublist(7, bytes.length - 1);
    if ((flags & _commandBit) != 0) {
      return RcspFrame._(
        isCommand: true,
        expectsResponse: (flags & _responseBit) != 0,
        opcode: opcode,
        sn: body[0],
        status: null,
        payload: Uint8List.fromList(body.sublist(1)),
      );
    }
    if (body.length < 2) {
      throw const FormatException('RCSP response has no status and sn');
    }
    return RcspFrame._(
      isCommand: false,
      expectsResponse: false,
      opcode: opcode,
      sn: body[1],
      status: body[0],
      payload: Uint8List.fromList(body.sublist(2)),
    );
  }

  Uint8List encode() {
    final body = [?status, sn, ...payload];
    final flags =
        (isCommand ? _commandBit : 0) | (expectsResponse ? _responseBit : 0);
    return Uint8List.fromList([
      ...magic,
      flags,
      opcode,
      body.length >> 8,
      body.length & 0xff,
      ...body,
      terminator,
    ]);
  }

  @override
  bool operator ==(Object other) =>
      other is RcspFrame &&
      other.isCommand == isCommand &&
      other.expectsResponse == expectsResponse &&
      other.opcode == opcode &&
      other.sn == sn &&
      other.status == status &&
      _sameBytes(other.payload, payload);

  @override
  int get hashCode => Object.hash(
    isCommand,
    expectsResponse,
    opcode,
    sn,
    status,
    Object.hashAll(payload),
  );

  @override
  String toString() =>
      'RcspFrame(${isCommand ? 'cmd' : 'rsp'} op=0x${_hex(opcode)} sn=$sn'
      '${status == null ? '' : ' status=$status'} '
      'payload=${payload.map(_hex).join(' ')})';
}

/// Splits a byte stream (SPP or BLE notifications) into frames.
///
/// Bytes before a magic and frames that fail to decode are dropped, so one
/// corrupt frame never stalls the stream.
class RcspFrameReader {
  final _buffer = <int>[];

  List<RcspFrame> add(List<int> chunk) {
    _buffer.addAll(chunk);
    final frames = <RcspFrame>[];
    while (true) {
      final start = _findMagic();
      if (start < 0) {
        // Keep a possible partial magic at the tail.
        final keep = _buffer.length < 2 ? _buffer.length : 2;
        _buffer.removeRange(0, _buffer.length - keep);
        return frames;
      }
      _buffer.removeRange(0, start);
      if (_buffer.length < 7) return frames;
      final end = RcspFrame.overhead + ((_buffer[5] << 8) | _buffer[6]);
      if (_buffer.length < end) return frames;
      try {
        frames.add(RcspFrame.decode(_buffer.sublist(0, end)));
        _buffer.removeRange(0, end);
      } on FormatException {
        _buffer.removeAt(0);
      }
    }
  }

  int _findMagic() {
    for (var i = 0; i + 2 < _buffer.length; i++) {
      if (_buffer[i] == RcspFrame.magic[0] &&
          _buffer[i + 1] == RcspFrame.magic[1] &&
          _buffer[i + 2] == RcspFrame.magic[2]) {
        return i;
      }
    }
    return -1;
  }
}

/// `len type value` item used by sys info and ADV info; `len` counts the
/// type byte.
class RcspTlv {
  RcspTlv(this.type, List<int> value) : value = Uint8List.fromList(value);

  final int type;
  final Uint8List value;

  static List<RcspTlv> parseAll(List<int> bytes) {
    final items = <RcspTlv>[];
    var i = 0;
    while (i < bytes.length) {
      final len = bytes[i];
      if (len == 0) {
        throw FormatException('RCSP TLV with zero length at $i');
      }
      final end = i + 1 + len;
      if (end > bytes.length) {
        throw FormatException('RCSP TLV at $i runs past the end');
      }
      items.add(RcspTlv(bytes[i + 1], bytes.sublist(i + 2, end)));
      i = end;
    }
    return items;
  }

  Uint8List encode() => Uint8List.fromList([value.length + 1, type, ...value]);

  @override
  bool operator ==(Object other) =>
      other is RcspTlv && other.type == type && _sameBytes(other.value, value);

  @override
  int get hashCode => Object.hash(type, Object.hashAll(value));
}

int _byte(int value, String name) {
  if (value < 0 || value > 0xff) {
    throw ArgumentError.value(value, name, 'must fit in one byte');
  }
  return value;
}

bool _sameBytes(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

String _hex(int b) => b.toRadixString(16).padLeft(2, '0');
