import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_buds/presentation/theme/kz_palette.dart';
import 'package:kz_buds/presentation/theme/kz_theme_preference.dart';
import 'package:kz_buds/presentation/widgets/kz_card.dart';

import '../../support/pump_kz.dart';

BoxDecoration decoration(WidgetTester tester) =>
    tester
            .widget<DecoratedBox>(
              find.descendant(
                of: find.byType(KzCard),
                matching: find.byType(DecoratedBox),
              ),
            )
            .decoration
        as BoxDecoration;

void main() {
  testWidgets('is an opaque panel with a hairline border', (tester) async {
    await pumpKz(tester, const KzCard(child: Text('inside')));
    expect(find.text('inside'), findsOneWidget);
    expect(decoration(tester).color, KzPalette.inkPanel);
    expect(decoration(tester).gradient, isNull);
    expect(decoration(tester).border, isNotNull);
    expect(find.byType(BackdropFilter), findsNothing);
  });

  testWidgets('uses the paper panel in the light mode', (tester) async {
    await pumpKz(
      tester,
      const KzCard(child: Text('inside')),
      preference: KzThemePreference.light,
    );
    expect(decoration(tester).color, KzPalette.paperPanel);
  });
}
