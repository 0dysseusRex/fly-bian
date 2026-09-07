# Debian on the Mellow Fly Lite 2.1

Bring-up notes and tools for running a real Debian userspace on the Fly Lite 2.1, with as much of the board enabled as the public H3 support plus the official FlyOS DTB will allow.

The Lite 2.1 is an Allwinner H3 host (512 MB, SD boot, onboard 2.4 GHz Wi-Fi, two USB-A ports, Type-C, FPC-HDMI, FPC-TFT). It is not a Raspberry Pi and it is not a printer MCU.

## Recommended first image

**Armbian Debian 13 (Trixie) Minimal CLI for Orange Pi Lite.** Same SoC class, same RAM, no Ethernet, SDIO Wi-Fi, two USB hosts. Flash it to a **second** MicroSD card. Keep official FlyOS on the original card.

- Board page: https://www.armbian.com/orange-pi-lite/
- Direct image (follows current trunk): https://dl.armbian.com/orangepilite/Trixie_current_minimal
- Checksum: https://dl.armbian.com/orangepilite/Trixie_current_minimal.sha
- Flasher: https://www.armbian.com/imager/

Official FlyOS for this board (loot the DTB, do not stay on FAST): https://mellow.klipper.cn/en/docs/ResDownload/system-img/fly-lite2/

Then:

1. Independent 5 V power. Fit the IPEX antenna. Leave TFT/HDMI unplugged.
2. Console over Type-C serial (115200) or a USB Ethernet dongle on a USB-A port.
3. Run `scripts/first-boot-checks.sh` on the board.
4. If Wi-Fi or a display is missing, extract the official H3 FlyOS image with `scripts/extract-flyos.sh` and diff the DTB.

If FlyOS is still running on the board (Wi-Fi or COM4 @ 115200), dump DTB/firmware/config from a machine on that LAN:

```bash
FLYOS_HOST=192.168.1.147 ./scripts/pull-live-flyos.sh
```

Klipper host pins and macros: [`docs/klipper-pins-and-macros.md`](docs/klipper-pins-and-macros.md).

## Repo layout

| Path | What it is |
| --- | --- |
| This web guide | Phased bring-up, hardware table, first-experiment helper |
| `docs/klipper-pins-and-macros.md` | Every host pin, sys-config key, and Klipper macro a future install needs |
| `klipper/host-fragments/` | Official `[mcu host]`, PLR, client variables, USB LIS2DW |
| `flyos-artifacts/` | Seeded FlyOS/vendor files + live-pull destination |
| `board/` | Hardware notes |
| `scripts/pull-live-flyos.sh` | SSH dump from a live FAST board (run on your LAN) |
| `scripts/first-boot-checks.sh` | Probe MMC, USB, Wi-Fi, HDMI, serial |
| `scripts/extract-flyos.sh` | Copy DTB, overlays, and firmware out of a FlyOS H3 image |
| `overlays/` | Candidate device-tree overlays. TFT overlay is disabled by default. |

## Run the guide locally

```bash
npm install
npm run dev
```

Open [http://127.0.0.1:43187](http://127.0.0.1:43187).
