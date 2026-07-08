# personal-toolchain

Personal Zsh-first dotfiles for daily terminal work on macOS and Linux.

> **Not a drop-in framework.** This repo is published to read, learn from, and
> copy pieces out of — the phase loader, individual `zshrc/init/*.zsh` modules,
> the stow/git split, etc. It hardcodes personal paths and assumptions and is
> not meant to be installed wholesale on someone else's machine. Lift the parts
> that are useful; don't `make stow-adopt` it into your `$HOME` expecting it to
> "just work."

## Bootstrap

For reference, this is how the setup wires itself onto a fresh machine.

Prerequisites: `zsh`, `git`, and GNU `stow` (macOS: `brew install stow`). The
`gh_source` plugin helper is self-bootstrapped by the dotfiles themselves
(`zshenv/pre-init/_gh_source.zsh`), so nothing extra is needed for plugins.

This repo uses a bare + worktree **container** layout (see
`bin/git-repo-to-bare-with-worktrees`):

    ~/Github/dotfiles/
    ├── .bare/     the git repository
    ├── _shared/   local-only files shared across worktrees (secrets), symlinked in
    └── main/      the working checkout, stow package, and $DOTFILES

Secrets (`zshenv/init/*.secret.zsh`, `*.work.zsh`) live in `_shared/` and are
symlinked into each worktree, so they are never duplicated across worktrees or
committed.

1. Clone to the expected location, then convert it to the container layout with
   the included tool — `$DOTFILES` is hardcoded to `~/Github/dotfiles/main` in
   `.zshenv` and `.zshrc`:

   ```sh
   git clone <this-repo> ~/Github/dotfiles
   cd ~/Github/dotfiles
   bin/git-repo-to-bare-with-worktrees --yes   # -> .bare/ + main/ + _shared/
   ```

2. Preview what stow would link, then adopt (see the Stow workflow section for
   what `--adopt` does) — run from the `main/` worktree:

   ```sh
   cd ~/Github/dotfiles/main
   make stow-adopt-dry-run
   make stow-adopt
   ```

3. Open a new shell. `.zshenv` → `.zprofile` → `.zshrc` source their phase
   directories and everything loads from there.

Runtime state (`.claude`, `.agents`, `.config/codex`, …) is stowed as folded
symlinks so it accumulates inside the `main/` worktree; `.gitignore` keeps that
state out of history while tracking only the curated config. Stow and git have
separate jobs here — see `.stow-local-ignore` (keeps repo-internal paths out of
`$HOME`) versus `.gitignore` (keeps machine state out of git).

## Phase system

Phase-based loader for shell startup.
The `_dotfiles_source_dir` helper sources `*.zsh` files from phase directories in order.

Startup flow:

- `.zshenv` (always): `zshenv/pre-init` -> `zshenv/init` -> `zshenv/post-init`
- `.zprofile` (login shells): `zprofile/pre-init` -> `zprofile/init` -> `zprofile/post-init`
- `.zshrc` (interactive shells): `zshrc/pre-init` -> `zshrc/init` -> `zshrc/post-init`

Phase intent:

- `pre-init`: environment/bootstrap (`PATH`, `FPATH`, completion prerequisites)
- `init`: aliases, functions, plugin setup, core behavior
- `post-init`: widgets, keybindings, terminal/UI hooks

Placement rule: add new behavior as a focused file in the correct phase directory instead of expanding entrypoint files.

## Tooling assumptions

- `zsh`
- `git`
- `stow`
- `shellcheck`
- `gh_source` (for plugin management)

Frequently used optional tools in this setup include `gh`, `fzf`, `bat`, `rg`, `fd`, `atuin`, `starship`, and `cargo`.

## Stow workflow

This repo is managed as the `main` GNU Stow package, run from the `main/` worktree;
the Makefile derives the stow directory as its parent (the container).

- Preview adoption first: `make stow-adopt-dry-run`
- Adopt and restow files into `~`: `make stow-adopt`

The Makefile derives the stow directory from the repo location and uses `$(HOME)` as the target, so the command does not depend on a hardcoded username.

`stow-adopt` runs the equivalent of:

```sh
stow --verbose --dir "$(dirname "$PWD")" --target "$HOME" "$(basename "$PWD")" --adopt
```

Use `--adopt` carefully: it can move existing files from `~` into this repo before linking them back.

## Editing guidelines

- Keep changes modular: add/update a focused file in the proper phase directory.
- Avoid broad inline `source` blocks in `.zshenv` or `.zshrc`.
- Follow existing `gh_source` usage for plugin sourcing.
- Use `gh_source --require` only for hard dependencies.
