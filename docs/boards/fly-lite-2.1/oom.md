# Fly Lite 2.1 — low memory (OOM), segfaults, and finishing installs

The Lite 2.1 has **512 MB RAM**. Heavy `apt` batches, big `git clone` + `pip`/`venv` installs, Docker, and always-on companion agents routinely hit the **OOM killer**. That shows up as:

- Installer “hangs” then dies
- `Killed` / exit code **137** / signal **9**
- `dpkg` / `apt` **segfault** (often after OOM, not a bad package)
- Broken package database (`dpkg was interrupted`)
- Kernel oops / `BAD_PAGE` after a severe OOM
- Rarely a corrupted `/boot/uInitrd` after a mid-apt crash (card stuck in U-Boot)

Fly-bian images create a **2 GiB `/swapfile`** on first boot. That helps, but it does **not** make KlipperScreen, Docker, or on-device OctoEverywhere safe.

## What to avoid (or prefer elsewhere)

| Prefer not to install on-device | Why / alternative |
| --- | --- |
| OctoEverywhere, OctoApp, Obico | Use the **phone/PC companion** app |
| OctoPrint | Separate full stack + venv |
| Spoolman via Docker | Docker is not viable here |
| KlipperScreen / DroidKlipp | Huge X/Mesa/`libmpv` apt storm; use **GrumpyScreen** (Simple-AF) or browser Fluidd/Mainsail |
| Moonraker “speedups” / `uvloop` | Clang compile OOMs; skip |
| PackageKit | Not needed; keep `enable_packagekit: False` in Moonraker |

**At most one** lighter agent if you insist: Mobileraker, Telegram bot, or Moongate — not several at once with Crowsnest.

## Diagnose: is it OOM?

From a **second** SSH/serial session (do not interrupt the installer TTY):

```bash
free -h
swapon --show
ls -lh /swapfile
dmesg -T | grep -iE 'oom|killed process|out of memory|segfault|bad_page' | tail -40
journalctl -b -p err --no-pager | tail -40
ps aux --sort=-%mem | head -15
```

Clues:

| Symptom | Likely cause |
| --- | --- |
| `dmesg` shows `Out of memory: Killed process …` | OOM killer |
| Process exit **137** / `Killed` during `pip`/`clang`/`apt` | OOM |
| `dpkg: error processing …` / `Segmentation fault` mid-apt | Often OOM aftermath |
| `E: dpkg was interrupted` | Recover with `dpkg --configure -a` (below) |
| `git`/`index-pack` quiet for minutes, CPU busy, memory climbing | Still working — wait |
| No git/apt process, no OOM line, Wi-Fi dead | Different issue (8189fs / power); see main Lite notes |

Confirm swap is present before heavy work:

```bash
swapon --show
# expect /swapfile ~2G on Fly-bian images after first boot
```

If swap is missing (old dump / failed first boot):

```bash
sudo systemctl start fly-swapfile.service   # if the unit exists
# or create manually only if you know the disk is resized:
# sudo fallocate -l 2G /swapfile && sudo chmod 600 /swapfile
# sudo mkswap /swapfile && sudo swapon /swapfile
```

## Repair apt/dpkg after a crash

Run these **before** retrying any installer:

```bash
sudo dpkg --configure -a
sudo apt -f install
sudo apt-get update
```

If a package keeps segfaulting in a big batch, install **one package at a time** with `--no-install-recommends`, then re-run the app installer.

```bash
sudo apt-get install -y --no-install-recommends PACKAGE_NAME
```

Do **not** `apt upgrade` kernel, DTB, or U-Boot from KIAUH/Simple-AF menus after a broken apt — fix `dpkg` first.

## Finish an install that OOM’d

1. Power-cycle only if the board is wedged (`reboot` often hangs on this hardware). Wait a few minutes between 5 V cycles.
2. Repair apt (`dpkg --configure -a` / `apt -f install`).
3. Free RAM: stop optional services you do not need during install.

```bash
sudo systemctl stop crowsnest KlipperScreen grumpyscreen 2>/dev/null || true
```

4. Retry **one** component at a time (Klipper, then Moonraker, then UI) — not a full “install everything” menu pass.
5. Prefer browser Fluidd (`:80`) / Mainsail (`:4409`) over on-device touch stacks while installing extras.
6. For KlipperScreen specifically (not recommended): see [`../../kiauh-fly-lite.md`](../../kiauh-fly-lite.md) — prep deps slowly or use `fly-klipperscreen-prep` if present, then retry.

## If the board will not boot (uInitrd / U-Boot)

A mid-apt OOM has been seen to leave a bad `/boot/uInitrd`. From another Linux machine mounting the card, or from initramfs if you can reach a shell:

```bash
# On the Lite rootfs, with correct kernel version:
sudo mkimage -A arm -O linux -T ramdisk -C gzip \
  -n uInitrd -d /boot/initrd.img-$(uname -r) /boot/uInitrd
```

(Use the matching `initrd.img-*` on the FAT `/boot` volume if you are repairing offline.)

## Slow ≠ stuck

On 512 MB + SDIO Wi-Fi, Moonraker/Klipper `git clone` and `apt-get` can sit quiet for several minutes while `index-pack` or dpkg runs. Progress is on the **SSH/installer session**, not always on serial. Details: [`../../fly-lite-armbian-notes.md`](../../fly-lite-armbian-notes.md#simple-af-and-kiauh-looks-hung-still-working).

## Related

- [Board README](README.md) — hardware overview  
- [`../../kiauh-fly-lite.md`](../../kiauh-fly-lite.md) — KIAUH extension table, KlipperScreen notes  
- [`../../fly-lite-armbian-notes.md`](../../fly-lite-armbian-notes.md) — Wi-Fi/CPU0, TFT, bring-up  
- Root [`../../../README.md`](../../../README.md) — flash flavors and RAM-heavy summary  
