#!/usr/bin/env python3
"""Replace Armbian figlet vendor banner with Fly-bian splash."""
from pathlib import Path
import sys

header = Path(sys.argv[1] if len(sys.argv) > 1 else "/etc/update-motd.d/10-armbian-header")
text = header.read_text(encoding="utf-8")
if "print-flybian.sh" in text:
	sys.exit(0)

start = text.find("# --- Vendor banner ---")
end = text.find("# --- Board name and version line ---")
if start < 0 or end < 0:
	sys.exit("10-armbian-header: vendor banner markers not found")

replacement = """# --- Vendor banner (Fly-bian Project) ---
if [[ -x /usr/share/fly-debian/motd/print-flybian.sh ]]; then
	/usr/share/fly-debian/motd/print-flybian.sh
elif [[ -n "${VENDORCOLOR:-}" ]]; then
	if command -v figlet >/dev/null 2>&1; then
		printf '\\e[38;2;%sm%s\\e[0m\\n' "${VENDORCOLOR}" "$(figlet -f small " ${VENDOR}")"
	else
		printf '\\e[38;2;%sm### %s ###\\e[0m\\n' "${VENDORCOLOR}" "${VENDOR}"
	fi
else
	if command -v figlet >/dev/null 2>&1; then
		printf '\\e[1;91m%s\\e[0m\\n' "$(figlet -f small " ${VENDOR}")"
	else
		printf '\\e[1;91m### %s ###\\e[0m\\n' "${VENDOR}"
	fi
fi

"""

header.write_text(text[:start] + replacement + text[end:], encoding="utf-8")
