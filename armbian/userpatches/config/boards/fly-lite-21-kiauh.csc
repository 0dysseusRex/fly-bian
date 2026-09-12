# Mellow Fly Lite 2.1 — KIAUH-centered stack pre-baked.
# Same hardware as fly-lite-21.csc. Do not mix with the Simple-AF board.
BOARD_NAME="Fly Lite 2.1 KIAUH"
BOARDFAMILY="sun8i"
BOARD_MAINTAINER=""
BOOTCONFIG="orangepi_lite_defconfig"
KERNEL_TARGET="current,edge"
KERNEL_TEST_TARGET="current"
FULL_DESKTOP="no"
BOOT_LOGO="desktop"

BOOTFS_TYPE="fat"
BOOTSIZE="256"

DEFAULT_OVERLAYS="uart1 usbhost0 usbhost2 usbhost3"
ENABLE_EXTENSIONS="wsl-docker-dns fly-windows-bootfs"
