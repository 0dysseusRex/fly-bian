#!/bin/sh
# Park the RTL8189FS second virtual iface so only wlan0 gets DHCP.
# Called from load-8189fs and fly-apply-fly-net.
set -eu

if [ ! -d /sys/class/net/wlan1 ]; then
	exit 0
fi

ip addr flush dev wlan1 2>/dev/null || true
ip link set wlan1 down 2>/dev/null || true

# Prefer persistent udev rule when present; otherwise leave the iface down.
if [ -d /etc/systemd/network ]; then
	# Stop systemd-networkd from configuring wlan1 on this boot.
	mkdir -p /run/systemd/network
	cat >/run/systemd/network/10-fly-disable-wlan1.network <<'EOF'
[Match]
Name=wlan1

[Link]
ActivationPolicy=down
Unmanaged=yes
EOF
	if command -v networkctl >/dev/null 2>&1; then
		networkctl reload 2>/dev/null || true
		networkctl reconfigure wlan1 2>/dev/null || true
	fi
fi

exit 0
