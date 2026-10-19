#!/usr/bin/env bash
# Bump repo-root FLYBIAN_VERSION. Required before each new image publish.
# usage: bump-flybian-version.sh [minor|major]
#   minor (default):
#     pre-1.0: +0.05  (0.5 -> 0.55 -> 0.60 -> … -> 1.0)
#     1.0+:    +0.1 on the minor field (1.0 -> 1.1)
#   major: 0.x -> 1.0, or 1.x -> 2.0, …
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
file=$root/FLYBIAN_VERSION
mode=${1:-minor}

cur=$(tr -d '[:space:]' <"$file")
[[ -n $cur ]] || { echo "empty FLYBIAN_VERSION" >&2; exit 1; }

next=$(
	awk -v v="$cur" -v mode="$mode" 'BEGIN {
		n = v + 0
		if (mode == "major") {
			if (n < 1.0) { print "1.0"; exit }
			major = int(n)
			print (major + 1) ".0"
			exit
		}
		if (mode != "minor") {
			print "BADMODE"
			exit
		}
		if (n < 1.0) {
			n += 0.05
			# float noise
			if (n >= 0.999) { print "1.0"; exit }
			printf "%.2f\n", n
			exit
		}
		# >= 1.0: bump minor digit (1.0 -> 1.1)
		major = int(n)
		minor = int((n - major) * 10 + 0.1)
		print major "." (minor + 1)
	}'
)

if [[ $next == BADMODE ]]; then
	echo "usage: $0 [major|minor]" >&2
	exit 1
fi

printf '%s\n' "$next" >"$file"
echo "FLYBIAN_VERSION: $cur -> $next"
echo "Next images: Fly-bian-${next}_<Device>_Base.img.xz"
echo "             Fly-bian-${next}_<Device>_Simple-AF-<pellcorpSHA>.img.xz"
echo "             Fly-bian-${next}_<Device>_KIAUH-<kiauhRev>.img.xz"
