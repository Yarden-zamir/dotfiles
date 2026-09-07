#!/bin/sh

set -eu

script_dir=$(cd -- "$(dirname -- "$0")" && pwd -P)
repo_root=$(dirname "$script_dir")
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT INT HUP TERM

repo="$tmp/empty-repo"
git init -q -b main "$repo"

"$repo_root/bin/wt-migrate" --yes "$repo"

[ -d "$repo/.bare" ]
[ -d "$repo/_shared" ]
[ -d "$repo/main" ]
[ "$(git -C "$repo/main" branch --show-current)" = 'main' ]
git -C "$repo/main" rev-parse --verify HEAD >/dev/null 2>&1 && {
  printf 'expected main to remain unborn\n' >&2
  exit 1
}

printf 'wt-migrate empty repository test passed\n'
