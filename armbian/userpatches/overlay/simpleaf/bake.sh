# Sourced from customize-image.sh when BOARD=fly-lite-21-simpleaf.
# Pre-bake pellcorp + Klipper stack. Do not create a daily user.
set -euo pipefail

echo "Fly Lite 2.1 customize-image: Simple-AF bake"

# shellcheck source=/dev/null
source "$OVERLAY/klipper-stack/common-apt.sh"
fly_klipper_stack_apt

STACK=/opt/fly-simple-af
install -d "$STACK" /usr/share/fly-debian/simpleaf /etc/fly-debian
printf 'simpleaf\n' >/etc/fly-debian/stack-flavo

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

# Do not mark "klipper" in pellcorp.done — install-klipper.sh must still stage
# homing.cfg / macros for the chosen printer. Keep trees when that runs.
install -d /etc/fly-debian
: >/etc/fly-debian/prebaked-simpleaf
if [[ -f $OVERLAY/simpleaf/patch-install-klipper.sh ]]; then
	bash "$OVERLAY/simpleaf/patch-install-klipper.sh" \
		"$STACK/pellcorp/rpi/install-klipper.sh"
fi
if [[ -f $OVERLAY/simpleaf/patch-config-helper.sh && -f $STACK/pellcorp/tools/config-helper.py ]]; then
	bash "$OVERLAY/simpleaf/patch-config-helper.sh" \
		"$STACK/pellcorp/tools/config-helper.py"
fi
if [[ -f $OVERLAY/simpleaf/patch-installer-cleanup.sh && -f $STACK/pellcorp/rpi/installer.sh ]]; then
	bash "$OVERLAY/simpleaf/patch-installer-cleanup.sh" \
		"$STACK/pellcorp/rpi/installer.sh"
fi

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
	install -d /etc/nginx/sites-available /etc/nginx/sites-enabled \
		/usr/share/fly-debian/simpleaf/nginx
	cp -a "$STACK/pellcorp/rpi/nginx/." /usr/share/fly-debian/simpleaf/nginx/
fi
if [[ -f $STACK/pellcorp/rpi/moonraker.conf ]]; then
	install -d /usr/share/fly-debian/simpleaf/config
	for f in moonraker.conf moonraker.asvc crowsnest.conf webcam.conf timelapse.conf; do
		[[ -f $STACK/pellcorp/rpi/$f ]] && \
			install -m 0644 "$STACK/pellcorp/rpi/$f" "/usr/share/fly-debian/simpleaf/config/$f"
	done
	# Drop pellcorp [cam web] / /dev/video0 example — on H3 video0 is cedrus.
	if [[ -x $OVERLAY/crowsnest/fly-crowsnest-strip-placeholders ]]; then
		for f in \
			"$STACK/pellcorp/rpi/crowsnest.conf" \
			/usr/share/fly-debian/simpleaf/config/crowsnest.conf; do
			[[ -f $f ]] && python3 "$OVERLAY/crowsnest/fly-crowsnest-strip-placeholders" "$f" || true
		done
	fi
	# moonraker.conf includes these; without them the service crash-loops.
	for f in notifier.conf spoolman.conf; do
		[[ -f $STACK/pellcorp/config/$f ]] && \
			install -m 0644 "$STACK/pellcorp/config/$f" "/usr/share/fly-debian/simpleaf/config/$f"
	done
fi

# ARMv7 GrumpyScreen — preferred touch UI on Fly Lite (512 MB). KlipperScreen
# (X/Mesa) OOMs this board. First-user bind enables the unit and frees tty1.
if [[ -f $OVERLAY/simpleaf/grumpyscreen/grumpyscreen ]]; then
	install -d "$STACK/grumpyscreen" /usr/share/fly-debian/simpleaf/grumpyscreen
	install -m 0755 "$OVERLAY/simpleaf/grumpyscreen/grumpyscreen" \
		"$STACK/grumpyscreen/grumpyscreen"
	install -m 0755 "$OVERLAY/simpleaf/grumpyscreen/grumpyscreen" \
		/usr/share/fly-debian/simpleaf/grumpyscreen/grumpyscreen
	for f in grumpyscreen.cfg release.info; do
		[[ -f $OVERLAY/simpleaf/grumpyscreen/$f ]] || continue
		install -m 0644 "$OVERLAY/simpleaf/grumpyscreen/$f" "$STACK/grumpyscreen/$f"
		install -m 0644 "$OVERLAY/simpleaf/grumpyscreen/$f" \
			"/usr/share/fly-debian/simpleaf/grumpyscreen/$f"
	done
fi
if [[ -f $OVERLAY/simpleaf/fly-grumpy-evdev.sh ]]; then
	install -m 0755 "$OVERLAY/simpleaf/fly-grumpy-evdev.sh" \
		/usr/local/sbin/fly-grumpy-evdev.sh
fi

for f in klipper.service moonraker.service crowsnest.service grumpyscreen.service \
	pellcorp.done.software README.fragment patch-install-klipper.sh \
	patch-config-helper.sh patch-installer-cleanup.sh; do
	if [[ -f $OVERLAY/simpleaf/$f ]]; then
		install -m 0644 "$OVERLAY/simpleaf/$f" "/usr/share/fly-debian/simpleaf/$f"
	fi
done
# patch scripts must stay executable if copied for reference
for f in patch-install-klipper.sh patch-config-helper.sh patch-installer-cleanup.sh; do
	[[ -f /usr/share/fly-debian/simpleaf/$f ]] && chmod 0755 "/usr/share/fly-debian/simpleaf/$f"
done

if [[ -f /boot/README.txt && -f $OVERLAY/simpleaf/README.fragment ]]; then
	cat "$OVERLAY/simpleaf/README.fragment" >>/boot/README.txt
	cp -a /boot/README.txt /usr/share/fly-debian/first-boot/README.txt 2>/dev/null || true
fi

chmod -R a+rX "$STACK"
echo "fly-bake: Simple-AF stack ready in $STACK"
