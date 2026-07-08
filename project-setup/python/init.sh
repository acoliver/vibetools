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
TARGET="$(cd "$TARGET" && pwd)"
PACKAGE="${2:-$(basename "$TARGET")}"

echo "==> Installing Python project-setup into: $TARGET"
echo "    Package name: $PACKAGE"

PYPROJECT="$TARGET/pyproject.toml"

if [[ ! -f "$PYPROJECT" ]]; then
  # No pyproject.toml — copy the full template and substitute the package name.
  sed "s/YOUR_PACKAGE/$PACKAGE/g" "$SCRIPT_DIR/pyproject.toml" > "$PYPROJECT"
  echo "    created pyproject.toml from template"
else
  # pyproject.toml exists — write the quality sections to a separate file for
  # manual merge (TOML table merging can't be done safely with sed).
  MERGE="$TARGET/project-setup-quality.toml"
  sed "s/YOUR_PACKAGE/$PACKAGE/g" "$SCRIPT_DIR/pyproject.toml" > "$MERGE"
  echo "    pyproject.toml already exists."
  echo "    Quality sections written to: $MERGE"
  echo "    Merge the [tool.*] tables and [dependency-groups] into your pyproject.toml,"
  echo "    then delete $MERGE."
fi

echo ""
echo "==> Done. Next steps:"
echo "    1. Install dev tools: pip install -e '.[dev]' or uv sync --group dev"
echo "    2. Run: ruff check ."
echo "    3. Run: mypy src tests"
echo "    4. Run: pytest --cov"
