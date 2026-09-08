# Fly Lite 2.1 board notes

Current target. User-facing steps: [`../README.md`](../README.md). Named image: [`../docs/build-named-image.md`](../docs/build-named-image.md). Lab log: [`../docs/fly-lite-armbian-notes.md`](../docs/fly-lite-armbian-notes.md).

Compact Allwinner H3 host. Not a printer MCU. Not a Raspberry Pi.

## Hardware

| Piece | Notes |
| --- | --- |
| SoC | Allwinner H3, 4× Cortex-A7, 32-bit, Mali-400 |
| RAM | 512 MB DDR3 |
| Boot | MicroSD only. No eMMC. |
| Network | Onboard 2.4 GHz Wi-Fi, IPEX1. No Ethernet jack. |
| USB-A | Two USB 2.0 hosts |
| Type-C | 5 V power and a real UART (CH340 on Windows, 115200 8N1). Do not pulse DTR/RTS. |
| Display | FPC-HDMI and FPC-TFT. Leave TFT unplugged for first boot. |
| Power | Independent 5 V. Do not feed from a printer MCU. |

Closest public DTS: [sun8i-h3-orangepi-lite.dts](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/tree/arch/arm/boot/dts/allwinner/sun8i-h3-orangepi-lite.dts). The working image uses Fly’s `sun8i-h3-fly-lite.dtb`.

## Stock Orange Pi Lite image (recovery only)

SPL loads from SD, then U-Boot treats `mmc0` as empty: Orange Pi Lite `cd-gpios = PF6`. On the Fly, PF6 is not CD. Named image must patch U-Boot **and** Linux. Manual paste for a stock card: [`docs/lite21-bringup.md`](../docs/lite21-bringup.md).

Stock Trixie Minimal is **one ext4** (no `FLY-SETUP`). The named image is not that layout.

- Board page (HTML, not a binary short URL): https://www.armbian.com/orange-pi-lite/
- FlyOS Lite2 / 2.1 (loot DTB only): https://mellow.klipper.cn/en/docs/ResDownload/system-img/fly-lite2/
