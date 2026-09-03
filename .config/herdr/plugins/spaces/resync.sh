#!/bin/sh
# Startup hook: re-sync every managed space (name starts with the marker)
# from its first pane's cwd. One-shot; exits when done.
set -eu
PATH="$HOME/.local/bin:/opt/homebrew/bin:$PATH"
sync="$HERDR_PLUGIN_ROOT/space-sync"
"$HERDR_BIN_PATH" workspace list | jq -r '.result.workspaces[] | select(.label | test("^(|»)")) | .workspace_id' |
while read -r ws; do
    cwd=$("$HERDR_BIN_PATH" pane list --workspace "$ws" | jq -r '.result.panes[0].cwd // empty')
    [ -n "$cwd" ] && "$sync" "$ws" "$cwd" || true
done
