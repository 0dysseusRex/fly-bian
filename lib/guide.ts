export type GuideLink = {
  label: string;
  href: string;
  note?: string;
};

export const downloads = {
  debian: [
    {
      label: "Armbian Orange Pi Lite board page",
      href: "https://www.armbian.com/orange-pi-lite/",
      note: "Pick the latest Debian Minimal (CLI) image. Do not take the Ubuntu Xfce desktop build.",
    },
    {
      label: "Debian 13 Trixie Minimal CLI (current redirect)",
      href: "https://dl.armbian.com/orangepilite/Trixie_current_minimal",
      note: "Stable Armbian short URL. Follows whatever trunk they published most recently.",
    },
    {
      label: "SHA-256 for that image",
      href: "https://dl.armbian.com/orangepilite/Trixie_current_minimal.sha",
    },
    {
      label: "Armbian Imager",
      href: "https://www.armbian.com/imager/",
      note: "Select manufacturer Orange Pi, board Orange Pi Lite, then Debian Minimal.",
    },
    {
      label: "Armbian getting started",
      href: "https://docs.armbian.com/User-Guide_Getting-Started/",
    },
  ] satisfies GuideLink[],
  flyos: [
    {
      label: "Official Lite2 / Lite2.1 image page",
      href: "https://mellow.klipper.cn/en/docs/ResDownload/system-img/fly-lite2/",
      note: "Mellow says Lite2 and Lite2.1 use the same H3 image. Download, unzip, then extract — do not boot this if you want Debian.",
    },
    {
      label: "H3 family image notes (MiniPad / Lite)",
      href: "https://mellow.klipper.cn/en/docs/ResDownload/system-img/fly-minipad/",
    },
    {
      label: "FlyOS-FAST documentation",
      href: "https://mellow.klipper.cn/en/docs/DebugDoc/flyos-fast/",
    },
  ] satisfies GuideLink[],
  tools: [
    {
      label: "Raspberry Pi Imager (can flash any .img)",
      href: "https://www.raspberrypi.com/software/",
    },
    {
      label: "Balena Etcher",
      href: "https://etcher.balena.io/",
    },
    {
      label: "Rufus (Windows)",
      href: "https://rufus.ie/en/",
    },
    {
      label: "Mellow flashing tools list",
      href: "https://mellow.klipper.cn/en/docs/ResDownload/auxiliary_software/",
    },
  ] satisfies GuideLink[],
  build: [
    {
      label: "Armbian build framework",
      href: "https://github.com/armbian/build",
    },
    {
      label: "Build preparation docs",
      href: "https://docs.armbian.com/Developer-Guide_Build-Preparation/",
    },
    {
      label: "Orange Pi One images (H3, no onboard Wi-Fi)",
      href: "https://www.armbian.com/orange-pi-one/",
    },
    {
      label: "DietPi downloads (no Orange Pi Lite image)",
      href: "https://dietpi.com/#download",
      note: "DietPi does not ship a Lite image. Start from Armbian if you want DietPi later.",
    },
    {
      label: "DietPi supported hardware list",
      href: "https://dietpi.com/docs/hardware/",
    },
  ] satisfies GuideLink[],
};

export const sources = [
  {
    label: "FLY Lite 2.1 product docs",
    href: "https://mellow.klipper.cn/en/docs/ProductDoc/SBC/fly-lite/lite2.1/",
  },
  {
    label: "FLY-Pi V3 product docs",
    href: "https://mellow.klipper.cn/en/docs/ProductDoc/SBC/fly-pi-v3/",
  },
  {
    label: "Armbian first-run Wi-Fi template",
    href: "https://github.com/armbian/build/blob/master/packages/bsp/armbian_first_run.txt.template",
  },
  {
    label: "Lite 2.1 SSH / Type-C serial",
    href: "https://mellow.klipper.cn/en/docs/ProductDoc/SBC/fly-lite/lite2.1/host/ssh",
  },
  {
    label: "Lite 2.1 KPPM / power-loss pin",
    href: "https://mellow.klipper.cn/en/docs/ProductDoc/SBC/fly-lite/lite2.1/advanced/kppm/",
  },
  {
    label: "Lite 2.1 accelerometer limits",
    href: "https://mellow.klipper.cn/en/docs/ProductDoc/SBC/fly-lite/lite2.1/advanced/adxl/",
  },
  {
    label: "Official Lite2 / Lite2.1 system image (H3 FlyOS)",
    href: "https://mellow.klipper.cn/en/docs/ResDownload/system-img/fly-lite2/",
  },
  {
    label: "Armbian Orange Pi Lite images",
    href: "https://www.armbian.com/orange-pi-lite/",
  },
  {
    label: "Debian 13 Trixie Minimal CLI redirect",
    href: "https://dl.armbian.com/orangepilite/Trixie_current_minimal",
  },
  {
    label: "Armbian Imager",
    href: "https://www.armbian.com/imager/",
  },
  {
    label: "linux-sunxi Orange Pi Lite (closest public H3 DTS)",
    href: "https://linux-sunxi.org/Orange_Pi_Lite",
  },
  {
    label: "Mainline sun8i-h3-orangepi-lite.dts",
    href: "https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/tree/arch/arm/boot/dts/allwinner/sun8i-h3-orangepi-lite.dts",
  },
  {
    label: "Community Armbian for Fly Gemini / Fly-Pi (method reference)",
    href: "https://github.com/reemo3dp/mellowfly-geminipi-armbian",
  },
] as const;

