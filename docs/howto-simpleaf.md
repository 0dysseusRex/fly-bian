# How to use the Fly-bian Simple-AF image

Flash the **Simple-AF** release (`Fly-bian-…_Fly-Lite-2.1_Simple-AF-….img.xz`), not the Base or KIAUH image. This card already has [pellcorp / Simple-AF](https://github.com/pellcorp/creality) trees and venvs under `/opt`; first login copies them into your home.

**Not FlyOS. Not official Mellow.** Unofficial Armbian + Simple-AF for Fly Lite 2.1.

## Upstream Simple-AF (RPi / Creality) docs

Use these for printer/probe choices, macros, and general Simple-AF behavior. Fly-bian only changes the host OS and first-boot helpers.

| Resource | URL |
| --- | --- |
| Simple-AF repo | [github.com/pellcorp/creality](https://github.com/pellcorp/creality) |
| Wiki (getting started) | [pellcorp.github.io/creality-wiki/getting-started](https://pellcorp.github.io/creality-wiki/getting-started/) |
| RPi / Debian host guide | [creality-wiki/rpi](https://pellcorp.github.io/creality-wiki/rpi/) |
| Supported OS notes | [creality-wiki/rpi_supported_os](https://pellcorp.github.io/creality-wiki/rpi_supported_os/) |
| Printer definitions | [creality-wiki/rpi_printer_definitions](https://pellcorp.github.io/creality-wiki/rpi_printer_definitions/) |
| GrumpyScreen | [creality-wiki/rpi_grumpyscreen](https://pellcorp.github.io/creality-wiki/rpi_grumpyscreen/) |
| Boot display (Plymouth) | [creality-wiki/rpi_boot_display](https://pellcorp.github.io/creality-wiki/rpi_boot_display/) |
| Webcam | [creality-wiki/rpi_webcam](https://pellcorp.github.io/creality-wiki/rpi_webcam/) |
| RPi FAQ | [creality-wiki/rpi_faq](https://pellcorp.github.io/creality-wiki/rpi_faq/) |
| Klipper fork used on RPi path | [github.com/pellcorp/klipper-rpi](https://github.com/pellcorp/klipper-rpi) |

On Fly Lite, prefer **GrumpyScreen**, not KlipperScreen (512 MB).

## Flash and first boot

1. Write the `.img.xz` with [Raspberry Pi Imager](https://www.raspberrypi.com/software/), balenaEtcher, or `xzcat … \| dd` (see main [README](../README.md)).
2. Eject, unplug, replug the card so the small **`FLY-SETUP`** FAT volume appears.
3. Edit `fly-start.txt`: Wi-Fi (2.4 GHz), locale/timezone, root password, sudo user.
4. Optional keys for later `fly-start` (examples in the file):
   - `INSTALL_CMD=~/pellcorp/installer.sh --install --printer … --probe … --mount …`
   - `AUTO_CAMERAS=Yes`
   - `ENABLE_GRUMPYSCREEN=Yes`
   - `INSTALL_BOOT_DISPLAY=Yes`
5. Fit the IPEX antenna. Power with independent **5 V** (not the printer MCU).
6. Wait several minutes (resize + 2 GB swap + Wi-Fi). SSH: `ssh USER_NAME@THE.PRINTER.IP`.

Board details: [`boards/fly-lite-2.1/README.md`](boards/fly-lite-2.1/README.md).

## After login — run the install

```bash
fly-help          # Fly-bian helpers
fly-start         # menu: full install / update / boot display / GrumpyScreen
```

Or run the installer directly (same idea as Simple-AF on an RPi):

```bash
# Example — edit printer / probe / mount for your machine
~/pellcorp/installer.sh --install --printer creality-k1m-2023 --probe bltouch --mount Default
```

Pick `--printer` / `--probe` / `--mount` from the [printer definitions](https://pellcorp.github.io/creality-wiki/rpi_printer_definitions/) wiki. Set `INSTALL_CMD` in `fly-start.txt` so `fly-start` uses your line.

Do **not** install KIAUH on this card.

## After install

- Fluidd / Mainsail: use the board’s IP (ports depend on bake; often Fluidd `:80`, Mainsail `:4409`).
- USB cams: `fly-crowsnest-add-cams` (or `AUTO_CAMERAS=Yes` after a full `fly-start`).
- GrumpyScreen rotation: `fly-grumpy-rotate` / `fly-grumpy-rotate 0|1|2|3`.
- Boot splash: `fly-boot-display enable|disable` or fly-start menu.
- Soft `reboot` often hangs — **5 V power cycle**. Space cycles a few minutes apart.

## 512 MB — skip heavy add-ons

Avoid on-device OctoEverywhere, OctoApp, Obico, OctoPrint, Spoolman/Docker, KlipperScreen. See [`boards/fly-lite-2.1/oom.md`](boards/fly-lite-2.1/oom.md).

Long quiet `git` / `apt` steps are normal: [`fly-lite-armbian-notes.md`](fly-lite-armbian-notes.md#simple-af-and-kiauh-looks-hung-still-working).
