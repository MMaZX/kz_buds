# Bluetooth Authentication Protocol (E1 / SAFER+)

## Overview

The KZ Castor Pro uses JieLi's RCSP authentication protocol (E1 algorithm) over SPP.
Authentication is a challenge-response using the SAFER+ block cipher with a 128-bit link key.

## Native Library

- **Library**: `libjl_bluetooth.so` (ARM64, in APK `lib/arm64-v8a/`)
- **Java class**: `com.jieli.bluetooth.impl.RcspAuth`
- **Native methods**: `nativeInit`, `getRandomAuthData`, `setLinkKey`, `getEncryptedAuthData`

## Default Key and Address

| Parameter | Value | Location |
|-----------|-------|----------|
| Link key (K̃) | `06 77 5f 87 91 8d d4 23 00 5d f1 d8 cf 0c 14 2b` | `DAT_00104060` |
| Device address (Ar) | `11 22 33 33 22 11` | `DAT_00104070` |

The key can be overridden at runtime via `setLinkKey(byte[16])`.

## Authentication Flow

```
App                          Device
 |                              |
 |-- RAND (16 bytes) ---------->|
 |                              | (device computes E1)
 |<-- Flag=1 + 16 bytes --------|
 | (app computes E1, compares)  |
 |-- Flag=1 + 16 bytes -------->|
 |                              | (device verifies)
 |<-- "pass" (5 bytes) ---------|
 |                              |
 Auth OK
```

### Step-by-step

1. **App generates RAND**: 17 bytes `[0x00, r0, ..., r15]` via `getRandomAuthData()` (16 × `rand()`)
2. **App sends RAND** (16 bytes, dropping leading 0x00) to device via SPP
3. **Device responds** with 17 bytes: `Flag=1 + E1(key, RAND[1:], addr)` 
   - The device computes `E1(K̃, RAND_app, BD_ADDR_device)`
4. **App verifies**: computes `E1(K̃, RAND_app, addr)` and compares with device response
   - If match: sends `getAuthOkData()` = `{0x02, 0x70, 0x61, 0x73, 0x73}` ("pass")
5. **Device responds** with 17 bytes: `Flag=0 + E1(key, RAND_device, addr)`
6. **App computes** `E1(K̃, RAND_device, addr)` and sends result (17 bytes, Flag=1)
7. **Device verifies** and responds with "pass" → **Auth OK**

## E1 Algorithm (SAFER+)

This is the standard Bluetooth E1 (Core spec, SAFER+ based `Ar`/`Ar'`): the "transform" below is the
E1 key offset, and the exp/log tables and key-schedule biases are `45^x mod 257`. JieLi uses all 16
output bytes and a fixed address instead of the real BD_ADDR. The pure-Dart port
(`lib/data/protocol/rcsp_auth.dart`) computes the tables from that definition, takes nothing from
the binary, and matches the 3 live vectors and 40 random inputs run through the emulator.

E1 uses the SAFER+ block cipher:

### Input
- `key`: 16 bytes (K̃, link key)
- `data`: 16 bytes (RAND or response)
- `addr`: 6 bytes (Bluetooth device address, expanded to 16 bytes)

### Address Expansion
```
expanded[0..5]  = addr[0..5]
expanded[6..11] = addr[0..5]
expanded[12..14] = addr[0..2]
expanded[15]     = addr[3]
```

### Algorithm
1. `output = data` (copy)
2. `round_keys = key_schedule(key)` — expands 16-byte key into 17 × 16-byte round keys
3. `output = round(output, round_keys, 0)` — round 0 (XOR/ADD + substitution + PHT)
4. `output[i] = expanded[i] + (output[i] XOR data[i])` for i in 0..15
5. `transformed_key = transform(key)` — byte-wise transform (sub/XOR with constants)
6. `round_keys = key_schedule(transformed_key)` — new round keys
7. `output = round(output, round_keys, 1)` — round 1 (with flag, adds input in round 3)
8. Return `output` (16 bytes) + flag byte (0x01)

### Key Schedule (0x1128)
- Computes parity = XOR of all 16 key bytes
- `round_keys[0] = key` (copy)
- Rotates key left by 3 bits per round
- For each of 16 rounds: generates 16 round key bytes using constants table (0x1dd7)
- Parity is rotated by 3 bits each round
- Total: 17 round keys × 16 bytes = 272 bytes

### Round Function (0x12a8)
- **Mask**: 0x9999 (determines XOR vs ADD per position)
- **Tables**: exp (0x1ec8), log (0x1fc8) — 256 bytes each
- **Operations**:
  1. XOR/ADD with round key (positions with bit set in 0x9999 → XOR, else ADD)
  2. Substitution: exp table for positions 0,3,4,7,8,11,12,15; log table for 1,2,5,6,9,10,13,14
  3. Linear diffusion: PHT (Pseudo-Hadamard Transform) in 3 stages
  4. Final XOR/ADD with round_keys+256 (last round key)

### Transform (0xe7c-0xf4c)
Byte-wise transformation of the key:
```
t[0]  = key[0]  - 0x17
t[1]  = key[1]  XOR 0xe5
t[2]  = key[2]  - 0x21
t[3]  = key[3]  XOR 0xc1
t[4]  = key[4]  - 0x4d
t[5]  = key[5]  XOR 0xa7
t[6]  = key[6]  - 0x6b
t[7]  = key[7]  XOR 0x83
t[8]  = key[8]  XOR 0xe9
t[9]  = key[9]  - 0x1b
t[10] = key[10] XOR 0xdf
t[11] = key[11] - 0x3f
t[12] = key[12] XOR 0xb3
t[13] = key[13] - 0x59
t[14] = key[14] XOR 0x95
t[15] = key[15] - 0x7d
```

## Verification

Verified against 3 real captures using Unicorn ARM64 emulation:

| RAND (from capture) | Expected (from capture) | Emulated | Match |
|---------------------|------------------------|----------|-------|
| `00 6d 83 df 5d ab 1e 75 b9 95 e3 a6 fc cc 6b 2c 4c` | `f3 97 64 5b c3 7b 83 55 ae a7 6b 0f 53 30 86 ea` | ✅ | Yes |
| `00 6a 74 fb 64 f1 8b 42 01 33 cc 8f c3 95 12 f9 1f` | `8a a1 23 05 79 09 94 f1 fa c9 be e3 f2 e1 47 3b` | ✅ | Yes |
| `00 03 53 2b 37 5c e1 d3 21 57 81 84 e5 20 24 2a b2` | `16 c2 77 f6 d3 be 46 58 bf 27 13 16 4a c9 17 5e` | ✅ | Yes |

## Tools

- Emulator: `/tmp/scratchpad/e1_emulate.py` (Unicorn ARM64)
- Usage: `emulate_e1(addr_bytes, key_bytes, input_bytes)` → 16 bytes encrypted
- Tables: `/tmp/scratchpad/exp.bin`, `log.bin`, `const.bin`

## References

- Binary: `re/kzaudio-jadx/resources/lib/arm64-v8a/libjl_bluetooth.so`
- Java: `re/kzaudio-jadx/sources/com/jieli/bluetooth/impl/RcspAuth.java`
- Bluetooth spec: E1 algorithm (SAFER+)
- Captures: `captures/noauth/*.json`