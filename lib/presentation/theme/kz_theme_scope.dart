import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'kz_motion.dart';
import 'kz_theme.dart';
import 'kz_theme_preference.dart';

/// App shell wiring for `WidgetsApp.builder`: replaces `ShadApp` so shadcn_ui
/// components work without Material. Must sit below the `MediaQuery` that
/// `WidgetsApp` creates.
class KzThemeScope extends StatelessWidget {
  const KzThemeScope({
    required this.preference,
    required this.child,
    super.key,
  });

  final KzThemePreference preference;
  final Widget child;

  static const _dark = KzThemeData.dark();
  static const _light = KzThemeData.light();

  KzThemeData _resolve(BuildContext context) => switch (preference) {
    KzThemePreference.dark => _dark,
    KzThemePreference.light => _light,
    KzThemePreference.system =>
      MediaQuery.platformBrightnessOf(context) == Brightness.dark
          ? _dark
          : _light,
  };

  @override
  Widget build(BuildContext context) {
    final data = _resolve(context);
    final motion = KzMotion.of(context);
    final foreground = data.scheme.foreground;

    return ShadAnimatedTheme(
      data: data.toShad(),
      duration: motion.base,
      curve: KzMotion.baseCurve,
      child: KzTheme(
        data: data,
        child: ShadMouseAreaSurface(
          child: ShadMouseCursorProvider(
            child: DefaultTextStyle(
              style: data.typography.body.copyWith(color: foreground),
              child: IconTheme(
                data: IconThemeData(size: 20, color: foreground),
                child: ShadAppBuilder(child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
