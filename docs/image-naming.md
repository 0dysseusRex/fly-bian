# Fly-bian image naming

Product releases use a **Fly-bian** version that is independent of the Armbian
framework / kernel version string. Pre-1.0 builds are WIP; **1.0** is the first
fully working release we are willing to call done.

## Filename

```
Fly-bian-<VERSION>_<DEVICE>_<FLAVOR>.img.xz
Fly-bian-<VERSION>_<DEVICE>_Simple-AF-<PELLCORP_SHA>.img.xz
Fly-bian-<VERSION>_<DEVICE>_KIAUH-<KIAUH_REV>.img.xz
```

| Part | Meaning | Examples |
| --- | --- | --- |
| `VERSION` | Fly-bian product version | `0.1`, `0.2`, … `1.0` |
| `DEVICE` | Board this image is for | `Fly-Lite-2.1`, later `Fly-Pi-V3` |
| `FLAVOR` | Stack baked into the image | `Base`, `Simple-AF`, `KIAUH` |
| `PELLCORP_SHA` | Short git HEAD of pellcorp/`creality` at bake | `58e5c1d` |
| `KIAUH_REV` | KIAUH `git describe --tags` (or short SHA) at bake | `v6.0.0`, `abc1234` |

Examples:

```
Fly-bian-0.6_Fly-Lite-2.1_Base.img.xz
Fly-bian-0.6_Fly-Lite-2.1_Simple-AF-58e5c1d.img.xz
Fly-bian-0.6_Fly-Lite-2.1_KIAUH-v6.0.0.img.xz
```

Rules:

- Use hyphens in the Fly-bian / device / stack-rev tokens; underscore only between the three main parts (`VERSION`, `DEVICE`, `FLAVOR[-rev]`).
- No spaces in the filename (Windows / Etcher friendly).
- Sidecars keep the same stem: `.img.xz.sha`, `.img.txt` (Armbian provenance + stack revision).
- Release **folders** stay `…/Simple-AF/` and `…/KIAUH/` (no rev in the directory name); only the **filename** carries the stack revision.
- **Every new image publish bumps the version.** Before the next Base / Simple-AF /
  KIAUH bake (or any restage that replaces flashable artifacts), raise
  `FLYBIAN_VERSION` in the repo root (`0.2` → `0.3` → … → `1.0`). Do not reuse a
  version number for a new build. Use `scripts/bump-flybian-version.sh` or edit
  the file by hand. Staging refuses to overwrite an existing
  `Releases/Fly-bian-<ver>/…` flavor tree unless `FLY_FORCE=1`.

## Flavors

| Flavor token | Armbian `BOARD` (build only) | What it is |
| --- | --- | --- |
| `Base` | `fly-lite-21` | Hardware + first-boot; no Klipper installer bake |
| `Simple-AF` | `fly-lite-21-simpleaf` | pellcorp / Simple-AF pre-bake |
| `KIAUH` | `fly-lite-21-kiauh` | KIAUH pre-bake |

Armbian still emits long `Armbian-unofficial_…` names during compile. Staging
renames (or copies as) the Fly-bian product name above. Do not publish the
Armbian-unofficial name as the user-facing release name.

Bake writes `output/images/flybian-meta-<flavor>.txt` (`stack_rev=…`, `stem=…`)
so `scripts/stage-flybian-release.sh` can name the file without mounting the image.

## Release folder layout

```
C:\Users\udrdr\fly-lite-armbian-image\Releases\
  RELEASES.txt
  Fly-bian-0.6\
    UPDATE-NOTES.txt          # what changed in this product version
    Fly-Lite-2.1\
      Base\
      Simple-AF\              # files named …_Simple-AF-<sha>.img.xz
      KIAUH\                  # files named …_KIAUH-<rev>.img.xz
  lab-snapshots\              # old full-card dd dumps (unchanged names)
```

Kernel / Armbian trunk strings belong in `UPDATE-NOTES.txt` and the `.img.txt`
sidecar, not in the product filename (beyond the stack rev for Simple-AF / KIAUH).

## On-card identity

Named images write at bake time:

| Path | Example |
| --- | --- |
| `/etc/fly-debian/flybian-version` | `0.6` |
| `/etc/fly-debian/flybian-image` | `Fly-bian-0.6_Fly-Lite-2.1_Simple-AF-58e5c1d` |
| `/etc/fly-debian/stack-rev` | `58e5c1d` |
| `/etc/fly-debian/stack-flavor` | `simpleaf` |

`FLYBIAN_VERSION` must be bumped **before** building so filename and card match.
`fly-help` / MOTD can show `/etc/fly-debian/flybian-image`.
