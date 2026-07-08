#!/usr/bin/env bash
#
# init.sh — install the canonical Deno lint/complexity/format setup into a
# target project. Copies deno.json (single config for lint, fmt, test, tasks).
#
# Usage:
#   ./init.sh [target-dir]    # default: current directory
#
set -euo pipefail

FINISHED_OK=0
warn_partial() {
  if [[ $FINISHED_OK -eq 0 ]]; then
    echo "Error during setup — partial state may remain in target." >&2
  fi
}
trap warn_partial EXIT

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${1:-.}"

if [[ ! -d "$TARGET" ]]; then
  FINISHED_OK=1
  echo "Error: target directory '$TARGET' does not exist." >&2
  exit 1
fi
TARGET="$(cd "$TARGET" && pwd)"

echo "==> Installing Deno project-setup into: $TARGET"

# Back up an existing file to a unique .bak path (avoids clobbering a prior backup).
backup_if_exists() {
  local file="$1"
  if [[ -f "$file" ]]; then
    local bak="${file}.bak"
    if [[ -e "$bak" ]]; then
      bak="${file}.bak.$(date +%s).$$"
    fi
    if ! cp "$file" "$bak"; then
      echo "Error: failed to back up '$file' — aborting to prevent data loss." >&2
      exit 1
    fi
    echo "    WARNING: $(basename "$file") already existed — backed up to $(basename "$bak")"
  fi
}

backup_if_exists "$TARGET/deno.json"
if ! cp "$SCRIPT_DIR/deno.json" "$TARGET/deno.json.tmp"; then
  echo "Error: failed to copy deno.json — aborting." >&2
  exit 1
fi
mv "$TARGET/deno.json.tmp" "$TARGET/deno.json"
echo "    copied deno.json"

# --- Optionally copy CI gate ---
CI_SRC="$(cd "$SCRIPT_DIR/../.." && pwd)/ci-gates/deno/ci.yml"
CI_DEST="$TARGET/.github/workflows/ci.yml"
if [[ ! -f "$CI_SRC" ]]; then
  echo "    (CI gate source not found at $CI_SRC — skipped)"
elif [[ -e "$CI_DEST" ]]; then
  echo "    (CI gate already exists at .github/workflows/ci.yml — skipped)"
else
  mkdir -p "$TARGET/.github/workflows"
  if ! cp "$CI_SRC" "$CI_DEST"; then
    echo "Error: failed to copy CI gate — aborting." >&2
    exit 1
  fi
  echo "    copied CI gate to .github/workflows/ci.yml"
fi

FINISHED_OK=1
echo ""
echo "==> Done. Next steps:"
echo "    1. Add dependencies with: deno add <pkg>"
echo "       (or add them to the \"imports\" map in deno.json)"
echo "    2. Run: deno task ci"
echo "       (runs fmt --check + lint + check + test)"
