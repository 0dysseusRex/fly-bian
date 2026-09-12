# Lite 2.1 Armbian image dumps

**Named images** (Armbian `.img.xz`, not a 32 GB `dd`). See [`build-named-image.md`](build-named-image.md).

Bench tree is one folder per Armbian/kernel version. Simple-AF and KIAUH for the same version live together:

```
C:\Users\udrdr\fly-lite-armbian-image\Releases\
  RELEASES.txt
  <version>\Fly Lite 2.1\         Lite images + UPDATE-NOTES.txt
  <version>\Fly Pi V3\            empty until a V3 image exists
```

| File | SHA256 | What it is |
| --- | --- | --- |
| `Releases/26.11.0-trunk_trixie_6.18.51/Fly Lite 2.1/Armbian-unofficial_26.11.0-trunk_Fly-lite-21-simpleaf_trixie_current_6.18.51_minimal.img.xz` | `407b89ff858754a9bd79d4d551f19bf9493e5b829ff231ca782bc472740ef083` | **Simple-AF named image.** Trixie minimal, kernel 6.18.51, Fly-bian splash, pellcorp stack under `/opt/fly-simple-af`, Debian numpy/matplotlib/scipy. FAT `FLY-SETUP`. Built 2026-09-12 (~21 min Armbian runtime). |
| `Releases/26.11.0-trunk_trixie_6.18.51/Fly Lite 2.1/Armbian-unofficial_26.11.0-trunk_Fly-lite-21-kiauh_trixie_current_6.18.51_minimal.img.xz` | `c634fa467453cafea0437f7cc0acb529748066d119d52046548c71982543a0c0` | **KIAUH named image.** Same hardware/splash; KIAUH + stock Klipper/Moonraker/web UIs under `/opt/fly-kiauh`. FAT `FLY-SETUP`. Built 2026-09-12 (~15 min Armbian runtime). |
| `Releases/26.11.0-trunk_trixie_6.18.50/Fly Lite 2.1/Armbian-unofficial_26.11.0-trunk_Fly-lite-21_trixie_current_6.18.50_minimal.img.xz` | `f2f0fdab516d19b7a9d829e69c9067a16eda1d0d164d62c763a839fb0e7c5b4b` | Earlier **base** named image (no Simple-AF/KIAUH bake). Kernel 6.18.50. |

Full-card dumps below are the earlier lab snapshots.

Full-card images (≥32 GB MicroSD). Flash the whole `.img` (after gunzip). Do not copy files onto a formatted card.

**On the bench Windows PC (not in this git repo):**

```
C:\Users\udrdr\fly-lite-armbian-image
```

This cloud workspace cannot read that path. `*.img` / `*.img.gz` are gitignored.

| File | SHA256 | What it is |
| --- | --- | --- |
| `Releases/lab-snapshots/Fly Lite 2.1/fly-lite-v2.1-armbian-pre-led.img.gz` | `6845e087e9dc59c910becac5ddc3d59cc006f4633967ae52d2fd72d0117f0758` | Armbian + Fly DTB + UART1/SPI/I2C2/USB hosts + Wi-Fi + KIAUH + `maxcpus=1`. GPIO LED overlay still broken. No TFT. |
| `Releases/lab-snapshots/Fly Lite 2.1/fly-lite-v2.1-armbian-led-tft.img.gz` | `375cc629f3acb8716f4b8263c5fcd6ee10aa86266e6e9c186304ff2222b9bafb` | Same base plus LED fix and TFT software bind. **Live `dd` of a running rootfs** — first boot may need `e2fsck -y /dev/mmcblk0p1` from initramfs, then `exit`. Also on FlyOS USB `/mnt/imgbackup/`. |
| `Releases/lab-snapshots/Fly Lite 2.1/fly-lite-v2.1-armbian-cpu-affinity.img.gz` | `adaae2ccc1e81bb72b66937d45a09c768e76265fb511afbf7d04b0b7437b378d` | **Current, verified.** led-tft plus isolcpus layout and Klipper CPU-affinity drop-ins/generator. 737367001 bytes gzip; source 31266439168 bytes. Imaged from a USB3 SD reader after `shutdown -h now` (last 2 MiB of reader EOF padded with zeros). Written back to the Lite: boots, SSH reachable. |

Current dump is **cpu-affinity**. The card is back in the Lite; SSH works. Affinity files: [`klipper/cpu-affinity/README.md`](../klipper/cpu-affinity/README.md).

**Do not live-`dd` `/dev/mmcblk0` over Wi-Fi.** Sequential mmc0 read plus 8189fs SDIO wedges the radio (silent lockup). Dump from a USB reader after a serial halt.

Live board notes: [`fly-lite-armbian-notes.md`](fly-lite-armbian-notes.md). Early U-Boot recovery (stock Orange Pi Lite image): [`lite21-bringup.md`](lite21-bringup.md).
