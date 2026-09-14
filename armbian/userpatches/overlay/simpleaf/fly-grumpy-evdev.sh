#!/bin/bash
# Pick a Fly-LCD (or any *Fly*LCD*) evdev node for GrumpyScreen.
# Writes /run/fly-grumpy-evdev.env for EnvironmentFile=- in the unit.
# Must run as root (systemd ExecStartPre=+...); User=fly cannot write /run.
set -euo pipefail

out=/run/fly-grumpy-evdev.env
dev=""
shopt -s nullglob
for d in /dev/input/by-id/*Fly-LCD*event* /dev/input/by-id/*Fly_LCD*event* \
	/dev/input/by-id/*FLY-LCD*event*; do
	dev=$d
	break
done
if [[ -n $dev ]]; then
	printf 'LVGL_EVDEV_DEV=%s\n' "$dev" >"$out"
else
	# No touch node yet; leave empty so the unit can still start for display-only.
	: >"$out"
fi
chmod 0644 "$out"
