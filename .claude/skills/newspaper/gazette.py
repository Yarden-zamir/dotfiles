"""Render a tick3d newspaper page from an items file and a picks file.

Usage: gazette.py ITEMS.json PICKS.json OUT.html

ITEMS holds the raw news items. PICKS holds the editorial choices: editions, lead, side stories, flow and boxes.
Each item appears in one place only. A second use of an item, an unknown item id or a generic image stops the build.
SKILL.md next to this file describes both file formats.
"""

import html
import json
import sys
from collections import Counter
from dataclasses import dataclass
from datetime import datetime, timedelta
from html.parser import HTMLParser
from pathlib import Path
from typing import Literal, get_args

type Kind = Literal["article", "release", "status"]
type BoxKind = Literal["weather", "classifieds", "corrections", "blotter", "overheard", "wire", "prolific"]

# Logos, share cards and house illustrations say nothing about a story. A picked image with one of these markers stops the build.
GENERIC_IMAGE_MARKERS = ("generic-", "social-v3-", "steam_share_image", "arc-raiders-social", "opengraph.githubassets.com", "/og/")


# ---------- input ----------

def fail(message: str) -> None:
    sys.exit(f"gazette: {message}")


def keys(data: object, where: str, required: set[str], optional: set[str] = frozenset()) -> dict:
    if not isinstance(data, dict):
        fail(f"{where} must be an object, not {type(data).__name__}")
    missing, unknown = required - data.keys(), data.keys() - required - optional
    if missing or unknown:
        fail(f"{where}: missing keys {sorted(missing)}, unknown keys {sorted(unknown)}")
    return data


def text(data: dict, key: str, where: str, default: str | None = None) -> str | None:
    value = data.get(key, default)
    if value is not None and not isinstance(value, str):
        fail(f"{where}.{key} must be text")
    return value


@dataclass(frozen=True)
class Item:
    id: str
    section: str
    title: str
    url: str | None
    summary: str
    published_at: datetime
    source: str
    kind: Kind
    read: bool
    saved: bool
    bonus: bool


@dataclass(frozen=True)
class Story:
    item: str
    kicker: str
    headline: str | None
    deck: str | None
    tag: str | None
    also: tuple[str, ...]
    image: str | None


@dataclass(frozen=True)
class Lead:
    story: Story
    body: str
    facts: tuple[tuple[str, str], ...]


@dataclass(frozen=True)
class Row:
    head: str
    text: str
    item: str


@dataclass(frozen=True)
class Box:
    kind: BoxKind
    title: str
    note: str | None
    rows: tuple[Row, ...]


@dataclass(frozen=True)
class Edition:
    section: str
    title: str
    banner: str
    lead: Lead
    side: tuple[Story, ...]
    quote: Row | None  # head is the quote, text is the credit.
    dates: tuple[Row, ...]  # head is the day, text is the event.
    flow: tuple[Story | Box, ...]


@dataclass(frozen=True)
class Number:
    value: str
    label: str
    tip: str
    href: str


@dataclass(frozen=True)
class Picks:
    title: str
    issue: str
    motto: str
    word: str | None
    colophon: str
    previous: str | None
    numbers: tuple[Number, ...]
    editions: tuple[Edition, ...]


STORY_KEYS = {"kicker", "headline", "deck", "tag", "also", "image"}


def load_items(path: Path) -> tuple[datetime, int, str | None, list[Item]]:
    data = keys(json.loads(path.read_text()), "items file", {"fetched", "days", "items"}, {"home"})
    items = []
    for index, raw in enumerate(data["items"]):
        where = f"items[{index}]"
        raw = keys(raw, where, {"id", "section", "title", "url", "summary", "published_at", "source", "kind"}, {"read", "saved", "bonus"})
        if raw["kind"] not in get_args(Kind.__value__):
            fail(f"{where}.kind must be one of {get_args(Kind.__value__)}")
        url = text(raw, "url", where)
        items.append(Item(
            id=str(raw["id"]), section=text(raw, "section", where), title=text(raw, "title", where),
            url=url if url and url.startswith(("https://", "http://")) else None,
            summary=text(raw, "summary", where) or "", published_at=datetime.fromisoformat(raw["published_at"]).astimezone(),
            source=text(raw, "source", where), kind=raw["kind"], read=bool(raw.get("read")), saved=bool(raw.get("saved")),
            bonus=bool(raw.get("bonus")),
        ))
    ids = Counter(item.id for item in items)
    if doubles := [item_id for item_id, count in ids.items() if count > 1]:
        fail(f"items file repeats ids {doubles[:5]}")
    return datetime.fromisoformat(data["fetched"]).astimezone(), int(data["days"]), text(data, "home", "items file"), items


def story(raw: object, where: str, extra: set[str] = frozenset()) -> Story:
    raw = keys(raw, where, {"item"}, STORY_KEYS | extra)
    image = text(raw, "image", where)
    if image and (not image.startswith("https://") or any(marker in image for marker in GENERIC_IMAGE_MARKERS)):
        fail(f"{where}.image is not a specific https image: {image}")
    return Story(item=str(raw["item"]), kicker=text(raw, "kicker", where, ""), headline=text(raw, "headline", where),
                 deck=text(raw, "deck", where), tag=text(raw, "tag", where),
                 also=tuple(str(extra_id) for extra_id in raw.get("also", ())), image=image)


