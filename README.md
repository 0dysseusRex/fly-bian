# Fly Debian

Armbian (Debian) images for [Mellow Fly](https://mellow.klipper.cn/en/docs/ProductDoc/SBC/) single-board hosts. Not FlyOS-FAST. Normal apt, a normal user, and the board’s hardware.

**Fly Lite 2.1 is first.** Fly Pi V3 is next. Other Fly hosts get a blurb until we pick one up.

This repository is the contract and the patches. Flashable `.img` files are **not** in git (they are large and may contain Wi-Fi secrets). Bench dumps live at `C:\Users\udrdr\fly-lite-armbian-image` — see [`docs/images.md`](docs/images.md).

## What you flash

| Image | Who it is for |
| --- | --- |
| **Named Fly Lite 2.1 Armbian image** (`fly-lite-21`) | Hardware + wizard only. Install Simple-AF or KIAUH yourself later. |
| **Simple-AF image** (`fly-lite-21-simpleaf`) | Same hardware, pellcorp/Klipper stack pre-baked under `/opt`. After login: `~/pellcorp/installer.sh --install --printer …`. Do not add KIAUH. |
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

- `fly-net.txt` — Wi-Fi, locale/timezone, root, and the sudo user (headless first-run)
- `README.txt` — the same three setup paths, written for a first-time user

Then put the card in the Lite, fit the IPEX antenna, and apply 5 V. First boot **expands the Debian partition** to fill the card and creates a 2 GB `/swapfile`. That can take several minutes.

### 1. Text file (headless SSH)

Armbian’s wizard only runs on serial or HDMI, so Wi-Fi in the file by itself cannot give you SSH. Fill **Wi-Fi + root + user** (and ideally locale/timezone) **before** the first power-on. `Your…` placeholders are ignored.

1. Open `fly-net.txt` on `FLY-SETUP` (Notepad is fine).
2. Set `WIFI_SSID`, `WIFI_PSK`, `WIFI_COUNTRY`. Leave `USE_STATIC=0` unless you need a static IPv4.
3. Set `LOCALE` / `TIMEZONE` (examples in the file).
4. Set `ROOT_PASSWORD`, `USER_NAME` (lowercase login), `USER_PASSWORD`.
5. Eject the volume. Card back in the Lite. Power on.
6. Wait for resize + radio (often several minutes), then `ssh USER_NAME@THE.PRINTER.IP`.

Leave root or user as `Your…` and the on-screen wizard still runs. 2.4 GHz only. Passwords in the file are plaintext. There is no pre-made `fly` account unless you type that name yourself.

### 2. Serial

Type-C to the PC, **115200 8N1**, no flow control. Data-capable cable. On Windows this is often **COM4**. Do **not** pulse DTR/RTS (it does not reset this board; it can drop you into U-Boot). Finish the wizard on the serial console.

### 3. Keyboard and screen

FPC-HDMI (or a USB-A HDMI adapter is not a thing — use the FPC) plus a USB keyboard. Leave the FPC-TFT unplugged for first boot. Complete the wizard on that console.

`reboot` on this hardware often hangs. Use a **5 V power cycle**.

## After first login

```bash
sudo apt update
# Do not apt-upgrade kernel, DTB, or U-Boot until those are in a named rebuild.
```

On the **base** image, Klipper is optional — install Simple-AF or KIAUH later as your normal user. On the **Simple-AF** or **KIAUH** named images the git trees and venvs are already on the card; first boot copies them into your home. CPU affinity for those units is already on every flavor (`klipper/cpu-affinity/`).

On this 512 MB board, several Simple-AF **and** KIAUH steps look hung but are still working: `git clone` (Moonraker especially — `Receiving objects` / `index-pack` over 8189fs), then `apt-get` of build deps. Progress is on the SSH/wizard session, not COM4. Wait if git or apt is still moving. Do not reboot. Details: [`docs/fly-lite-armbian-notes.md`](docs/fly-lite-armbian-notes.md#simple-af-and-kiauh-looks-hung-still-working).

## Other Fly boards

| Board | Status | Notes |
| --- | --- | --- |
| Fly Lite 2.1 | Now | This README. H3, MicroSD only. |
| Fly Pi V3 | Next | H618, Ethernet, optional FLY M2WE eMMC. New board file, not a Lite respin. |
| Fly Pi V2, MiniPad, Gemini | Later | Different SoCs. Same first-boot idea, different images. |

## This repo

| Path | What it is |
| --- | --- |
| `first-boot/` | `fly-net.txt` + `README.txt` that belong on `FLY-SETUP` |
| `scripts/prepare-sd.sh` | Copy those files onto a mounted FAT volume |
| `docs/build-named-image.md` | How to **build** the named Lite 2.1 image (Armbian userpatches) |
| `armbian/userpatches/` | Board file, customize hook, overlay for that build |
| `docs/fly-lite-armbian-notes.md` | Lab log (working cpu-affinity card) |
| `docs/lite21-bringup.md` | U-Boot paste if a stock Orange Pi Lite image will not autoboot |
| `docs/images.md` | Bench `.img.gz` dumps and SHA256 |
| `overlays/` | Device-tree overlays |
| `klipper/` | CPU affinity + host-side Klipper fragments (not a Klipper tree) |

## Building an image

A named image is produced with the [Armbian build framework](https://github.com/armbian/build), not by `dd` of a 32 GB card. Follow [`docs/build-named-image.md`](docs/build-named-image.md). From WSL: `scripts/run-armbian-compile.sh base|simpleaf|kiauh`. That build needs a Linux host with Docker or a native Armbian build tree, and the Lite on the bench to verify autoboot, Wi-Fi, serial, and resize.
