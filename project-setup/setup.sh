#!/usr/bin/env bash
#
# setup.sh — universal launcher for language-specific project setup.
# Delegates to the per-language init.sh installer.
#
# Usage:
#   setup.sh <language> [target-dir] [extra-args...]
#
#   language   : rust | typescript | python
#   target-dir : project root (default: current directory)
#
# Examples:
#   setup.sh rust .
#   setup.sh typescript ./my-app
#   setup.sh python . my_package
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Discover available languages dynamically (shared by usage + error paths).
list_languages() {
  local found=0
  for lang_dir in "$SCRIPT_DIR"/*/; do
    if [[ -f "${lang_dir}init.sh" ]]; then
      echo "  $(basename "$lang_dir")"
      found=1
    fi
  done
  if [[ $found -eq 0 ]]; then
    echo "  (none found — no language directories with init.sh)"
  fi
}

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <language> [target-dir] [extra-args...]"
  echo ""
  echo "Available languages:"
  list_languages
  exit 1
fi

LANG_NAME="$1"
shift

# Reject path separators / traversal attempts to prevent exec of scripts
# outside the intended language directories.
if [[ "$LANG_NAME" == */* || "$LANG_NAME" == *..* ]]; then
  echo "Error: invalid language name '$LANG_NAME' (must not contain '/' or '..')" >&2
  exit 1
fi

LANG_DIR="$SCRIPT_DIR/$LANG_NAME"

if [[ ! -d "$LANG_DIR" ]] || [[ ! -f "$LANG_DIR/init.sh" ]]; then
  echo "Error: unknown language '$LANG_NAME'" >&2
  echo "Available languages:"
  list_languages >&2
  exit 1
fi

exec "$LANG_DIR/init.sh" "$@"
