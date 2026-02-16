# uv troubleshooting

## Quick diagnosis grid

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| `uv run --locked` fails with lockfile out of date | `pyproject.toml` changed without lock refresh | Run `uv lock` (or `uv sync`) and commit `uv.lock` |
| Command runs but imports wrong versions | Extraneous packages in env with inexact sync | Run `uv sync` (exact) or `uv run --exact ...` |
| `ModuleNotFoundError` in project command | Dependency not declared in project | Add with `uv add <pkg>` then rerun via `uv run ...` |
| `ModuleNotFoundError` in `uv run python -c ...` snippet | Third-party import missing from one-off execution environment | Re-run with `uv run --with <pkg> python -c ...`; if persistent, use `uv add <pkg>` |
| Package works locally but team/CI misses it | Installed with `uv pip install` so dependency was not recorded in `pyproject.toml` | Re-add using `uv add <pkg>`, regenerate lock (`uv lock`), sync (`uv sync`) |
| `uv pip install` complains about missing environment | No active/discovered venv | Create one with `uv venv` or use `--system` (only where appropriate) |
| Private index package not found | Credentials missing or wrong index pinning | Verify `[[tool.uv.index]]`, auth env vars, and `tool.uv.sources` pin |
| `uvx` tool cannot import project package | `uvx` runs isolated tool env | Use `uv run <tool>` instead of `uvx` |
| Tool executable not found after install | Tool bin dir not on PATH | Run `uv tool update-shell` or set `UV_TOOL_BIN_DIR` |
| Build fails under isolation (`PEP 517`) | Missing build dependency in package metadata | Prefer `tool.uv.extra-build-dependencies` before disabling isolation |
| Git dependency auth fails | Missing SSH key/credential helper | Use SSH URL or configure helper (`gh auth login`, `gh auth setup-git`) |
| TLS/certificate errors in enterprise network | Corporate CA not trusted by bundled roots | Use `--native-tls`/`UV_NATIVE_TLS=true` or set `SSL_CERT_FILE` |
| `uv` resolves old versions unexpectedly | Existing lock/output file acts as preference | Use `--upgrade` / `--upgrade-package` intentionally |
| Pre-release package rejected | Default prerelease policy is strict | Add explicit prerelease specifier or use `--prerelease allow` |

## Dependency resolution failures

When resolution fails, follow this order:

1. Inspect incompatible ranges in error output.
2. Tighten direct dependency constraints (`uv add '<pkg><range>'`).
3. If conflict is valid and unavoidable, declare explicit conflicts in `[tool.uv.conflicts]` for extras/groups.
4. Use constraints for narrowing (`--constraint`) or overrides only as a last resort (`--override` / `tool.uv.override-dependencies`).

Use overrides cautiously: they can produce runtime breakage even when resolution succeeds.

## Lock and sync confusion

Key behaviors to remember:

- `uv sync` is exact by default (removes extraneous packages).
- `uv run` is inexact by default (keeps extraneous packages).
- `--locked` means "do not update lockfile" and fail if stale.
- `--frozen` means "trust lockfile as-is" and skip freshness check.
- `--no-sync` skips environment update checks and can run stale environments.

## Build isolation strategies

Preferred strategy:

1. Keep build isolation on.
2. Add missing build dependencies via `tool.uv.extra-build-dependencies`.
3. Use `match-runtime = true` where package metadata supports it.

Fallback strategy:

1. Mark package under `tool.uv.no-build-isolation-package`.
2. Ensure required build dependencies are explicitly installed first.

Avoid global `--no-build-isolation` unless there is no practical alternative.

## Index and auth failures

Checklist:

1. Confirm index name and URL in `[[tool.uv.index]]`.
2. Confirm package pinning in `[tool.uv.sources]` when required.
3. Confirm credential source order and values:
   - URL credentials
   - `.netrc`
   - uv auth store
   - keyring provider (if enabled)
4. If an index proxies to PyPI for unauthenticated requests, set `authenticate = "always"`.
5. Keep secure default strategy (`first-index`) unless there is an explicit need to change.

## Script mode pitfalls

- PEP 723 script metadata requires `dependencies = []` even when empty.
- Scripts with inline metadata run isolated from project dependencies.
- Use `uv run --no-project` for local scripts in project directories when project install is not needed.

## Ad-hoc snippet pitfalls (`uv run python -c`)

- Third-party imports are not auto-installed.
- Use `--with` for one-off snippet dependencies.
- If a snippet becomes recurring, move dependency to project with `uv add`.

## Docker and CI pitfalls

- Do not copy local `.venv` into images; build env inside container.
- Use cache mounts and `UV_LINK_MODE=copy` to avoid hard-link warnings across filesystems.
- In CI, prefer:
  - `uv sync --locked`
  - `uv run ...`
  - `uv cache prune --ci` after job steps

## Legacy migration pitfalls

- `uv` does not read `pip.conf` or `PIP_*` variables. Replace with `UV_*` or uv config files.
- `uv pip` requires venv by default; use `--system` only in controlled contexts.
- Using `uv pip install` in uv-managed projects bypasses project dependency declarations; prefer `uv add`.
- Multi-platform requirements from pip-tools may need marker normalization before import into universal lock workflows.

## Anti-pattern: `uv pip install` in uv projects

- Symptom: dependency is available in one environment but absent in other machines or CI.
- Root cause: package was installed imperatively, not declared in project metadata.
- Corrective action: model dependency declaratively with `uv add`, then lock and sync.
