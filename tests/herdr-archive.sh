#!/bin/sh
# Unit-style test for the archive plugin against the running herdr server.
# It uses a scratch state and config dir, a per-run archive label, toasts
# off and focus_on_restore off, so it never touches the real archive space
# and never moves focus. Throwaway workspaces are closed on exit.
#
# Usage: tests/herdr-archive.sh   (needs HERDR_SOCKET_PATH, uv, jq)
set -eu

repo=$(cd "$(dirname "$0")/.." && pwd)
herdr=${HERDR_BIN_PATH:-herdr}
run="uv run --script --quiet $repo/.config/herdr/plugins/archive/archive.py"
tmp=$(mktemp -d)
tag="archive-test-$$"

export HERDR_PLUGIN_STATE_DIR="$tmp/state"
export HERDR_PLUGIN_CONFIG_DIR="$tmp/config"
mkdir -p "$HERDR_PLUGIN_STATE_DIR" "$HERDR_PLUGIN_CONFIG_DIR"
cat > "$HERDR_PLUGIN_CONFIG_DIR/archive.toml" <<EOF
label = "$tag"
max_age_days = 0
toasts = false
focus_on_restore = false
EOF

ws_list() { "$herdr" workspace list | jq -c '.result.workspaces'; }
ws_by_label() { ws_list | jq -r --arg l "$1" '.[] | select(.label == $l) | .workspace_id'; }
last_ws() { ws_list | jq -r '.[-1].workspace_id'; }
stack_len() { jq '.stack | length' "$HERDR_PLUGIN_STATE_DIR/stack.json"; }

cleanup() {
    for id in $(ws_list | jq -r --arg t "$tag" '.[] | select(.label | startswith($t)) | .workspace_id'); do
        "$herdr" workspace close "$id" >/dev/null 2>&1 || true
    done
    rm -rf "$tmp"
}
trap cleanup EXIT

fail() { echo "FAIL: $*" >&2; exit 1; }

new_origin() {
    "$herdr" workspace create --cwd "$tmp" --label "$tag-origin-$1" --no-focus \
        | jq -r '.result.root_pane.pane_id'
}

# --- archive: pane lands in its own labeled tab, origin closes, stack grows
pane=$(new_origin a)
HERDR_PANE_ID=$pane $run archive
arc=$(ws_by_label "$tag")
[ -n "$arc" ] || fail "no archive workspace labeled $tag"
[ -z "$(ws_by_label "$tag-origin-a")" ] || fail "single-pane origin should close after archive"
[ "$(stack_len)" = 1 ] || fail "stack should have 1 entry"
tab_label=$("$herdr" tab list --workspace "$arc" | jq -r '.result.tabs[0].label')
case "$tab_label" in "$tag-origin-a › "*) ;; *) fail "tab label '$tab_label' lacks origin prefix" ;; esac

# --- pin-last: archive returns to the end after being moved to the front
first=$(ws_list | jq -r '.[0].workspace_id')
printf '{"id":"t","method":"workspace.move_block","params":{"workspace_ids":["%s"],"before_workspace_id":"%s"}}\n' "$arc" "$first" \
    | nc -U "$HERDR_SOCKET_PATH" >/dev/null
[ "$(last_ws)" != "$arc" ] || fail "setup: archive should not be last now"
$run pin-last
[ "$(last_ws)" = "$arc" ] || fail "pin-last should move the archive workspace last"

# --- restore-last: origin is recreated with its label, stack empties
$run restore-last
[ -n "$(ws_by_label "$tag-origin-a")" ] || fail "restore-last should recreate the origin workspace"
[ "$(stack_len)" = 0 ] || fail "stack should be empty after restore"

# --- restore-pick: a fake fzf picks the first (newest) row
pane_b=$(new_origin b)
pane_c=$(new_origin c)
HERDR_PANE_ID=$pane_b $run archive
HERDR_PANE_ID=$pane_c $run archive
[ "$(stack_len)" = 2 ] || fail "stack should have 2 entries"
mkdir -p "$tmp/bin"
printf '#!/bin/sh\nhead -n 1\n' > "$tmp/bin/fzf"; chmod +x "$tmp/bin/fzf"
PATH="$tmp/bin:$PATH" $run restore-pick
[ -n "$(ws_by_label "$tag-origin-c")" ] || fail "restore-pick should restore the newest pane (c)"
[ -z "$(ws_by_label "$tag-origin-b")" ] || fail "pane b should still be archived"
[ "$(stack_len)" = 1 ] || fail "stack should have 1 entry after pick"

# --- reap: an entry older than max_age_days is closed
sed -i '' 's/^max_age_days = 0/max_age_days = 0.00001/' "$HERDR_PLUGIN_CONFIG_DIR/archive.toml"
sleep 2
$run reap
[ "$(stack_len)" = 0 ] || fail "reap should drop the aged entry"
# Closing the last pane also closes the archive workspace.
[ -z "$(ws_by_label "$tag")" ] || fail "reap should close the aged pane and the empty archive workspace"
sed -i '' 's/^max_age_days = 0.00001/max_age_days = 0/' "$HERDR_PLUGIN_CONFIG_DIR/archive.toml"

# --- clear: archive workspace closes, state resets
pane_d=$(new_origin d)
HERDR_PANE_ID=$pane_d $run archive
$run clear
[ -z "$(ws_by_label "$tag")" ] || fail "clear should close the archive workspace"
[ "$(stack_len)" = 0 ] || fail "clear should reset the stack"

echo "ok"
