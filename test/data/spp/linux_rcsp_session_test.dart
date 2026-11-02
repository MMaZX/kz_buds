import 'package:flutter_test/flutter_test.dart';
import 'package:kz_buds/data/spp/linux/linux_rcsp_session.dart';
import 'package:kz_buds/domain/entities/detected_earbuds.dart';

import '../../support/fake_rcsp_earbuds.dart';

void main() {
  const carol = DetectedEarbuds(id: '00:11:22:33:44:55', name: 'Carol Pro');

  test('connects the earbuds through the OS before opening RFCOMM', () async {
    final calls = <String>[];

    final session = await openLinuxRcspSession(
      discover: () async => [carol],
      connectOs: (id) async => calls.add('os $id'),
      openLink: (id) async {
        calls.add('link $id');
        return FakeRcspEarbuds();
      },
    );
    addTearDown(session.close);

    expect(calls, ['os ${carol.id}', 'link ${carol.id}']);
    expect(session.osName, carol.name);
  });

  test('fails without touching the radio when nothing is paired', () async {
    final calls = <String>[];

    await expectLater(
      openLinuxRcspSession(
        discover: () async => [],
        connectOs: (id) async => calls.add('os'),
        openLink: (id) async {
          calls.add('link');
          return FakeRcspEarbuds();
        },
      ),
      throwsStateError,
    );
    expect(calls, isEmpty);
  });
}
