#!/bin/sh
# 8189fs is not SMP-safe. Boot with maxcpus=1 isolcpus=1-3 irqaffinity=0,
# bring Wi-Fi up on CPU0, then online isolated cores for compute.
#
# First boot is memory-tight (resize + 2 GiB swapfile). Online CPUs only
# after swap is usable when possible, one core at a time, to avoid kernel
# cpumask oopses seen on 6.18.x (__bitmap_clear / irqs disabled).
set -eu

# Prefer having /swapfile active before hotplug (fly-swapfile.service orders us).
if [ -f /swapfile ]; then
	swapon --show 2>/dev/null | grep -q '^/swapfile ' || swapon /swapfile 2>/dev/null || true
fi

online_one() {
	c=$1
	path=/sys/devices/system/cpu/cpu$c/online
	[ -f "$path" ] || return 0
	cur=$(cat "$path" 2>/dev/null || echo 1)
	[ "$cur" = 1 ] && return 0
	# Retry a few times; hotplug can fail under early-boot pressure.
	n=0
	while [ "$n" -lt 5 ]; do
		if echo 1 >"$path" 2>/dev/null; then
			# Confirm and give the scheduler a beat before the next core.
			sleep 1
			cur=$(cat "$path" 2>/dev/null || echo 0)
			[ "$cur" = 1 ] && return 0
		fi
		n=$((n + 1))
		sleep 1
	done
	echo "fly-online-isolated-cpus: WARN could not online cpu$c" >&2
	return 0
}

for c in 1 2 3; do
	online_one "$c"
done

# Marker so affinity tooling can tell hotplug finished this boot.
mkdir -p /run/fly-debian
echo "$(cat /sys/devices/system/cpu/online 2>/dev/null || echo '?')" \
	>/run/fly-debian/cpus-online
