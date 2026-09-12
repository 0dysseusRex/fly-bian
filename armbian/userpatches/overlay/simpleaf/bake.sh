# Sourced from customize-image.sh when BOARD=fly-lite-21-simpleaf.
# Pre-bake pellcorp + Klipper stack. Do not create a daily user.
set -euo pipefail

echo "Fly Lite 2.1 customize-image: Simple-AF bake"

# shellcheck source=/dev/null
source "$OVERLAY/klipper-stack/common-apt.sh"
fly_klipper_stack_apt

STACK=/opt/fly-simple-af
install -d "$STACK" /usr/share/fly-debian/simpleaf /etc/fly-debian
printf 'simpleaf\n' >/etc/fly-debian/stack-flavor

fly_git_clone https://github.com/pellcorp/creality.git "$STACK/pellcorp"
fly_git_clone https://github.com/Arksine/moonraker.git "$STACK/moonraker"
fly_git_clone https://github.com/pellcorp/klipper-rpi.git "$STACK/klipper"
fly_git_clone https://github.com/mainsail-crew/crowsnest.git "$STACK/crowsnest"
fly_web_release https://github.com/fluidd-core/fluidd/releases/latest/download/fluidd.zip \
	"$STACK/fluidd"
fly_web_release https://github.com/mainsail-crew/mainsail/releases/latest/download/mainsail.zip \
	"$STACK/mainsail"
fly_git_clone https://github.com/mainsail-crew/moonraker-timelapse.git "$STACK/moonraker-timelapse"
fly_git_clone https://github.com/Frix-x/klippain-shaketune.git "$STACK/klippain_shaketune"

echo "fly-bake: moonraker-env (no speedups / uvloop compile)"
fly_venv "$STACK/moonraker-env"
fly_pip_reqs "$STACK/moonraker-env" \
	"$STACK/moonraker/scripts/moonraker-requirements.txt"

echo "fly-bake: klippy-env (Debian numpy/matplotlib; no qemu source builds)"
fly_venv "$STACK/klippy-env"
fly_pip_reqs "$STACK/klippy-env" \
	"$STACK/klipper/scripts/klippy-requirements.txt" \
	"$STACK/pellcorp/rpi/klippy-requirements.txt" \
	"$STACK/klippain_shaketune/requirements.txt"

if [[ -d $STACK/pellcorp/rpi/nginx ]]; then
	install -d /etc/nginx/sites-available /etc/nginx/sites-enabled
	cp -a "$STACK/pellcorp/rpi/nginx/." /usr/share/fly-debian/simpleaf/nginx/ 2>/dev/null || true
fi
if [[ -f $STACK/pellcorp/rpi/moonraker.conf ]]; then
	install -d /usr/share/fly-debian/simpleaf/config
	for f in moonraker.conf moonraker.asvc crowsnest.conf webcam.conf timelapse.conf; do
		[[ -f $STACK/pellcorp/rpi/$f ]] && \
			install -m 0644 "$STACK/pellcorp/rpi/$f" "/usr/share/fly-debian/simpleaf/config/$f"
	done
fi

for f in klipper.service moonraker.service crowsnest.service pellcorp.done.software README.fragment; do
	if [[ -f $OVERLAY/simpleaf/$f ]]; then
		install -m 0644 "$OVERLAY/simpleaf/$f" "/usr/share/fly-debian/simpleaf/$f"
	fi
done

if [[ -f /boot/README.txt && -f $OVERLAY/simpleaf/README.fragment ]]; then
	cat "$OVERLAY/simpleaf/README.fragment" >>/boot/README.txt
	cp -a /boot/README.txt /usr/share/fly-debian/first-boot/README.txt 2>/dev/null || true
fi

chmod -R a+rX "$STACK"
echo "fly-bake: Simple-AF stack ready in $STACK"
