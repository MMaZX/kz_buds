import 'package:flutter_test/flutter_test.dart';
import 'package:kz_buds/data/protocol/rcsp_commands.dart';
import 'package:kz_buds/data/protocol/rcsp_frame.dart';

import 'hex.dart';

void main() {
  group('builders', () {
    test('GET_TARGET_INFO frames as the captured request', () {
      final frame = RcspCommands.getTargetInfo().toFrame(sn: 1);

      expect(frame.encode(), hex('fe dc ba c0 03 00 06 01 ff ff ff ff 00 ef'));
    });

    test('GET_SYS_INFO battery frames as the captured request', () {
      final frame = RcspCommands.getSysInfo(
        function: RcspSysFunction.public,
        mask: RcspSysAttr.maskOf([RcspSysAttr.battery]),
      ).toFrame(sn: 2);

      expect(frame.encode(), hex('fe dc ba c0 07 00 06 02 ff 00 00 00 01 ef'));
    });

    test('the connect-time public mask covers battery, volume, EQ, noise', () {
      expect(
        RcspSysAttr.maskOf([
          RcspSysAttr.battery,
          RcspSysAttr.volume,
          RcspSysAttr.eq,
          RcspSysAttr.noiseLive,
        ]),
        0x00002013,
      );
    });

    test('SET_SYS_INFO volume is func ff plus one TLV', () {
      final cmd = RcspCommands.setVolume(6);

      expect(cmd.opcode, RcspOpcode.setSysInfo);
      expect(cmd.payload, hex('ff 02 01 06'));
    });

    test('SET_SYS_INFO EQ carries the mode and ten signed gains', () {
      final cmd = RcspCommands.setEq(
        RcspEq(
          mode: RcspEq.customMode,
          gains: [0, -3, -3, 4, -6, 1, 2, 2, 2, 2],
        ),
      );

      expect(cmd.payload, hex('ff 0c 04 06 00 fd fd 04 fa 01 02 02 02 02'));
    });

    test('SET_SYS_INFO noise is func ff plus the 9-byte attr 13 entry', () {
      final cmd = RcspCommands.setNoise(
        const RcspNoise(
          mode: 2,
          leftMax: 0x0102,
          rightMax: 0x0304,
          leftCurrent: 0x0506,
          rightCurrent: 0x0708,
        ),
      );

      expect(cmd.opcode, RcspOpcode.setSysInfo);
      expect(cmd.payload, hex('ff 0a 0d 02 01 02 03 04 05 06 07 08'));
    });

    test('ADV_GET_INFO carries the mask as u32 BE', () {
      final cmd = RcspCommands.advGetInfo();

      expect(cmd.opcode, RcspOpcode.advGetInfo);
      expect(cmd.payload, hex('ff ff ff ff'));
    });

    test('ADV_SETTINGS carries one LTV', () {
      final cmd = RcspCommands.advSettings(RcspAdvType.workMode, [1]);

      expect(cmd.opcode, RcspOpcode.advSettings);
      expect(cmd.payload, hex('02 05 01'));
    });

    test('SEARCH_DEVICE start rings both buds for the timeout', () {
      final cmd = RcspCommands.searchDevice(start: true, timeoutSeconds: 60);

      expect(cmd.opcode, RcspOpcode.searchDevice);
      expect(cmd.payload, hex('01 01 00 3c 00 00'));
    });

    test('SEARCH_DEVICE stop uses op 0', () {
      final cmd = RcspCommands.searchDevice(start: false);

      expect(cmd.payload, hex('01 00 00 00 00 00'));
    });

    test('rejects a volume that does not fit in a byte', () {
      expect(() => RcspCommands.setVolume(256), throwsArgumentError);
    });

    test('rejects an EQ without ten gains', () {
      expect(
        () => RcspCommands.setEq(RcspEq(mode: 6, gains: const [0, 1])),
        throwsArgumentError,
      );
    });
  });

  group('parsers', () {
    test('target info reads the support flags from TLV 19', () {
      // 0x44: bit 2 search device, bit 6 ANC; 0x81: bit 0 hearing assist,
      // bit 7 double connection. TLV 0 (protocol version) is skipped.
      final info = RcspTargetInfo.parse(hex('02 00 21 03 13 44 81'));

      expect(info.support, isNotNull);
      expect(info.support!.searchDevice, isTrue);
      expect(info.support!.anc, isTrue);
      expect(info.support!.gameMode, isFalse);
      expect(info.support!.eqBanned, isFalse);
      expect(info.support!.doubleConnection, isTrue);
    });

    test('target info with a one-byte TLV 19 leaves the second byte clear', () {
      final info = RcspTargetInfo.parse(hex('02 13 12'));

      expect(info.support!.gameMode, isTrue);
      expect(info.support!.eqBanned, isTrue);
      expect(info.support!.doubleConnection, isFalse);
    });

    test('target info reads the device name (TLV 16)', () {
      final info = RcspTargetInfo.parse(
        hex('0a 10 43 41 52 4f 4c 20 50 52 4f'),
      );

      expect(info.name, 'CAROL PRO');
    });

    test('target info reads vid, pid and uid (TLV 10)', () {
      final info = RcspTargetInfo.parse(hex('07 0a 05 d6 00 0a 00 03'));

      expect(info.vendorId, 0x05d6);
      expect(info.productId, 0x000a);
      expect(info.uid, 3);
    });

    test('a two-byte TLV 10 is a uid under the JieLi vendor', () {
      final info = RcspTargetInfo.parse(hex('03 0a 00 07'));

      expect(info.vendorId, 0x05d6);
      expect(info.productId, isNull);
      expect(info.uid, 7);
    });

    test('target info without name or ids reports them as unknown', () {
      final info = RcspTargetInfo.parse(hex('02 00 21'));

      expect(info.name, isNull);
      expect(info.vendorId, isNull);
    });

    test('target info without TLV 19 reports unknown support', () {
      expect(RcspTargetInfo.parse(hex('02 00 21')).support, isNull);
    });

    test('sys info splits the function and its attributes', () {
      final info = RcspSysInfo.parse(
        hex('ff 02 00 50 02 01 09 0c 04 00 00 fd fd 04 fa 01 02 02 02 02'),
      );

      expect(info.function, RcspSysFunction.public);
      expect(info.battery, 80);
      expect(info.volume, 9);
      expect(
        info.eq,
        RcspEq(mode: 0, gains: [0, -3, -3, 4, -6, 1, 2, 2, 2, 2]),
      );
    });

    test('missing attributes are null', () {
      final info = RcspSysInfo.parse(hex('ff 02 00 50'));

      expect(info.volume, isNull);
      expect(info.eq, isNull);
      expect(info.noise, isNull);
    });

    test('live noise reads the mode and four u16 BE values', () {
      final info = RcspSysInfo.parse(
        hex('ff 0a 0d 01 40 00 00 60 ff 00 00 60'),
      );

      expect(
        info.noise,
        const RcspNoise(
          mode: 1,
          leftMax: 0x4000,
          rightMax: 0x0060,
          leftCurrent: 0xff00,
          rightCurrent: 0x0060,
        ),
      );
    });

    test('noise table reads the count and one 9-byte entry per mode', () {
      final info = RcspSysInfo.parse(
        hex(
          'ff 14 0e 02 '
          '00 00 00 00 00 00 00 00 00 '
          '01 00 0a 00 0b 00 03 00 04',
        ),
      );

      expect(info.noiseTable, const [
        RcspNoise(
          mode: 0,
          leftMax: 0,
          rightMax: 0,
          leftCurrent: 0,
          rightCurrent: 0,
        ),
        RcspNoise(
          mode: 1,
          leftMax: 10,
          rightMax: 11,
          leftCurrent: 3,
          rightCurrent: 4,
        ),
      ]);
    });

    test('a noise table shorter than its count is rejected', () {
      final info = RcspSysInfo.parse(hex('ff 05 0e 02 00 00 00'));

      expect(() => info.noiseTable, throwsFormatException);
    });

    test('ADV battery maps 0 to null and reads the charging bit', () {
      final info = RcspAdvInfo.parse(hex('04 00 5a d0 00 02 08 02'));

      expect(info.battery.left, const RcspLevel(percent: 90, charging: false));
      expect(info.battery.right, const RcspLevel(percent: 80, charging: true));
      expect(info.battery.chargingCase, isNull);
      expect(info.values[RcspAdvType.inEar], hex('02'));
    });

    test('ADV info without a battery item reports nothing', () {
      final info = RcspAdvInfo.parse(hex('02 05 01'));

      expect(info.battery, const RcspBattery());
    });

    test('the C2 status block carries left, right and case', () {
      final status = RcspDeviceStatus.parse(
        hex('05 d6 00 00 00 00 22 aa bb cc dd ee ff 02 46 00 00 e0'),
      );

      expect(status.vendorId, 0x05d6);
      expect(status.action, 2);
      expect(
        status.battery.left,
        const RcspLevel(percent: 70, charging: false),
      );
      expect(status.battery.right, isNull);
      expect(status.battery.chargingCase, isNull);
      expect(status.sequence, 0xe0);
    });

    test('a short C2 block is rejected', () {
      expect(
        () => RcspDeviceStatus.parse(hex('05 d6 00')),
        throwsFormatException,
      );
    });
  });

  test('a command frame round-trips through the codec', () {
    final frame = RcspCommands.setVolume(3).toFrame(sn: 9);

    expect(RcspFrame.decode(frame.encode()), frame);
  });
}
