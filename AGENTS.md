# AGENTS.md — KZ Buds

Rules for any human or AI agent working in this repository.
The roadmap lives in [PLAN.md](PLAN.md); read it first.

## Project in one paragraph

KZ Buds is a cross-platform Flutter app (Android, Linux, Windows first; iOS/macOS later)
to control **KZ true-wireless (TWS) earbuds over Bluetooth**. Primary test device: **KZ Castor Pro**.
USB DAC support is **out of scope** for now.

## Toolchain

- Flutter is managed with **FVM**. The version is pinned in `.fvmrc` (currently 3.47.9, Dart 3.13.7).
- Always run `fvm flutter ...` and `fvm dart ...`, never the global `flutter` / `dart`.
- Do not bump the pinned version without being asked.
- Verify a package's current version on pub.dev before adding it. Never guess versions.

## Architecture: hexagonal (ports and adapters)

```
lib/
├── domain/          Pure Dart. No Flutter, no Riverpod, no Bluetooth packages.
│   ├── entities/    Earbuds, BatteryStatus, AncMode, ...
│   ├── capabilities/  Capability enum + helpers
│   └── ports/       Abstract interfaces (EarbudsPort, ...)
├── data/            Adapters that implement the ports.
│   ├── fake/        FakeEarbudsAdapter (simulated data, used for UI work)
│   ├── ble/         Real BLE adapter(s) and the protocol codec
│   └── protocol/    Pure-Dart packet encode/decode (JieLi RCSP), unit-testable
├── presentation/    Flutter UI + Riverpod providers.
│   ├── providers/   Dependency injection and state
│   ├── pages/
│   ├── widgets/
│   └── theme/
└── main.dart
```

Dependency rule: `presentation -> domain <- data`. The domain never imports from the other two.
`presentation` never imports concrete adapters except in the single composition root (provider overrides).

## Rules

1. **Domain stays pure.** No `package:flutter`, `flutter_riverpod`, or BLE packages under `lib/domain/`.
2. **Riverpod lives in presentation only.** Providers wire ports to adapters and expose state to widgets.
3. **Capabilities, not models.** The UI shows a feature only if the connected device reports the capability.
   Never branch on a model name in a widget.
4. **Unknown is `null`.** If a device does not report a value (for example the charging case battery),
   model it as nullable and hide it in the UI. Never invent or default it.
5. **One adapter per transport/platform concern.** Platform quirks stay inside the adapter.
6. **Protocol code is pure Dart and tested.** Packet parsing/building has unit tests with captured byte fixtures.
7. **UI first with the fake adapter.** Every screen must work with `FakeEarbudsAdapter` before real BLE is wired.
8. **No hardware calls in widgets.** Widgets read providers; they never touch Bluetooth.
9. **No Material, no Cupertino, with one exception.** The UI uses only `package:flutter/widgets.dart` (and lower layers
   such as `rendering`, `painting`, `animation`). Never import `package:flutter/material.dart` or
   `package:flutter/cupertino.dart`, except to use the allowlisted widgets below. The app root is `WidgetsApp`.
   All visuals are our own design system.
   - **Allowlisted Material widgets:** `Scaffold` only. Import it narrowly:
     `import 'package:flutter/material.dart' show Scaffold;`. Adding a widget to this list needs explicit approval.
   - Third-party design packages (such as `shadcn_ui`) are fine as long as our own code follows this rule.

## Reverse engineering and legal

- Only reverse engineer **our own devices**. Document findings in `docs/protocol/` with the raw bytes.
- The original Java app (`../app-android-original`) is a **reference for understanding**, not code to copy.
  Its license is unverified; do not copy it into this repo until that is resolved.
- BitChord (the visual inspiration) is GPLv3. **Take design ideas only. Copy no code, assets, or layouts pixel for pixel.**
- Before using JieLi SDK material, check its license.

## Code style

- Follow `analysis_options.yaml`; `fvm flutter analyze` must pass with no issues.
- Format with `fvm dart format .`.
- Prefer immutable classes, `final`, and `const` constructors.
- Code, comments, identifiers, UI strings, and docs are in **English**.
- Keep comments rare; explain why, not what.

## Testing

- Domain and protocol: unit tests (`fvm flutter test`).
- UI: widget tests using the fake adapter via provider overrides.
- A bug fix starts with a failing test when a deterministic test is possible.
- Run `fvm flutter analyze` and `fvm flutter test` before declaring work done.

## Git

- Conventional Commits (`feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`).
- **No AI attribution** and no `Co-Authored-By` lines in commits or PRs.
- Small, reviewable commits (about 400 changed lines at most). Tests and docs go with the behavior.
- Never commit, push, or open PRs without being asked.

## Do not

- Do not add USB/DAC code yet.
- Do not add a backend/server until PLAN.md says so.
- Do not add dependencies without a reason tied to a plan phase.
- Do not commit captured traffic that contains personal data (MAC addresses, device names): redact it first.
