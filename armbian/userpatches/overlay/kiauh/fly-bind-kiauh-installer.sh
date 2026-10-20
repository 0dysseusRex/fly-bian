#!/bin/bash
# Copy the pre-baked KIAUH installer into the first wizard user's home.
# Used on Pi V3 KIAUH images (installer only — no Klipper tree in /opt).
set -euo pipefail

MARKER=/var/lib/fly-kiauh-bound
SRC=/opt/fly-kiauh/kiauh

log() { logger -t fly-bind-kiauh -- "$*" 2>/dev/null || printf '%s\n' "$*"; }

if [[ -f $MARKER ]]; then
	exit 0
fi
[[ -d $SRC ]] || exit 0

user=""
uid=""
while IFS=: read -r name _ uid _ _ home _; do
	case "$uid" in
		''|*[!0-9]*) continue ;;
	esac
	if ((uid >= 1000 && uid < 60000)); then
		case "$name" in
			nobody|nfsnobody) continue ;;
		esac
		user=$name
		break
	fi
done </etc/passwd

if [[ -z ${user:-} ]]; then
	log "no wizard user yet; will retry next boot"
	exit 0
fi

home=$(getent passwd "$user" | cut -d: -f6)
if [[ -z $home || ! -d $home ]]; then
	log "home missing for $user"
	exit 0
fi

mkdir -p "$home/kiauh"
if command -v rsync >/dev/null; then
	rsync -a --ignore-existing "$SRC/" "$home/kiauh/"
else
	cp -a "$SRC/." "$home/kiauh/"
fi
chown -R "$user:$user" "$home/kiauh"
log "bound KIAUH installer for $user -> $home/kiauh"
date -u +%Y-%m-%dT%H:%M:%SZ >"$MARKER"
chmod 644 "$MARKER"
exit 0
