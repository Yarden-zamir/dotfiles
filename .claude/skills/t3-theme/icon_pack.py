"""The neo-brutalism icon pack of the tick3d themes.

Each icon is a list of parts on a 24 x 24 grid: ("fill", d) is a body with a hard shadow,
("solid", d) is a solid ink shape, ("line", d) is an ink stroke. Bodies have class "nbf" and
shadows class "nbs", so the theme CSS sets their colours.

Usage:
  uv run icon_pack.py                       print the pack as JSON
  uv run icon_pack.py --write THEME.json... set the "icons" field of each theme file
"""
import json, sys

C = lambda cx, cy, r: f"M{cx-r} {cy}a{r} {r} 0 1 0 {2*r} 0a{r} {r} 0 1 0 {-2*r} 0Z"
QMARK = "M9.6 9.2a2.5 2.5 0 1 1 3.4 2.3c-.6.3-1 .8-1 1.5"

ICONS = {
  # Group icons
  "group.dot": [("fill", C(12, 12, 5))],
  "group.star": [("fill", "M12 2.5l2.9 6.1 6.6.7-5 4.5 1.5 6.7-6-3.5-6 3.5 1.5-6.7-5-4.5 6.6-.7Z")],
  "group.heart": [("fill", "M12 20.5 3.6 12A4.6 4.6 0 0 1 12 6.4 4.6 4.6 0 0 1 20.4 12Z")],
  "group.bolt": [("fill", "M13.5 2.5 4.5 13.5H11L9.5 21.5l10-12H13Z")],
  "group.flame": [("fill", "M12 2.5c3 3.5 7 6.5 7 11.5a7 7 0 0 1-14 0c0-3.5 2.5-5.5 3.5-7 .5 2.5 2 3.5 3 3.5-1-3-.5-5.5.5-8Z")],
  "group.sparkles": [("fill", "M10 3l1.8 5.2L17 10l-5.2 1.8L10 17l-1.8-5.2L3 10l5.2-1.8Z"), ("fill", "M18 14l.9 2.1 2.1.9-2.1.9L18 20l-.9-2.1L15 17l2.1-.9Z")],
  "group.rocket": [("fill", "M8 13 4.5 16.5v3L8 17.5Z"), ("fill", "M16 13l3.5 3.5v3L16 17.5Z"), ("fill", "M12 2.5c4 3 5 7.5 4 12.5H8c-1-5 0-9.5 4-12.5Z"), ("line", C(12, 9.5, 1.8)), ("line", "M10.5 18.5 12 21.5l1.5-3")],
  "group.bug": [("fill", "M9 9.5a3 3 0 0 1 6 0Z"), ("fill", "M7 9.5h10v6a5 5 0 0 1-10 0Z"), ("line", "M7 12.5H3.5M17 12.5h3.5M7 16.5l-3 2.5M17 16.5l3 2.5M12 10v10")],
  "group.wrench": [("fill", "M4 17.5 11.5 10l2.5 2.5L6.5 20Z"), ("fill", "M15 2.5a6 6 0 0 0-4 8.5l2 2a6 6 0 0 0 8.5-4L18 12l-3.5-2.5L13 6Z")],
  "group.code": [("line", "M8.5 6.5 3 12l5.5 5.5M15.5 6.5 21 12l-5.5 5.5M13.5 4l-3 16")],
  "group.terminal": [("fill", "M2.5 4.5h19v15h-19Z"), ("line", "M6.5 9 10 12l-3.5 3M12.5 15.5h5")],
  "group.bot": [("fill", "M4.5 8h15v11.5h-15Z"), ("line", "M12 8V4.5M2.5 12v3.5M21.5 12v3.5"), ("solid", "M8 11.5h2.5V14H8ZM13.5 11.5H16V14h-2.5Z"), ("solid", C(12, 3.5, 1.5))],
  "group.branch": [("line", "M6 8.5v7M18 10.5c0 3.5-6 2.5-10 6"), ("fill", C(6, 6, 2.5)), ("fill", C(6, 18, 2.5)), ("fill", C(18, 8, 2.5))],
  "group.eye": [("fill", "M2 12c3-5.5 17-5.5 20 0-3 5.5-17 5.5-20 0Z"), ("solid", C(12, 12, 3))],
  "group.clock": [("fill", C(12, 12, 9.5)), ("line", "M12 7v5l3.5 2")],
  "group.calendar": [("fill", "M3 5.5h18v15H3Z"), ("line", "M3 10h18M8 3v4M16 3v4"), ("solid", "M7 13h3v3H7Z")],
  "group.bell": [("fill", "M5 17c1.5-1.5 1.5-4 1.5-6.5a5.5 5.5 0 0 1 11 0c0 2.5 0 5 1.5 6.5Z"), ("line", "M10 20.5h4M12 2.5v2")],
  "group.flag": [("line", "M5 21.5V3"), ("fill", "M5 4h14l-3 4.5 3 4.5H5Z")],
  "group.bookmark": [("fill", "M6 3h12v18l-6-4.5L6 21Z")],
  "group.tag": [("fill", "M3 3h8.5l9.5 9.5-8.5 8.5L3 11.5Z"), ("solid", C(7.5, 7.5, 1.5))],
  "group.inbox": [("fill", "M2.5 13l3-8.5h13l3 8.5v6.5h-19Z"), ("line", "M2.5 13H8l1.5 2.5h5L16 13h5.5")],
  "group.archive": [("fill", "M4 8.5h16v12H4Z"), ("fill", "M2.5 4h19v4.5h-19Z"), ("line", "M10 12h4")],
  "group.folder": [("fill", "M2.5 5h7l2 2.5h10v12h-19Z")],
  "group.layers": [("line", "M2 16.5l10 5 10-5M2 12.5l10 5 10-5"), ("fill", "M12 3l10 5-10 5L2 8Z")],
  "group.box": [("fill", "M3 7.5 12 3l9 4.5V17l-9 4.5L3 17Z"), ("line", "M3 7.5 12 12l9-4.5M12 12v9.5")],
  "group.briefcase": [("line", "M8.5 7.5v-3h7v3"), ("fill", "M2.5 7.5h19v12h-19Z"), ("line", "M2.5 12.5h19")],
  "group.home": [("fill", "M3 10.5 12 3l9 7.5v10H3Z"), ("solid", "M9.5 20.5v-6h5v6Z")],
  "group.book": [("fill", "M4 4h7c1 0 1 1 1 2v14.5c0-1-1-1.5-2-1.5H4Z"), ("fill", "M20 4h-7c-1 0-1 1-1 2v14.5c0-1 1-1.5 2-1.5h6Z")],
  "group.globe": [("fill", C(12, 12, 9.5)), ("line", "M2.5 12h19M12 2.5c-3.5 3.5-3.5 15.5 0 19 3.5-3.5 3.5-15.5 0-19")],
  "group.cloud": [("fill", "M7 19a4.5 4.5 0 0 1-.5-9 5.5 5.5 0 0 1 10.5-1.5 5 5 0 0 1 .5 10.5Z")],
  "group.server": [("fill", "M3 3.5h18v7H3Z"), ("fill", "M3 13.5h18v7H3Z"), ("solid", C(7, 7, 1.2)), ("solid", C(7, 17, 1.2))],
  "group.database": [("fill", "M4 6a8 3 0 0 1 16 0v12a8 3 0 0 1-16 0Z"), ("line", "M4 6a8 3 0 0 0 16 0M4 12a8 3 0 0 0 16 0")],
  "group.shield": [("fill", "M12 2.5l8 3v6c0 5-3.5 8-8 10-4.5-2-8-5-8-10v-6Z")],
  # Status icons, on tabs and on thread rows
  "status.working": [("fill", C(12, 12, 9)), ("solid", "M12 12V3a9 9 0 0 1 9 9Z")],
  "status.waiting": [("fill", "M6 3h12v3.5L13 12l5 5.5V21H6v-3.5l5-5.5-5-5.5Z"), ("solid", "M9 19.5 12 16l3 3.5Z")],
  "status.approval": [("fill", "M12 2.5l8 3v6c0 5-3.5 8-8 10-4.5-2-8-5-8-10v-6Z"), ("line", QMARK), ("solid", C(12, 16.5, 1.2))],
  "status.input": [("fill", "M3 4h18v12H11l-5 4.5V16H3Z"), ("line", "M9.6 7.7a2.5 2.5 0 1 1 3.4 2.3c-.6.3-1 .8-1 1.5"), ("solid", C(12, 13.5, 1.1))],
  "status.failed": [("fill", C(12, 12, 9.5)), ("line", "M12 7v6"), ("solid", C(12, 16.5, 1.3))],
  "status.limited": [("fill", "M12 2.5l10 18H2Z"), ("line", "M12 9v5"), ("solid", C(12, 17, 1.2))],
  "status.woke": [("line", "M3.5 6l3-2.5M20.5 6l-3-2.5"), ("fill", C(12, 13, 8)), ("line", "M12 9.5V13l2.5 1.5")],
  "status.done": [("fill", C(12, 12, 9.5)), ("line", "M7.5 12.5l3 3 6-7")],
  # Tab bar buttons
  "groups.more": [("line", "M6 9.5l6 6 6-6")],
  "groups.new": [("fill", "M3.5 3.5h17v17h-17Z"), ("line", "M12 7.5v9M7.5 12h9")],
  "groups.edit": [("line", "M3 7h18M3 17h18"), ("fill", "M7.5 4.5h4v5h-4Z"), ("fill", "M13 14.5h4v5h-4Z")],
  # Sidebar header
  "sidebar.search": [("line", "M15.5 15.5 21 21"), ("fill", C(10.5, 10.5, 6.5))],
  "sidebar.filter": [("fill", "M3 4h18l-7 8.5V20l-4-2v-5.5Z")],
  "sidebar.add-project": [("fill", "M2.5 5h7l2 2.5h10v12h-19Z"), ("line", "M12 10.5v6M9 13.5h6")],
  "sidebar.new-thread": [("fill", "M15.5 3.5l5 5L9 20H4v-5Z"), ("line", "M13 6l5 5")],
}

