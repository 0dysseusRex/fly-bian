# Test debs

**STOP. Do not download or install anything in this folder unless you were told to, and you know exactly what you are doing.**

These packages replace the **running Linux kernel** on a Fly Lite 2.1. A mistake can leave the board unable to boot. This is **not** `flybian-update`. This is **not** for Fly Pi V3. This is **not** a FlyOS file.

If you just want a working 1.06 system, flash the 1.06 Base image from [Releases](https://github.com/0dysseusRex/fly-bian/releases) instead.

---

## What this is

A **lab test** of installing the Fly-bian **1.06** kernel onto a card that was flashed as **Fly-bian 1.0 Lite Base**.

| File | Role |
| --- | --- |
| `linux-dtb-current-sunxi_26.11.0-trunk+flybian1.06_armhf.deb` | Device trees for 6.18.57 |
| `linux-image-current-sunxi_26.11.0-trunk+flybian1.06_armhf.deb` | Kernel + modules (includes the SDIO/SD one-xfer fix) |

Debian version is `26.11.0-trunk+flybian1.06` so `dpkg` treats it as newer than the 1.0 `26.11.0-trunk` packages. U-Boot is **not** in this folder. Headers are **not** in this folder.

After install, `/etc/fly-debian/flybian-image-baked` stays `1.0`. Only `uname -r` should change to `6.18.57-current-sunxi`.

## Who may use this

- Fly **Lite 2.1**
- Image flavor **Base**
- Baked Fly-bian **1.0** (`cat /etc/fly-debian/flybian-version` → `1.0`)
- A spare test card, not a printer you cannot recover

Do **not** use on Simple-AF or KIAUH until that combination is tested. Do **not** use on Pi V3 (`arm64`).

## Install (testbench)

Copy the two `.deb` files onto the board. Fly Lite / Mini already has a **2 GiB** swapfile from first boot (`swapon --show`). RAM is 512 MB; do **not** add another 512 MiB swap for this test.

```bash
swapon --show
# expect ~2 GiB already

sudo apt-mark unhold linux-image-current-sunxi linux-dtb-current-sunxi
cd ~/test-debs
sudo dpkg -i linux-dtb-current-sunxi_26.11.0-trunk+flybian1.06_armhf.deb
sudo dpkg -i linux-image-current-sunxi_26.11.0-trunk+flybian1.06_armhf.deb
sudo apt-mark hold linux-image-current-sunxi linux-dtb-current-sunxi
sudo reboot
```

If serial stops on a line like `[ OK ]`, **power-cycle**. Lite often does not reset until you pull power.

After boot:

```bash
uname -r
# expect: 6.18.57-current-sunxi

cat /etc/fly-debian/flybian-image-baked
# expect: 1.0
```

Leave the kernel packages **held**. If you `apt-mark unhold` them, Armbian’s repo can overwrite this kernel with one that does **not** have the SDIO fix.

## If it does not boot

Reflash **Fly-bian 1.0 Base** or **Fly-bian 1.06 Base** from a PC. There is no in-place rollback package in this folder.

## Do not

- Run these commands because they were in a chat and you did not read this page
- Install these on Fly Pi V3
- `apt-mark unhold` after the test
- `apt dist-upgrade` expecting this kernel to come from Debian/Armbian
- Install `linux-u-boot-*` or `linux-headers-*` from a random Armbian bake next to these files
