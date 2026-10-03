# Lite 2.1 Armbian image dumps

**Named images** (Armbian `.img.xz`, not a 32 GB `dd`). Naming: [`image-naming.md`](image-naming.md). Build: [`build-named-image.md`](build-named-image.md).

Product releases are versioned as **Fly-bian** (repo `FLYBIAN_VERSION`). From 0.6 onward, Simple-AF / KIAUH filenames include the stack revision (pellcorp short SHA / KIAUH tag). Naming: [`image-naming.md`](image-naming.md).

```
C:\Users\udrdr\fly-lite-armbian-image\Releases\
  RELEASES.txt
  Fly-bian-1.0\
    Fly-Lite-2.1\
      UPDATE-NOTES.txt
      Base\          Fly-bian-1.0_Fly-Lite-2.1_Base.img.xz
      Simple-AF\     Fly-bian-1.0_Fly-Lite-2.1_Simple-AF-0d21afe.img.xz
      KIAUH\         Fly-bian-1.0_Fly-Lite-2.1_KIAUH-v6.3.2.img.xz
  lab-snapshots\     old full-card dd dumps
```

Stage with: `scripts/stage-flybian-release.sh all`

| File | SHA256 | What it is |
| --- | --- | --- |
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
