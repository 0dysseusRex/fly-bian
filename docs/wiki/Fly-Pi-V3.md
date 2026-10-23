# Fly Pi V3

![Fly Pi V3](https://raw.githubusercontent.com/0dysseusRex/fly-bian/main/docs/boards/fly-pi-v3/fly-pi-v3.jpg)

**Status:** Supported — use Fly-bian **1.05** images whose names contain `Fly-Pi-V3`. Product version is independent of the Lite line (Lite is 1.06).

Board notes in the repo: [docs/boards/fly-pi-v3/README.md](https://github.com/0dysseusRex/fly-bian/blob/main/docs/boards/fly-pi-v3/README.md).

## Important

**Do not flash Fly Lite 2.1 images** (`Fly-Lite-2.1` in the filename) onto a Fly Pi V3. Wrong SoC / boot / device tree.

Download from [Releases](https://github.com/0dysseusRex/fly-bian/releases/tag/v1.05-pi-v3):

- `Fly-bian-1.05_Fly-Pi-V3_Base.img.xz`
- `Fly-bian-1.05_Fly-Pi-V3_Simple-AF-ea7125a.img.xz`
- `Fly-bian-1.05_Fly-Pi-V3_KIAUH-v6.3.2.img.xz`

Flash flow matches [Getting started](Getting-Started.md): burn MicroSD (or M2WE eMMC) → `FLY-SETUP` / wizard → SSH → `fly-start` or `fly-kiauh`.

## Quick facts

| Item | Detail |
| --- | --- |
| SoC | Allwinner H618, quad Cortex-A53 |
| RAM | **1 GB DDR4** |
| Swap | **512 MiB** `fly-swapfile` after first-boot resize |
| Kernel | **6.12.114** `legacy-sunxi64`, DTB `fly-h618.dtb` |
| Storage | Onboard MicroSD and/or official FLY **M2** module (private socket) |
| Ethernet | 100 Mb — easiest first network path |
| Wi-Fi | From an M2 module (or USB). No onboard radio |
| Power | DC 12–24 V **or** Type-C 5 V / ≥2 A (choose one) |
| Debug | Type-C CH340 UART, **115200 8N1**, no flow control. Do not pulse DTR/RTS |
| Display | FPC-HDMI (Fly HDMI cable 800×480) and/or micro HDMI; FPC-TFT 16P |

## M2 module variants

| Module | Wi-Fi | Module storage |
| --- | --- | --- |
| M2 2.4G Wi-Fi only | 2.4 GHz | None (use onboard MicroSD for OS) |
| **M2WE** | 2.4 + 5 GHz | 16 GB eMMC |
| **M2WS** | 2.4 + 5 GHz | 16 GB soldered TF on the module |

**Do not flash the image onto both the onboard MicroSD and the module eMMC (or M2WS TF).** One medium holds the OS. If you flash a MicroSD while factory FlyOS is still on the eMMC, the board boots FlyOS. Blank or remove the module storage first, or boot from the module alone.

The 2.4 GHz-only M2 cannot join a 5 GHz network. That module is not on the bench yet: an SDIO id other than the AIC8800 is printed on the serial console and the radio is left down.

## Pi V3-specific tips

1. **Ethernet first** if you have a cable. Wi-Fi needs an official M2 module and its antenna.
2. **First boot is slow** — resize + 512 MiB swap. Keep serial open.
3. Soft **`reboot` often hangs** after `[ OK ]` — use a 5 V (or 12–24 V) power cycle.
4. Do **not** pulse DTR/RTS on the USB-UART.
5. For GrumpyScreen, use the **Fly HDMI cable** (HDMI framebuffer + USB touch). The SPI TFT is a second framebuffer and stays blank.
6. Do **not** unmask `systemd-udev-trigger`.
7. Simple-AF / KIAUH after login: `fly-start` or `fly-kiauh`. KIAUH Spoolman needs Docker first — [spoolman.md](../boards/fly-pi-v3/spoolman.md).

## After login

```bash
fly-help
fly-start          # Simple-AF image
fly-kiauh          # KIAUH image
fly-crowsnest-add-cams
fly-grumpy-rotate  # Simple-AF / GrumpyScreen
sudo fly-media-sd status                 # extra STLs / timelapse (Pi V3 only)
sudo fly-media-sd enable                 # first run may ask for a power cycle
sudo fly-media-sd disable                # unbind before unplugging extra media
```

`fly-media-sd` is **Pi V3 only**. With the OS on M2WE eMMC / M2WS, extra storage is a second card in the onboard TF slot. With the OS on the onboard MicroSD, extra storage is one USB flash drive or a MicroSD in a USB reader. Do not flash a Fly-bian image onto that extra media. **Do not unplug it until `disable`.**

## Known limits

See [untested.md](../boards/fly-pi-v3/untested.md). Short list: RS232 not electrically tested, micro-HDMI jack as a monitor not plugged, ADXL/RRF header has no sensor attached, Type-C USB gadget and HDMI audio not tested, 2.4-only M2 not labbed, extra USB storage when the OS is on the onboard TF is not labbed, `systemd-udev-trigger` stays masked. **1.05** turns overlay `fly-pi-v3-sd` on by default (SD-only and eMMC first boot both proven). Stock **1.0** SD-only boot still needs that overlay copied onto `FLY-SETUP`.

## Do not flash

- Fly Lite 2.1 images
- Raspberry Pi OS, Mainsail OS
- FlyOS-FAST (different layout; keep a recovery copy if you want it)

## Related

- [Getting started](Getting-Started.md)
- [Fly Lite 2.1](Fly-Lite-2.1.md)
