import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_buds/presentation/theme/kz_palette.dart';
import 'package:kz_buds/presentation/theme/kz_theme_preference.dart';
import 'package:kz_buds/presentation/widgets/kz_block_button.dart';

import '../../support/pump_kz.dart';

BoxDecoration decoration(WidgetTester tester) =>
    tester
            .widget<DecoratedBox>(
              find.byKey(const ValueKey('kz-block-button-fill')),
            )
            .decoration
        as BoxDecoration;

void main() {
  testWidgets('is a solid red block with an uppercase label and taps', (
    tester,
  ) async {
    var taps = 0;
    await pumpKz(
      tester,
      KzBlockButton(label: 'Reset', onPressed: () => taps++),
    );
    expect(find.text('RESET'), findsOneWidget);
    expect(decoration(tester).color, KzPalette.signalRedDark);
    expect(decoration(tester).border, isNull);
    expect(decoration(tester).borderRadius, isNotNull);
    final text = tester.widget<Text>(find.text('RESET'));
    expect(text.style!.color, KzPalette.white);

    await tester.tap(find.byType(KzBlockButton));
    expect(taps, 1);
  });

  testWidgets('uses the light red on paper', (tester) async {
    await pumpKz(
      tester,
      KzBlockButton(label: 'Stop', onPressed: () {}),
      preference: KzThemePreference.light,
    );
    expect(decoration(tester).color, KzPalette.signalRedLight);
  });

  testWidgets('is a button for assistive tech, named by its label', (
    tester,
  ) async {
    await pumpKz(tester, KzBlockButton(label: 'Stop', onPressed: () {}));
    expect(find.bySemanticsLabel('Stop'), findsOneWidget);
  });
}
