# How to use the Fly-bian KIAUH image

Flash the **KIAUH** release (`Fly-bian-…_Fly-Lite-2.1_KIAUH-….img.xz`), not the Base or Simple-AF image. This card already has [KIAUH](https://github.com/dw-0/kiauh) plus stock Klipper / Moonraker / Fluidd / Mainsail trees under `/opt`; first login copies them into your home.

**Not FlyOS. Not official Mellow.** Unofficial Armbian + KIAUH for Fly Lite 2.1.

## Upstream KIAUH

| Resource | URL |
| --- | --- |
| KIAUH repo | [github.com/dw-0/kiauh](https://github.com/dw-0/kiauh) |

Do **not** install Simple-AF / pellcorp on this card — the stacks conflict.

## Flash and first boot

1. Write the `.img.xz` (Pi Imager, Etcher, or `dd` — see main [README](../README.md)).
2. Eject, unplug, replug so **`FLY-SETUP`** appears.
3. Edit `fly-start.txt`: Wi-Fi (2.4 GHz), locale/timezone, root, sudo user.  
   KIAUH images do **not** use Simple-AF `INSTALL_CMD` / GrumpyScreen keys — only network and accounts.
4. Fit the IPEX antenna. Independent **5 V**. Wait for resize + swap + Wi-Fi.
5. SSH: `ssh USER_NAME@THE.PRINTER.IP`.

Board details: [`boards/fly-lite-2.1/README.md`](boards/fly-lite-2.1/README.md).

## After login

```bash
fly-help                 # Fly-bian helpers
fly-kiauh                # menu: Start KIAUH / Add USB cameras
fly-kiauh cameras        # same as fly-crowsnest-add-cams
```

`fly-kiauh` opens the usual KIAUH menu. Trees are already present — you mainly **enable** components, set MCU serial in `~/printer_data/config/printer.cfg`, and avoid re-cloning everything if KIAUH offers a fresh install.

Bind seeds (when present):

- `~/printer_data/config/moonraker.conf`
- `~/printer_data/config/printer.cfg` (stub — set your MCU serial)
- nginx for Fluidd (`:80`) and Mainsail (`:4409`)

Skip Moonraker “speedups” / uvloop compile on this 512 MB board.

## USB cameras

```bash
fly-kiauh cameras
# or
fly-crowsnest-add-cams
```

Stream example: `http://<board-ip>:8080/?action=stream`.

## 512 MB — prefer browser UIs

Prefer Fluidd/Mainsail in a browser. KlipperScreen often OOMs apt/`dpkg` on the Lite — see lab notes in [`kiauh-fly-lite.md`](kiauh-fly-lite.md).

**Avoid:** OctoEverywhere (on-device), OctoApp, Obico, OctoPrint, Spoolman/Docker, DroidKlipp.  
**Diagnose / repair:** [`boards/fly-lite-2.1/oom.md`](boards/fly-lite-2.1/oom.md).

Do not let KIAUH upgrade the kernel, DTB, or U-Boot.

Soft `reboot` often hangs — **5 V power cycle**, with a few minutes between cycles.

## More detail

[`kiauh-fly-lite.md`](kiauh-fly-lite.md) — extension table, KlipperScreen recovery, camera notes.
