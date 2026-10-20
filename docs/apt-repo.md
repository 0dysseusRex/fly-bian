# Fly-bian apt repo (maintainers)

User how-to: [`howto-update.md`](howto-update.md). This page is how we build and gate the packages.

## Goal

Ship **Architecture: all** helper packages so a running card can pull script/overlay fixes over SSH without a reflash. Kernel, DTB, and U-Boot stay apt-held. Klipper/Moonraker trees stay git (KIAUH / Simple-AF).

One repo, not one repo per image file. Package **version** follows repo `FLYBIAN_VERSION` (Lite product line). Pi V3 bake stamps (`0.75`, …) are independent; the **min-image** table decides whether that card may install the package set.

## Packages

| Package | Who gets it | Contents |
| --- | --- | --- |
| `flybian-release` | every Fly-bian card | apt source, `min-image`, `flybian-update`, version files |
| `flybian-common` | every card | `fly-help`, `fly-apply`, cameras, swap helper, MOTD, ip-announce |
| `flybian-board-fly-lite-21` | Lite only | Lite overlays + isolcpus helper |
| `flybian-board-fly-pi-v3` | Pi V3 only | Pi V3 overlays + fly-start templates; compiles `.dtbo` when `dtc` exists |
| `flybian-kiauh-installer` | KIAUH flavor | `fly-kiauh` + home bind (not Klipper) |
| `flybian-simpleaf-helpers` | Simple-AF flavor | `fly-start`, Grumpy/Plymouth helpers (not pellcorp) |

Board packages **conflict** with each other. Flavor helper packages **conflict** with each other. Base images install release + common + board only.

Files are copied from `armbian/userpatches/overlay/` at package build time. Edit the overlay, then rebuild debs. Do not duplicate helpers inside `apt/`.

## Minimum image gate

`armbian/userpatches/overlay/apt/min-image`:

```
Fly-Lite-2.1	1.00
Fly-Pi-V3	0.70
```

`flybian-release` **preinst** compares `/etc/fly-debian/flybian-image-baked` (fallback: `flybian-version`) to that line. Rank is `major*100 + minor` (`0.75` → 75, `1.06` → 106). If the card is older, install fails with the reflash instructions in `howto-update.md`.

**Bump a min-image line** in the same commit as a change that cannot run on older cards:

- U-Boot / SPL
- Partition / `FLY-SETUP` layout
- Kernel ABI the overlays assume
- Removal of a boot contract the old extraargs still need

Do **not** bump min-image for `fly-kiauh` ownership, MOTD, or overlay source-only fixes.

## Build

```bash
bash scripts/build-flybian-apt.sh
```

On WSL the output is `$HOME/fly-build/flybian-apt/` (dpkg-deb refuses the 0777 Windows mount). Native Linux uses `apt/out/` (gitignored). Override with `FLY_APT_OUT`.

Writes:

- `repo/pool/main/f/*.deb`
- `repo/dists/trixie/main/binary-all/Packages.gz`
- `flybian-debs-<FLYBIAN_VERSION>.tar.gz` — attach to a GitHub Release

Needs `dpkg-deb` (and `dpkg-scanpackages` if present). Run under WSL.

## Publish (Fly-bian 1.0+)

Do **not** upload apt or images for product versions **under 1.0**.

1. Build debs after bumping `FLYBIAN_VERSION`.
2. Copy `apt/out/repo/` to GitHub Pages at `https://0dysseusrex.github.io/fly-bian/apt/` (`dists/` + `pool/`).
3. Attach `flybian-debs-*.tar.gz` to the same GitHub Release as the images.
4. On new bakes, set `Enabled: yes` in `overlay/apt/flybian.sources` once that URL actually serves `Packages`.

Until step 4, images ship the source with `Enabled: no` so `apt update` does not error on a missing Pages site.

Signing: `Trusted: yes` is a stand-in. Add a repo keyring package before calling this a public production apt. Do not commit a private GPG key.

## Bake integration

`customize-image.sh` writes:

| Path | Role |
| --- | --- |
| `/etc/fly-debian/flybian-image-baked` | Never overwritten by apt |
| `/etc/fly-debian/flybian-version` | Bake stamp; apt later sets this to the package version |
| `/etc/fly-debian/flybian-apt-version` | Written by `flybian-release` postinst |
| `/etc/apt/sources.list.d/flybian.sources` | Helper repo (disabled until Pages is live) |

New cards still install helpers from the overlay (same as today). The first `flybian-update` / `dpkg -i --force-overwrite` lets dpkg own those paths.

## Lab check

On a running card that meets min-image:

```bash
sudo /usr/lib/fly-debian/check-min-image && echo OK
```

Install the matching board deb first if `flybian-device` is `Fly-Pi-V3` vs `Fly-Lite-2.1`.
