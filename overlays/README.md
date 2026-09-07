# Device-tree overlays

These are starting points for Armbian on the Fly Lite 2.1. They assume an Orange Pi Lite compatible base DTB (`allwinner,sun8i-h3`).

```bash
sudo armbian-add-overlay overlays/sdio-wifi-rtl8189.dts
```

| File | When to use |
| --- | --- |
| `sdio-wifi-rtl8189.dts` | MMC1 is missing or disabled and you expect SDIO Wi-Fi |
| `usb-otg-peripheral.dts` | Type-C serial works on FlyOS, not on Debian, and you already have another login |
| `fly-tft-spi-candidate.dts` | Only after a FlyOS DTB dump confirms the GPIOs. Panel node is `disabled` on purpose. |

Do not apply the TFT overlay as a first experiment.
