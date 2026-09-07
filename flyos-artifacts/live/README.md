# Live FlyOS dumps

Nothing here yet. `192.168.1.147` is not reachable from the cloud workspace.

From a PC on the same LAN as the Lite (FlyOS booted, Wi-Fi up, or serial-forwarded SSH):

```bash
FLYOS_HOST=192.168.1.147 ./scripts/pull-live-flyos.sh
```

Each run creates `pull-<utc>/` and points `LATEST` at it. Review `klipper-config/` for secrets before committing.
