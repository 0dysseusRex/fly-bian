#!/bin/bash
# Announce that multi-user boot finished (serial / HDMI / issue).
set -euo pipefail

MSG=${FLY_BOOT_COMPLETE_MSG:-Boot Complete}

for t in /dev/ttyS0 /dev/console /dev/tty1; do
	if [[ -c $t && -w $t ]]; then
		printf '\n%s\n\n' "$MSG" >"$t" 2>/dev/null || true
	fi
done

mkdir -p /etc/issue.d
printf '%s\n\n' "$MSG" >/etc/issue.d/95-fly-boot-complete.issue
chmod 0644 /etc/issue.d/95-fly-boot-complete.issue 2>/dev/null || true
echo "fly-boot-complete: $MSG"
