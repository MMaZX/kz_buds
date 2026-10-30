import 'package:flutter_test/flutter_test.dart';
import 'package:kz_buds/data/fake/fake_earbuds_adapter.dart';
import 'package:kz_buds/domain/capabilities/capability.dart';
import 'package:kz_buds/domain/entities/bud.dart';
import 'package:kz_buds/presentation/providers/remap_providers.dart';
import 'package:kz_buds/presentation/widgets/kz_chip.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../support/pump_home.dart';

FakeEarbudsAdapter withRemap() =>
    FakeEarbudsAdapter(capabilities: {Capability.buttonRemap});

Future<void> openTouch(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel('Touch'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lists the four gestures for the left bud first', (tester) async {
    await pumpApp(tester, withRemap());
    await openTouch(tester);
    expect(find.text('Touch controls'), findsOneWidget);
    for (final gesture in TouchGesture.values) {
      expect(find.text(gesture.label), findsOneWidget);
    }
    expect(find.byType(ShadSelect<TouchAction>), findsNWidgets(4));
    expect(
      tester.widget<KzChip>(find.widgetWithText(KzChip, 'Left')).selected,
      isTrue,
    );
  });

  testWidgets('choosing an action updates the setting', (tester) async {
    final container = await pumpApp(tester, withRemap());
    await openTouch(tester);
    await tester.tap(find.byType(ShadSelect<TouchAction>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(TouchAction.volumeUp.label));
    await tester.pumpAndSettle();
    expect(
      container
          .read(touchRemapProvider)
          .actionFor(Bud.left, TouchGesture.singleTap),
      TouchAction.volumeUp,
    );
  });

  testWidgets('the right bud has its own settings', (tester) async {
    final container = await pumpApp(tester, withRemap());
    container
        .read(touchRemapProvider.notifier)
        .setAction(Bud.right, TouchGesture.singleTap, TouchAction.none);
    await openTouch(tester);
    final leftDefault = container
        .read(touchRemapProvider)
        .actionFor(Bud.left, TouchGesture.singleTap);
    expect(find.text(leftDefault.label), findsWidgets);

    await tester.tap(find.widgetWithText(KzChip, 'Right'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<KzChip>(find.widgetWithText(KzChip, 'Right')).selected,
      isTrue,
    );
    expect(find.text(TouchAction.none.label), findsWidgets);
  });
}
