#!/usr/bin/env bash
set -euo pipefail

MAP_FILE=".file-organizer-map.json"

usage() {
  cat <<EOF
Usage: $(basename "$0") <command> <target-dir>

Commands:
  save     <dir>   Read rename map from stdin (JSON) and save to <dir>/$MAP_FILE
  show     <dir>   Print the current rollback map
  rollback <dir>   Undo all renames/moves recorded in the map
  clear    <dir>   Delete the rollback map
EOF
  exit 1
}

[[ $# -lt 2 ]] && usage

CMD="$1"
TARGET_DIR="$2"
MAP_PATH="$TARGET_DIR/$MAP_FILE"

case "$CMD" in
  save)
    # Reads JSON from stdin: [{"from":"old/path","to":"new/path"}, ...]
    cat > "$MAP_PATH"
    echo "Saved rollback map to $MAP_PATH"
    ;;

  show)
    if [[ ! -f "$MAP_PATH" ]]; then
      echo "No rollback map found at $MAP_PATH"
      exit 1
    fi
    cat "$MAP_PATH"
    ;;

  rollback)
    if [[ ! -f "$MAP_PATH" ]]; then
      echo "No rollback map found at $MAP_PATH"
      exit 1
    fi

    # Parse JSON array and reverse each operation (last-first for correct ordering)
    entries=$(python3 -c "
import json, sys
with open('$MAP_PATH') as f:
    ops = json.load(f)
for op in reversed(ops):
    print(op['to'] + '\t' + op['from'])
")

    errors=0
    count=0
    while IFS=$'\t' read -r src dst; do
      if [[ -e "$src" ]]; then
        mkdir -p "$(dirname "$dst")"
        mv -- "$src" "$dst"
        echo "  ✓ $src → $dst"
        ((count++))
      else
        echo "  ✗ Not found: $src"
        ((errors++))
      fi
    done <<< "$entries"

    echo ""
    echo "Rollback complete: $count restored, $errors errors"

    # Clean up empty _unknown directory if it exists
    [[ -d "$TARGET_DIR/_unknown" ]] && rmdir --ignore-fail-on-non-empty "$TARGET_DIR/_unknown" 2>/dev/null || true
    ;;

  clear)
    if [[ -f "$MAP_PATH" ]]; then
      rm "$MAP_PATH"
      echo "Cleared rollback map at $MAP_PATH"
    else
      echo "No rollback map to clear."
    fi
    ;;

  *)
    usage
    ;;
esac
