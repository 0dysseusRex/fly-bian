# Mellow Fly Lite 2.1 (Allwinner H3). Start from Orange Pi Lite boot blob,
# then Fly DTB + SD card-detect patch in customize-image / kernel patchdir.
BOARD_NAME="Fly Lite 2.1"
BOARDFAMILY="sun8i"
BOARD_MAINTAINER=""
BOOTCONFIG="orangepi_lite_defconfig"
KERNEL_TARGET="current,edge"
KERNEL_TEST_TARGET="current"
FULL_DESKTOP="no"
BOOT_LOGO="desktop"

# FAT volume Windows/macOS/Linux can mount. If sun8i ignores this, the
# build notes in docs/build-named-image.md add FLY-SETUP another way.
BOOTFS_TYPE="fat"
BOOTSIZE="256"

DEFAULT_OVERLAYS="uart1 usbhost0 usbhost2 usbhost3"
ENABLE_EXTENSIONS="wsl-docker-dns fly-windows-bootfs"
