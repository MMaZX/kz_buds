import 'dart:typed_data';

import 'rcsp_frame.dart';

/// Opcodes we send or receive. Reboot (0xE7), factory reset (0xFF), rename
/// and OTA are deliberately absent: the app must never send them.
abstract final class RcspOpcode {
  static const getTargetInfo = 0x03;
  static const getSysInfo = 0x07;
  static const setSysInfo = 0x08;
  static const sysInfoAutoUpdate = 0x09;
  static const searchDevice = 0x19;
  static const advSettings = 0xc0;
  static const advGetInfo = 0xc1;
  static const advStatus = 0xc2;
  static const advRequest = 0xc4;
}

abstract final class RcspSysFunction {
  static const bt = 0x00;
  static const public = 0xff;
}

/// Sys info attributes (GET/SET_SYS_INFO TLV types and mask bits).
abstract final class RcspSysAttr {
  static const battery = 0;
  static const volume = 1;
  static const eq = 4;
  static const noiseLive = 13;
  static const noiseTable = 14;

  static int maskOf(Iterable<int> attrs) =>
      attrs.fold(0, (mask, attr) => mask | (1 << attr));
}

/// ADV info item types (ADV_GET_INFO / ADV_SETTINGS).
abstract final class RcspAdvType {
  static const battery = 0;
  static const keySettings = 2;
  static const micChannel = 4;
  static const workMode = 5;
  static const inEar = 8;
  static const ancCycle = 10;
}

/// A request without its sn; [RcspProtocol] numbers it when sending.
class RcspRequest {
  RcspRequest(this.opcode, List<int> payload)
    : payload = Uint8List.fromList(payload);

  final int opcode;
  final Uint8List payload;

  RcspFrame toFrame({required int sn}) =>
      RcspFrame.command(opcode: opcode, sn: sn, payload: payload);
}

abstract final class RcspCommands {
  static RcspRequest getTargetInfo({int mask = 0xffffffff}) =>
      RcspRequest(RcspOpcode.getTargetInfo, [..._u32(mask), 0x00]);

  static RcspRequest getSysInfo({required int function, required int mask}) =>
      RcspRequest(RcspOpcode.getSysInfo, [
        _byte(function, 'function'),
        ..._u32(mask),
      ]);

  static RcspRequest setSysInfo({
    required int function,
    required List<RcspTlv> items,
  }) => RcspRequest(RcspOpcode.setSysInfo, [
    _byte(function, 'function'),
    for (final item in items) ...item.encode(),
  ]);

  static RcspRequest setVolume(int volume) => setSysInfo(
    function: RcspSysFunction.public,
    items: [
      RcspTlv(RcspSysAttr.volume, [_byte(volume, 'volume')]),
    ],
  );

  static RcspRequest setEq(RcspEq eq) => setSysInfo(
    function: RcspSysFunction.public,
    items: [RcspTlv(RcspSysAttr.eq, eq.encode())],
  );

  static RcspRequest advGetInfo({int mask = 0xffffffff}) =>
      RcspRequest(RcspOpcode.advGetInfo, _u32(mask));

  static RcspRequest advSettings(int type, List<int> value) =>
      RcspRequest(RcspOpcode.advSettings, RcspTlv(type, value).encode());

  /// `[1][op][timeout u16 BE][side][player]`; op 1 starts, 0 stops.
  /// [side] 0 both, 1 left, 2 right. [player] 0 is what the KZ app sends.
  static RcspRequest searchDevice({
    required bool start,
    int timeoutSeconds = 0,
    int side = 0,
    int player = 0,
  }) {
    if (timeoutSeconds < 0 || timeoutSeconds > 0xffff) {
      throw ArgumentError.value(timeoutSeconds, 'timeoutSeconds');
    }
    return RcspRequest(RcspOpcode.searchDevice, [
      0x01,
      start ? 0x01 : 0x00,
      timeoutSeconds >> 8,
      timeoutSeconds & 0xff,
      _byte(side, 'side'),
      _byte(player, 'player'),
    ]);
  }
}

/// GET_SYS_INFO response payload: `[function][TLV...]`.
class RcspSysInfo {
  RcspSysInfo._(this.function, this.values);

  factory RcspSysInfo.parse(List<int> payload) {
    if (payload.isEmpty) {
      throw const FormatException('Sys info payload is empty');
    }
    return RcspSysInfo._(payload[0], {
      for (final item in RcspTlv.parseAll(payload.sublist(1)))
        item.type: item.value,
    });
  }

  final int function;
  final Map<int, Uint8List> values;

  /// Single level 0-100; which earbud it describes is unproven.
  int? get battery => _single(RcspSysAttr.battery);

  int? get volume => _single(RcspSysAttr.volume);

  RcspEq? get eq {
    final v = values[RcspSysAttr.eq];
    return v == null ? null : RcspEq.parse(v);
  }

  RcspNoise? get noise {
    final v = values[RcspSysAttr.noiseLive];
    return v == null ? null : RcspNoise.parse(v);
  }

  int? _single(int attr) {
    final v = values[attr];
    return v == null || v.isEmpty ? null : v[0];
  }
}

/// EQ attribute: `[mode][10 x s8 dB]`.
class RcspEq {
  RcspEq({required this.mode, required List<int> gains})
    : gains = List.unmodifiable(gains);

  factory RcspEq.parse(List<int> value) {
    if (value.length != 1 + bandCount) {
      throw FormatException('EQ needs ${1 + bandCount} bytes', value);
    }
    return RcspEq(
      mode: value[0],
      gains: [for (final b in value.sublist(1)) b.toSigned(8)],
    );
  }

