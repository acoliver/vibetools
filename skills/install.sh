#!/usr/bin/env bash
#
# Installs all skills from this directory into the platform-specific user
# skills directory, or a target project. Each skill is a subdirectory
# containing a SKILL.md.
#
# Modern llxprt-code uses platform-specific paths (via envPaths):
#   macOS:   ~/Library/Preferences/llxprt-code/skills/
#   Linux:   ~/.config/llxprt-code/skills/
#   Windows: %APPDATA%\llxprt-code\Config\skills\
#
# Override with $LLXPRT_CONFIG_HOME. The legacy ~/.llxprt/skills/ path is
# deprecated but still works as a fallback.
#
# Usage:
#   skills/install.sh                    # install to user skills dir
#   skills/install.sh /path/to/project   # install to project's .llxprt/skills/
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FINISHED_OK=0

trap 'if [ "$FINISHED_OK" -ne 1 ]; then
  echo "ERROR: install.sh failed unexpectedly." >&2
fi' EXIT

# Resolve the platform-specific config directory for user skills.
resolve_user_skills_dir() {
  # Honor LLXPRT_CONFIG_HOME override (highest priority, matches llxprt-code).
  if [ -n "${LLXPRT_CONFIG_HOME:-}" ]; then
    echo "$LLXPRT_CONFIG_HOME/skills"
    return
  fi

  local os_name
  os_name="$(uname -s)"
  case "$os_name" in
    Darwin)
      echo "$HOME/Library/Preferences/llxprt-code/skills"
      ;;
    Linux)
      # Respect XDG_CONFIG_HOME if set.
      echo "${XDG_CONFIG_HOME:-$HOME/.config}/llxprt-code/skills"
      ;;
    MINGW*|MSYS*|CYGWIN*)
      echo "$APPDATA/llxprt-code/Config/skills"
      ;;
    *)
      # Fallback to legacy path.
      echo "$HOME/.llxprt/skills"
      ;;
  esac
}

# Resolve target directory
if [ "$#" -ge 1 ]; then
  TARGET_BASE="$1/.llxprt/skills"
else
  TARGET_BASE="$(resolve_user_skills_dir)"
fi

mkdir -p "$TARGET_BASE"

# Find all skill directories (subdirs containing SKILL.md)
installed=0
for skill_dir in "$SCRIPT_DIR"/*/; do
  [ -f "$skill_dir/SKILL.md" ] || continue
  skill_name="$(basename "$skill_dir")"
  dest="$TARGET_BASE/$skill_name"

  # Stage the new copy in a temp location first, then swap atomically.
  # This avoids destroying the existing install if the copy fails.
  staging="${dest}.new.$$"
  cp -r "$skill_dir" "$staging"

  # Backup existing skill, then swap the staged copy into place.
  if [ -d "$dest" ]; then
    backup="${dest}.bak.$(date +%Y%m%d%H%M%S).$$"
    echo "    WARNING: $skill_name already installed — backed up to $(basename "$backup")"
    mv "$dest" "$backup"
  fi

  mv "$staging" "$dest"
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
