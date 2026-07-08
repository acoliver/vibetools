#!/usr/bin/env bash
#
# init.sh — install the canonical Python lint/type/test config into a target
# Python project. Copies the pyproject.toml quality sections, substituting the
# package name placeholder.
#
# Usage:
#   ./init.sh [target-dir] [package-name]
#   # target-dir defaults to current directory
#   # package-name defaults to the basename of target-dir
#
set -euo pipefail

FINISHED_OK=0
TMP_FILE=""
warn_partial() {
  if [[ $FINISHED_OK -eq 0 ]]; then
    echo "Error during setup — partial state may remain in target." >&2
    # Clean up orphaned temp file from a failed/interrupted run.
    [[ -n "$TMP_FILE" && -f "$TMP_FILE" ]] && rm -f "$TMP_FILE"
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
PACKAGE="${2:-$(basename "$TARGET")}"

# Normalize hyphens to underscores for Python import compatibility
# (e.g. "my-pkg" → "my_pkg") — hyphens are invalid in Python identifiers.
PACKAGE_NORMALIZED="${PACKAGE//-/_}"

if [[ ! "$PACKAGE_NORMALIZED" =~ ^[a-z][_a-z0-9]*$ ]]; then
  FINISHED_OK=1
  echo "Error: invalid package name '$PACKAGE'." >&2
  echo "       Must be lowercase ASCII letters/digits/hyphens/underscores, starting with a letter." >&2
  exit 1
fi

echo "==> Installing Python project-setup into: $TARGET"
echo "    Package name: $PACKAGE_NORMALIZED"

# PACKAGE_NORMALIZED is validated against ^[a-z][_a-z0-9]*$ (no sed
# metacharacters possible), so it can be substituted directly.
render_template() {
  sed "s|YOUR_PACKAGE|$PACKAGE_NORMALIZED|g" "$SCRIPT_DIR/pyproject.toml"
}

PYPROJECT="$TARGET/pyproject.toml"

if [[ ! -f "$PYPROJECT" ]]; then
  # Atomic write: render to a temp file, then move into place.
  TMP_FILE="$(mktemp "$TARGET/.pyproject.tmp.XXXXXX")"
  render_template > "$TMP_FILE"
  mv "$TMP_FILE" "$PYPROJECT"
  TMP_FILE=""   # ownership transferred; trap must not clean it up
  echo "    created pyproject.toml from template"
else
  MERGE="$TARGET/project-setup-quality.toml"
  if [[ -e "$MERGE" ]]; then
    FINISHED_OK=1
    echo "Error: '$MERGE' already exists. Remove it and re-run." >&2
    exit 1
  fi
  render_template > "$MERGE"
  echo "    pyproject.toml already exists."
  echo "    Quality sections written to: $MERGE"
  echo "    Merge the [tool.*] tables and [dependency-groups] into your pyproject.toml,"
  echo "    then delete $MERGE."
fi

FINISHED_OK=1
echo ""
echo "==> Done. Next steps:"
echo "    1. Create your package source directories (e.g. src/ and tests/)."
echo "    2. Install dev tools: pip install -e '.[dev]' or uv sync --group dev"
echo "    3. Run: ruff check ."
echo "    4. Run: mypy src tests scripts"
echo "    5. Run: pytest --cov"

# --- Optionally copy CI gate ---
CI_SRC="$(cd "$SCRIPT_DIR/../.." && pwd)/ci-gates/python/ci.yml"
CI_DEST="$TARGET/.github/workflows/ci.yml"
if [[ -f "$CI_SRC" ]] && [[ ! -e "$CI_DEST" ]]; then
  mkdir -p "$TARGET/.github/workflows"
  cp "$CI_SRC" "$CI_DEST"
  echo "    copied CI gate to .github/workflows/ci.yml"
elif [[ -e "$CI_DEST" ]]; then
  echo "    (CI gate already exists at .github/workflows/ci.yml — skipped)"
fi
