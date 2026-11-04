import 'package:flutter_test/flutter_test.dart';
import 'package:kz_buds/data/spp/linux/linux_rfcomm_link.dart';

void main() {
  group('bdaddrBytes', () {
    test('stores the address least significant byte first', () {
      expect(bdaddrBytes('00:11:22:AA:bb:FF'), [
        0xff,
        0xbb,
        0xaa,
        0x22,
        0x11,
        0x00,
      ]);
    });

    test('rejects anything that is not six hex pairs', () {
      expect(() => bdaddrBytes('00:11:22:33:44'), throwsArgumentError);
      expect(() => bdaddrBytes('00:11:22:33:44:GG'), throwsArgumentError);
      expect(() => bdaddrBytes('0011:22:33:44:55'), throwsArgumentError);
    });
  });

  group('finishConnect', () {
    const eintr = 4, econnrefused = 111, einprogress = 115, etimedout = 110;

    Matcher failsWith(int errno) => throwsA(
      isA<LinuxBluetoothException>().having((e) => e.errno, 'errno', errno),
    );

    test('returns at once when connect succeeds', () {
      var awaited = 0;

      finishConnect(connectOnce: () => 0, awaitOutcome: () => awaited++);

      expect(awaited, 0);
    });

    test('after a signal it waits for the outcome and never calls '
        'connect again (Bluetooth sockets answer EBADFD)', () {
      var connects = 0;

      finishConnect(
        connectOnce: () {
          connects++;
          return eintr;
        },
        awaitOutcome: () => 0,
      );

      expect(connects, 1);
    });

    test('an in-progress connect also waits for the outcome', () {
      var awaited = 0;

      finishConnect(
        connectOnce: () => einprogress,
        awaitOutcome: () {
          awaited++;
          return 0;
        },
      );

      expect(awaited, 1);
    });

    test('reports the outcome error after a signal', () {
      expect(
        () => finishConnect(
          connectOnce: () => eintr,
          awaitOutcome: () => econnrefused,
        ),
        failsWith(econnrefused),
      );
    });

    test('reports a timeout from the wait', () {
      expect(
        () => finishConnect(
          connectOnce: () => eintr,
          awaitOutcome: () => etimedout,
        ),
        failsWith(etimedout),
      );
    });

    test('a direct failure does not wait', () {
      var awaited = 0;

      expect(
        () => finishConnect(
          connectOnce: () => econnrefused,
          awaitOutcome: () => awaited++,
        ),
        failsWith(econnrefused),
      );
      expect(awaited, 0);
    });
  });
}
