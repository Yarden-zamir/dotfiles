#!/usr/bin/env -S uv run --script --quiet
# /// script
# requires-python = ">=3.11"
# ///
"""Contract tests for the archive plugin against a fake herdr socket.

Usage: tests/herdr-archive-fake.py

Runs archive.py as herdr does (env vars, one action per process) with
HERDR_SOCKET_PATH on a fake server in a temp dir. Never touches the live
herdr server. The fake models only the socket methods archive.py calls.
"""

import json
import os
import socketserver
import subprocess
import sys
import tempfile
import threading
import time
from pathlib import Path

ARCHIVE = Path(__file__).resolve().parent.parent / ".config/herdr/plugins/archive/archive.py"
SID = "0549b90f-59a5-4c54-ac78-b98f2e19887a"


class FakeHerdr:
    """Workspaces and panes, plus a log of keys, input and toasts."""

    def __init__(self) -> None:
        self.workspaces: list[dict] = [{"workspace_id": "w1", "label": "work"}]
        self.panes: dict[str, dict] = {}
        self.next_pane = 1
        self.keys: list[tuple[str, str]] = []
        self.inputs: list[tuple[str, str, list[str]]] = []
        self.toasts: list[str] = []
        self.closed: list[str] = []

    def add_pane(self, workspace_id: str, **agent) -> str:
        pane_id = f"{workspace_id}:p{self.next_pane}"
        self.next_pane += 1
        self.panes[pane_id] = {
            "pane_id": pane_id, "terminal_id": f"term_{pane_id}", "workspace_id": workspace_id,
            "tab_id": f"{workspace_id}:t{self.next_pane}", "cwd": "/tmp/repo",
            "agent_status": "unknown", "shell_pid": 100, "fg": 100, "ctrl_c_to_quit": 0,
            **agent,
        }
        return pane_id

    def public(self, pane: dict) -> dict:
        return {k: v for k, v in pane.items() if k not in ("shell_pid", "fg", "ctrl_c_to_quit")}

    def handle(self, method: str, params: dict) -> dict:
        match method:
            case "workspace.list":
                for w in self.workspaces:
                    w["pane_count"] = sum(p["workspace_id"] == w["workspace_id"] for p in self.panes.values())
                return {"workspaces": self.workspaces}
            case "pane.list":
                wid = params.get("workspace_id")
                return {"panes": [self.public(p) for p in self.panes.values()
                                  if wid is None or p["workspace_id"] == wid]}
            case "pane.move":
                return {"move_result": {"pane": self.public(self.move(params))}}
            case "pane.process_info":
                p = self.panes[params["pane_id"]]
                return {"process_info": {"pane_id": p["pane_id"], "shell_pid": p["shell_pid"],
                                         "foreground_process_group_id": p["fg"]}}
            case "pane.send_keys":
                p = self.panes[params["pane_id"]]
                for key in params["keys"]:
                    self.keys.append((p["pane_id"], key))
                    if key == "ctrl+c" and p["fg"] != p["shell_pid"] and p["ctrl_c_to_quit"] > 0:
                        p["ctrl_c_to_quit"] -= 1
                        if p["ctrl_c_to_quit"] == 0:
                            p.update(fg=p["shell_pid"], agent=None, agent_status="unknown",
                                     agent_session=None)
                return {}
            case "pane.send_input":
                self.inputs.append((params["pane_id"], params["text"], params["keys"]))
                return {}
            case "pane.close":
                self.closed.append(params["pane_id"])
                del self.panes[params["pane_id"]]
                return {}
            case "notification.show":
                self.toasts.append(f"{params['title']}: {params['body']}")
                return {}
            case "tab.rename" | "workspace.move_block":
                return {}
        raise AssertionError(f"fake herdr: unexpected method {method}")

    def move(self, params: dict) -> dict:
        old = self.panes.pop(params["pane_id"])
        dest = params["destination"]
        if dest["type"] == "new_workspace":
            wid = f"w{len(self.workspaces) + 1}"
            self.workspaces.append({"workspace_id": wid, "label": dest["label"]})
        else:
            wid = dest["workspace_id"]
        # herdr closes a workspace when its last pane moves out.
        if not any(p["workspace_id"] == old["workspace_id"] for p in self.panes.values()):
            self.workspaces = [w for w in self.workspaces if w["workspace_id"] != old["workspace_id"]]
        new_id = f"{wid}:p{self.next_pane}"
        self.next_pane += 1
        pane = {**old, "pane_id": new_id, "workspace_id": wid, "tab_id": f"{wid}:t{self.next_pane}"}
        self.panes[new_id] = pane
        return pane


def serve(fake: FakeHerdr, sock_path: str) -> socketserver.UnixStreamServer:
    class Handler(socketserver.StreamRequestHandler):
        def handle(self) -> None:
            req = json.loads(self.rfile.readline())
            try:
                reply = {"id": req["id"], "result": fake.handle(req["method"], req["params"])}
            except Exception as err:  # the plugin sees it as an API error
                reply = {"id": req["id"], "error": {"code": "fake", "message": str(err)}}
            self.wfile.write(json.dumps(reply).encode() + b"\n")

    server = socketserver.UnixStreamServer(sock_path, Handler)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    return server


