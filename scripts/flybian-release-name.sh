#!/usr/bin/env bash
# Print Fly-bian product image stem / paths from FLYBIAN_VERSION + flavor.
# usage:
#   flybian-release-name.sh stem base|simpleaf|kiauh [device] [stack_rev]
#   flybian-release-name.sh dir  base|simpleaf|kiauh [device]
#
# Simple-AF / KIAUH stems append -<stack_rev> (pellcorp SHA or KIAUH tag).
# stack_rev may also come from env FLY_STACK_REV or meta file (staging).
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
mode=${1:?usage: $0 stem|dir <flavor> [device] [stack_rev]}
flavor=${2:?}
device=${3:-Fly-Lite-2.1}
stack_rev=${4:-${FLY_STACK_REV:-}}

ver=$(tr -d '[:space:]' <"$root/FLYBIAN_VERSION")
[[ -n $ver ]] || { echo "empty FLYBIAN_VERSION" >&2; exit 1; }

case "$flavor" in
	base|Base|minimal) flavor_token=Base ;;
	simpleaf|Simple-AF|simple-af) flavor_token=Simple-AF ;;
	kiauh|KIAUH) flavor_token=KIAUH ;;
	*)
		echo "unknown flavor: $flavor (want base|simpleaf|kiauh)" >&2
		exit 1
		;;
esac

# Folder stays Base / Simple-AF / KIAUH (no rev); filename carries the rev.
rel_dir="Fly-bian-${ver}/${device}/${flavor_token}"

if [[ $flavor_token == Base ]]; then
	stem="Fly-bian-${ver}_${device}_${flavor_token}"
else
	stack_rev=${stack_rev:-unknown}
	# Sanitize (bake already does; staging may pass raw describe).
	stack_rev=$(printf '%s' "$stack_rev" | tr -c 'A-Za-z0-9._-' '-' | sed -E 's/-+/-/g; s/^-+//; s/-+$//')
	stem="Fly-bian-${ver}_${device}_${flavor_token}-${stack_rev}"
fi

case "$mode" in
	stem) printf '%s\n' "$stem" ;;
	dir) printf '%s\n' "$rel_dir" ;;
	*)
		echo "usage: $0 stem|dir <flavor> [device] [stack_rev]" >&2
		exit 1
		;;
esac
