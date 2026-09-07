# Fly Debian

Debian-based images for Mellow Fly hosts. **Fly Lite 2.1 first**: boot a real Debian userspace, enable as much original hardware as possible, then bake a flashable image. **Fly Pi V3** is next. Other boards get blurbs until we pick one up.

The later image will flash to MicroSD, and to eMMC on boards that have it (Lite 2.1 does not). Every image keeps an easy text file for Wi-Fi before first boot, plus serial and HDMI+USB as setup paths.

Project plan: [`docs/project.md`](docs/project.md).

## Right now — Lite 2.1

The Lite is an Allwinner H3 host (512 MB, **MicroSD only**, onboard 2.4 GHz Wi-Fi, two USB-A, Type-C, FPC-HDMI, FPC-TFT). Not a Raspberry Pi. Not a printer MCU.

**Armbian Debian 13 Trixie Minimal CLI for Orange Pi Lite** on a **second** MicroSD. Keep FlyOS on the original card.

**Live status:** Kernel 6.18.49 starts. Linux then hides the SD card (same PF6 CD). After loading the DTB, `fdt rm /soc/mmc@1c0f000 cd-gpios` before `bootz`. MMC1 SDIO Wi-Fi already probed. Paste: [`docs/lite21-bringup.md`](docs/lite21-bringup.md).

1. Flash: https://dl.armbian.com/orangepilite/Trixie_current_minimal
2. This Trixie image is **one ext4 partition** (no FAT `armbi_boot`), so skip `fly-net.txt` until Linux is up. Use Type-C serial.
3. Independent 5 V. IPEX antenna. Leave TFT unplugged.
4. At U-Boot: `gpio clear PF6`, `mmc dev 0`, then the `ext4load` / `bootz` block in the bring-up doc. On Windows see [`first-boot/windows.md`](first-boot/windows.md) — this workspace cannot open COM4.
5. On the board: `scripts/first-boot-checks.sh`
6. If Wi-Fi or a display is missing, loot the official H3 FlyOS DTB (`scripts/extract-flyos.sh` or `scripts/pull-live-flyos.sh`)

Klipper host pins: [`docs/klipper-pins-and-macros.md`](docs/klipper-pins-and-macros.md).

## Repo layout

| Path | What it is |
| --- | --- |
| This web guide | Project, board family, first-boot, Lite 2.1 bring-up |
| `docs/project.md` | Roadmap and image contract |
| `docs/lite21-bringup.md` | Live U-Boot paste (PF6 CD + flat DTB path) |
| `first-boot/fly-net.txt` | Edit SSID/password; copy to the FAT boot partition |
| `scripts/prepare-sd.sh` | Writes Armbian `armbian_first_run.txt` from that file |
| `docs/klipper-pins-and-macros.md` | Host pins, sys-config keys, PLR / client macros |
| `klipper/host-fragments/` | `[mcu host]`, PLR, USB LIS2DW |
| `flyos-artifacts/` | Seeded FlyOS/vendor files + live-pull destination |
| `overlays/` | Candidate DTB overlays. TFT stays disabled. |

## Run the guide locally

```bash
npm install
npm run dev
```

Open [http://127.0.0.1:43187](http://127.0.0.1:43187).
