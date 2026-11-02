import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kz_buds/data/protocol/rcsp_auth.dart';
import 'package:kz_buds/data/protocol/rcsp_commands.dart';
import 'package:kz_buds/data/protocol/rcsp_frame.dart';
import 'package:kz_buds/data/protocol/rcsp_protocol.dart';

import 'hex.dart';

/// In-memory transport; [onWrite] plays the earbuds.
class FakeTransport implements RcspTransport {
  final _incoming = StreamController<List<int>>();
  final written = <Uint8List>[];
  void Function(Uint8List bytes)? onWrite;

  @override
  Stream<List<int>> get incoming => _incoming.stream;

  @override
  Future<void> write(List<int> bytes) async {
    final copy = Uint8List.fromList(bytes);
    written.add(copy);
    onWrite?.call(copy);
  }

  void deviceSends(List<int> bytes) => _incoming.add(bytes);

  Future<void> close() => _incoming.close();
}

/// Earbuds side of the handshake, answering with [deviceAuth].
void playHonestEarbuds(FakeTransport t, {RcspAuth? deviceAuth}) {
  final auth = deviceAuth ?? RcspAuth();
  final ownChallenge = hex(
    '00 6a 74 fb 64 f1 8b 42 01 33 cc 8f c3 95 12 f9 1f',
  );
  t.onWrite = (bytes) {
    if (bytes.length == 17 && bytes[0] == RcspAuth.challengeFlag) {
      t.deviceSends(auth.answer(bytes));
    } else if (RcspAuth.isPass(bytes)) {
      t.deviceSends(ownChallenge);
    } else if (bytes.length == 17 && bytes[0] == RcspAuth.answerFlag) {
      if (auth.verify(ownChallenge, bytes)) t.deviceSends(RcspAuth.passMessage);
    }
  };
}

void main() {
  const timeout = Duration(milliseconds: 60);
  late FakeTransport transport;
  late RcspProtocol protocol;

  setUp(() {
    transport = FakeTransport();
    protocol = RcspProtocol(
      transport,
      auth: RcspAuth(random: Random(1)),
      timeout: timeout,
    );
  });

  tearDown(() async {
    await protocol.close();
    await transport.close();
  });

  group('authenticate', () {
    test('completes the two-way handshake', () async {
      playHonestEarbuds(transport);

      await protocol.authenticate();

      expect(transport.written, hasLength(3));
      expect(transport.written[0].first, RcspAuth.challengeFlag);
      expect(RcspAuth.isPass(transport.written[1]), isTrue);
      expect(transport.written[2].first, RcspAuth.answerFlag);
    });

    test('accepts the handshake split into small chunks', () async {
      final honest = RcspAuth();
      transport.onWrite = (bytes) {
        if (bytes[0] == RcspAuth.challengeFlag) {
          final reply = honest.answer(bytes);
          transport
            ..deviceSends(reply.sublist(0, 5))
            ..deviceSends(reply.sublist(5));
        } else if (RcspAuth.isPass(bytes)) {
          transport.deviceSends(
            hex('00 6d 83 df 5d ab 1e 75 b9 95 e3 a6 fc cc 6b 2c 4c'),
          );
        } else {
          transport
            ..deviceSends(hex('02 70'))
            ..deviceSends(hex('61 73 73'));
        }
      };

      await protocol.authenticate();
    });

    test('rejects earbuds that answer with another key', () async {
      playHonestEarbuds(
        transport,
        deviceAuth: RcspAuth(linkKey: List.filled(16, 0)),
      );

      await expectLater(
        protocol.authenticate(),
        throwsA(isA<RcspAuthException>()),
      );
      expect(transport.written, hasLength(1));
    });

    test('times out when the earbuds stay silent', () async {
      await expectLater(
        protocol.authenticate(),
        throwsA(isA<TimeoutException>()),
      );
    });
  });

  group('send', () {
    void answerEveryCommand({int status = 0, Set<int> ignore = const {}}) {
      var seen = 0;
      transport.onWrite = (bytes) {
        final request = RcspFrame.decode(bytes);
        if (ignore.contains(seen++)) return;
        transport.deviceSends(
          RcspFrame.response(
            opcode: request.opcode,
            status: status,
            sn: request.sn,
            payload: hex('ff 02 00 50'),
          ).encode(),
        );
      };
    }

    test('returns the response with the same opcode and sn', () async {
      answerEveryCommand();

      final response = await protocol.send(
        RcspCommands.getSysInfo(function: RcspSysFunction.public, mask: 1),
      );

      expect(response.opcode, RcspOpcode.getSysInfo);
      expect(response.payload, hex('ff 02 00 50'));
    });

    test('gives every request its own sn', () async {
      answerEveryCommand();

      await protocol.send(RcspCommands.advGetInfo());
      await protocol.send(RcspCommands.advGetInfo());

      final sns = transport.written.map((b) => RcspFrame.decode(b).sn);
      expect(sns.toSet(), hasLength(2));
    });

    test('ignores a response with another sn', () async {
      transport.onWrite = (bytes) {
        final request = RcspFrame.decode(bytes);
        transport
          ..deviceSends(
            RcspFrame.response(
              opcode: request.opcode,
              status: 0,
              sn: (request.sn + 1) & 0xff,
              payload: hex('aa'),
            ).encode(),
          )
          ..deviceSends(
            RcspFrame.response(
              opcode: request.opcode,
              status: 0,
              sn: request.sn,
              payload: hex('bb'),
            ).encode(),
          );
      };

      final response = await protocol.send(RcspCommands.advGetInfo());

      expect(response.payload, hex('bb'));
    });

    test('retries a request that got no answer', () async {
      answerEveryCommand(ignore: {0});

      await protocol.send(RcspCommands.advGetInfo());

      expect(transport.written, hasLength(2));
      expect(transport.written[0], transport.written[1]);
    });

    test('gives up after the last retry', () async {
      await expectLater(
        protocol.send(RcspCommands.advGetInfo()),
        throwsA(isA<TimeoutException>()),
      );
      expect(transport.written, hasLength(RcspProtocol.defaultRetries + 1));
    });

    test('throws when the earbuds report a failure status', () async {
      answerEveryCommand(status: 1);

      await expectLater(
        protocol.send(RcspCommands.advGetInfo()),
        throwsA(
          isA<RcspCommandException>().having((e) => e.status, 'status', 1),
        ),
      );
    });
  });

  test('device commands are published on their own stream', () async {
    final next = protocol.deviceCommands.first;

    transport.deviceSends(hex('fe dc ba 80 09 00 05 05 00 02 07 01 ef'));

    final frame = await next;
    expect(frame.opcode, RcspOpcode.sysInfoAutoUpdate);
    expect(frame.payload, hex('00 02 07 01'));
  });

  test('closed completes when the link ends', () async {
    await transport.close();

    await expectLater(protocol.closed, completes);
  });

  test('close fails a pending request', () async {
    final failure = expectLater(
      protocol.send(RcspCommands.advGetInfo()),
      throwsA(isA<StateError>()),
    );

    await protocol.close();

    await failure;
  });
}
