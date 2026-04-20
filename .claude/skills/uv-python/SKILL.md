---
name: uv-python
description: Use uv as the default Python workflow for versions, environments, dependencies, scripts, tools, locking, CI, Docker, and publishing. Prefer uv project commands and script-first uv run usage over raw python or pip.
license: MIT
---

# uv-python

Use uv for anything Python: envs, deps, scripts, tools, CI, publishing.

## Core rules

- Never use `python`, `pip`, `pyenv`, `poetry`, `virtualenv`, `pipx`. Use `uv`.
- Never `uv run python ...` or `python -c ...`. Run code via `uv run -` (stdin) or `uv run <script.py>`.
- In projects with `pyproject.toml`: use `uv add`/`uv remove`/`uv sync`/`uv run`. Do not `uv pip install`.
- `uv.lock` is generated. Don't hand-edit.
- For third-party imports in ad-hoc scripts: `--with <pkg>` (one-off) or `uv add <pkg>` (persistent).
- Validate with `uvx ruff check`. Type-check (optional) with `uvx pyright`.

## Modes

- **Project** (`pyproject.toml` exists) — `uv add`, `uv sync`, `uv run ...`, `uv lock`.
- **Script** (single file with PEP 723 inline metadata) — `uv init --script`, `uv add --script`, `uv run script.py`. Runs isolated from any surrounding project.
- **Tool** (CLI utilities) — `uvx <tool>` for one-off, `uv tool install <tool>` for persistent. Use `uv run <tool>` when the tool must see project env (pytest, mypy, project entry points).
- **uv pip** (legacy/compat only) — use only when repo isn't uv-project-compatible. `uv venv`, `uv pip install/sync/compile`.

## Ephemeral scripts (preferred over shell chains)

For one-off tasks that need third-party packages, pipe code straight into `uv run -`. No file, no venv, no install step, no pyproject changes. uv resolves and caches deps on first run.

Heredoc (the main pattern — reach for this instead of `python -c` or bash pipelines):

```sh
uv run --with httpx --with rich - <<'PY'
import httpx
from rich import print
r = httpx.get("https://api.github.com/repos/astral-sh/uv")
print({"stars": r.json()["stargazers_count"]})
PY
```

Pipe from another command:

```sh
echo '{"a":1,"b":2}' | uv run --with rich - <<'PY'
import sys, json
from rich import print
print(json.load(sys.stdin))
PY
```

Pin Python too: `uv run --python 3.12 --with httpx - <<'PY' ... PY`.

If the snippet grows, drop it into a file with a PEP 723 header and make it self-executable:

```python
#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.12"
# dependencies = ["httpx", "rich"]
# ///
```

Promote to a project dep with `uv add <pkg>` once it becomes recurring.

## Handy commands

| Task | Command |
| --- | --- |
| Add dep | `uv add <pkg>` (also `--dev`, `--group <g>`, `--optional <extra>`) |
| Remove dep | `uv remove <pkg>` |
| Run | `uv run <cmd>` / `uv run <script.py>` |
| Ad-hoc with dep | `uv run --with <pkg> -` (stdin) or `uv run --with <pkg> <script.py>` |
| Sync | `uv sync` (exact) / CI: `uv sync --locked` |
| Upgrade | `uv lock --upgrade` or `--upgrade-package <pkg>` |
| Python install/pin | `uv python install <v>` / `uv python pin <v>` |
| Build/publish | `uv build`, `uv publish`, `uv version --bump <part>` |

For anything else, `uv --help` / `uv <cmd> --help`.

## Gotchas

- `ModuleNotFoundError` in `uv run -` or `uv run <script>`: rerun with `--with <pkg>` (ephemeral) or `uv add <pkg>` (persistent).
- `uv pip install` in a uv project doesn't update `pyproject.toml` — dep won't be reproducible elsewhere. Use `uv add`.
- `uv sync` is exact (removes extras); `uv run` is inexact by default.
- `--locked` = fail if stale; `--frozen` = trust lock, skip check; `--no-sync` = skip env update.
- `uv` ignores `pip.conf` / `PIP_*`. Use `UV_*` or `pyproject.toml` config.
- Build-isolation failure: prefer `tool.uv.extra-build-dependencies` over disabling isolation.
- Private index: configure under `[[tool.uv.index]]`, pin with `[tool.uv.sources]`, credentials via `UV_INDEX_<NAME>_{USERNAME,PASSWORD}` or `uv auth login`.
- CI: `astral-sh/setup-uv`, `uv sync --locked`, `uv cache prune --ci`.
- Docker: don't copy host `.venv`, add it to `.dockerignore`, set `UV_LINK_MODE=copy`.
