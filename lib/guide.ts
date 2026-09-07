export const sources = [
  {
    label: "FLY Lite 2.1 product docs",
    href: "https://mellow.klipper.cn/en/docs/ProductDoc/SBC/fly-lite/lite2.1/",
  },
  {
    label: "FlyOS-FAST system notes",
    href: "https://mellow.klipper.cn/en/docs/ProductDoc/SBC/fly-lite/lite2/host/",
  },
  {
    label: "SimpleAF for RPi",
    href: "https://pellcorp.github.io/creality-wiki/rpi/",
  },
  {
    label: "SimpleAF supported OS list",
    href: "https://pellcorp.github.io/creality-wiki/rpi_supported_os/",
  },
  {
    label: "Community Armbian for Fly Gemini / Fly-Pi",
    href: "https://github.com/reemo3dp/mellowfly-geminipi-armbian",
  },
] as const;

export const specs = [
  { label: "SoC", value: "Allwinner H3, 4× Cortex-A7" },
  { label: "GPU", value: "Mali-400 MP2" },
  { label: "RAM", value: "512 MB DDR3" },
  { label: "Storage", value: "MicroSD 16–128 GB, C10+" },
  { label: "Network", value: "Onboard 2.4 GHz Wi-Fi only" },
  { label: "USB", value: "USB 2.0 × 2, Type-C power/serial" },
  { label: "Display", value: "FPC-HDMI + FPC-TFT" },
  { label: "Power", value: "Independent 5 V, not from the printer MCU" },
] as const;

export const verdicts = [
  {
    tone: "go" as const,
    title: "Custom Debian is possible",
    body: "The Lite V2.1 is a Linux single-board computer, not a microcontroller. It boots from a MicroSD card, so replacing FlyOS with another ARM Debian image is the normal install method.",
  },
  {
    tone: "stop" as const,
    title: "Stock FlyOS-FAST cannot run SimpleAF",
    body: "FlyOS-FAST is root-only, mostly read-only, and ships without a normal package manager. SimpleAF’s installer needs apt, git, a non-root sudo user, and a clean host with no existing Klipper stack.",
  },
  {
    tone: "caution" as const,
    title: "Full board functionality is the hard part",
    body: "USB to the printer MCU is realistic. Onboard Wi-Fi, the FPC screen ports, Type-C serial, and Mellow power-loss extras depend on Fly’s device tree and userspace. 512 MB RAM also forces a lean SimpleAF install.",
  },
];

export const flyosBlockers = [
  {
    fly: "Only the root user exists",
    simple: "Installer must be run as a normal user (pi, orangepi, dietpi). Root is rejected.",
  },
  {
    fly: "Traditional package managers were removed",
    simple: "First steps are sudo apt-get update and apt-get install git.",
  },
  {
    fly: "Root filesystem is read-only except /etc and /data",
    simple: "The stack lives in a normal home directory and system service paths.",
  },
  {
    fly: "Klipper, Moonraker, Fluidd, Mainsail, KlipperScreen, and Crowsnest are preinstalled",
    simple: "Do not install onto Mainsail OS, KIAUH, or any existing Klipper host.",
  },
  {
    fly: "Official docs say FAST does not support updating Klipper-style plugins",
    simple: "SimpleAF replaces Klipper/Kalico and related services on purpose.",
  },
];

export const features = [
  {
    name: "Boot from MicroSD",
    flyos: "Works",
    generic: "Works",
    flyDtb: "Works",
    note: "This is how the board is meant to be installed. Keep a second card with FlyOS so you can revert.",
  },
  {
    name: "USB host to printer MCU",
    flyos: "Works",
    generic: "Likely",
    flyDtb: "Likely",
    note: "Standard H3 USB host. This is the path SimpleAF actually needs.",
  },
  {
    name: "Onboard 2.4 GHz Wi-Fi",
    flyos: "Works",
    generic: "Uncertain",
    flyDtb: "Plausible",
    note: "SDIO Wi-Fi, usually an RTL8189-class chip on H3 lite boards. Needs the right device tree and firmware. No 5 GHz, ever.",
  },
  {
    name: "USB Ethernet or USB Wi-Fi dongle",
    flyos: "Works",
    generic: "Likely",
    flyDtb: "Likely",
    note: "The reliable fallback. Bring a dongle so a missing onboard driver does not brick the project.",
  },
  {
    name: "Type-C serial console",
    flyos: "Works",
    generic: "Uncertain",
    flyDtb: "Plausible",
    note: "Use a data-capable Type-C cable. If the PC never sees a USB serial device, you need Fly gadget/UART enablement or a 3.3 V UART adapter.",
  },
  {
    name: "FPC-TFT / KlipperScreen",
    flyos: "Works",
    generic: "Unlikely",
    flyDtb: "Extra work",
    note: "Fly-specific SPI pinmux and overlays. Community DTS work exists for other Fly H3 boards, not a drop-in for Lite 2.1.",
  },
  {
    name: "FPC-HDMI",
    flyos: "Works",
    generic: "Unlikely",
    flyDtb: "Extra work",
    note: "Custom FPC pinout, not a stock Orange Pi HDMI connector.",
  },
  {
    name: "KPPM power-loss resume",
    flyos: "Works",
    generic: "No",
    flyDtb: "No",
    note: "Hardware module plus FlyOS userspace. Leave it off unless you port Mellow’s scripts.",
  },
  {
    name: "Auto MCU flash on boot",
    flyos: "Works",
    generic: "No",
    flyDtb: "DIY",
    note: "A FlyOS convenience. SimpleAF does not need it; you flash the printer board once over USB.",
  },
];