export const project = {
  now: "Fly Lite 2.1 — boot Debian, then enable every connector that works",
  next: "Bake a Lite 2.1 image, then port the same first-boot contract to Fly Pi V3",
  later: "Named images per SoC family. One file for Wi-Fi before first boot; serial and HDMI+USB stay as setup paths.",
} as const;

export const boards = [
  {
    id: "lite21",
    name: "Fly Lite 2.1",
    status: "Now",
    soc: "Allwinner H3, 4× Cortex-A7, 512 MB, armhf",
    storage: "MicroSD only. No eMMC.",
    network: "Onboard 2.4 GHz Wi-Fi (IPEX1). No Ethernet.",
    display: "FPC-HDMI + FPC-TFT (16P). Type-C serial.",
    image: "Armbian Debian 13 Trixie Minimal CLI, board = Orange Pi Lite",
    note: "Current work. Closest public DTB. Keep FlyOS on a second card. Live U-Boot: gpio clear PF6, then load the flat orangepi-lite.dtb — not allwinner/.",
  },
  {
    id: "piv3",
    name: "Fly Pi V3",
    status: "Next",
    soc: "Allwinner H618, 4× Cortex-A53, 1 GB DDR4, aarch64",
    storage: "MicroSD, or official FLY M2WE eMMC (not generic M.2).",
    network: "100 M Ethernet onboard. No onboard Wi-Fi — M2WE or USB radio.",
    display: "Micro-HDMI + FPC-HDMI + FPC-TFT. 12–24 V or Type-C 5 V.",
    image: "Not yet. Will need an H618 board file (Orange Pi Zero 2 / similar), not the Lite image.",
    note: "Different SoC and boot chain. Do not flash the Lite 2.1 card here.",
  },
  {
    id: "piv2",
    name: "Fly Pi V2",
    status: "Later",
    soc: "Allwinner H5, 4× Cortex-A53, 1 GB, aarch64",
    storage: "MicroSD or FLY M2WE eMMC.",
    network: "100 M Ethernet. No onboard Wi-Fi — M2WE or USB.",
    display: "FPC-HDMI, FPC-TFT, Micro-HDMI. TFT shares SPI with the ADXL header.",
    image: "Likely an Orange Pi PC2 / Prime class Armbian image plus Fly DTB.",
    note: "Pi-shaped host. Community Gemini/Pi Armbian trees are a method reference.",
  },
  {
    id: "minipad",
    name: "Fly MiniPad",
    status: "Later",
    soc: "Allwinner H3 family (same official FAST image as Lite2).",
    storage: "MicroSD.",
    network: "Onboard Wi-Fi in the H3 FlyOS family.",
    display: "Integrated pad / TFT first, not a generic HDMI host.",
    image: "Same H3 loot path as Lite 2.1. Confirm DTB before sharing an image.",
    note: "Mellow ships one H3 FAST image for MiniPad and Lite2/2.1.",
  },
  {
    id: "gemini",
    name: "Fly Gemini V3",
    status: "Later",
    soc: "H5-class host plus an onboard STM32 printer MCU",
    storage: "MicroSD or M2WE eMMC.",
    network: "Ethernet / M2WE. Not a Lite.",
    display: "Host + MCU on one PCB. Different pinmux and DRAM.",
    image: "Do not use a Gemini community image on the Lite. Reverse is also wrong.",
    note: "Useful later as a combined host+MCU target, not as a Lite shortcut.",
  },
] as const;

