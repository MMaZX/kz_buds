import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_buds/data/protocol/rcsp_auth.dart';
import 'package:kz_buds/data/protocol/rcsp_commands.dart';
import 'package:kz_buds/data/protocol/rcsp_protocol.dart';
import 'package:kz_buds/data/rcsp/rcsp_earbuds_adapter.dart';
import 'package:kz_buds/data/spp/rcsp_spp_session.dart';
import 'package:kz_buds/domain/capabilities/capability.dart';
import 'package:kz_buds/domain/entities/anc_mode.dart';
import 'package:kz_buds/domain/entities/battery_status.dart';
import 'package:kz_buds/domain/entities/earbuds_identity.dart';
import 'package:kz_buds/domain/entities/eq_settings.dart';
import 'package:kz_buds/domain/entities/find_target.dart';
import 'package:kz_buds/domain/entities/link_state.dart';

import '../../protocol/hex.dart';
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

  /// Collects what [DebugLog] prints during one test.
  List<String> capturePrints() {
    final printed = <String>[];
    final original = debugPrint;
    debugPrint = (message, {wrapWidth}) => printed.add(message ?? '');
    addTearDown(() => debugPrint = original);
    return printed;
  }

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

  group('identity', () {
    test('comes from the target info name and outlives a drop', () async {
      await adapter.connect();
      await earbuds.drop();
      await pumpEventQueue();

      expect(
        await adapter.identity(),
        const EarbudsIdentity(name: 'CAROL PRO'),
      );
    });

    test('falls back to the name the OS knows', () async {
      earbuds = FakeRcspEarbuds(deviceName: '');
      adapter = RcspEarbudsAdapter(
        () => RcspSppSession.open(
          () async => earbuds,
          timeout: timeout,
          osName: 'Carol Pro',
        ),
      );

      await adapter.connect();

      expect(
        await adapter.identity(),
        const EarbudsIdentity(name: 'Carol Pro'),
      );
    });

    test('is unknown before the first connection', () async {
      expect(await adapter.identity(), isNull);
    });
  });

  group('capabilities', () {
    test('find buds and ANC come from the device flags', () async {
      await adapter.connect();

      expect(await adapter.capabilities(), {
        Capability.findBuds,
        Capability.anc,
        Capability.eq,
      });
    });

    test('no ANC when the device has no noise table', () async {
      earbuds = FakeRcspEarbuds(noiseTable: const []);
      adapter = build();
      await adapter.connect();

      expect(await adapter.capabilities(), isNot(contains(Capability.anc)));
      expect(() => adapter.setAncMode(AncMode.ambient), throwsUnsupportedError);
    });

    test('no find buds when the device does not report it', () async {
      earbuds = FakeRcspEarbuds(supportFlags: const [0x00]);
      adapter = build();
      await adapter.connect();

      expect(
        await adapter.capabilities(),
        isNot(contains(Capability.findBuds)),
      );
      expect(
        () => adapter.playFindSound(FindTarget.left),
        throwsUnsupportedError,
      );
    });

    test('empty while disconnected', () async {
      expect(await adapter.capabilities(), isEmpty);
    });
  });

  group('ANC', () {
    test('starts from the live noise mode', () async {
      earbuds = FakeRcspEarbuds(liveNoiseMode: 2);
      adapter = build();
      await adapter.connect();

      expect(await adapter.watchAncMode().first, AncMode.ambient);
    });

    test('sends the device table entry for each mode and reports it', () async {
      await adapter.connect();
      final modes = <AncMode>[];
      final sub = adapter.watchAncMode().listen(modes.add);

      await adapter.setAncMode(AncMode.ambient);
      await adapter.setAncMode(AncMode.off);
      await adapter.setAncMode(AncMode.noiseCancelling);
      await pumpEventQueue();

      final sets = earbuds.requests
          .where((r) => r.opcode == RcspOpcode.setSysInfo)
          .map((r) => r.payload);
      expect(sets, [
        hex('ff 0a 0d 02 00 08 00 08 00 04 00 04'),
        hex('ff 0a 0d 00 00 00 00 00 00 00 00 00'),
        hex('ff 0a 0d 01 00 0a 00 0a 00 05 00 05'),
      ]);
      expect(modes, [
        AncMode.noiseCancelling,
        AncMode.ambient,
        AncMode.off,
        AncMode.noiseCancelling,
      ]);
      await sub.cancel();
    });

    test('a mode missing from the device table is unsupported', () async {
      earbuds = FakeRcspEarbuds(
        noiseTable: [FakeRcspEarbuds.defaultNoiseTable[0]],
      );
      adapter = build();
      await adapter.connect();

      expect(() => adapter.setAncMode(AncMode.ambient), throwsUnsupportedError);
    });

    test('a rejected set keeps the previous mode and logs it', () async {
      final logs = capturePrints();
      earbuds = FakeRcspEarbuds(setSysInfoStatus: 1);
      adapter = build();
      await adapter.connect();

      await expectLater(
        adapter.setAncMode(AncMode.ambient),
        throwsA(isA<RcspCommandException>()),
      );

      expect(await adapter.watchAncMode().first, AncMode.noiseCancelling);
      expect(logs.where((l) => l.contains('ambient')), isNotEmpty);
    });
  });

  test('logs every unsolicited device frame with opcode and payload', () async {
    final logs = capturePrints();
    adapter = build();
    await adapter.connect();

    earbuds.push(RcspOpcode.sysInfoAutoUpdate, [0xff, 0x0a, 0x0d, 0x02]);
    await pumpEventQueue();

    expect(logs, contains('[device] push op 09: ff 0a 0d 02'));
  });

  group('EQ', () {
    const carolStart = <double>[0, -3, -3, 4, -6, 1, 2, 2, 2, 2];

    test('comes from the device flags and its preset table', () async {
      await adapter.connect();

      expect(await adapter.capabilities(), contains(Capability.eq));
      expect(
        await adapter.watchEq().first,
        const EqSettings(mode: 0, gains: carolStart),
      );
    });

    test('no EQ when the device bans it or has no presets', () async {
      for (final fake in [
        FakeRcspEarbuds(supportFlags: const [0x54, 0x00]),
        FakeRcspEarbuds(eqPresets: const []),
      ]) {
        earbuds = fake;
        adapter = build();
        await adapter.connect();

        expect(await adapter.capabilities(), isNot(contains(Capability.eq)));
        expect(await adapter.eqProfile(), isNull);
        expect(
          () => adapter.setEq(const EqSettings(mode: 6, gains: [])),
          throwsUnsupportedError,
        );
        await adapter.dispose();
      }
    });

    test('the profile keeps the presets and falls back to standard bands '
        'when the device ones are out of order', () async {
      await adapter.connect();
      final profile = (await adapter.eqProfile())!;

      expect(profile.frequencies, RcspEarbudsAdapter.standardBands);
      expect(profile.customMode, 6);
      expect(profile.presets.map((p) => p.mode), [0, 1, 2, 3, 4, 5, 6]);
      expect(profile.presets.first.gains, carolStart);
      expect(profile.minGain, lessThan(0));
      expect(profile.maxGain, greaterThan(0));
    });

    test('the profile uses the device bands when they ascend', () async {
      final presets = List.of(FakeRcspEarbuds.carolEqPresets);
      const ascending = [31, 62, 125, 250, 500, 1000, 2000, 4000, 8000, 16000];
      for (var i = 0; i < 10; i++) {
        presets[1 + i * 2] = ascending[i] >> 8;
        presets[2 + i * 2] = ascending[i] & 0xff;
      }
      earbuds = FakeRcspEarbuds(eqPresets: presets);
      adapter = build();
      await adapter.connect();

      expect((await adapter.eqProfile())!.frequencies, ascending);
    });

    test('setEq sends attr 4 and reports the new settings', () async {
      await adapter.connect();
      final next = adapter.watchEq().skip(1).first;
      const custom = EqSettings(
        mode: 6,
        gains: [1, -2, 0, 0, 0, 0, 0, 0, 0, 3],
      );

      await adapter.setEq(custom);

      final sets = earbuds.requests
          .where((r) => r.opcode == RcspOpcode.setSysInfo)
          .map((r) => r.payload);
      expect(sets, [hex('ff 0c 04 06 01 fe 00 00 00 00 00 00 00 03')]);
      expect(await next, custom);
    });

    test('a rejected set keeps the previous settings', () async {
      earbuds = FakeRcspEarbuds(setSysInfoStatus: 1);
      adapter = build();
      await adapter.connect();

      await expectLater(
        adapter.setEq(EqSettings(mode: 6, gains: List.filled(10, 1))),
        throwsA(isA<RcspCommandException>()),
      );

      expect(
        await adapter.watchEq().first,
        const EqSettings(mode: 0, gains: carolStart),
      );
    });
  });

  group('find sound', () {
    test('maps both, left and right to way 0, 1 and 2 with player 1', () async {
      await adapter.connect();

      for (final target in FindTarget.values) {
        await adapter.playFindSound(target);
      }
      await adapter.stopFindSound();

      final finds = earbuds.requests
          .where((r) => r.opcode == RcspOpcode.searchDevice)
          .map((r) => r.payload)
          .toList();
      // player 1: the earbud plays the sound (player 0 is silent, L30).
      expect(finds, [
        hex('01 01 00 3c 00 01'),
        hex('01 01 00 3c 01 01'),
        hex('01 01 00 3c 02 01'),
        hex('01 00 00 00 00 00'),
      ]);
    });

    test('stop is a no-op while disconnected', () async {
      await adapter.stopFindSound();
    });
  });
}
