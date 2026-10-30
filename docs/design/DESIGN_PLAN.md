# KZ Buds Design System Plan

Status: proposal, not implemented. Date: 2026-10-29.
Scope: Phase 1 visual system (PLAN.md section 6). Presentation layer only, under `lib/presentation/`.
Constraints: AGENTS.md rule 9 (`widgets.dart` only, `Scaffold` the only Material widget), `shadcn_ui` ^0.57.3,
Riverpod ^3.4.3, Inter, dark + light modes, an original palette.

## Decisions (2026-10-29, user)

Supersede the recommendations in sections 1, 3.1, 9 and 11 where they differ. Tracked in `odd/tasks/design-system.md`.

1. Accent: **Signal Red** (`#FF4D3D` dark, `#D22A1E` light), not Copper. Glows are tinted from the accent. Critical battery and destructive actions always carry an icon and label (S13).
2. Healthy battery: neutral.
3. Dot-matrix numerals (Doto): yes.
4. Earbuds artwork: a `Placeholder` widget for now; renders come at the end.
5. Theme options: system, light, dark. Default: system.

Legend: **VERIFIED** means checked in source or on pub.dev during this research. **UNVERIFIED** means not checked
here; a spec or spike in section 10 covers it.

---

## 0. References actually reviewed

I opened all three images. Where they disagree with the written brief, the images win.

