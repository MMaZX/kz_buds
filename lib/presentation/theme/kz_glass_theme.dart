import 'package:flutter/widgets.dart';

import 'kz_palette.dart';

enum KzGlassLevel { subtle, panel, chrome }

class KzGlassLevelStyle {
  const KzGlassLevelStyle({
    required this.fill,
    required this.sigma,
    required this.fallbackFill,
    this.fallbackShadows = const [],
  });

  final Color fill;
  final double sigma;

  /// Opaque fill used when transparency is reduced.
  final Color fallbackFill;
  final List<BoxShadow> fallbackShadows;
}

class KzGlassTheme {
  const KzGlassTheme({
    required this.border,
    required this.highlight,
    required this.subtle,
    required this.panel,
    required this.chrome,
  });

  const KzGlassTheme.dark()
    : this(
        border: KzPalette.glassBorderDark,
        highlight: KzPalette.glassHighlightDark,
        subtle: const KzGlassLevelStyle(
          fill: KzPalette.glassSubtleDark,
          sigma: 12,
          fallbackFill: KzPalette.ink800,
        ),
        panel: const KzGlassLevelStyle(
          fill: KzPalette.glassPanelDark,
          sigma: 24,
          fallbackFill: KzPalette.ink900,
          fallbackShadows: [
            BoxShadow(
              color: KzPalette.shadowMdDark,
              offset: Offset(0, 8),
              blurRadius: 24,
            ),
          ],
        ),
        chrome: const KzGlassLevelStyle(
          fill: KzPalette.glassChromeDark,
          sigma: 32,
          fallbackFill: KzPalette.ink850,
          fallbackShadows: [
            BoxShadow(
              color: KzPalette.shadowLgDark,
              offset: Offset(0, 16),
              blurRadius: 40,
            ),
          ],
        ),
      );

  const KzGlassTheme.light()
    : this(
        border: KzPalette.glassBorderLight,
        highlight: KzPalette.glassHighlightLight,
        subtle: const KzGlassLevelStyle(
          fill: KzPalette.glassSubtleLight,
          sigma: 12,
          fallbackFill: KzPalette.mist100,
        ),
        panel: const KzGlassLevelStyle(
          fill: KzPalette.glassPanelLight,
          sigma: 24,
          fallbackFill: KzPalette.white,
          fallbackShadows: [
            BoxShadow(
              color: KzPalette.shadowMdLight,
              offset: Offset(0, 8),
              blurRadius: 24,
            ),
          ],
        ),
        chrome: const KzGlassLevelStyle(
          fill: KzPalette.glassChromeLight,
          sigma: 32,
          fallbackFill: KzPalette.white,
          fallbackShadows: [
            BoxShadow(
              color: KzPalette.shadowLgLight,
              offset: Offset(0, 16),
              blurRadius: 40,
            ),
          ],
        ),
      );

  final Color border;
  final Color highlight;
  final KzGlassLevelStyle subtle;
  final KzGlassLevelStyle panel;
  final KzGlassLevelStyle chrome;

  KzGlassLevelStyle of(KzGlassLevel level) => switch (level) {
    KzGlassLevel.subtle => subtle,
    KzGlassLevel.panel => panel,
    KzGlassLevel.chrome => chrome,
  };
}

/// Colors of the ambient field that glass sits on.
class KzAmbientTheme {
  const KzAmbientTheme({
    required this.top,
    required this.bottom,
    required this.copperGlow,
    required this.steelGlow,
  });

  const KzAmbientTheme.dark()
    : this(
        top: KzPalette.ink850,
        bottom: KzPalette.ink950,
        copperGlow: KzPalette.ambientCopperGlowDark,
        steelGlow: KzPalette.ambientSteelGlowDark,
      );

  const KzAmbientTheme.light()
    : this(
        top: KzPalette.ambientTopLight,
        bottom: KzPalette.mist100,
        copperGlow: KzPalette.ambientCopperGlowLight,
        steelGlow: KzPalette.ambientSteelGlowLight,
      );

  final Color top;
  final Color bottom;
  final Color copperGlow;
  final Color steelGlow;
}
