# FLY-TFT vendor slice

Copied from https://github.com/Mellow-3D/FLY-TFT (Raspberry Pi overlay + README).

Useful for Debian on the Lite:

- Panel is **ST7796**, 320×480, SPI
- Resistive touch: `ti,ads7846`
- Capacitive touch: `goodix,gt911` at `0x14` or `0x5d`
- Compatible string: `mellow,fly-tft-v2`

**Not** useful as-is:

- `compatible = "brcm,bcm2835", …` — Broadcom, not Allwinner H3
- GPIOs 6 / 13 / 19 / 24 / 26 are Raspberry Pi numbers

On FlyOS-FAST the Lite uses `screen=fly-tft-v2-r` in `sys-config.conf` and a **16P** FPC. Extract the H3 DTB (live pull or official image) before enabling `overlays/fly-tft-spi-candidate.dts`.
