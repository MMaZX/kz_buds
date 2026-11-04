import 'package:flutter_test/flutter_test.dart';
import 'package:kz_buds/data/spp/jieli_detection.dart';

void main() {
  const spp = '00001101-0000-1000-8000-00805f9b34fb';
  const a2dp = '0000110b-0000-1000-8000-00805f9b34fb';

  group('bluetoothVendorId', () {
    test('reads the vendor of a Bluetooth SIG modalias', () {
      expect(bluetoothVendorId('bluetooth:v05D6p000Ad0240'), 0x05d6);
    });

    test('ignores a USB-IF modalias, whose ids are another namespace', () {
      expect(bluetoothVendorId('usb:v05D6p000Ad0240'), isNull);
    });

    test('returns null for an empty or malformed modalias', () {
      expect(bluetoothVendorId(''), isNull);
      expect(bluetoothVendorId('bluetooth:vXYZ'), isNull);
    });
  });

  group('isJieliRcspCandidate', () {
    test('accepts a JieLi device that offers SPP', () {
      expect(
        isJieliRcspCandidate(
          modalias: 'bluetooth:v05D6p000Ad0240',
          uuids: [a2dp, spp],
        ),
        isTrue,
      );
    });

    test('matches the SPP UUID in any case', () {
      expect(
        isJieliRcspCandidate(
          modalias: 'bluetooth:v05D6p000Ad0240',
          uuids: [spp.toUpperCase()],
        ),
        isTrue,
      );
    });

    test('rejects a JieLi device without SPP', () {
      expect(
        isJieliRcspCandidate(
          modalias: 'bluetooth:v05D6p000Ad0240',
          uuids: [a2dp],
        ),
        isFalse,
      );
    });

    test('rejects another vendor that offers SPP', () {
      expect(
        isJieliRcspCandidate(
          modalias: 'bluetooth:v004Cp0001d0001',
          uuids: [spp],
        ),
        isFalse,
      );
    });
  });
}
