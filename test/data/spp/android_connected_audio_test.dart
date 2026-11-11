import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_buds/data/spp/android/android_connected_audio.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('kz_buds/bluetooth');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('returns the connected addresses in upper case', () async {
    final methods = <String>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      methods.add(call.method);
      return ['aa:bb:cc:dd:ee:ff'];
    });

    expect(await androidConnectedAudioAddresses(), {'AA:BB:CC:DD:EE:FF'});
    expect(methods, ['connectedAudioDevices']);
  });

  test('returns an empty set when nothing is connected', () async {
    messenger.setMockMethodCallHandler(channel, (call) async => <String>[]);

    expect(await androidConnectedAudioAddresses(), isEmpty);
  });

  test('is unknown when the platform reports an error', () async {
    messenger.setMockMethodCallHandler(
      channel,
      (call) async => throw PlatformException(code: 'unavailable'),
    );

    expect(await androidConnectedAudioAddresses(), isNull);
  });

  test('is unknown when the platform side is missing', () async {
    expect(await androidConnectedAudioAddresses(), isNull);
  });

  group('androidConnectedAudioChanges', () {
    test('emits the current devices, then again on each signal', () async {
      final signals = StreamController<Object?>();
      final answers = [
        <String>{},
        {'AA:BB:CC:DD:EE:FF'},
      ];
      var queries = 0;
      final seen = <Set<String>?>[];
      final subscription = androidConnectedAudioChanges(
        signals: signals.stream,
        query: () async => answers[queries++],
      ).listen(seen.add);

      await pumpEventQueue();
      signals.add(null);
      await pumpEventQueue();

      expect(seen, [
        <String>{},
        {'AA:BB:CC:DD:EE:FF'},
      ]);
      await subscription.cancel();
      await signals.close();
    });

    test('asks again when a signal arrives during a query', () async {
      final signals = StreamController<Object?>();
      final pending = <Completer<Set<String>?>>[];
      final seen = <Set<String>?>[];
      final subscription = androidConnectedAudioChanges(
        signals: signals.stream,
        query: () {
          pending.add(Completer());
          return pending.last.future;
        },
      ).listen(seen.add);

      await pumpEventQueue();
      signals.add(null);
      await pumpEventQueue();
      expect(pending, hasLength(1));

      pending[0].complete(<String>{});
      await pumpEventQueue();
      expect(pending, hasLength(2));

      pending[1].complete({'AA:BB:CC:DD:EE:FF'});
      await pumpEventQueue();

      expect(seen.last, {'AA:BB:CC:DD:EE:FF'});
      await subscription.cancel();
      await signals.close();
    });

    test('stops listening to signals when cancelled', () async {
      final signals = StreamController<Object?>();
      final subscription = androidConnectedAudioChanges(
        signals: signals.stream,
        query: () async => <String>{},
      ).listen((_) {});
      await pumpEventQueue();

      await subscription.cancel();

      expect(signals.hasListener, isFalse);
      await signals.close();
    });
  });
}
