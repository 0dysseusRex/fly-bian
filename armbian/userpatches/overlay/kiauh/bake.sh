# Sourced from customize-image.sh when BOARD=fly-lite-21-kiauh.
# Pre-bake KIAUH + stock Klipper/Moonraker/web UIs. Do not create a user.
set -euo pipefail

echo "Fly Lite 2.1 customize-image: KIAUH bake"

# shellcheck source=/dev/null
source "$OVERLAY/klipper-stack/common-apt.sh"
fly_klipper_stack_apt

STACK=/opt/fly-kiauh
install -d "$STACK" /usr/share/fly-debian/kiauh /etc/fly-debian
printf 'kiauh\n' >/etc/fly-debian/stack-flavo

fly_git_clone https://github.com/dw-0/kiauh.git "$STACK/kiauh"
fly_git_clone https://github.com/Klipper3d/klipper.git "$STACK/klipper"
fly_git_clone https://github.com/Arksine/moonraker.git "$STACK/moonraker"
fly_web_release https://github.com/fluidd-core/fluidd/releases/latest/download/fluidd.zip \
	"$STACK/fluidd"
fly_web_release https://github.com/mainsail-crew/mainsail/releases/latest/download/mainsail.zip \
	"$STACK/mainsail"
fly_git_clone https://github.com/mainsail-crew/crowsnest.git "$STACK/crowsnest"
fly_git_clone https://github.com/KlipperScreen/KlipperScreen.git "$STACK/KlipperScreen"

echo "fly-bake: moonraker-env (no speedups / uvloop compile)"
fly_venv "$STACK/moonraker-env"
fly_pip_reqs "$STACK/moonraker-env" \
	"$STACK/moonraker/scripts/moonraker-requirements.txt"

echo "fly-bake: klippy-env (Debian numpy/matplotlib; no qemu source builds)"
fly_venv "$STACK/klippy-env"
fly_pip_reqs "$STACK/klippy-env" \
	"$STACK/klipper/scripts/klippy-requirements.txt"

for f in klipper.service moonraker.service README.fragment; do
	if [[ -f $OVERLAY/kiauh/$f ]]; then
		install -m 0644 "$OVERLAY/kiauh/$f" "/usr/share/fly-debian/kiauh/$f"
	fi
done

if [[ -f /boot/README.txt && -f $OVERLAY/kiauh/README.fragment ]]; then
	cat "$OVERLAY/kiauh/README.fragment" >>/boot/README.txt
	cp -a /boot/README.txt /usr/share/fly-debian/first-boot/README.txt 2>/dev/null || true
fi

chmod -R a+rX "$STACK"
echo "fly-bake: KIAUH stack ready in $STACK"
