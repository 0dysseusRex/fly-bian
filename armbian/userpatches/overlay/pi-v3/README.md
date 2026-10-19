# Fly Pi V3 overlay bits

Staged from `flyos-artifacts/live/m2ws-usb-pull/curated/` for Armbian Base bring-up.

| Path | Role |
| --- | --- |
| `boot/fly-h618.dtb` | OEM FlyOS-FAST H618 DTB |
| `firmware/` | M2 Wi-Fi firmware (`rtw88`, `aic8800`, `rtl_bt`) |
| `overlays/` | Optional `sun50i-h616` / `sun50i-h618` dtbos (not loaded by default) |

U-Boot still starts from `orangepi_zero3_defconfig`; customize-image forces `fdtfile=fly-h618.dtb`.

Default `user_overlays` (sibling dirs under `overlay/`):

| Overlay | Role |
| --- | --- |
| `io/fly-pi-v3-io` | uart1/3/4 (FlyOS `board=fly-pi-v3` pinmux) |
| `usb/fly-pi-v3-usb` | Four USB-A EHCI/OHCI hosts + VBUS; Type-C musb peripheral |
| `hdmi/fly-pi-v3-hdmi` | DW-HDMI + connector (Micro HDMI and FPC-HDMI) |
| `tft/fly-pi-v3-tft` | Fly TFT V2 SPI panel (`panel-mipi-dbi` / ST7796) + resistive touch |
| `tft/fly-pi-v3-tft-c` | Capacitive GT911 (disables ADS7846) |

TFT owns SPI1 — leave FPC-TFT unplugged when using the ZH1.5-7P ADXL/RRF header.

## LEDs

`fly-h618.dtb` already defines `gpio-leds` (status **PI0** heartbeat, power **PI16** on, eth **PH2/PH3**). Do not ship a LEDs overlay (Lite `-EBUSY` lesson). `config/modules-load.d/fly-gmac-leds.conf` loads `ledtrig-netdev` for the eth pair.

## U-Boot

`userpatches/u-boot/v2026.07-sunxi64/board_fly-pi-v3/` enables `CONFIG_MMC_SUNXI_SLOT_EXTRA=2` + `&mmc2` so SPL can boot M2WE eMMC (`Trying to boot from MMC2`).
