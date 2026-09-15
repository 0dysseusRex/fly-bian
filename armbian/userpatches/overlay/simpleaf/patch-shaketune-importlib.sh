#!/bin/bash
# Fix Klippain Shake&Tune importlib.util AttributeError under Klipper connect.
# Upstream does `import importlib` then `importlib.util.find_spec(...)`; in the
# Klipper load path that can fail with:
#   AttributeError: module 'importlib' has no attribute 'util'
#   Internal error during connect: module 'importlib' has no attribute 'util'
set -euo pipefail

target=${1:-}
[[ -n $target && -f $target ]] || {
	echo "patch-shaketune-importlib: missing target (path to shaketune.py)" >&2
	exit 1
}

python3 - "$target" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text()
marker = "Fly-bian: importlib.util"
if marker in text:
    print(f"patch-shaketune-importlib: already patched {path}")
    raise SystemExit(0)

old_import = "import importlib\n"
old_line = (
    "        self.IN_DANGER = importlib.util.find_spec('extras.danger_options') is not None\n"
)
new_import = "import importlib.util\n"
new_line = (
    "        # Fly-bian: importlib.util must be imported explicitly under Klipper.\n"
    "        try:\n"
    "            self.IN_DANGER = importlib.util.find_spec('extras.danger_options') is not None\n"
    "        except Exception:\n"
    "            self.IN_DANGER = False\n"
)

if old_import not in text and "import importlib.util" not in text:
    raise SystemExit(f"patch-shaketune-importlib: import line not found in {path}")
if old_line not in text:
    raise SystemExit(f"patch-shaketune-importlib: IN_DANGER line not found in {path}")

if old_import in text:
    text = text.replace(old_import, new_import, 1)
text = text.replace(old_line, new_line, 1)
path.write_text(text)
print(f"patch-shaketune-importlib: patched {path}")
PY
