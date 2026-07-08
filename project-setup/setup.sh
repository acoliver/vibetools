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

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <rust|typescript|python> [target-dir] [extra-args...]"
  echo ""
  echo "Available languages:"
  for lang_dir in "$SCRIPT_DIR"/*/; do
    lang=$(basename "$lang_dir")
    if [[ -f "$lang_dir/init.sh" ]]; then
      echo "  $lang"
    fi
  done
  exit 1
fi

LANG_NAME="$1"
shift

LANG_DIR="$SCRIPT_DIR/$LANG_NAME"

if [[ ! -d "$LANG_DIR" ]]; then
  echo "Error: unknown language '$LANG_NAME'"
  echo "Available languages: rust, typescript, python"
  exit 1
fi

if [[ ! -f "$LANG_DIR/init.sh" ]]; then
  echo "Error: no init.sh found for '$LANG_NAME'"
  exit 1
fi

exec "$LANG_DIR/init.sh" "$@"