export const setupPaths = [
  {
    id: "wifi-file",
    title: "Pre-boot Wi-Fi file",
    summary:
      "Edit first-boot/fly-net.txt, run scripts/prepare-sd.sh on the mounted FAT boot partition. Stock Armbian reads armbian_first_run.txt on first boot.",
  },
  {
    id: "serial",
    title: "Serial console",
    summary:
      "Type-C at 115200 8N1 (COM4 on Windows if the same cable as FlyOS). Stock Armbian autoboot does not see the SD card (PF6 CD). Paste the U-Boot block in docs/lite21-bringup.md, then finish the first-login wizard on ttyS0.",
  },
  {
    id: "hdmi-usb",
    title: "HDMI + USB keyboard",
    summary:
      "FPC-HDMI and a USB-A keyboard. Leave the TFT unplugged. If /sys/class/drm never shows a connected display, loot the FlyOS DTB next.",
  },
] as const;

export const specs = [
  { label: "SoC", value: "Allwinner H3, 4× Cortex-A7, 32-bit" },
  { label: "GPU", value: "Mali-400 MP2" },
  { label: "RAM", value: "512 MB DDR3" },
  { label: "Storage", value: "MicroSD only, 16–128 GB, C10+" },
  { label: "Network", value: "Onboard 2.4 GHz Wi-Fi, IPEX1 antenna" },
  { label: "USB", value: "USB-A 2.0 × 2, Type-C power + serial" },
  { label: "Display", value: "FPC-HDMI + FPC-TFT" },
  { label: "Power", value: "Independent 5 V. Do not feed from a printer MCU." },
] as const;

export const phases = [
  {
    id: "boot",
    title: "Boot Debian",
    likelihood: "High",
    summary:
      "SPL already loads U-Boot from the SD card. U-Boot then honors Orange Pi Lite’s PF6 card-detect, which is high on this PCB, so autoboot says MMC: no card present. gpio clear PF6 then ext4load the real kernel, uInitrd, and flat sun8i-h3-orangepi-lite.dtb. Do not use the allwinner/ path or /boot/zImage (symlink).",
  },
  {
    id: "console",
    title: "Get a console",
    likelihood: "High",
    summary:
      "Mellow’s Type-C is a real UART: U-Boot already prints on COM4 at 115200. Stay on that port for the first-login wizard after bootz. HDMI+USB is a fallback, not required to prove Debian.",
  },
  {
    id: "usb",
    title: "USB-A hosts",
    likelihood: "High",
    summary:
      "H3 EHCI/OHCI ports 1 and 2 are enabled on the Orange Pi Lite DTB. A keyboard, Ethernet dongle, or printer MCU should enumerate without Fly-specific work.",
  },
  {
    id: "wifi",
    title: "Onboard 2.4 GHz Wi-Fi",
    likelihood: "Medium-high",
    summary:
      "H3 lite boards almost always put an RTL8189-class chip on MMC1/SDIO. If Mellow did the same, the Orange Pi Lite image may bring wlan0 up. If not, extract the FlyOS DTB and firmware.",
  },
  {
    id: "hdmi",
    title: "FPC-HDMI",
    likelihood: "Medium",
    summary:
      "HDMI lives in the H3, not in a Fly ASIC. If the FPC is just a compact connector on the same TMDS pins, enabling &hdmi is enough. The “HDMI + USB one-cable” accessory is a separate mux problem.",
  },
  {
    id: "tft",
    title: "FPC-TFT",
    likelihood: "Low until Fly DTB",
    summary:
      "SPI panel plus reset/DC/backlight GPIOs. Pinmux is board-specific. Do this after Wi-Fi and USB work, using overlays extracted from the official H3 FlyOS image.",
  },
];

