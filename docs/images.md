# Lite 2.1 Armbian image dumps

**Named images** (Armbian `.img.xz`, not a 32 GB `dd`). See [`build-named-image.md`](build-named-image.md).

Bench tree is one folder per Armbian/kernel version. Flavors are separate
subfolders under `Fly Lite 2.1`:

```
C:\Users\udrdr\fly-lite-armbian-image\Releases\
  RELEASES.txt
  <version>\Fly Lite 2.1\
    UPDATE-NOTES.txt
    base\          installer-agnostic
    simpleaf\      Simple-AF pre-bake
    kiauh\         KIAUH pre-bake
  <version>\Fly Pi V3\            empty until a V3 image exists
```

| File | SHA256 | What it is |
| --- | --- | --- |
| `Releases/26.11.0-trunk_trixie_6.18.51/Fly Lite 2.1/simpleaf/Armbian-unofficial_26.11.0-trunk_Fly-lite-21-simpleaf_trixie_current_6.18.51_minimal.img.xz` | `bf2e571c74b735dc31a401c8941728ba52856a4fddf9d8a6b7af98e8c23cbe19` | **Simple-AF named image (rebuild 2026-09-13).** Trixie minimal, kernel 6.18.51. GrumpyScreen preferred/enabled on first-user bind; `BOOT_LOGO=desktop` splash; getty+fly-ip-announce (no greetd); host-MCU skip patch; nginx/polkitd/wlan1/swap. FAT `FLY-SETUP`. |
| `Releases/26.11.0-trunk_trixie_6.18.51/Fly Lite 2.1/kiauh/Armbian-unofficial_26.11.0-trunk_Fly-lite-21-kiauh_trixie_current_6.18.51_minimal.img.xz` | `924228f69da11ae22b31c298744832fc0f0f156a84fe645d875ca1574e67981a` | **KIAUH named image (rebuild 2026-09-13).** Same hardware/splash; KIAUH stack under `/opt/fly-kiauh`. Shared boot fixes (polkitd, wlan1, getty, swap, SSH keys). |
| `Releases/26.11.0-trunk_trixie_6.18.51/Fly Lite 2.1/base/Armbian-unofficial_26.11.0-trunk_Fly-lite-21_trixie_current_6.18.51_minimal.img.xz` | `b7c549e88bbbe2a11c7934699e0299aeeaef30cdd27baf68ba5a1e3f552a0272` | **Base named image (rebuild 2026-09-13).** No Simple-AF/KIAUH bake. Kernel 6.18.51. Same hardware/boot fixes. |
| `Releases/26.11.0-trunk_trixie_6.18.50/Fly Lite 2.1/base/Armbian-unofficial_26.11.0-trunk_Fly-lite-21_trixie_current_6.18.50_minimal.img.xz` | `f2f0fdab516d19b7a9d829e69c9067a16eda1d0d164d62c763a839fb0e7c5b4b` | Earlier **base** named image. Kernel 6.18.50. |

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
