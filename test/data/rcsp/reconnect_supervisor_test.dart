import 'dart:async';
import 'dart:math';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_buds/data/rcsp/reconnect_supervisor.dart';
import 'package:kz_buds/domain/entities/link_state.dart';

/// [nextDouble] always returns [value], so the jitter is predictable.
class FixedRandom implements Random {
  FixedRandom(this.value);

  final double value;

  @override
  double nextDouble() => value;

  @override
  int nextInt(int max) => (value * max).floor();

  @override
  bool nextBool() => value >= 0.5;
}

class Harness {
  Harness({double random = 0.5, this.connectResult = _fail}) {
    supervisor = ReconnectSupervisor(
      osLink: os.stream,
      session: session.stream,
      connect: () {
        calls++;
        return connectResult(this);
      },
      random: FixedRandom(random),
      log: logs.add,
    )..start();
    addTearDown(close);
  }

  void close() {
    unawaited(os.close());
    unawaited(session.close());
  }

  final os = StreamController<bool>();
  final session = StreamController<LinkState>();
  Future<void> Function(Harness) connectResult;
  late final ReconnectSupervisor supervisor;
  int calls = 0;
  final logs = <String>[];

  static Future<void> _fail(Harness _) async => throw StateError('no reply');
}

void main() {
  test('connects at once when the OS connects the earbuds', () {
    fakeAsync((async) {
      final h = Harness()..session.add(LinkState.disconnected);

      h.os.add(true);
      async.flushMicrotasks();

      expect(h.calls, 1);
    });
  });

  test('retries 5-10 s apart while the OS has them and the session is '
      'down', () {
    fakeAsync((async) {
      // 0.5 puts the delay in the middle of the window: 7.5 s.
      final h = Harness()
        ..session.add(LinkState.disconnected)
        ..os.add(true);
      async.flushMicrotasks();
      expect(h.calls, 1);

      async.elapse(const Duration(milliseconds: 7400));
      expect(h.calls, 1);
      async.elapse(const Duration(milliseconds: 200));
      expect(h.calls, 2);
    });
  });

  test('the delay never goes below 5 s or reaches 10 s', () {
    fakeAsync((async) {
      final low = Harness(random: 0)
        ..session.add(LinkState.disconnected)
        ..os.add(true);
      final high = Harness(random: 0.999)
        ..session.add(LinkState.disconnected)
        ..os.add(true);
      async.flushMicrotasks();

      async.elapse(const Duration(milliseconds: 4990));
      expect(low.calls, 1);
      async.elapse(const Duration(milliseconds: 20));
      expect(low.calls, 2);

      // 0.999 gives 9.995 s: still waiting at 9.99 s, fired by 10 s.
      async.elapse(const Duration(milliseconds: 4980));
      expect(high.calls, 1);
      async.elapse(const Duration(milliseconds: 10));
      expect(high.calls, 2);
    });
  });

  test('never forces a connect while the OS does not have the earbuds', () {
    fakeAsync((async) {
      final h = Harness()
        ..session.add(LinkState.disconnected)
        ..os.add(false);

      async.elapse(const Duration(minutes: 5));

      expect(h.calls, 0);
    });
  });

  test('stops once the session is connected', () {
    fakeAsync((async) {
      final h = Harness(
        connectResult: (h) async => h.session.add(LinkState.connected),
      )..session.add(LinkState.disconnected);

      h.os.add(true);
      async.elapse(const Duration(minutes: 1));

      expect(h.calls, 1);
    });
  });

  test('a session drop while the OS has them retries after the jitter', () {
    fakeAsync((async) {
      final h = Harness()
        ..session.add(LinkState.connected)
        ..os.add(true);
      async.flushMicrotasks();
      expect(h.calls, 0);

      h.session.add(LinkState.disconnected);
      async.elapse(const Duration(milliseconds: 7400));
      expect(h.calls, 0);
      async.elapse(const Duration(milliseconds: 200));
      expect(h.calls, 1);
    });
  });

  test('the OS losing the earbuds cancels the pending retry', () {
    fakeAsync((async) {
      final h = Harness()
        ..session.add(LinkState.disconnected)
        ..os.add(true);
      async.flushMicrotasks();

      h.os.add(false);
      async.elapse(const Duration(minutes: 1));

      expect(h.calls, 1);
    });
  });

  test('never runs two attempts at once', () {
    fakeAsync((async) {
      final h = Harness(connectResult: (_) => Completer<void>().future)
        ..session.add(LinkState.disconnected)
        ..os.add(true);

      async.elapse(const Duration(minutes: 1));

      expect(h.calls, 1);
    });
  });

  test('stop cancels the pending retry', () {
    fakeAsync((async) {
      final h = Harness()
        ..session.add(LinkState.disconnected)
        ..os.add(true);
      async.flushMicrotasks();

      unawaited(h.supervisor.stop());
      async.elapse(const Duration(minutes: 1));

      expect(h.calls, 1);
    });
  });

  test('logs the OS link, each attempt, its failure and the next retry', () {
    fakeAsync((async) {
      final h = Harness()
        ..session.add(LinkState.disconnected)
        ..os.add(true);
      async.flushMicrotasks();

      expect(h.logs, [
        'session: disconnected',
        'OS link: connected',
        'attempt: connecting',
        'attempt failed: Bad state: no reply',
        'retry in 7.5 s',
      ]);
    });
  });

  test('an error from the OS watch is logged and does not stop it', () {
    fakeAsync((async) {
      final h = Harness()..session.add(LinkState.disconnected);

      h.os.addError(StateError('D-Bus gone'));
      async.flushMicrotasks();
      h.os.add(true);
      async.flushMicrotasks();

      expect(h.logs, contains('OS link watch failed: Bad state: D-Bus gone'));
      expect(h.calls, 1);
    });
  });
}
