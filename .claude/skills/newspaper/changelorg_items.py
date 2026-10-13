"""Write a newspaper items file from changelorg, through the changelorg CLI and its agent access.

Usage: changelorg_items.py OUT.json [DAYS]

Every changelorg profile becomes one section. DAYS defaults to 7. The CLI must be signed in; see the changelorg skill.
"""

import json
import subprocess
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path
from urllib.parse import quote

CLI = ["uvx", "--from", "git+https://github.com/Yarden-zamir/changeLorg", "changelorg"]
HOME = "https://changelorg.yarden-zamir.com/"
LIMIT = 500


def api(path: str):
    result = subprocess.run([*CLI, "api", path], capture_output=True, text=True)
    if result.returncode != 0:
        sys.exit(f"changelorg api {path} failed: {result.stderr.strip() or result.stdout.strip()}")
    return json.loads(result.stdout)


def window(profile: str, start: datetime, end: datetime) -> list[dict]:
    """A full page means a cut window, so split it in halves."""
    rows = api(f"/changes?profile={quote(profile)}&since={quote(start.isoformat())}&until={quote(end.isoformat())}"
               f"&include_dismissed=true&limit={LIMIT}")
    if not isinstance(rows, list):
        sys.exit("/changes did not return a list")
    if len(rows) < LIMIT:
        return rows
    middle = start + (end - start) / 2
    return window(profile, start, middle) + window(profile, middle, end)


def kind(source_name: str) -> str:
    # changelorg has no source type field, so the source name decides. Revisit when sources get a type,
    # or when a release feed or a status page does not follow the "... Releases" or "... Status" name.
    if source_name.endswith("Releases"):
        return "release"
    if source_name.endswith("Status"):
        return "status"
    return "article"


def main() -> None:
    if len(sys.argv) not in (2, 3):
        sys.exit(__doc__)
    out, days = Path(sys.argv[1]), int(sys.argv[2]) if len(sys.argv) == 3 else 7
    now = datetime.now(timezone.utc).astimezone()
    profiles = api("/profiles")
    if not isinstance(profiles, list) or not all(isinstance(p, dict) and "name" in p for p in profiles):
        sys.exit("unexpected /profiles response")
    items = []
    for profile in profiles:
        for row in window(profile["name"], now - timedelta(days=days), now):
            items.append({
                "id": str(row["id"]), "section": profile["name"], "title": row["title"], "url": row.get("url"),
                "summary": row.get("summary") or row.get("content") or "", "published_at": row["published_at"],
                "source": row["source_name"], "kind": kind(row["source_name"]),
                "read": bool(row.get("dismissed")), "saved": bool(row.get("saved")),
            })
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps({"fetched": now.isoformat(), "days": days, "home": HOME, "items": items}, indent=1))
    counts = {p["name"]: sum(item["section"] == p["name"] for item in items) for p in profiles}
    print(f"wrote {out}: {counts}")


if __name__ == "__main__":
    main()
