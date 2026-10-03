# Sourced from customize-image.sh when BOARD=fly-lite-21-kiauh.
# Pre-bake KIAUH + stock Klipper/Moonraker/web UIs. Do not create a user.
set -euo pipefail

echo "Fly Lite 2.1 customize-image: KIAUH bake"

# shellcheck source=/dev/null
source "$OVERLAY/klipper-stack/common-apt.sh"
fly_klipper_stack_apt

STACK=/opt/fly-kiauh
install -d "$STACK" /usr/share/fly-debian/kiauh /etc/fly-debian
printf 'kiauh\n' >/etc/fly-debian/stack-flavor

fly_git_clone https://github.com/dw-0/kiauh.git "$STACK/kiauh"
fly_git_clone https://github.com/Klipper3d/klipper.git "$STACK/klipper"
fly_git_clone https://github.com/Arksine/moonraker.git "$STACK/moonraker"
fly_web_release https://github.com/fluidd-core/fluidd/releases/latest/download/fluidd.zip \
	"$STACK/fluidd"
fly_web_release https://github.com/mainsail-crew/mainsail/releases/latest/download/mainsail.zip \
	"$STACK/mainsail"
fly_git_clone https://github.com/mainsail-crew/crowsnest.git "$STACK/crowsnest"

# Optional KlipperScreen: pre-install heavy apt deps at bake time (build host
# has RAM). On-device KIAUH install still OOMs if these are pulled live on
# 512 MB — see docs/kiauh-fly-lite.md and fly-klipperscreen-prep.
fly_git_clone https://github.com/KlipperScreen/KlipperScreen.git "$STACK/KlipperScreen"
echo "fly-bake: KlipperScreen apt deps (X11 + PyGObject + fonts/mpv)"
export DEBIAN_FRONTEND=noninteractive
apt-get install -y --no-install-recommends \
	xinit xinput x11-xserver-utils \
	xserver-xorg-input-evdev xserver-xorg-input-libinput \
	xserver-xorg-legacy xserver-xorg-video-fbdev \
	libgirepository1.0-dev gcc libcairo2-dev pkg-config python3-dev gir1.2-gtk-3.0 \
	librsvg2-common libopenjp2-7 libdbus-glib-1-dev autoconf \
	fonts-nanum fonts-ipafont libmpv-dev \
	build-essential cmake libsystemd-dev || {
	echo "fly-bake: WARN KlipperScreen apt deps incomplete (non-fatal)"
}
if [[ -f $STACK/KlipperScreen/scripts/KlipperScreen-requirements.txt ]]; then
	echo "fly-bake: KlipperScreen venv (piwheels)"
	fly_venv "$STACK/KlipperScreen-env"
	# armv7: prefer piwheels binary wheels to avoid qemu source builds.
	"$STACK/KlipperScreen-env/bin/pip" install --prefer-binary \
		--extra-index-url https://www.piwheels.org/simple \
		-r "$STACK/KlipperScreen/scripts/KlipperScreen-requirements.txt" \
		|| echo "fly-bake: WARN KlipperScreen pip incomplete (non-fatal)"
	# Upstream install defaults to ~/.KlipperScreen-env
	rm -rf "$STACK/.KlipperScreen-env"
	mv "$STACK/KlipperScreen-env" "$STACK/.KlipperScreen-env"
fi

echo "fly-bake: moonraker-env (no speedups / uvloop compile)"
fly_venv "$STACK/moonraker-env"
fly_pip_reqs "$STACK/moonraker-env" \
	"$STACK/moonraker/scripts/moonraker-requirements.txt"

echo "fly-bake: klippy-env (Debian numpy/matplotlib; no qemu source builds)"
fly_venv "$STACK/klippy-env"
fly_pip_reqs "$STACK/klippy-env" \
	"$STACK/klipper/scripts/klippy-requirements.txt"

install -d /usr/share/fly-debian/kiauh/nginx /usr/share/fly-debian/kiauh/config
for f in klipper.service moonraker.service README.fragment; do
	if [[ -f $OVERLAY/kiauh/$f ]]; then
		install -m 0644 "$OVERLAY/kiauh/$f" "/usr/share/fly-debian/kiauh/$f"
	fi
done
# Nginx templates from the bundled KIAUH tree (sites-available on bind).
KIAUH_ASSETS="$STACK/kiauh/kiauh/components/webui_client/assets"
if [[ ! -d $KIAUH_ASSETS && -d $OVERLAY/kiauh/kiauh/components/webui_client/assets ]]; then
	KIAUH_ASSETS=$OVERLAY/kiauh/kiauh/components/webui_client/assets
fi
for f in nginx_cfg upstreams.conf common_vars.conf; do
	if [[ -f $KIAUH_ASSETS/$f ]]; then
		install -m 0644 "$KIAUH_ASSETS/$f" "/usr/share/fly-debian/kiauh/nginx/$f"
	fi
done
if [[ -d $OVERLAY/kiauh/config ]]; then
	cp -a "$OVERLAY/kiauh/config/." /usr/share/fly-debian/kiauh/config/
fi

# KIAUH first-boot: no Simple-AF INSTALL_CMD / Plymouth / Grumpy keys.
if [[ -f $OVERLAY/kiauh/fly-start.txt ]]; then
	install -m 0644 "$OVERLAY/kiauh/fly-start.txt" /usr/share/fly-debian/first-boot/fly-start.txt
	install -m 0644 "$OVERLAY/kiauh/fly-start.txt" /boot/fly-start.txt
fi

if [[ -f /boot/README.txt && -f $OVERLAY/kiauh/README.fragment ]]; then
	cat "$OVERLAY/kiauh/README.fragment" >>/boot/README.txt
	cp -a /boot/README.txt /usr/share/fly-debian/first-boot/README.txt 2>/dev/null || true
fi

# Simple-AF-only helpers are not useful on this image.
rm -f /usr/local/bin/fly-boot-display \
	/usr/local/bin/fly-grumpy-rotate \
	/usr/local/bin/fly-ensure-shaketune \
	/usr/local/bin/fly-start

if [[ -f $OVERLAY/tools/fly-kiauh ]]; then
	install -m 0755 "$OVERLAY/tools/fly-kiauh" /usr/local/bin/fly-kiauh
fi
if [[ -f $OVERLAY/tools/fly-klipperscreen-prep ]]; then
	install -m 0755 "$OVERLAY/tools/fly-klipperscreen-prep" \
		/usr/local/bin/fly-klipperscreen-prep
fi

# Re-patch MOTD Commands for KIAUH labels (Help / KIAUH / Cameras).
if [[ -x /usr/share/fly-debian/motd/patch-armbian-commands.py ]]; then
	python3 /usr/share/fly-debian/motd/patch-armbian-commands.py \
		/etc/update-motd.d/41-commands kiauh || true
fi

chmod -R a+rX "$STACK"
fly_set_stack_identity kiauh "$STACK/kiauh"
echo "fly-bake: KIAUH stack ready in $STACK"
