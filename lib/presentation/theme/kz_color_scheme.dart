import 'package:shadcn_ui/shadcn_ui.dart';

import 'kz_palette.dart';

abstract final class KzColorKeys {
  static const brand = 'brand';
  static const brandForeground = 'brandForeground';
  static const success = 'success';
  static const warning = 'warning';
  static const batteryOk = 'batteryOk';
  static const batteryCritical = 'batteryCritical';
  static const batteryTrack = 'batteryTrack';
}

/// Maps the KZ palette onto the shadcn tokens. The accent lives in `ring` and
/// `custom`, never in `accent`, which shadcn uses as the hover surface.
class KzColorScheme extends ShadColorScheme {
  const KzColorScheme.dark()
    : super(
        background: KzPalette.ink950,
        foreground: KzPalette.paper,
        card: KzPalette.ink900,
        cardForeground: KzPalette.paper,
        popover: KzPalette.ink850,
        popoverForeground: KzPalette.paper,
        primary: KzPalette.paper,
        primaryForeground: KzPalette.ink950,
        secondary: KzPalette.ink800,
        secondaryForeground: KzPalette.paper,
        muted: KzPalette.ink900,
        mutedForeground: KzPalette.ink350,
        accent: KzPalette.ink700,
        accentForeground: KzPalette.paper,
        destructive: KzPalette.criticalDark,
        destructiveForeground: KzPalette.ink950,
        border: KzPalette.ink750,
        input: KzPalette.ink500,
        ring: KzPalette.copperDark,
        selection: KzPalette.copperSelectionDark,
        custom: const {
          KzColorKeys.brand: KzPalette.copperDark,
          KzColorKeys.brandForeground: KzPalette.ink950,
          KzColorKeys.success: KzPalette.successDark,
          KzColorKeys.warning: KzPalette.warningDark,
          KzColorKeys.batteryOk: KzPalette.paper,
          KzColorKeys.batteryCritical: KzPalette.criticalDark,
          KzColorKeys.batteryTrack: KzPalette.ink850,
        },
      );

  const KzColorScheme.light()
    : super(
        background: KzPalette.mist50,
        foreground: KzPalette.ink,
        card: KzPalette.white,
        cardForeground: KzPalette.ink,
        popover: KzPalette.white,
        popoverForeground: KzPalette.ink,
        primary: KzPalette.ink,
        primaryForeground: KzPalette.white,
        secondary: KzPalette.mist100,
        secondaryForeground: KzPalette.ink,
        muted: KzPalette.mist100,
        mutedForeground: KzPalette.mist600,
        accent: KzPalette.mist120,
        accentForeground: KzPalette.ink,
        destructive: KzPalette.criticalLight,
        destructiveForeground: KzPalette.white,
        border: KzPalette.mist150,
        input: KzPalette.mist400,
        ring: KzPalette.copperLight,
        selection: KzPalette.copperSelectionLight,
        custom: const {
          KzColorKeys.brand: KzPalette.copperLight,
          KzColorKeys.brandForeground: KzPalette.white,
          KzColorKeys.success: KzPalette.successLight,
          KzColorKeys.warning: KzPalette.warningLight,
          KzColorKeys.batteryOk: KzPalette.ink,
          KzColorKeys.batteryCritical: KzPalette.criticalLight,
          KzColorKeys.batteryTrack: KzPalette.mist150,
        },
      );
}
