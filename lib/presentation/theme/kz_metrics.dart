abstract final class KzRadii {
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 28;
  static const double pill = 999;
}

/// 4-pt grid.
abstract final class KzSpace {
  static const double s2 = 2;
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;
  static const double s40 = 40;
  static const double s56 = 56;
}

abstract final class KzStroke {
  static const double hairline = 1;
  static const double icon = 1.5;
  static const double iconEmphasis = 2;
  static const double focusRing = 2;
  static const double batteryBar = 4;
}

enum KzSizeClass { compact, medium, expanded }

abstract final class KzBreakpoints {
  static const double medium = 600;
  static const double expanded = 1024;

  static KzSizeClass sizeClassFor(double width) {
    if (width >= expanded) return KzSizeClass.expanded;
    if (width >= medium) return KzSizeClass.medium;
    return KzSizeClass.compact;
  }
}
