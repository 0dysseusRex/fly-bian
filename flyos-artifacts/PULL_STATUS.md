# Pull status

| Source | Status | Notes |
| --- | --- | --- |
| Live board `192.168.1.147:22` | **Unreachable from this workspace** | Ping 100% loss. COM4 is on the user's Windows PC. |
| Official H3 FlyOS `.img` | Not mirrored as a stable direct URL | Download page works; file sits behind the Mellow release UI / Drive. |
| `sun8i-h3-orangepi-lite.dts` | Seeded | `reference/` |
| FLY-TFT overlay + README | Seeded | Pi pinmux only |
| USB-Accelerometer README | Seeded | |
| Official Lite 2.1 Klipper docs | Captured into `docs/klipper-pins-and-macros.md` | KPPM pin `host:gpiochip1/gpio8` |

Next action on the user's LAN: `./scripts/pull-live-flyos.sh`
