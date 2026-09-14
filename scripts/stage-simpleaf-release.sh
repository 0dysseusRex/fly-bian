#!/usr/bin/env bash
# Deprecated wrapper — use stage-flybian-release.sh simpleaf.
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
echo "note: stage-simpleaf-release.sh now delegates to stage-flybian-release.sh" >&2
exec "$root/scripts/stage-flybian-release.sh" simpleaf
