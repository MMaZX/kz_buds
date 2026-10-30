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
        background: KzPalette.inkBg,
        foreground: KzPalette.inkText,
        card: KzPalette.inkPanel,
        cardForeground: KzPalette.inkText,
        popover: KzPalette.inkMass,
        popoverForeground: KzPalette.inkText,
        primary: KzPalette.inkText,
        primaryForeground: KzPalette.inkBg,
        secondary: KzPalette.inkMass,
        secondaryForeground: KzPalette.inkText,
        muted: KzPalette.inkPanel,
        mutedForeground: KzPalette.inkFaint,
        accent: KzPalette.inkMass,
        accentForeground: KzPalette.inkText,
        destructive: KzPalette.criticalDark,
        destructiveForeground: KzPalette.inkBg,
        border: KzPalette.inkLine,
        input: KzPalette.inkInput,
        ring: KzPalette.copperDark,
        selection: KzPalette.copperSelectionDark,
        custom: const {
          KzColorKeys.brand: KzPalette.copperDark,
          KzColorKeys.brandForeground: KzPalette.inkBg,
          KzColorKeys.success: KzPalette.successDark,
          KzColorKeys.warning: KzPalette.warningDark,
          KzColorKeys.batteryOk: KzPalette.inkText,
          KzColorKeys.batteryCritical: KzPalette.criticalDark,
          KzColorKeys.batteryTrack: KzPalette.inkMass,
        },
      );

  const KzColorScheme.light()
    : super(
        background: KzPalette.paperBg,
        foreground: KzPalette.paperText,
        card: KzPalette.paperPanel,
        cardForeground: KzPalette.paperText,
        popover: KzPalette.paperElevated,
        popoverForeground: KzPalette.paperText,
        primary: KzPalette.paperText,
        primaryForeground: KzPalette.paperBg,
        secondary: KzPalette.paperMass,
        secondaryForeground: KzPalette.paperText,
        muted: KzPalette.paperPanel,
        mutedForeground: KzPalette.paperDim,
        accent: KzPalette.paperHover,
        accentForeground: KzPalette.paperText,
        destructive: KzPalette.criticalLight,
        destructiveForeground: KzPalette.white,
        border: KzPalette.paperLine,
        input: KzPalette.paperInput,
        ring: KzPalette.copperLight,
        selection: KzPalette.copperSelectionLight,
        custom: const {
          KzColorKeys.brand: KzPalette.copperLight,
          KzColorKeys.brandForeground: KzPalette.white,
          KzColorKeys.success: KzPalette.successLight,
          KzColorKeys.warning: KzPalette.warningLight,
          KzColorKeys.batteryOk: KzPalette.paperText,
          KzColorKeys.batteryCritical: KzPalette.criticalLight,
          KzColorKeys.batteryTrack: KzPalette.paperLine,
        },
      );
}
