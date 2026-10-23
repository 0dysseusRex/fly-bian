#!/usr/bin/env bash
# Print the Fly-bian product version for FLY_DEVICE.
# Lite uses repo FLYBIAN_VERSION. Pi V3 uses FLY_PI_V3_VERSION.
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
device=${FLY_DEVICE:-Fly-Lite-2.1}
case "$device" in
	Fly-Pi-V3)
		f=$root/FLY_PI_V3_VERSION
		;;
	*)
		f=$root/FLYBIAN_VERSION
		;;
esac
ver=$(tr -d '[:space:]' <"$f")
[[ -n $ver ]] || { echo "empty $f" >&2; exit 1; }
printf '%s\n' "$ver"
