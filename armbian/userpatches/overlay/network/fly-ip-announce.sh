#!/bin/bash
# Announce wlan0 IPv4 on serial/HDMI consoles and /etc/issue.d.
# Never print SSIDs or passwords.
set -euo pipefail

IFACE=${FLY_IP_IFACE:-wlan0}
ISSUE_DIR=/etc/issue.d
ISSUE=$ISSUE_DIR/90-fly-ip.issue
TRIES=${FLY_IP_TRIES:-30}
SLEEP_S=${FLY_IP_SLEEP:-2}

get_ip() {
	ip -4 -o addr show dev "$IFACE" scope global 2>/dev/null \
		| awk '{print $4}' | cut -d/ -f1 | head -n1
}

announce() {
	local line=$1
	# Prefer consoles humans watch; ignore write errors (no HDMI, busy VT).
	# Skip tty1 when GrumpyScreen owns HDMI — console text corrupts the UI.
	local targets=(/dev/ttyS0 /dev/console)
	if ! systemctl is-enabled --quiet grumpyscreen.service 2>/dev/null \
		&& ! systemctl is-active --quiet grumpyscreen.service 2>/dev/null; then
		targets+=(/dev/tty1)
	fi
	for t in "${targets[@]}"; do
		if [[ -c $t && -w $t ]]; then
			printf '\n%s\n\n' "$line" >"$t" 2>/dev/null || true
		fi
	done
	mkdir -p "$ISSUE_DIR"
	# Trailing blank line keeps agetty issue layout readable.
	printf '%s\n\n' "$line" >"$ISSUE"
	chmod 0644 "$ISSUE" 2>/dev/null || true
}

ip_addr=""
for _ in $(seq 1 "$TRIES"); do
	ip_addr=$(get_ip || true)
	if [[ -n $ip_addr ]]; then
		break
	fi
	sleep "$SLEEP_S"
done

if [[ -n $ip_addr ]]; then
	announce "fly-lite: $IFACE $ip_addr"
	echo "fly-ip-announce: $IFACE $ip_addr"
else
	announce "fly-lite: $IFACE has no IPv4 yet"
	echo "fly-ip-announce: $IFACE has no IPv4 yet"
	exit 1
fi
