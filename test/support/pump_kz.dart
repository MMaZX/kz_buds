import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_buds/presentation/theme/kz_palette.dart';
import 'package:kz_buds/presentation/theme/kz_theme_preference.dart';
import 'package:kz_buds/presentation/theme/kz_theme_scope.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Pumps [child] inside a WidgetsApp wrapped by our own theme scope.
Future<void> pumpKz(
  WidgetTester tester,
  Widget child, {
  KzThemePreference preference = KzThemePreference.dark,
  bool settle = true,
}) async {
  await tester.pumpWidget(
    WidgetsApp(
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
      home: Center(child: child),
    ),
  );
  // An endless animation never settles; pump one frame instead.
  settle ? await tester.pumpAndSettle() : await tester.pump();
}
