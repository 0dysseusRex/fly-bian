# Fly Pi V3

![Fly Pi V3](https://raw.githubusercontent.com/0dysseusRex/fly-bian/main/docs/boards/fly-pi-v3/fly-pi-v3.jpg)

**Status:** Next target after Fly Lite 2.1. **No Fly-bian public image yet.**

Board notes in the repo: [docs/boards/fly-pi-v3/README.md](https://github.com/0dysseusRex/fly-bian/blob/main/docs/boards/fly-pi-v3/README.md).

## Important

**Do not flash Fly Lite 2.1 images** (`Fly-Lite-2.1` in the filename) onto a Fly Pi V3. Wrong SoC / boot / device tree - it will not work and can waste a lot of time.

When Pi V3 images ship, filenames will look like:

- `Fly-bian-*_Fly-Pi-V3_Base.img.xz`
- `Fly-bian-*_Fly-Pi-V3_Simple-AF-*.img.xz`
- `Fly-bian-*_Fly-Pi-V3_KIAUH-*.img.xz`

...and the flash flow will match [Getting started](Getting-Started.md) (download -> burn MicroSD -> `FLY-SETUP` / wizard -> SSH -> `fly-start` or `fly-kiauh`).

## What we know from the board (bring-up TBD)

Visible on the PCB (for orientation only - pinmux and drivers still to be confirmed in Fly-bian):

- Marked **Fly-PI3**
- Ethernet + USB-A, fan header, reset
- M.2-style **FLY M2** socket (private FLY modules only)
- Large supercapacitor module on some units

### M2 module variants (all must work)

| Module | Wi-Fi | Module storage |
| --- | --- | --- |
| M2 2.4G Wi-Fi only | 2.4 GHz | None (use onboard MicroSD for OS) |
| **M2WE** | 2.4 + 5 GHz | 16 GB eMMC |
| **M2WS** | 2.4 + 5 GHz | 16 GB soldered TF on the module |

Fly-bian images must support SD-only, SD + Wi-Fi M2, M2WE boot, and M2WS boot. By default, gcode and timelapse stay on the boot medium (including everything on M2WE/M2WS if that is what the user wants). Optionally, users with an onboard MicroSD can redirect **gcode** and **timelapse** there - documented how-to, not forced.

**Do not flash the image onto both the onboard MicroSD and the module eMMC (or M2WS TF).** One medium holds the OS. The other may be blank storage. Two bootable copies let U-Boot and the root filesystem come from different installs.

The 2.4 GHz-only M2 cannot join a 5 GHz network. M2WE and M2WS can use either band. That 2.4-only module is not on the bench yet. Until it is, an SDIO id other than the AIC8800 (`0xc8a1`) is printed on the serial console and the radio is left down.

### Captured from M2WS + FlyOS-FAST H618 v1.4.0

- DTB: `fly-h618.dtb` (console **`ttyS0` @ 115200**)
- SDIO Wi-Fi named **`rtl8821cs`** in the DTB; image also ships AIC8800 bits for other radios
- MMC0 MicroSD / MMC1 Wi-Fi / MMC2 eMMC (live `mmcblk` order still needs a seated Pi V3)
- Artifacts: [m2ws-usb-pull REPORT](https://github.com/0dysseusRex/fly-bian/blob/main/flyos-artifacts/live/m2ws-usb-pull/REPORT.md)

Exact pinmux and dual-storage `mmcblk` mapping still need a board with `board=fly-pi-v3` booted.

## Until images exist

- Follow Mellow's own docs/firmware for Pi V3 if you need a working printer today.
- Watch [Releases](https://github.com/0dysseusRex/fly-bian/releases) for the first `Fly-Pi-V3` artifacts.
- Same three-flavor model as the Lite: **Base**, **Simple-AF**, **KIAUH**.

## Spoolman

KIAUH’s Spoolman extension needs Docker Engine, and the login user has to be in the `docker` group, before the install. How-to: [Spoolman needs Docker first](../boards/fly-pi-v3/spoolman.md).

## Related

- [Getting started](Getting-Started.md) (Lite today; same pattern later for Pi V3)
- [Fly Lite 2.1](Fly-Lite-2.1.md) - currently supported board
