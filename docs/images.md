# Fly-bian image dumps

**Named images** (Armbian `.img.xz`, not a 32 GB `dd`). Naming: [`image-naming.md`](image-naming.md). Build: [`build-named-image.md`](build-named-image.md).

Product versions are **Fly-bian** (repo `FLYBIAN_VERSION`). Only **1.0+** are GitHub Release candidates; pre-1.0 stays local under `Releases/`.

```
C:\Users\udrdr\fly-lite-armbian-image\Releases\
  RELEASES.txt
  Fly-bian-1.06\
    Fly-Lite-2.1\    … GitHub Release v1.06
  Fly-bian-1.05\
    Fly-Lite-2.1\    … GitHub Release v1.05
  Fly-bian-1.0\
    Fly-Lite-2.1\    … GitHub RC
  Fly-bian-0.1\
    Fly-Pi-V3\       … local bring-up only (not on GitHub Releases)
  lab-snapshots\     old full-card dd dumps
```

Stage with: `scripts/stage-flybian-release.sh` (set `FLY_DEVICE` for Pi V3).

## Fly Pi V3 (local / pre-RC)

| File | SHA256 | What it is |
| --- | --- | --- |
| `Releases/Fly-bian-0.1/Fly-Pi-V3/Base/Fly-bian-0.1_Fly-Pi-V3_Base.img.xz` | `b7897664d934dfd20adbe96bd0bbc3ea282b454801c611e2cc80a5926c127062` | **Fly-bian 0.1 Base** bring-up. Kernel 6.18.54, `fly-h618.dtb`, no Klipper stack. **Not** a GitHub Release. |

## Fly Lite 2.1

| File | SHA256 | What it is |
| --- | --- | --- |
| `Releases/Fly-bian-1.06/Fly-Lite-2.1/Base/Fly-bian-1.06_Fly-Lite-2.1_Base.img.xz` | `555e187347663010f363c2cf5800c897b9d5b384fa7974559882c5a818767e7b` | **Fly-bian 1.06 Base.** Kernel 6.18.57. One MMC transfer at a time so the SD card and the Wi-Fi chip do not unmap DMA together. The RCU grace-period thread stays on CPU 0. |
| `Releases/Fly-bian-1.06/Fly-Lite-2.1/Simple-AF/Fly-bian-1.06_Fly-Lite-2.1_Simple-AF-ea7125a.img.xz` | `e1aa28d08138b511f235b51a4fc1852bcf08767ed7ac9a8fdb37307ddf8b8cd2` | **Fly-bian 1.06 Simple-AF** (pellcorp `ea7125a`). Moonraker `9e676eb`, pellcorp Klipper `2f08ab4`. How-to: [`howto-simpleaf.md`](howto-simpleaf.md). |
| `Releases/Fly-bian-1.06/Fly-Lite-2.1/KIAUH/Fly-bian-1.06_Fly-Lite-2.1_KIAUH-v6.3.2.img.xz` | `d79cd6858a16dc54c1d5f474fa707dce6db4d8babbe3d1e76ff3f84def3296c8` | **Fly-bian 1.06 KIAUH** (`v6.3.2`, latest tag). Klipper `c63b295`, Moonraker `9e676eb`. How-to: [`howto-kiauh.md`](howto-kiauh.md). |
| `Releases/Fly-bian-1.05/Fly-Lite-2.1/Base/Fly-bian-1.05_Fly-Lite-2.1_Base.img.xz` | `4fcabd93ee91408a84a58497743d960c6745955787c84c631256bdaa44ec2730` | **Fly-bian 1.05 Base.** Kernel 6.18.57. `fly-lite-board` holds `vdd-cpux` at 1.3 V and disables the unused EMAC. Apt installs one named package at a time. `SERIAL_CONSOLE` in `fly-start.txt`. |
| `Releases/Fly-bian-1.05/Fly-Lite-2.1/Simple-AF/Fly-bian-1.05_Fly-Lite-2.1_Simple-AF-707e558.img.xz` | `2079250936b6359d91cc5f9400a5c44443fa77c5e3621149fc27ac87c2dbcbfd` | **Fly-bian 1.05 Simple-AF** (pellcorp `707e558`). How-to: [`howto-simpleaf.md`](howto-simpleaf.md). |
| `Releases/Fly-bian-1.05/Fly-Lite-2.1/KIAUH/Fly-bian-1.05_Fly-Lite-2.1_KIAUH-v6.3.2.img.xz` | `e61afaa7d1743a1be18687ab952b06bf74abfa60c07686ceb92e0701cd443dd2` | **Fly-bian 1.05 KIAUH** (`v6.3.2`). How-to: [`howto-kiauh.md`](howto-kiauh.md). |
| `Releases/Fly-bian-1.0/Fly-Lite-2.1/Base/Fly-bian-1.0_Fly-Lite-2.1_Base.img.xz` | `37c5c33ad61880bf9670c64e24428edc41e655f5697abc9e6b2b85cc22033c1d` | **Fly-bian 1.0 Base.** Kernel 6.18.54, Cap TFT/GT911 defaults, SPI firmware. |
| `Releases/Fly-bian-1.0/Fly-Lite-2.1/Simple-AF/Fly-bian-1.0_Fly-Lite-2.1_Simple-AF-0d21afe.img.xz` | `3523ba04239469a7654b9d3b5ce8d07d9bf0d138a92ea3c833cd38d0f7c9e470` | **Fly-bian 1.0 Simple-AF** (pellcorp `0d21afe`). How-to: [`howto-simpleaf.md`](howto-simpleaf.md). |
| `Releases/Fly-bian-1.0/Fly-Lite-2.1/KIAUH/Fly-bian-1.0_Fly-Lite-2.1_KIAUH-v6.3.2.img.xz` | `0773a9323d02b09c7c3cd8da41c495fdadb59a6c59595749546f5641336f6d39` | **Fly-bian 1.0 KIAUH** (`v6.3.2`). How-to: [`howto-kiauh.md`](howto-kiauh.md). |
| `Releases/Fly-bian-0.6/Fly-Lite-2.1/Simple-AF/Fly-bian-0.6_Fly-Lite-2.1_Simple-AF-0d21afe.img.xz` | `b1be15b826d5da2a57d6651b3cf25cbd961501e26f91a04cf95149623dda52c9` | **Fly-bian 0.6 Simple-AF** (pellcorp `0d21afe`). Fresh stack clone + KIAUH nginx/config seeds + MOTD fix. |
| `Releases/Fly-bian-0.6/Fly-Lite-2.1/KIAUH/Fly-bian-0.6_Fly-Lite-2.1_KIAUH-v6.3.2.img.xz` | `f8fd6b5f04646c9badd5719b02f38069e4d3b3566e80d6fab8ec7416f92fa9a2` | **Fly-bian 0.6 KIAUH** (`v6.3.2`). |
| `Releases/Fly-bian-0.6/Fly-Lite-2.1/Base/Fly-bian-0.6_Fly-Lite-2.1_Base.img.xz` | `ac2eb65b71a6203523e483c08348cc3c21829e4fe04d8aaf9090991c7e44dafb` | **Fly-bian 0.6 Base.** |
| `Releases/Fly-bian-0.5/…/Simple-AF/Fly-bian-0.5_Fly-Lite-2.1_Simple-AF.img.xz` | (see Releases) | **Fly-bian 0.5 Simple-AF** — last bake without stack-rev in the filename. |
| `Releases/Fly-bian-0.4/Fly-Lite-2.1/Simple-AF/Fly-bian-0.4_Fly-Lite-2.1_Simple-AF.img.xz` | `4b0b2eedda3747aa05dabf0e0d9e5819e5d7fbda66895eff34e6f2f0fd98c8d0` | **Fly-bian 0.4 Simple-AF** (2026-09-14). |
| `Releases/Fly-bian-0.4/Fly-Lite-2.1/KIAUH/Fly-bian-0.4_Fly-Lite-2.1_KIAUH.img.xz` | `2495782c5a1df2fc3623b68186de05ea89f03872090c97e2ee3d0d286ae3244c` | **Fly-bian 0.4 KIAUH.** |
| `Releases/Fly-bian-0.4/Fly-Lite-2.1/Base/Fly-bian-0.4_Fly-Lite-2.1_Base.img.xz` | `9bb5142ba04bf376e2348481f0e8bd43bd8671fba029db856b9e04963014e806` | **Fly-bian 0.4 Base.** |
| `Releases/Fly-bian-0.2/Fly-Lite-2.1/Simple-AF/Fly-bian-0.2_Fly-Lite-2.1_Simple-AF.img.xz` | `6168acb032b635045085f555529dd0ea7433f6687b90dfe2b0846b847dc68acd` | Fly-bian 0.2 Simple-AF (older). |
| `Releases/Fly-bian-0.2/Fly-Lite-2.1/KIAUH/Fly-bian-0.2_Fly-Lite-2.1_KIAUH.img.xz` | `72d90c707aec424578a74d8b0a4f6d33bfc7f72ba5b64fc0ff6701a3dd18f094` | Fly-bian 0.2 KIAUH. |
| `Releases/Fly-bian-0.2/Fly-Lite-2.1/Base/Fly-bian-0.2_Fly-Lite-2.1_Base.img.xz` | `8eac3b667933749d8485c45493cc7e91edf782f1457783ff404c34c8e29b7168` | Fly-bian 0.2 Base. |

