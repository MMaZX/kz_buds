import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'kz_color_scheme.dart';
import 'kz_colors.dart';
import 'kz_glass_theme.dart';
import 'kz_metrics.dart';
import 'kz_typography.dart';

class KzThemeData {
  const KzThemeData._({
    required this.brightness,
    required this.scheme,
    required this.typography,
    required this.glass,
  });

  const KzThemeData.dark()
    : this._(
        brightness: Brightness.dark,
        scheme: const KzColorScheme.dark(),
        typography: const KzTypography(),
        glass: const KzGlassTheme.dark(),
      );

  const KzThemeData.light()
    : this._(
        brightness: Brightness.light,
        scheme: const KzColorScheme.light(),
        typography: const KzTypography(),
        glass: const KzGlassTheme.light(),
      );

  final Brightness brightness;
  final ShadColorScheme scheme;
  final KzTypography typography;
  final KzGlassTheme glass;

  KzColors get colors => KzColors(scheme);

  ShadThemeData toShad() => ShadThemeData(
    brightness: brightness,
    colorScheme: scheme,
    textTheme: typography.toShadTextTheme(),
    radius: BorderRadius.circular(KzRadii.md),
  );
}

/// Our own theme access. shad widgets read `ShadTheme`; everything else reads
/// this one, so widgets never touch hex values.
class KzTheme extends InheritedWidget {
  const KzTheme({
    required this.data,
    required super.child,
    this.reduceTransparency = false,
    super.key,
  });

  final KzThemeData data;

  /// App setting that swaps every glass surface for an opaque fallback.
  final bool reduceTransparency;

  static KzThemeData of(BuildContext context) {
    final theme = context.dependOnInheritedWidgetOfExactType<KzTheme>();
    assert(theme != null, 'No KzTheme found. Wrap the app in KzThemeScope.');
    return theme!.data;
  }

  static bool reduceTransparencyOf(BuildContext context) {
    final theme = context.dependOnInheritedWidgetOfExactType<KzTheme>();
    assert(theme != null, 'No KzTheme found. Wrap the app in KzThemeScope.');
    return theme!.reduceTransparency;
  }

  @override
  bool updateShouldNotify(KzTheme oldWidget) =>
      data != oldWidget.data ||
      reduceTransparency != oldWidget.reduceTransparency;
}
