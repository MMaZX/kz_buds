import 'package:flutter/widgets.dart';

/// The only file in `lib/` that may contain hex color literals.
abstract final class KzPalette {
  // Dark surfaces, sampled from a near-black companion-app reference.
  static const ink950 = Color(0xFF050709);
  static const ink900 = Color(0xFF0E1012);
  static const ink850 = Color(0xFF17191B);
  static const ink800 = Color(0xFF191B1D);
  static const ink750 = Color(0xFF1F2326);
  static const ink700 = Color(0xFF212427);
  static const ink500 = Color(0xFF5E646A);
  static const ink350 = Color(0xFF9AA0A6);
  static const paper = Color(0xFFF2F4F5);

  // Light surfaces.
  static const mist50 = Color(0xFFEFF2F1);
  static const mist100 = Color(0xFFE3E7E6);
  static const mist120 = Color(0xFFE6EAE9);
  static const mist150 = Color(0xFFD9DEDD);
  static const mist400 = Color(0xFF8A9190);
  static const mist600 = Color(0xFF5A6160);
  static const white = Color(0xFFFFFFFF);
  static const ink = Color(0xFF0B0D0F);

  // KZ Copper accent.
  static const copperDark = Color(0xFFD9905F);
  static const copperLight = Color(0xFFA25A2C);
  static const copperSelectionDark = Color(0xFF4F392C);
  static const copperSelectionLight = Color(0xFFEBDBD1);

  // Semantic.
  static const criticalDark = Color(0xFFF0625C);
  static const criticalLight = Color(0xFFC8312B);
  static const successDark = Color(0xFF5FD08B);
  static const successLight = Color(0xFF177A42);
  static const warningDark = Color(0xFFF2C14E);
  static const warningLight = Color(0xFF8A5A00);

  static const transparent = Color(0x00000000);

  // Glass fills, borders and highlights (alpha baked in).
  static const glassSubtleDark = Color(0x14FFFFFF);
  static const glassPanelDark = Color(0x990E1012);
  static const glassChromeDark = Color(0xB817191B);
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

  // Ambient background.
  static const ambientTopLight = Color(0xFFF7F9F8);
  static const ambientCopperGlowDark = Color(0x29C9835A);
  static const ambientSteelGlowDark = Color(0x405B6B80);
  static const ambientCopperGlowLight = Color(0x59E7B38F);
  static const ambientSteelGlowLight = Color(0x73BFCADB);
}
