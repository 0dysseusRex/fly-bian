# Fly Debian

Armbian (Debian) images for [Mellow Fly Lite 2](https://mellow.klipper.cn/en/docs/ProductDoc/SBC/fly-lite/lite2/) single-board hosts. Not FlyOS-FAST. Normal apt, a normal user, and the board’s hardware.

**Fly Lite 2.1 is first.** Fly Pi V3 is next. Other Fly hosts get a blurb until we pick one up.

This repository is the contract and the patches. Flashable `.img` files are **not** in git (they are large and may contain Wi-Fi secrets). Bench dumps live at `C:\Users\udrdr\fly-lite-armbian-image` — see [`docs/images.md`](docs/images.md).

## What you flash

| Image | Who it is for |
| --- | --- |
| **Named Fly Lite 2.1 Armbian image** (`fly-lite-21`) | Hardware + wizard only. Install Simple-AF or KIAUH yourself later. |
| **Simple-AF image** (`fly-lite-21-simpleaf`) | Same hardware, pellcorp/Klipper stack pre-baked under `/opt`. After login: `fly-start` (or `~/pellcorp/installer.sh --install --printer …`). Do not add KIAUH. |
| **KIAUH image** (`fly-lite-21-kiauh`) | Same hardware, KIAUH + stock Klipper/Moonraker/UIs pre-baked. After login: `~/kiauh/kiauh.sh`. Do not add Simple-AF. |
| Current lab dump `fly-lite-v2.1-armbian-cpu-affinity.img.gz` | Already-working card (full-size `dd`). Use only until the named image exists. |
| Stock Orange Pi Lite Trixie from [armbian.com/orange-pi-lite](https://www.armbian.com/orange-pi-lite/) | Recovery / comparison. Single ext4, no Fly DTB, U-Boot card-detect is wrong on this PCB. |

Do **not** flash Raspberry Pi OS, Mainsail OS, or Fly Gemini / Fly-Pi H5 community images onto the Lite.

## Fly Lite 2.1 in one page

Compact Allwinner **H3** host (512 MB, **MicroSD only**, no eMMC). Onboard 2.4 GHz Wi-Fi (IPEX), two USB-A, Type-C power + UART, FPC-HDMI, FPC-TFT. Independent **5 V**. Do not power it from a printer MCU.

The working lab image uses Fly’s `sun8i-h3-fly-lite.dtb`, heartbeat LED, `wlan0` (8189fs on **CPU0**), TFT DRM bound (panel may still be in the mail). Klipper is **not** preinstalled. systemd drop-ins pin a later KIAUH or Simple-AF stack to CPUs **1–3**.

## First boot (named image)

After flashing, **eject, unplug, and replug** the card so the small FAT volume appears. Windows, macOS, and Linux can all read it. Label is `FLY-SETUP`.

On that volume you will find:

- `fly-start.txt` — Wi-Fi, locale/timezone, root, sudo user, plus Simple-AF install options
- `README.txt` — the same three setup paths, written for a first-time user

Then put the card in the Lite, fit the IPEX antenna, and apply 5 V. First boot **expands the Debian partition** to fill the card and creates a 2 GB `/swapfile`. That can take several minutes.

### 1. Text file (headless SSH)

Armbian’s wizard only runs on serial or HDMI, so Wi-Fi in the file by itself cannot give you SSH. Fill **Wi-Fi + root + user** (and ideally locale/timezone) **before** the first power-on. `Your…` placeholders are ignored.

1. Open `fly-start.txt` on `FLY-SETUP` (Notepad is fine).
2. Set `WIFI_SSID`, `WIFI_PSK`, `WIFI_COUNTRY`. Leave `USE_STATIC=0` unless you need a static IPv4.
3. Set `LOCALE` / `TIMEZONE` (examples in the file).
4. Set `ROOT_PASSWORD`, `USER_NAME` (lowercase login), `USER_PASSWORD`.
5. Optionally set `INSTALL_CMD`, `AUTO_CAMERAS`, `ENABLE_GRUMPYSCREEN`, `INSTALL_BOOT_DISPLAY` for later `fly-start`.
6. Eject the volume. Card back in the Lite. Power on.
7. Wait for resize + radio (often several minutes), then `ssh USER_NAME@THE.PRINTER.IP`.
8. Run `fly-help` or `fly-start`.

Leave root or user as `Your…` and the on-screen wizard still runs. 2.4 GHz only. Passwords in the file are plaintext. There is no pre-made `fly` account unless you type that name yourself.

### 2. Serial

Type-C to the PC, **115200 8N1**, no flow control. Data-capable cable. On Windows this is often **COM4**. Do **not** pulse DTR/RTS (it does not reset this board; it can drop you into U-Boot). Finish the wizard on the serial console.

### 3. Keyboard and screen

FPC-HDMI (or a USB-A HDMI adapter is not a thing — use the FPC) plus a USB keyboard. Leave the FPC-TFT unplugged for first boot. Complete the wizard on that console.

`reboot` on this hardware often hangs. Use a **5 V power cycle**.

## After first login

```bash
fly-help                  # install tips + custom commands
fly-start                 # Simple-AF full install / update (reads fly-start.txt)
sudo apt update
# Do not apt-upgrade kernel, DTB, or U-Boot until those are in a named rebuild.
```

On the **base** image, Klipper is optional — install Simple-AF or KIAUH later as your normal user. On the **Simple-AF** or **KIAUH** named images the git trees and venvs are already on the card; first boot copies them into your home. CPU affinity for those units is already on every flavor (`klipper/cpu-affinity/`).

On this 512 MB board, several Simple-AF **and** KIAUH steps look hung but are still working: `git clone` (Moonraker especially — `Receiving objects` / `index-pack` over 8189fs), then `apt-get` of build deps. Progress is on the SSH/wizard session, not COM4. Wait if git or apt is still moving. Do not reboot. Details: [`docs/fly-lite-armbian-notes.md`](docs/fly-lite-armbian-notes.md#simple-af-and-kiauh-looks-hung-still-working).

### USB cameras (Crowsnest)

After Crowsnest is installed (Simple-AF/`make install` or KIAUH), plug in a UVC webcam and from SSH:

```bash
fly-crowsnest-add-cams          # discover cams, edit ~/printer_data/config/crowsnest.conf, restart
fly-crowsnest-add-cams --dry-run
```

Uses stable `/dev/v4l/by-id/…-video-index0` paths and skips the H3 cedrus encoder. Re-run after plugging another cam; already-configured devices are left alone. Stream example: `http://<board-ip>:8080/?action=stream`. Set `AUTO_CAMERAS=Yes` in `fly-start.txt` to run this after a full `fly-start` install.

### GrumpyScreen rotation

```bash
fly-grumpy-rotate          # show current
fly-grumpy-rotate 0        # 0°
fly-grumpy-rotate 1        # 90°
fly-grumpy-rotate 2        # 180°
fly-grumpy-rotate 3        # 270° (image default)
```

Writes `~/printer_data/config/grumpyscreen.ini` and restarts GrumpyScreen. Changing rotation triggers touch recalibration. Set `ENABLE_GRUMPYSCREEN=Yes` in `fly-start.txt` to enable GrumpyScreen after a full `fly-start` install. Set `INSTALL_BOOT_DISPLAY=Yes` for the Plymouth early-boot splash (not GrumpyScreen). Toggle later with `fly-boot-display enable|disable` or fly-start menu 3/4. Rotate from fly-start menu 5/6 or `fly-grumpy-rotate`.

### Boot display (Plymouth)

Simple-AF images bake `plymouth` + the Simple-AF theme. Default is off (`bootlogo=false`) to keep early boot light on 512 MB.

```bash
fly-boot-display status
fly-boot-display enable    # Simple-AF splash; reboot to apply
fly-boot-display disable   # text boot sequence for diagnostics; reboot to apply
```

Or set `INSTALL_BOOT_DISPLAY=Yes` in `fly-start.txt` (full install) / fly-start menu 3–4.

## Other Fly boards

| Board | Status | Notes |
| --- | --- | --- |
| Fly Lite 2.1 | Now | This README. H3, MicroSD only. |
| Fly Pi V3 | Next | H618, Ethernet, optional FLY M2WE eMMC. New board file, not a Lite respin. |
| Fly Pi V2, MiniPad, Gemini | Later | Different SoCs. Same first-boot idea, different images. |

## This repo

| Path | What it is |
| --- | --- |
| `FLYBIAN_VERSION` | Product version (`0.2` … `1.0`). Bump before every new image (`scripts/bump-flybian-version.sh`). See [`docs/image-naming.md`](docs/image-naming.md) |
| `first-boot/` | `fly-start.txt` + `README.txt` that belong on `FLY-SETUP` |
| `scripts/prepare-sd.sh` | Copy those files onto a mounted FAT volume |
| `scripts/stage-flybian-release.sh` | Rename/copy Armbian output to Fly-bian product names |
| `docs/build-named-image.md` | How to **build** the named Lite 2.1 image (Armbian userpatches) |
| `docs/image-naming.md` | Fly-bian release filename scheme |
| `armbian/userpatches/` | Board file, customize hook, overlay for that build |
| `docs/fly-lite-armbian-notes.md` | Lab log (working cpu-affinity card) |
| `docs/lite21-bringup.md` | U-Boot paste if a stock Orange Pi Lite image will not autoboot |
| `docs/images.md` | Bench `.img.gz` dumps and SHA256 |
| `overlays/` | Device-tree overlays |
| `klipper/` | CPU affinity + host-side Klipper fragments (not a Klipper tree) |

## Building an image

A named image is produced with the [Armbian build framework](https://github.com/armbian/build), not by `dd` of a 32 GB card. Follow [`docs/build-named-image.md`](docs/build-named-image.md). From WSL: `scripts/run-armbian-compile.sh base|simpleaf|kiauh`. That build needs a Linux host with Docker or a native Armbian build tree, and the Lite on the bench to verify autoboot, Wi-Fi, serial, and resize.
