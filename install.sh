#!/usr/bin/env bash
# Install script for explain-diff-skill (Hermes Agent skills)
# Usage (macOS / Linux):
#   curl -fsSL https://raw.githubusercontent.com/CheolyongKim/explain-diff-skill/main/install.sh | bash
#
# Copies the `skills/` directory from the GitHub repo into the Hermes Agent
# skills folder. It only writes inside the Hermes skills folder.

set -euo pipefail

REPO="CheolyongKim/explain-diff-skill"
BRANCH="main"
SKILLS_DIR="skills"

# 1) Locate the Hermes skills folder.
find_hermes_skills() {
  if [ -n "${HERMES_SKILLS_DIR:-}" ] && [ -d "$HERMES_SKILLS_DIR" ]; then
    echo "$HERMES_SKILLS_DIR"; return
  fi
  local candidates=(
    "$HOME/Library/Application Support/hermes/skills"   # macOS
    "${XDG_DATA_HOME:-$HOME/.local/share}/hermes/skills" # Linux (XDG)
    "$HOME/.hermes/skills"
  )
  for c in "${candidates[@]}"; do
    if [ -d "$c" ]; then echo "$c"; return; fi
  done
  # Default to XDG/Local path even if not present yet.
  echo "${XDG_DATA_HOME:-$HOME/.local/share}/hermes/skills"
}

SKILLS_TARGET="$(find_hermes_skills)"
mkdir -p "$SKILLS_TARGET"

TMP="$(mktemp -d)"
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

URL="https://github.com/$REPO/archive/refs/heads/$BRANCH.zip"

echo "Downloading $REPO@$BRANCH ..."
if command -v curl >/dev/null 2>&1; then
  curl -fsSL "$URL" -o "$TMP/repo.zip"
elif command -v wget >/dev/null 2>&1; then
  wget -qO "$TMP/repo.zip" "$URL"
else
  echo "error: need curl or wget to download the archive" >&2; exit 1
fi

# Extract.
if command -v unzip >/dev/null 2>&1; then
  unzip -q "$TMP/repo.zip" -d "$TMP/extracted"
else
  echo "error: 'unzip' is required (install it, or use the npm install method)" >&2; exit 1
fi

REPO_ROOT="$(find "$TMP/extracted" -maxdepth 1 -type d -name "${REPO##*/}-*" | head -1)"
SRC="$REPO_ROOT/$SKILLS_DIR"
[ -d "$SRC" ] || { echo "error: could not find $SKILLS_DIR/ in the archive" >&2; exit 1; }

COPIED=()
for d in "$SRC"/*/; do
  name="$(basename "$d")"
  cp -R "$d" "$SKILLS_TARGET/$name"
  COPIED+=("$name")
done

echo
echo "explain-diff-skill installed."
echo "Skills folder: $SKILLS_TARGET"
for c in "${COPIED[@]}"; do echo "  - $c"; done
echo
echo "Restart Hermes Agent (or run /skills) to load the new skills."
