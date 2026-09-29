#!/usr/bin/env -S uv run --script --quiet
# /// script
# requires-python = ">=3.11"
# ///
"""Archive herdr panes instead of closing them.

Usage: archive.py archive|restore-last|restore-pick|clear|reap|pin-last|startup

An archived pane moves to the archive workspace (config `label`). The
process, scrollback and agent session stay alive. Each archived pane gets
its own tab, labeled "<origin space> › <pane title>". Restore moves a pane
back to its origin workspace, or recreates that workspace when the archive
move closed it (moving the last pane out of a workspace closes it).

With exit_agents_on_archive, archive first quits an idle agent (claude,
opencode, codex, copilot) with ctrl+c and saves its session id. Restore
then runs the resume command in the pane.

Stack entries key on the archive pane id (e.g. w49:p3). herdr keeps pane
ids across a server restart; terminal ids change. Entries written before
0.3.0 have no pane_id: they match no pane, so reap and restore skip them.

restore-last pops the newest entry. restore-pick runs fzf over every live
archived pane (run it inside a popup pane). clear closes the whole archive
workspace. reap closes archived panes older than `max_age_days`; archive
and startup call it. pin-last moves the archive workspace to the end of
the sidebar; the manifest calls it on workspace.created/moved and startup.

Config: $HERDR_PLUGIN_CONFIG_DIR/archive.toml (written with defaults on
first run). State: $HERDR_PLUGIN_STATE_DIR/stack.json.
"""

import json
import os
import shlex
import socket
import subprocess
import sys
import time
import tomllib
from dataclasses import dataclass
from pathlib import Path

PLUGIN_ID = "yarden.archive"
TITLE_MAX = 48
DAY_SECONDS = 86400.0

DEFAULT_CONFIG = """\
# Archive plugin (yarden.archive). Edit and rerun an action; no reload needed.

# Label of the workspace that holds archived panes.
label = "archive"

# Close archived panes older than this many days. 0 disables the reaper.
# The reaper runs on every archive action and on server startup.
max_age_days = 14

# Show herdr toasts on restore, clear, reap, and when an archived agent
# keeps running. A normal archive shows none.
toasts = true

# Focus a pane when it is restored. When false, the restore toast still
# offers a click to jump there.
focus_on_restore = true

# Quit an idle agent before its pane moves to the archive, and resume its
# session on restore. A working or blocked agent is never interrupted.
exit_agents_on_archive = true
"""


@dataclass(frozen=True)
class Config:
    label: str
    max_age_days: float
    toasts: bool
    focus_on_restore: bool
    exit_agents_on_archive: bool


def plugin_dir(env_name: str) -> Path:
    value = os.environ.get(env_name)
    if not value:
        sys.exit(f"{env_name} not set; run through herdr")
    return Path(value)


def load_config() -> Config:
    file = plugin_dir("HERDR_PLUGIN_CONFIG_DIR") / "archive.toml"
    if not file.exists():
        file.parent.mkdir(parents=True, exist_ok=True)
        file.write_text(DEFAULT_CONFIG)
    data = tomllib.loads(file.read_text())
    return Config(
        label=str(data.get("label", "archive")),
        max_age_days=float(data.get("max_age_days", 14)),
        toasts=bool(data.get("toasts", True)),
        focus_on_restore=bool(data.get("focus_on_restore", True)),
        exit_agents_on_archive=bool(data.get("exit_agents_on_archive", True)),
    )


CONFIG = load_config()


# --- socket ---------------------------------------------------------------


def request(method: str, params: dict) -> dict:
    sock_path = os.environ.get("HERDR_SOCKET_PATH")
    if not sock_path:
        sys.exit("HERDR_SOCKET_PATH not set; run through herdr")
    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    try:
        sock.connect(sock_path)
        sock.settimeout(5)
        payload = {"id": f"{PLUGIN_ID}:{method}", "method": method, "params": params}
        sock.sendall(json.dumps(payload).encode() + b"\n")
        buf = b""
        while b"\n" not in buf:
            data = sock.recv(65536)
            if not data:
                raise OSError("socket closed")
            buf += data
    finally:
        sock.close()
    reply = json.loads(buf.split(b"\n", 1)[0])
    if "error" in reply:
        raise RuntimeError(f"{method}: {reply['error']}")
    return reply["result"]


