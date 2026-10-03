#!/usr/bin/env bash
# Bump repo-root FLYBIAN_VERSION (0.2 -> 0.3, …). Required before each new image publish.
# usage: bump-flybian-version.sh [major|minor]
#   minor (default): 0.2 -> 0.3
#   major:           0.9 -> 1.0  (or 1.0 -> 2.0)
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
file=$root/FLYBIAN_VERSION
mode=${1:-minor}

cur=$(tr -d '[:space:]' <"$file")
[[ -n $cur ]] || { echo "empty FLYBIAN_VERSION" >&2; exit 1; }

IFS=. read -r major minor _ <<<"${cur}."
major=${major:-0}
minor=${minor:-0}

case "$mode" in
	minor)
		minor=$((minor + 1))
		;;
	major)
		major=$((major + 1))
		minor=0
		;;
	*)
		echo "usage: $0 [major|minor]" >&2
		exit 1
		;;
esac

next="${major}.${minor}"
printf '%s\n' "$next" >"$file"
echo "FLYBIAN_VERSION: $cur -> $next"
echo "Next images: Fly-bian-${next}_<Device>_Base.img.xz"
echo "             Fly-bian-${next}_<Device>_Simple-AF-<pellcorpSHA>.img.xz"
echo "             Fly-bian-${next}_<Device>_KIAUH-<kiauhRev>.img.xz"
