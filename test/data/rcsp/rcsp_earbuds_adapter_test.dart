import 'package:flutter_test/flutter_test.dart';
import 'package:kz_buds/data/protocol/rcsp_auth.dart';
import 'package:kz_buds/data/protocol/rcsp_commands.dart';
import 'package:kz_buds/data/protocol/rcsp_protocol.dart';
import 'package:kz_buds/data/rcsp/rcsp_earbuds_adapter.dart';
import 'package:kz_buds/data/spp/rcsp_spp_session.dart';
import 'package:kz_buds/domain/entities/anc_mode.dart';
import 'package:kz_buds/domain/entities/battery_status.dart';
import 'package:kz_buds/domain/entities/bud.dart';
import 'package:kz_buds/domain/entities/link_state.dart';

import '../../support/fake_rcsp_earbuds.dart';

void main() {
  const timeout = Duration(milliseconds: 200);
  late FakeRcspEarbuds earbuds;
  late RcspEarbudsAdapter adapter;

  RcspEarbudsAdapter build({Duration poll = const Duration(minutes: 1)}) =>
      RcspEarbudsAdapter(
        () => RcspSppSession.open(() async => earbuds, timeout: timeout),
        batteryPoll: poll,
      );

  setUp(() {
    earbuds = FakeRcspEarbuds();
    adapter = build();
  });

  tearDown(() => adapter.dispose());

  test('connect goes through connecting to connected', () async {
    final states = <LinkState>[];
    final sub = adapter.watchConnection().listen(states.add);

    await adapter.connect();
    await pumpEventQueue();

    expect(states, [
      LinkState.disconnected,
      LinkState.connecting,
      LinkState.connected,
    ]);
    await sub.cancel();
  });

  test('reads left and right from ADV info; the case stays null', () async {
    await adapter.connect();

    expect(
      await adapter.watchBattery().first,
      const BatteryStatus(left: 60, right: 70),
    );
  });

  test('an unsolicited C2 block updates the battery', () async {
    await adapter.connect();
    final next = adapter.watchBattery().skip(1).first;

    earbuds.pushStatus([0x32, 0x00, 0x00]);

    expect(await next, const BatteryStatus(left: 50));
  });

  test('polls the battery while connected', () async {
    adapter = build(poll: const Duration(milliseconds: 20));
    await adapter.connect();

    await Future<void>.delayed(const Duration(milliseconds: 70));

    final advReads = earbuds.requests.where(
      (r) => r.opcode == RcspOpcode.advGetInfo,
    );
    expect(advReads.length, greaterThan(1));
  });

  test('a failed handshake ends disconnected with the link closed', () async {
    earbuds = FakeRcspEarbuds(
      deviceAuth: RcspAuth(linkKey: List.filled(16, 0)),
    );
    adapter = build();

    await expectLater(adapter.connect(), throwsA(isA<RcspAuthException>()));

    expect(await adapter.watchConnection().first, LinkState.disconnected);
    expect(earbuds.closed, isTrue);
  });

  test('a dropped link turns the state to disconnected', () async {
    await adapter.connect();
    final next = adapter.watchConnection().skip(1).first;

    await earbuds.drop();

    expect(await next, LinkState.disconnected);
  });

  test('connect after a drop opens a new session', () async {
    await adapter.connect();
    await earbuds.drop();
    await pumpEventQueue();
    earbuds = FakeRcspEarbuds(advBattery: [0x28, 0x2d, 0x00]);

    await adapter.connect();

    expect(await adapter.watchConnection().first, LinkState.connected);
    expect(
      await adapter.watchBattery().first,
      const BatteryStatus(left: 40, right: 45),
    );
  });

  test('reports no capability until one is proven live', () async {
    await adapter.connect();

    expect(await adapter.capabilities(), isEmpty);
    expect(() => adapter.setAncMode(AncMode.ambient), throwsUnsupportedError);
    expect(() => adapter.playFindSound(Bud.left), throwsUnsupportedError);
  });
}
