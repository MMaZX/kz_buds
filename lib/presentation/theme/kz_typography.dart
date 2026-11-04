import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Inter Display type scale (closest open alternative to SF Pro Display). Colors are applied by the theme, not here.
class KzTypography {
  const KzTypography();

  static const family = 'InterDisplay';

  static const _tabular = [FontFeature.tabularFigures()];

  TextStyle get numeralXl => const TextStyle(
    fontFamily: family,
    fontSize: 64,
    fontWeight: FontWeight.w300,
    height: 1,
    letterSpacing: -1.6,
    fontFeatures: _tabular,
  );

  TextStyle get numeralL => const TextStyle(
    fontFamily: family,
    fontSize: 40,
    fontWeight: FontWeight.w300,
    height: 1.05,
    letterSpacing: -0.8,
    fontFeatures: _tabular,
  );

  TextStyle get h1 => _style(28, FontWeight.w600, 1.15, -0.42);
  TextStyle get h2 => _style(22, FontWeight.w600, 1.2, -0.22);
  TextStyle get title => _style(17, FontWeight.w600, 1.3, -0.09);
  TextStyle get body => _style(15, FontWeight.w400, 1.45, 0);
  TextStyle get bodyStrong => _style(15, FontWeight.w500, 1.45, 0);
  TextStyle get label => _style(13, FontWeight.w500, 1.3, 0.07);
  TextStyle get caption => _style(12, FontWeight.w400, 1.35, 0.12);

  /// Render uppercase; the case is applied by the widget, not the style.
  TextStyle get overline => _style(11, FontWeight.w600, 1.2, 0.88);

  TextStyle _style(
    double size,
    FontWeight weight,
    double height,
    double letterSpacing,
  ) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: weight,
    height: height,
    letterSpacing: letterSpacing,
  );

  ShadTextTheme toShadTextTheme() => ShadTextTheme(
    family: family,
    h1: h1,
    h2: h2,
    h3: title,
    h4: title,
    p: body,
    lead: body,
    large: title,
    small: label,
    muted: caption,
  );
}
