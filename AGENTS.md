# AGENTS.md

## Purpose
- This repository is a personal dotfiles and shell-toolchain workspace.
- Most tracked logic is Zsh (`.zsh`, `.zshenv`, `.zshrc`, `.zprofile`) plus small shell utilities.
- There is no compiled artifact, app binary, or formal unit-test harness.
- Treat syntax checks, linting, and shell startup smoke tests as the validation baseline.

## Repository Snapshot
- Startup entrypoints are `.zshenv`, `.zshrc`, and `.zprofile`.
- `.zshenv` defines `DOTFILES` and `_dotfiles_source_dir`, then sources phase folders.
- `.zshrc` and `.zprofile` call `_dotfiles_source_dir` and rely on `.zshenv` loading first.
- Main config code is in `zshenv/**` and `zshrc/**`; `zprofile/**` is currently optional/empty.
- Extra scripts/configs live in `completions/*.zsh`, `swiftbar/*.sh`, `.yabairc`, and `.config/**`.
- Global ignore rules are in `global.gitignore` (wired via `.gitconfig` `core.excludesfile`).

## Load Order and Placement
- Do not add broad inline `source` blocks directly in `.zshenv` or `.zshrc`.
- Add new behavior as a focused file in the right phase directory.
- Use `pre-init` for env/bootstrap work (`PATH`, `FPATH`, completion prerequisites).
- Use `init` for aliases, functions, plugin setup, and primary feature logic.
- Use `post-init` for interactive bindings, widgets, and terminal/UI hooks.
- Keep `.zprofile` changes limited to login-shell concerns.

## Cursor / Copilot Rules Discovery
- Checked for external editor-agent rule files in:
  - `.cursor/rules/`
  - `.cursorrules`
  - `.github/copilot-instructions.md`
- Current result: none of these files exist in this repository.
- Do not assume hidden Cursor/Copilot policy beyond this `AGENTS.md`.

## Build and Apply Commands
- There is no compile step for this repository.
- “Build” means applying dotfiles and validating startup behavior.

```bash
stow --target "$HOME" --restow .
```

```bash
zsh -lc 'source ~/.zshenv; source ~/.zshrc'
```

```bash
zsh -lic 'exit'
```

## Lint Commands
- Primary linter: `shellcheck`.
- Repo config: `.shellcheckrc` currently disables `SC2148` for extension-only scripts.

- Lint a single file (fast path):

```bash
shellcheck zshrc/init/open_with.zsh
```

- Lint all tracked shell files by repo conventions:

```bash
zsh -fc 'setopt null_glob; files=(.zshenv .zshrc .zprofile .yabairc zshenv/**/*.zsh zshrc/**/*.zsh zprofile/**/*.zsh completions/**/*.zsh swiftbar/**/*.sh); shellcheck "${files[@]}"'
```

## Test Commands
- There is no unit/integration test runner in this repo (no pytest/bats/go test/etc).
- Tests are syntax checks plus startup smoke checks.

- Run a single test (single-file syntax check):

```bash
zsh -n zshrc/init/open_with.zsh
```

- Run all syntax tests:

```bash
zsh -fc 'setopt null_glob; files=(.zshenv .zshrc .zprofile .yabairc zshenv/**/*.zsh zshrc/**/*.zsh zprofile/**/*.zsh completions/**/*.zsh swiftbar/**/*.sh); for f in "${files[@]}"; do zsh -n "$f" || exit 1; done'
```

- Combined pre-commit check (syntax + lint):

```bash
zsh -fc 'setopt null_glob; files=(.zshenv .zshrc .zprofile .yabairc zshenv/**/*.zsh zshrc/**/*.zsh zprofile/**/*.zsh completions/**/*.zsh swiftbar/**/*.sh); for f in "${files[@]}"; do zsh -n "$f" || exit 1; done; shellcheck "${files[@]}"'
```

## Code Style Guidelines

### Sourcing and Imports
- Prefer adding new files in phase directories over editing entrypoint files.
- Keep plugin loading aligned with existing `gh_source` pattern.
- Use `gh_source --require` only for hard dependencies that should fail loudly.
- Guard optional tools/files and fail soft for non-critical startup features.

### Formatting and Structure
- Preserve surrounding style; no mass reformatting.
- Keep one logical concern per file when possible.
- Keep line lengths readable; split long pipelines/options with continuation `\`.
- Keep exactly one trailing newline at end of file.
- Do not add comments unless they clarify non-obvious behavior.

### Quoting and Expansion
- Quote variable expansions by default (`"$var"`, `"${array[@]}"`).
- Prefer `[[ ... ]]` in Zsh files; reserve `[` for POSIX shell files when needed.
- Use parameter expansion intentionally (`${commands[name]:-}`, `${path%/suffix}`).
- Avoid unquoted command substitution unless splitting is explicitly required.

### Functions, Locals, and Types (Zsh)
- Declare locals at function start.
- Use typed locals when useful (`local -a`, `local -A`, `local -F`).
- Use `typeset -g` only when global scope is required.
- Use `(( ... ))` for arithmetic instead of string-based shell math.
- Prefer early returns to reduce nested conditionals.

### Naming Conventions
- Keep file names lowercase and descriptive (`feature_name.zsh`, `tool.1s.sh`).
- Prefix private helpers with `_` or `_dotfiles_`.
- Keep user-facing widget/function names command-like (`open-with`, `git-stage`).
- Keep env vars uppercase; avoid ambiguous new aliases.

### Error Handling and Defensive Defaults
- Guard optional binaries with `command -v <cmd> &>/dev/null`.
- Guard optional paths before use (`[[ -f path ]]`, `[[ -d path ]]`).
- For optional integrations, avoid startup-breaking exits.
- Redirect expected noisy failures to `/dev/null` where appropriate.
- In interactive widgets, handle empty selection/input safely.

## File-Specific Notes
- Preserve `.zshrc` generated completion block markers (`###-begin-opencode-completions-###`).
- `swiftbar/*.sh` should stay executable and keep explicit shebangs.
- `.config/zellij/config.kdl` is autogenerated by Zellij; avoid manual edits unless required.
- Keep app config formats valid (`.toml`, `.kdl`, and plain key/value configs).
- Avoid whitespace churn in large generated/config-heavy files.

## Security and Secrets
- Keep `*.secret*` and `*.work*` untracked patterns in `global.gitignore` behavior.
- Never commit plaintext credentials, tokens, or private keys.
- Use environment variables or local untracked files for sensitive values.
- Avoid printing secrets in shell output, logs, or debug traces.

## Agent Checklist
- Edit the smallest relevant file in the correct load-phase directory.
- Verify changed files with single-file checks first (`zsh -n <file>`, `shellcheck <file>`).
- Run full syntax + lint pass for broader changes.
- Check that no secret-bearing file was accidentally staged.
- Keep changes minimal, targeted, and consistent with existing patterns.
