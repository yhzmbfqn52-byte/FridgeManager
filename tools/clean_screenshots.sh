#!/usr/bin/env bash
# Delete PNG screenshots from project Screenshots folders.
set -euo pipefail
cd "$(dirname "$0")"
ROOT="$(cd .. && pwd)/FridgeManager"
FOLDERS=("${ROOT}/Screenshots" "${ROOT}/FridgeManager/Screenshots")
removed=()
for d in "${FOLDERS[@]}"; do
  if [ -d "$d" ]; then
    shopt -s nullglob
    for f in "$d"/*.png; do
      echo "Removing $f"
      rm -f "$f"
      removed+=("$f")
    done
    shopt -u nullglob
  fi
done
if [ ${#removed[@]} -eq 0 ]; then
  echo "No PNG screenshots found to remove."
else
  echo "Removed ${#removed[@]} files."
fi
