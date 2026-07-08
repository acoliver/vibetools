#!/usr/bin/env bash
#
# init.sh — install the canonical Rust lint/complexity/format setup into a
# target Rust project. Copies clippy.toml, .rustfmt.toml, .cargo/config.toml
# and merges the [lints] + [profile] sections into Cargo.toml.
#
# Usage:
#   ./init.sh [target-dir]    # default: current directory
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${1:-.}"
TARGET="$(cd "$TARGET" && pwd)"

echo "==> Installing Rust project-setup into: $TARGET"

# --- Copy standalone config files (overwrite if present) ---
for f in clippy.toml .rustfmt.toml; do
  cp "$SCRIPT_DIR/$f" "$TARGET/$f"
  echo "    copied $f"
done

mkdir -p "$TARGET/.cargo"
cp "$SCRIPT_DIR/.cargo/config.toml" "$TARGET/.cargo/config.toml"
echo "    copied .cargo/config.toml"

# --- Merge [lints] + [profile] sections into Cargo.toml ---
CARGO="$TARGET/Cargo.toml"

if [[ ! -f "$CARGO" ]]; then
  echo "    No Cargo.toml found — creating a minimal template."
  echo "    (Edit the crate name and add your dependencies.)"
  cp "$SCRIPT_DIR/lints.snippet.toml" "$CARGO"
  # Prepend a minimal [package] header
  {
    echo '[package]'
    echo 'name = "CHANGE_ME"'
    echo 'version = "0.1.0"'
    echo 'edition = "2021"'
    echo ''
    echo '[dependencies]'
    echo ''
  } | cat - "$CARGO" > "$CARGO.tmp" && mv "$CARGO.tmp" "$CARGO"
  echo "    created Cargo.toml (minimal template)"
else
  if grep -q '\[lints.rust\]' "$CARGO"; then
    echo "    WARNING: Cargo.toml already has a [lints] section."
    echo "    Review $SCRIPT_DIR/lints.snippet.toml and merge manually."
  else
    # Append lint + profile sections (TOML allows tables at the end)
    {
      echo ""
      echo "# --- Canonical lint policy from vibetools project-setup/rust ---"
      sed -n '/^\[lints\.rust\]/,$p' "$SCRIPT_DIR/lints.snippet.toml"
    } >> "$CARGO"
    echo "    merged [lints] + [profile] sections into Cargo.toml"
  fi
fi

echo ""
echo "==> Done. Next steps:"
echo "    1. Set 'edition' in .rustfmt.toml to match your Cargo.toml."
echo "    2. Run: cargo clippy --all-targets -- -D warnings"
echo "    3. Run: cargo fmt --check"
