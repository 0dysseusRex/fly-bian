# Fly Lite 2.1 — KIAUH image notes
#
# First-run lab notes (Fly-bian 0.5–0.6) and bake expectations.

## After first login

```bash
fly-kiauh            # menu: Start KIAUH / Add USB cameras
fly-kiauh cameras    # or: fly-crowsnest-add-cams
```

Trees under `/opt/fly-kiauh` are copied into `$HOME` by `fly-bind-klipper-stack`.
Bind also seeds:

- `~/printer_data/config/moonraker.conf`
- `~/printer_data/config/printer.cfg` (stub — set your MCU serial)
- nginx sites for Fluidd (`:80`) and Mainsail (`:4409`) under
  `/etc/nginx/sites-available/{fluidd,mainsail}`

Skip Moonraker “speedups” / uvloop compile on this 512 MB board.

**Board hardware README:** [`boards/fly-lite-2.1/README.md`](boards/fly-lite-2.1/README.md).  
**OOM / segfault recovery:** [`boards/fly-lite-2.1/oom.md`](boards/fly-lite-2.1/oom.md).

## KlipperScreen (optional, fragile on 512 MB)

KIAUH can still install KlipperScreen. On Fly Lite the upstream installer’s
big `apt install` batches (fonts, `libmpv-dev`, GTK/PyGObject) often **OOM**,
`dpkg` segfaults, and apt stays broken until repaired.

**If install already failed:**

```bash
sudo dpkg --configure -a
sudo apt -f install
```

**Before retrying on a live 0.6 card**, install deps slowly (or wait for the
next image that pre-bakes them):

```bash
# After next bake ships this helper on the card:
fly-klipperscreen-prep
# then: fly-kiauh → Install → KlipperScreen (prefer X11)
```

One-shot recovery without the helper (still easy to OOM):

```bash
sudo dpkg --configure -a
# then install packages ONE at a time, e.g.:
sudo apt-get install -y --no-install-recommends libmpv-dev
# …repeat for each of: fonts-nanum fonts-ipafont and the PyGObject list
```

**Next KIAUH bakes** pre-install X11 + PyGObject + fonts/mpv and a
`.KlipperScreen-env` at image build time so on-device KIAUH mostly wires the
service. Even then, prefer Fluidd/Mainsail in a browser when possible.

## Prefer not to install on this board

| Item | Why |
| --- | --- |
| **KlipperScreen** (if you can avoid it) | Apt/X stack OOMs; can break `dpkg`. Use `fly-klipperscreen-prep` if you insist. |
| **Simple-AF / pellcorp** | Wrong stack for this card. |
| **Blind `apt upgrade` / KIAUH “system packages”** | After a failed KS/`dpkg` interrupt, upgrades fail until `sudo dpkg --configure -a`. Do not upgrade kernel / DTB / U-Boot from KIAUH. |

## KIAUH community extensions (512 MB)

Anything that does **git clone + venv/pip + an always-on agent** (or Docker /
KlipperScreen) can OOM this board — OctoEverywhere has already caused a
kernel oops (`BAD_PAGE`) here. Prefer phone/PC companion apps when offered.

**Avoid / very heavy**

| Extension | Why |
| --- | --- |
| **OctoEverywhere** (on-device) | Proven OOM → kernel oops. Use the **OctoEverywhere companion app**. |
| **OctoApp** | Same pattern (clone + `install.sh` + venv + persistent agent). |
| **Obico** | Moonraker companion + venv; camera/AI path is RAM-hungry. |
| **OctoPrint** | Full second stack + its own venv. |
| **Spoolman (Docker)** | Needs Docker; not viable on this image/board. |
| **DroidKlipp** | Requires **KlipperScreen** (already fragile here). |

**Moderate — install can spike; keep at most one if any**

| Extension | Notes |
| --- | --- |
| **Mobileraker** | Companion service + venv/install script. |
| **Moonraker Telegram Bot** | Another Python venv + always-on process. |
| **Moongate** | Extra Moonraker plugin/service; lighter than OE, still extra RAM. |

**Usually fine (config / static / small module)**

- SimplyPrint (Moonraker config)
- KAMP, TMC Autotune, G-Code Shell Command
- Mainsail Theme Installer, PrettyGCode (static + nginx)
- Klipper-Backup (scripts/git)

Do not stack several “moderate” agents with Klipper + Moonraker + Crowsnest.
After a heavy install hang: 5 V power-cycle and wait a few minutes before
powering back on.

## First-run pitfalls (0.5 bake)

Observed when KIAUH showed Klipper/Moonraker as installed but UIs as partial:

1. **Fluidd / Mainsail install menus crashed** — missing nginx sites; fixed by
   seeding nginx on bind (0.6+).
2. **Mainsail-Config / update_manager** — missing `moonraker.conf` /
   `printer.cfg`; fixed by stubs on bind (0.6+).
3. **OctoEverywhere** — “No moonraker instances” until Moonraker runs; still
   not recommended on-device. On-device install has caused kernel oops (OOM).
4. **TMC Autotune** — needs `printer.cfg` (stub provided).
5. **MOTD `fly-commands` return code 1** — first login before Wi-Fi route;
   fixed in `42-fly-commands`.
6. **Mainsail PolKit / PackageKit warnings** — the 0.6 on-card
   `fly-moonraker-polkit` only installed PolKit rules; PackageKit is not
   installed, so Moonraker still warned until `enable_packagekit: False`
   is set under `[update_manager]` in `~/printer_data/config/moonraker.conf`
   and Moonraker is restarted. Next images seed that key and the helper
   patches it. Do not install PackageKit on 512 MB.

## USB cameras

After Crowsnest exists:

```bash
fly-kiauh cameras
# or: fly-crowsnest-add-cams
```

## Related

- Product naming: [`image-naming.md`](image-naming.md)
- Hardware / reboot notes: [`fly-lite-armbian-notes.md`](fly-lite-armbian-notes.md)
