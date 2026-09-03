"""Shared helpers for the palette plugin scripts (palette, api-run).

Stdlib only. Both scripts run with `uv run --script` from this directory,
so `import common` resolves to this file.
"""
import json
import os
import socket
import subprocess
import sys
import tomllib
from pathlib import Path

HERDR = os.environ.get("HERDR_BIN_PATH") or os.path.expanduser("~/.local/bin/herdr")
SOCK = os.environ.get("HERDR_SOCKET_PATH") or os.path.expanduser("~/.config/herdr/herdr.sock")
CONFIG_PATH = Path(os.environ.get("HERDR_CONFIG_PATH")
                   or "~/.config/herdr/config.toml").expanduser()
PLUGIN_DIR = Path(__file__).resolve().parent

# ANSI 16-color escapes so the popup follows the terminal palette (and
# with it the light/dark theme) instead of hard-coding hex colors.
DIM = "\x1b[2m"
ACCENT = "\x1b[34m"
BOLD = "\x1b[1m"
RESET = "\x1b[0m"

# herdr theme names that are light. Limit: a name match only; the
# `auto_switch` mode is ignored. Revisit if Yarden enables auto_switch.
LIGHT_THEME_HINTS = ("latte", "light", "day", "dawn", "lotus")


def herdr_config() -> dict:
    if not CONFIG_PATH.exists():
        return {}
    with CONFIG_PATH.open("rb") as fh:
        return tomllib.load(fh)


def theme_is_light(config: dict | None = None) -> bool:
    theme = (config if config is not None else herdr_config()).get("theme", {})
    name = str(theme.get("name", "")).lower()
    return any(hint in name for hint in LIGHT_THEME_HINTS)


def state_dir() -> Path:
    path = Path(os.environ.get("HERDR_PLUGIN_STATE_DIR")
                or Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache"))
                / "herdr-palette")
    path.mkdir(parents=True, exist_ok=True)
    return path


def fzf_args(prompt: str, light: bool | None = None) -> list[str]:
    """Base fzf flags shared by every picker: layout and theme colors."""
    scheme = "light" if (theme_is_light() if light is None else light) else "dark"
    return [
        "fzf", "--reverse", "--ansi", "--cycle", "--info=inline-right",
        f"--prompt={prompt} ", "--pointer=▌", "--marker=✓",
        f"--color={scheme},hl:4,hl+:4,pointer:4,prompt:4,marker:4,header:8,info:8,border:8",
    ]


def call_raw(method: str, params: dict | None) -> bytes:
    """Send one request over the socket and return the raw response line."""
    with socket.socket(socket.AF_UNIX) as sock:
        sock.connect(SOCK)
        sock.sendall((json.dumps(
            {"id": "palette", "method": method, "params": params}) + "\n").encode())
        sock.shutdown(socket.SHUT_WR)
        chunks = []
        while data := sock.recv(65536):
            chunks.append(data)
    return b"".join(chunks)


def call(method: str, params: dict | None = None) -> dict:
    """Send one request and return `result`; exit with the error message on failure."""
    parsed = json.loads(call_raw(method, params or {}))
    if error := parsed.get("error"):
        sys.exit(f"{method}: {error.get('message', error)}")
    return parsed["result"]


def cli_json(*args: str) -> dict:
    out = subprocess.run([HERDR, *args], capture_output=True, text=True, check=True)
    return json.loads(out.stdout)["result"]
