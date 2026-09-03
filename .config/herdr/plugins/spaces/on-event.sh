#!/bin/sh
# Event hook: a pane or tab changed shape (created, closed, exited, moved
# in or out). Re-sync every workspace named in the event payload so the
# checkout rows reflect the panes that are actually there now.
set -eu
PATH="$HOME/.local/bin:/opt/homebrew/bin:$PATH"
sync="$HERDR_PLUGIN_ROOT/space-sync"
printf '%s' "${HERDR_PLUGIN_EVENT_JSON-}" \
    | jq -r '[.. | objects | to_entries[] | select(.key | endswith("workspace_id")) | .value] | unique[]' \
    | while read -r ws; do
        cwd=$("$HERDR_BIN_PATH" pane list --workspace "$ws" 2>/dev/null | jq -r '.result.panes[0].cwd // empty') || true
        [ -n "$cwd" ] && "$sync" "$ws" "$cwd" || true
    done
