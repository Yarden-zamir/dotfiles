# uv command cookbook

## Fast command map

| Task | Preferred command |
| --- | --- |
| Create project | `uv init` |
| Add dependency | `uv add <pkg>` |
| Add dev dependency | `uv add --dev <pkg>` |
| Remove dependency | `uv remove <pkg>` |
| Lock dependencies | `uv lock` |
| Sync environment | `uv sync` |
| Run command in project env | `uv run <command>` |
| Run Python directly in project env | `uv run python ...` |
| Show dependency tree | `uv tree` |
| Export lock to requirements | `uv export --format requirements.txt` |
| One-off tool execution | `uvx <tool> ...` |
| Install persistent tool | `uv tool install <tool>` |
| Install Python versions | `uv python install <version>` |
| Pin Python version | `uv python pin <version>` |
| Build distributions | `uv build` |
| Publish distributions | `uv publish` |

## Policy

- In uv-managed projects, prefer `uv add`/`uv remove`/`uv run`.
- Avoid `uv pip install` unless you are in a legacy pip-style workflow or migration scenario.
- Prefer converting workflows to uv project mode over extending pip-interface usage.

## Daily project operations

### Add, remove, and update

- Add runtime package: `uv add requests`
- Add exact/ranged constraint: `uv add 'httpx>=0.27,<1'`
- Add from Git: `uv add git+https://github.com/encode/httpx`
- Remove package: `uv remove requests`
- Upgrade one package in lockfile: `uv lock --upgrade-package requests`
- Upgrade all locked packages: `uv lock --upgrade`

### Run project commands

- Run tests: `uv run pytest`
- Run module: `uv run -m pytest`
- Run app entrypoint: `uv run python -m my_app`
- Run with temporary extra package: `uv run --with rich python script.py`
- Run one-liner with temporary dependency: `uv run --with mpmath python -c "from mpmath import mp; print(mp.pi)"`

### Ad-hoc one-liner templates

- Stdlib-only snippet: `uv run python -c "import json; print(json.dumps({'ok': True}))"`
- Third-party one-off snippet: `uv run --with <pkg> python -c "import <pkg>; ..."`
- Multi-package one-off snippet: `uv run --with <pkg1> --with <pkg2> python -c "..."`
- Promote one-off dependency to project dependency: `uv add <pkg> && uv run python -c "import <pkg>; ..."`

### Lock and sync semantics

- Check lock is current: `uv lock --check`
- Sync exact environment from lock: `uv sync`
- Sync but keep extraneous packages: `uv sync --inexact`
- Run without updating lockfile: `uv run --locked ...`
- Run without lock/env checks: `uv run --frozen --no-sync ...`

## Script operations (PEP 723)

- Initialize script metadata: `uv init --script example.py --python 3.12`
- Add script dependencies: `uv add --script example.py requests rich`
- Run script: `uv run example.py`
- Run script with one-off dependency: `uv run --with typer example.py`
- Lock script dependencies: `uv lock --script example.py`

Inline metadata block (example):

```python
# /// script
# requires-python = ">=3.12"
# dependencies = ["httpx", "rich"]
# ///
```

## Tool operations

- Ephemeral run: `uvx ruff check`
- Pin tool version: `uvx [email protected] check`
- Use different package/command name: `uvx --from httpie http --help`
- Install tool persistently: `uv tool install ruff`
- Upgrade one tool: `uv tool upgrade ruff`
- Upgrade all tools: `uv tool upgrade --all`
- Install with plugin packages: `uv tool install mkdocs --with mkdocs-material`

## Python version operations

- Install latest available Python: `uv python install`
- Install multiple versions: `uv python install 3.10 3.11 3.12`
- Install implementation variant: `uv python install [email protected]`
- List available/installed versions: `uv python list`
- Pin project interpreter: `uv python pin 3.12`
- Find compatible interpreter: `uv python find '>=3.11,<3.13'`
- Upgrade managed patch versions: `uv python upgrade` or `uv python upgrade 3.12`

## uv pip compatibility mode

Warning: this mode is fallback compatibility, not the preferred path for uv-managed projects.

- Create venv: `uv venv`
- Install package: `uv pip install flask`
- Install from requirements: `uv pip install -r requirements.txt`
- Compile lock file: `uv pip compile requirements.in -o requirements.txt`
- Compile universal requirements: `uv pip compile --universal requirements.in -o requirements.txt`
- Sync exactly to lock: `uv pip sync requirements.txt`
- Environment check: `uv pip check`

## Build and publish

- Build package: `uv build`
- Build package without sources overrides: `uv build --no-sources`
- Show current version: `uv version`
- Bump version: `uv version --bump patch`
- Publish artifacts: `uv publish`
- Publish using named index: `uv publish --index testpypi`

## Cache and performance

- Cache directory path: `uv cache dir`
- Clear all cache: `uv cache clean`
- Clear package cache: `uv cache clean ruff`
- Remove stale cache entries: `uv cache prune`
- CI-optimized prune: `uv cache prune --ci`

## Authentication and indexes

- Store credentials: `uv auth login example.com`
- Remove stored credentials: `uv auth logout example.com`
- Show token for host: `uv auth token example.com`

Example `pyproject.toml` index configuration:

```toml
[[tool.uv.index]]
name = "internal"
url = "https://example.com/simple"

[tool.uv.sources]
my-private-package = { index = "internal" }
```

Environment credentials format for named index:

- `UV_INDEX_<INDEX_NAME>_USERNAME`
- `UV_INDEX_<INDEX_NAME>_PASSWORD`

## pip to uv translation

| pip/pip-tools pattern | uv equivalent |
| --- | --- |
| `python -m venv .venv` | `uv venv` |
| `pip install <pkg>` | `uv pip install <pkg>` (legacy) or `uv add <pkg>` (project mode) |
| `pip uninstall <pkg>` | `uv pip uninstall <pkg>` |
| `pip install -r requirements.txt` | `uv pip install -r requirements.txt` |
| `pip-tools: pip-compile` | `uv pip compile` |
| `pip-tools: pip-sync` | `uv pip sync` |
| `pipx run <tool>` | `uvx <tool>` |
| `pipx install <tool>` | `uv tool install <tool>` |
| `pyenv install 3.12` | `uv python install 3.12` |

Use project mode (`uv add`/`uv lock`/`uv sync`/`uv run`) whenever `pyproject.toml` exists.
