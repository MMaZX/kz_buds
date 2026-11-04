import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kz_buds/data/protocol/rcsp_auth.dart';

import 'hex.dart';

void main() {
  // Live challenge/response pairs captured from a Carol Pro over SPP
  // (odd/tasks/carol-pro-bluetooth.md L7).
  const vectors = {
    '6d 83 df 5d ab 1e 75 b9 95 e3 a6 fc cc 6b 2c 4c':
        'f3 97 64 5b c3 7b 83 55 ae a7 6b 0f 53 30 86 ea',
    '6a 74 fb 64 f1 8b 42 01 33 cc 8f c3 95 12 f9 1f':
        '8a a1 23 05 79 09 94 f1 fa c9 be e3 f2 e1 47 3b',
    '03 53 2b 37 5c e1 d3 21 57 81 84 e5 20 24 2a b2':
        '16 c2 77 f6 d3 be 46 58 bf 27 13 16 4a c9 17 5e',
  };

  group('e1', () {
    for (final MapEntry(key: challenge, value: response) in vectors.entries) {
      test('matches the earbuds for challenge $challenge', () {
        final out = e1(
          key: RcspAuth.defaultLinkKey,
          random: hex(challenge),
          address: RcspAuth.defaultAddress,
        );

        expect(out, hex(response));
      });
    }

    test('rejects inputs of the wrong length', () {
      expect(
        () => e1(
          key: RcspAuth.defaultLinkKey,
          random: hex('00 01'),
          address: RcspAuth.defaultAddress,
        ),
        throwsArgumentError,
      );
    });
  });

  group('RcspAuth', () {
    test('a challenge is 0x00 plus 16 random bytes', () {
      final auth = RcspAuth(random: Random(7));

      final challenge = auth.randomChallenge();

      expect(challenge, hasLength(17));
      expect(challenge.first, 0x00);
      expect(challenge.sublist(1).toSet().length, greaterThan(1));
    });

    test('answers a challenge with 0x01 plus the E1 result', () {
      final auth = RcspAuth();
      final challenge = hex('00 ${vectors.keys.first}');

      expect(auth.answer(challenge), hex('01 ${vectors.values.first}'));
    });

    test('verifies the earbuds reply to its own challenge', () {
      final auth = RcspAuth();
      final challenge = hex('00 ${vectors.keys.first}');

      expect(auth.verify(challenge, hex('01 ${vectors.values.first}')), isTrue);
      expect(auth.verify(challenge, hex('01 ${vectors.values.last}')), isFalse);
    });

    test('a new link key changes the answer', () {
      final auth = RcspAuth()..setLinkKey(List.filled(16, 0));
      final challenge = hex('00 ${vectors.keys.first}');

      expect(auth.answer(challenge), isNot(hex('01 ${vectors.values.first}')));
    });

    test('recognises the pass message', () {
      expect(RcspAuth.isPass(hex('02 70 61 73 73')), isTrue);
      expect(RcspAuth.isPass(hex('02 70 61 73 74')), isFalse);
    });
  });
}
