import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_buds/presentation/theme/kz_palette.dart';
import 'package:kz_buds/presentation/widgets/kz_battery_glyph.dart';

import '../../support/pump_kz.dart';

KzBatteryPainter painter(WidgetTester tester) {
  final paint = tester.widget<CustomPaint>(
    find.descendant(
      of: find.byType(KzBatteryGlyph),
      matching: find.byType(CustomPaint),
    ),
  );
  return paint.painter! as KzBatteryPainter;
}

void main() {
  testWidgets('fill is proportional to the level', (tester) async {
    await pumpKz(tester, const KzBatteryGlyph(level: 72));
    expect(painter(tester).fraction, closeTo(0.72, 0.001));
    await pumpKz(tester, const KzBatteryGlyph(level: 0));
    expect(painter(tester).fraction, 0);
    await pumpKz(tester, const KzBatteryGlyph(level: 100));
    expect(painter(tester).fraction, 1);
  });

  testWidgets('out of range levels are clamped', (tester) async {
    await pumpKz(tester, const KzBatteryGlyph(level: 150));
    expect(painter(tester).fraction, 1);
    await pumpKz(tester, const KzBatteryGlyph(level: -5));
    expect(painter(tester).fraction, 0);
  });

  testWidgets('critical at 20, neutral at 21', (tester) async {
    await pumpKz(tester, const KzBatteryGlyph(level: 20));
    expect(painter(tester).fill, KzPalette.criticalDark);
    await pumpKz(tester, const KzBatteryGlyph(level: 21));
    expect(painter(tester).fill, KzPalette.inkText);
  });

  testWidgets('charging uses the success color and a bolt', (tester) async {
    await pumpKz(tester, const KzBatteryGlyph(level: 50, charging: true));
    expect(painter(tester).fill, KzPalette.successDark);
    expect(painter(tester).charging, isTrue);
    expect(find.byType(KzBatteryGlyph), paints..path());
  });

  testWidgets('no bolt when not charging', (tester) async {
    await pumpKz(tester, const KzBatteryGlyph(level: 50));
    expect(find.byType(KzBatteryGlyph), isNot(paints..path()));
  });

  testWidgets('describes the level for accessibility', (tester) async {
    await pumpKz(tester, const KzBatteryGlyph(level: 72));
    expect(find.bySemanticsLabel('Battery 72%'), findsOneWidget);
    await pumpKz(tester, const KzBatteryGlyph(level: 40, charging: true));
    expect(find.bySemanticsLabel('Battery 40%, charging'), findsOneWidget);
  });
}
