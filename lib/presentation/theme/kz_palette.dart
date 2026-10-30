import 'package:flutter/widgets.dart';

/// The only file in `lib/` that may contain hex color literals.
///
/// Two flat modes, no gradients: `ink` (dark) and `paper` (light), with
/// slightly warm neutrals.
abstract final class KzPalette {
  // Ink (dark).
  static const inkBg = Color(0xFF17171A);
  static const inkPanel = Color(0xFF1E1E22);
  static const inkMass = Color(0xFF26262B);
  static const inkLine = Color(0xFF35353D);
  static const inkInput = Color(0xFF706F77);
  static const inkFaint = Color(0xFF908F96);
  static const inkText = Color(0xFFEAE8EE);

  // Paper (light).
  static const paperBg = Color(0xFFEFECE5);
  static const paperElevated = Color(0xFFF5F3EE);
  static const paperPanel = Color(0xFFE7E3DA);
  static const paperMass = Color(0xFFDDD8CC);
  static const paperHover = Color(0xFFE2DED4);
  static const paperLine = Color(0xFFCBC5B6);
  static const paperInput = Color(0xFF7D796A);
  static const paperDim = Color(0xFF55534A);
  static const paperText = Color(0xFF15140F);
  static const white = Color(0xFFFFFFFF);

  // KZ Copper accent.
  static const copperDark = Color(0xFFD9905F);
  static const copperLight = Color(0xFF9A5226);
  static const copperSelectionDark = Color(0xFF4F392C);
  static const copperSelectionLight = Color(0xFFEBDBD1);

  // Semantic.
  static const criticalDark = Color(0xFFF0625C);
  static const criticalLight = Color(0xFFB5271F);
  static const successDark = Color(0xFF5FD08B);
  static const successLight = Color(0xFF177A42);
  static const warningDark = Color(0xFFF2C14E);
  static const warningLight = Color(0xFF8A5A00);

  // Glass, only for surfaces that float over scrolling content (alpha baked in).
  static const glassSubtleDark = Color(0x14FFFFFF);
  static const glassPanelDark = Color(0x991E1E22);
  static const glassChromeDark = Color(0xB826262B);
  static const glassBorderDark = Color(0x1AFFFFFF);
  static const glassHighlightDark = Color(0x0FFFFFFF);
  static const glassSubtleLight = Color(0x8CFFFFFF);
  static const glassPanelLight = Color(0x9EF5F3EE);
  static const glassChromeLight = Color(0xCCF5F3EE);
  static const glassBorderLight = Color(0xB3FFFFFF);
  static const glassHighlightLight = Color(0xE6FFFFFF);

  // Shadows.
  static const shadowMdDark = Color(0x66000000);
  static const shadowLgDark = Color(0x80000000);
  static const shadowMdLight = Color(0x140B0D0F);
  static const shadowLgLight = Color(0x1F0B0D0F);
}
