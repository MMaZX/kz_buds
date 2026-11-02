import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_buds/presentation/theme/kz_metrics.dart';
import 'package:kz_buds/presentation/theme/kz_motion.dart';
import 'package:kz_buds/presentation/theme/kz_palette.dart';
import 'package:kz_buds/presentation/theme/kz_theme.dart';
import 'package:kz_buds/presentation/theme/kz_theme_preference.dart';
import 'package:kz_buds/presentation/theme/kz_theme_scope.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class _Probe extends StatelessWidget {
  const _Probe();

  @override
  Widget build(BuildContext context) => const Text('probe');
}

Widget app(KzThemePreference preference) => WidgetsApp(
  color: KzPalette.inkBg,
  localizationsDelegates: const [
    GlobalShadLocalizations.delegate,
    DefaultWidgetsLocalizations.delegate,
  ],
  pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) =>
      PageRouteBuilder<T>(
        settings: settings,
        pageBuilder: (context, _, _) => builder(context),
      ),
  builder: (context, navigator) =>
      KzThemeScope(preference: preference, child: navigator!),
  home: const _Probe(),
);

Color background(WidgetTester tester) =>
    ShadTheme.of(tester.element(find.byType(_Probe))).colorScheme.background;

void main() {
  tearDown(() {
    final binding = TestWidgetsFlutterBinding.instance;
    binding.platformDispatcher.clearPlatformBrightnessTestValue();
    binding.platformDispatcher.clearAccessibilityFeaturesTestValue();
  });

  testWidgets('dark and light preferences resolve their palettes', (
    tester,
  ) async {
    await tester.pumpWidget(app(KzThemePreference.dark));
    await tester.pumpAndSettle();
    expect(background(tester), KzPalette.inkBg);

    await tester.pumpWidget(app(KzThemePreference.light));
    await tester.pumpAndSettle();
    expect(background(tester), KzPalette.paperBg);
  });

  testWidgets('system follows the platform brightness', (tester) async {
    final dispatcher = tester.platformDispatcher;
    dispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pumpWidget(app(KzThemePreference.system));
    await tester.pumpAndSettle();
    expect(background(tester), KzPalette.paperBg);

    dispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pumpAndSettle();
    expect(background(tester), KzPalette.inkBg);
  });

  testWidgets('light and dark override the platform brightness', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pumpWidget(app(KzThemePreference.light));
    await tester.pumpAndSettle();
    expect(background(tester), KzPalette.paperBg);
  });

  testWidgets('switching animates over 200 ms', (tester) async {
    await tester.pumpWidget(app(KzThemePreference.dark));
    await tester.pumpAndSettle();
    await tester.pumpWidget(app(KzThemePreference.light));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final mid = background(tester);
    expect(mid, isNot(KzPalette.inkBg));
    expect(mid, isNot(KzPalette.paperBg));
    await tester.pump(const Duration(milliseconds: 150));
    expect(background(tester), KzPalette.paperBg);
  });

  testWidgets('switching is instant when animations are disabled', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    await tester.pumpWidget(app(KzThemePreference.dark));
    await tester.pumpAndSettle();
    await tester.pumpWidget(app(KzThemePreference.light));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    expect(background(tester), KzPalette.paperBg);
  });

  testWidgets('provides KzTheme, text style, icon theme and toaster', (
    tester,
  ) async {
    await tester.pumpWidget(app(KzThemePreference.dark));
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(_Probe));

    expect(KzTheme.of(context).colors.brand, KzPalette.signalRedDark);
    final style = DefaultTextStyle.of(context).style;
    expect(style.fontFamily, 'Inter');
    expect(style.fontSize, 15);
    expect(style.color, KzPalette.inkText);
    expect(IconTheme.of(context).color, KzPalette.inkText);
    expect(() => ShadToaster.of(context), returnsNormally);
  });

  test('motion durations collapse to zero without animations', () {
    expect(
      const KzMotion(enabled: true).base,
      const Duration(milliseconds: 200),
    );
    expect(const KzMotion(enabled: false).base, Duration.zero);
    expect(const KzMotion(enabled: false).slow, Duration.zero);
  });

  test('metrics follow the plan scales', () {
    expect(KzRadii.md, 14);
    expect(KzRadii.pill, 999);
    expect(KzSpace.s16, 16);
    expect(KzBreakpoints.sizeClassFor(599), KzSizeClass.compact);
    expect(KzBreakpoints.sizeClassFor(600), KzSizeClass.medium);
    expect(KzBreakpoints.sizeClassFor(1024), KzSizeClass.expanded);
  });
}
