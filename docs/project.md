# Fly Debian — image contract

Debian-based images you can flash to a MicroSD card (and later to eMMC on boards that have it) for Mellow Fly hosts. Not FlyOS-FAST.

How to **build** the Lite 2.1 named image: [`build-named-image.md`](build-named-image.md). How images are **named**: [`image-naming.md`](image-naming.md). How to **use** it: [`../README.md`](../README.md).

## Order of work

1. **Named Fly Lite 2.1 image** — small `.img.xz`, FAT `FLY-SETUP`, rootfs grows on first boot, first-run wizard. Lab dump `cpu-affinity` is the hardware reference, not the ship format.
2. **Keep dumps** on the bench PC (`C:\Users\udrdr\fly-lite-armbian-image`). See [`images.md`](images.md).
3. **Fly Pi V3 next** — H618, Ethernet, optional FLY M2WE eMMC. New board file.
4. **Other Fly hosts** — same first-boot idea, different SoCs.

## First-boot contract (every named image)

| Path | What the new user does |
| --- | --- |
| **FAT `FLY-SETUP`** | Edit `fly-start.txt`; read `README.txt`. Windows, macOS, Linux. After SSH: `fly-help` / `fly-start`. |
| **Serial** | Type-C, 115200 8N1. Finish the Armbian wizard. |
| **HDMI + USB keyboard** | FPC-HDMI, USB-A keyboard. Leave TFT unplugged for first boot. |

Do not bake a daily user into the image. The wizard must run.

## Storage

| Board | Flash target |
| --- | --- |
| Fly Lite 2.1 | **MicroSD only.** No eMMC. Keep a FlyOS recovery card. |
| Fly Pi V3 | MicroSD, or official **FLY M2WE eMMC** (private connector). |

## What we are not shipping in the image

- The `.img` in git
- FlyOS-FAST (OTA, read-only root, root-only login)
- One image for every Fly SoC
- A Klipper tree (KIAUH / Simple-AF later; CPU affinity drop-ins **are** in the image)
