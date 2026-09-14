#!/bin/bash
# Soften pellcorp installer cleanup_probe so a config-helper failure removing
# stepper_z keys cannot abort the whole install (exit 139 / SIGSEGV).
set -euo pipefail

target=${1:-}
[[ -n $target && -f $target ]] || {
	echo "patch-installer-cleanup: missing target" >&2
	exit 1
}

python3 - "$target" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
text = path.read_text()
orig = text

# Do not abort install if remove-section-entry crashes or no-ops.
text, n1 = re.subn(
    r'(\$CONFIG_HELPER --remove-section-entry "stepper_z" "homing_retract_dist") \|\| exit \$\?',
    r'\1 || true',
    text,
)
text, n2 = re.subn(
    r'(\$CONFIG_HELPER --remove-section-entry "stepper_z" "position_endstop") \|\| exit \$\?',
    r'\1 || true',
    text,
)

if text == orig:
    if '|| true' in text and 'homing_retract_dist' in text:
        print(f"patch-installer-cleanup: already patched {path}")
        raise SystemExit(0)
    raise SystemExit(f"patch-installer-cleanup: targets not found in {path}")

path.write_text(text)
print(f"patch-installer-cleanup: patched {path} (homing={n1} endstop={n2})")
PY
