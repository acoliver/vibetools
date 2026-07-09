#!/usr/bin/env bash
#
# Installs all skills from this directory into ~/.llxprt/skills/ (user-global)
# or a target directory. Each skill is a subdirectory containing a SKILL.md.
#
# Usage:
#   skills/install.sh                    # install to ~/.llxprt/skills/
#   skills/install.sh /path/to/project   # install to /path/to/project/.llxprt/skills/
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FINISHED_OK=0

trap 'if [ "$FINISHED_OK" -ne 1 ]; then
  echo "ERROR: install.sh failed unexpectedly." >&2
fi' EXIT

# Resolve target directory
if [ "$#" -ge 1 ]; then
  TARGET_BASE="$1/.llxprt/skills"
else
  TARGET_BASE="$HOME/.llxprt/skills"
fi

mkdir -p "$TARGET_BASE"

# Find all skill directories (subdirs containing SKILL.md)
installed=0
for skill_dir in "$SCRIPT_DIR"/*/; do
  [ -f "$skill_dir/SKILL.md" ] || continue
  skill_name="$(basename "$skill_dir")"
  dest="$TARGET_BASE/$skill_name"

  # Backup existing skill
  if [ -d "$dest" ]; then
    backup="${dest}.bak.$(date +%Y%m%d%H%M%S).$$"
    echo "    WARNING: $skill_name already installed — backed up to $(basename "$backup")"
    mv "$dest" "$backup"
  fi

  cp -r "$skill_dir" "$dest"
  echo "    installed: $skill_name -> $dest"
  installed=$((installed + 1))
done

echo ""
if [ "$installed" -gt 0 ]; then
  echo "==> Installed $installed skill(s) to $TARGET_BASE"
else
  echo "==> No skills found to install."
fi

FINISHED_OK=1
