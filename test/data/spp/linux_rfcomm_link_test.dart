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
}