def row(raw: object, where: str, head: str, body: str) -> Row:
    raw = keys(raw, where, {head, body, "item"})
    return Row(head=text(raw, head, where), text=text(raw, body, where), item=str(raw["item"]))


def load_picks(path: Path) -> Picks:
    data = keys(json.loads(path.read_text()), "picks file", {"title", "issue", "motto", "colophon", "editions"},
                {"word", "previous", "numbers"})
    editions = []
    for index, raw in enumerate(data["editions"]):
        where = f"editions[{index}]"
        raw = keys(raw, where, {"section", "title", "banner", "lead", "flow"}, {"side", "quote", "dates"})
        lead_raw = keys(raw["lead"], f"{where}.lead", {"item", "body"}, STORY_KEYS | {"facts"})
        facts = tuple((str(value), str(label)) for value, label in lead_raw.get("facts", ()))
        flow: list[Story | Box] = []
        for position, part in enumerate(raw["flow"]):
            part_where = f"{where}.flow[{position}]"
            if isinstance(part, dict) and "box" in part:
                part = keys(part, part_where, {"box", "title"}, {"note", "rows"})
                if part["box"] not in get_args(BoxKind.__value__):
                    fail(f"{part_where}.box must be one of {get_args(BoxKind.__value__)}")
                rows = tuple(row(item, f"{part_where}.rows[{n}]", "head", "text") for n, item in enumerate(part.get("rows", ())))
                if part["box"] != "prolific" and not rows:
                    fail(f"{part_where} needs rows")
                flow.append(Box(kind=part["box"], title=part["title"], note=text(part, "note", part_where), rows=rows))
            else:
                flow.append(story(part, part_where))
        editions.append(Edition(
            section=raw["section"], title=raw["title"], banner=raw["banner"],
            lead=Lead(story=story({k: v for k, v in lead_raw.items() if k not in ("body", "facts")}, f"{where}.lead"),
                      body=lead_raw["body"], facts=facts),
            side=tuple(story(item, f"{where}.side[{n}]") for n, item in enumerate(raw.get("side", ()))),
            quote=row(raw["quote"], f"{where}.quote", "text", "credit") if raw.get("quote") else None,
            dates=tuple(row(item, f"{where}.dates[{n}]", "day", "text") for n, item in enumerate(raw.get("dates", ()))),
            flow=tuple(flow),
        ))
    numbers = tuple(Number(**keys(raw, f"numbers[{n}]", {"value", "label", "tip", "href"})) for n, raw in enumerate(data.get("numbers", ())))
    return Picks(title=data["title"], issue=data["issue"], motto=data["motto"], word=text(data, "word", "picks file"),
                 colophon=data["colophon"], previous=text(data, "previous", "picks file"), numbers=numbers, editions=tuple(editions))


# ---------- helpers ----------

