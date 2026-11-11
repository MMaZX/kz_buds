import 'package:flutter_test/flutter_test.dart';
import 'package:kz_buds/data/spp/android/android_rcsp_session.dart';
import 'package:kz_buds/domain/entities/bluetooth_access_denied.dart';
import 'package:kz_buds/domain/entities/detected_earbuds.dart';

import '../../support/fake_rcsp_earbuds.dart';

void main() {
  const speaker = DetectedEarbuds(id: 'AA:AA:AA:AA:AA:AA', name: 'Speaker');
  const carol = DetectedEarbuds(id: '00:11:22:33:44:55', name: 'Carol Pro');

  test('asks for access before touching the radio', () async {
    final calls = <String>[];

    await expectLater(
      openAndroidRcspSession(
        requestAccess: () async => false,
        discover: () async {
          calls.add('discover');
          return [carol];
        },
        openLink: (id) async {
          calls.add('link');
          return FakeRcspEarbuds();
        },
      ),
      throwsA(isA<BluetoothAccessDenied>()),
    );
    expect(calls, isEmpty);
  });

  test('tries each candidate until one completes the RCSP handshake', () async {
    final tried = <String>[];

    final session = await openAndroidRcspSession(
      requestAccess: () async => true,
      discover: () async => [speaker, carol],
      openLink: (id) async {
        tried.add(id);
        if (id == speaker.id) throw StateError('no SPP service');
        return FakeRcspEarbuds();
      },
    );
    addTearDown(session.close);

    expect(tried, [speaker.id, carol.id]);
    expect(session.osName, carol.name);
  });

  test('rethrows the last failure when no candidate speaks RCSP', () async {
    await expectLater(
      openAndroidRcspSession(
        requestAccess: () async => true,
        discover: () async => [speaker],
        openLink: (id) async => throw StateError('no SPP service'),
      ),
      throwsStateError,
    );
  });

  test('stops at a denied access instead of trying the next one', () async {
    final tried = <String>[];

    await expectLater(
      openAndroidRcspSession(
        requestAccess: () async => true,
        discover: () async => [speaker, carol],
        openLink: (id) async {
          tried.add(id);
          throw const BluetoothAccessDenied();
        },
      ),
      throwsA(isA<BluetoothAccessDenied>()),
    );
    expect(tried, [speaker.id]);
  });

  test('retries discovery while the OS Bluetooth service comes up', () async {
    var reads = 0;

    final session = await openAndroidRcspSession(
      requestAccess: () async => true,
      discover: () async => ++reads < 3 ? [] : [carol],
      openLink: (id) async => FakeRcspEarbuds(),
      emptyRetryDelay: Duration.zero,
    );
    addTearDown(session.close);

    expect(reads, 3);
    expect(session.osName, carol.name);
  });

  test('fails without opening a link when nothing is paired', () async {
    final calls = <String>[];

    await expectLater(
      openAndroidRcspSession(
        requestAccess: () async => true,
        emptyRetryDelay: Duration.zero,
        discover: () async => [],
        openLink: (id) async {
          calls.add('link');
          return FakeRcspEarbuds();
        },
      ),
      throwsStateError,
    );
    expect(calls, isEmpty);
  });

  test('passes no OS name when the device has none', () async {
    const unnamed = DetectedEarbuds(id: '00:11:22:33:44:55', name: '');

    final session = await openAndroidRcspSession(
      requestAccess: () async => true,
      discover: () async => [unnamed],
      openLink: (id) async => FakeRcspEarbuds(),
    );
    addTearDown(session.close);

    expect(session.osName, isNull);
  });

  test('reports which candidates failed and which one answered', () async {
    final failed = <String>[];
    final proven = <String>[];

    final session = await openAndroidRcspSession(
      requestAccess: () async => true,
      discover: () async => [speaker, carol],
      openLink: (id) async {
        if (id == speaker.id) throw StateError('no SPP service');
        return FakeRcspEarbuds();
      },
      onFailed: failed.add,
      onProven: proven.add,
    );

    expect(failed, [speaker.id]);
    expect(proven, [carol.id]);
    await session.close();
  });
}
