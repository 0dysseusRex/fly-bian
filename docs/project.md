# Fly Debian images

Debian-based images you can flash to a MicroSD card (and later to eMMC on boards that have it) for Mellow Fly hosts. Not FlyOS-FAST. Normal apt, a normal user, and as much of each board as the public sunxi/Allwinner support plus Fly’s DTB will allow.

## Order of work

1. **Fly Lite 2.1 now** — boot stock Debian, then enable hardware (console, USB, Wi-Fi, HDMI, TFT last).
2. **Write a Lite 2.1 image** — after the board is proven, bake a named image with our first-boot file and overlays.
3. **Fly Pi V3 next** — different SoC (H618), Ethernet, optional M2WE eMMC. New board file, not a Lite respin.
4. **Other Fly hosts** — blurbs and a likely public base image only, until we pick one up.

## First-boot contract (every image)

Three working ways to finish setup. The custom image will keep all three; stock Armbian already supports them.

| Path | When to use | What you do |
| --- | --- | --- |
| **Pre-boot Wi-Fi file** | Headless, onboard radio or USB Wi-Fi | Edit `first-boot/fly-net.txt`, copy onto the FAT boot partition before first power-on |
| **Serial** | Safest first login | Type-C (Lite 2.1) or UART at **115200 8N1** |
| **HDMI + USB** | Keyboard and a screen | FPC-HDMI or Micro-HDMI plus a USB keyboard. Do not mix TFT and HDMI while testing |

The editable file is `first-boot/fly-net.txt`. `scripts/prepare-sd.sh` writes Armbian’s `armbian_first_run.txt` from it so a stock Orange Pi Lite image connects on first boot. The later custom image will read `fly-net.txt` directly.

## Storage

| Board | Flash target |
| --- | --- |
| Fly Lite 2.1 | **MicroSD only.** No eMMC. Keep a FlyOS recovery card. |
| Fly Pi V3 | MicroSD, or official **FLY M2WE eMMC** (private connector — not a generic M.2). |

## What we are not doing yet

- Baking a downloadable `.img` (comes after Lite 2.1 hardware works).
- Cloning FlyOS-FAST (OTA, read-only root, root-only login).
- One image that boots every Fly board. SoCs differ (H3, H5, H618).
