---
name: uv-python
description: Use uv for anything Python. Never invoke python, python3, pip, pipx, poetry, pyenv, or virtualenv directly, uv replaces all of them. Covers project environments, dependencies, locking, tools, tests, CI, Docker, and publishing. Equally the default for throwaway work: any one-off computation, parsing, JSON or CSV handling, HTTP call, or quick check goes through a heredoc into `uv run -` rather than `python -c`, a scratch file, or a bash/jq/awk/sed pipeline. Applies even for a single line, even when no Python project exists, and even when the request never mentions Python.
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
- Any throwaway check beyond a trivial shell one-liner goes to `uv run -`, not bash. Parsing, JSON/CSV, HTTP, math, date handling, file munging: a heredoc you can read beats a jq/awk/sed chain you have to debug.
- Validate with `uvx ruff check`. Type-check with `uvx ty`.

## Modes

- **Project** (`pyproject.toml` exists) — `uv add`, `uv sync`, `uv run ...`, `uv lock`.
- **Script** (single file with PEP 723 inline metadata) — `uv init --script`, `uv add --script`, `uv run script.py`. Runs isolated from any surrounding project.
- **Tool** (CLI utilities) — `uvx <tool>`. Use `uv run <tool>` when the tool must see project env (pytest, mypy, project entry points).
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

If the snippet grows, drop it into a file with a PEP 723 header and make it self-executable:

```python
#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.12"
# dependencies = ["httpx", "rich"]
# ///
```