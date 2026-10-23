# Community alternate firmware for Mellow Fly products

**Survey date:** 2026-10-04  
**Scope:** Unofficial / community OS images, Armbian board support, and related host firmware for Mellow Fly SBCs and companions. Not FlyOS. Not an endorsement.

There are only a handful of active alternate-host projects. Most GitHub hits under “Mellow” / “Fly Gemini” are **hardware info** repos under [Mellow-3D](https://github.com/Mellow-3D), MCU firmware, or unrelated names. The useful host-OS work clusters around **Fly Gemini / early Fly Pi (H5)** and, newly, **upstream Armbian Fly-C5 (H618)**.

---

## Active / useful (host OS)

| Project | Board / SoC | What it is | Notes |
| --- | --- | --- | --- |
| [reemo3dp/mellowfly-geminipi-armbian](https://github.com/reemo3dp/mellowfly-geminipi-armbian) | Fly Gemini V3 / Fly Pi (Allwinner H5) | Patches + images so stock Armbian builds boot those boards | Best community Armbian path for Gemini/Pi H5. Mentions Wi-Fi (`rtw88_8821cs` blacklist patterns), eMMC, based on older Mellow `flypi` work. Last push ~2026-05. |
| [reemo3dp/mellowfly-geminipi-mainsailos](https://github.com/reemo3dp/mellowfly-geminipi-mainsailos) | Same H5 boards | Config to build MainsailOS on top of the Reemo Armbian base | Companion to the repo above; quieter since 2024. |
| [DerFuchs/Armbian-with-Klipper-on-Fly-Gemini-3](https://github.com/DerFuchs/Armbian-with-Klipper-on-Fly-Gemini-3) | Gemini 3 / Fly Pi | Guide: “mostly clean” Klipper host on Gemini | Points at Mellow Armbian / Reemo images rather than a full board tree. |
| [kakwa/fly-gemini](https://github.com/kakwa/fly-gemini) | Fly Gemini | Notes and flash scripts | Small; useful for flashing tips, not a maintained image line. |
| [armbian/build](https://github.com/armbian/build) `mellowflyc5` | **Mellow Fly-C5** (H618) | **Upstream Armbian board** (`config/boards/mellowflyc5.csc`) | Closest official mainline peer to Fly Pi V3 (same SoC family). Maintainer `deece` (Alastair D'Silva). Includes eMMC SPL slot, RTL8821CS packages, serial-getty on `ttyS1`, mainline-style DTS `sun50i-h618-mellow-fly-c5`. Merged mid-2026; U-Boot ported to v2026.07. **Primary reference for Pi V3 bring-up.** |
| [FloralDroid/armbian](https://github.com/FloralDroid/armbian) | Fly-C5 lineage | Community Armbian tree with Fly-C5 DTS work | Overlaps / feeds the upstream `mellowflyc5` support; check before reinventing H618 Wi-Fi pwrseq / regulators / mmc1–2. |
| [0dysseusRex/fly-bian](https://github.com/0dysseusRex/fly-bian) | Fly Lite 2.1 (H3); Fly Pi V3 (H618) | This project — unofficial Armbian (Debian) for Mellow Fly SBCs | Not FlyOS. Lite 2.1 (1.06) and Pi V3 (1.05) supported. |

---

## Historical / low activity (host OS)

| Project | Board / SoC | What it is | Notes |
| --- | --- | --- | --- |
| [Mellow-3D/build](https://github.com/Mellow-3D/build) | Fly Pi (`flypi` / `fly-pi` branches, H5) | Vendor fork of Armbian build framework | Last push ~2022-12. Source of early `flypi` board files that community Gemini work built on. Stale as a daily driver. |
| [s6t/armbian-mellow-fly-pi](https://github.com/s6t/armbian-mellow-fly-pi) | Fly Pi H5 (stale `flypi`) | Fork/mirror of `armbian/build` with old Fly Pi bits | Not ahead of modern Armbian main; do not treat as current Pi V3 support. |

---

## Related (not full SBC host OS)

| Project | Product | What it is |
| --- | --- | --- |
| [TekuSP/OpenHalo](https://github.com/TekuSP/OpenHalo) | Mellow Fly Halo | Open-source firmware for the Halo wireless terminal (nanoFramework / C#), not an SBC Debian image. |
| [Nitrooxyde/Mellow-LLL-Plus-Klipper-Firmware](https://github.com/Nitrooxyde/Mellow-LLL-Plus-Klipper-Firmware) | FLY LLL Buffer Plus | Klipper MCU / in-firmware auto-feed — toolboard class, not host OS. |
| [Mellow-3D/FLY-TFT](https://github.com/Mellow-3D/FLY-TFT) (and similar under org) | FLY TFT panels | Vendor TFT / overlay material — useful for displays, not an alternate host firmware line. |
| [Mellow-3D](https://github.com/Mellow-3D) hardware repos | Gemini V1–V3, C8, Super8, etc. | Schematics / product info. **Not** alternate Debian/Armbian images. |

---

## What is missing (as of survey)

- **No** maintained community Armbian/Debian line specifically named for **Fly Pi V3** or **Fly Lite 2.1** outside Fly-bian.
- **No** upstream Armbian `BOARD` for Fly Lite 2.1 or Fly Pi V3 yet (C5 is the H618 foothold).
- Searches for “Fly Lite” / “flylite” Armbian mostly hit unrelated Debian projects.

---

## Relevance to Fly-bian

1. **Gemini / H5** — Reemo + DerFuchs + kakwa document the community’s expectations for “Armbian instead of FlyOS” on older hosts. Useful if/when Gemini is scheduled; not a shortcut for Lite or Pi V3.  
2. **H618 / Pi V3** — Study [armbian/build `mellowflyc5`](https://github.com/armbian/build/blob/main/config/boards/mellowflyc5.csc) and FloralDroid’s DTS: Wi-Fi power sequencing, mmc1/mmc2, eMMC SPL (`CONFIG_MMC_SUNXI_SLOT_EXTRA=2`), DRAM/PMIC caveats, and console on `ttyS1`. Pi V3 uses its own board file and OEM `fly-h618.dtb` / overlays where they diverge from C5.  
3. **Vendor `Mellow-3D/build`** — Historical only; prefer current Armbian + Fly-bian userpatches.

### Applied in Fly-bian (Pi V3 bring-up)

| Lesson | Where |
| --- | --- |
| `PACKAGE_LIST_BOARD="rfkill mmc-utils"` (C5) | `armbian/userpatches/config/boards/fly-pi-v3.csc` |
| Force `CONFIG_MMC_SUNXI_SLOT_EXTRA=2` in U-Boot config | same `.csc` `post_config_uboot_target__fly_pi_v3_emmc` (+ existing patch) |
| Defer `rtw88_8821cs` / AIC8800 autoload (Reemo) | `customize-image.sh` → `/etc/modprobe.d/fly-pi-v3-wifi-defer.conf` |
| Explicit modprobe + unmask networkd on Wi-Fi apply | `overlay/fly-apply-fly-net.sh` |
| Pi V3 console stays **ttyS0** (Type-C CH340), not C5’s ttyS1 | `customize-image.sh` |
| Bounded flush instead of bare `sync` after FLY-SETUP (WSL/Docker hang) | `extensions/fly-windows-bootfs.sh` |

---

## Related docs

- [Other Mellow SBCs (stubs)](boards/other-mellow/README.md)  
- [Fly Pi V3 board README](boards/fly-pi-v3/README.md)  
- [Board index](boards/README.md)  
- [Main project README](../README.md)  