def svg(parts):
    filled = [d for kind, d in parts if kind == "fill"]
    out = ['<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.25" stroke-linejoin="miter" stroke-linecap="square">']
    if filled:
        out.append(f'<path class="nbs" transform="translate(1.6 1.6)" fill="currentColor" stroke="none" d="{"".join(filled)}"/>')
    for kind, d in parts:
        if kind == "fill":
            out.append(f'<path class="nbf" d="{d}"/>')
        elif kind == "solid":
            out.append(f'<path fill="currentColor" stroke="none" d="{d}"/>')
        else:
            out.append(f'<path d="{d}"/>')
    out.append("</svg>")
    return "".join(out)

pack = {slot: svg(parts) for slot, parts in ICONS.items()}
for slot, value in pack.items():
    # The theme schema rejects an icon longer than 4096 characters.
    assert len(value) <= 4096, slot

if sys.argv[1:2] == ["--write"]:
    for path in sys.argv[2:]:
        with open(path) as file:
            theme = json.load(file)
        theme["icons"] = pack
        text = json.dumps(theme, indent=2, ensure_ascii=False) + "\n"
        # The server skips a theme file over 32 KB.
        assert len(text.encode()) <= 32 * 1024, f"{path} is over 32 KB"
        with open(path, "w") as file:
            file.write(text)
        print(f"{path}: {len(pack)} icons, {len(text.encode())} bytes")
else:
    json.dump(pack, sys.stdout, indent=2)
