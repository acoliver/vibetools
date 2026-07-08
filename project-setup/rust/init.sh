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

echo "==> Installing Rust project-setup into: $TARGET"

# Back up an existing file to a unique .bak path (avoids clobbering a prior
# backup on re-run). Appends PID for sub-second uniqueness.
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

# --- Copy standalone config files (backup if already present) ---
for f in clippy.toml .rustfmt.toml; do
  backup_if_exists "$TARGET/$f"
  cp "$SCRIPT_DIR/$f" "$TARGET/$f"
  echo "    copied $f"
done

mkdir -p "$TARGET/.cargo"
if [[ -f "$TARGET/.cargo/config.toml" ]]; then
  backup_if_exists "$TARGET/.cargo/config.toml"
  echo "    (existing .cargo/config.toml was backed up — review the .bak for custom settings to restore)"
fi
cp "$SCRIPT_DIR/.cargo/config.toml" "$TARGET/.cargo/config.toml"
echo "    copied .cargo/config.toml"

# --- Merge [lints] + [profile] sections into Cargo.toml ---
CARGO="$TARGET/Cargo.toml"
SNIPPET="$SCRIPT_DIR/cargo.snippet.toml"
# Extract [lints.*] and [profile.*] sections from first match to EOF.
LINT_BODY="$(awk '/^\[(lints|profile)\./{found=1} found{print}' "$SNIPPET")"

if [[ -z "$LINT_BODY" ]] || ! grep -qE '^\[(lints|profile)\.' <<<"$LINT_BODY"; then
  echo "Error: failed to extract sections from $SNIPPET — body is empty." >&2
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
    echo "# --- Canonical lint + profile policy from vibetools project-setup/rust ---"
    printf '%s\n' "$LINT_BODY"
  } > "$CARGO"
  echo "    created Cargo.toml (minimal template)"
else
  if grep -qE '^\[(lints|profile)(\.|\s*\])' "$CARGO"; then
    echo "    WARNING: Cargo.toml already has [lints] or [profile] sections."
    echo "    Review $SNIPPET and merge manually."
    FINISHED_OK=1  # standalone files were copied; merge is intentionally manual
  else
    # Ensure the file ends with a newline before appending.
    if [[ -s "$CARGO" ]] && [[ "$(tail -c1 "$CARGO")" != $'
' ]]; then
      echo "" >> "$CARGO"
    fi
    {
      echo "# --- Canonical lint + profile policy from vibetools project-setup/rust ---"
      printf '%s\n' "$LINT_BODY"
    } >> "$CARGO"
    echo "    merged [lints] + [profile] sections into Cargo.toml"
  fi
fi

FINISHED_OK=1
echo ""
echo "==> Done. Next steps:"
echo "    1. If your Cargo.toml uses an edition other than 2021, update 'edition' in .rustfmt.toml to match."
echo "    2. Run: cargo clippy --all-targets -- -D warnings"
echo "    3. Run: cargo fmt --check"

# --- Optionally copy CI gate ---
CI_SRC="$(cd "$SCRIPT_DIR/../.." && pwd)/ci-gates/rust/ci.yml"
CI_DEST="$TARGET/.github/workflows/ci.yml"
if [[ -f "$CI_SRC" ]] && [[ ! -e "$CI_DEST" ]]; then
  mkdir -p "$TARGET/.github/workflows"
  cp "$CI_SRC" "$CI_DEST"
  echo "    copied CI gate to .github/workflows/ci.yml"
elif [[ -e "$CI_DEST" ]]; then
  echo "    (CI gate already exists at .github/workflows/ci.yml — skipped)"
fi
