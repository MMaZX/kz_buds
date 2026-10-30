import 'package:flutter/widgets.dart';

/// The only file in `lib/` that may contain hex color literals.
///
/// Two flat modes, no gradients: `ink` (dark) and `paper` (light), in neutral
/// grays.
abstract final class KzPalette {
  // Ink (dark): neutral grays, R = G = B.
  static const inkBg = Color(0xFF171717);
  static const inkPanel = Color(0xFF1E1E1E);
  static const inkMass = Color(0xFF262626);
  static const inkLine = Color(0xFF353535);
  static const inkGrid = Color(0xFF202020);
  static const inkInput = Color(0xFF707070);
  static const inkFaint = Color(0xFF909090);
  static const inkText = Color(0xFFEDEDED);

  // Paper (light): neutral grays, R = G = B.
  static const paperBg = Color(0xFFF5F5F5);
  static const paperElevated = Color(0xFFFFFFFF);
  static const paperPanel = Color(0xFFECECEC);
  static const paperMass = Color(0xFFE0E0E0);
  static const paperHover = Color(0xFFE6E6E6);
  static const paperLine = Color(0xFFCCCCCC);
  static const paperGrid = Color(0xFFE8E8E8);
  static const paperInput = Color(0xFF7A7A7A);
  static const paperDim = Color(0xFF555555);
  static const paperText = Color(0xFF111111);
  static const white = Color(0xFFFFFFFF);
  static const transparent = Color(0x00000000);

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
  static const glassPanelDark = Color(0x991E1E1E);
  static const glassChromeDark = Color(0xB8262626);
  static const glassBorderDark = Color(0x1AFFFFFF);
  static const glassHighlightDark = Color(0x0FFFFFFF);
  static const glassSubtleLight = Color(0x8CFFFFFF);
  static const glassPanelLight = Color(0x9EFFFFFF);
  static const glassChromeLight = Color(0xCCFFFFFF);
  static const glassBorderLight = Color(0xB3FFFFFF);
  static const glassHighlightLight = Color(0xE6FFFFFF);

  // Shadows.
  static const shadowMdDark = Color(0x66000000);
  static const shadowLgDark = Color(0x80000000);
  static const shadowMdLight = Color(0x140B0D0F);
  static const shadowLgLight = Color(0x1F0B0D0F);
}
