#!/bin/sh
# Incremental copy of ~/.claude/projects/-Users-kcw-Github-dotfiles-main/*.jsonl
# to _shared/herdr-agents/transcripts. Skips when the last run is under 5 min old.
set -eu
src="$HOME/.claude/projects/-Users-kcw-Github-dotfiles-main"
dst="$HOME/Github/dotfiles/_shared/herdr-agents/transcripts"
stamp="${HERDR_PLUGIN_STATE_DIR:-/tmp}/last-backup"
if [ -f "$stamp" ] && [ -n "$(find "$stamp" -mmin -5 2>/dev/null)" ]; then exit 0; fi
mkdir -p "$dst" "$(dirname "$stamp")"
rsync -a --include='*.jsonl' --exclude='*' "$src/" "$dst/"
touch "$stamp"