def workspaces() -> list[dict]:
    return request("workspace.list", {})["workspaces"]


def panes(workspace_id: str | None = None) -> list[dict]:
    return request("pane.list", {"workspace_id": workspace_id})["panes"]


def toast(title: str, body: str, action: dict | None = None) -> None:
    if not CONFIG.toasts:
        return
    request("notification.show", {"title": title, "body": body, "action": action})


# --- state ----------------------------------------------------------------


def state_file() -> Path:
    return plugin_dir("HERDR_PLUGIN_STATE_DIR") / "stack.json"


def load_state() -> dict:
    file = state_file()
    if not file.exists():
        return {"archive_workspace_id": None, "stack": []}
    return json.loads(file.read_text())


def save_state(state: dict) -> None:
    state_file().write_text(json.dumps(state, indent=1))


def archive_workspace(state: dict) -> dict | None:
    # Resolve by stored id first; fall back to the label when state was lost.
    live = {w["workspace_id"]: w for w in workspaces()}
    stored = state.get("archive_workspace_id")
    if stored in live:
        return live[stored]
    return next((w for w in live.values() if w["label"] == CONFIG.label), None)


def pane_title(pane: dict) -> str:
    title = pane.get("terminal_title_stripped") or pane.get("terminal_title") or ""
    if not title:
        title = Path(pane.get("cwd") or "").name or pane["pane_id"]
    return title[:TITLE_MAX]


def age_text(archived_at: float) -> str:
    hours = (time.time() - archived_at) / 3600
    if hours < 1:
        return f"{int(hours * 60)}m"
    if hours < 48:
        return f"{int(hours)}h"
    return f"{int(hours / 24)}d"


# --- agents ---------------------------------------------------------------

# Resume commands per agent, a copy of herdr src/agent_resume.rs plan().
# Limit: only these four agents. Replace this table when herdr exposes the
# resume argv on agent_session.
RESUME_ARGV = {
    "claude": lambda sid: ["claude", "--resume", sid],
    "opencode": lambda sid: ["opencode", "--session", sid],
    "codex": lambda sid: ["codex", "resume", sid],
    "copilot": lambda sid: ["copilot", f"--resume={sid}"],
}
QUIT_STATUSES = {"idle", "done"}  # never interrupt working, blocked or unknown
QUIT_ATTEMPTS = 3
QUIT_KEY_GAP = 0.3  # second ctrl+c must land inside the agent's "press again" window
QUIT_WAIT = 2.0
POLL = 0.2


def resumable_session(pane: dict) -> dict | None:
    """The pane's native agent session when herdr and RESUME_ARGV know it."""
    session = pane.get("agent_session")
    if session is None:
        return None
    agent = session["agent"]
    if agent not in RESUME_ARGV or session["kind"] != "id" or session["source"] != f"herdr:{agent}":
        return None
    return session


def shell_in_foreground(pane_id: str) -> bool:
    info = request("pane.process_info", {"pane_id": pane_id})["process_info"]
    shell_pid = info.get("shell_pid")
    if shell_pid is None:
        raise RuntimeError(f"pane {pane_id} has no shell pid")
    return info.get("foreground_process_group_id") == shell_pid