Full-card dumps below are the earlier lab snapshots.

Full-card images (≥32 GB MicroSD). Flash the whole `.img` (after gunzip). Do not copy files onto a formatted card.

**On the bench Windows PC (not in this git repo):**

```
C:\Users\udrdr\fly-lite-armbian-image
```

`*.img` / `*.img.gz` / `*.img.xz` are gitignored.

| File | SHA256 | What it is |
| --- | --- | --- |
| `Releases/lab-snapshots/Fly Lite 2.1/fly-lite-v2.1-armbian-pre-led.img.gz` | `6845e087e9dc59c910becac5ddc3d59cc006f4633967ae52d2fd72d0117f0758` | Armbian + Fly DTB + UART1/SPI/I2C2/USB hosts + Wi-Fi + KIAUH + `maxcpus=1`. GPIO LED overlay still broken. No TFT. |
| `Releases/lab-snapshots/Fly Lite 2.1/fly-lite-v2.1-armbian-led-tft.img.gz` | `375cc629f3acb8716f4b8263c5fcd6ee10aa86266e6e9c186304ff2222b9bafb` | Same base plus LED fix and TFT software bind. **Live `dd` of a running rootfs** — first boot may need `e2fsck -y /dev/mmcblk0p1` from initramfs, then `exit`. Also on FlyOS USB `/mnt/imgbackup/`. |
| `Releases/lab-snapshots/Fly Lite 2.1/fly-lite-v2.1-armbian-cpu-affinity.img.gz` | `adaae2ccc1e81bb72b66937d45a09c768e76265fb511afbf7d04b0b7437b378d` | **Lab dump, verified.** led-tft plus isolcpus layout and Klipper CPU-affinity drop-ins/generator. |

**Do not live-`dd` `/dev/mmcblk0` over Wi-Fi.** Dump from a USB reader after a serial halt.

Live board notes: [`fly-lite-armbian-notes.md`](fly-lite-armbian-notes.md). Early U-Boot recovery: [`lite21-bringup.md`](lite21-bringup.md).
