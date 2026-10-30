import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_buds/data/fake/fake_earbuds_adapter.dart';
import 'package:kz_buds/main.dart';
import 'package:kz_buds/presentation/providers/earbuds_providers.dart';
import 'package:kz_buds/presentation/providers/theme_providers.dart';
import 'package:kz_buds/presentation/theme/kz_theme_preference.dart';

/// Pumps the whole app on top of [fake] and returns its provider container.
Future<ProviderContainer> pumpApp(
  WidgetTester tester,
  FakeEarbudsAdapter fake, {
  KzThemePreference preference = KzThemePreference.dark,
}) async {
  addTearDown(fake.dispose);
  final container = ProviderContainer(
    overrides: [earbudsPortProvider.overrideWithValue(fake)],
  );
  addTearDown(container.dispose);
  container.read(themePreferenceProvider.notifier).set(preference);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const KzBudsApp()),
  );
  await tester.pumpAndSettle();
  return container;
}