def quit_agent(pane: dict) -> bool:
    """Quit the idle agent in the pane with ctrl+c. True when the shell is back.

    The first ctrl+c clears a draft; claude, codex and copilot quit on a
    second ctrl+c; opencode quits on the first. A ctrl+c that reaches the
    shell does nothing. On timeout the agent stays alive (no kill).
    """
    pane_id = pane["pane_id"]
    if shell_in_foreground(pane_id):
        return True
    if pane.get("agent_status") not in QUIT_STATUSES:
        return False
    for _ in range(QUIT_ATTEMPTS):
        request("pane.send_keys", {"pane_id": pane_id, "keys": ["ctrl+c"]})
        time.sleep(QUIT_KEY_GAP)
        request("pane.send_keys", {"pane_id": pane_id, "keys": ["ctrl+c"]})
        deadline = time.monotonic() + QUIT_WAIT
        while time.monotonic() < deadline:
            if shell_in_foreground(pane_id):
                return True
            time.sleep(POLL)
    return False


def resume_agent(session: dict, pane_id: str) -> bool:
    """Run the resume command in the pane when its shell is in the foreground."""
    if not shell_in_foreground(pane_id):
        return False  # the agent never quit, or something else runs there
    argv = RESUME_ARGV[session["agent"]](session["value"])
    request("pane.send_input", {"pane_id": pane_id, "text": shlex.join(argv), "keys": ["Enter"]})
    return True


# --- actions --------------------------------------------------------------


def pin_last(state: dict) -> None:
    """Keep the archive workspace at the end of the sidebar."""
    target = archive_workspace(state)
    if target is None:
        return
    order = workspaces()
    if order[-1]["workspace_id"] == target["workspace_id"]:
        return
    request("workspace.move_block", {
        "workspace_ids": [target["workspace_id"]],
        "before_workspace_id": None,
    })


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
    title = pane_title(pane)
    session = resumable_session(pane)
    # Quit only a resumable agent; without a session id the conversation is lost.
    agent_alive = (CONFIG.exit_agents_on_archive and session is not None
                   and not quit_agent(pane))
    if target:
        destination = {"type": "new_tab", "workspace_id": target["workspace_id"]}
    else:
        destination = {"type": "new_workspace", "label": CONFIG.label}
    result = request("pane.move", {
        "pane_id": pane_id, "destination": destination, "focus": False,
    })["move_result"]
    moved = result["pane"]
    request("tab.rename", {
        "tab_id": moved["tab_id"], "label": f"{origin['label']} › {title}",
    })
    state["archive_workspace_id"] = moved["workspace_id"]
    state["stack"].append({
        "pane_id": moved["pane_id"],
        "origin_workspace_id": origin["workspace_id"],
        "origin_label": origin["label"],
        "title": title,
        "archived_at": time.time(),
        "agent_session": session,
    })
    save_state(state)
    pin_last(state)
    reap(state)
    # No toast for a normal archive: the pane leaves the view, and cmd+shift+t
    # restores it. Warn only when the agent keeps running in the archive.
    if agent_alive:
        toast("Archived, agent still running",
              f"{title} · {session['agent']} was {pane.get('agent_status')}")


def restore(entry: dict, pane: dict) -> None:
    live_ids = {w["workspace_id"] for w in workspaces()}
    if entry["origin_workspace_id"] in live_ids:
        destination = {"type": "new_tab", "workspace_id": entry["origin_workspace_id"]}
    else:
        destination = {"type": "new_workspace", "label": entry["origin_label"]}
    moved = request("pane.move", {
        "pane_id": pane["pane_id"], "destination": destination,
        "focus": CONFIG.focus_on_restore,
    })["move_result"]["pane"]
    title = entry.get("title") or pane_title(pane)  # entries before 0.2.0 have no title
    session = entry.get("agent_session")
    if session is not None and resume_agent(session, moved["pane_id"]):
        title = f"{title} · {session['agent']} resumed"
    # A focus_pane toast is suppressed while the pane's tab is visible, so
    # it only appears when the restore happened out of view.
    toast("Restored", f"{title} → {entry['origin_label']}",
          {"type": "focus_pane", "pane_id": moved["pane_id"]})


def archived_panes(state: dict) -> dict[str, dict]:
    """Live panes in the archive workspace, keyed by pane id."""
    target = archive_workspace(state)
    if target is None:
        return {}
    return {p["pane_id"]: p for p in panes(target["workspace_id"])}


