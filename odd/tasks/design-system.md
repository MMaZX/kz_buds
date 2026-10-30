# Feature: design-system
Objective: custom dark/light shadcn_ui theme (Signal Red accent, Inter, glass), then the Phase 1 screens. Branch: main (work-unit commits). Delivery: ask-on-risk. Runner: `fvm flutter test`, `fvm flutter analyze`.
Plan: docs/design/DESIGN_PLAN.md (sections 1-3 use Copper values; Signal Red below supersedes them).

## Specs
- S1 The app root is `WidgetsApp`. `KzThemeScope` provides `ShadTheme`, `KzTheme`, toaster and sonner without `ShadApp`. Rule 9: "NO USAREMOS MATERIAL O CUPERTINO solo widgets.dart"; "scafold si son widgets permitidos" (`Scaffold` is the only allowed Material widget).
- S2 Guard tests fail if any file under `lib/` imports `package:flutter/material.dart` without `show Scaffold;`, imports `package:flutter/cupertino.dart`, contains `Color(0x` outside `lib/presentation/theme/kz_palette.dart`, or references `HugeIcons.` outside `kz_icons.dart`.
- S3 `KzColorScheme.dark()` and `.light()` follow DESIGN_PLAN.md 2.2, except the accent: "usaremos \"Signal Red\"" = dark `#FF4D3D`, light `#D22A1E` for `ring` and `custom['brand']`; `brandForeground` dark `#0E1014`, light `#FFFFFF`. `selection` is the accent mixed over the background (about 30% dark, 15% light). Values are pinned by S4 tests, adjust only with a Log entry.
- S4 Contrast unit tests (`Color.computeLuminance`): foreground, mutedForeground and destructive on background and card >= 4.5; `input` on card >= 3.0; `ring` on background >= 3.0, in both modes.
- S5 Battery: "neutro". `critical` (0-20) uses `batteryCritical`; 21-100 uses `batteryOk` (= foreground). A `null` level renders nothing (AGENTS rule 4).
- S6 Theme preference has three options, "segun sistema, claro y oscuro", default system. `system` follows `platformBrightness`; switching animates 200 ms, instantly when `disableAnimations`.
- S7 Typography: Inter bundled as assets under family `'Inter'`, `KzTypography.body` is 15/400/1.45; numeric styles use tabular figures. "doto": the hero numerals use Doto (OFL, dot-matrix) behind `signatureNumerals` (default on, home hero only, settings toggle).
- S8 `KzGlass` sigma 12/24/32 (subtle/panel/chrome). With `reduceTransparency` or `highContrast` there is no `BackdropFilter` and the fill equals the fallback token.
- S9 `KzIcons` wraps `hugeicons` 1.2.0 (stroke 1.5, 2.0 when emphasized). "no necesariamente de lucide": widgets never name `HugeIcons.*`.
- S10 Home hides L, R and Case indicators whose level is `null`, and hides ANC chips without `Capability.anc`.
- S11 Every Phase 1 screen (home, ANC, EQ, remap, find, settings, about) renders in dark and light with `FakeEarbudsAdapter` for: all capabilities, no ANC, case null, disconnected.
- S12 Earbuds artwork: "haremos render pero al final, aqui no lo aplicaremos por el momento lo reemplazaremos por un widget Placeholder". The hero uses the widgets `Placeholder`; no earbud painter or `KzEarbudGlyph` in this feature.
- S13 Signal Red collides with critical battery and destructive. Critical battery and destructive actions always carry an icon and a text label; the accent is never used to convey state (focus ring, active ANC indicator, slider track and glow only).

## Tasks
- [ ] T1 S1 inline spike: shadcn_ui under WidgetsApp (widget test, findings in Log). Commit: -
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
- L3 Analysis: "shadcn_flutter" in L1 read as `shadcn_ui` (^0.57.3), the package gr-manager uses; already added. Signal Red was not the plan's recommendation (Copper was); S13 records the mitigation for its collision with critical/destructive.
