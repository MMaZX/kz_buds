import 'dart:async';

import 'package:bluetooth_rfcomm/bluetooth_rfcomm.dart';
import 'package:bluetooth_rfcomm/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_buds/data/protocol/rcsp_auth.dart';
import 'package:kz_buds/data/protocol/rcsp_commands.dart';
import 'package:kz_buds/data/protocol/rcsp_frame.dart';
import 'package:kz_buds/data/protocol/rcsp_protocol.dart';
import 'package:kz_buds/data/spp/rcsp_spp_session.dart';
import 'package:kz_buds/data/spp/rfcomm_package_link.dart';

/// Plays the earbuds on a fake RFCOMM link: answers the handshake with
/// [deviceAuth] and every RCSP request with a battery TLV.
void playEarbuds(FakeBluetoothRfcommPlatform platform, {RcspAuth? deviceAuth}) {
  final auth = deviceAuth ?? RcspAuth();
  final ownChallenge = auth.randomChallenge();
  var handled = 0;
  Timer.periodic(const Duration(milliseconds: 2), (timer) {
    if (platform.transports.isEmpty) return;
    final link = platform.transports.single;
    if (link.state == ConnectionState.disconnected) {
      timer.cancel();
      return;
    }
    while (handled < link.sent.length) {
      final bytes = link.sent[handled++];
      if (bytes.length == 17 && bytes[0] == RcspAuth.challengeFlag) {
        link.deliver(auth.answer(bytes));
      } else if (RcspAuth.isPass(bytes)) {
        link.deliver(ownChallenge);
      } else if (bytes.length == 17 && bytes[0] == RcspAuth.answerFlag) {
        if (auth.verify(ownChallenge, bytes)) {
          link.deliver(RcspAuth.passMessage);
        }
      } else {
        final request = RcspFrame.decode(bytes);
        link.deliver(
          RcspFrame.response(
            opcode: request.opcode,
            status: 0,
            sn: request.sn,
            payload: const [0xff, 0x02, 0x00, 0x50],
          ).encode(),
        );
      }
    }
  });
}

void main() {
  const address = '00:11:22:33:44:55';
  const timeout = Duration(milliseconds: 300);
  late FakeBluetoothRfcommPlatform platform;
  late BluetoothRfcomm bluetooth;

  setUp(() {
    platform = FakeBluetoothRfcommPlatform();
    bluetooth = BluetoothRfcomm(platform: platform);
  });

  test('opens SPP, authenticates and answers a battery request', () async {
    playEarbuds(platform);

    final session = await RcspSppSession.open(
      () => RfcommPackageLink.connect(bluetooth, address),
      timeout: timeout,
    );
    addTearDown(session.close);

    final response = await session.protocol.send(
      RcspCommands.getSysInfo(
        function: RcspSysFunction.public,
        mask: RcspSysAttr.maskOf([RcspSysAttr.battery]),
      ),
    );

    expect(platform.transports.single.device, DeviceId.address(address));
    expect(RcspSysInfo.parse(response.payload).battery, 80);
  });

  test('closes the link when the earbuds fail auth', () async {
    playEarbuds(platform, deviceAuth: RcspAuth(linkKey: List.filled(16, 0)));

    await expectLater(
      RcspSppSession.open(
        () => RfcommPackageLink.connect(bluetooth, address),
        timeout: timeout,
      ),
      throwsA(isA<RcspAuthException>()),
    );

    expect(platform.transports.single.state, ConnectionState.disconnected);
  });

  test('close disconnects the link', () async {
    playEarbuds(platform);
    final session = await RcspSppSession.open(
      () => RfcommPackageLink.connect(bluetooth, address),
      timeout: timeout,
    );

    await session.close();

    expect(platform.transports.single.state, ConnectionState.disconnected);
  });

  test('a connect failure surfaces unchanged', () async {
    platform.connectError = const BluetoothConnectionException('no route');

    await expectLater(
      RcspSppSession.open(
        () => RfcommPackageLink.connect(bluetooth, address),
        timeout: timeout,
      ),
      throwsA(isA<BluetoothConnectionException>()),
    );
  });
}