  static const bandCount = 10;
  static const customMode = 6;

  final int mode;
  final List<int> gains;

  Uint8List encode() {
    if (gains.length != bandCount) {
      throw ArgumentError.value(gains, 'gains', 'needs $bandCount values');
    }
    return Uint8List.fromList([
      _byte(mode, 'mode'),
      for (final g in gains) _signedByte(g),
    ]);
  }

  @override
  bool operator ==(Object other) =>
      other is RcspEq && other.mode == mode && _sameInts(other.gains, gains);

  @override
  int get hashCode => Object.hash(mode, Object.hashAll(gains));

  @override
  String toString() => 'RcspEq(mode: $mode, gains: $gains)';
}

/// Live noise attribute (SDK order; only [mode] is confirmed on hardware).
class RcspNoise {
  const RcspNoise({
    required this.mode,
    required this.leftMax,
    required this.rightMax,
    required this.leftCurrent,
    required this.rightCurrent,
  });

  factory RcspNoise.parse(List<int> value) {
    if (value.length != 9) {
      throw FormatException('Noise attribute needs 9 bytes', value);
    }
    int u16(int i) => (value[i] << 8) | value[i + 1];
    return RcspNoise(
      mode: value[0],
      leftMax: u16(1),
      rightMax: u16(3),
      leftCurrent: u16(5),
      rightCurrent: u16(7),
    );
  }

  final int mode;
  final int leftMax;
  final int rightMax;
  final int leftCurrent;
  final int rightCurrent;

  @override
  bool operator ==(Object other) =>
      other is RcspNoise &&
      other.mode == mode &&
      other.leftMax == leftMax &&
      other.rightMax == rightMax &&
      other.leftCurrent == leftCurrent &&
      other.rightCurrent == rightCurrent;

  @override
  int get hashCode =>
      Object.hash(mode, leftMax, rightMax, leftCurrent, rightCurrent);

  @override
  String toString() =>
      'RcspNoise($mode, $leftMax, $rightMax, $leftCurrent, $rightCurrent)';
}

/// One battery byte: bit 7 charging, bits 0-6 percent.
class RcspLevel {
  const RcspLevel({required this.percent, required this.charging});

  final int percent;
  final bool charging;

  /// 0 means the part is not reporting, so it is unknown, not empty.
  static RcspLevel? fromByte(int b) => (b & 0x7f) == 0
      ? null
      : RcspLevel(percent: b & 0x7f, charging: (b & 0x80) != 0);

  @override
  bool operator ==(Object other) =>
      other is RcspLevel &&
      other.percent == percent &&
      other.charging == charging;

  @override
  int get hashCode => Object.hash(percent, charging);

  @override
  String toString() => 'RcspLevel($percent%${charging ? ', charging' : ''})';
}

class RcspBattery {
  const RcspBattery({this.left, this.right, this.chargingCase});

  factory RcspBattery.fromBytes(List<int> bytes) {
    RcspLevel? at(int i) =>
        i < bytes.length ? RcspLevel.fromByte(bytes[i]) : null;
    return RcspBattery(left: at(0), right: at(1), chargingCase: at(2));
  }

  final RcspLevel? left;
  final RcspLevel? right;
  final RcspLevel? chargingCase;

  @override
  bool operator ==(Object other) =>
      other is RcspBattery &&
      other.left == left &&
      other.right == right &&
      other.chargingCase == chargingCase;

  @override
  int get hashCode => Object.hash(left, right, chargingCase);

  @override
  String toString() => 'RcspBattery(L: $left, R: $right, case: $chargingCase)';
}

/// ADV_GET_INFO response payload: a list of TLVs.
class RcspAdvInfo {
  RcspAdvInfo._(this.values);

  factory RcspAdvInfo.parse(List<int> payload) => RcspAdvInfo._({
    for (final item in RcspTlv.parseAll(payload)) item.type: item.value,
  });

  final Map<int, Uint8List> values;

  RcspBattery get battery {
    final v = values[RcspAdvType.battery];
    return v == null ? const RcspBattery() : RcspBattery.fromBytes(v);
  }
}

/// Unsolicited 0xC2 block:
/// `vid u16, uid u16, pid u16, chip<<4|version, mac[6], action, L, R, case, seq`.
class RcspDeviceStatus {
  const RcspDeviceStatus._({
    required this.vendorId,
    required this.productId,
    required this.action,
    required this.battery,
    required this.sequence,
  });

  factory RcspDeviceStatus.parse(List<int> payload) {
    if (payload.length < 18) {
      throw FormatException('C2 status needs 18 bytes', payload);
    }
    return RcspDeviceStatus._(
      vendorId: (payload[0] << 8) | payload[1],
      productId: (payload[4] << 8) | payload[5],
      action: payload[13],
      battery: RcspBattery.fromBytes(payload.sublist(14, 17)),
      sequence: payload[17],
    );
  }

  final int vendorId;
  final int productId;

  /// 0 dismiss, 1 unconnected, 2 connected, 3 connecting, 4 connectionless.
  final int action;
  final RcspBattery battery;
  final int sequence;
}

List<int> _u32(int v) => [
  (v >> 24) & 0xff,
  (v >> 16) & 0xff,
  (v >> 8) & 0xff,
  v & 0xff,
];

int _byte(int value, String name) {
  if (value < 0 || value > 0xff) {
    throw ArgumentError.value(value, name, 'must fit in one byte');
  }
  return value;
}

int _signedByte(int value) {
  if (value < -128 || value > 127) {
    throw ArgumentError.value(value, 'gain', 'must fit in a signed byte');
  }
  return value & 0xff;
}

bool _sameInts(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
