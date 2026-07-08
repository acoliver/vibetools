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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${1:-.}"

if [[ ! -d "$TARGET" ]]; then
  echo "Error: target directory '$TARGET' does not exist." >&2
  exit 1
fi
TARGET="$(cd "$TARGET" && pwd)"
PACKAGE="${2:-$(basename "$TARGET")}"

# Validate the package name (PEP 508 / PEP 8 conventions).
if [[ ! "$PACKAGE" =~ ^[a-z][_a-z0-9-]*$ ]]; then
  echo "Error: invalid package name '$PACKAGE'." >&2
  echo "       Must be lowercase ASCII letters/digits/hyphens/underscores, starting with a letter." >&2
  exit 1
fi

echo "==> Installing Python project-setup into: $TARGET"
echo "    Package name: $PACKAGE"

# Escape sed metacharacters for the '|' delimiter used in render_template.
escape_pkg() {
  printf '%s\n' "$PACKAGE" | sed 's/[&|\\]/\\&/g'
}
ESCAPED_PKG="$(escape_pkg)"

# Render the template with the package name substituted.
render_template() {
  sed "s|YOUR_PACKAGE|$ESCAPED_PKG|g" "$SCRIPT_DIR/pyproject.toml"
}

PYPROJECT="$TARGET/pyproject.toml"

if [[ ! -f "$PYPROJECT" ]]; then
  # Atomic write: render to a temp file, then move into place.
  TMP_FILE="$(mktemp "$TARGET/.pyproject.tmp.XXXXXX")"
  render_template > "$TMP_FILE"
  mv "$TMP_FILE" "$PYPROJECT"
  echo "    created pyproject.toml from template"
else
  MERGE="$TARGET/project-setup-quality.toml"
  render_template > "$MERGE"
  echo "    pyproject.toml already exists."
  echo "    Quality sections written to: $MERGE"
  echo "    Merge the [tool.*] tables and [dependency-groups] into your pyproject.toml,"
  echo "    then delete $MERGE."
fi

echo ""
echo "==> Done. Next steps:"
echo "    1. Install dev tools: pip install -e '.[dev]' or uv sync --group dev"
echo "    2. Run: ruff check ."
echo "    3. Run: mypy src tests scripts"
echo "    4. Run: pytest --cov"
