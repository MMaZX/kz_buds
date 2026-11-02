import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kz_buds/data/protocol/rcsp_frame.dart';

import 'hex.dart';

void main() {
  group('RcspFrame.encode', () {
    test('matches the captured GET_TARGET_INFO request', () {
      final frame = RcspFrame.command(
        opcode: 0x03,
        sn: 1,
        payload: hex('ff ff ff ff 00'),
      );

      expect(frame.encode(), hex('fe dc ba c0 03 00 06 01 ff ff ff ff 00 ef'));
    });

    test('matches the captured GET_SYS_INFO battery request', () {
      final frame = RcspFrame.command(
        opcode: 0x07,
        sn: 2,
        payload: hex('ff 00 00 00 01'),
      );

      expect(frame.encode(), hex('fe dc ba c0 07 00 06 02 ff 00 00 00 01 ef'));
    });

    test('puts status before sn in a response', () {
      final frame = RcspFrame.response(
        opcode: 0x07,
        status: 0,
        sn: 2,
        payload: hex('ff 02 00 64'),
      );

      expect(frame.encode(), hex('fe dc ba 00 07 00 06 00 02 ff 02 00 64 ef'));
    });

    test('clears the response bit for a command that expects none', () {
      final frame = RcspFrame.command(
        opcode: 0x09,
        sn: 5,
        payload: hex('00 02 07 01'),
        expectsResponse: false,
      );

      expect(frame.encode(), hex('fe dc ba 80 09 00 05 05 00 02 07 01 ef'));
    });
  });

  group('RcspFrame.decode', () {
    test('reads a response with status and sn', () {
      final frame = RcspFrame.decode(
        hex('fe dc ba 00 07 00 06 00 02 ff 02 00 64 ef'),
      );

      expect(frame.isCommand, isFalse);
      expect(frame.opcode, 0x07);
      expect(frame.status, 0);
      expect(frame.sn, 2);
      expect(frame.payload, hex('ff 02 00 64'));
    });

    test('reads a device command with sn and no status', () {
      final frame = RcspFrame.decode(
        hex('fe dc ba 80 09 00 05 05 00 02 07 01 ef'),
      );

      expect(frame.isCommand, isTrue);
      expect(frame.expectsResponse, isFalse);
      expect(frame.opcode, 0x09);
      expect(frame.status, isNull);
      expect(frame.sn, 5);
      expect(frame.payload, hex('00 02 07 01'));
    });

    test('round-trips a command', () {
      final original = RcspFrame.command(
        opcode: 0xc1,
        sn: 200,
        payload: hex('ff ff ff ff'),
      );

      final decoded = RcspFrame.decode(original.encode());

      expect(decoded, original);
    });

    test('rejects a bad magic', () {
      expect(
        () => RcspFrame.decode(hex('fe dc bb c0 03 00 01 01 ef')),
        throwsFormatException,
      );
    });

    test('rejects a missing terminator', () {
      expect(
        () => RcspFrame.decode(hex('fe dc ba c0 03 00 01 01 ee')),
        throwsFormatException,
      );
    });

    test('rejects a length that does not match the bytes', () {
      expect(
        () => RcspFrame.decode(hex('fe dc ba c0 03 00 04 01 ff ef')),
        throwsFormatException,
      );
    });

    test('rejects a response too short to hold status and sn', () {
      expect(
        () => RcspFrame.decode(hex('fe dc ba 00 03 00 01 00 ef')),
        throwsFormatException,
      );
    });
  });

  group('RcspFrameReader', () {
    test('reassembles a frame split across chunks', () {
      final reader = RcspFrameReader();

      expect(reader.add(hex('fe dc ba 00 07')), isEmpty);
      final frames = reader.add(hex('00 06 00 02 ff 02 00 64 ef'));

      expect(frames, hasLength(1));
      expect(frames.single.sn, 2);
    });

    test('returns every frame in one chunk', () {
      final reader = RcspFrameReader();
      final bytes = Uint8List.fromList([
        ...hex('fe dc ba 80 09 00 05 05 00 02 07 01 ef'),
        ...hex('fe dc ba 00 07 00 06 00 02 ff 02 00 64 ef'),
      ]);

      final frames = reader.add(bytes);

      expect(frames.map((f) => f.opcode), [0x09, 0x07]);
    });

    test('skips bytes before the magic', () {
      final reader = RcspFrameReader();

      final frames = reader.add(
        hex('01 02 fe fe dc ba 80 09 00 05 05 00 02 07 01 ef'),
      );

      expect(frames.single.opcode, 0x09);
    });

    test('drops a corrupt frame and keeps reading', () {
      final reader = RcspFrameReader();

      final frames = reader.add(
        hex(
          'fe dc ba 80 09 00 05 05 00 02 07 01 ee '
          'fe dc ba 80 09 00 05 06 00 02 07 00 ef',
        ),
      );

      expect(frames.single.sn, 6);
    });
  });

  group('RcspTlv', () {
    test('parses the captured EQ and live noise attributes', () {
      final items = RcspTlv.parseAll(
        hex(
          '0c 04 00 00 fd fd 04 fa 01 02 02 02 02 '
          '0a 0d 01 40 00 00 60 ff 00 00 60',
        ),
      );

      expect(items.map((t) => t.type), [4, 13]);
      expect(items[0].value, hex('00 00 fd fd 04 fa 01 02 02 02 02'));
      expect(items[1].value, hex('01 40 00 00 60 ff 00 00 60'));
    });

    test('encodes len as the type byte plus the value', () {
      expect(RcspTlv(1, hex('32')).encode(), hex('02 01 32'));
    });

    test('rejects an item that runs past the end', () {
      expect(() => RcspTlv.parseAll(hex('05 04 00 01')), throwsFormatException);
    });
  });
}
