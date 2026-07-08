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

# Back up an existing file to a unique .bak path (avoids clobbering a prior backup).
backup_if_exists() {
  local file="$1"
  if [[ -f "$file" ]]; then
    local bak="${file}.bak"
    if [[ -e "$bak" ]]; then
      bak="${file}.bak.$(date +%s)"
    fi
    cp "$file" "$bak"
    echo "    WARNING: $(basename "$file") already existed — backed up to $(basename "$bak")"
  fi
}

# --- Copy standalone config files (backup if already present) ---
for f in clippy.toml .rustfmt.toml; do
  backup_if_exists "$TARGET/$f"
  cp "$SCRIPT_DIR/$f" "$TARGET/$f"
  echo "    copied $f"
done

mkdir -p "$TARGET/.cargo"
if [[ -f "$TARGET/.cargo/config.toml" ]]; then
  backup_if_exists "$TARGET/.cargo/config.toml"
  cp "$SCRIPT_DIR/.cargo/config.toml" "$TARGET/.cargo/config.toml"
  echo "    copied .cargo/config.toml (existing file was backed up — review the .bak for custom settings to restore)"
else
  cp "$SCRIPT_DIR/.cargo/config.toml" "$TARGET/.cargo/config.toml"
  echo "    copied .cargo/config.toml"
fi

# --- Merge [lints] sections into Cargo.toml ---
CARGO="$TARGET/Cargo.toml"
# Extract from [lints.rust] through the end of all [lints.*] sections.
LINT_BODY="$(awk '/^\[lints\./{found=1} found && /^\[/ && !/^\[lints\./{found=0} found{print}' "$SCRIPT_DIR/lints.snippet.toml")"

if [[ -z "$LINT_BODY" ]] || ! grep -q '^\[lints\.' <<<"$LINT_BODY"; then
  echo "Error: failed to extract [lints.*] sections from lints.snippet.toml." >&2
  exit 1
fi

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
  if grep -qE '^\[lints(\.(rust|clippy))?\]' "$CARGO"; then
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
echo "    1. If your Cargo.toml uses an edition other than 2021, update 'edition' in .rustfmt.toml to match."
echo "    2. Run: cargo clippy --all-targets -- -D warnings"
echo "    3. Run: cargo fmt --check"
