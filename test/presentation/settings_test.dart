import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kz_buds/data/fake/fake_earbuds_adapter.dart';
import 'package:kz_buds/presentation/app_info.dart';
import 'package:kz_buds/presentation/providers/theme_providers.dart';
import 'package:kz_buds/presentation/providers/visual_settings_providers.dart';
import 'package:kz_buds/presentation/theme/kz_palette.dart';
import 'package:kz_buds/presentation/theme/kz_theme_preference.dart';
import 'package:kz_buds/presentation/widgets/kz_chip.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../support/pump_home.dart';

bool chipSelected(WidgetTester tester, String label) =>
    tester.widget<KzChip>(find.widgetWithText(KzChip, label)).selected;

Future<void> openSettings(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel('Settings'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('appearance chips reflect and change the theme preference', (
    tester,
  ) async {
    final container = await pumpApp(tester, FakeEarbudsAdapter());
    await openSettings(tester);
    expect(chipSelected(tester, 'Ink'), isTrue);

    await tester.tap(find.widgetWithText(KzChip, 'Paper'));
    await tester.pumpAndSettle();
    expect(container.read(themePreferenceProvider), KzThemePreference.light);
    expect(chipSelected(tester, 'Paper'), isTrue);
    final context = tester.element(find.text('Settings').first);
    expect(ShadTheme.of(context).colorScheme.background, KzPalette.paperBg);

    await tester.tap(find.widgetWithText(KzChip, 'System'));
    await tester.pumpAndSettle();
    expect(container.read(themePreferenceProvider), KzThemePreference.system);
  });

  testWidgets('has the three theme options', (tester) async {
    await pumpApp(tester, FakeEarbudsAdapter());
    await openSettings(tester);
    expect(find.widgetWithText(KzChip, 'System'), findsOneWidget);
    expect(find.widgetWithText(KzChip, 'Paper'), findsOneWidget);
    expect(find.widgetWithText(KzChip, 'Ink'), findsOneWidget);
  });

  testWidgets('the reduce transparency switch updates the setting', (
    tester,
  ) async {
    final container = await pumpApp(tester, FakeEarbudsAdapter());
    await openSettings(tester);
    expect(container.read(visualSettingsProvider).reduceTransparency, isFalse);
    await tester.tap(find.byType(ShadSwitch));
    await tester.pumpAndSettle();
    expect(container.read(visualSettingsProvider).reduceTransparency, isTrue);
  });

  group('about', () {
    Future<void> openAbout(WidgetTester tester) async {
      await pumpApp(tester, FakeEarbudsAdapter());
      await openSettings(tester);
      await tester.tap(find.text('About KZ Buds'));
      await tester.pumpAndSettle();
    }

    testWidgets('shows the version and the credits', (tester) async {
      await openAbout(tester);
      expect(find.text('Version $kAppVersion'), findsOneWidget);
      expect(find.text('Inter'), findsOneWidget);
      expect(find.text('SIL Open Font License 1.1'), findsOneWidget);
      expect(find.text('shadcn_ui'), findsOneWidget);
      expect(find.text('hugeicons'), findsOneWidget);
    });

    testWidgets('back returns to the settings', (tester) async {
      await openAbout(tester);
      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();
      expect(find.text('About KZ Buds'), findsOneWidget);
      expect(find.text('Version $kAppVersion'), findsNothing);
    });
  });

  test('the displayed version matches pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final version = RegExp(
      r'^version:\s*([\d.]+)',
      multiLine: true,
    ).firstMatch(pubspec)!.group(1);
    expect(kAppVersion, version);
  });
}