| File | Content | Corrections to the brief |
|---|---|---|
| `eaff17c2…5b3.webp` | Aerium: one composite image with **three** screens (home, device detail, area control). It is not two crops. | The screens are **neutral graphite** (sampled `#2B2B2B` to `#2D2D2D` at the top, `#161A1E` at the bottom). The cool slate (`#2E363A`) belongs to the presentation backdrop, not the app. Copper appears **only in the product render** (the fan ring); the UI has no copper at all. Fan-level chips (Low/Med/High/Ultra) are **dark filled pills**, not outlined. Only the room-filter chips are outlined. In the bottom nav pill, the selected item is a **lighter translucent pill with icon + label**, not solid white. The ON toggle is a pill holding an "ON" label and a white knob with a power glyph. |
| `original-c7c0…8b8.webp` | Icon sheet | Background sampled `#EFF1F5` (the brief said `#EEF0F4`). White tiles with a corner radius of about 22% of the tile. Strokes are about 1.5 px on a 24 px grid; at the rendered size they look like 2 px. The second ear glyph has a deeper inner curl, so it could mean "ear + ring" or an earring, and the meaning is ambiguous. Low-battery fill sampled at `#E87265` (close to the brief's `#E5736F`). Full battery is a solid ink fill. |
| `original-bad4…046.webp` | Nothing Ear (1) app | Matches the brief, with one fix: the **red dot is on the earbud hardware**, not in the UI. The UI itself is pure black (`#010609`), with dot-matrix type, short green bars (`#5AAC65`) on a dark track, and large `#1A1C1E` circular buttons with dot-matrix uppercase labels. |

What we take from them, as ideas only: a near-monochrome surface where the "primary" is ink or paper; one warm metallic
note; big light numerals; pill chips; circular icon buttons; a floating nav pill; glass that appears only where
something sits on a rich backdrop; a product-as-hero layout; dot-matrix type as an industrial signature.
BitChord (GPLv3) remains inspiration only. Nothing was copied from it or from the screenshots.

---

## 1. Primary and accent color

### Decision: neutral primary + one copper accent

- **Primary is neutral**: paper `#ECEEF1` on dark, ink `#14171C` on light. In every reference, the strongest
  call-to-action is a white pill on dark (Aerium "All"/"Off"), or the hardware itself (Nothing). A neutral primary keeps the
  UI calm, puts the earbuds in the hero role, and never competes with battery and error semantics.
- **Accent is a separate hue, "KZ Copper"**, used sparingly: the focus ring, the active ANC mode indicator, the slider
  active track, the selected EQ preset dot, and the ambient glow. It is never used for buttons, large fills, or anything
  that carries meaning.
- Copper sits in shadcn's `ring` and in `custom['brand']`, **not** in shadcn's `accent` token. In shadcn, `accent` is
  the hover/highlight surface for ghost buttons and menu items, so it stays neutral.

Contrast was computed with the WCAG 2.x relative-luminance formula (script in the scratchpad, not committed):

| Option | Dark hex | on bg `#0E1014` | on card `#181B20` | Ink `#0E1014` on it | Light hex | on bg `#EEF0F3` | on card `#FFFFFF` | White on it |
|---|---|---|---|---|---|---|---|---|
| **Recommended: KZ Copper** | `#D9905F` | 7.35 | 6.66 | 7.35 | `#A25A2C` | 4.56 | 5.20 | 5.20 |
| Alt 1: Ion Blue | `#7FA8FF` | 8.11 | n/c | 8.11 | `#2D5BD0` | 5.23 | n/c | 5.97 |
| Alt 2: Signal Red | `#FF4D3D` | 5.79 | n/c | 5.79 | `#D22A1E` | 4.50 | n/c | 5.13 |
| Primary (neutral) | `#ECEEF1` | 16.38 | 14.85 | 16.38 | `#14171C` | 15.73 | 17.96 | 17.96 |

(n/c = not computed.)

How each option coexists with the semantic colors:

- **Copper (recommended)**: battery uses only ink/paper (ok) and red (critical), and charging uses green. Copper hue (about 24°)
  sits between red (about 3°) and amber (about 42°). Amber is therefore **removed from battery states** and reserved for
  rare non-battery warnings (firmware/OTA caution), where it always comes with an icon and text. Copper never conveys
  state, so a color-vision-deficient user loses nothing. This option gives a warm metal note over graphite, in the spirit
  of the Aerium product render. It is distinctive for an audio product without being a stock shadcn color.
- **Ion Blue**: zero hue collision with green/amber/red, and the safest choice. It is also more generic and "tech default".
- **Signal Red**: the Nothing-like single dot. It collides with destructive and critical battery, which then need shape
  cues everywhere. Not recommended.

---

## 2. Token set

### 2.1 Neutral scale "Graphite" (slightly cool, hue about 215°)

| Step | Hex | Main roles |
|---|---|---|
| 0 | `#FFFFFF` | light card, light popover |
| 40 | `#ECEEF1` | dark foreground ("paper") |
| 50 | `#EEF0F3` | light background |
| 100 | `#E3E6EB` | light secondary/muted |
| 120 | `#E6E9EE` | light accent (hover) |
| 150 | `#DADEE4` | light border |
| 300 | `#A9AFB8` | disabled text (dark) |
| 350 | `#959CA6` | dark muted foreground |
| 400 | `#8D949E` | light input border |
| 500 | `#666D77` | dark input border |
| 600 | `#5C636D` | light muted foreground |
| 700 | `#3A4049` | dark strong border |
| 750 | `#2C3138` | dark border |
| 780 | `#2A2F36` | dark accent (hover) |
| 800 | `#22262C` | dark popover/secondary |
| 850 | `#181B20` | dark card/muted |
| 900 | `#14171C` | light foreground ("ink"), dark glass chrome tint |
| 950 | `#0E1014` | dark background |
| 1000 | `#08090B` | dark ambient floor |

Copper scale: `300 #E9C3A6`, `400 #D9905F`, `500 #C9835A` (glow), `700 #A25A2C`, `900 #5A3D2B`.

### 2.2 `ShadColorScheme` mapping

VERIFIED against `lib/src/theme/color_scheme/base.dart` in 0.57.3. The required fields are the same 20 as in 0.43.4.
The only addition is the optional `Map<String, Color> custom` (lerped, and merged by key in `merge`), plus the
`canMerge` flag. The constructor is `const`, so `KzColorScheme` can have `const` `.dark()` and `.light()` constructors,
like `CustomThemeCatppuccin` does.

| Field | Dark | Light | Contrast notes (computed) |
|---|---|---|---|
| background | `#0E1014` | `#EEF0F3` | |
| foreground | `#ECEEF1` | `#14171C` | 16.38 / 15.73 |
| card | `#181B20` | `#FFFFFF` | fg on card: 14.85 / 17.96 |
| cardForeground | `#ECEEF1` | `#14171C` | |
| popover | `#22262C` | `#FFFFFF` | |
| popoverForeground | `#ECEEF1` | `#14171C` | |
| primary | `#ECEEF1` | `#14171C` | |
| primaryForeground | `#0E1014` | `#FFFFFF` | 16.38 / 17.96 |
| secondary | `#22262C` | `#E3E6EB` | fg on secondary: 13.08 / 14.36 |
| secondaryForeground | `#ECEEF1` | `#14171C` | |
| muted | `#181B20` | `#E3E6EB` | |
| mutedForeground | `#959CA6` | `#5C636D` | dark: 6.88 bg, 6.23 card, 5.49 popover. light: 5.32 bg, 6.07 card, 4.85 muted |
| accent (hover surface) | `#2A2F36` | `#E6E9EE` | |
| accentForeground | `#ECEEF1` | `#14171C` | |
| destructive | `#F0625C` | `#C8312B` | 5.99 on bg / 4.68 on bg |
| destructiveForeground | `#0E1014` | `#FFFFFF` | 5.99 / 5.34 |
| border (decorative hairline) | `#2C3138` | `#DADEE4` | decorative, exempt from 1.4.11 |
| input (field boundary) | `#666D77` | `#8D949E` | 3.30 on dark card / 3.06 on white card (fields sit on cards) |
| ring | `#D9905F` | `#A25A2C` | 7.35 / 4.56 |
| selection | `#4F392C` | `#EBDBD1` | fg on selection: 9.25 / 13.33 |

`custom` keys (all read through `KzColors`, never by string in widgets):

| Key | Dark | Light | Use |
|---|---|---|---|
| `brand` | `#D9905F` | `#A25A2C` | the accent |
| `brandForeground` | `#0E1014` | `#FFFFFF` | |
| `success` | `#5FD08B` | `#177A42` | charging, connected. 9.87 / 4.72 on bg |
| `warning` | `#F2C14E` | `#8A5A00` | OTA/firmware caution only. 11.35 / 5.19 |
| `batteryOk` | = foreground | = foreground | level 21-100 |
| `batteryCritical` | `#F0625C` | `#C8312B` | level 0-20 (5.43 on dark card, 5.34 on white) |
| `batteryCharging` | = success | = success | with a bolt glyph, never by color alone |
| `batteryTrack` | `#2C3138` | `#DADEE4` | empty part of bars |

Battery thresholds: `critical <= 20`, otherwise ok. A `null` level is **hidden** (AGENTS rule 4), never drawn as 0.

### 2.3 Glass tints and shadows

| Token | Dark | Light |
|---|---|---|
| glass.subtle fill | `#FFFFFF` @ 8% | `#FFFFFF` @ 55% |
| glass.panel fill | `#181B20` @ 60% | `#FFFFFF` @ 62% |
| glass.chrome fill | `#14171C` @ 72% | `#FFFFFF` @ 80% |
| glass border | `#FFFFFF` @ 10% | `#FFFFFF` @ 70% |
| glass top highlight (1 px inner) | `#FFFFFF` @ 6% | `#FFFFFF` @ 90% |
| shadow.sm | `0 1 2` `#000000` @ 30% | `0 1 2` `#14171C` @ 6% |
| shadow.md | `0 8 24` `#000000` @ 40% | `0 8 24` `#14171C` @ 8% |
| shadow.lg (nav, sheet) | `0 16 40` `#000000` @ 50% | `0 16 40` `#14171C` @ 12% |

Text on glass, computed against the **worst-case backdrop** (brightest ambient point dark `#372F2D`, darkest light `#D8DDE5`):

- Dark panel composite `#242325`: fg 13.46, muted 5.65, copper 6.04, red 4.92, green 8.11.
- Dark chrome composite `#1E1E21`: fg 14.31, muted 6.01.
- Light panel composite `#F0F2F5`: fg 16.02, muted 5.41, copper 4.64, red 4.76, green 4.80.
- Rule: **muted text is not allowed on glass.subtle** (muted on that composite is 3.93). Chips use foreground text.

---

## 3. Glass and blur system

### 3.1 What is behind the glass

We have no album art or photos. The backdrop is an **ambient field**, painted once per theme and brightness:

- Dark: a vertical gradient `#1B1F25` (top) to `#08090B` (bottom), plus two radial glows: copper `#C9835A` @ 16% at
  top-right (radius 0.9 of the shortest side) and steel `#5B6B80` @ 25% at bottom-left (radius 1.1).
- Light: a vertical gradient `#F6F7F9` to `#E3E6EB`, plus glows: copper `#E7B38F` @ 35% top-right and steel `#BFCADB` @ 45%
  bottom-left.
- Above it sits the **earbuds hero**: an original line/volume illustration of a generic TWS pair, drawn with
  `CustomPainter` (paths with gradients), L and R separate so each can dim when that bud is unknown or disconnected.
  Per-model renders can come later through capability profiles, if licensing allows.
- State hint (optional, subtle): ANC on tightens the glows by 15%; ambient mode widens them by 15%. Animation lasts
  480 ms and is skipped when `MediaQuery.disableAnimationsOf` is true.
- `KzAmbientBackground` wraps its painter in a `RepaintBoundary`. It is static unless the ANC state changes, so the blur
  samples a cached layer.

### 3.2 Levels

| Level | sigma (x = y) | Reduced tier | Allowed on | Fallback (reduce transparency) |
|---|---|---|---|---|
| G1 subtle | 12 | 8 | chips and the ON pill when they sit directly on the ambient field or the hero | `secondary` fill + `border` |
| G2 panel | 24 | 16 | the home hero card (battery + quick ANC), the "Find my buds" panel | `card` fill + `border` + shadow.md |
| G3 chrome | 32 | 16 | floating bottom nav pill, bottom sheets, dialogs over the ambient field | `popover` fill + `border` + shadow.lg |

**Blur is not allowed on**: list rows, settings rows, EQ bands, cards inside scroll views, popovers, tooltips, toasts,
and selects (all opaque `popover`). Glass is never placed on glass (no nested `BackdropFilter`). At most
**two** blurred regions are visible at once (for example hero + nav). Glass appears only over the ambient field, never over
plain `background`, because there it adds cost and no visible effect.

### 3.3 Implementation (widgets and `dart:ui` only)

- `KzGlass(level:, borderRadius:, child:)` = `ClipRRect` > `BackdropFilter(filter: ImageFilter.blur(sigmaX:, sigmaY:,
  tileMode: TileMode.clamp))` > `DecoratedBox` (fill, 1 px border, top highlight via a `LinearGradient` foreground).
- VERIFIED in the pinned SDK 3.47.9 (`widgets/basic.dart`): `BackdropGroup` and `BackdropFilter.grouped` exist. When nav
  and sheet blur together, they share one backdrop read through `BackdropGroup` at the page root.
- VERIFIED in `dart:ui` (`painting.dart`): `ImageFilter.blur` takes an optional `bounds` ("bounded blur", which stops edge
  bleed). Use it for the nav pill once the spike confirms it renders on all three platforms (**UNVERIFIED** per platform).
- Reduce transparency: Flutter has **no** `reduceTransparency` flag in `MediaQueryData` (VERIFIED: the flags are
  `highContrast`, `disableAnimations`, `boldText`, `invertColors`, `accessibleNavigation`, `onOffSwitchLabels`). We
  therefore use an app setting `reduceTransparency` (default off), forced **on** when `MediaQuery.highContrastOf` is
  true. `KzGlass` then renders the fallback column of 3.2 with no `BackdropFilter` in the tree.

### 3.4 Performance risks and mitigations

| Platform | Risk | Mitigation |
|---|---|---|
| Android low-end | Every `BackdropFilter` reads back and blurs the area under it, every frame it repaints. Large sigma over a full-width nav during scroll is the classic jank source. | The ambient layer is in a `RepaintBoundary` and blurred regions are not inside scrollables (the nav floats above a scroll view, and the content scrolls under it). Use the reduced sigma tier when `View.devicePixelRatio >= 3` and the screen is small. A manual setting "Reduce transparency" is available. Profile with `fvm flutter run --profile` on a low-end device (target: no frame over 16 ms on the home page). |
| Linux | Renderer/driver variance (software GL in VMs). **UNVERIFIED** whether Impeller is the default on Linux in 3.47.9. | Spike task T1 checks it. If blur looks wrong or is slow, default `reduceTransparency` to on for Linux. |
| Windows | Same as Linux; with a high-DPI 4K window, the blur area is large. | Cap the blurred area: the nav pill max width is 560 logical px, and sheets max 640. |
| All | Theme switching animates every color, and glass repaints. | `ShadAnimatedTheme` with 200 ms; the ambient painter cross-fades instead of re-blurring per tick. |

---

## 4. Typography

### 4.1 Bundling Inter

- **Asset bundle, not `google_fonts`.** VERIFIED on pub.dev: `google_fonts` 9.0.0 (2026-09-28) depends on `http`,
  `path_provider` and **`material_ui`** (the "official Flutter Material UI Library"). It also fetches fonts at
  runtime by default. That adds Material and network access to an offline Bluetooth tool, so we reject it.
- Source: `rsms/inter` release **v4.1** (2024-11-16, VERIFIED via the GitHub API), license **SIL OFL 1.1** (VERIFIED in
  `LICENSE.txt`). Ship the license as `assets/fonts/inter/LICENSE.txt` and register it with `LicenseRegistry`, so the
  About screen lists it.
- Files (static, deterministic on every platform): `Inter-Regular.ttf` (412 KB), `Inter-Medium.ttf` (417 KB),
  `Inter-SemiBold.ttf` (420 KB), `InterDisplay-Light.ttf` (413 KB, for the big numerals). About 1.66 MB in total.
  Optional later optimization: the single `InterVariable.ttf` (880 KB) with `FontVariation('wght', …)`. **UNVERIFIED**
  whether `FontWeight` alone drives the `wght` axis on all three platforms, so the statics come first.
- shadcn wiring: `ShadThemeData(textTheme: ShadTextTheme(family: 'Inter', …))`. VERIFIED: the shadcn default is
  `packages/shadcn_ui/Geist`, and `family` overrides it.

### 4.2 Scale

Letter spacing is in logical px (Flutter uses absolute values) = size × em.

| Token | Family | Size | Weight | Line height | Tracking | Use |
|---|---|---|---|---|---|---|
| `numeralXl` | Inter Display | 64 | 300 | 1.00 | -1.6 (-2.5%) | hero battery %, tabular |
| `numeralL` | Inter Display | 40 | 300 | 1.05 | -0.8 | L/R battery in hero |
| `h1` | Inter | 28 | 600 | 1.15 | -0.42 | page title |
| `h2` | Inter | 22 | 600 | 1.20 | -0.22 | section title |
| `title` | Inter | 17 | 600 | 1.30 | -0.09 | card title |
| `body` | Inter | 15 | 400 | 1.45 | 0 | default `DefaultTextStyle` |
| `bodyStrong` | Inter | 15 | 500 | 1.45 | 0 | row labels |
| `label` | Inter | 13 | 500 | 1.30 | +0.07 | buttons, chips |
| `caption` | Inter | 12 | 400 | 1.35 | +0.12 | meta, units |
| `overline` | Inter | 11 | 600 | 1.20 | +0.88 (8%), UPPERCASE | section labels, circular-button labels |

- Tabular numerals: every numeric style adds `fontFeatures: [FontFeature.tabularFigures()]` (`tnum`), so `72%` to `100%`
  does not shift. Inter documents `tnum` support (**UNVERIFIED** here because fontTools was unavailable; T1 checks it with
  a width-equality widget test).
- Mapping to `ShadTextTheme`: h1 = `h1`, h2 = `h2`, h3 = `title`, h4 = `title`, p = `body`, large = `title`, small = `label`,
  muted = `caption` + mutedForeground, lead = `body` + mutedForeground.
- Respect `MediaQuery.textScalerOf`; clamp hero numerals at 1.3× (`TextScaler.clamp(maxScaleFactor: 1.3)`) so the hero
  stays in one piece.

### 4.3 Optional signature face: Doto (dot-matrix)

- **Doto** by Óliver Lalan, Google Fonts, license **OFL** (VERIFIED in `google/fonts/ofl/doto/METADATA.pb`).
  Variable axes `ROND` 0-100 and `wght` 100-900. File `Doto[ROND,wght].ttf`, 457 KB.
- Use: hero numerals and the device name **only** at ≥28 px, with `FontVariation('wght', 600)` and `('ROND', 100)`.
  Never for body text (readability). If the `%` glyph is missing (**UNVERIFIED**), render the unit in Inter.
- Behind a theme flag `signatureNumerals` (default on, see Q3). When off, the hero uses `numeralXl` in Inter Display.
- Alternatives checked (both OFL): `DotGothic16` (pixel, CJK-oriented) and `Sixtyfour` (retro CRT). Doto fits best.

---

## 5. Shape, spacing, stroke, motion

| Radii | Value | Use |
|---|---|---|
| `xs` | 6 | badges, focus ring inner |
| `sm` | 10 | inputs, small buttons |
| `md` | 14 | default `ShadThemeData.radius`, buttons |
| `lg` | 20 | cards, icon tiles |
| `xl` | 28 | hero card, sheets (top corners) |
| `pill` | 999 | chips, ON pill, nav pill, circular buttons |

Spacing (4-pt grid): `2, 4, 8, 12, 16, 20, 24, 32, 40, 56`. Page padding: 20 (compact), 32 (medium/expanded). Gap between
cards: 12. Touch target min 44×44 (circular buttons 56, compact icon buttons 44).

Breakpoints: compact < 600, medium 600-1023, expanded ≥ 1024 (desktop shows a side rail instead of the nav pill, and a
two-column home).

Stroke: hairline border 1; icon stroke 1.5 (default) and 2.0 (selected/emphasis); focus ring 2 with offset 2; battery
bar height 4, radius pill.

Motion (`KzMotion`):

| Token | Duration | Curve | Use |
|---|---|---|---|
| `press` | 100 ms | `Curves.easeOut` | scale 1.0 to 0.97, plus a 6% foreground overlay |
| `fast` | 150 ms | `Curves.easeOutCubic` | chip select, toggle knob |
| `base` | 200 ms | `Curves.easeInOutCubic` | theme switch, tab change |
| `slow` | 320 ms | `Cubic(0.2, 0, 0, 1)` | sheets, page transitions (fade + 8 px rise) |
| `ambient` | 480 ms | `Curves.easeInOutSine` | glow change on ANC mode |

All durations become `Duration.zero` when `MediaQuery.disableAnimationsOf(context)` is true. Disabled state = 40% opacity
(the same as the shadcn default `disabledOpacity`, kept explicit).

---

## 6. Icon library

Verified on pub.dev (API + archive inspection) on 2026-10-29. "Material" = whether the package's own `lib/` imports
`material.dart` or `cupertino.dart`. Rule 9 governs **our** imports, so a package that imports Material is allowed;
this is noted for awareness.

| Package | Version | Published | License | Icons (approx.) | Format / stroke control | Material in pkg |
|---|---|---|---|---|---|---|
| **hugeicons** | 1.2.0 | 2026-09-18 | MIT | 6,063 stroke-rounded | path data to SVG via `flutter_svg`; **`strokeWidth` per icon** (default 1.5) | yes (`HugeIcon` widget imports material + cupertino) |
| lucide_icons_flutter | 3.1.25 resolved (4.0.1 latest; shadcn pins `<4.0.0`) | 2026-10-21 (4.0.1) | MIT | about 2,137 base, weights 100-600 | font | only `test_icons.dart` |
| phosphor_flutter | 2.1.0 | 2024-05-10 | MIT | 1,512 × 6 weights | font, thin/light/regular/bold/fill/duotone | yes (`PhosphorIcon` widget) |
| flutter_tabler_icons | 1.43.0 | 2024-09-28 | MIT | 5,717 (with filled) | font, fixed 2 px | no |
| iconsax_flutter | 1.0.1 | 2025-06-07 | BSD-3 | about 1,000 (+ copies) | font | no |
| solar_icons | 0.2.0 | 2026-09-28 | BSD-3 | 1,248 | font | no |
| remixicon | 4.9.3 | 2026-04-04 | MIT | 3,230 line+fill | font | no |

Glyph coverage for our vocabulary (✓ = exact name found in source):

| Need | hugeicons | lucide 3.1.25 | phosphor | tabler |
|---|---|---|---|---|
| ear | ✓ `ear` | ✓ `ear` | ✓ `ear` | ✓ `ear` |
| earbuds | ✓ `airpod01..03` | ✗ (headphones only) | ✗ (headphones only) | ✓ `device_airpods`, `_case` |
| touch / tap | ✓ `tap01..08`, `touch01..10` | ~ `pointer`, `hand` | ✓ `handTap` | ✓ `hand_click` |
| gamepad | ✓ `gameController03`, `gamepad` | ✓ `gamepad2` | ✓ `gameController` | ✓ `device_gamepad_2` |
| waveform | ✓ `audioWave01`, `audioWaveform` | ✓ `audioWaveform` | ✓ `waveform` | ~ `wave_sine` |
| battery levels | ✓ empty/low/medium/full/charging | ✓ low/medium/full/warning/charging | ✓ empty/low/medium/high/full/charging | ✓ 1-4 + filled |
| trash / edit / help | ✓ `delete02` / `edit02` / `helpSquare` | ✓ `trash2` / `squarePen` / `circleHelp` | ✓ | ✓ |
| update (circle-up) | ✓ `circleArrowUp01` | ✓ `circleArrowUp` | ✓ `arrowCircleUp` | ✓ `circle_arrow_up` |
| menu / back / close | ✓ `menu01` / `arrowLeft01` / `cancel01` | ✓ | ✓ `list` / `arrowLeft` / `x` | ✓ |
| bluetooth, sliders | ✓ | ✓ | ✓ | ✓ |

**Recommendation: `hugeicons` 1.2.0.**

- It is the only candidate with every domain glyph (ear, earbuds, tap, gamepad, waveform, battery).
- Its stroke-rounded style is closest to the icon sheet.
- `strokeWidth` is adjustable (1.5 default, 2.0 for emphasis), it is MIT, and it was published recently.
- It reads `IconTheme.of(context)` first, so our `IconTheme` drives color and opacity. Its last fallback is
  `Theme.of(context).colorScheme.onSurface`; without a Material `Theme`, that resolves to `ThemeData.fallback()` and
  does not crash.
- Cost: icons are built as SVG strings and parsed by `flutter_svg` once per widget `State` (cached in `_cachedSvg`), so
  each screen should show few icons. `flutter_svg` 2.3.2 is already in the graph through `shadcn_ui`.

Notes and fallbacks:

- shadcn components draw their internal glyphs (checkbox, select chevrons) with Lucide. The weights differ slightly
  (Lucide 2/24, Hugeicons 1.5/24) and are acceptable at 16 px. **Runner-up:** `flutter_tabler_icons` (no Material, has
  airpods and case), with only fixed 2 px strokes and its last publish in 2024-09.
- Custom `CustomPainter` glyphs, which no package provides: `KzBatteryGlyph` (continuous fill proportional to the level,
  with critical color and charging bolt), `KzEarbudGlyph` (L/R mirrored, original), and `KzAncRings` (off/ANC/ambient
  as 0/2/3 concentric arcs).
- Widgets never reference `HugeIcons.*` directly; only `KzIcons` does (see 8). Switching libraries then touches one file.

---

## 7. shadcn_ui under our own `WidgetsApp` (rule 9)

### 7.1 What `ShadApp` provides (VERIFIED in `lib/src/app.dart`, 0.57.3)

| Provided by `ShadApp` | Needed by components? | Our replacement |
|---|---|---|
| `ScrollConfiguration(ShadScrollBehavior)`; it uses Material `Scrollbar` (desktop) and `CupertinoScrollbar` (Apple) | no | `KzScrollBehavior extends ScrollBehavior` with `RawScrollbar` on desktop |
| `HeroControllerScope(HeroController())` | only for `Hero` | add it if the earbuds hero animates between routes |
| `ShadAnimatedTheme(data, curve)` providing `ShadTheme` | **yes**: `ShadTheme.of` throws without it (used by about 40 component files) | `ShadAnimatedTheme` in `WidgetsApp.builder` |
| `ShadMouseAreaSurface` | no (`MouseAreaRegistry.maybeOf` is nullable) | include it anyway (hover regions) |
| `ShadMouseCursorProvider` | only `ShadResizable` (`context.read<ShadMouseCursorController>`) | include it (cheap) |
| Material `AnimatedTheme(ThemeData)` | **no** component reads Material `Theme`. VERIFIED: in `lib/src`, only `app.dart` imports `material.dart`/`cupertino.dart` | omit |
| `WidgetsApp` with delegates `GlobalShadLocalizations`, `GlobalMaterialLocalizations`, `GlobalCupertinoLocalizations`, `GlobalWidgetsLocalizations` | only `ShadLocalizations` (input, date/time picker, keyboard toolbar), and it **falls back to English** if missing | pass `GlobalShadLocalizations.delegate` (exported by `shadcn_ui`); no `flutter_localizations` dependency for now |
| `pageRouteBuilder` defaults to `MaterialPageRoute` | n/a | our existing `PageRouteBuilder` with a `slow` fade+rise |
| `ShadAppBuilder` in `builder`: `ShadToaster(ShadSonner(child))` + `ColoredBox(background)` | toasts (`ShadToaster.of`/`ShadSonner.of` throw without them) | `ShadAppBuilder(child: navigator)` (public widget, usable as-is) |
| `ThemeMode` (a Material enum) in its API | n/a | our own `KzThemePreference { system, light, dark }` |

### 7.2 Verdict

**Source-verified as feasible; one runtime spike (T1) before it becomes a spec.** The composition is:

```
WidgetsApp(builder: (ctx, nav) =>
  KzThemeScope            // resolves brightness from MediaQuery + provider
   > ShadAnimatedTheme    // ShadTheme for all shad widgets
   > KzTheme              // our InheritedWidget: glass, typography, metrics, semantic colors
   > ShadMouseAreaSurface > ShadMouseCursorProvider
   > ScrollConfiguration(KzScrollBehavior)
   > DefaultTextStyle(KzTypography.body) > IconTheme(size 20, foreground)
   > ShadAppBuilder(backgroundColor: transparent, child: nav)   // toaster + sonner
)
```

Gotcha found in source (VERIFIED, `material/scaffold.dart` lines 3236-3237 and `material/material.dart` lines 476-477):
`Scaffold` wraps its body in a `Material` that installs
`AnimatedDefaultTextStyle(Theme.of(context).textTheme.bodyMedium)`. Without a Material `Theme`, that is
`ThemeData.fallback()`, so **text inside a `Scaffold` would lose our style** and its background would default to the
fallback scaffold color. Recommendation: build pages with our own `KzPage` (SafeArea + Stack + keyboard insets), and use
`Scaffold` only when it is really needed, with `backgroundColor: Color(0x00000000)` plus a re-applied
`DefaultTextStyle`.

### 7.3 Spike T1 (steps and success criteria)

1. In a widget test, pump the composition above with `KzTheme.dark()`. Pump `ShadButton`, `ShadSwitch`, `ShadSlider`,
   `ShadInput`, `ShadSelect` (open it), `ShadPopover` (open it), `ShadSheet`, and `ShadDialog`, and show a toast and a sonner.
2. Assert that there are no exceptions, that the `ShadTheme.of(context).colorScheme.background` equals `#0E1014`, and that
   the popover/select overlays render (they need the Navigator `Overlay`, which `WidgetsApp` provides).
3. Repeat inside a `Scaffold` and assert that `DefaultTextStyle.of(body)` is still `KzTypography.body` (expected to fail
   without the re-wrap; that documents the gotcha).
4. Run `fvm flutter run -d linux` and `-d windows`/Android (manual) with a `ShadInput`: check text selection handles,
   desktop hover cursors, and blur rendering of `KzGlass` with and without `bounds`.
5. Tabular-figure check: `Text('11%')` and `Text('88%')` in `numeralXl` have equal width.
6. A `RotatedBox(quarterTurns: 3, child: ShadSlider)` works for the vertical EQ bands (VERIFIED: `ShadSlider` has no axis
   option).

Success: steps 1, 2, 5 and 6 pass in CI; step 3 documents the gotcha; step 4 has notes per platform in the feature log.

---

## 8. Code architecture (`lib/presentation/theme/`)

Presentation only. The domain stays untouched, and theme files import `widgets.dart`, `dart:ui`, `shadcn_ui`, and `hugeicons`
(only in `kz_icons.dart`).

| File | Public API | Responsibility |
|---|---|---|
| `kz_palette.dart` | `KzPalette` (`static const graphite950 = Color(0xFF0E1014)`, …), `KzPalette.copper*` | **The only file with hex literals.** |
| `kz_color_scheme.dart` | `KzColorScheme extends ShadColorScheme` with `const .dark()`/`.light()`; `KzColorKeys` (custom map keys) | mapping table 2.2 |
| `kz_colors.dart` | `KzColors` (brand, success, warning, `battery(int level) -> Color`, batteryTrack, glow colors) | typed semantic access; reads `custom` |
| `kz_typography.dart` | `KzTypography` (styles of 4.2), `toShadTextTheme()` | Inter + optional Doto |
| `kz_metrics.dart` | `KzRadii`, `KzSpace`, `KzStroke`, `KzBreakpoints` | section 5 |
| `kz_motion.dart` | `KzMotion.of(context)` (respects disableAnimations) | durations and curves |
| `kz_glass.dart` | `KzGlassLevel {subtle, panel, chrome}`, `KzGlassStyle`, `KzGlass` widget | section 3 + fallback |
| `kz_ambient_background.dart` | `KzAmbientBackground({AncMode? mode})` | painter + RepaintBoundary |
| `kz_icons.dart` | `KzIcons` (semantic names: `ear`, `earbuds`, `tap`, `gameMode`, `eq`, `batteryLow`, …), `KzIcon(KzIconData, {size, emphasized})` | the only importer of `hugeicons` |
| `kz_theme.dart` | `KzThemeData` (colors, typography, glass, metrics), `KzThemeData.light()/dark()`, `KzThemeData.toShad() -> ShadThemeData`, `KzTheme` InheritedWidget with `KzTheme.of(context)` | aggregate |
| `kz_theme_scope.dart` | `KzThemeScope` (the `WidgetsApp.builder` composition of 7.2), `KzScrollBehavior` | app shell wiring |

Providers (`lib/presentation/providers/theme_providers.dart`, Riverpod 3 `Notifier`):

```dart
enum KzThemePreference { system, light, dark }
final themePreferenceProvider =
    NotifierProvider<ThemePreferenceNotifier, KzThemePreference>(ThemePreferenceNotifier.new);
final visualSettingsProvider =
    NotifierProvider<VisualSettingsNotifier, KzVisualSettings>(VisualSettingsNotifier.new);
// KzVisualSettings { bool reduceTransparency = false; bool signatureNumerals = true; }
```

Persistence comes later through a port (`SettingsPort` in `domain/ports`, adapter in `data/`). The notifiers start in memory.
`KzThemeScope` resolves `system` with `MediaQuery.platformBrightnessOf(context)`. That is why it lives in `builder`, below
the `MediaQuery` that `WidgetsApp` creates.

How widgets consume tokens, with no hex values:

- `final t = KzTheme.of(context);` then `t.colors.battery(level)`, `t.text.numeralXl`, `t.space.s16`, `KzGlass(level: KzGlassLevel.panel)`.
- shad widgets read `ShadTheme.of(context)` themselves.
- Guard tests (see S2): no `Color(0x` outside `kz_palette.dart`; no `package:flutter/material.dart` import except
  `show Scaffold;`; no `package:flutter/cupertino.dart`; no `HugeIcons.` outside `kz_icons.dart`.

Shared components (`lib/presentation/widgets/`): `KzPage`, `KzChip` (pill; selected = primary fill, unselected = G1 or
outlined), `KzPowerPill` (label + knob, the ON toggle), `KzRoundButton` (56 px circle, icon + optional overline label),
`KzBatteryIndicator` (label + numeral + 4 px bar, hides itself on `null`), `KzNavPill` (G3, 4 items max), `KzSection`
(overline header + opaque card), `KzListRow`.

---

## 9. Phase 1 screen vocabulary

Every block appears only if its capability exists (rule 3). A `null` battery level hides its indicator (rule 4).

```
DEVICE HOME (compact)                       ANC / AMBIENT (sheet G3 or page)
┌──────────────────────────────┐            ┌──────────────────────────────┐
│ ‹menu›   Castor Pro      (●) │ (●)=link   │ Noise control                │
│                              │            │  (  OFF  ) ( ANC ) (AMBIENT) │ KzChip row
│      [ earbuds hero art ]    │ ambient    │      [ KzAncRings large ]    │
│   L 72%      ▔▔▔▔   R 100%   │ field      │  Ambient level  ──●──────    │ ShadSlider
│ ┌──────────── G2 ──────────┐ │            └──────────────────────────────┘
│ │  72%  numeralXl  Case 40% │ │ hero card
│ │  ( ANC )(Ambient)( Off ) │ │ G1 chips    EQ
│ └──────────────────────────┘ │            ┌──────────────────────────────┐
│ ( HEAR ) ( TOUCH ) ( GAME )  │ KzRound-   │ (Flat)(Bass)(Vocal)(Custom)  │ chips
│                              │ Buttons    │  ┃  ┃  ┃  ┃  ┃  ┃  ┃  ┃  ┃  ┃ │ vertical bands,
│ ╭──── nav pill G3 ────╮      │ by caps    │ 31 62 125 … 16k   dB scale   │ opaque card
│ │ Home  EQ  Touch  ⚙ │      │            │ [ Reset ]          [ Save ]  │ ShadButton
└──────────────────────────────┘            └──────────────────────────────┘
```

- **Home**: the hero shows L/R from `KzBatteryIndicator`, and Case only if non-null. If both buds are null, the hero shows the
  link state instead. Disconnected: the hero art at 40% opacity + a primary `ShadButton` "Reconnect".
- **Button remap** (Touch): opaque `KzSection` per bud (L/R tabs via `KzChip`), rows "Single tap / Double tap / Triple
  tap / Long press" → `ShadSelect` of actions. The `tap` icon leads each row.
- **Find my buds**: G2 panel with L and R `KzRoundButton` (play sound), a destructive-styled "Stop" while playing, and a
  `warning` caption: "Remove the earbuds before playing a sound."
- **Settings**: opaque sections: Appearance (System/Light/Dark chips, "Reduce transparency" `ShadSwitch`, "Dot-matrix
  numerals" `ShadSwitch`), Device (name, forget device = destructive), About link.
- **About**: app version, firmware (if reported), licenses (Inter OFL, Doto OFL, Hugeicons MIT, shadcn_ui MIT), repo link.
- **Desktop (≥1024)**: a side rail replaces the nav pill; the home is two columns (hero left, controls right).

---

## 10. ODD breakdown (feeds `odd/tasks/design-system.md`)

### Specs

- **S1** The app root is `WidgetsApp`. `KzThemeScope` provides `ShadTheme`, `KzTheme`, toaster and sonner without `ShadApp`.
  All shad components listed in 7.3 step 1 pump with no exception.
- **S2** Guard tests fail if any file under `lib/` imports `package:flutter/material.dart` without `show Scaffold;`, imports
  `package:flutter/cupertino.dart`, contains `Color(0x` outside `lib/presentation/theme/kz_palette.dart`, or references
  `HugeIcons.` outside `kz_icons.dart`.
- **S3** `KzColorScheme.dark()` and `.light()` equal table 2.2 field by field (for example dark `background == Color(0xFF0E1014)`,
  light `ring == Color(0xFFA25A2C)`).
- **S4** Contrast unit tests (computed in Dart with `Color.computeLuminance`): foreground, mutedForeground, and destructive on
  background/card ≥ 4.5; `input` on card ≥ 3.0; ring on background ≥ 3.0, in both modes.
- **S5** `KzColors.battery(level)` returns `batteryCritical` for 0-20 and `batteryOk` for 21-100. `KzBatteryIndicator`
  renders nothing for `null`.
- **S6** `KzThemePreference.system` follows `platformBrightness`; `light`/`dark` override it. Switching animates in 200 ms
  (`KzMotion.base`), or instantly when `disableAnimations` is true.
- **S7** Typography: Inter assets are registered under family `'Inter'`; `KzTypography.body` is 15/400/1.45. Numeric styles
  include `FontFeature.tabularFigures()`. `'11%'` and `'88%'` have equal width in `numeralXl`.
- **S8** `KzGlass` uses sigma 12/24/32 for subtle/panel/chrome. With `reduceTransparency` or `highContrast` on, no
  `BackdropFilter` exists under it, and the fill equals the fallback token.
- **S9** `KzIcons` exposes the semantic set (ear, earbuds, tap, gameMode, eq, battery*, trash, edit, help, update, menu,
  back, close, bluetooth) with stroke 1.5, or 2.0 when `emphasized`.
- **S10** Home hides L, R and Case indicators whose level is `null`, and hides ANC chips without `Capability.anc`.
- **S11** Each Phase 1 screen (home, ANC, EQ, remap, find, settings, about) renders in dark and light with `FakeEarbudsAdapter`
  for: all capabilities, no ANC, case null, disconnected.

### Tasks

| ID | Specs | Work | Est. lines | Risk | Commit |
|---|---|---|---|---|---|
| T1 | S1 | Spike of 7.3 as a widget test + `KzThemeScope` draft; notes in the log | ~180 | item 6 (runtime behavior not yet pinned) | `test(theme): spike shadcn under WidgetsApp` |
| T2 | S2, S3, S4 | `kz_palette`, `kz_color_scheme`, `kz_colors`, guard + contrast tests | ~320 | none | `feat(theme): add KZ palette and color scheme` |
| T3 | S7 | Inter assets + license registration, `kz_typography` | ~160 + fonts | item 5 (assets in pubspec) | `feat(theme): bundle Inter and type scale` |
| T4 | S1, S6 | `kz_metrics`, `kz_motion`, `kz_theme`, `kz_theme_scope`, theme providers, `main.dart` wiring | ~350 | none | `feat(theme): theme scope and preference provider` |
| T5 | S8 | `kz_glass`, `kz_ambient_background`, golden tests both modes | ~300 | item 6 (visual, mitigated with goldens) | `feat(theme): glass levels and ambient background` |
| T6 | S9, S5 | add `hugeicons` 1.2.0, `kz_icons`, `KzBatteryGlyph`, `KzEarbudGlyph`, `KzAncRings` | ~330 | item 5 (new dependency) | `feat(theme): icon set and custom glyphs` |
| T7 | S5 | components: `KzPage`, `KzChip`, `KzPowerPill`, `KzRoundButton`, `KzBatteryIndicator`, `KzNavPill`, `KzSection`, `KzListRow` + widget tests | ~400 | none | `feat(ui): core component kit` |
| T8 | S10, S11 | device home redesign + tests | ~300 | none | `feat(ui): device home` |
| T9 | S11 | ANC + EQ screens + tests | ~380 | none | `feat(ui): ANC and EQ screens` |
| T10 | S11 | remap, find, settings, about + tests | ~400 | none | `feat(ui): remap, find, settings, about` |
| T11 | S7 | optional Doto signature numerals behind `signatureNumerals` | ~120 + font | item 5 | `feat(theme): optional dot-matrix numerals` |

Order: T1 → T2 → T3 → T4 → T5/T6 (parallelizable, disjoint files) → T7 → T8 → T9/T10 → T11. Total of about 3,240 authored
lines, so the `ask-on-risk` delivery strategy applies (slice by the commits above).

---

## 11. Open questions (one decision each)

1. **Accent**: KZ Copper (`#D9905F` dark, `#A25A2C` light), Ion Blue, or Signal Red? *Recommendation: Copper.*
2. **Battery "ok" color**: neutral ink/paper (as in the icon sheet) or green bars (as in Nothing)? *Recommendation: neutral;
   green stays reserved for charging/connected.*
3. **Dot-matrix numerals (Doto)**: on by default for the hero, off, or not shipped? *Recommendation: on by default, hero
   only, with a settings toggle.*
4. **Earbuds hero art**: one original generic vector pair for all models, or per-model renders (which need licensed
   images)? *Recommendation: generic vector now, per-model later via capability profiles.*
5. **Default theme**: follow the system, or dark-first like the references? *Recommendation: follow the system; dark
   is the design reference for review.*