class Env:
    """One fake server plus plugin config and state dirs."""

    def __init__(self, config: str = "") -> None:
        self.dir = Path(tempfile.mkdtemp(prefix="arch-"))
        (self.dir / "config").mkdir()
        (self.dir / "state").mkdir()
        (self.dir / "config/archive.toml").write_text(
            'label = "archive"\nmax_age_days = 14\ntoasts = true\nfocus_on_restore = false\n' + config)
        self.fake = FakeHerdr()
        self.server = serve(self.fake, str(self.dir / "s.sock"))

    def run(self, action: str, pane_id: str | None = None) -> None:
        env = {**os.environ, "HERDR_SOCKET_PATH": str(self.dir / "s.sock"),
               "HERDR_PLUGIN_CONFIG_DIR": str(self.dir / "config"),
               "HERDR_PLUGIN_STATE_DIR": str(self.dir / "state")}
        env.pop("HERDR_PANE_ID", None)
        env.pop("HERDR_ACTIVE_PANE_ID", None)
        if pane_id:
            env["HERDR_PANE_ID"] = pane_id
        proc = subprocess.run(["uv", "run", "--script", "--quiet", str(ARCHIVE), action],
                              env=env, capture_output=True, text=True, timeout=60)
        assert proc.returncode == 0, f"{action} failed: {proc.stderr}"

    def stack(self) -> list[dict]:
        return json.loads((self.dir / "state/stack.json").read_text())["stack"]

    def close(self) -> None:
        self.server.shutdown()
        self.server.server_close()


def claude(status: str, ctrl_c_to_quit: int) -> dict:
    session = {"source": "herdr:claude", "agent": "claude", "kind": "id", "value": SID}
    return {"agent": "claude", "agent_status": status, "agent_session": session,
            "fg": 200, "ctrl_c_to_quit": ctrl_c_to_quit}


def test_idle_agent_quits_and_resumes() -> None:
    env = Env()
    pane = env.fake.add_pane("w1", **claude("idle", ctrl_c_to_quit=2))
    env.fake.add_pane("w1")  # keep the origin workspace alive
    env.run("archive", pane)
    [entry] = env.stack()
    archived = env.fake.panes[entry["pane_id"]]
    assert archived["fg"] == archived["shell_pid"], "agent still in foreground"
    assert entry["agent_session"]["value"] == SID
    assert [k for _, k in env.fake.keys] == ["ctrl+c", "ctrl+c"]
    assert env.fake.toasts == [], "a normal archive posts no toast"

    env.run("restore-last")
    assert env.stack() == []
    [(pane_id, text, keys)] = env.fake.inputs
    assert env.fake.panes[pane_id]["workspace_id"] == "w1"
    assert text == f"claude --resume {SID}" and keys == ["Enter"]
    env.close()


def test_working_agent_is_not_interrupted() -> None:
    env = Env()
    pane = env.fake.add_pane("w1", **claude("working", ctrl_c_to_quit=2))
    env.fake.add_pane("w1")
    env.run("archive", pane)
    assert env.fake.keys == []
    assert env.fake.toasts[-1].startswith("Archived, agent still running")
    env.run("restore-last")
    assert env.fake.inputs == [], "resume typed into a live agent"
    env.close()


def test_stubborn_agent_stays_alive() -> None:
    env = Env()
    pane = env.fake.add_pane("w1", **claude("idle", ctrl_c_to_quit=99))
    env.run("archive", pane)
    assert len(env.fake.keys) == 6  # 3 attempts, 2 keys each
    [entry] = env.stack()
    assert env.fake.panes[entry["pane_id"]]["agent"] == "claude"
    env.close()


def test_agent_without_session_is_left_alive() -> None:
    env = Env()
    agent = {**claude("idle", ctrl_c_to_quit=2), "agent_session": None}
    pane = env.fake.add_pane("w1", **agent)
    env.run("archive", pane)
    assert env.fake.keys == []
    env.close()


def test_knob_off_leaves_agent() -> None:
    env = Env("exit_agents_on_archive = false\n")
    pane = env.fake.add_pane("w1", **claude("idle", ctrl_c_to_quit=2))
    env.run("archive", pane)
    assert env.fake.keys == []
    env.close()


def test_entries_survive_terminal_id_change() -> None:
    # A server restart renumbers terminal ids and keeps pane ids.
    env = Env()
    pane = env.fake.add_pane("w1")
    env.fake.add_pane("w1")
    env.run("archive", pane)
    for p in env.fake.panes.values():
        p["terminal_id"] = "term_new_" + p["pane_id"]
    env.run("restore-last")
    assert env.stack() == []
    assert env.fake.toasts[-1].startswith("Restored")
    env.close()


def test_reap_closes_old_entries_and_skips_legacy() -> None:
    env = Env()
    pane = env.fake.add_pane("w1")
    env.fake.add_pane("w1")
    env.run("archive", pane)
    state_file = env.dir / "state/stack.json"
    state = json.loads(state_file.read_text())
    state["stack"][0]["archived_at"] = time.time() - 15 * 86400
    state["stack"].insert(0, {"terminal_id": "term_gone", "origin_workspace_id": "w1",
                              "origin_label": "work", "title": "old", "archived_at": 0})
    state_file.write_text(json.dumps(state))
    archived_pane = state["stack"][1]["pane_id"]
    env.run("reap")
    assert env.fake.closed == [archived_pane]
    assert [e.get("terminal_id") for e in env.stack()] == ["term_gone"]
    env.close()


if __name__ == "__main__":
    tests = [(n, f) for n, f in sorted(globals().items()) if n.startswith("test_")]
    for name, test in tests:
        test()
        print(f"ok {name}")
    print(f"ok {len(tests)} tests")
    sys.exit(0)
