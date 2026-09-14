#!/usr/bin/env bash
# Guard Fly-bian version reuse.
# usage:
#   flybian-require-new-version.sh           # fail if any flavor already staged for this ver
#   flybian-require-new-version.sh <flavor>  # fail if that flavor's image already staged
# Override: FLY_FORCE=1
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
releases=${FLY_RELEASES:-/mnt/c/Users/udrdr/fly-lite-armbian-image/Releases}
device=${FLY_DEVICE:-Fly-Lite-2.1}
ver=$(tr -d '[:space:]' <"$root/FLYBIAN_VERSION")
want=${1:-}

if [[ ${FLY_FORCE:-0} == 1 || ${FLY_FORCE:-} == yes ]]; then
	echo "flybian-require-new-version: FLY_FORCE set; allowing reuse of $ver"
	exit 0
fi

flavor_token() {
	case "$1" in
		base|Base|minimal) echo Base ;;
		simpleaf|Simple-AF|simple-af) echo Simple-AF ;;
		kiauh|KIAUH) echo KIAUH ;;
		*)
			echo "unknown flavor: $1" >&2
			return 1
			;;
	esac
}

check_one() {
	local fl=$1 stem path
	fl=$(flavor_token "$fl")
	stem="Fly-bian-${ver}_${device}_${fl}"
	path="$releases/Fly-bian-${ver}/${device}/${fl}/${stem}.img.xz"
	if [[ -f $path ]]; then
		echo "ERROR: already staged: $path" >&2
		return 1
	fi
	return 0
}

failed=0
if [[ -n $want ]]; then
	check_one "$want" || failed=1
else
	for fl in base simpleaf kiauh; do
		check_one "$fl" || failed=1
	done
fi

if [[ $failed -eq 1 ]]; then
	cat >&2 <<EOF
Bump the product version before a new image publish:
  ./scripts/bump-flybian-version.sh
  # or edit FLYBIAN_VERSION (currently $ver)
Same version may still build Base+Simple-AF+KIAUH in one release; do not
restage over an existing flavor file. Override only if intentional: FLY_FORCE=1
See docs/image-naming.md.
EOF
	exit 1
fi

echo "flybian-require-new-version: OK for $ver${want:+ ($want)}"
