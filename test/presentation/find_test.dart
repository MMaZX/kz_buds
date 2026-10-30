import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_buds/data/fake/fake_earbuds_adapter.dart';
import 'package:kz_buds/domain/capabilities/capability.dart';
import 'package:kz_buds/domain/entities/bud.dart';
import 'package:kz_buds/presentation/pages/find_page.dart';

import '../support/pump_home.dart';

FakeEarbudsAdapter withFind() =>
    FakeEarbudsAdapter(capabilities: {Capability.findBuds});

Future<void> openFind(WidgetTester tester) async {
  await tester.tap(find.text('FIND'));
  await tester.pumpAndSettle();
}

void main() {
  group('home entry points', () {
    testWidgets('FIND appears only with the findBuds capability', (
      tester,
    ) async {
      await pumpApp(tester, FakeEarbudsAdapter());
      expect(find.text('FIND'), findsNothing);
    });

    testWidgets('TOUCH appears only with buttonRemap and opens it', (
      tester,
    ) async {
      await pumpApp(tester, FakeEarbudsAdapter());
      expect(find.text('TOUCH'), findsNothing);
      await pumpApp(
        tester,
        FakeEarbudsAdapter(capabilities: {Capability.buttonRemap}),
      );
      await tester.tap(find.text('TOUCH'));
      await tester.pumpAndSettle();
      expect(find.text('Touch controls'), findsOneWidget);
    });
  });

  group('find my buds', () {
    testWidgets('warns before playing and offers both buds', (tester) async {
      await pumpApp(tester, withFind());
      await openFind(tester);
      expect(find.byType(FindPage), findsOneWidget);
      expect(
        find.text('Remove the earbuds before playing a sound.'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Play on left earbud'), findsOneWidget);
      expect(find.bySemanticsLabel('Play on right earbud'), findsOneWidget);
      expect(find.text('Stop'), findsNothing);
    });

    testWidgets('the home does not show through the page', (tester) async {
      await pumpApp(tester, withFind());
      expect(find.byType(Placeholder), findsOneWidget);
      await openFind(tester);
      expect(find.byType(FindPage), findsOneWidget);
      expect(find.byType(Placeholder), findsNothing);
      expect(find.text('KZ Buds'), findsNothing);
    });

    testWidgets('playing shows Stop and tells the device', (tester) async {
      final fake = withFind();
      await pumpApp(tester, fake);
      await openFind(tester);
      await tester.tap(find.bySemanticsLabel('Play on left earbud'));
      await tester.pumpAndSettle();
      expect(fake.findSoundBud, Bud.left);
      expect(find.text('Stop'), findsOneWidget);

      await tester.tap(find.text('Stop'));
      await tester.pumpAndSettle();
      expect(fake.findSoundBud, isNull);
      expect(find.text('Stop'), findsNothing);
    });

    testWidgets('leaving the page stops the sound', (tester) async {
      final fake = withFind();
      await pumpApp(tester, fake);
      await openFind(tester);
      await tester.tap(find.bySemanticsLabel('Play on right earbud'));
      await tester.pumpAndSettle();
      expect(fake.findSoundBud, Bud.right);

      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();
      expect(fake.findSoundBud, isNull);
    });
  });
}
