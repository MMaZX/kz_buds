import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_buds/presentation/theme/kz_glass.dart';
import 'package:kz_buds/presentation/theme/kz_glass_theme.dart';
import 'package:kz_buds/presentation/theme/kz_palette.dart';
import 'package:kz_buds/presentation/theme/kz_theme.dart';
import 'package:kz_buds/presentation/theme/kz_theme_preference.dart';

import '../../support/pump_kz.dart';

Widget glass(KzGlassLevel level) => KzGlass(
  level: level,
  borderRadius: BorderRadius.circular(20),
  child: const SizedBox(width: 120, height: 60, child: Text('inside')),
);

ImageFilter blur(double sigma) =>
    ImageFilter.blur(sigmaX: sigma, sigmaY: sigma, tileMode: TileMode.clamp);

BackdropFilter backdrop(WidgetTester tester) =>
    tester.widget<BackdropFilter>(find.byType(BackdropFilter));

BoxDecoration decoration(WidgetTester tester) {
  final box = tester.widget<DecoratedBox>(
    find.descendant(
      of: find.byType(KzGlass),
      matching: find.byType(DecoratedBox),
    ),
  );
  return box.decoration as BoxDecoration;
}

void main() {
  tearDown(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher
        .clearAccessibilityFeaturesTestValue();
  });

  group('blur levels', () {
    for (final (level, sigma) in [
      (KzGlassLevel.subtle, 12.0),
      (KzGlassLevel.panel, 24.0),
      (KzGlassLevel.chrome, 32.0),
    ]) {
      testWidgets('$level blurs with sigma $sigma', (tester) async {
        await pumpKz(tester, glass(level));
        expect(backdrop(tester).filter, blur(sigma));
        expect(find.text('inside'), findsOneWidget);
      });
    }
  });

  group('reduced transparency', () {
    testWidgets('has no BackdropFilter and uses the opaque fallback', (
      tester,
    ) async {
      await pumpKz(tester, glass(KzGlassLevel.panel), reduceTransparency: true);
      expect(find.byType(BackdropFilter), findsNothing);
      expect(find.text('inside'), findsOneWidget);
      expect(decoration(tester).color, KzPalette.ink900);
    });

    testWidgets('fallback fills follow the plan per level', (tester) async {
      await pumpKz(
        tester,
        glass(KzGlassLevel.subtle),
        reduceTransparency: true,
      );
      expect(decoration(tester).color, KzPalette.ink800);
      await pumpKz(
        tester,
        glass(KzGlassLevel.chrome),
        reduceTransparency: true,
      );
      expect(decoration(tester).color, KzPalette.ink850);
    });

    testWidgets('high contrast forces the fallback', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(highContrast: true);
      await pumpKz(tester, glass(KzGlassLevel.panel));
      expect(find.byType(BackdropFilter), findsNothing);
    });
  });

  testWidgets('glass fills come from the palette and differ by mode', (
    tester,
  ) async {
    await pumpKz(tester, glass(KzGlassLevel.chrome));
    expect(decoration(tester).color, KzPalette.glassChromeDark);
    await pumpKz(
      tester,
      glass(KzGlassLevel.chrome),
      preference: KzThemePreference.light,
    );
    expect(decoration(tester).color, KzPalette.glassChromeLight);
  });

  testWidgets('KzTheme exposes the ambient colors', (tester) async {
    await pumpKz(tester, const Text('x'));
    final theme = KzTheme.of(tester.element(find.text('x')));
    expect(theme.ambient.bottom, KzPalette.ink950);
    expect(theme.ambient.copperGlow, KzPalette.ambientCopperGlowDark);
  });
}
