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
      "The Lite boots from MicroSD. Armbian Bookworm CLI for Orange Pi Lite is the closest public H3 image: same SoC, 512 MB, no Ethernet, SDIO Wi-Fi, two USB hosts.",
  },
  {
    id: "console",
    title: "Get a console",
    likelihood: "High",
    summary:
      "Mellow’s Type-C port shows up as USB serial on FlyOS. On Debian that is either a hardware UART-USB bridge (best case) or a USB gadget that needs musb in peripheral mode.",
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
    status: "Expected",
    how: "Flash Armbian to a second card. Keep official FlyOS on the first card as rollback.",
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
    status: "Likely",
    how: "If the PC sees a serial port during U-Boot, it is a UART bridge and just works. If it appears only after Linux, enable musb gadget (overlay in this repo).",
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
    title: "First boot with nothing but power and console",
    body: "Independent 5 V. Fit the IPEX antenna. Unplug the printer MCU, TFT, and HDMI. Watch the activity LED. Open Type-C serial at 115200 8N1 if a port appears.",
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

export const faqs = [
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
];
