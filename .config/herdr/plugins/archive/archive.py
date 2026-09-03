# /// script
# requires-python = ">=3.11"
# ///
"""Archive herdr panes instead of closing them.

Usage: archive.py archive|restore-last|clear

An archived pane moves to a workspace labeled "archive". The process,
scrollback and agent session stay alive. Restore moves the most recent
archived pane back to its origin workspace, or recreates that workspace
when the archive move closed it (moving the last pane out of a workspace
closes the workspace).

Limit: clear closes the whole archive workspace at once. Revisit when
manual clearing becomes a chore; then add a timed reaper on archived_at.
"""

import json
import os
import subprocess
import sys
import time
from pathlib import Path

HERDR = os.environ.get("HERDR_BIN_PATH", "herdr")
LABEL = "archive"


def herdr(*args: str) -> dict:
    proc = subprocess.run([HERDR, *args], capture_output=True, text=True)
    if proc.returncode != 0:
        sys.exit(f"herdr {' '.join(args)} failed: {proc.stderr.strip() or proc.stdout.strip()}")
    return json.loads(proc.stdout)["result"]


def state_file() -> Path:
    state_dir = os.environ.get("HERDR_PLUGIN_STATE_DIR")
    if not state_dir:
        sys.exit("HERDR_PLUGIN_STATE_DIR not set; run through herdr")
    return Path(state_dir) / "stack.json"


def load_state() -> dict:
    file = state_file()
    if not file.exists():
        return {"archive_workspace_id": None, "stack": []}
    data = json.loads(file.read_text())
    if isinstance(data, list):  # pre-id state format
        return {"archive_workspace_id": None, "stack": data}
    return data


def save_state(state: dict) -> None:
    state_file().write_text(json.dumps(state, indent=1))


def workspaces() -> list[dict]:
    return herdr("workspace", "list")["workspaces"]


def panes() -> list[dict]:
    return herdr("pane", "list")["panes"]


def archive_workspace(state: dict) -> dict | None:
    # Labels auto-revert to the pane cwd, so resolve by stored id first.
    live = {w["workspace_id"]: w for w in workspaces()}
    stored = state.get("archive_workspace_id")
    if stored in live:
        return live[stored]
    return next((w for w in live.values() if w["label"] == LABEL), None)


def current_pane_id() -> str:
    pane_id = os.environ.get("HERDR_PANE_ID") or os.environ.get("HERDR_ACTIVE_PANE_ID")
    if not pane_id:
        sys.exit("no pane context (HERDR_PANE_ID/HERDR_ACTIVE_PANE_ID unset)")
    return pane_id


def do_archive() -> None:
    pane_id = current_pane_id()
    pane = next((p for p in panes() if p["pane_id"] == pane_id), None)
    if pane is None:
        sys.exit(f"pane {pane_id} not found")
    state = load_state()
    target = archive_workspace(state)
    if target and pane["workspace_id"] == target["workspace_id"]:
        return
    origin = next(w for w in workspaces() if w["workspace_id"] == pane["workspace_id"])
    if target:
        result = herdr(
            "pane", "move", pane_id,
            "--new-tab", "--workspace", target["workspace_id"], "--no-focus",
        )
    else:
        result = herdr(
            "pane", "move", pane_id,
            "--new-workspace", "--label", LABEL, "--no-focus",
        )
    moved = result["move_result"]["pane"]
    state["archive_workspace_id"] = moved["workspace_id"]
    state["stack"].append({
        "terminal_id": moved["terminal_id"],
        "origin_workspace_id": origin["workspace_id"],
        "origin_label": origin["label"],
        "archived_at": time.time(),
    })
    save_state(state)


def do_restore_last() -> None:
    state = load_state()
    target = archive_workspace(state)
    if target is None:
        sys.exit("no archive workspace")
    stack = state["stack"]
    archived = {
        p["terminal_id"]: p
        for p in panes()
        if p["workspace_id"] == target["workspace_id"]
    }
    while stack:
        entry = stack.pop()
        pane = archived.get(entry["terminal_id"])
        if pane is None:
            continue  # closed from inside the archive; skip the stale entry
        live_ids = {w["workspace_id"] for w in workspaces()}
        if entry["origin_workspace_id"] in live_ids:
            herdr(
                "pane", "move", pane["pane_id"],
                "--new-tab", "--workspace", entry["origin_workspace_id"], "--focus",
            )
        else:
            herdr(
                "pane", "move", pane["pane_id"],
                "--new-workspace", "--label", entry["origin_label"], "--focus",
            )
        save_state(state)
        return
    save_state(state)
    sys.exit("archive stack empty; restore untracked panes by hand from the archive workspace")


def do_clear() -> None:
    state = load_state()
    target = archive_workspace(state)
    if target:
        herdr("workspace", "close", target["workspace_id"])
    save_state({"archive_workspace_id": None, "stack": []})


ACTIONS = {"archive": do_archive, "restore-last": do_restore_last, "clear": do_clear}

if len(sys.argv) != 2 or sys.argv[1] not in ACTIONS:
    sys.exit("usage: archive.py archive|restore-last|clear")
ACTIONS[sys.argv[1]]()
