import 'package:flutter_test/flutter_test.dart';
import 'package:kz_buds/data/protocol/rcsp_commands.dart';
import 'package:kz_buds/data/rcsp/rcsp_diagnostics.dart';
import 'package:kz_buds/data/spp/rcsp_spp_session.dart';

import '../../protocol/hex.dart';
import '../../support/fake_rcsp_earbuds.dart';

void main() {
  late FakeRcspEarbuds earbuds;
  late RcspSppSession session;
  final logs = <String>[];

  setUp(() async {
    logs.clear();
    earbuds = FakeRcspEarbuds();
    session = await RcspSppSession.open(
      () async => earbuds,
      timeout: const Duration(milliseconds: 200),
    );
  });

  tearDown(() => session.close());

  test('info logs the support flags, battery and EQ', () async {
    await rcspInfo(session.protocol, logs.add);

    expect(logs, [
      'support RcspSupport(search: true, gameMode: false, anc: true, '
          'adaptiveAnc: false, eqBanned: false, doubleConnection: false)',
      'sys battery 80, volume null',
      'eq RcspEq(mode: 0, gains: [0, -3, -3, 4, -6, 1, 2, 2, 2, 2])',
      'adv battery RcspBattery(L: RcspLevel(60%), R: RcspLevel(70%), '
          'case: null)',
    ]);
  });

  test('find rings the chosen side with the player byte, then stops', () async {
    await rcspFind(
      session.protocol,
      logs.add,
      side: 2,
      player: 1,
      ring: Duration.zero,
    );

    final finds = earbuds.requests
        .where((r) => r.opcode == RcspOpcode.searchDevice)
        .map((r) => r.payload)
        .toList();
    expect(finds, [hex('01 01 00 0a 02 01'), hex('01 00 00 00 00 00')]);
    expect(
      logs.first,
      'find start: side 2, player 1, '
      'payload 01 01 00 0a 02 01',
    );
    expect(logs.last, startsWith('find stop answered: status 0'));
  });

  test('snapshot keys every readable sys and ADV item by source', () async {
    final snapshot = await rcspSnapshot(session.protocol, logs.add);

    expect(snapshot['sys ff attr 00'], '50');
    expect(snapshot['sys ff attr 0d'], '01 00 0a 00 0a 00 05 00 05');
    expect(snapshot['adv type 00'], '3c 46 00');
    expect(snapshot.keys.where((k) => k.startsWith('sys 00 ')), isNotEmpty);
  });

  test('diff lists changed, added and removed items, sorted', () {
    final lines = rcspDiff(
      {'adv type 05': '00', 'sys ff attr 0d': '01', 'sys ff attr 01': '08'},
      {'adv type 05': '01', 'sys ff attr 0d': '01', 'sys ff attr 02': 'aa'},
    );

    expect(lines, [
      'adv type 05: 00 -> 01',
      'sys ff attr 01: 08 -> (gone)',
      'sys ff attr 02: (new) -> aa',
    ]);
  });

  test('diff of equal snapshots is empty', () {
    expect(rcspDiff({'a': '01'}, {'a': '01'}), isEmpty);
  });
}
