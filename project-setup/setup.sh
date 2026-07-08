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
  local langs=""
  for lang_dir in "$SCRIPT_DIR"/*/; do
    if [[ -f "${lang_dir}init.sh" ]]; then
      langs+="$(basename "$lang_dir")"$'
'
    fi
  done
  if [[ -n "$langs" ]]; then
    printf '%s' "$langs" | sort | sed 's/^/  /'
  else
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

LANG_SEL="$1"
shift

# Reject empty names, path separators, and traversal attempts.
if [[ -z "$LANG_SEL" || "$LANG_SEL" == */* || "$LANG_SEL" == *..* ]]; then
  echo "Error: invalid language name '$LANG_SEL'" >&2
  echo "Must not be empty, contain '/', or contain '..'" >&2
  exit 1
fi

LANG_DIR="$SCRIPT_DIR/$LANG_SEL"

if [[ ! -d "$LANG_DIR" ]] || [[ ! -f "$LANG_DIR/init.sh" ]]; then
  echo "Error: unknown language '$LANG_SEL'" >&2
  echo "Available languages:"
  list_languages >&2
  exit 1
fi

if [[ ! -x "$LANG_DIR/init.sh" ]]; then
  echo "Error: $LANG_SEL/init.sh is not executable." >&2
  exit 1
fi

exec "$LANG_DIR/init.sh" "$@"
