# Lite 2.1 Armbian image dumps

Full-card images (≥32 GB MicroSD). Flash the whole `.img` (after gunzip). Do not copy files onto a formatted card.

**On the bench Windows PC (not in this git repo):**

```
C:\Users\udrdr\fly-lite-armbian-image
```

This cloud workspace cannot read that path. `*.img` / `*.img.gz` are gitignored.

| File | SHA256 | What it is |
| --- | --- | --- |
| `fly-lite-v2.1-armbian-pre-led.img.gz` | `6845e087e9dc59c910becac5ddc3d59cc006f4633967ae52d2fd72d0117f0758` | Armbian + Fly DTB + UART1/SPI/I2C2/USB hosts + Wi-Fi + KIAUH + `maxcpus=1`. GPIO LED overlay still broken. No TFT. |
| `fly-lite-v2.1-armbian-led-tft.img.gz` | `375cc629f3acb8716f4b8263c5fcd6ee10aa86266e6e9c186304ff2222b9bafb` | Same base plus LED fix and TFT software bind. **Live `dd` of a running rootfs** — first boot may need `e2fsck -y /dev/mmcblk0p1` from initramfs, then `exit`. Also on FlyOS USB `/mnt/imgbackup/`. |
| `fly-lite-v2.1-armbian-cpu-affinity.img.gz` | `adaae2ccc1e81bb72b66937d45a09c768e76265fb511afbf7d04b0b7437b378d` | **Current.** led-tft plus isolcpus layout and Klipper CPU-affinity drop-ins/generator. 737367001 bytes gzip; source 31266439168 bytes. Imaged from a USB3 SD reader after `shutdown -h now` (last 2 MiB of reader EOF padded with zeros). |

Current dump is **cpu-affinity**. Put that card back in the Lite to boot. Affinity files: [`klipper/cpu-affinity/README.md`](../klipper/cpu-affinity/README.md).

**Do not live-`dd` `/dev/mmcblk0` over Wi-Fi.** Sequential mmc0 read plus 8189fs SDIO wedges the radio (silent lockup). Dump from a USB reader after a serial halt.

Live board notes: [`fly-lite-armbian-notes.md`](fly-lite-armbian-notes.md). Early U-Boot recovery (stock Orange Pi Lite image): [`lite21-bringup.md`](lite21-bringup.md).
