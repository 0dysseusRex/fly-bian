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
# Who you are (some of these are missing on 1.0 cards — that is OK)
cat /etc/fly-debian/flybian-version
cat /etc/fly-debian/flybian-image
cat /etc/fly-debian/flybian-device
cat /etc/fly-debian/flybian-image-baked
cat /etc/fly-debian/stack-flavor

# Optional backup of printer data (on the card or scp off)
tar -C "$HOME" -czf "$HOME/printer_data-backup.tgz" printer_data
```

| File | Meaning |
| --- | --- |
| `flybian-version` | Product stamp. **1.0 Lite Base has this.** |
| `flybian-image` | `Fly-bian-1.0_Fly-Lite-2.1_Base` — enough to identify the board |
| `flybian-device` | `Fly-Lite-2.1` or `Fly-Pi-V3`. Missing before 1.05 |
| `flybian-image-baked` | Frozen flash stamp. Missing before the apt helpers |
| `stack-flavor` | `simpleaf` / `kiauh`. **Empty on Base** — do not install flavor debs |

Lite **1.00** and newer may update in place. Use only the Lite board package on a Lite card. Base images skip KIAUH and Simple-AF helper debs.

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

Copy the tarball onto the board (use the real filename, not a glob that might miss), then unpack **in that directory**:

```bash
mkdir -p ~/flybian-debs
tar -C ~/flybian-debs -xzf ~/flybian-debs-1.06.tar.gz
cd ~/flybian-debs
ls *.deb
```

Install **only** the packages for this card. Comments in older how-tos were not commands — do not install Pi V3 debs on Lite, and do not install KIAUH/Simple-AF helpers on Base.

**Lite Base** (your `flybian-version` is `1.0`, no `stack-flavor`):

```bash
sudo dpkg -i --force-overwrite \
  flybian-release_*.deb \
  flybian-common_*.deb \
  flybian-board-fly-lite-21_*.deb
sudo apt-get install -f -y
```

**Lite Simple-AF** — same three, plus `flybian-simpleaf-helpers_*.deb`.  
**Lite KIAUH** — same three, plus `flybian-kiauh-installer_*.deb`.  
**Pi V3** — use `flybian-board-fly-pi-v3_*.deb` instead of the Lite board package.

If an **already-built** 1.06 `flybian-release` still says `missing flybian-device`, write the id once, then retry the Lite Base command above:

```bash
echo Fly-Lite-2.1 | sudo tee /etc/fly-debian/flybian-device
```

Newer helper debs infer `Fly-Lite-2.1` from `/etc/fly-debian/flybian-image` and do not need that tee.

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
- Do not install `flybian-board-fly-pi-v3` on a Lite card, or Lite board debs on a Pi V3.
- Do not install KIAUH or Simple-AF helper debs on a **Base** image.
- Do not use this to skip a Debian release upgrade. That is still a new image.

## Maintainers

How packages are built and when to bump min-image: [`apt-repo.md`](apt-repo.md).
