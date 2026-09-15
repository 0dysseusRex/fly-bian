#!/bin/bash
# Announce that multi-user boot finished (serial / issue).
# Skip HDMI tty1 when GrumpyScreen owns the framebuffer — writing there
# corrupts the UI (vertical bars / mixed journal text).
set -euo pipefail

MSG=${FLY_BOOT_COMPLETE_MSG:-Boot Complete}

targets=(/dev/ttyS0 /dev/console)
if ! systemctl is-enabled --quiet grumpyscreen.service 2>/dev/null \
	&& ! systemctl is-active --quiet grumpyscreen.service 2>/dev/null; then
	targets+=(/dev/tty1)
fi

for t in "${targets[@]}"; do
	if [[ -c $t && -w $t ]]; then
		printf '\n%s\n\n' "$MSG" >"$t" 2>/dev/null || true
	fi
done

mkdir -p /etc/issue.d
printf '%s\n\n' "$MSG" >/etc/issue.d/95-fly-boot-complete.issue
chmod 0644 /etc/issue.d/95-fly-boot-complete.issue 2>/dev/null || true
echo "fly-boot-complete: $MSG"
