#!/usr/bin/env bash
# Install script for explain-diff-skill (Hermes Agent skills)
# Usage (macOS / Linux):
#   curl -fsSL https://raw.githubusercontent.com/CheolyongKim/explain-diff-skill/main/install.sh | bash
#
# Downloads the `skills/` files directly from GitHub (git tree API + raw URLs)
# and writes them into the Hermes Agent skills folder. No archive extraction,
# so it works without unzip. Only writes inside the Hermes skills folder.

set -euo pipefail

REPO="CheolyongKim/explain-diff-skill"
BRANCH="main"
SKILLS_DIR="skills"

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
  echo "${XDG_DATA_HOME:-$HOME/.local/share}/hermes/skills"
}

SKILLS_TARGET="$(find_hermes_skills)"
mkdir -p "$SKILLS_TARGET"

echo "Resolving file tree for $REPO@$BRANCH ..."
API="https://api.github.com/repos/$REPO/git/trees/$BRANCH?recursive=1"
# List blob paths under skills/
PATHS="$(curl -fsSL -H 'User-Agent: explain-diff-installer' "$API" \
  | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{const j=JSON.parse(s);console.log(j.tree.filter(x=>x.type==="blob"&&x.path.startsWith("skills/")).map(x=>x.path).join("\n"))})')"

if [ -z "$PATHS" ]; then
  echo "error: no files found under $SKILLS_DIR/ in the repo tree" >&2
  exit 1
fi

COPIED=""
while IFS= read -r p; do
  [ -z "$p" ] && continue
  url="https://raw.githubusercontent.com/$REPO/$BRANCH/$p"
  dest="$SKILLS_TARGET/$p"
  mkdir -p "$(dirname "$dest")"
  curl -fsSL "$url" > "$dest"
  skill="$(echo "$p" | cut -d/ -f2)"
  case "$COPIED" in *"$skill"*) ;; *) COPIED="$COPIED $skill" ;; esac
done <<< "$PATHS"

echo
echo "explain-diff-skill installed."
echo "Skills folder: $SKILLS_TARGET"
for c in $COPIED; do echo "  - $c"; done
echo
echo "Restart Hermes Agent (or run /skills) to load the new skills."
