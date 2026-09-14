# Fly-bian image naming

Product releases use a **Fly-bian** version that is independent of the Armbian
framework / kernel version string. Pre-1.0 builds are WIP; **1.0** is the first
fully working release we are willing to call done.

## Filename

```
Fly-bian-<VERSION>_<DEVICE>_<FLAVOR>.img.xz
```

| Part | Meaning | Examples |
| --- | --- | --- |
| `VERSION` | Fly-bian product version | `0.1`, `0.2`, … `1.0` |
| `DEVICE` | Board this image is for | `Fly-Lite-2.1`, later `Fly-Pi-V3` |
| `FLAVOR` | Stack baked into the image | `Base`, `Simple-AF`, `KIAUH` |

Examples:

```
Fly-bian-0.2_Fly-Lite-2.1_Base.img.xz
Fly-bian-0.2_Fly-Lite-2.1_Simple-AF.img.xz
Fly-bian-0.2_Fly-Lite-2.1_KIAUH.img.xz
```

Rules:

- Use hyphens in the Fly-bian / device tokens; underscore only between the three parts.
- No spaces in the filename (Windows / Etcher friendly).
- Sidecars keep the same stem: `.img.xz.sha`, `.img.txt` (Armbian provenance).
- **Every new image publish bumps the version.** Before the next Base / Simple-AF /
  KIAUH bake (or any restage that replaces flashable artifacts), raise
  `FLYBIAN_VERSION` in the repo root (`0.2` → `0.3` → … → `1.0`). Do not reuse a
  version number for a new build. Use `scripts/bump-flybian-version.sh` or edit
  the file by hand. Staging refuses to overwrite an existing
  `Releases/Fly-bian-<ver>/…` tree unless `FLY_FORCE=1`.

## Flavors

| Flavor token | Armbian `BOARD` (build only) | What it is |
| --- | --- | --- |
| `Base` | `fly-lite-21` | Hardware + first-boot; no Klipper installer bake |
| `Simple-AF` | `fly-lite-21-simpleaf` | pellcorp / Simple-AF pre-bake |
| `KIAUH` | `fly-lite-21-kiauh` | KIAUH pre-bake |

Armbian still emits long `Armbian-unofficial_…` names during compile. Staging
renames (or copies as) the Fly-bian product name above. Do not publish the
Armbian-unofficial name as the user-facing release name.

## Release folder layout

```
C:\Users\udrdr\fly-lite-armbian-image\Releases\
  RELEASES.txt
  Fly-bian-0.2\
    UPDATE-NOTES.txt          # what changed in this product version
    Fly-Lite-2.1\
      Base\
      Simple-AF\
      KIAUH\
  lab-snapshots\              # old full-card dd dumps (unchanged names)
```

Kernel / Armbian trunk strings belong in `UPDATE-NOTES.txt` and the `.img.txt`
sidecar, not in the product filename.

## On-card identity

Named images write `/etc/fly-debian/flybian-version` (e.g. `0.2`) and
`/etc/fly-debian/flybian-image` (full product stem) at bake time so SSH/`fly-help`
can show what is running. That on-card value comes from `FLYBIAN_VERSION` at
compile time — bump the file **before** building so filename and card match.
