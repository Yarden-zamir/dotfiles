---
name: worktree-repo
description: Set up a repo in the bare + worktree container layout (.bare/, _shared/, main/). Use when creating a new project, cloning a repo, converting an existing clone, adding a worktree or branch checkout, or working in any directory that contains a .bare/ folder.
---

# Bare + worktree repo layout

Every repo is a **container directory** holding the git dir, shared local files, and one folder per checked-out branch:

```
~/Github/<project>/
├── .bare/      the git repository (bare)
├── _shared/    local-only files (secrets, env) shared across worktrees
├── main/               worktree for the main branch
└── <branch-basename>/  worktree named exactly after the branch's final path component
```

The worktree directory name must equal the branch's **final path component** one-to-one: `feat/api/qcdi-1234-auth` → `qcdi-1234-auth/`. Preserve that component exactly, including ticket prefixes, casing, and separators; do not shorten it further.

Nothing in `$DOTFILES/bin` is on `$PATH` — call these tools by path.

## Creating or converting a repo

Clone normally into the container path, then convert. `wt-migrate` is dry-run by default; pass `--yes` to apply.

```sh
git clone <url> ~/Github/<project>
$DOTFILES/bin/wt-migrate ~/Github/<project>          # print the plan
$DOTFILES/bin/wt-migrate --yes ~/Github/<project>    # apply
```

Run with no path to pick a repo under `$PWD` with `fzf`.

It refuses to migrate a dirty tree, a detached HEAD, a bare repo, or a repo that already has linked worktrees. Ignored files in the repo root move to `_shared/`; ignored files inside directories (`node_modules/`, build output) stay in the worktree. Stashes are left alone.

## Adding a worktree

Plain git is correct — the `post-checkout` hook links `_shared/` automatically:

```sh
git --git-dir ~/Github/<project>/.bare worktree add ~/Github/<project>/qcdi-1234-auth -b feat/api/qcdi-1234-auth
```

## _shared/

Local-only files that must not be committed and must not be duplicated per worktree live in `_shared/`, mirroring their path inside the worktree:

```
_shared/zshenv/init/atuin.secret.zsh
  -> main/zshenv/init/atuin.secret.zsh   (symlink)
```

`$DOTFILES/bin/git-shared-link [worktree]` creates these links. The global `post-checkout` hook (`$DOTFILES/.config/git/hooks/post-checkout`, wired up by `core.hooksPath`) runs it on every branch checkout, clone, and `worktree add`. It is idempotent and never overwrites a real file, so **do not create these symlinks by hand** — put the file in `_shared/` and check out the branch.

Anything in `_shared/` must also be ignored by git, or it will show up as untracked in every worktree.