def untracked_entry(pane: dict) -> dict:
    """Stack entry for a pane that reached the archive without this plugin."""
    return {
        "pane_id": pane["pane_id"],
        "origin_workspace_id": None,
        "origin_label": "restored",
        "title": pane_title(pane),
        "archived_at": None,
        "agent_session": None,
    }


def do_restore_last() -> None:
    state = load_state()
    archived = archived_panes(state)
    stack = state["stack"]
    while stack:
        entry = stack.pop()
        pane = archived.get(entry.get("pane_id"))
        if pane is None:
            continue  # closed from inside the archive; drop the stale entry
        save_state(state)
        restore(entry, pane)
        return
    save_state(state)
    sys.exit("archive stack empty; use restore-pick for untracked panes")


def do_restore_pick() -> None:
    """fzf over every live archived pane, newest first. Run inside a popup."""
    state = load_state()
    archived = archived_panes(state)
    if not archived:
        sys.exit("archive is empty")
    tracked = {e["pane_id"]: e for e in state["stack"] if "pane_id" in e}
    entries = [tracked.get(pid) or untracked_entry(p) for pid, p in archived.items()]
    entries.sort(key=lambda e: e["archived_at"] or 0, reverse=True)
    rows = []
    for entry in entries:
        age = age_text(entry["archived_at"]) if entry["archived_at"] else "?"
        title = entry.get("title") or pane_title(archived[entry["pane_id"]])
        rows.append(f"{entry['pane_id']}\t{age:>4}  {entry['origin_label']} › {title}")
    proc = subprocess.run(
        ["fzf", "--delimiter=\t", "--with-nth=2", "--prompt=restore > ",
         "--reverse", "--no-info"],
        input="\n".join(rows), capture_output=True, text=True,
    )
    if proc.returncode != 0:
        return  # cancelled
    pane_id = proc.stdout.split("\t", 1)[0].strip()
    entry = next(e for e in entries if e["pane_id"] == pane_id)
    state["stack"] = [e for e in state["stack"] if e.get("pane_id") != pane_id]
    save_state(state)
    restore(entry, archived[pane_id])


def reap(state: dict) -> None:
    """Close tracked archived panes older than max_age_days."""
    if CONFIG.max_age_days <= 0:
        return
    archived = archived_panes(state)
    cutoff = time.time() - CONFIG.max_age_days * DAY_SECONDS
    closed = []
    for entry in state["stack"]:
        pane = archived.get(entry.get("pane_id"))
        if pane is not None and entry["archived_at"] < cutoff:
            request("pane.close", {"pane_id": pane["pane_id"]})
            closed.append(entry)
    if not closed:
        return
    state["stack"] = [e for e in state["stack"] if e not in closed]
    save_state(state)
    toast("Archive reaped", f"{len(closed)} pane(s) older than {CONFIG.max_age_days:g} days closed")


def do_clear() -> None:
    state = load_state()
    target = archive_workspace(state)
    count = target["pane_count"] if target else 0
    if target:
        request("workspace.close", {"workspace_id": target["workspace_id"]})
    save_state({"archive_workspace_id": None, "stack": []})
    toast("Archive cleared", f"{count} pane(s) closed")


def do_reap() -> None:
    reap(load_state())


def do_pin_last() -> None:
    pin_last(load_state())


def do_startup() -> None:
    state = load_state()
    reap(state)
    pin_last(state)


ACTIONS = {
    "archive": do_archive,
    "restore-last": do_restore_last,
    "restore-pick": do_restore_pick,
    "clear": do_clear,
    "reap": do_reap,
    "pin-last": do_pin_last,
    "startup": do_startup,
}

if len(sys.argv) != 2 or sys.argv[1] not in ACTIONS:
    sys.exit(f"usage: archive.py {'|'.join(ACTIONS)}")
ACTIONS[sys.argv[1]]()
