# Named Armbian image — Fly Lite 2.1

Build a **small** flashable image that behaves like a public Armbian card: Etcher/Imager, a FAT volume Windows/macOS/Linux can mount, first-boot resize, first-run wizard. Do **not** ship a 32 GB live `dd`.

Working hardware (already proven on the lab card) must land in this image. Lab log: [`fly-lite-armbian-notes.md`](fly-lite-armbian-notes.md).

## Product name

Armbian-style filename, for example:

```
Armbian_fly-lite-21_trixie_current_<kernel>_minimal.img.xz
```

Board id: `fly-lite-21` (family `sun8i`, 32-bit). Image type: **Debian Trixie Minimal CLI** (no desktop).

## Partition layout

| Partition | Type | Size in the *file* | Role |
| --- | --- | --- | --- |
| (SPL / U-Boot) | raw sectors | Armbian default | Allwinner boot, before the partition table |
| `mmcblk0p1` | FAT32, label **`FLY-SETUP`** | ~128–256 MB | `fly-net.txt`, `README.txt`. Must mount on Windows, macOS, and Linux after flash. |
| `mmcblk0p2` | ext4 root | **as small as Armbian will emit** (not the full card) | Debian + `/boot`. **Grow to fill the SD on first boot.** |

Prefer Armbian’s own `BOOTFS_TYPE=fat` + `BOOTSIZE=256` if the `sun8i` path still autoboots. If the family forces a single ext4, add `FLY-SETUP` as a dedicated FAT partition and point U-Boot at **partition 2** for the rootfs (`root=/dev/mmcblk0p2`). Autoboot must work with no serial paste.

Do not live-`dd` `/dev/mmcblk0` over `wlan0` (8189fs + sequential mmc0 read wedges Wi-Fi). For golden images, use the Armbian `output/images/` artifact. If you must snapshot a card, shut down, USB reader, then compress.

## First-run contract (new user)

Leave Armbian’s first-run wizard **enabled**:

- Keep `/root/.not_logged_in_yet`.
- Do **not** preset `PRESET_USER_NAME`, `PRESET_USER_PASSWORD`, or a baked `fly` account.
- Do **not** preset `PRESET_ROOT_PASSWORD` in the image.
- First boot must resize the ext4 partition (`armbian-resize-filesystem` or equivalent), then offer locale / root password / normal sudo user on serial **and** HDMI.

Wi-Fi from the FAT file is optional and must not skip the wizard:

- If `fly-net.txt` still has `WIFI_SSID=YourNetwork`, do not join a network; still run the wizard.
- If the user edited SSID/PSK, apply that (Armbian `armbian_first_run.txt` or a small systemd oneshot that reads `/boot` **and** the `FLY-SETUP` partition). Do not require the user to know about `armbian_first_run.txt`.

Copy onto `FLY-SETUP` at image-build time (from this repo):

- `first-boot/fly-net.txt` (placeholder SSID)
- `first-boot/README.txt`

Windows: after flash, replug the reader and assign a drive letter if needed. macOS/Linux: volume name `FLY-SETUP`.

## Hardware that must be in the image

Clone from the working **cpu-affinity** card, not from stock Orange Pi Lite autoboot.

