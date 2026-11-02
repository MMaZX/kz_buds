# GATT Map — KZ Carol Pro ("Carol Pro")

## Services

| UUID | Name | Description |
|------|------|-------------|
| `0x1800` | Generic Access | Standard BLE service |
| `0xAE00` | JieLi RCSP | Custom service for RCSP communication |

## Characteristics

| UUID | Service | Properties | Description |
|------|---------|------------|-------------|
| `0xAE01` | `0xAE00` | Write No Response | Command channel (app → device) |
| `0xAE02` | `0xAE00` | Notify + CCCD | Response channel (device → app) |

## Connection Parameters

- **MTU**: 247 (reported by the original app)
- **Transport**: SPP (classic Bluetooth, RFCOMM) on Linux; BLE GATT on Android
- **Bonding**: Classic Bluetooth bond (modalias `v05D6p000Ad0240`, JieLi company ID `0x05D6`)

## Discovery

The app scans for devices advertising:
- Service UUID `0xAE00`, OR
- JieLi company ID `0x05D6` in manufacturer data

Features shown come from what the device reports, never from a model name.

## Notes

- No LE advertisement was observed in 4 scans (Phase 2 L4). The Carol Pro appears as a classic Bluetooth device.
- On Linux, the connection path is SPP (RFCOMM), not BLE.
- The original app reports "GATT · MTU 247" and "Chip answering".