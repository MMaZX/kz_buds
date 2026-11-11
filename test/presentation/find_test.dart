import 'package:flutter_test/flutter_test.dart';
import 'package:kz_buds/data/fake/fake_earbuds_adapter.dart';
import 'package:kz_buds/domain/capabilities/capability.dart';
import 'package:kz_buds/domain/entities/find_target.dart';
import 'package:kz_buds/presentation/pages/device_home_page.dart';
import 'package:kz_buds/presentation/pages/find_page.dart';

import '../support/pump_home.dart';

FakeEarbudsAdapter withFind() =>
    FakeEarbudsAdapter(capabilities: {Capability.findBuds});

Future<void> openFind(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel('Find my buds'));
  await tester.pumpAndSettle();
}

void main() {
  group('home entry points', () {
    testWidgets('FIND appears only with the findBuds capability', (
      tester,
    ) async {
      await pumpApp(tester, FakeEarbudsAdapter());
      expect(find.bySemanticsLabel('Find my buds'), findsNothing);
    });

    testWidgets('CONTROLS appears only with buttonRemap and opens it', (
      tester,
    ) async {
      await pumpApp(tester, FakeEarbudsAdapter());
      expect(find.text('CONTROLS'), findsNothing);
      await pumpApp(
        tester,
        FakeEarbudsAdapter(capabilities: {Capability.buttonRemap}),
      );
      await tester.tap(find.text('CONTROLS'));
      await tester.pumpAndSettle();
      expect(find.text('Touch controls'), findsOneWidget);
    });
  });

  group('find my buds', () {
    testWidgets('offers both by default, then left and right with a '
        'firmware note', (tester) async {
      await pumpApp(tester, withFind());
      await openFind(tester);
      expect(find.byType(FindPage), findsOneWidget);
      expect(
        find.text('Remove the earbuds before playing a sound.'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Play on both earbuds'), findsOneWidget);
      expect(find.bySemanticsLabel('Play on left earbud'), findsOneWidget);
      expect(find.bySemanticsLabel('Play on right earbud'), findsOneWidget);
      expect(find.text(FindPage.singleSideNote), findsOneWidget);
      expect(find.text('STOP'), findsNothing);
    });

    testWidgets('both plays on both earbuds', (tester) async {
      final fake = withFind();
      await pumpApp(tester, fake);
      await openFind(tester);

      await tester.tap(find.bySemanticsLabel('Play on both earbuds'));
      await tester.pumpAndSettle();

      expect(fake.findSoundTarget, FindTarget.both);
      expect(find.text('STOP'), findsOneWidget);
    });

    testWidgets('the home does not show through the page', (tester) async {
      await pumpApp(tester, withFind());
      expect(find.byType(DeviceHomePage), findsOneWidget);
      await openFind(tester);
      expect(find.byType(FindPage), findsOneWidget);
      expect(find.byType(DeviceHomePage), findsNothing);
      expect(find.text('KZ BUDS'), findsNothing);
    });

    testWidgets('playing shows Stop and tells the device', (tester) async {
      final fake = withFind();
      await pumpApp(tester, fake);
      await openFind(tester);
      await tester.tap(find.bySemanticsLabel('Play on left earbud'));
      await tester.pumpAndSettle();
      expect(fake.findSoundTarget, FindTarget.left);
      expect(find.text('STOP'), findsOneWidget);

      await tester.tap(find.text('STOP'));
      await tester.pumpAndSettle();
      expect(fake.findSoundTarget, isNull);
      expect(find.text('STOP'), findsNothing);
    });

    testWidgets('leaving the page stops the sound', (tester) async {
      final fake = withFind();
      await pumpApp(tester, fake);
      await openFind(tester);
      await tester.tap(find.bySemanticsLabel('Play on right earbud'));
      await tester.pumpAndSettle();
      expect(fake.findSoundTarget, FindTarget.right);

      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();
      expect(fake.findSoundTarget, isNull);
    });
  });
}