export const features = [
  {
    name: "MicroSD boot",
    status: "Manual U-Boot",
    how: "Card is fine. U-Boot CD on PF6 is wrong for this PCB. gpio clear PF6, mmc dev 0, load real filenames. Autoboot needs a U-Boot DTB patch (broken-cd), not only a Linux overlay.",
  },
  {
    name: "CPU, RAM, timers, thermal",
    status: "Expected",
    how: "sun8i-h3 is mainline. Expect DVFS and throttling from the Orange Pi Lite thermal tables.",
  },
  {
    name: "USB-A host × 2",
    status: "Expected",
    how: "ehci1/ehci2 + ohci1/ohci2 are on in sun8i-h3-orangepi-lite.dts.",
  },
  {
    name: "Type-C 5 V power",
    status: "Hardware",
    how: "Independent of the OS. Use a data-capable cable only when you also want serial.",
  },
  {
    name: "Type-C serial console",
    status: "Hardware",
    how: "U-Boot and the kernel both use ttyS0 on the Type-C UART. Open COM4 at 115200. Do not wait on g_serial.",
  },
  {
    name: "Onboard 2.4 GHz Wi-Fi",
    status: "First experiment",
    how: "Look for MMC1 and an RTL8189/8723/8821 SDIO function. Copy firmware from FlyOS if the chip probes but firmware is missing.",
  },
  {
    name: "FPC-HDMI",
    status: "Plausible",
    how: "Enable the H3 HDMI block. Test with a known-good HDMI panel on Mellow’s FPC cable, one display at a time.",
  },
  {
    name: "FPC-TFT / touch",
    status: "Extract from FlyOS",
    how: "Need the official DTB fragments for SPI, reset, DC, backlight, and the touch controller (ADS7846 or GT911 on other Fly screens).",
  },
  {
    name: "LED activity",
    status: "May differ",
    how: "Orange Pi Lite LED GPIOs are probably wrong. Harmless. Fix after you have a console.",
  },
  {
    name: "KPPM power-loss module",
    status: "FlyOS userspace",
    how: "Hardware can sit unused. Porting Mellow’s shutdown/resume scripts is optional and last.",
  },
];

export const steps = [
  {
    title: "Keep a FlyOS recovery card",
    body: "The Lite has no eMMC. Two MicroSD cards is a full rollback. Do not overwrite the only card that already boots FlyOS.",
  },
  {
    title: "Flash Armbian Debian 13 Trixie CLI for Orange Pi Lite",
    body: "Use the current Minimal (CLI) image from the Orange Pi Lite board page. Not the Ubuntu Xfce desktop, not Raspberry Pi OS. H3 is 32-bit ARM (armhf).",
  },
  {
    title: "Optional: write fly-net.txt onto the boot partition",
    body: "After flashing, remount the FAT boot volume and run scripts/prepare-sd.sh so Armbian joins Wi-Fi on first boot. Still keep serial or HDMI+USB as a fallback — the radio may not probe yet.",
  },
  {
    title: "First boot: serial past U-Boot, then HDMI+USB or Wi-Fi",
    body: "Independent 5 V. Fit the IPEX antenna. Unplug the printer MCU and TFT. This Trixie image is a single ext4 partition (no FAT), so fly-net.txt cannot be applied from Windows. At the U-Boot => prompt paste the block in docs/lite21-bringup.md. DTB path is /boot/dtb-<ver>-current-sunxi/sun8i-h3-orangepi-lite.dtb — not allwinner/. Finish the Armbian user wizard on ttyS0.",
  },
  {
    title: "Create a normal sudo user and add swap",
    body: "512 MB needs zram plus a 1 GB swap file before you compile anything. Armbian’s first-run wizard will ask for a user. Keep it.",
  },
  {
    title: "Prove USB host",
    body: "Plug a USB Ethernet dongle or a flash drive. lsusb should list it. This is your network lifeline if onboard Wi-Fi is dark.",
  },
  {
    title: "Identify the Wi-Fi chip",
    body: "Run the first-boot script in this repo. If MMC1 shows an SDIO vendor, you are one firmware file away from wlan0. If MMC1 is empty, dump the FlyOS DTB next.",
  },
  {
    title: "Extract FlyOS when a peripheral is missing",
    body: "scripts/extract-flyos.sh against the official H3 image copies DTB, overlays, and /lib/firmware. That is how community Fly Gemini Armbian images were made. Same method, this board.",
  },
  {
    title: "Enable displays last",
    body: "HDMI first (SoC block). TFT only after you have the Fly pinmux. Never connect TFT and HDMI at the same time while testing.",
  },
];

export const extractFlow = [
  {
    title: "Get the official H3 FlyOS image",
    body: "Use the Lite2 / Lite2.1 image page (same image for both). Unzip it. Do not flash the archive. You want the DTB and firmware, not a FAST boot.",
  },
  {
    title: "Run the extractor on a Linux PC",
    body: "scripts/extract-flyos.sh FlyOS_h3_*.img writes dtb/, overlays/, firmware/, and a report into out/flyos-extract/.",
  },
  {
    title: "Compare DTB against Orange Pi Lite",
    body: "dtc -I dtb -O dts on both files. Diff mmc1, usb, hdmi, spi, and uart nodes. Those diffs are the Lite 2.1 board support.",
  },
  {
    title: "Copy firmware, then overlays",
    body: "If the chip already probes, firmware alone may be enough. If the bus is off, compile the Fly fragments with armbian-add-overlay or rebuild the DTB.",
  },
];

