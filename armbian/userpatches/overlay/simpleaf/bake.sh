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
if [[ -f $OVERLAY/simpleaf/patch-shaketune-importlib.sh && -f $STACK/klippain_shaketune/shaketune/shaketune.py ]]; then
	bash "$OVERLAY/simpleaf/patch-shaketune-importlib.sh" \
		"$STACK/klippain_shaketune/shaketune/shaketune.py"
fi

# Plymouth Simple-AF early-boot splash (packages + theme). Toggle with
# fly-boot-display / INSTALL_BOOT_DISPLAY — default bootlogo=false.
if [[ -f $OVERLAY/simpleaf/bake-plymouth.sh ]]; then
	# shellcheck source=/dev/null
	source "$OVERLAY/simpleaf/bake-plymouth.sh" "$OVERLAY/simpleaf/plymouth"
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

# So [shaketune] is valid after bind without a separate install.sh run.
if [[ -d $STACK/klippain_shaketune/shaketune && -d $STACK/klipper/klippy/extras ]]; then
	ln -sfn "$STACK/klippain_shaketune/shaketune" \
		"$STACK/klipper/klippy/extras/shaketune"
	echo "fly-bake: linked klippy extras/shaketune"
fi

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
	# 512 MB: apt CLI instead of PackageKit (avoids Mainsail PolKit noise).
	if [[ -f /usr/share/fly-debian/simpleaf/config/moonraker.conf ]]; then
		cfg=/usr/share/fly-debian/simpleaf/config/moonraker.conf
		if grep -qE '^[[:space:]]*enable_packagekit[[:space:]]*:' "$cfg"; then
			sed -i -E 's|^[[:space:]]*enable_packagekit[[:space:]]*:.*|enable_packagekit: False|' "$cfg"
		elif grep -q '^\[update_manager\]' "$cfg"; then
			sed -i '/^\[update_manager\]/a enable_packagekit: False' "$cfg"
		else
			printf '\n[update_manager]\nenable_packagekit: False\n' >>"$cfg"
		fi
	fi
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

# Ensure GrumpyScreen override carries display_rotate in [ui]. Simple-AF's
# install-grumpyscreen.sh copies pellcorp/config/grumpyscreen.ini over
# printer_data/config/ — without this key, rotation falls back to the base
# cfg and user fly-grumpy-rotate settings get wiped on reinstall.
install -d /usr/share/fly-debian/simpleaf/config
ensure_grumpy_display_rotate() {
	local f=$1
	[[ -f $f ]] || return 0
	if grep -qiE '^[[:space:]]*display_rotate[[:space:]]*:' "$f"; then
		return 0
	fi
	if grep -q '^\[ui\]' "$f"; then
		sed -i '/^\[ui\]/a display_rotate: 0' "$f"
	else
		printf '\n[ui]\ndisplay_rotate: 0\n' >>"$f"
	fi
}
if [[ -f $STACK/pellcorp/config/grumpyscreen.ini ]]; then
	ensure_grumpy_display_rotate "$STACK/pellcorp/config/grumpyscreen.ini"
	install -m 0644 "$STACK/pellcorp/config/grumpyscreen.ini" \
		/usr/share/fly-debian/simpleaf/config/grumpyscreen.ini
fi
# Bind-time seed (rsync --ignore-existing): minimal override if no pellcorp copy.
if [[ -f $OVERLAY/simpleaf/config/grumpyscreen.ini ]]; then
	if [[ ! -f /usr/share/fly-debian/simpleaf/config/grumpyscreen.ini ]]; then
		install -m 0644 "$OVERLAY/simpleaf/config/grumpyscreen.ini" \
			/usr/share/fly-debian/simpleaf/config/grumpyscreen.ini
	else
		ensure_grumpy_display_rotate /usr/share/fly-debian/simpleaf/config/grumpyscreen.ini
	fi
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
	patch-config-helper.sh patch-installer-cleanup.sh patch-shaketune-importlib.sh; do
	if [[ -f $OVERLAY/simpleaf/$f ]]; then
		install -m 0644 "$OVERLAY/simpleaf/$f" "/usr/share/fly-debian/simpleaf/$f"
	fi
done
# patch scripts must stay executable if copied for reference
for f in patch-install-klipper.sh patch-config-helper.sh patch-installer-cleanup.sh \
	patch-shaketune-importlib.sh; do
	[[ -f /usr/share/fly-debian/simpleaf/$f ]] && chmod 0755 "/usr/share/fly-debian/simpleaf/$f"
done

if [[ -f /boot/README.txt && -f $OVERLAY/simpleaf/README.fragment ]]; then
	cat "$OVERLAY/simpleaf/README.fragment" >>/boot/README.txt
	cp -a /boot/README.txt /usr/share/fly-debian/first-boot/README.txt 2>/dev/null || true
fi

chmod -R a+rX "$STACK"
fly_set_stack_identity simpleaf "$STACK/pellcorp"
echo "fly-bake: Simple-AF stack ready in $STACK"
