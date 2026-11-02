# RCSP Frame Format

## Frame Structure

```
FE DC BA | flags | opcode | len_be | sn [+ status] | param | EF
```

| Field | Size | Description |
|-------|------|-------------|
| Magic | 3 bytes | `FE DC BA` (little-endian marker) |
| Flags | 1 byte | bit 7 = command (clear = response), bit 6 = response expected: `0xC0` request, `0x80` command without response, `0x00` response |
| Opcode | 1 byte | Command opcode (see table below) |
| Length | 2 bytes | Big-endian count of every byte between the length field and `EF` (status, sn and payload) |
| Status | 1 byte | Response status (0 = OK), only in responses, before sn |
| Serial (sn) | 1 byte | Request sequence number; a response echoes it |
| Payload | variable | Command parameters (TLV format for sys info) |
| End | 1 byte | `EF` (frame terminator) |

## Device-Originated vs App-Originated

- **App → Device**: `FE DC BA C0 <op> <len> <sn> <payload> EF` (flags = 0xC0)
- **Device → App (response)**: `FE DC BA 00 <op> <len> <status> <sn> <payload> EF` (flags = 0x00)
- **Device → App (unsolicited)**: `FE DC BA 80 <op> <len> <sn> <payload> EF` (flags = 0x80, no status)

Response payloads: GET_SYS_INFO is `[func][TLV...]`; ADV_GET_INFO is `[TLV...]` with no func byte.
Pure-Dart codec: `lib/data/protocol/rcsp_frame.dart`, tests in `test/protocol/`.

## TLV Format (System Info)

System info uses TLV: `len type value` where `len` counts the type byte.

```
0c 04 ...  = attr 4 (EQ, 11 value bytes)
0a 0d ...  = attr 13 (live noise, 9 value bytes)
1d 0e ...  = attr 14 (saved noise table, 28 value bytes)
```

Multi-byte values are big-endian.

## Opcodes

| Opcode | Name | Direction | Description |
|--------|------|-----------|-------------|
| `0x01` | DATA | both | Data transfer |
| `0x03` | GET_TARGET_INFO | app→device | Get device info (mask `ffffffff00`) |
| `0x07` | GET_SYS_INFO | app→device | Get system info (func + mask u32 BE) |
| `0x08` | SET_SYS_INFO | app→device | Set system info (func + [len][attr][data] items) |
| `0x09` | SYS_INFO_AUTO_UPDATE | device→app | Auto-update (func + len + attr + data) |
| `0x19` | SEARCH_DEVICE | app→device | Find buds (op 0 = stop) |
| `0xC0` | ADV_SETTINGS | app→device | Advertising settings (one LTV) |
| `0xC1` | ADV_GET_INFO | app→device | Get advertising info (mask u32 BE) |
| `0xC2` | (battery/status) | device→app | Unsolicited status block |
| `0xC4` | (device request) | device→app | Device request (sn + op) |
| `0xE7` | (reboot/shutdown) | app→device | `00` reboot, `01` shutdown |
| `0xFF` | (factory reset) | app→device | `03 05` — DANGEROUS, never send |

## GET_SYS_INFO Functions

| Func | Name | Mask bits |
|------|------|-----------|
| `0xFF` | Public | bits 0,1,4,13 (battery, volume, EQ, live noise) |
| `0x00` | BT | volume, etc. |

## System Attributes

| Attr | Name | Size | Format |
|------|------|------|--------|
| 0 | battery | 1 byte | 0-100% |
| 1 | volume | 1 byte | 0-100% |
| 4 | EQ | 11 bytes | `[mode][10 × s8 dB]`, custom = 6 |
| 7 | light | — | — |
| 13 | noise_live | 9 bytes | `mode, leftMax, rightMax, leftCur, rightCur` (u16 BE) |
| 14 | noise_table | 28 bytes | saved noise table (3 × 9 bytes) |
| 0x19 | in_ear | 1 byte | in-ear detection |

## Device-Originated Commands

Device-originated commands carry `sn` first; responses carry `status` then `sn`.

## Authentication Frame

Auth uses 16-byte RAND + 1-byte flag:
- App → Device: `00` + 16 bytes RAND (17 bytes total, but app sends 16)
- Device → App: `01` + 16 bytes (SAFER+ E1 encrypted)
- App → Device: `01` + 16 bytes (SAFER+ E1 encrypted)
- Device → App: `02 70 61 73 73` ("pass")

See `docs/protocol/safer-e1-auth.md` for the full E1 algorithm.