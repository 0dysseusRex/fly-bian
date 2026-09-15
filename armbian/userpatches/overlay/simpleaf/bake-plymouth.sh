#!/bin/bash
# Install Plymouth + Simple-AF theme into the image (called from simpleaf/bake.sh).
# Packages are the runtime deps; theme assets live under overlay/simpleaf/plymouth/.
set -euo pipefail

OVERLAY=${OVERLAY:-/tmp/overlay}
THEME_SRC=${1:-$OVERLAY/simpleaf/plymouth}
THEME_DST=/usr/share/plymouth/themes/simpleaf
STASH=/usr/share/fly-debian/simpleaf/plymouth

echo "fly-bake: Plymouth packages + Simple-AF boot theme"

export DEBIAN_FRONTEND=noninteractive
apt-get install -y --no-install-recommends \
	plymouth plymouth-themes unzip || {
	echo "fly-bake: WARN could not install plymouth packages" >&2
	return 0 2>/dev/null || exit 0
}

if [[ ! -f $THEME_SRC/simpleaf.zip ]]; then
	# Fall back to prebaked pellcorp tree when overlay copy is absent.
	if [[ -f /opt/fly-simple-af/pellcorp/rpi/plymouth/simpleaf.zip ]]; then
		THEME_SRC=/opt/fly-simple-af/pellcorp/rpi/plymouth
	else
		echo "fly-bake: WARN no simpleaf.zip theme assets; skip theme install" >&2
		return 0 2>/dev/null || exit 0
	fi
fi

rm -rf "$THEME_DST"
mkdir -p "$THEME_DST"
unzip -qo "$THEME_SRC/simpleaf.zip" -d "$THEME_DST"
# pellcorp ships .plymouth / .script beside the zip; prefer those.
[[ -f $THEME_SRC/simpleaf.plymouth ]] && \
	install -m 0644 "$THEME_SRC/simpleaf.plymouth" "$THEME_DST/simpleaf.plymouth"
[[ -f $THEME_SRC/simpleaf.script ]] && \
	install -m 0644 "$THEME_SRC/simpleaf.script" "$THEME_DST/simpleaf.script"

install -d "$STASH"
cp -a "$THEME_SRC/simpleaf.zip" "$STASH/" 2>/dev/null || true
[[ -f $THEME_SRC/simpleaf.plymouth ]] && cp -a "$THEME_SRC/simpleaf.plymouth" "$STASH/"
[[ -f $THEME_SRC/simpleaf.script ]] && cp -a "$THEME_SRC/simpleaf.script" "$STASH/"

if command -v plymouth-set-default-theme >/dev/null 2>&1; then
	# -R rebuilds initramfs so the theme is available at early boot.
	plymouth-set-default-theme -R simpleaf 2>/dev/null || \
		plymouth-set-default-theme simpleaf 2>/dev/null || true
fi

# Available out of the box; stay off until fly-boot-display enable /
# INSTALL_BOOT_DISPLAY=Yes (512 MB: splash is optional).
if [[ -f /boot/armbianEnv.txt ]]; then
	if grep -q '^bootlogo=' /boot/armbianEnv.txt; then
		sed -i 's/^bootlogo=.*/bootlogo=false/' /boot/armbianEnv.txt
	else
		echo 'bootlogo=false' >>/boot/armbianEnv.txt
	fi
fi

echo "fly-bake: Plymouth theme simpleaf installed (bootlogo=false until enabled)"
