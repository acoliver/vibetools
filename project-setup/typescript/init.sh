#!/usr/bin/env bash
#
# init.sh — install the canonical TypeScript lint/complexity/format setup into
# a target project. Copies eslint.config.js, tsconfig.json, .prettierrc.json
# and shows the devDependencies + scripts to merge into package.json.
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

echo "==> Installing TypeScript project-setup into: $TARGET"

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

for f in eslint.config.js tsconfig.json .prettierrc.json; do
  backup_if_exists "$TARGET/$f"
  cp "$SCRIPT_DIR/$f" "$TARGET/$f"
  echo "    copied $f"
done

PKG="$TARGET/package.json"
if [[ ! -f "$PKG" ]]; then
  echo "    No package.json found — creating a minimal one."
  cat > "$PKG" <<'JSONEOF'
{
  "name": "change-me",
  "version": "0.1.0",
  "type": "module",
  "scripts": {},
  "devDependencies": {}
}
JSONEOF
  echo "    created package.json"
fi

# --- Optionally copy CI gate ---
CI_SRC="$(cd "$SCRIPT_DIR/../.." && pwd)/ci-gates/typescript/ci.yml"
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
echo "    1. Merge devDependencies + scripts from:"
echo "       $SCRIPT_DIR/package.devdeps.json"
echo "       into your package.json, then run: npm install"
echo "    2. For React projects, also install eslint-plugin-react \\"
echo "       eslint-plugin-react-hooks and uncomment the React block in eslint.config.js."
echo "    3. For Vitest, install @vitest/eslint-plugin and uncomment the Vitest lines."
echo "    4. Run: npx eslint . --max-warnings 0"
echo "    5. Run: npx prettier --check ."
echo "    6. Run: npx tsc --noEmit"
