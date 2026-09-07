# FlyOS artifacts for Debian on Fly Lite 2.1

Local stash of everything FlyOS-specific a Debian (Armbian Orange Pi Lite) image is likely to need: device trees, overlays, wireless firmware, `sys-config` keys, and stock Klipper snippets.

The live board at **192.168.1.147** (serial COM4 @ 115200) is on the user's LAN. This workspace cannot reach it. Pull from a machine on that LAN:

```bash
# Linux or WSL, same Wi-Fi as the Lite
sudo apt install sshpass device-tree-compiler
FLYOS_HOST=192.168.1.147 ./scripts/pull-live-flyos.sh
```

Official FAST login: `root` / `mellow`. Prefer a key (`FLYOS_SSH_IDENTITY`) if you have one.

## Layout

| Path | What it is |
| --- | --- |
| `live/` | Output of `scripts/pull-live-flyos.sh`. Empty until you run it. |
| `extracted/` | Output of `scripts/extract-flyos.sh` against an official H3 `.img`. |
| `reference/sun8i-h3-orangepi-lite.dts` | Closest public mainline DTB (H3, 512 MB, no Ethernet, SDIO Wi-Fi). |
| `reference/official-urls.md` | Mellow / kernel URLs used to seed this tree. |
| `vendor/FLY-TFT/` | Official FLY-TFT-V2 overlay (Raspberry Pi GPIOs — pinmux is **not** H3). |
| `vendor/USB-Accelerometer/` | USB accel hardware notes. |

## What Debian needs from FlyOS

In priority order:

1. **DTB / overlays** — MMC1 Wi-Fi, USB OTG/gadget on Type-C, FPC-TFT SPI GPIOs, HDMI connector.
2. **`/lib/firmware` RTL bits** — if MMC1 probes but `wlan0` stays down.
3. **`sys-config.conf` / `config.txt`** — `board=fly-lite2.1`, `screen=`, KPPM shutdown keys.
4. **Stock `printer.cfg` + `plr.cfg`** — confirm `[mcu host]` and macros; do not copy printer-MCU pins from some other machine.

Do **not** copy the FAST rootfs. FAST has no normal `apt`, is root-only, and is read-only except `/etc` and `/data`.

## If you have the official image instead of SSH

Download the Lite2 / Lite2.1 H3 image (same file for both), unzip it, then:

```bash
./scripts/extract-flyos.sh /path/to/FlyOS_h3_*.img
```

That writes `out/flyos-extract/`. Copy useful files into `extracted/` if you want them in-tree (skip the raw `.img`).
