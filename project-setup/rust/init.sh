#!/usr/bin/env bash
#
# init.sh — install the canonical Rust lint/complexity/format setup into a
# target Rust project. Copies clippy.toml, .rustfmt.toml, .cargo/config.toml
# and merges the [lints] sections into Cargo.toml.
#
# Usage:
#   ./init.sh [target-dir]    # default: current directory
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${1:-.}"

if [[ ! -d "$TARGET" ]]; then
  echo "Error: target directory '$TARGET' does not exist." >&2
  exit 1
fi
TARGET="$(cd "$TARGET" && pwd)"

echo "==> Installing Rust project-setup into: $TARGET"

# --- Copy standalone config files (backup if already present) ---
for f in clippy.toml .rustfmt.toml; do
  if [[ -f "$TARGET/$f" ]]; then
    cp "$TARGET/$f" "$TARGET/$f.bak"
    echo "    WARNING: $f already existed — backed up to $f.bak"
  fi
  cp "$SCRIPT_DIR/$f" "$TARGET/$f"
  echo "    copied $f"
done

mkdir -p "$TARGET/.cargo"
if [[ -f "$TARGET/.cargo/config.toml" ]]; then
  cp "$TARGET/.cargo/config.toml" "$TARGET/.cargo/config.toml.bak"
  echo "    WARNING: .cargo/config.toml already existed — backed up to config.toml.bak"
fi
cp "$SCRIPT_DIR/.cargo/config.toml" "$TARGET/.cargo/config.toml"
echo "    copied .cargo/config.toml"

# --- Merge [lints] sections into Cargo.toml ---
# Only the [lints.rust] and [lints.clippy] tables are appended. Profile
# settings live in .cargo/config.toml (global), so there is no risk of
# duplicate [profile.*] tables.
CARGO="$TARGET/Cargo.toml"
LINT_BODY="$(awk '/^\[lints\.rust\]/{found=1} found{print}' "$SCRIPT_DIR/lints.snippet.toml")"

if [[ ! -f "$CARGO" ]]; then
  echo "    No Cargo.toml found — creating a minimal template."
  echo "    (Edit the crate name and add your dependencies.)"
  {
    echo '[package]'
    echo 'name = "CHANGE_ME"'
    echo 'version = "0.1.0"'
    echo 'edition = "2021"'
    echo ''
    echo '[dependencies]'
    echo ''
    echo "# --- Canonical lint policy from vibetools project-setup/rust ---"
    printf '%s\n' "$LINT_BODY"
  } > "$CARGO"
  echo "    created Cargo.toml (minimal template)"
else
  if grep -qE '\[lints\.(rust|clippy)\]' "$CARGO"; then
    echo "    WARNING: Cargo.toml already has a [lints] section."
    echo "    Review $SCRIPT_DIR/lints.snippet.toml and merge manually."
  else
    {
      echo ""
      echo "# --- Canonical lint policy from vibetools project-setup/rust ---"
      printf '%s\n' "$LINT_BODY"
    } >> "$CARGO"
    echo "    merged [lints] sections into Cargo.toml"
  fi
fi

echo ""
echo "==> Done. Next steps:"
echo "    1. Set 'edition' in .rustfmt.toml to match your Cargo.toml."
echo "    2. Run: cargo clippy --all-targets -- -D warnings"
echo "    3. Run: cargo fmt --check"
