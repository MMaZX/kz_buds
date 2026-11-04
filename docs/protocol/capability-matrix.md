# Capability Matrix — KZ Carol Pro

States: **proven** (live bytes), **seen in code** (path:line), **seen in app only**, **unknown**.

| Feature | State | Evidence |
|---------|-------|----------|
| Battery L/R | proven | ADV type 0: `[L][R][C]`, bit7 charging, bits0-6 % (L20) |
| Case battery | unknown | Not reported; C byte always 0 (L17, L20) |
| Physical noise mode | unknown | Not exposed by any connect-time query (L15) |
| Noise mode set/get | proven | op 08/07 mask 0x2000/0x4000, attr 13/14, 9 bytes (VoiceMode.java). Set = SET_SYS_INFO func ff attr 13 with the device table entry; Carol Pro table has modes 0, 1, 2, all answered status 0 and heard live (2026-11-04) |
| ANC modes (key cycle) | seen in code | C0/C1, ADV type 10, u32 BE bitmask (HandsetManager.java:115-138) |
| EQ get/set | seen in code | op 07 mask 0x1010/08, attr 4, [mode][10×s8 dB], custom=6 (CommandBuilder.java:150-177) |
| Bass/treble | seen in code | op 08/07 mask 0x800, attr 11, bass s32 BE, treble s32 BE |
| Key remap | seen in code | C0/C1, ADV type 2, triplets [key][action][function], 0xFF=cycle ANC (ParseHelper.java:599-616) |
| Work mode (game mode) | seen in code | C0/C1, ADV type 5, 1 byte (HandsetManager.java:193-194) |
| Mic channel | seen in code | C0/C1, ADV type 4, 1 byte (MethodChannelImpl.java:132-136) |
| In-ear detection | seen in code | C1/C0, ADV type 8, 1 byte (BaseManager.java:240-245) |
| Find buds | proven | op 0x19, `[1][op][timeout u16 BE][way][player]`, stop op 0; way 0 both, 1 left, 2 right; player 1 (RING_PLAYER_DEVICE) rings the earbuds, player 0 (what the KZ app sends) leaves them silent and the KZ app plays an alarm on the phone instead. Firmware limit (live 2026-11-02): a single side rings only on the earbud holding the link; the other side mutes media and plays nothing. way 0 and way 3 ring both. The app defaults to both |
| Support flags | proven | GET_TARGET_INFO TLV 19 (ParseHelper.java:383-388); Carol Pro reports search, game mode and ANC; not adaptive ANC, EQ ban or double connection (live 2026-11-02) |
| Volume | seen in code | op 08/07 mask 2, attr 1, 1 byte (CommandBuilder.java:111-121) |
| Rename | seen in code | C0, ADV type 1, raw name bytes; may reboot (HandsetManager.java:60-85) |
| Reboot/shutdown | seen in code | E7, `00` reboot, `01` shutdown (CommandBuilder.java:427-432) |
| Factory reset | seen in code | FF, raw `03 05` (CustomManager.java:38,54-55,79) — DANGEROUS, never send |
| LDAC / codec / low latency | unknown | Not found in the bridge (0xD5 defined, unused) |
| Case button | unknown | No function found (L18) |
| Auth (E1/SAFER+) | proven | 3 live challenge/response pairs verified (L5, L24) |

## Battery Details

- **Slot 1 = LEFT**, **Slot 2 = RIGHT** (proven, L20)
- **Case = 0** in every frame (not reported, L17)
- ADV type 0 format: `[L][R][C]`, bit7 = charging, bits0-6 = percentage
- C2 frame format: `vid(2) uid(2) pid(2) (chip<<4)|version MAC(6) F L R C X`
  - F = action (0 dismiss, 1 unconnected, 2 connected, 3 connecting, 4 connectionless)
  - X = sequence counter
  - Castor Pro: vid 0x05D6, uid 0, pid 0, chip 2, version 2

## EQ Details

- Attr 4 format: `[mode][10 × s8 dB]`
- Mode 0 = Flat, gains all 0
- Custom mode = 6
- Bit 7 of mode = dynamic EQ with `[n][gains]`

## Noise Mode Details

- Attr 13 (live): 9 bytes `mode, leftMax, rightMax, leftCur, rightCur` (u16 BE)
- Mode: 0 = off, 1 = ANC, 2 = transparency
- The firmware does not report the hold-selected mode: attr 13 keeps the last mode set over RCSP (read 0 after the app set off, 2026-11-04), and no push (C2 or 09) arrives when the mode changes by touch
- Attr 14 (table): `[count][count × 9 bytes]`, one entry per mode (Carol Pro: 3, modes 0, 1, 2)

## Key Remap Details

- ADV type 2: triplets `[key][action][function]`
- Function 0xFF = cycle ANC modes
- Key/gesture/action names come from server product data per vid/uid/pid

## Notes

- The app has no hardcoded per-model list (no Castor/Carol/vid/pid strings)
- All rows are "seen in code" until a live capture proves them
- The app enables a capability only when the device reports it (TLV 19) and the feature is proven live
- Code alone never makes a row "proven"