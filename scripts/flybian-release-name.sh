#!/usr/bin/env bash
# Print Fly-bian product image stem / paths from FLYBIAN_VERSION + flavor.
# usage:
#   flybian-release-name.sh stem base|simpleaf|kiauh [device]
#   flybian-release-name.sh dir  base|simpleaf|kiauh [device]
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
mode=${1:?usage: $0 stem|dir <flavor> [device]}
flavor=${2:?}
device=${3:-Fly-Lite-2.1}

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

stem="Fly-bian-${ver}_${device}_${flavor_token}"
rel_dir="Fly-bian-${ver}/${device}/${flavor_token}"

case "$mode" in
	stem) printf '%s\n' "$stem" ;;
	dir) printf '%s\n' "$rel_dir" ;;
	*)
		echo "usage: $0 stem|dir <flavor> [device]" >&2
		exit 1
		;;
esac
