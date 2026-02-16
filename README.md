# personal-toolchain

Personal Zsh-first dotfiles for daily terminal work on macOS and Linux.

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

## Editing guidelines

- Keep changes modular: add/update a focused file in the proper phase directory.
- Avoid broad inline `source` blocks in `.zshenv` or `.zshrc`.
- Follow existing `gh_source` usage for plugin sourcing.
- Use `gh_source --require` only for hard dependencies.
