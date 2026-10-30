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
}
