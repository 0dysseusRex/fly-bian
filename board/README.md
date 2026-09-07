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

## Live U-Boot (Armbian 2026.07 on Lite 2.1)

Confirmed on serial: H3, 512 MiB, model `Xunlong Orange Pi Lite`, USB EHCI/OHCI 1 and 2 up, no Ethernet. SPL loads from the SD card (`Trying to boot from MMC1`), then U-Boot treats `mmc0` as empty. `mmc dev 0 0 1` does **not** skip card-detect in this U-Boot. `mmc1` is SDIO Wi-Fi (`voltage select -110`), not the boot card.

Orange Pi Lite DTB: `cd-gpios = PF6`, active-low. On the Fly, PF6 is not a working CD. At the `=>` prompt, pull PF6 low or delete `cd-gpios` from the live FDT, then `mmc dev 0`. Overlay for Linux: `overlays/sd-broken-cd.dts`. U-Boot will need the same in its DTB before autoboot works.

- Debian image: https://www.armbian.com/orange-pi-lite/
- Trixie Minimal CLI: https://dl.armbian.com/orangepilite/Trixie_current_minimal
- FlyOS Lite2 / 2.1: https://mellow.klipper.cn/en/docs/ResDownload/system-img/fly-lite2/

## Power and antennas

- Fit the IPEX antenna before judging Wi-Fi.
- Type-C cable must be data-capable if you want serial.
- Official docs: Lite 2.1 does not support being powered by a lower-level controller.
