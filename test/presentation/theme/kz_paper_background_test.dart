import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_buds/presentation/theme/kz_palette.dart';
import 'package:kz_buds/presentation/theme/kz_paper_background.dart';
import 'package:kz_buds/presentation/theme/kz_theme.dart';
import 'package:kz_buds/presentation/theme/kz_theme_preference.dart';

import '../../support/pump_kz.dart';

void main() {
  test('grid lines sit every 72 px starting at 0', () {
    expect(KzPaperBackground.lineOffsets(390), [0, 72, 144, 216, 288, 360]);
    expect(KzPaperBackground.lineOffsets(72), [0]);
    expect(KzPaperBackground.lineOffsets(73), [0, 72]);
    expect(KzPaperBackground.lineOffsets(0), isEmpty);
  });

  testWidgets('the theme carries one grid tone per mode', (tester) async {
    await pumpKz(tester, const Text('x'));
    expect(KzTheme.of(tester.element(find.text('x'))).grid, KzPalette.inkGrid);
    await pumpKz(tester, const Text('x'), preference: KzThemePreference.light);
    expect(
      KzTheme.of(tester.element(find.text('x'))).grid,
      KzPalette.paperGrid,
    );
  });

  testWidgets('paints the flat background, then the grid', (tester) async {
    await pumpKz(tester, const Text('x'));
    expect(
      find.byType(KzPaperBackground),
      paints
        ..rect(color: KzPalette.inkBg)
        ..rect(color: KzPalette.inkGrid),
    );
  });

  testWidgets('paper mode uses the paper background and grid', (tester) async {
    await pumpKz(tester, const Text('x'), preference: KzThemePreference.light);
    expect(
      find.byType(KzPaperBackground),
      paints
        ..rect(color: KzPalette.paperBg)
        ..rect(color: KzPalette.paperGrid),
    );
  });

  testWidgets('the grid is subtle: close to the background tone', (
    tester,
  ) async {
    for (final (bg, grid) in [
      (KzPalette.inkBg, KzPalette.inkGrid),
      (KzPalette.paperBg, KzPalette.paperGrid),
    ]) {
      final delta = ((bg.r - grid.r).abs() * 255);
      expect(delta, lessThan(24));
      expect(delta, greaterThan(4));
    }
  });
}
