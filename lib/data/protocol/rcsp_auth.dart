import 'dart:math';
import 'dart:typed_data';

/// RCSP challenge/response auth, built on the Bluetooth E1 function
/// (SAFER+ based). Clean-room from the public Bluetooth Core specification;
/// the JieLi specifics (key, address, message layout) are in
/// docs/protocol/safer-e1-auth.md.
class RcspAuth {
  RcspAuth({Random? random, List<int>? linkKey})
    : _random = random ?? Random.secure(),
      _key = Uint8List.fromList(linkKey ?? defaultLinkKey) {
    _checkLength(_key, 16, 'linkKey');
  }

  /// Built-in key of the JieLi library; neither KZ app overrides it.
  static final defaultLinkKey = Uint8List.fromList(const [
    0x06, 0x77, 0x5f, 0x87, 0x91, 0x8d, 0xd4, 0x23, //
    0x00, 0x5d, 0xf1, 0xd8, 0xcf, 0x0c, 0x14, 0x2b,
  ]);

  /// Fixed address the library feeds to E1 instead of the real BD_ADDR.
  static final defaultAddress = Uint8List.fromList(const [
    0x11,
    0x22,
    0x33,
    0x33,
    0x22,
    0x11,
  ]);

  static const challengeFlag = 0x00;
  static const answerFlag = 0x01;

  /// "pass" message, sent by whichever side accepted the other's answer.
  static final passMessage = Uint8List.fromList(const [
    0x02,
    0x70,
    0x61,
    0x73,
    0x73,
  ]);

  final Random _random;
  Uint8List _key;

  void setLinkKey(List<int> key) {
    _checkLength(key, 16, 'key');
    _key = Uint8List.fromList(key);
  }

  /// `[0x00, r0..r15]`, ready to send.
  Uint8List randomChallenge() => Uint8List.fromList([
    challengeFlag,
    for (var i = 0; i < 16; i++) _random.nextInt(256),
  ]);

  /// Answers a `[0x00, r0..r15]` challenge with `[0x01, E1(r)]`.
  Uint8List answer(List<int> challenge) {
    _checkMessage(challenge, challengeFlag, 'challenge');
    return Uint8List.fromList([
      answerFlag,
      ...e1(key: _key, random: challenge.sublist(1), address: defaultAddress),
    ]);
  }

  /// Whether [reply] is the correct answer to our own [challenge].
  bool verify(List<int> challenge, List<int> reply) {
    if (reply.length != 17 || reply[0] != answerFlag) return false;
    final expected = answer(challenge);
    var diff = 0;
    for (var i = 1; i < 17; i++) {
      diff |= expected[i] ^ reply[i];
    }
    return diff == 0;
  }

  static bool isPass(List<int> message) =>
      message.length == passMessage.length &&
      Iterable<int>.generate(message.length)
          .every((i) => message[i] == passMessage[i]);

  static void _checkMessage(List<int> message, int flag, String name) {
    _checkLength(message, 17, name);
    if (message[0] != flag) {
      throw ArgumentError.value(message[0], name, 'must start with $flag');
    }
  }
}

/// Bluetooth E1: `Ar'(K~, (Ar(K, RAND) xor RAND) + E(addr))`, all 16 bytes.
Uint8List e1({
  required List<int> key,
  required List<int> random,
  required List<int> address,
}) {
  _checkLength(key, 16, 'key');
  _checkLength(random, 16, 'random');
  _checkLength(address, 6, 'address');

  final first = _Safer.encrypt(key, random, modified: false);
  final mixed = Uint8List(16);
  for (var i = 0; i < 16; i++) {
    mixed[i] = ((first[i] ^ random[i]) + address[i % 6]) & 0xff;
  }
  return _Safer.encrypt(_offsetKey(key), mixed, modified: true);
}

const _offsetConstants = [
  233, 229, 223, 193, 179, 167, 149, 131, //
  233, 229, 223, 193, 179, 167, 149, 131,
];

/// Bytes 0, 2, 4, 6, 9, 11, 13, 15 are added, the rest XORed.
const _offsetAdds = {0, 2, 4, 6, 9, 11, 13, 15};

