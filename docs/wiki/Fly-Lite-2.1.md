# Fly Lite 2.1

![Fly Lite 2.1](https://raw.githubusercontent.com/0dysseusRex/fly-bian/main/docs/boards/fly-lite-2.1/fly-lite-2.1.jpg)

**Status:** Supported — use Fly-bian **1.0** (or newer) images whose names contain `Fly-Lite-2.1`.

Deep hardware notes in the repo: [docs/boards/fly-lite-2.1/README.md](https://github.com/0dysseusRex/fly-bian/blob/main/docs/boards/fly-lite-2.1/README.md).

## Quick facts

| Item | Detail |
| --- | --- |
| SoC | Allwinner H3 |
| RAM | **512 MB** (tight — see [OOM guide](https://github.com/0dysseusRex/fly-bian/blob/main/docs/boards/fly-lite-2.1/oom.md)) |
| Storage | **MicroSD only** (no eMMC) |
| Wi‑Fi | 2.4 GHz, **IPEX antenna required** |
| Power | Independent **5 V** — not from printer MCU |
| Debug | Type-C UART, **115200 8N1**, no flow control |
| Display | FPC-HDMI and/or FPC-TFT (Cap / GT911 on current bakes) |

## Which image to download

From [Releases](https://github.com/0dysseusRex/fly-bian/releases):

- `Fly-bian-*_Fly-Lite-2.1_Base.img.xz`
- `Fly-bian-*_Fly-Lite-2.1_Simple-AF-*.img.xz`
- `Fly-bian-*_Fly-Lite-2.1_KIAUH-*.img.xz`

Full beginner flash steps: [Getting started](Getting-Started.md).

## Lite-specific tips

1. **Antenna first** — without it, Wi‑Fi is poor or fails.  
2. **First boot is slow** — resize + 2 GB swap; wait several minutes.  
3. Soft **`reboot` often hangs** — use a 5 V power cycle; space cycles a few minutes apart.  
4. Do **not** pulse DTR/RTS on the USB-UART to “reset” the SoC.  
5. For first wizard on a screen, use **FPC-HDMI** + USB keyboard; leave FPC-TFT unplugged until after first login if you want a simple path.  
6. On 512 MB: skip heavy add-ons (OctoEverywhere on-device, KlipperScreen if you can, Docker Spoolman, etc.). Simple-AF → GrumpyScreen.

## After login

```bash
fly-help
fly-start          # Simple-AF image
fly-kiauh          # KIAUH image
fly-crowsnest-add-cams
fly-grumpy-rotate  # Simple-AF / GrumpyScreen
```

## Do not flash

- Fly Pi V3 images (when they exist)  
- Raspberry Pi OS, Mainsail OS  
- Stock Orange Pi Lite images (wrong card-detect / no Fly DTB) except for recovery experiments  
