#!/bin/sh
# Popup: page the last API response. q or Esc closes the popup.
set -eu
PATH="/opt/homebrew/bin:$PATH"
file="${XDG_CACHE_HOME:-$HOME/.cache}/herdr-palette/last.json"
if [ ! -f "$file" ]; then
    printf 'no palette output yet\n'
    read -r _ignored
    exit 0
fi
jq -C . "$file" | less -R
