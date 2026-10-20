# Update Fly-bian over SSH (keep printer data)

Use this when the board is already running and you do **not** want to lose `printer.cfg`, gcode, Moonraker history, or Wi-Fi. Fly-bian helper packages replace scripts, overlays, and MOTD. They do **not** replace the kernel, DTB, or U-Boot.

**Not FlyOS OTA.** This is Debian `apt` for Fly-bian files only.

## What stays, what changes

| Stays on the card | May update | Still needs a new image |
| --- | --- | --- |
| `~/printer_data` | `fly-help`, `fly-kiauh`, `fly-start`, `fly-apply` | SPL / U-Boot |
| User account, SSH keys | Board overlays (`.dtbo`) | Partition layout / `FLY-SETUP` |
| Klipper/Moonraker git trees | Swap helper, MOTD, bind scripts | Debian release jump (e.g. Trixie → next) |
| Kernel / DTB / U-Boot (held) | | Kernel ABI the helpers cannot assume |

Simple-AF and KIAUH **stacks** still update with `~/pellcorp/installer.sh --update` or the KIAUH menu, not with this apt.

## Before you start

```bash
# Who you are
cat /etc/fly-debian/flybian-device
cat /etc/fly-debian/flybian-image-baked
cat /etc/fly-debian/flybian-version
cat /etc/fly-debian/stack-flavor

# Optional backup of printer data (on the card or scp off)
tar -C "$HOME" -czf "$HOME/printer_data-backup.tgz" printer_data
```

Cards baked before this feature exist only have `flybian-version` (no `flybian-image-baked`). `flybian-update` then uses `flybian-version` as the bake stamp.

## After the public apt repo is up (Fly-bian 1.0+)

The source file is already on new images at `/etc/apt/sources.list.d/flybian.sources` with `Enabled: no` until the GitHub Pages repo exists.

```bash
sudo sed -i 's/^Enabled: no/Enabled: yes/' /etc/apt/sources.list.d/flybian.sources
sudo flybian-update
```

`flybian-update` installs:

- `flybian-release` — version gate + apt source
- `flybian-common` — shared helpers
- `flybian-board-fly-lite-21` **or** `flybian-board-fly-pi-v3`
- `flybian-kiauh-installer` on KIAUH cards, or `flybian-simpleaf-helpers` on Simple-AF cards

It uses `dpkg --force-overwrite` once so files that were copied at bake (not owned by dpkg yet) can be taken over. Kernel packages stay on hold.

Check:

```bash
cat /etc/fly-debian/flybian-image-baked   # original flash
cat /etc/fly-debian/flybian-apt-version   # helper package set
```

## Until the apt URL is live (debs by hand)

On a PC, from this repo:

```bash
bash scripts/build-flybian-apt.sh
```

Copy `apt/out/flybian-debs-<ver>.tar.gz` to the board, then:

```bash
mkdir -p ~/flybian-debs && tar -C ~/flybian-debs -xzf flybian-debs-*.tar.gz
cd ~/flybian-debs
sudo dpkg -i --force-overwrite flybian-release_*.deb flybian-common_*.deb
# board package (pick one):
sudo dpkg -i --force-overwrite flybian-board-fly-pi-v3_*.deb
# or: sudo dpkg -i --force-overwrite flybian-board-fly-lite-21_*.deb
# flavor (if this is a stack image):
sudo dpkg -i --force-overwrite flybian-kiauh-installer_*.deb
# or: sudo dpkg -i --force-overwrite flybian-simpleaf-helpers_*.deb
sudo apt-get install -f -y
```

If `dpkg` prints the min-image error below, stop. Do not `--force` past it.

## When apt says you must reflash

The package set carries a **minimum baked image** per board (`/usr/share/fly-debian/min-image`). If this card is older than that line, install **stops** and prints the reason.

Typical causes: U-Boot/SPL, partition map, or a kernel the helpers cannot run on.

1. Copy `~/printer_data` (and `~/.ssh` if you want) off the board.
2. Flash the current Fly-bian image for **this** board and flavor.
3. First boot, create the same user if you can, then copy `printer_data` back onto `~/printer_data`.
4. Do not flash a Lite image onto a Pi V3 (or the reverse).

`printer.cfg` MCU serial paths and `fly-start.txt` Wi-Fi are independent of the helper packages. Restore those from the backup.

## What not to do

- Do not `apt-mark unhold` `linux-image-*`, `linux-dtb-*`, or `linux-u-boot-*`.
- Do not `apt full-upgrade` and assume Fly-bian kernel packages from Armbian are safe.
- Do not install Simple-AF helpers on a KIAUH card (or the reverse). The packages conflict.
- Do not use this to skip a Debian release upgrade. That is still a new image.

## Maintainers

How packages are built and when to bump min-image: [`apt-repo.md`](apt-repo.md).
