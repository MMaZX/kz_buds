# Sources and References

## Static Sources

### APKs (decompiled outside the repo)

| APK | Path | Package | Decompiler |
|-----|------|---------|------------|
| KZ AUDIO 1.0.8 | `../KZAUDIO_1.0.8.apk` | `com.kzhifi.earphone` | jadx 1.5.6 → `../re/kzaudio-jadx/` |
| KZ Carol Control 2.24.17 | `../KZ-Carol-Control.apk` | `com.carol.control` | jadx 1.5.6 → `../re/carol-control-jadx/` |

### Native Libraries

| Library | Path | Arch | Size |
|---------|------|------|------|
| `libjl_bluetooth.so` | `re/kzaudio-jadx/resources/lib/arm64-v8a/` | ARM64 | 14 KB |
| `libjl_enc.so` | `re/kzaudio-jadx/resources/lib/arm64-v8a/` | ARM64 | 18 KB |

### Key Source Files (relative to `re/kzaudio-jadx/sources/com/`)

| File | Lines | Relevance |
|------|-------|-----------|
| `jieli/bluetooth/impl/RcspAuth.java` | 350+ | Auth flow, native method declarations |
| `jieli/bluetooth/utils/CommandBuilder.java` | 800+ | Command builders (EQ, volume, find, etc.) |
| `jieli/bluetooth/utils/ParseHelper.java` | 600+ | Response parsers (battery, key remap) |
| `jieli/bluetooth/bean/parameter/*.java` | various | Parameter beans |
| `jieli/bluetooth/constant/Command.java` | 100+ | Opcode constants |
| `yj/jie_li/manager/cmd/handset/HandsetManager.java` | 200+ | ADV settings, key remap, rename |
| `yj/jie_li/manager/cmd/base/BaseManager.java` | 300+ | Base manager, in-ear detection |
| `yj/jie_li/MethodChannelImpl.java` | 200+ | Flutter bridge |

## Live Sources

### Captures

| Type | Path | Description |
|------|------|-------------|
| noauth JSON | `captures/noauth/*.json` | Auth challenge/response pairs (3 vectors) |
| HCI snoop | `captures/raw/*.zip` | Full bugreports with btsnoop logs |
| Sessions | `captures/sesiones/pasada-*/` | Per-action capture sessions |

### Tools

| Tool | Path | Purpose |
|------|------|---------|
| rcsp_probe.py | `tools/rcsp_probe.py` | HCI snoop capture and decode |
| rcsp_noauth.py | `tools/rcsp_noauth.py` | BLE probe (no auth) |
| rcsp_spp.py | `tools/rcsp_spp.py` | SPP connection via BlueZ |
| e1_emulate.py | `/tmp/scratchpad/e1_emulate.py` | Unicorn ARM64 E1 emulator |

## Legal Notes

- APKs are decompiled with jadx outside the repo (`../re/`)
- No code, assets, or layouts are copied into the repo
- Every claim cites path:line from the decompiled source
- Raw captures hold device MAC and auth keys; they stay outside the repo
- Redacted excerpts only in `docs/protocol/` (AGENTS.md "Do not")