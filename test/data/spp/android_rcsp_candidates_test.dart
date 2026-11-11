import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_buds/data/rcsp/reconnect_supervisor.dart';
import 'package:kz_buds/data/spp/android/android_rcsp_candidates.dart';
import 'package:kz_buds/domain/entities/detected_earbuds.dart';
import 'package:kz_buds/domain/entities/link_state.dart';

void main() {
  const carol = '00:11:22:33:44:55';
  const speaker = 'AA:AA:AA:AA:AA:AA';

  test('is not worth trying until the OS reports a connected device', () {
    final candidates = AndroidRcspCandidates();

    expect(candidates.worthTrying, isFalse);

    candidates.update({carol});

    expect(candidates.worthTrying, isTrue);
  });

  test('is not worth trying while the OS cannot tell', () {
    final candidates = AndroidRcspCandidates()..update({carol});

    candidates.update(null);

    expect(candidates.worthTrying, isFalse);
  });

  test('gives up on a device after the failure limit', () {
    final candidates = AndroidRcspCandidates(maxFailures: 2)..update({speaker});

    candidates.failed(speaker);
    expect(candidates.worthTrying, isTrue);

    candidates.failed(speaker);
    expect(candidates.worthTrying, isFalse);
  });

  test('tries a given-up device again after it reconnects', () {
    final candidates = AndroidRcspCandidates(maxFailures: 1)
      ..update({speaker})
      ..failed(speaker);

    candidates.update(const {});
    candidates.update({speaker});

    expect(candidates.worthTrying, isTrue);
  });

  test('never gives up on a device that completed the handshake', () {
    final candidates = AndroidRcspCandidates(maxFailures: 1)
      ..update({carol})
      ..proven(carol);

    candidates.failed(carol);

    expect(candidates.worthTrying, isTrue);
  });

  test('matches addresses in any letter case', () {
    final candidates = AndroidRcspCandidates(maxFailures: 1)
      ..update({speaker.toLowerCase()});

    candidates.failed(speaker);

    expect(candidates.worthTrying, isFalse);
  });

  test('emits the current value on listen, then each change', () async {
    final candidates = AndroidRcspCandidates(maxFailures: 1);
    final seen = <bool>[];
    final subscription = candidates.worthTryingChanges.listen(seen.add);

    candidates.update({speaker});
    candidates.update({speaker});
    candidates.failed(speaker);
    await pumpEventQueue();

    expect(seen, [false, true, false]);
    await subscription.cancel();
  });

  test('orders proven devices first and given-up devices last', () {
    const a = DetectedEarbuds(id: speaker, name: 'Speaker');
    const b = DetectedEarbuds(id: 'BB:BB:BB:BB:BB:BB', name: 'New');
    const c = DetectedEarbuds(id: carol, name: 'Carol Pro');
    final candidates = AndroidRcspCandidates(maxFailures: 1)
      ..update({a.id, b.id, c.id})
      ..failed(a.id)
      ..proven(c.id);

    expect(candidates.prioritize([a, b, c]), [c, b, a]);
  });

  test('the supervisor stops retrying a device that never answers', () {
    fakeAsync((async) {
      final candidates = AndroidRcspCandidates();
      final session = StreamController<LinkState>();
      var attempts = 0;
      final supervisor = ReconnectSupervisor(
        osLink: candidates.worthTryingChanges,
        session: session.stream,
        connect: () async {
          attempts++;
          candidates.failed(speaker);
          throw StateError('no SPP service');
        },
      )..start();
      session.add(LinkState.disconnected);
      async.flushMicrotasks();

      candidates.update({speaker});
      async.elapse(const Duration(minutes: 5));

      expect(attempts, candidates.maxFailures);

      candidates.update(const {});
      candidates.update({speaker});
      async.elapse(const Duration(minutes: 5));

      expect(attempts, candidates.maxFailures * 2);
      unawaited(supervisor.stop());
      unawaited(session.close());
    });
  });
}