class _Text(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.parts: list[str] = []

    def handle_data(self, data: str) -> None:
        self.parts.append(data)


def plain(raw: str) -> str:
    parser = _Text()
    parser.feed(raw or "")
    return " ".join(" ".join(parser.parts).split())


def e(value: object) -> str:
    return html.escape(str(value), quote=True)


def tip(item: Item) -> str:
    bonus = "Bonus pick, not from your feed. " if item.bonus else ""
    return f"{bonus}{item.source}: {item.title}"


def a(item: Item, label: str, cls: str = "", note: str | None = None) -> str:
    """Link to the source item. The hover note names the source and its original headline, unless a note is given."""
    klass = f' class="{cls}"' if cls else ""
    if not item.url:
        return f'<span{klass} title="{e(note or tip(item))}">{e(label)}</span>'
    return f'<a{klass} href="{e(item.url)}" title="{e(note or tip(item))}" target="_blank" rel="noopener">{e(label)}</a>'


def clean_title(item: Item) -> str:
    """Release feeds often prefix titles with the repository name: 'uv - uv 0.13.0 ...'."""
    prefix, sep, rest = item.title.partition(" - ")
    return rest if sep and item.kind == "release" and " " not in prefix else item.title


def plural(count: int, word: str) -> str:
    return f"{count} {word}" + ("" if count == 1 else "s")


# ---------- render ----------

class Paper:
    def __init__(self, fetched: datetime, days: int, home: str | None, items: list[Item]) -> None:
        self.fetched, self.days, self.home = fetched, days, home
        self.sections: dict[str, list[Item]] = {}
        for item in sorted(items, key=lambda item: item.published_at, reverse=True):
            self.sections.setdefault(item.section, []).append(item)
        self.by_id = {item.id: item for item in items}
        self.used: set[str] = set()

    def use(self, item_id: str) -> Item:
        """Take an item for one place on the page. A second use is a duplicate and stops the build."""
        if item_id not in self.by_id:
            fail(f"picked item {item_id!r} is not in the items file")
        if item_id in self.used:
            fail(f"item {item_id!r} ({self.by_id[item_id].title}) is picked twice. Keep each item in one place.")
        self.used.add(item_id)
        return self.by_id[item_id]

    def date(self, item: Item) -> str:
        today = item.published_at.date() == self.fetched.date()
        return (f'<span class="sticker {"info" if today else ""}" title="Published {item.published_at:%A %d %B, %H:%M}">'
                f'{item.published_at:%d %b}</span>')

    @staticmethod
    def marks(item: Item) -> str:
        read = '<span class="stamp" title="You cleared this from your desk">✓ read</span>' if item.read else ""
        bonus = '<span class="sticker bonus" title="Bonus pick from outside your feed">Bonus</span>' if item.bonus else ""
        return bonus + read

    @staticmethod
    def figure(item: Item, url: str | None, cls: str = "") -> str:
        if not url:
            return ""
        return (f'<figure class="photo {cls}"><img src="{e(url)}" alt="" loading="lazy" referrerpolicy="no-referrer">'
                f'<figcaption>Image: {e(item.source)}</figcaption></figure>')

    def also(self, story: Story, main: Item) -> str:
        """Extra sources of a story. Name the source, or the headline when the source repeats."""
        parts = []
        for extra_id in story.also:
            item = self.use(extra_id)
            parts.append(f' · {a(item, item.source if item.source != main.source else clean_title(item))}')
        return "".join(parts)

    def card(self, story: Story) -> str:
        item = self.use(story.item)
        tag = f'<span class="sticker warn">{e(story.tag)}</span>' if story.tag else ""
        return f"""<article class="card story">{self.figure(item, story.image)}
          <div class="pad"><div class="meta">{self.date(item)}<span class="label">{e(story.kicker)}</span>{tag}{self.marks(item)}</div>
          <h3>{a(item, story.headline or clean_title(item))}</h3>
          {f'<p class="deck">{e(story.deck)}</p>' if story.deck else ""}
          <p class="src">{e(item.source)}{self.also(story, item)}</p></div></article>"""

    @staticmethod
    def box_head(box: Box) -> str:
        note = f'<p class="note">{e(box.note)}</p>' if box.note else ""
        return f"<header><h2>{e(box.title)}</h2>{note}</header>"

    def box(self, box: Box, section: str) -> str:
        if box.kind == "prolific":
            counts = Counter(item.source for item in self.sections[section] if item.kind == "article").most_common(6)
            peak = counts[0][1] if counts else 1
            rows = "".join(
                f'<li><span class="name" title="{count} items from {e(name)} in {self.days} days">{e(name)}</span>'
                f'<span class="bar" style="--w:{count / peak:.3f}"></span><b>{count}</b></li>'
                for name, count in counts)
            return f'<section class="card box prolific">{self.box_head(box)}<ol>{rows}</ol></section>'
        rows = "".join(
            f'<li><span class="{"sticker wait" if box.kind == "classifieds" else "label"}">{e(line.head)}</span> '
            f'{a(self.use(line.item), line.text)}</li>'
            for line in box.rows)
        return f'<section class="card box {e(box.kind)}">{self.box_head(box)}<ul>{rows}</ul></section>'

    def lead(self, lead: Lead) -> str:
        story = lead.story
        item = self.use(story.item)
        also = "".join(f' · {a(extra, clean_title(extra))}' for extra in map(self.use, story.also))
        facts = "".join(f"<div><b>{e(value)}</b><span>{e(label)}</span></div>" for value, label in lead.facts)
        top = self.figure(item, story.image, "fill") or (f'<div class="facts">{facts}</div>' if facts else "")
        return f"""<article class="card lead">{top}
          <span class="stamp extra" title="The biggest story of the edition, as picked by the agent">Extra!</span>
          <div class="pad"><div class="meta">{self.date(item)}<span class="label">{e(story.kicker)}</span>{self.marks(item)}</div>
          <h3>{a(item, story.headline or clean_title(item))}</h3>
          {f'<p class="deck">{e(story.deck)}</p>' if story.deck else ""}<p class="body">{e(lead.body)}</p>
          <p class="jump">{a(item, "Continued at " + item.source + " →")}{also}</p></div></article>"""

    def side(self, edition: Edition) -> str:
        parts = []
        for story in edition.side:
            item = self.use(story.item)
            parts.append(f"""<article class="card side-story"><div class="pad">
              <div class="meta">{self.date(item)}<span class="label">{e(story.kicker)}</span>{self.marks(item)}</div>
              <h3>{a(item, story.headline or clean_title(item))}</h3><p class="deck">{e(story.deck or "")}</p>
              <p class="src">{e(item.source)}{self.also(story, item)}</p></div></article>""")
        if edition.quote:
            parts.append(f'<figure class="card quote"><blockquote>“{e(edition.quote.head)}”</blockquote>'
                         f'<figcaption>{a(self.use(edition.quote.item), edition.quote.text)}</figcaption></figure>')
        if edition.dates:
            rows = "".join(f'<li><span class="sticker wait">{e(line.head)}</span>{a(self.use(line.item), line.text)}</li>'
                           for line in edition.dates)
            parts.append(f'<section class="card box coming"><header><h2>Save the date</h2></header><ul>{rows}</ul></section>')
        return "".join(parts)

    def release_log(self, section: str) -> str:
        """Release feeds that no story covers, newest version each. It marks every release item as used."""
        groups: dict[str, list[Item]] = {}
        for item in self.sections[section]:
            if item.kind == "release":
                groups.setdefault(item.source, []).append(item)
        cells, total = "", 0
        for name, items in sorted(groups.items(), key=lambda pair: (-len(pair[1]), pair[0].lower())):
            covered = any(item.id in self.used for item in items)
            self.used.update(item.id for item in items)
            if covered:
                continue
            latest = items[0]
            url = latest.url or ""
            version = url.rsplit("/tag/", 1)[1] if "/tag/" in url else clean_title(latest)
            project = name.removesuffix(" Releases")
            total += len(items)
            cells += (f'<li><span class="name">{e(project)}</span>'
                      f'{a(latest, version, "ver", f"{project}: newest of {len(items)} releases in {self.days} days")}'
                      f'<span class="label">{len(items)}× · {latest.published_at:%d %b}</span></li>')
        if not cells:
            return ""
        return f"""<section class="card ticker" aria-label="Also shipped"><span class="ticker-label">Also shipped · {total}</span>
          <ul>{cells}</ul></section>"""

    def brief(self, section: str, limit: int = 14) -> str:
        """In brief items as a pool. The page script deals them into the shortest columns to even out the ends."""
        picked = {self.by_id[item_id].title.casefold() for item_id in self.used}
        rest = [item for item in self.sections[section]
                if item.id not in self.used and item.kind != "status" and item.title.casefold() not in picked]
        if not rest:
            return ""
        rows = "".join(f'<li>{self.date(item)}<span>{a(item, clean_title(item))} '
                       f'<span class="label">{e(item.source)}</span>{self.marks(item)}</span></li>'
                       for item in rest[:limit])
        more = len(rest) - min(limit, len(rest))
        return f'<ul class="brief-pool" data-pool data-more="{more}" hidden>{rows}</ul>'

    def shelf(self, section: str) -> str:
        """Saved items that no story uses yet."""
        items = [item for item in self.sections[section] if item.saved and item.id not in self.used]
        if not items:
            return ""
        rows = "".join(f'<li>{a(self.use(item.id), item.title)} <span class="label">{e(item.source)}</span>{self.marks(item)}</li>'
                       for item in items)
        return (f'<section class="card box shelf"><header><h2>On your shelf</h2><p class="note">Saved for later. Later is now.</p>'
                f'</header><ul>{rows}</ul></section>')

    def edition(self, edition: Edition) -> str:
        items = self.sections.get(edition.section)
        if items is None:
            fail(f"section {edition.section!r} has no items. Sections in the items file: {sorted(self.sections)}")
        sources = len({item.source for item in items})
        front = f'<div class="front">{self.lead(edition.lead)}<div class="side">{self.side(edition)}</div></div>'
        flow = [self.card(part) if isinstance(part, Story) else self.box(part, edition.section) for part in edition.flow]
        if shelf := self.shelf(edition.section):
            flow.insert(min(3, len(flow)), shelf)
        ticker = self.release_log(edition.section)
        brief = self.brief(edition.section)
        if not flow and brief:
            fail(f"edition {edition.section!r} has In brief items but no flow to put them in. Add flow picks.")
        below = (f'<div class="fold"><span>Below the fold</span></div><div class="flow" data-flow>{"".join(flow)}</div>{brief}'
                 if flow else "")
        return f"""<section class="edition" id="{e(edition.section)}" data-section="{e(edition.section)}">
          <div class="banner"><span class="label">{e(edition.title)} · {plural(len(items), "item")} · {plural(sources, "source")}</span>
            <h2>{e(edition.banner)}</h2></div>
          {front}{ticker}{below}
        </section>"""

    def numbers(self, picks: Picks) -> str:
        every = [item for rows in self.sections.values() for item in rows]
        span = f"{self.fetched - timedelta(days=self.days):%d %b} to {self.fetched:%d %b}"
        per_section = ", ".join(f"{len(rows)} {name}" for name, rows in self.sections.items())
        first = f"#{picks.editions[0].section}"
        cards = [
            Number(str(len(every)), f"items · {per_section}", f"Every item on this page, published {span}", self.home or first),
            Number(str(len({(item.section, item.source) for item in every})), "sources with news",
                   "Sources with at least one item in the window", self.home or first),
        ]
        if read := sum(item.read for item in every):
            cards.append(Number(str(read), "items you already read", "Items that you cleared from your desk. They carry a ✓ read stamp.", first))
        cards += picks.numbers
        return '<section class="numbers" aria-label="By the numbers">' + "".join(
            f'<a class="card num" href="{e(card.href)}" title="{e(card.tip)}"{"" if card.href.startswith("#") else " target=_blank rel=noopener"}>'
            f'<b>{e(card.value)}</b><span>{e(card.label)}</span></a>'
            for card in cards) + "</section>"

    def render(self, picks: Picks) -> str:
        body = "".join(self.edition(edition) for edition in picks.editions)
        every = [item for rows in self.sections.values() for item in rows]
        today = sum(item.published_at.date() == self.fetched.date() for item in every)
        first = f"#{picks.editions[0].section}"
        word = ""
        if picks.word:
            count = sum(picks.word.casefold() in f"{item.title} {plain(item.summary)[:600]}".casefold() for item in every)
            word = (f'<a class="ear" href="{first}" title="Items whose title or summary contains the word {e(picks.word)}">'
                    f'<span class="label">Word of the week</span><b>“{e(picks.word)}”</b><span>in {count} items</span></a>')
        buttons = ""
        if len(picks.editions) > 1:
            buttons = '<div class="seg" role="group" aria-label="Show edition"><button aria-pressed="true" data-show="all">All editions</button>' + "".join(
                f'<button aria-pressed="false" data-show="{e(ed.section)}">{e(ed.section.title())}</button>' for ed in picks.editions) + "</div>"
        previous = f' <a href="{e(picks.previous)}" title="The issue before this one">← Previous issue</a>' if picks.previous else ""
        return f"""<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="theme-color" content="#E4E7FF" media="(prefers-color-scheme: light)"><meta name="theme-color" content="#15122B" media="(prefers-color-scheme: dark)">
<title>{e(picks.title)} · {self.fetched:%d %B %Y}</title><style>{CSS}</style></head>
<body><div class="page">
<header class="card masthead">
  <div class="rule"><span class="label">{e(picks.issue)}</span><span class="label">{self.fetched:%A, %d %B %Y}</span><span class="label">Price: 0 tokens</span></div>
  <div class="head">
    {word or "<span></span>"}
    <h1>{e(picks.title)}</h1>
    <a class="ear" href="{first}" title="Items published on {self.fetched:%d %B}, local time"><span class="label">Late edition</span><b>{today} new</b><span>items today</span></a>
  </div>
  <p class="motto">{e(picks.motto)}</p>
  <div class="rule">{buttons}<span class="stamp big" title="Every story links to the item that it comes from">✓ Every story sourced</span></div>
</header>
{self.numbers(picks)}
{body}
<footer>{e(picks.colophon)} Hover a link to see its source and original headline.{previous}</footer>
</div><script>{JS}</script></body></html>"""


CSS = """
@import url("https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,400;12..96,600;12..96,800&family=JetBrains+Mono:wght@400;600&display=swap");
:root {
  color-scheme: light;
  --canvas: #E4E7FF; --dots: #00000026; --surface: #FFFFFF; --raised: #F1F2FF;
  --ink: #000000; --muted: #3D3D5C; --border: #000000; --shadow-ink: #000000;
  --accent: #6C5CE7; --accent-fg: #FFFFFF; --select: #FFE14D; --select-fg: #000000;
  --info: #00B3FF; --warning: #FFB347; --warning-surface: #FFF6D1; --error: #FF5277;
  --green: #7CFF8A; --yellow: #FFE14D; --pink: #FF9EB0; --stamp: #8250DF;
  --radius: 0.25rem; --bw: 2px; --shadow: 4px 4px 0 0 var(--shadow-ink); --gap: 1.1rem;
  --sans: "Bricolage Grotesque", system-ui, sans-serif;
  --mono: "JetBrainsMono Nerd Font Mono", "JetBrains Mono", monospace;
}
@media (prefers-color-scheme: dark) {
  :root {
    color-scheme: dark;
    --canvas: #15122B; --dots: #F3F0FF22; --surface: #262147; --raised: #1D1938;
    --ink: #F3F0FF; --muted: #BDB6E6; --border: #F3F0FF; --shadow-ink: #B9A8FF;
    --select: #6C5CE7; --select-fg: #FFFFFF; --warning-surface: #3A3018; --stamp: #A371F7;
  }
}
* { box-sizing: border-box; }
/* The user reads the paper at 130% on desktop. The base grows from 18px at a 1108px viewport to 23.4px (130%) at 1440px. */
html { font-size: clamp(18px, 1.625vw, 23.4px); }
body { margin: 0; font: 1rem/1.45 var(--sans); color: var(--ink); background-color: var(--canvas);
  background-image: radial-gradient(var(--dots) 1.2px, transparent 1.2px); background-size: 16px 16px; }
h1, h2, h3 { font-weight: 800; letter-spacing: -0.01em; margin: 0; }
a { color: inherit; text-decoration-color: var(--accent); text-decoration-thickness: 2px; text-underline-offset: 2px; }
h3 a { text-decoration: none; }
h3 a:hover { text-decoration: underline; text-decoration-color: var(--accent); text-decoration-thickness: 3px; }
:focus-visible { outline: 2px solid var(--accent); outline-offset: 2px; box-shadow: 0 0 0 6px #FF527766; }
[hidden] { display: none !important; }
.page { max-width: 78rem; margin: 0 auto; padding: 1rem 0.9rem 2.5rem; display: grid; gap: var(--gap); }
.card { background: var(--surface); border: var(--bw) solid var(--border); border-radius: var(--radius); box-shadow: var(--shadow); }
.pad { padding: 0.7rem 0.85rem 0.75rem; display: grid; gap: 0.3rem; }
.label { font-size: 0.68rem; font-weight: 800; letter-spacing: 0.06em; text-transform: uppercase; color: var(--muted); }
.sticker { display: inline-block; max-width: 100%; overflow: hidden; text-overflow: ellipsis; padding: 0 0.35rem;
  line-height: 1.5; white-space: nowrap; font-size: 0.65rem; font-weight: 800; letter-spacing: 0.04em;
  text-transform: uppercase; color: #000000; background: var(--pink); border: var(--bw) solid var(--shadow-ink);
  border-radius: 4px; box-shadow: 2px 2px 0 0 var(--shadow-ink); transform: rotate(var(--tilt, -3deg)); }
.sticker.info { background: var(--info); } .sticker.wait { background: var(--yellow); } .sticker.warn { background: var(--warning); }
.sticker.bonus { background: var(--green); }
.story:nth-child(3n+2) .sticker, li:nth-child(3n+2) .sticker { --tilt: 2deg; }
.story:nth-child(3n) .sticker, li:nth-child(3n) .sticker { --tilt: -1.5deg; }
.stamp { display: inline-block; padding: 0 0.3rem; border: 2px solid var(--stamp); border-radius: 3px; color: var(--stamp);
  font: 900 0.65rem/1.4 var(--sans); text-transform: uppercase; transform: rotate(-6deg); }
.stamp.big { font-size: 0.8rem; padding: 0.05rem 0.4rem; transform: rotate(-8deg); }
.meta { display: flex; flex-wrap: wrap; align-items: center; gap: 0.3rem 0.55rem; }
.deck { margin: 0; color: var(--muted); font-size: 0.88rem; line-height: 1.4; }
.src { margin: 0; font-family: var(--mono); font-size: 0.62rem; color: var(--muted); }

/* Masthead with ears, like a broadsheet. */
.masthead { padding: 0.6rem 1rem; text-align: center; }
.masthead .rule { display: flex; flex-wrap: wrap; justify-content: space-between; align-items: center; gap: 0.5rem 1rem; }
.masthead .rule:first-child { border-bottom: var(--bw) solid var(--border); padding-bottom: 0.4rem; }
.masthead .rule:last-child { border-top: var(--bw) solid var(--border); padding-top: 0.55rem; }
.head { display: grid; grid-template-columns: 8.5rem 1fr 8.5rem; align-items: center; gap: 1rem; margin: 0.55rem 0 0.2rem; }
.masthead { container-type: inline-size; }
/* The title is about 10.3 em wide. Its cell is the masthead width minus two 8.5rem ears and two 1rem gaps. */
.head h1 { font-size: clamp(2.2rem, calc((100cqi - 19rem) / 10.6), 4.4rem); line-height: 0.95; }
.ear { display: grid; gap: 0.05rem; padding: 0.35rem 0.4rem; border: var(--bw) solid var(--border); border-radius: var(--radius);
  background: var(--raised); color: inherit; text-decoration: none; transition: transform 80ms, box-shadow 80ms; }
.ear b { font-size: 1.05rem; line-height: 1.1; } .ear span:last-child { font-size: 0.7rem; color: var(--muted); }
@media (max-width: 44rem) { .head { grid-template-columns: 1fr; } .ear, .head > span:empty { display: none; } }
.motto { margin: 0 0 0.55rem; font-weight: 600; color: var(--muted); font-style: italic; }
.seg { display: inline-flex; flex-wrap: wrap; overflow: hidden; background: var(--surface); border: var(--bw) solid var(--border); border-radius: var(--radius); }
.seg button { font: inherit; font-weight: 800; padding: 0.2rem 0.8rem; cursor: pointer; border: 0; background: transparent; color: var(--ink); }
.seg button + button { border-left: var(--bw) solid var(--border); }
.seg button[aria-pressed="true"] { background: var(--select); color: var(--select-fg); }
.seg button:focus-visible { outline-offset: -4px; box-shadow: none; }

.numbers { display: grid; grid-template-columns: repeat(auto-fit, minmax(min(100%, 9rem), 1fr)); gap: var(--gap); }
.num { padding: 0.5rem 0.7rem; display: grid; align-content: start; text-decoration: none; color: inherit;
  transition: transform 80ms, box-shadow 80ms; }
.num:hover, .ear:hover { transform: translate(-1px, -1px); box-shadow: 5px 5px 0 0 var(--shadow-ink); }
.num:active, .ear:active { transform: translate(3px, 3px); box-shadow: none; }
.num b { font-size: 1.8rem; line-height: 1.05; font-weight: 800; }
.num span { font-size: 0.72rem; color: var(--muted); }

.edition { display: grid; gap: var(--gap); }
.edition + .edition { border-top: 4px double var(--border); padding-top: 1.3rem; }
.banner { display: grid; gap: 0.1rem; }
.banner h2 { font-size: clamp(1.9rem, 4.6vw, 3rem); line-height: 1; text-transform: uppercase; letter-spacing: -0.02em; }

/* The lead stretches to the side column height; its photo or fact panel absorbs the extra space. */
.front { display: grid; grid-template-columns: minmax(0, 1.75fr) minmax(0, 1fr); gap: var(--gap); align-items: stretch; }
.side { display: grid; gap: var(--gap); align-content: start; }
@media (max-width: 54rem) { .front { grid-template-columns: 1fr; } }
.lead { position: relative; display: flex; flex-direction: column; overflow: hidden; }
.lead .pad { gap: 0.45rem; padding: 0.85rem 1rem 0.9rem; }
.lead h3 { font-size: clamp(1.8rem, 3.8vw, 2.7rem); line-height: 1.02; }
.lead .deck { font-size: 1.05rem; font-weight: 600; color: var(--ink); }
.lead .body { margin: 0; font-size: 0.92rem; }
.lead .body::first-letter { float: left; font-size: 2.3rem; line-height: 0.9; font-weight: 800; padding: 0.15rem 0.35rem;
  margin: 0.1rem 0.4rem 0 0; background: var(--select); color: var(--select-fg); border: var(--bw) solid var(--border); border-radius: var(--radius); }
.jump { margin: 0; font-size: 0.75rem; font-weight: 800; }
.extra { position: absolute; top: 0.8rem; right: 0.8rem; z-index: 2; font-size: 1.1rem; padding: 0.1rem 0.5rem;
  background: var(--surface); transform: rotate(8deg); }
/* Lead facts: big numbers with a highlighter band, where a lead without a specific photo would put one. */
.facts { flex: 1 1 auto; min-height: 10rem; display: grid; grid-template-columns: repeat(auto-fit, minmax(min(100%, 14rem), 1fr));
  align-content: space-evenly; gap: 1.2rem 1.6rem; padding: 2.6rem 1.2rem 1.2rem; background: var(--raised); border-bottom: var(--bw) solid var(--border); }
.facts div { display: grid; gap: 0.2rem; align-content: start; }
.facts b { justify-self: start; font-size: clamp(2rem, 4.6vw, 3.4rem); line-height: 1.05; font-weight: 800; letter-spacing: -0.02em;
  background: linear-gradient(transparent 55%, var(--select) 55%, var(--select) 92%, transparent 92%); }
.facts span { font-size: 0.85rem; font-weight: 600; color: var(--muted); }
.photo { margin: 0; position: relative; border-bottom: var(--bw) solid var(--border); background: var(--raised); }
.photo img { display: block; width: 100%; aspect-ratio: 16 / 9; object-fit: cover; }
.photo.fill { flex: 1 1 auto; min-height: 13rem; }
.photo.fill img { position: absolute; inset: 0; height: 100%; aspect-ratio: auto; }
.photo figcaption { position: absolute; left: 0.5rem; bottom: 0.45rem; padding: 0 0.35rem; font-size: 0.58rem; font-weight: 800;
  text-transform: uppercase; letter-spacing: 0.04em; color: #000000; background: var(--yellow); border: var(--bw) solid #000000; border-radius: 3px; }
.side-story { overflow: hidden; display: grid; grid-template-columns: 1fr; }
.side-story h3, .story h3 { font-size: 1.08rem; line-height: 1.15; }
.quote { margin: 0; padding: 0.8rem 0.95rem; background: var(--select); color: var(--select-fg); }
.quote blockquote { margin: 0; font-size: 1.15rem; font-weight: 800; line-height: 1.22; letter-spacing: -0.01em; }
.quote figcaption { margin-top: 0.45rem; font-size: 0.72rem; font-weight: 600; }

/* A static ticker: it scrolls by hand, never by itself. */
.ticker { display: flex; align-items: stretch; overflow: hidden; }
.ticker-label { flex: none; display: grid; place-items: center; padding: 0 0.7rem; background: var(--ink); color: var(--canvas);
  font-size: 0.68rem; font-weight: 800; letter-spacing: 0.06em; text-transform: uppercase; }
.ticker ul { list-style: none; margin: 0; padding: 0.45rem 0.6rem; display: flex; gap: 1rem; overflow-x: auto; scrollbar-width: thin; }
.ticker li { flex: none; display: grid; gap: 0.05rem; padding-right: 1rem; border-right: var(--bw) solid var(--raised); }
.ticker .name { font-size: 0.7rem; font-weight: 800; }
.ticker .ver { font-family: var(--mono); font-size: 0.72rem; }
.ticker .label { font-size: 0.58rem; }

.fold { display: flex; align-items: center; gap: 0.8rem; color: var(--muted); }
.fold::before, .fold::after { content: ""; flex: 1; border-top: var(--bw) dashed var(--border); }
.fold span { font-size: 0.68rem; font-weight: 800; letter-spacing: 0.08em; text-transform: uppercase; }

/* Masonry: JavaScript deals cards into the shortest column, in rank order. CSS columns are the fallback. */
.flow { columns: 3 17rem; column-gap: var(--gap); }
.flow > * { break-inside: avoid; margin-bottom: var(--gap); }
.flow.packed { columns: auto; display: grid; grid-template-columns: repeat(var(--cols), minmax(0, 1fr)); gap: var(--gap); align-items: stretch; }
.flow.packed > .col { display: flex; flex-direction: column; gap: var(--gap); }
/* While cards are dealt, columns keep their natural height, so "shortest" means something. */
.flow.packed.packing { align-items: start; }
.flow.packed .col > * { margin-bottom: 0; }
/* The last card of a column takes the leftover height: its photo grows, then the end mark sits at the bottom. */
.flow.packed .col > :last-child { flex: 1 0 auto; display: flex; flex-direction: column; }
.flow.packed .col > :last-child::after { content: "— 30 —"; margin: auto auto 0.5rem; padding-top: 0.4rem;
  font: 800 0.7rem/1 var(--mono); letter-spacing: 0.2em; color: var(--muted); }
.flow.packed .col > .story:last-child .photo { flex: 1 0 auto; }
.story { overflow: hidden; display: flex; flex-direction: column; }
.story .photo { aspect-ratio: 16 / 9; flex: none; }
.story .photo img { position: absolute; inset: 0; height: 100%; aspect-ratio: auto; }

.box > header, .brief > header { padding: 0.4rem 0.85rem; background: var(--raised); border-bottom: var(--bw) solid var(--border); }
.box > header .note { margin: 0.1rem 0 0; font-size: 0.7rem; font-style: italic; color: var(--muted); }
.box h2, .brief h2 { font-size: 0.95rem; text-transform: uppercase; letter-spacing: 0.05em; }
.box ul, .box ol, .brief ul { list-style: none; margin: 0; padding: 0.3rem 0.85rem 0.55rem; display: grid; }
.box li, .brief li { padding: 0.4rem 0; border-bottom: var(--bw) solid var(--raised); font-size: 0.84rem; line-height: 1.35; }
.box li:last-child, .brief li:last-child { border-bottom: 0; }
.box a { text-decoration-thickness: 1px; }
.weather li, .wire li { display: grid; grid-template-columns: 4.6rem 1fr; gap: 0.4rem; }
.blotter li { display: grid; grid-template-columns: 5.6rem 1fr; gap: 0.4rem; }
.blotter > header { background: repeating-linear-gradient(-45deg, var(--raised) 0 8px, var(--surface) 8px 16px); }
.overheard li { display: grid; gap: 0.1rem; }
.overheard a { font-weight: 700; font-style: italic; }
.classifieds ul { font-family: var(--mono); }
.classifieds li { font-size: 0.74rem; }
.classifieds .sticker { font-family: var(--sans); margin-right: 0.2rem; }
.corrections { border-style: dashed; }
.corrections li { display: grid; gap: 0.1rem; }
.coming li { display: grid; gap: 0.3rem; justify-items: start; font-weight: 700; }
.prolific li { display: grid; grid-template-columns: 7.5rem 1fr 1.6rem; align-items: center; gap: 0.5rem; }
.prolific .name { font-size: 0.72rem; font-weight: 700; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.prolific .bar { height: 0.8rem; width: calc(var(--w) * 100%); background: var(--accent); border: var(--bw) solid var(--border); border-radius: 2px; }
.prolific b { text-align: right; font-size: 0.8rem; }
.shelf li .stamp { margin-left: 0.4rem; }

.brief li { display: flex; align-items: baseline; gap: 0.5rem; font-weight: 600; }
.brief .sticker { flex: none; }
.brief-pool { display: none; }
.brief .label { margin-left: 0.25rem; font-size: 0.58rem; }
.more { margin: 0; padding: 0 0.85rem 0.6rem; font-size: 0.72rem; color: var(--muted); font-style: italic; }
footer { text-align: center; font-size: 0.72rem; color: var(--muted); max-width: 46rem; margin: 0 auto; }
"""

JS = """
// Masonry: deal cards in rank order into the shortest column, so the top row holds the best stories.
const flows = [...document.querySelectorAll("[data-flow]")].map((flow) => {
  const pool = flow.nextElementSibling?.matches("[data-pool]") ? flow.nextElementSibling : null;
  return { flow, cards: [...flow.children], briefs: pool ? [...pool.children] : [], more: Number(pool?.dataset.more ?? 0) };
});
const shortest = (cols) => cols.reduce((low, col) => (col.offsetHeight < low.offsetHeight ? col : low));
function briefBox(title) {
  const box = Object.assign(document.createElement("section"), { className: "card box brief" });
  box.innerHTML = `<header><h2>${title}</h2></header><ul></ul>`;
  return box;
}
function pack() {
  for (const { flow, cards, briefs, more } of flows) {
    if (flow.closest("[hidden]")) continue;
    // Sizes are in rem and the base size follows the viewport, so measure it on each pack.
    const root = getComputedStyle(document.documentElement);
    const rem = parseFloat(root.fontSize);
    const gap = parseFloat(root.getPropertyValue("--gap")) * rem;
    const columns = Math.max(1, Math.floor((flow.clientWidth + gap) / (17 * rem + gap)));
    const cols = Array.from({ length: columns }, () => Object.assign(document.createElement("div"), { className: "col" }));
    flow.classList.add("packed", "packing");
    flow.style.setProperty("--cols", columns);
    flow.replaceChildren(...cols);
    for (const card of cards) shortest(cols).append(card);
    // In brief fills the gaps: one item at a time into the shortest column, each column with its own box.
    // Three items or fewer stay together in one box, because a box with one item looks empty.
    const boxes = new Map();
    for (const item of briefs) {
      const col = briefs.length <= 3 && boxes.size ? boxes.keys().next().value : shortest(cols);
      if (!boxes.has(col)) boxes.set(col, col.appendChild(briefBox(boxes.size ? "In brief, continued" : "In brief")));
      boxes.get(col).querySelector("ul").append(item);
    }
    if (more && boxes.size) {
      const note = Object.assign(document.createElement("p"), { className: "more", textContent: `…and ${more} more on your desk.` });
      [...boxes.values()].at(-1).append(note);
    }
    flow.classList.remove("packing");
  }
}
let pending = 0;
const schedule = () => { cancelAnimationFrame(pending); pending = requestAnimationFrame(pack); };
addEventListener("resize", schedule);
document.fonts?.ready.then(schedule);
for (const img of document.images) img.addEventListener("error", () => { img.closest(".photo")?.remove(); img.remove(); schedule(); });
pack();

const buttons = document.querySelectorAll(".seg button");
for (const button of buttons) button.addEventListener("click", () => {
  for (const other of buttons) other.setAttribute("aria-pressed", String(other === button));
  for (const section of document.querySelectorAll(".edition")) {
    section.hidden = button.dataset.show !== "all" && section.dataset.section !== button.dataset.show;
  }
  schedule();
});
"""


def main() -> None:
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    items_path, picks_path, out = map(Path, sys.argv[1:])
    paper = Paper(*load_items(items_path))
    page = paper.render(load_picks(picks_path))
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(page)
    images = page.count('<figure class="photo')
    links = page.count(' target="_blank"')
    print(f"wrote {out}: {links} source links, {images} images, {len(paper.used)} of {len(paper.by_id)} items placed")


if __name__ == "__main__":
    main()
