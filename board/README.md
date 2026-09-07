# Fly Lite 2.1 board notes

Current target for Fly Debian. See `docs/project.md` for the image family and later boards.

Compact Allwinner H3 host. Not a printer MCU. Not a Raspberry Pi.

## Hardware that matters for Debian

| Piece | Notes |
| --- | --- |
| SoC | Allwinner H3, 4× Cortex-A7, 32-bit, Mali-400 |
| RAM | 512 MB DDR3 |
| Boot | MicroSD only. No eMMC. |
| Network | Onboard 2.4 GHz Wi-Fi, IPEX1. No Ethernet jack. |
| USB-A | Two USB 2.0 hosts |
| Type-C | 5 V power and, on FlyOS, a USB serial console |
| Display | FPC-HDMI and FPC-TFT. Test one at a time. |
| Power | Independent 5 V. Do not feed from a printer MCU. |

## Closest public board file

[`sun8i-h3-orangepi-lite.dts`](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/tree/arch/arm/boot/dts/allwinner/sun8i-h3-orangepi-lite.dts)

That file already enables MMC0 (SD), MMC1 (SDIO Wi-Fi), EHCI/OHCI 1 and 2, HDMI, UART0, and USB PHY.

## What Fly likely changed

- Type-C instead of micro-USB OTG / UART wiring
- FPC instead of full-size HDMI
- FPC-TFT SPI pinmux
- LED GPIOs
- Wi-Fi regulator / reset GPIO, if not a stock RTL8189FTV on MMC1

Dump those from the official H3 FlyOS image with `scripts/extract-flyos.sh`.

- Debian image: https://www.armbian.com/orange-pi-lite/
- Trixie Minimal CLI: https://dl.armbian.com/orangepilite/Trixie_current_minimal
- FlyOS Lite2 / 2.1: https://mellow.klipper.cn/en/docs/ResDownload/system-img/fly-lite2/

## Power and antennas

- Fit the IPEX antenna before judging Wi-Fi.
- Type-C cable must be data-capable if you want serial.
- Official docs: Lite 2.1 does not support being powered by a lower-level controller.
