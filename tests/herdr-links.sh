#!/bin/sh
# Unit test for .config/herdr/plugins/links/links. No herdr server, no
# popup, no keystrokes: candidates come from a fixture, fzf is the shared
# fake shim, and --print replaces every open command.
set -eu
root=$(cd "$(dirname "$0")/.." && pwd)
links=$root/.config/herdr/plugins/links/links
tools=$root/../_shared/herdr-agents/tools
# Real path: candidates print resolved paths, and macOS mktemp lives under
# a /var symlink.
work=$(cd "$(mktemp -d)" && pwd -P)
trap 'rm -rf "$work"' EXIT

fail() { echo "FAIL: $*" >&2; exit 1; }
expect() { # expect <label> <needle> <haystack>
    case "$3" in *"$2"*) ;; *) fail "$1: expected '$2' in: $3" ;; esac
}

# Fixture tree the candidates must exist in.
mkdir -p "$work/repo/src" "$work/repo/docs dir"
: > "$work/repo/src/main.rs"
: > "$work/repo/Cargo.toml"
: > "$work/repo/docs dir/a.md"
export HERDR_PLUGIN_CONFIG_DIR=$work/config
export HERDR_PLUGIN_CONTEXT_JSON="{\"focused_pane_cwd\":\"$work/repo\",\"focused_pane_id\":\"w0:p0\"}"

cat > "$work/screen.txt" <<EOF
⏺ Update($work/repo/Cargo.toml)
  see src/main.rs:12:3 and ./src/main.rs, also \`Cargo.toml\`.
  docs at https://herdr.dev/docs/plugins/, (https://example.com/x) done.
  link: file://$work/repo/src/main.rs#L7
  not a path: version 0.9.0, e.g. words, --flag, missing/file.rs:1
  home: ~/ and root: /
EOF

out=$("$links" candidates < "$work/screen.txt")
expect "file with line:col" "file	$work/repo/src/main.rs:12:3" "$out"
expect "dotslash file" "file	$work/repo/src/main.rs
" "$out"
expect "bare toml in cwd" "file	$work/repo/Cargo.toml" "$out"
expect "url" "url	https://herdr.dev/docs/plugins/" "$out"
expect "url in parens" "url	https://example.com/x" "$out"
expect "file url fragment" "file	$work/repo/src/main.rs:7" "$out"
expect "home dir" "dir	$HOME" "$out"
expect "root dir" "dir	/" "$out"
case "$out" in *"0.9.0"*|*"e.g"*|*"--flag"*|*"missing/file"*) fail "prose leaked: $out" ;; esac
# Newest output first: the last screen line fills the first rows.
first=$(printf '%s\n' "$out" | head -1)
expect "order" "dir	$HOME" "$first"

# open: kinds map to the right command; --print runs nothing.
out=$("$links" open "$work/repo/src/main.rs:12" --print)
expect "file editor" '"command": ["code", "-g", "'"$work"'/repo/src/main.rs:12"]' "$out"
out=$("$links" open "$work/repo" --print)
expect "dir herdr-open-path" "bin/herdr-open-path\", \"$work/repo\"]" "$out"
out=$("$links" open "https://herdr.dev" --print)
expect "url opener" '"command": ["open", "https://herdr.dev"]' "$out"
out=$(HERDR_PLUGIN_CLICKED_URL="file://$work/repo/src/main.rs#L3" "$links" open --print)
expect "clicked url env" "$work/repo/src/main.rs:3" "$out"
if HERDR_BIN_PATH=/usr/bin/true "$links" open "$work/nope" --print 2>/dev/null; then
    fail "missing path must fail"
fi

# links.toml editor override.
printf 'editor = ["nvim", "+"]\n' > "$work/config/links.toml"
out=$("$links" open "$work/repo/Cargo.toml" --print)
expect "editor override" '"command": ["nvim", "+", "'"$work"'/repo/Cargo.toml"]' "$out"

# pick with the fake fzf: pick the toml row, --print shows the open command.
mkdir -p "$work/bin" && ln -s "$tools/fake-fzf" "$work/bin/fzf"
export FAKE_STATE=$work/fzf-state FAKE_PICK_1="Cargo.toml"
out=$(PATH="$work/bin:$PATH" "$links" pick --from "$work/screen.txt" --print)
expect "pick opens the toml" "$work/repo/Cargo.toml" "$out"
# Cancel: no output, exit 0.
rm -f "$FAKE_STATE"; unset FAKE_PICK_1
out=$(PATH="$work/bin:$PATH" "$links" pick --from "$work/screen.txt" --print)
[ -z "$out" ] || fail "cancel must print nothing: $out"

echo ok
