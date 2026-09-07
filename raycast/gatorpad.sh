#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Open GatorPad
# @raycast.mode silent
# @raycast.packageName Notes
#
# Documentation:
# @raycast.description Open the notes scratchpad in Ghostty
# @raycast.author Yarden
# @raycast.authorURL https://github.com/yarden-zamir

set -euo pipefail

GATORPAD_BIN="$HOME/Github/GatorPad/main/target/release/gatorpad"

if [[ ! -x "$GATORPAD_BIN" ]]; then
    echo "GatorPad release binary not found: $GATORPAD_BIN" >&2
    exit 1
fi

/usr/bin/open -na "/Applications/Ghostty.app" --args \
    --config-default-files=false \
    --font-size=28 \
    --maximize=true \
    --background-opacity=0.9 \
    --background-blur=true \
    --window-save-state=never \
    --macos-titlebar-style=hidden \
    --confirm-close-surface=false \
    -e "$GATORPAD_BIN" \
    --theme dark
