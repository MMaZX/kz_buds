import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_buds/data/fake/fake_earbuds_adapter.dart';
import 'package:kz_buds/main.dart';
import 'package:kz_buds/presentation/pages/device_home_page.dart';
import 'package:kz_buds/presentation/providers/earbuds_providers.dart';
import 'package:kz_buds/presentation/providers/theme_providers.dart';
import 'package:kz_buds/presentation/providers/visual_settings_providers.dart';
import 'package:kz_buds/presentation/theme/kz_palette.dart';
import 'package:kz_buds/presentation/theme/kz_theme.dart';
import 'package:kz_buds/presentation/theme/kz_theme_preference.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

void main() {
  testWidgets('the app follows themePreferenceProvider', (tester) async {
    final fake = FakeEarbudsAdapter();
    addTearDown(fake.dispose);
    final container = ProviderContainer(
      overrides: [earbudsPortProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const KzBudsApp()),
    );
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(DeviceHomePage));

    container
        .read(themePreferenceProvider.notifier)
        .set(KzThemePreference.dark);
    await tester.pumpAndSettle();
    expect(ShadTheme.of(context).colorScheme.background, KzPalette.ink950);

    container
        .read(themePreferenceProvider.notifier)
        .set(KzThemePreference.light);
    await tester.pumpAndSettle();
    expect(ShadTheme.of(context).colorScheme.background, KzPalette.mist50);
  });

  testWidgets('the reduce transparency setting reaches KzTheme', (
    tester,
  ) async {
    final fake = FakeEarbudsAdapter();
    addTearDown(fake.dispose);
    final container = ProviderContainer(
      overrides: [earbudsPortProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const KzBudsApp()),
    );
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(DeviceHomePage));
    expect(KzTheme.reduceTransparencyOf(context), isFalse);

    container.read(visualSettingsProvider.notifier).setReduceTransparency(true);
    await tester.pumpAndSettle();
    expect(KzTheme.reduceTransparencyOf(context), isTrue);
  });
}
