import 'package:flutter/widgets.dart';

/// The only file in `lib/` that may contain hex color literals.
///
/// Two flat modes, no gradients and no blur: `ink` (dark, on true black) and
/// `paper` (light), in neutral grays. Surfaces separate from the background
/// by fill; only controls carry a stroke.
abstract final class KzPalette {
  // Ink (dark): neutral grays, R = G = B.
  static const inkBg = Color(0xFF000000);
  static const inkPanel = Color(0xFF141414);
  static const inkMass = Color(0xFF222222);
  static const inkLine = Color(0xFF4A4A4A);
  static const inkInput = Color(0xFF707070);
  static const inkFaint = Color(0xFF909090);
  static const inkText = Color(0xFFEDEDED);

  // Paper (light): neutral grays, R = G = B.
  static const paperBg = Color(0xFFF5F5F5);
  static const paperElevated = Color(0xFFFFFFFF);
  static const paperPanel = Color(0xFFECECEC);
  static const paperMass = Color(0xFFE0E0E0);
  static const paperHover = Color(0xFFE6E6E6);
  static const paperLine = Color(0xFFBDBDBD);
  static const paperInput = Color(0xFF7A7A7A);
  static const paperDim = Color(0xFF555555);
  static const paperText = Color(0xFF111111);
  static const white = Color(0xFFFFFFFF);

  // Signal red accent: reads as text on its background and carries white
  // text on top of it (AA both ways).
  static const signalRedDark = Color(0xFFE22B33);
  static const signalRedLight = Color(0xFFC8102E);
  static const signalSelectionDark = Color(0xFF4A1C1F);
  static const signalSelectionLight = Color(0xFFF6D4D7);

  // Semantic.
  static const criticalDark = Color(0xFFF0625C);
  static const criticalLight = Color(0xFFB5271F);
  static const successDark = Color(0xFF5FD08B);
  static const successLight = Color(0xFF177A42);
  static const warningDark = Color(0xFFF2C14E);
  static const warningLight = Color(0xFF8A5A00);
}
