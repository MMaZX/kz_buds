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
          fallbackFill: KzPalette.inkMass,
        ),
        panel: const KzGlassLevelStyle(
          fill: KzPalette.glassPanelDark,
          sigma: 24,
          fallbackFill: KzPalette.inkPanel,
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
          fallbackFill: KzPalette.inkMass,
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
          fallbackFill: KzPalette.paperMass,
        ),
        panel: const KzGlassLevelStyle(
          fill: KzPalette.glassPanelLight,
          sigma: 24,
          fallbackFill: KzPalette.paperPanel,
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
          fallbackFill: KzPalette.paperElevated,
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
