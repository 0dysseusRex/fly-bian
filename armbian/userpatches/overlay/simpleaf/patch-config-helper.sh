#!/bin/bash
# Harden pellcorp config-helper.py against ConfigUpdater crashes on ARMv7
# when deleting missing/odd section entries (seen as exit 139 / SIGSEGV).
set -euo pipefail

target=${1:-}
[[ -n $target && -f $target ]] || {
	echo "patch-config-helper: missing target" >&2
	exit 1
}

python3 - "$target" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text()
old = '''def remove_section_value(updater, section_name, key):
    if updater.has_section(section_name):
        section = updater.get_section(section_name, None)
        if section:
            current_value = section.get(key, None)
            if current_value:
                del section[key]
                return True
    return False
'''
new = '''def remove_section_value(updater, section_name, key):
    # Fly-bian: ConfigUpdater del can SIGSEGV on armhf with some option types.
    try:
        if not updater.has_section(section_name):
            return False
        section = updater.get_section(section_name, None)
        if not section or key not in section:
            return False
        del section[key]
        return True
    except Exception as exc:
        print(f"WARN: remove-section-entry {section_name}/{key}: {exc}", file=sys.stderr)
        return False
'''
if old not in text:
    if 'Fly-bian: ConfigUpdater del can SIGSEGV' in text:
        print(f"patch-config-helper: already patched {path}")
        raise SystemExit(0)
    raise SystemExit(f"patch-config-helper: remove_section_value not found in {path}")
path.write_text(text.replace(old, new, 1))
print(f"patch-config-helper: patched {path}")
PY
