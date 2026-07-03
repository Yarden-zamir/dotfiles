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

1. Clone to the expected location — `$DOTFILES` is hardcoded to
   `~/Github/dotfiles` in `.zshenv` and `.zshrc`:

   ```sh
   git clone <this-repo> ~/Github/dotfiles
   cd ~/Github/dotfiles
   ```

2. Preview what stow would link, then adopt (see the Stow workflow section for
   what `--adopt` does):

   ```sh
   make stow-adopt-dry-run
   make stow-adopt
   ```

3. Open a new shell. `.zshenv` → `.zprofile` → `.zshrc` source their phase
   directories and everything loads from there.

Runtime state (`.claude`, `.agents`, `.config/codex`, …) is stowed as folded
symlinks so it accumulates inside this repo; `.gitignore` keeps that state out
of history while tracking only the curated config. Stow and git have separate
jobs here — see `.stow-local-ignore` (keeps repo-internal paths out of `$HOME`)
versus `.gitignore` (keeps machine state out of git).

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

This repo is managed as the `dotfiles` GNU Stow package from its parent directory.

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
