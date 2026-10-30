# Feature: design-system
Objective: custom dark/light shadcn_ui theme (KZ Copper accent, Inter, glass), then the Phase 1 screens. Branch: main (work-unit commits). Delivery: ask-on-risk. Runner: `fvm flutter test`, `fvm flutter analyze`.
Plan: docs/design/DESIGN_PLAN.md (Copper accent, as recommended there).

## Specs
- S1 The app root is `WidgetsApp`. `KzThemeScope` provides `ShadTheme`, `KzTheme`, toaster and sonner without `ShadApp`. Rule 9: "NO USAREMOS MATERIAL O CUPERTINO solo widgets.dart"; "scafold si son widgets permitidos" (`Scaffold` is the only allowed Material widget).
- S2 Guard tests fail if any file under `lib/` imports `package:flutter/material.dart` without `show Scaffold;`, imports `package:flutter/cupertino.dart`, contains `Color(0x` outside `lib/presentation/theme/kz_palette.dart`, or references `HugeIcons.` outside `kz_icons.dart`.
- S3 `KzColorScheme.dark()` and `.light()` equal DESIGN_PLAN.md 2.2 field by field (accent: "lo recomendado" = KZ Copper, dark `#D9905F`, light `#A25A2C` for `ring` and `custom['brand']`; for example dark `background == Color(0xFF0E1014)`, light `ring == Color(0xFFA25A2C)`).
- S4 Contrast unit tests (`Color.computeLuminance`): foreground, mutedForeground and destructive on background and card >= 4.5; `input` on card >= 3.0; `ring` on background >= 3.0, in both modes.
- S5 Battery: "neutro". `critical` (0-20) uses `batteryCritical`; 21-100 uses `batteryOk` (= foreground). A `null` level renders nothing (AGENTS rule 4).
- S6 Theme preference has three options, "segun sistema, claro y oscuro", default system. `system` follows `platformBrightness`; switching animates 200 ms, instantly when `disableAnimations`.
- S7 Typography: Inter bundled as assets under family `'Inter'`, `KzTypography.body` is 15/400/1.45; numeric styles use tabular figures. "doto": the hero numerals use Doto (OFL, dot-matrix) behind `signatureNumerals` (default on, home hero only, settings toggle).
- S8 `KzGlass` sigma 12/24/32 (subtle/panel/chrome). With `reduceTransparency` or `highContrast` there is no `BackdropFilter` and the fill equals the fallback token.
- S9 `KzIcons` wraps `hugeicons` 1.2.0 (stroke 1.5, 2.0 when emphasized). "no necesariamente de lucide": widgets never name `HugeIcons.*`.
- S10 Home hides L, R and Case indicators whose level is `null`, and hides ANC chips without `Capability.anc`.
- S11 Every Phase 1 screen (home, ANC, EQ, remap, find, settings, about) renders in dark and light with `FakeEarbudsAdapter` for: all capabilities, no ANC, case null, disconnected.
- S12 Earbuds artwork: "haremos render pero al final, aqui no lo aplicaremos por el momento lo reemplazaremos por un widget Placeholder". The hero uses the widgets `Placeholder`; no earbud painter or `KzEarbudGlyph` in this feature.
- S13 The accent never conveys state: it appears only in the focus ring, the active ANC indicator, slider tracks and the ambient glow. Critical battery and destructive actions use the red tokens and always carry an icon and a text label.

## Tasks
- [x] T1 S1 inline spike: shadcn_ui under WidgetsApp (test/spike/shadcn_under_widgets_app_test.dart, findings in L5). Commit: `test(theme): spike shadcn under WidgetsApp`
- [ ] T2 S2 S3 S4 inline: palette, color scheme, colors, guard + contrast tests. Commit: -
- [ ] T3 S7 inline: Inter assets + license, type scale. Commit: -
- [ ] T4 S1 S6 inline: metrics, motion, theme, scope, providers, main wiring. Commit: -
- [ ] T5 S8 inline: glass + ambient background (+ goldens). Commit: -
- [ ] T6 S9 S5 inline: hugeicons, `KzIcons`, battery glyph, ANC rings. Commit: -
- [ ] T7 S5 S13 inline: component kit (page, chip, power pill, round button, battery indicator, nav pill, section, row). Commit: -
- [ ] T8 S10 S11 S12 inline: device home with `Placeholder` hero. Commit: -
- [ ] T9 S11 inline: ANC + EQ screens. Commit: -
- [ ] T10 S11 inline: remap, find, settings, about. Commit: -
- [ ] T11 S7 inline: Doto signature numerals. Commit: -

Route: all inline; no Writer trigger (units are sequential and share theme files). Risk: T3, T6, T11 item 5 (assets/dependency), T1 and T5 item 6.

## Log
- L1 (2026-10-29, user, original request, verbatim): "ok inserta la ultima version de shadcn_flutter, riverpod y esta app tendra dos modos, un modo oscuro y claro y va a tener un diseño custom, osea un tema custom. /home/fulanito/development/gr-manager-flutter/lib/main.dart este proyecto tiene shadcn de una version anterior, pero la forma que crea temas como el catputchin es la base para nosotros crear nuestro tema personalizado, unico claro y oscuro, pero el color primario... que color primario usamos?? [images] este diseño me agrada, claro no todo es blurred, [images] esto estoooooo es lo que necesito realmente un blurred con un tema asi, [images] los iconos deben ser no necesariamente de lucide, seria bueno conseguir una libreria de iconos creo. [image] quiero un tema minimalista, conceptual y sobre todo con una paleta clean minimal. la fuente que usaremos sería Inter te he pasado 4 imagenes armemos algo increible si gustas lanza en un subagente con opus y arma el plan de diseño, y ese será el primer odd. y dame un artifact para entender que es lo que haremos"
- L2 (2026-10-29, user, answers, verbatim): "1. ok usaremos \"Signal Red\" 2. neutro 3. doto 4. haremos render pero al final, aqui no lo aplicaremos por el momento lo reemplazaremos por un widget Placeholder :D 5. seguir el sitema tenemos 3 opciones: segun sistema, claro y oscuro."
- L4 (2026-10-29, user, correction, verbatim): "entonces en vez de signal red usemos lo recomendado a este tema: [Image #6]" (the Nothing Ear image). Read as: use the recommended accent, KZ Copper. Reopens S3 and S13 only; L2 answer 1 is superseded.
- L3 Analysis: "shadcn_flutter" in L1 read as `shadcn_ui` (^0.57.3), the package gr-manager uses; already added. Signal Red was not the plan's recommendation (Copper was); S13 records the mitigation for its collision with critical/destructive.
- L5 T1 result (2026-10-29): under our own `WidgetsApp` (no `ShadApp`, no Material `Theme`), composed as `ShadAnimatedTheme` > `DefaultTextStyle` > `ShadAppBuilder`, with `GlobalShadLocalizations.delegate`: ShadButton, ShadSwitch, ShadSlider, ShadInput and ShadSelect render; select, popover, dialog, sheet and toast open with no exception; `ShadTheme.of` resolves. 3 tests pass, `fvm flutter analyze` clean. Not yet covered: plan 7.3 step 3 (Scaffold text-style gotcha, known from source only), step 4 (selection handles, hover, blur on Linux/Windows/Android: manual), step 5 (tabular figures, needs Inter from T3), step 6 (rotated vertical slider, T9).
- L6 Note: the Engram mirror `odd/design-system/tasks` was first saved as a summary; it must hold the full document, refresh it after each task.
