#!/bin/bash
# Pick an evdev node for GrumpyScreen (Fly-LCD HDMI, or Fly TFT V2 touch).
# Writes /run/fly-grumpy-evdev.env for EnvironmentFile=- in the unit.
# Must run as root (systemd ExecStartPre=+...); User=fly cannot write /run.
#
# Pi V3 masks systemd-udev-trigger (full coldplug kills the Type-C console),
# so early DRM/HID nodes stay 0600 root:root. Grumpy runs as the wizard user
# (video + input groups) and cannot open them. Fix those nodes here; do not
# unmask udev-trigger.
set -euo pipefail

out=/run/fly-grumpy-evdev.env
dev=""
want_handlers=0
shopt -s nullglob

fix_node() {
	local node=$1 group=$2
	[[ -e $node ]] || return 0
	chgrp "$group" "$node" 2>/dev/null || true
	chmod 0660 "$node" 2>/dev/null || true
}

for n in /dev/fb*; do
	fix_node "$n" video
done

# Prefer Fly-LCD USB/HDMI panels (by-id symlink), then SPI TFT touch.
for d in /dev/input/by-id/*Fly-LCD*event* /dev/input/by-id/*Fly_LCD*event* \
	/dev/input/by-id/*FLY-LCD*event*; do
	dev=$d
	break
done

# Fly-LCD / Fly TFT V2 Cap (Goodix GT911) or Resi (ADS7846) — match by name.
# by-id is often missing on Pi V3 because udev-trigger is masked.
if [[ -z $dev && -r /proc/bus/input/devices ]]; then
	while IFS= read -r line; do
		case "$line" in
			'N: Name="OpenMoko, Mellow Fly-LCD"'* | \
			'N: Name="Goodix Capacitive TouchScreen"'* | \
			'N: Name="ADS7846 Touchscreen"'* | \
			'N: Name="ADS7846"'*)
				want_handlers=1
				;;
			'H: Handlers='*)
				if [[ $want_handlers -eq 1 ]]; then
					handlers=${line#H: Handlers=}
					for tok in $handlers; do
						case "$tok" in
							event*)
								if [[ -e /dev/input/$tok ]]; then
									dev=/dev/input/$tok
									break 2
								fi
								;;
						esac
					done
					want_handlers=0
				fi
				;;
			'')
				want_handlers=0
				;;
		esac
	done </proc/bus/input/devices
fi

# Last resort: sole event node (common on Cap-only TFT setups).
if [[ -z $dev ]]; then
	set -- /dev/input/event*
	if [[ $# -eq 1 && -e $1 ]]; then
		dev=$1
	fi
fi

if [[ -n $dev ]]; then
	# Follow by-id / by-path so chmod hits the real event node.
	real=$dev
	if command -v readlink >/dev/null; then
		real=$(readlink -f "$dev" 2>/dev/null || printf '%s' "$dev")
	fi
	fix_node "$real" input
	printf 'LVGL_EVDEV_DEV=%s\n' "$dev" >"$out"
else
	# No touch node yet; leave empty so the unit can still start for display-only.
	: >"$out"
fi
chmod 0644 "$out"
