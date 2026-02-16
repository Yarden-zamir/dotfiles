# AGENTS.md

## Purpose
- This repository is a personal dotfiles/toolchain repo.
- It is mostly Zsh configuration and small shell utilities.
- There is no single app binary to build and no formal test framework.
- Treat shell syntax checks and linting as the core validation flow.

## Repository Layout
- `.zshenv` defines `DOTFILES` and loads files from:
  - `zshenv/pre-init/*.zsh`
  - `zshenv/init/*.zsh`
  - `zshenv/post-init/*.zsh`
- `.zshrc` loads files from:
  - `zshrc/pre-init/*.zsh`
  - `zshrc/init/*.zsh`
  - `zshrc/post-init/*.zsh`
- `.zprofile` loads files from:
  - `zprofile/pre-init/*.zsh`
  - `zprofile/init/*.zsh`
  - `zprofile/post-init/*.zsh`
- Extra shell scripts/configs live in:
  - `completions/*.zsh`
  - `swiftbar/*.sh`
  - root config files like `.yabairc`
  - app configs under `.config/`

## Cursor/Copilot Rules Discovery
- Checked paths:
  - `.cursor/rules/`
  - `.cursorrules`
  - `.github/copilot-instructions.md`
- Result: no Cursor or Copilot instruction files are present in this repo.
- Do not assume external editor-agent rules beyond this file.

## Build / Install Commands
- There is no compile/build step for this repo itself.
- "Build" in this repo means applying dotfiles and validating shell startup.
- If using GNU Stow to apply dotfiles:

```bash
stow --target "$HOME" --restow .
```

- Reload shell config after changes:

```bash
zsh -lc 'source ~/.zshenv; source ~/.zshrc'
```

## Lint Commands
- Primary linter: `shellcheck` (repo includes `.shellcheckrc`).
- `.shellcheckrc` currently disables `SC2148` for extension-only scripts.

- Lint a single file (fast path):

```bash
shellcheck zshrc/init/open_with.zsh
```

- Lint all shell files tracked by layout conventions:

```bash
zsh -fc 'setopt null_glob; shellcheck .zshenv .zshrc .zprofile .yabairc zshenv/**/*.zsh zshrc/**/*.zsh completions/**/*.zsh swiftbar/**/*.sh'
```

## Test Commands
- There is no unit-test harness (no pytest/bats/go test/etc in repo).
- Treat syntax validation as tests.

- Run a single test (single-file syntax check):

```bash
zsh -n zshrc/init/open_with.zsh
```

- Run all syntax tests:

```bash
zsh -fc 'setopt null_glob; files=(.zshenv .zshrc .zprofile .yabairc zshenv/**/*.zsh zshrc/**/*.zsh completions/**/*.zsh swiftbar/**/*.sh); for f in "${files[@]}"; do zsh -n "$f" || exit 1; done'
```

- Useful combined check before commit:

```bash
zsh -fc 'setopt null_glob; files=(.zshenv .zshrc .zprofile .yabairc zshenv/**/*.zsh zshrc/**/*.zsh completions/**/*.zsh swiftbar/**/*.sh); for f in "${files[@]}"; do zsh -n "$f" || exit 1; done; shellcheck "${files[@]}"'
```

## Code Style Guidelines

### Imports / Sourcing / Load Order
- Do not add direct `source` sprawl inside `.zshenv` or `.zshrc`.
- Add new config as separate files under the existing phase folders.
- Choose phase by startup needs:
  - `pre-init`: `PATH`/`FPATH`, completion prerequisites, bootstrap helpers.
  - `init`: aliases, functions, plugin setup, feature logic.
  - `post-init`: keybindings, interactive-only behavior, terminal hooks.
- Use `gh_source` for external plugins when following existing pattern.
- Use `gh_source --require` only for hard dependencies.

### Formatting
- Keep formatting stable; this repo has no autoformatter configured.
- Match surrounding file style instead of mass reformatting.
- Keep lines readable; split long pipelines with continuation (`\`) when needed.
- Use a single trailing newline at file end.
- Preserve existing comment density; do not add comment noise.

### Quoting and Expansion
- Quote variable expansions by default: `"$var"`, `"${array[@]}"`.
- Prefer `[[ ... ]]` for tests in Zsh files.
- Use parameter expansion intentionally (for example `${commands[name]:-}` and `${var%/suffix}`).
- Avoid unquoted command substitution unless word splitting is required.

### Types and Data Structures (Zsh)
- Use explicit locals at function start:
  - `local name`
  - `local -a items`
  - `local -A map`
  - `local -F elapsed`
- Use `typeset -g...` only when global scope is required.
- Use `(( ... ))` for arithmetic and counters.

### Naming Conventions
- File names are lowercase with `.zsh`/`.sh`; keep naming consistent per folder.
- Internal helper functions should be prefixed (`_dotfiles_` or `_`).
- User-facing widgets/functions may be command-like (`open-with`) when useful.
- Environment variables are uppercase (`SOME_SETTING`).
- Keep aliases short and ergonomic, but avoid ambiguous new aliases.

### Error Handling and Defensive Defaults
- Guard optional commands with `command -v <cmd> &>/dev/null`.
- Guard optional files/dirs before sourcing or reading:
  - `[[ -f path ]]`
  - `[[ -d path ]]`
- Prefer early returns in helper functions (`|| return 0`) for optional paths.
- Avoid startup-breaking failures for non-essential features.
- Redirect noisy optional failures to `/dev/null` where appropriate.
- In interactive widgets, handle empty selection/input safely.

## File-Specific Notes
- `swiftbar/*.sh` should remain executable shell scripts with explicit shebang.
- `.config/zellij/config.kdl` is autogenerated; avoid hand-editing unless necessary.
- Keep app config formats valid (`.toml`, `.kdl`, plain key/value configs), and avoid unrelated whitespace churn in large generated blocks.

## Security and Secrets
- `.gitignore` ignores `*.secret*` and `*.work*`; keep this behavior.
- Never add new plaintext tokens, passwords, or API keys to tracked files.
- If secret values are needed, use local untracked files or environment injection.
- Do not print or log secret values in scripts.

## Change Checklist for Agents
- Edit the smallest relevant file in the correct load-phase directory.
- Run single-file checks first on touched files (`zsh -n`, `shellcheck`).
- Run full syntax/lint pass for broad changes and verify no accidental secret additions.
