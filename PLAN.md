# PLAN.md — KZ Buds

## 1. Vision

An open-source, cross-platform control app for KZ true-wireless earbuds.
The existing Android app is a WebView with HTML on top of ~10k lines of Java and looks dated.
We want a real, modern native UI (inspired by the look and feel of BitChord) and a clean
architecture that lets the community add support for more KZ models.

Primary test device: **KZ Castor Pro**.

## 2. Scope

**In scope (now)**
- Bluetooth control of KZ wireless earbuds (TWS, earhooks).
- Android, Linux, Windows. iOS and macOS later, when a Mac is available.
- Show only the features each device actually supports.

**Out of scope (for now)**
- USB DAC control (`UsbDac.java` in the original app).
- A backend server. The "backend" is the earbuds themselves, over Bluetooth.
- Autoeq catalog and manuals sync (possible later, see Phase 6).

## 3. What we learned about the original app

Source: `../app-android-original` (read-only reference).

- UI is a WebView (`assets/www/index.html`) talking to Java through a JS bridge named `CarolNative`.
- `BleBridge.java` (~3100 lines) uses **two** Bluetooth transports:
  - BLE/GATT, with the JieLi service `0000ae00-0000-1000-8000-00805f9b34fb` (also `ae80`, `fe01`).
  - Bluetooth Classic SPP/RFCOMM (UUID `00001101-...`), with a reflection fallback.
- `JlProtocol.java` (~370 lines) holds the JieLi RCSP packet logic; `FwOta.java` handles firmware update.
- `KzCatalog.java` maps device names to feature flags (anc, ldac, aptx, game, jl).
  **The Castor Pro is not in it**, so we do not know what it exposes.
- Nothing in the original reads the **charging case battery**.
- The original states that firmware features only work "when the chip answers". We adopt the same idea as a core design rule.

## 4. Platform reality

| Capability | Android | Linux | Windows | iOS |
|---|---|---|---|---|
| BLE / GATT | Yes | Yes | Yes (needs a Windows-capable package) | Yes |
| Bluetooth Classic SPP | Yes | Hard, no mature Flutter plugin | Hard, no mature Flutter plugin | **No** (CoreBluetooth is BLE only; classic needs MFi) |

Consequences:
- Everything that works over **BLE** can reach all platforms.
- Anything that works **only over SPP** is Android-first (possibly a native `MethodChannel`).
- Whether the Castor Pro control channel is BLE, SPP, or both is **unknown**. Phase 2 answers it.

BLE package candidates (versions to be verified on pub.dev when added):
- `universal_ble`: Android, iOS, macOS, Windows, Linux, Web with one API. Known quirks: a delay needed in service discovery on Linux, MTU can only be read on Windows.
- `flutter_blue_plus`: Linux/Android/iOS/macOS; Windows needs a separate package.

## 5. Architecture

Hexagonal, as defined in [AGENTS.md](AGENTS.md).

Core port (sketch, not final):

```dart
abstract class EarbudsPort {
  Stream<ConnectionState> watchConnection();
  Future<Set<Capability>> capabilities();
  Stream<BatteryStatus> watchBattery();   // left, right, case (nullable)
  Future<void> setAncMode(AncMode mode);  // only if Capability.anc
  // ...grows with discovered capabilities
}
```

- `FakeEarbudsAdapter` first, `BleEarbudsAdapter` later, per-platform adapters only if needed.
- Riverpod provides the adapter (composition root) and exposes state to widgets.
- The UI is **capability driven**: a tile appears only if the capability exists.

## 6. Roadmap

### Phase 0 — Foundation (in progress)
- [x] Project created, Flutter 3.47.9 pinned with FVM.
- [ ] Android licenses accepted (`fvm flutter doctor --android-licenses`).
- [ ] `git init`, `.gitignore` review, first commit.
- [ ] Add dependencies verified on pub.dev: `flutter_riverpod` (+ generator if wanted).
- [ ] Create the `domain / data / presentation` skeleton.
- [ ] Strict `analysis_options.yaml`.

### Phase 1 — Design and UI with simulated data
- [ ] Study the BitChord look and feel (colors, spacing, motion) and define our own design tokens and theme. Original work only; BitChord is GPLv3.
- [ ] Screens: device home (battery for left, right, case), ANC / ambient control, EQ, button remapping, find my buds, settings, about.
- [ ] Responsive layouts: phone and desktop.
- [ ] `FakeEarbudsAdapter` with configurable capabilities to test every UI state (missing case battery, no ANC, disconnected).
- [ ] Widget tests with provider overrides.

### Phase 2 — Discover the Castor Pro (reverse engineering of our own device)
- [ ] nRF Connect: list GATT services and characteristics; note the services, and whether `ae00` is present.
- [ ] Android Bluetooth HCI snoop log while using the original app; analyze in Wireshark.
- [ ] Map traffic to `JlProtocol.java` and the JieLi RCSP SDK; document opcodes in `docs/protocol/`.
- [ ] Find out: control channel (BLE or SPP), battery packet layout, whether the case level is reported (and when: lid open/close), supported ANC modes, EQ, button actions.
- [ ] Output: a capability matrix for the Castor Pro with raw byte examples.

### Phase 3 — Protocol layer
- [ ] Pure-Dart RCSP codec (framing, CRC, auth handshake if required) with unit tests from captured fixtures.
- [ ] Confirm the license of any JieLi SDK material used for reference.

### Phase 4 — Real Bluetooth on Android
- [ ] `BleEarbudsAdapter` with the chosen package.
- [ ] Permissions flow (Android 12+ Bluetooth permissions).
- [ ] Scan, connect, reconnect, capability discovery, battery stream.
- [ ] Decide on SPP: native `MethodChannel` only if Phase 2 shows it is required.

### Phase 5 — Desktop
- [ ] Linux (BlueZ) validation.
- [ ] Windows validation; evaluate the Windows BLE package maturity.
- [ ] Per-platform packaging (AppImage / MSIX or installer / APK).

### Phase 6 — Extras and community
- [ ] More functions: find buds, game mode, firmware info (OTA only with extreme care, it can brick devices).
- [ ] Optional AutoEQ presets (data from the original `kz-autoeq.json`, license permitting).
- [ ] Contribution guide for adding a new model; capability profile files.
- [ ] iOS and macOS when a Mac is available (BLE only).

## 7. Risks

| Risk | Impact | Mitigation |
|---|---|---|
| Castor Pro uses SPP only | No iOS; harder on desktop | Phase 2 finds out early; native bridge on Android |
| Case battery is not reported | Feature cannot exist | Nullable model; hide in UI |
| Windows BLE quirks | Delays desktop support | Isolate in an adapter; test early in Phase 5 |
| Firmware OTA | Can brick a device | Last, opt-in, with explicit warnings |
| Licensing (original Java, JieLi SDK, BitChord GPLv3) | Blocks publishing | Reference only; verify before any reuse |
| Hardware access limited to one model | Poor generalization | Capability-driven design; community profiles |

## 8. Open questions

1. Does the Castor Pro expose its control channel over BLE, SPP, or both?
2. Which license applies to the original Java code and to the JieLi Android SDK?
3. Exact BLE package choice for Windows (decide with a spike in Phase 5, not before).
4. Project name, license, and repository host for the public release.

## 9. Definition of done for the first public milestone

- App runs on Android and Linux with the Castor Pro: connection state, left/right battery, and every capability proven in Phase 2.
- Unsupported capabilities are hidden, not broken.
- `fvm flutter analyze` and `fvm flutter test` are clean.
- Protocol notes are documented, the license is chosen, and a README explains how to add a device.
