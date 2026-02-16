---
name: uv-python
description: Use uv as the default Python workflow for versions, environments, dependencies, scripts, tools, locking, CI, Docker, and publishing. Prefer uv project commands and uv run over raw python or pip.
license: MIT
compatibility: opencode+claude-code
metadata:
  standard: agentskills.io
  source: docs.astral.sh/uv
  last-reviewed: 2026-02-16
---

# uv-python

Use this skill for any Python task that touches environments, dependency management, script execution, tooling, packaging, publishing, CI, or Docker.

## Non-negotiable defaults

- Prefer `uv` commands over `python`, `pip`, `pip-tools`, `virtualenv`, `pipx`, `poetry`, and `pyenv`.
- Run Python through uv. Use `uv run python ...` instead of `python ...`.
- In uv projects, change dependencies with `uv add` and `uv remove`, not `uv pip install`.
- `uv pip install` is legacy compatibility mode and is not recommended for uv-managed projects.
- In almost all cases, prefer making the workflow uv-project-compatible (`uv add`, `uv lock`, `uv sync`, `uv run`) instead of using the pip interface.
- Treat `uv.lock` as generated output. Never hand-edit it.
- Keep dependency changes reproducible: update `pyproject.toml` and `uv.lock` together.
- For ad-hoc `uv run python -c` snippets, never assume third-party imports exist. Use `--with` for one-off dependencies or `uv add` for persistent ones.

## Mode detection

1. If a `pyproject.toml` exists, use **project mode**.
2. If operating on a standalone script with PEP 723 metadata, use **script mode**.
3. If there is no project metadata and the workflow is pip-style, use **uv pip mode**.
4. If invoking CLI packages like `ruff` or `black` outside the project env, use **tool mode** (`uvx` / `uv tool`).

## Project mode workflow

1. Ensure interpreter intent is clear (`.python-version`, `project.requires-python`, or explicit `--python`).
2. Install or update dependencies with `uv add` / `uv remove`.
3. Sync environment with `uv sync`.
4. Run commands with `uv run ...`.
5. Lock with `uv lock` (or rely on automatic lock/sync from `uv run` and `uv sync`).

Use these defaults:

- Add runtime dependency: `uv add <pkg>`
- Add dev dependency: `uv add --dev <pkg>`
- Add named group dependency: `uv add --group <group> <pkg>`
- Add optional extra dependency: `uv add --optional <extra> <pkg>`
- Remove dependency: `uv remove <pkg>`
- Run tests: `uv run pytest`
- Run module: `uv run -m <module>`

## Script mode workflow

Use this for one-file scripts and automation snippets.

- Initialize script with metadata: `uv init --script script.py --python 3.12`
- Add script dependency: `uv add --script script.py <pkg>`
- Run script: `uv run script.py`
- Run ad-hoc with one-off dependency: `uv run --with <pkg> script.py`
- Lock script dependencies: `uv lock --script script.py`

Notes:

- PEP 723 scripts with inline metadata run in isolated environments.
- If inline metadata exists, project dependencies are ignored for that script.

## Ad-hoc snippet preflight (`uv run python -c`)

Before running any ad-hoc Python snippet:

1. Inspect imports in the snippet.
2. If imports are stdlib-only, run with `uv run python -c ...`.
3. If snippet uses third-party modules for one-off execution, run with `uv run --with <pkg> [--with <pkg> ...] python -c ...`.
4. If dependency should persist in project, install first via `uv add <pkg>`, then run with `uv run python -c ...`.
5. If `ModuleNotFoundError` occurs, rerun immediately with `--with` (or install via `uv add`) before retrying.

Example:

- One-off: `uv run --with mpmath python -c "from mpmath import mp; ..."`

## Tool mode workflow

Use for command-line tools that should be isolated from project dependencies.

- One-off command: `uvx <tool> ...`
- One-off with explicit package source: `uvx --from <package> <command> ...`
- Install persistent tool: `uv tool install <package>`
- Upgrade tool: `uv tool upgrade <package>`
- List tools: `uv tool list`
- Uninstall tool: `uv tool uninstall <package>`

Choose `uv run` instead of `uvx` when the tool must see the project package/environment (for example `pytest`, `mypy`, or project entry points).

## uv pip mode workflow (last-resort compatibility)

Use only when working in a pip-style repository or explicit migration tasks. Do not use this mode as the default in uv-managed projects.

Default-first rule:

- If a `pyproject.toml` exists, use `uv add`/`uv remove` and `uv run`.
- Reach for `uv pip ...` only when the repository is not yet uv-project-compatible.

- Create venv: `uv venv`
- Install: `uv pip install <pkg>`
- Install from requirements: `uv pip install -r requirements.txt`
- Compile locks: `uv pip compile requirements.in -o requirements.txt`
- Sync exact environment: `uv pip sync requirements.txt`

Important behavior:

- uv does not read `pip.conf` or `PIP_*` env vars.
- uv defaults to virtual environments for `uv pip`; use `--system` only when explicitly needed (CI/container cases).

## Python version management workflow

- Install Python: `uv python install <version>`
- List versions: `uv python list`
- Pin project version: `uv python pin <version>`
- Find matching interpreter: `uv python find '<specifier>'`
- Upgrade managed patch versions: `uv python upgrade [<minor>]`

Defaults:

- uv can auto-download missing Python versions unless disabled.
- Prefer managed interpreters by default; use `--no-managed-python` only when required.

## Reproducibility and safety defaults

- CI installs should prefer lock correctness: `uv sync --locked`.
- For hard reproducibility where lock freshness checks are already enforced upstream, use `--frozen`.
- Use `uv lock --check` to validate lock freshness.
- Use `uv run --no-sync` only when intentionally skipping environment updates.
- Use `uv sync` for exact installs (removes extraneous packages).
- Use `uv run` for inexact run-time sync by default (keeps extraneous packages unless `--exact`).

## Indexes and authentication defaults

- Define indexes with `[[tool.uv.index]]` in project config.
- Keep the default secure index strategy (`first-index`) unless explicitly changed.
- Prefer environment variables for credentials over embedding them in project files.
- Use `uv auth login <host>` for uv-managed HTTP credential storage.
- For private Git dependencies, prefer SSH URLs or configured Git credential helpers.

## Packaging and publishing defaults

- Build distributions: `uv build`
- Validate package build without source overrides: `uv build --no-sources`
- Publish: `uv publish`
- Bump version: `uv version --bump <major|minor|patch|...>`

## CI and Docker defaults

- In GitHub Actions, use `astral-sh/setup-uv` and pin uv version.
- Cache uv data for CI speedups; prune with `uv cache prune --ci`.
- In Docker, use intermediate layers with `uv sync --no-install-project` (or `--no-install-workspace` in workspaces), then final sync.
- Add `.venv` to `.dockerignore`.

## Quick escalation rules

- If resolution fails, inspect conflicts first, then consider constraints or overrides.
- If build isolation fails, prefer `tool.uv.extra-build-dependencies` before disabling build isolation.
- If private index auth fails, verify index config and auth source order (URL, netrc, uv auth store, keyring).
- If you are about to use `uv pip install` in a project with `pyproject.toml`, stop and model the change with `uv add` instead.

## Supporting docs in this skill

- Command cookbook and pip-to-uv mapping: [COMMANDS.md](COMMANDS.md)
- Failure diagnosis and fixes: [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
