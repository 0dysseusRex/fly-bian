#!/bin/bash
# Copy the pre-baked stack from /opt into the first wizard/fly-net user.
# Never creates that user. Safe to run every boot until it binds once.
set -euo pipefail

MARKER=/var/lib/fly-stack-bound
FLAVOR_FILE=/etc/fly-debian/stack-flavor
OPT_SAF=/opt/fly-simple-af
OPT_KIAUH=/opt/fly-kiauh

log() { logger -t fly-bind-stack -- "$*" 2>/dev/null || printf '%s\n' "$*"; }

if [[ -f $MARKER ]]; then
	exit 0
fi

flavor=""
[[ -f $FLAVOR_FILE ]] && flavor=$(tr -d '\r\n' <"$FLAVOR_FILE")

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

if [[ -z $user ]]; then
	log "no wizard user yet; will retry next boot"
	exit 0
fi

home=$(getent passwd "$user" | cut -d: -f6)
if [[ -z $home || ! -d $home ]]; then
	log "home missing for $user"
	exit 0
fi

bind_tree() {
	local src=$1
	[[ -d $src ]] || return 0
	mkdir -p "$home"
	# Keep existing files the user already created.
	if command -v rsync >/dev/null; then
		rsync -a --ignore-existing "$src/" "$home/"
	else
		cp -a "$src/." "$home/"
	fi
	chown -R "$user:$user" "$home"
}

install_unit() {
	local src=$1 dest=$2
	[[ -f $src ]] || return 0
	sed -e "s|__USER__|$user|g" -e "s|__HOME__|$home|g" "$src" >"$dest"
}

case "$flavor" in
	simpleaf)
		bind_tree "$OPT_SAF"
		mkdir -p "$home/printer_data/config" "$home/printer_data/logs" "$home/printer_data/gcodes"
		if [[ -d /usr/share/fly-debian/simpleaf/config ]]; then
			rsync -a --ignore-existing /usr/share/fly-debian/simpleaf/config/ \
				"$home/printer_data/config/"
		fi
		if [[ -f /usr/share/fly-debian/simpleaf/pellcorp.done.software ]]; then
			if [[ ! -f $home/pellcorp.done ]]; then
				cp /usr/share/fly-debian/simpleaf/pellcorp.done.software "$home/pellcorp.done"
			fi
		fi
		install_unit /usr/share/fly-debian/simpleaf/klipper.service \
			/etc/systemd/system/klipper.service
		install_unit /usr/share/fly-debian/simpleaf/moonraker.service \
			/etc/systemd/system/moonraker.service
		install_unit /usr/share/fly-debian/simpleaf/crowsnest.service \
			/etc/systemd/system/crowsnest.service
		systemctl daemon-reload
		systemctl enable klipper.service moonraker.service nginx.service 2>/dev/null || true
		# Do not start klipper until the user runs the printer/probe installer.
		chown -R "$user:$user" "$home"
		log "bound Simple-AF tree for $user"
		;;
	kiauh)
		bind_tree "$OPT_KIAUH"
		mkdir -p "$home/printer_data/config" "$home/printer_data/logs" "$home/printer_data/gcodes"
		install_unit /usr/share/fly-debian/kiauh/klipper.service \
			/etc/systemd/system/klipper.service
		install_unit /usr/share/fly-debian/kiauh/moonraker.service \
			/etc/systemd/system/moonraker.service
		systemctl daemon-reload
		# Leave units disabled until KIAUH enables them.
		chown -R "$user:$user" "$home"
		log "bound KIAUH tree for $user"
		;;
	*)
		log "unknown flavor '$flavor'; nothing to bind"
		exit 0
		;;
esac

date -u +%Y-%m-%dT%H:%M:%SZ >"$MARKER"
chmod 644 "$MARKER"
exit 0
