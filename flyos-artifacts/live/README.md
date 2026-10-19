# Live FlyOS dumps

| Pull | Status |
| --- | --- |
| [`m2ws-usb-pull/`](m2ws-usb-pull/) | **Done** — H618 v1.4.0 from M2WS USB gadget (`curated/` + REPORT.md) |
| Lite SSH `192.168.1.147` | Not reachable from cloud workspace |

From a PC on the same LAN as a booted FlyOS board:

```bash
FLYOS_HOST=192.168.1.147 ./scripts/pull-live-flyos.sh
```

Each SSH run creates `pull-<utc>/` and points `LATEST` at it. Review `klipper-config/` for secrets before committing.