| Item | Requirement |
| --- | --- |
| DTB | `sun8i-h3-fly-lite.dtb` as `fdtfile` |
| SD card-detect | PF6 is **not** CD on this PCB. Patch **U-Boot and Linux** (`broken-cd` / `mmc-broken-cd`). Autoboot must see `mmc0` without `gpio clear PF6`. |
| Overlays | `uart1 usbhost0 usbhost2 usbhost3` plus user `mmc-broken-cd fly-lite-io fly-lite-tft fly-lite-hdmi` (or compiled into the DTB). `fly-lite-hdmi` sets `&hdmi` okay — Fly’s DTB ships HDMI disabled, so Linux otherwise drops the HDMI5 after U-Boot. `disp_mode=800x480p60`. Do **not** load `fly-lite-leds` (duplicates Fly LED nodes → `-EBUSY`). |
| Wi-Fi | RTL8189FTV / `8189fs` on SDIO. Boot **`maxcpus=1`**, then online isolated CPUs 1–3 **after** 8189fs (`isolcpus=1-3 irqaffinity=0`). Same pattern as `fly-online-isolated-cpus.service`. Do not boot four cores from t=0. |
| CPU affinity | Install `klipper/cpu-affinity/` so a later Klipper stack is `CPUAffinity=1-3`. Do not wrap installers. Do not install Klipper. |
| Kernel cmdline extras | `nohz=off clocksource=timer cma=16M` plus the isolcpus set. `console=serial` (or serial+display if HDMI wizard needs it — wizard must work on Type-C UART at 115200). |
| Packages | Freeze kernel, DTB, and U-Boot (`armbian-hold` / apt-mark) so a casual `apt upgrade` does not lose PF6 + Fly DTB. |
| Swap | 2 GiB `/swapfile` on first boot **after** rootfs grow (`fly-swapfile.service`). Do not `fallocate` it at image-build time (that bloats the `.img` by 2 GiB). Stock zram (~226 Mi) is not enough for Moonraker `uvloop` / clang on 512 MB. |
| Displays | TFT software bind is OK (`panel-mipi-dbi`, `/lib/firmware/ST7796S.bin`). HDMI5 / FPC-HDMI: `fly-lite-hdmi` + `disp_mode=800x480p60` so the wizard has a DRM connector, not only U-Boot simplefb. |

Type-C is a real UART (CH340 on Windows). Do not treat it as USB gadget-only. Do not pulse DTR/RTS in tests.

## Build method

Use https://github.com/armbian/build on a Linux host (Docker is fine).

```text
BOARD=fly-lite-21                 # hardware only (installer-agnostic)
BOARD=fly-lite-21-simpleaf        # same hardware + Simple-AF (pellcorp) pre-bake
BOARD=fly-lite-21-kiauh           # same hardware + KIAUH pre-bake
BRANCH=current
RELEASE=trixie
BUILD_MINIMAL=yes
BUILD_DESKTOP=no
KERNEL_CONFIGURE=no
```

From WSL: `scripts/run-armbian-compile.sh base|simpleaf|kiauh`.

Simple-AF / KIAUH images install the apt toolchain, clone the usual git trees into `/opt/fly-simple-af` or `/opt/fly-kiauh`, and create `moonraker-env` / `klippy-env` **without** `moonraker-speedups` / uvloop source builds. After the first-run user exists, `fly-bind-klipper-stack` copies that tree into `$HOME`. Do **not** bake a `fly` account or a printer.cfg. Do **not** mix Simple-AF and KIAUH on one card.

Start from `orangepilite` (`orangepi_lite_defconfig`, family `sun8i`), then apply Fly DTB + CD patch + overlays. Userpatches live in [`armbian/userpatches/`](../armbian/userpatches/).

Do not point documentation at Armbian’s `Trixie_current_minimal` **short URL** (it 302s to a `.img.xz` and chat clients download it). Use the [Orange Pi Lite board page](https://www.armbian.com/orange-pi-lite/) if you need a stock reference image.

## Verify on the Lite before declaring done

1. Flash the **xz** (or `.img`) with Etcher / Raspberry Pi Imager / `dd`. Image file should be far smaller than 32 GB.
2. Replug: `FLY-SETUP` mounts; `README.txt` and `fly-net.txt` are there.
3. First power-on **without** editing Wi-Fi: wizard still runs on serial and/or HDMI. Rootfs fills the card (`lsblk`).
4. Second card (or reflash): edit `fly-net.txt`, boot, wizard **and** `wlan0` on the SSID.
5. SSH as the **wizard user**, not a baked `fly`.
6. `wlan0` stays up with load on CPUs 1–3 (`isolcpus` layout).
7. Heartbeat LED. USB-A. Serial at 115200.
8. `systemctl cat klipper.service.d/50-fly-cpu-affinity.conf` exists even though Klipper is not installed.
9. After first boot + resize: `swapon --show` lists `/swapfile` at 2 GiB.

Copy the artifact into `C:\Users\udrdr\fly-lite-armbian-image\Releases\<version>\<board>\` (Lite images under `Fly Lite 2.1`, V3 under `Fly Pi V3`; Simple-AF and KIAUH of the same version share the Lite folder), `sha256sum` the `.img.xz`, add a line to `Releases/RELEASES.txt`, and record it in [`images.md`](images.md). Do not commit the image or passwords.
