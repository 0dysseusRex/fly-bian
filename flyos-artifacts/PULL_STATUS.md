# Pull status

| Source | Status | Notes |
| --- | --- | --- |
| M2WS USB gadget (H618 v1.4.0) | **Pulled** | `live/m2ws-usb-pull/` — DTB, boot.scr, Wi-Fi fw/modules, config.txt. See REPORT.md |
| Live Lite `192.168.1.147:22` | **Unreachable from this workspace** | Ping 100% loss. COM4 is on the user's Windows PC. |
| Official H3 FlyOS `.img` | Not mirrored as a stable direct URL | Download page works; file sits behind the Mellow release UI / Drive. |
| `sun8i-h3-orangepi-lite.dts` | Seeded | `reference/` |
| FLY-TFT overlay + README | Seeded | Pi pinmux only |
| USB-Accelerometer README | Seeded | |
| Official Lite 2.1 Klipper docs | Captured into `docs/klipper-pins-and-macros.md` | KPPM pin `host:gpiochip1/gpio8` |

Next: seat M2 on Pi V3 with `board=fly-pi-v3`, capture serial + live `mmcblk` / `wlan` bind.
