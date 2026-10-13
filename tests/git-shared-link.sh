#!/bin/sh

set -eu

script_dir=$(cd -- "$(dirname -- "$0")" && pwd -P)
repo_root=$(dirname "$script_dir")
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT INT HUP TERM

repo="$tmp/repo"
git init -q -b main "$repo"
git -C "$repo" -c user.name=test -c user.email=test@example.com commit -q --allow-empty -m init
"$repo_root/bin/wt-migrate" --yes "$repo" >/dev/null 2>&1

mkdir -p "$repo/_shared/tools" "$repo/_shared/backup/App (Nightly) [2].app"
printf 'secret\n' >"$repo/_shared/tools/token.env"
printf 'x\n' >"$repo/_shared/backup/App (Nightly) [2].app/file"

"$repo_root/bin/git-shared-link" "$repo/main" 2>/dev/null
"$repo_root/bin/git-shared-link" "$repo/main" 2>/dev/null

[ -L "$repo/main/tools/token.env" ]
[ -L "$repo/main/backup/App (Nightly) [2].app/file" ]

status=$(git -C "$repo/main" status --porcelain --untracked-files=all)
[ -z "$status" ] || {
  printf 'expected linked files to stay out of git status, got:\n%s\n' "$status" >&2
  exit 1
}

git -C "$repo/main" add -A
staged=$(git -C "$repo/main" diff --cached --name-only)
[ -z "$staged" ] || {
  printf 'expected git add -A to stage nothing, got:\n%s\n' "$staged" >&2
  exit 1
}

exclude="$repo/.bare/info/exclude"
[ "$(grep -cxF '/tools/token.env' "$exclude")" = 1 ] || {
  printf 'expected one exclude line per link after two runs\n' >&2
  exit 1
}

printf 'git-shared-link exclude test passed\n'