/** Paste at the U-Boot `=>` prompt on the Lite 2.1 (Armbian 6.18.49-current-sunxi). */
export const ubootManualBoot = `gpio clear PF6
mmc dev 0
setenv kernel_addr_r 0x42000000
setenv fdt_addr_r 0x43000000
setenv ramdisk_addr_r 0x43300000
ext4load mmc 0:1 \${kernel_addr_r} /boot/vmlinuz-6.18.49-current-sunxi
ext4load mmc 0:1 \${ramdisk_addr_r} /boot/uInitrd-6.18.49-current-sunxi
ext4load mmc 0:1 \${fdt_addr_r} /boot/dtb-6.18.49-current-sunxi/sun8i-h3-orangepi-lite.dtb
setenv bootargs console=ttyS0,115200 earlyprintk root=/dev/mmcblk0p1 rootwait rootfstype=ext4
bootz \${kernel_addr_r} \${ramdisk_addr_r} \${fdt_addr_r}`;

export const faqs = [
  {
    q: "U-Boot says Failed to load …/allwinner/sun8i-h3-orangepi-lite.dtb",
    a: "This Armbian layout keeps DTBs flat in /boot/dtb-<ver>-current-sunxi/. There is no allwinner/ folder. Load sun8i-h3-orangepi-lite.dtb from that directory. Do not bootz until that ext4load prints ~34541 bytes.",
  },
  {
    q: "Why MMC: no card present after SPL already booted from the card?",
    a: "Orange Pi Lite’s DTB uses PF6 as SD card-detect, active-low. On the Fly Lite 2.1 PF6 is high, so U-Boot skips mmc0. gpio clear PF6 then mmc dev 0. Autoboot needs the same change in U-Boot’s DTB; a Linux overlay is not enough.",
  },
  {
    q: "When do we write a custom image?",
    a: "After Debian boots on the Lite 2.1 and USB, Wi-Fi, serial, and HDMI are characterized. Baking an .img before that freezes the wrong DTB. The first-boot Wi-Fi file is already the contract that image will keep.",
  },
  {
    q: "Can I flash this to eMMC?",
    a: "Not on the Lite 2.1 — it has no eMMC. Fly Pi V3 and Pi V2 can use the official FLY M2WE module (private connector, not a generic M.2). We will add an eMMC install path when we get to those boards.",
  },
  {
    q: "Why Orange Pi Lite and not Orange Pi One or PC?",
    a: "Lite matches the product: H3, 512 MB, no Ethernet jack, SDIO Wi-Fi, two USB hosts. One has no Wi-Fi. PC has Ethernet and more RAM. Start from Lite; you can still turn unused nodes off.",
  },
  {
    q: "Will Raspberry Pi OS boot?",
    a: "No. Different boot ROM, different DRAM init, different kernel. You need a sunxi/H3 image. Armbian’s Orange Pi Lite Debian Minimal CLI is the one with a current download.",
  },
  {
    q: "Is FlyOS itself Debian?",
    a: "FAST is a locked, read-only appliance built on Linux. It is not a usable Debian userspace. Older Mellow hosts had a fuller Armbian image; current Lite 2.1 docs point at FAST.",
  },
  {
    q: "What if Type-C serial never appears?",
    a: "Try another data-capable cable. If U-Boot never shows a port, the Type-C path is probably USB gadget and the foreign image has not loaded g_serial. Use a USB Ethernet dongle on a USB-A port, or a 3.3 V UART adapter on UART0 pads if you can identify them.",
  },
  {
    q: "Can I just boot the Gemini community Armbian image?",
    a: "No. Fly Gemini / Fly-Pi community images target H5-class Fly hosts with different DRAM and pinmux. Use them as a method reference, not as a Lite 2.1 image.",
  },
  {
    q: "Do I need to rebuild Armbian from source?",
    a: "Not for the first boot. Flash a stock Orange Pi Lite image. Rebuild only if you want a named fly-lite-2.1 board config, a custom kernel, or a DTB compiled in. Extraction plus overlays is faster.",
  },
  {
    q: "Will one image boot every Fly board?",
    a: "No. Lite 2.1 is H3/armhf. Pi V2 and Gemini are H5/aarch64. Pi V3 is H618/aarch64. Same first-boot file and bring-up method, different board files.",
  },
  {
    q: "Why did a bare bootz reset the board?",
    a: "bootz without a loaded FDT leaves Working FDT set to 0. This U-Boot has no ATAGS fallback. Load kernel, ramdisk, and the flat orangepi-lite.dtb, then bootz with all three addresses.",
  },
];