export const ramBudget = [
  { item: "Debian Bookworm CLI, idle", size: "~80–120 MB" },
  { item: "Klipper host + MCU serial", size: "~40–80 MB" },
  { item: "Moonraker", size: "~50–90 MB" },
  { item: "Nginx + one web UI", size: "~30–60 MB" },
  { item: "Second web UI (Fluidd + Mainsail)", size: "extra idle cost" },
  { item: "Crowsnest / webcam", size: "100 MB+ and CPU", warn: true },
  { item: "KlipperScreen + GPU/framebuffer", size: "too much on 512 MB", warn: true },
];

export const planSteps = [
  {
    title: "Keep a recovery card",
    body: "Flash official FlyOS-FAST on one MicroSD and leave it alone. Use a second card for Debian. The Lite has no eMMC, so swapping cards is a full rollback.",
  },
  {
    title: "Start from Armbian Bookworm CLI",
    body: "The closest public boards are Orange Pi Lite and Orange Pi One: same H3, 512 MB, SD boot. Use a minimal Debian 12 image, not a desktop build. H3 is 32-bit ARM; SimpleAF supports that.",
  },
  {
    title: "Get a console before you care about Wi-Fi",
    body: "First boot over Type-C serial if it enumerates, otherwise a USB Ethernet dongle. Create a non-root sudo user. SimpleAF will refuse to run as root.",
  },
  {
    title: "Make 512 MB survivable",
    body: "Enable zram and a 1 GB swap file. Do not install a desktop. Plan to skip Crowsnest and KlipperScreen. One web interface is enough even if SimpleAF installs both.",
  },
  {
    title: "Install SimpleAF on a clean host",
    body: "apt-get install git, clone pellcorp/creality, then run installer.sh as that normal user with --printer and --probe. Point --printer at a single printer.cfg for your actual motion board, not the Lite.",
  },
  {
    title: "Treat Fly extras as a second project",
    body: "If onboard Wi-Fi or the FPC screen still matter, extract the device tree and firmware from the official H3 FlyOS image and layer them on Armbian. That is how the Fly Gemini community images were built. It is not required for SimpleAF.",
  },
];

export const faqs = [
  {
    q: "Is the Fly Lite V2.1 a Raspberry Pi?",
    a: "No. It is an Allwinner H3 board sold as a Pi replacement for Klipper hosting. Same job, different SoC, different boot firmware, 512 MB RAM, and no Ethernet jack.",
  },
  {
    q: "Can I install SimpleAF on top of the image Mellow already ships?",
    a: "Not the current FlyOS-FAST image. It is intentionally locked down. You replace the SD card image with a real Debian-based system first.",
  },
  {
    q: "Does SimpleAF support this board by name?",
    a: "No. The RPi variant targets Debian 11–13 on Pi-like SBCs: Raspberry Pi, Orange Pi, DietPi, Armbian, BTT CB/CM boards. The Lite qualifies only after you put a normal Debian userspace on it.",
  },
  {
    q: "What is the printer MCU in this setup?",
    a: "The Lite is the host. Your Ender, Voron, or other control board is still the MCU. SimpleAF needs a single printer.cfg with that board’s pins. The Lite does not replace the motion controller.",
  },
  {
    q: "Will Armbian for Orange Pi Lite just boot?",
    a: "Often yes for basic CPU, SD, and USB. Onboard Wi-Fi, FPC displays, and Type-C gadget serial are the parts that may need Fly’s device tree. Always have a USB network dongle before you wipe the FlyOS card you are using now.",
  },
  {
    q: "Is there an official Mellow Debian I can use instead?",
    a: "Older Fly hosts had a fuller Armbian image with apt. Current Lite 2.1 docs point at FlyOS-FAST. Community Armbian patches exist for Fly Gemini / Fly-Pi; they are the right reference, not a guaranteed Lite 2.1 image.",
  },
];
