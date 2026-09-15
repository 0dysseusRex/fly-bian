# Lite 2.1 Armbian image dumps

**Named images** (Armbian `.img.xz`, not a 32 GB `dd`). Naming: [`image-naming.md`](image-naming.md). Build: [`build-named-image.md`](build-named-image.md).

Product releases are versioned as **Fly-bian** (repo `FLYBIAN_VERSION`, currently **0.4**):

```
C:\Users\udrdr\fly-lite-armbian-image\Releases\
  RELEASES.txt
  Fly-bian-0.4\
    Fly-Lite-2.1\
      UPDATE-NOTES.txt
      Base\          Fly-bian-0.4_Fly-Lite-2.1_Base.img.xz
      Simple-AF\     Fly-bian-0.4_Fly-Lite-2.1_Simple-AF.img.xz
      KIAUH\         Fly-bian-0.4_Fly-Lite-2.1_KIAUH.img.xz
  lab-snapshots\     old full-card dd dumps
```

Stage with: `scripts/stage-flybian-release.sh all`

| File | SHA256 | What it is |
| --- | --- | --- |
| `Releases/Fly-bian-0.4/Fly-Lite-2.1/Simple-AF/Fly-bian-0.4_Fly-Lite-2.1_Simple-AF.img.xz` | `4b0b2eedda3747aa05dabf0e0d9e5819e5d7fbda66895eff34e6f2f0fd98c8d0` | **Fly-bian 0.4 Simple-AF** (2026-09-14). `fly-boot-display` enable/disable, split Grumpy vs Plymouth flags, kernel 6.18.52. |
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
