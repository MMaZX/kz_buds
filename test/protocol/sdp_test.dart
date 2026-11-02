import 'package:flutter_test/flutter_test.dart';
import 'package:kz_buds/data/protocol/sdp.dart';

import 'hex.dart';

void main() {
  group('serviceSearchAttributeRequest', () {
    test('asks for the protocol descriptor list of SPP', () {
      final pdu = Sdp.serviceSearchAttributeRequest(
        transactionId: 1,
        uuid16: Sdp.serialPortUuid,
        attributeId: Sdp.protocolDescriptorListAttr,
      );

      expect(pdu, hex('06 00 01 00 0d 35 03 19 11 01 03 f0 35 03 09 00 04 00'));
    });

    test('appends the continuation state of a previous response', () {
      final pdu = Sdp.serviceSearchAttributeRequest(
        transactionId: 2,
        uuid16: Sdp.serialPortUuid,
        attributeId: Sdp.protocolDescriptorListAttr,
        continuation: hex('aa bb'),
      );

      expect(
        pdu,
        hex('06 00 02 00 0f 35 03 19 11 01 03 f0 35 03 09 00 04 02 aa bb'),
      );
    });
  });

  group('parseServiceSearchAttributeResponse', () {
    // One record: L2CAP, then RFCOMM on channel 2.
    const oneRecord =
        '35 13 35 11 09 00 04 35 0c 35 03 19 01 00 35 05 19 00 03 08 02';

    test('returns the attribute bytes when there is no continuation', () {
      final response = Sdp.parseServiceSearchAttributeResponse(
        hex('07 00 01 00 18 00 15 $oneRecord 00'),
        transactionId: 1,
      );

      expect(response.attributeBytes, hex(oneRecord));
      expect(response.continuation, isEmpty);
    });

    test('returns the continuation state of a partial response', () {
      final response = Sdp.parseServiceSearchAttributeResponse(
        hex('07 00 01 00 07 00 02 35 13 02 aa bb'),
        transactionId: 1,
      );

      expect(response.attributeBytes, hex('35 13'));
      expect(response.continuation, hex('aa bb'));
    });

    test('rejects a response to another transaction', () {
      expect(
        () => Sdp.parseServiceSearchAttributeResponse(
          hex('07 00 09 00 18 00 15 $oneRecord 00'),
          transactionId: 1,
        ),
        throwsFormatException,
      );
    });

    test('reports an SDP error response with its code', () {
      expect(
        () => Sdp.parseServiceSearchAttributeResponse(
          hex('01 00 01 00 02 00 03'),
          transactionId: 1,
        ),
        throwsA(isA<SdpException>().having((e) => e.code, 'code', 3)),
      );
    });

    test('rejects a truncated response', () {
      expect(
        () => Sdp.parseServiceSearchAttributeResponse(
          hex('07 00 01 00 18 00 15 35 13'),
          transactionId: 1,
        ),
        throwsFormatException,
      );
    });
  });

  group('rfcommChannel', () {
    test('finds the channel after the RFCOMM UUID', () {
      expect(
        Sdp.rfcommChannel(
          hex('35 13 35 11 09 00 04 35 0c 35 03 19 01 00 35 05 19 00 03 08 02'),
        ),
        2,
      );
    });

    test('reads channel 1 from the Carol Pro capture (two SPP records)', () {
      // Live SDP AttributeLists from the Carol Pro, 2026-11-01; 16-bit
      // sequence lengths (0x36).
      expect(
        Sdp.rfcommChannel(
          hex(
            '36 00 2e '
            '36 00 14 09 00 04 36 00 0e 36 00 03 19 01 00 '
            '36 00 05 19 00 03 08 01 '
            '36 00 14 09 00 04 36 00 0e 36 00 03 19 01 00 '
            '36 00 05 19 00 03 08 01',
          ),
        ),
        1,
      );
    });

    test('accepts the 128-bit form of the RFCOMM UUID', () {
      expect(
        Sdp.rfcommChannel(
          hex(
            '35 21 35 1f 09 00 04 35 1a 35 03 19 01 00 '
            '35 13 1c 00 00 00 03 00 00 10 00 80 00 00 80 5f 9b 34 fb 08 05',
          ),
        ),
        5,
      );
    });

    test('skips records without RFCOMM', () {
      expect(
        Sdp.rfcommChannel(
          hex(
            '35 1a '
            '35 0a 09 00 04 35 05 35 03 19 01 00 '
            '35 0c 09 00 04 35 07 35 05 19 00 03 08 07',
          ),
        ),
        7,
      );
    });

    test('returns null when no record offers RFCOMM', () {
      expect(
        Sdp.rfcommChannel(hex('35 0c 35 0a 09 00 04 35 05 35 03 19 01 00')),
        isNull,
      );
    });

    test('rejects a data element that runs past the end', () {
      expect(
        () => Sdp.rfcommChannel(hex('35 13 35 11')),
        throwsFormatException,
      );
    });
  });
}
