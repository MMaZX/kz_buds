import 'package:flutter_test/flutter_test.dart';
import 'package:kz_buds/data/fake/fake_earbuds_adapter.dart';
import 'package:kz_buds/domain/capabilities/capability.dart';
import 'package:kz_buds/domain/entities/anc_mode.dart';
import 'package:kz_buds/domain/entities/battery_status.dart';
import 'package:kz_buds/domain/entities/earbuds_identity.dart';
import 'package:kz_buds/domain/entities/find_target.dart';
import 'package:kz_buds/domain/entities/link_state.dart';

void main() {
  test('reports the configured capabilities', () async {
    final fake = FakeEarbudsAdapter(capabilities: {Capability.eq});
    expect(await fake.capabilities(), {Capability.eq});
    await fake.dispose();
  });

  test('battery stream emits current value then updates', () async {
    final fake = FakeEarbudsAdapter(
      initialBattery: const BatteryStatus(left: 10),
    );
    final events = <BatteryStatus>[];
    final sub = fake.watchBattery().listen(events.add);
    await pumpEventQueue();
    fake.updateBattery(const BatteryStatus(left: 20, caseLevel: 5));
    await pumpEventQueue();
    expect(events, const [
      BatteryStatus(left: 10),
      BatteryStatus(left: 20, caseLevel: 5),
    ]);
    await sub.cancel();
    await fake.dispose();
  });

  test('connection stream emits current value then updates', () async {
    final fake = FakeEarbudsAdapter(initialLinkState: LinkState.connecting);
    final events = <LinkState>[];
    final sub = fake.watchConnection().listen(events.add);
    await pumpEventQueue();
    fake.updateLinkState(LinkState.disconnected);
    await pumpEventQueue();
    expect(events, [LinkState.connecting, LinkState.disconnected]);
    await sub.cancel();
    await fake.dispose();
  });

  test('setAncMode works only with the anc capability', () async {
    final withAnc = FakeEarbudsAdapter(capabilities: {Capability.anc});
    await withAnc.setAncMode(AncMode.ambient);
    expect(withAnc.ancMode, AncMode.ambient);

    final without = FakeEarbudsAdapter(capabilities: {});
    expect(
      () => without.setAncMode(AncMode.ambient),
      throwsA(isA<UnsupportedError>()),
    );
    await withAnc.dispose();
    await without.dispose();
  });

  test('anc mode stream emits current value then each change', () async {
    final fake = FakeEarbudsAdapter(capabilities: {Capability.anc});
    final events = <AncMode>[];
    final sub = fake.watchAncMode().listen(events.add);
    await pumpEventQueue();
    await fake.setAncMode(AncMode.noiseCancelling);
    await fake.setAncMode(AncMode.ambient);
    await pumpEventQueue();
    expect(events, [AncMode.off, AncMode.noiseCancelling, AncMode.ambient]);
    await sub.cancel();
    await fake.dispose();
  });

  group('find sound', () {
    test('plays on one bud and stops', () async {
      final fake = FakeEarbudsAdapter(capabilities: {Capability.findBuds});
      expect(fake.findSoundTarget, isNull);
      await fake.playFindSound(FindTarget.right);
      expect(fake.findSoundTarget, FindTarget.right);
      await fake.stopFindSound();
      expect(fake.findSoundTarget, isNull);
      await fake.dispose();
    });

    test('requires the findBuds capability', () async {
      final fake = FakeEarbudsAdapter(capabilities: {});
      expect(
        () => fake.playFindSound(FindTarget.left),
        throwsA(isA<UnsupportedError>()),
      );
      await fake.dispose();
    });
  });

  test('reports the configured identity', () async {
    final fake = FakeEarbudsAdapter(
      identity: const EarbudsIdentity(name: 'Carol Pro'),
    );

    expect(await fake.identity(), const EarbudsIdentity(name: 'Carol Pro'));
    expect(await FakeEarbudsAdapter().identity(), isNull);
    await fake.dispose();
  });

  group('connect', () {
    test('goes from disconnected through connecting to connected', () async {
      final fake = FakeEarbudsAdapter(initialLinkState: LinkState.disconnected);
      final states = <LinkState>[];
      final sub = fake.watchConnection().listen(states.add);
      await pumpEventQueue();

      await fake.connect();
      await pumpEventQueue();

      expect(states, [
        LinkState.disconnected,
        LinkState.connecting,
        LinkState.connected,
      ]);
      expect(fake.connectCalls, 1);
      await sub.cancel();
      await fake.dispose();
    });

    test('does nothing while already connected', () async {
      final fake = FakeEarbudsAdapter();

      await fake.connect();

      expect(fake.connectCalls, 1);
      expect(await fake.watchConnection().first, LinkState.connected);
      await fake.dispose();
    });
  });
}