Uint8List _offsetKey(List<int> key) => Uint8List.fromList([
  for (var i = 0; i < 16; i++)
    _offsetAdds.contains(i)
        ? (key[i] + _offsetConstants[i]) & 0xff
        : key[i] ^ _offsetConstants[i],
]);

/// SAFER+ with a 128-bit key, as profiled by Bluetooth (Ar and Ar').
abstract final class _Safer {
  static const _rounds = 8;

  /// Positions that take XOR in the first key addition (mask 0x9999).
  static const _xorFirst = [
    true, false, false, true, true, false, false, true, //
    true, false, false, true, true, false, false, true,
  ];

  /// Armenian shuffle: output[i] = input[_shuffle[i]].
  static const _shuffle = [
    8,
    11,
    12,
    15,
    2,
    1,
    6,
    5,
    10,
    9,
    14,
    13,
    0,
    7,
    4,
    3,
  ];

  /// exp[i] = (45^i mod 257) mod 256, log is its inverse.
  static final (Uint8List, Uint8List) _tables = () {
    final exp = Uint8List(256);
    final log = Uint8List(256);
    var v = 1;
    for (var i = 0; i < 256; i++) {
      exp[i] = v & 0xff;
      log[v & 0xff] = i;
      v = (v * 45) % 257;
    }
    return (exp, log);
  }();

  static Uint8List encrypt(
    List<int> key,
    List<int> input, {
    required bool modified,
  }) {
    final (exp, log) = _tables;
    final keys = _schedule(key, exp);
    var state = Uint8List.fromList(input);
    for (var r = 0; r < _rounds; r++) {
      if (modified && r == 2) _mix(state, input, xorFirst: true);
      _mix(state, keys[2 * r], xorFirst: true);
      for (var i = 0; i < 16; i++) {
        state[i] = _xorFirst[i] ? exp[state[i]] : log[state[i]];
      }
      _mix(state, keys[2 * r + 1], xorFirst: false);
      state = _diffuse(state);
    }
    _mix(state, keys[2 * _rounds], xorFirst: true);
    return state;
  }

  /// Adds [other] into [state]: XOR at the 0x9999 positions and ADD elsewhere
  /// when [xorFirst], the opposite otherwise.
  static void _mix(Uint8List state, List<int> other, {required bool xorFirst}) {
    for (var i = 0; i < 16; i++) {
      state[i] = _xorFirst[i] == xorFirst
          ? state[i] ^ other[i]
          : (state[i] + other[i]) & 0xff;
    }
  }

  /// Four Pseudo-Hadamard layers with an Armenian shuffle between them.
  static Uint8List _diffuse(Uint8List state) {
    var s = state;
    for (var layer = 0; layer < 4; layer++) {
      if (layer > 0) {
        s = Uint8List.fromList([for (final j in _shuffle) s[j]]);
      }
      for (var i = 0; i < 16; i += 2) {
        final a = s[i];
        final b = s[i + 1];
        s[i] = (2 * a + b) & 0xff;
        s[i + 1] = (a + b) & 0xff;
      }
    }
    return s;
  }

  /// 17 round keys from a 16-byte key extended with its XOR parity byte.
  static List<Uint8List> _schedule(List<int> key, Uint8List exp) {
    final reg = Uint8List(17)..setRange(0, 16, key);
    reg[16] = key.fold(0, (a, b) => a ^ b);
    final keys = [Uint8List.fromList(key)];
    for (var p = 2; p <= 17; p++) {
      for (var i = 0; i < 17; i++) {
        reg[i] = ((reg[i] << 3) | (reg[i] >> 5)) & 0xff;
      }
      keys.add(
        Uint8List.fromList([
          for (var i = 0; i < 16; i++)
            (reg[(p - 1 + i) % 17] + exp[exp[(17 * p + i + 1) & 0xff]]) & 0xff,
        ]),
      );
    }
    return keys;
  }
}

void _checkLength(List<int> bytes, int length, String name) {
  if (bytes.length != length) {
    throw ArgumentError.value(bytes.length, name, 'must be $length bytes');
  }
}
