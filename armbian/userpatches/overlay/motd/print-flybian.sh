#!/bin/bash
# Fly-bian Project SSH splash. TAAG Breach Blue / TheDraw palette on black
# (#5555FF, #0000AA, #AAAAAA) from patorjk ft=thedraw&fp=true.
set -euo pipefail

ART="${FLYBIAN_ART:-/usr/share/fly-debian/motd/flybian.txt}"
ANSI="${FLYBIAN_ANSI:-/usr/share/fly-debian/motd/flybian.ansi}"

if [[ -s $ANSI ]]; then
	# MOTD is not a tty; always emit color. Client (SSH/PuTTY) interprets it.
	cat "$ANSI"
	printf '\e[0m\n\n\n'
	exit 0
fi

if [[ ! -f $ART ]]; then
	printf '\e[38;2;255;0;0mFly-bian Project\e[0m\n\n\n'
	exit 0
fi

python3 - "$ART" <<'PY'
import sys
from pathlib import Path

RED = "\x1b[38;2;255;0;0m"
BLUE = "\x1b[38;2;0;0;255m"
RESET = "\x1b[0m"
BG = "\x1b[48;2;0;0;0m"
STRIPE = {chr(0x2588), chr(0x2591)}

def paint(text: str) -> str:
	out = []
	for line in text.splitlines():
		parts = [BG]
		cur = None
		for ch in line:
			if ch in STRIPE:
				col = BLUE
			elif ch == " ":
				col = RESET + BG
			else:
				col = RED
			if col != cur:
				parts.append(col)
				cur = col
			parts.append(ch)
		parts.append(RESET)
		out.append("".join(parts))
	return "\n".join(out) + "\n\n\n"

sys.stdout.write(paint(Path(sys.argv[1]).read_text(encoding="utf-8")))
PY
