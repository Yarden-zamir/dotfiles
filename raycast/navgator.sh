#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Open Navgator
# @raycast.mode silent
# @raycast.packageName Navigation
#
# Documentation:
# @raycast.description Open the project action launcher in Ghostty
# @raycast.author Yarden
# @raycast.authorURL https://github.com/yarden-zamir

set -euo pipefail

NAVGATOR_BIN="$HOME/Github/navgator/main/target/release/navgator"

if [[ ! -x "$NAVGATOR_BIN" ]]; then
    echo "Navgator release binary not found: $NAVGATOR_BIN" >&2
    exit 1
fi

/usr/bin/open -na "/Applications/Ghostty.app" --args \
    --config-default-files=false \
    --font-size=25 \
    --maximize=true \
    --background-opacity=0.9 \
    --background-blur=true \
    --window-save-state=never \
    --macos-titlebar-style=hidden \
    --confirm-close-surface=false \
    -e "$NAVGATOR_BIN" \
    --config-entry 'ui.theme="dark"' \
    --config-entry 'actions.picker=["open-vs-code","open-iterm","open-github-desktop","open-repo-online","open-intellij","open-claude-iterm","open-opencode-iterm"]' \
    --config-entry 'keybindings.navigator.enter="actions"'
