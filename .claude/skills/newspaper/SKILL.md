---
name: newspaper
description: Build a newspaper-style news page (the Gazette) in the tick3d neo-brutalism style from any sources, such as changelorg profiles, feeds, release pages, web pages or web search results. The page has a lead story, ranked cards, press boxes (weather, classifieds, corrections, police blotter, overheard) and hover notes on every link. Use when the user asks for a news page, a digest, a newspaper, an edition or the Gazette, or asks to publish the weekly issue on news.yarden-zamir.com.
license: MIT
---

# Newspaper

You collect news items, act as the editor, and render one HTML page. The page uses the tick3d style of the `neo-brutalism` skill.

Files in this folder:

- `gazette.py`: renders the page from an items file and a picks file. It stops on a duplicate item, an unknown item, an unknown key or a generic image.
- `changelorg_items.py`: writes an items file from changelorg. Every changelorg profile becomes one section.
- `og_image.py`: prints the share image of each page URL.
- `example-picks.json`: a complete picks file of a real issue. Read it for the tone and for the use of each box.

Run each script with `uv run --no-project --python 3.12 python -I <script> <arguments>`. The scripts use only the standard library.

## Steps

1. Make a work folder for the issue, for example `desk/<date>/`.
2. Write `items.json`:
   - For changelorg, run `changelorg_items.py desk/<date>/items.json <days>`. If the CLI is not signed in, do the steps of the `changelorg` skill.
   - For other sources, write the items yourself from feeds, pages or web search results.
   - Give each item its real URL and publish time. Do not invent an item.
   - If you add a story from outside the feed of the user, set `"bonus": true`. The page marks it.
3. Read the candidate items. Before you write about an item, read its full text: the item summary, or the page.
4. Rank the items by interest to the reader. Use what you know about the user.
5. Write `picks.json`. Follow the editorial rules below.
6. For each story that gets a picture, run `og_image.py <url>`. Look at each image. Use only images that show the story itself.
7. Run `gazette.py desk/<date>/items.json desk/<date>/picks.json <out>/index.html`. Fix each error that it reports.
8. Check the page in the T3 browser preview. See "Check".

## Items file

```json
{
  "fetched": "2026-10-13T21:37:22+03:00",
  "days": 7,
  "home": "https://changelorg.yarden-zamir.com/",
  "items": [
    {"id": "577653", "section": "dev", "title": "Redesigning source control at Anthropic",
     "url": "https://www.anthropic.com/engineering/redesigning-source-control", "summary": "As our merges per day grew…",
     "published_at": "2026-10-13T00:00:00+00:00", "source": "Anthropic Engineering", "kind": "article",
     "read": false, "saved": false, "bonus": false}
  ]
}
```

- `id` is unique text. `section` names the edition that holds the item.
- `kind` is `article`, `release` or `status`. Release items without a story go into the "Also shipped" ticker. Status items go only into a weather box.
- `read`, `saved`, `bonus` and `home` are optional. Saved items that no story uses go into an "On your shelf" box.

## Picks file

```json
{
  "title": "The changelorg Gazette", "issue": "Vol. 1 · No. 2",
  "motto": "All the feed that fits · seven days of your dev, games and work desks",
  "word": "agent",
  "colophon": "Built 16 October 2026 from changelorg with agent access. Headlines, decks, boxes and the ranking are an agent edit.",
  "previous": "/issues/2026-10-13/",
  "numbers": [{"value": "12", "label": "ARC Raiders posts", "tip": "Why this number matters", "href": "#games"}],
  "editions": [{
    "section": "dev", "title": "Dev edition", "banner": "Source control has a moment",
    "lead": {"item": "577653", "kicker": "Anthropic", "headline": "…", "deck": "…", "body": "…",
             "facts": [["30,000+", "merges a day in September"]], "image": null, "also": []},
    "side": [{"item": "531163", "kicker": "GitHub", "headline": "…", "deck": "…"}],
    "quote": {"text": "Exact words from the item", "credit": "Who said it", "item": "577706"},
    "dates": [{"day": "27 Oct", "text": "What happens", "item": "577772"}],
    "flow": [
      {"item": "577728", "kicker": "Mistral", "headline": "…", "deck": "…", "tag": "Breaking", "also": ["577726"], "image": "https://…"},
      {"box": "weather", "title": "Pipeline weather", "note": "…", "rows": [{"head": "⛈ Mon 5", "text": "…", "item": "524252"}]}
    ]
  }]
}
```

- `word`, `previous`, `numbers`, `side`, `quote` and `dates` are optional.
- In a story, only `item` is required. Without `headline`, the page uses the item title.
- `also` lists other items about the same story. The card links them by source name.
- The page computes the item count, the source count and the read count. Put only extra numbers in `numbers`. Count them from the items file.
- `previous` links the footer to the issue before this one.

Box kinds for `flow`:

| `box` | Use it for |
| --- | --- |
| `weather` | Incidents and outages, from status items. Put a weather sign and a day in `head`. |
| `classifieds` | Small items in one line each. Put a short word in `head`, such as WANTED, LOST or FOR RENT. |
| `corrections` | Fixes, regressions, withdrawn alerts and metric errors. |
| `blotter` | Agents, bots or services that did something wrong. Put the place in `head`. |
| `overheard` | Short exact quotes. Put the speaker in `head` and the quote in curly quotes in `text`. |
| `wire` | Feeds that send headlines only. Put the date in `head`. |
| `prolific` | A bar chart of the sources with the most articles. It takes no rows. |

## Editorial rules

- **Rank.** Put the most interesting story first. The page deals cards into columns in rank order.
- **One place per item.** Each item appears once. The build stops on a second use. If two sources tell the same story, make one card with `also`.
- **Short decks.** Write one or two sentences, at most 25 words. Do not repeat the headline.
- **True facts.** Take every fact, number and date from the linked item. Copy quotes word for word.
- **Light humor.** Put jokes in banners, box titles, box notes and classifieds. Keep facts plain.
- **Few images.** Use about one image for each six cards. Never use a logo, a share card or a house illustration.
- **Lead.** Give the lead an image or two to four `facts`. Without them, the lead card has empty space.
- **Small sections.** If an edition has fewer than about eight items, use a lead and side stories only, with an empty `flow`.
- **Status and releases.** Put status items in a weather box. Leave release items to the ticker, unless a release is a story.
- **Hover notes.** Every link gets a note with its source and original headline. Write a link only through the picks.

## Check

1. Serve the output folder: `uv run --no-project python -m http.server <port> --bind 127.0.0.1 --directory <out>`. Start it detached with `nohup`, so that it lives after the turn.
2. Open `http://127.0.0.1:<port>/` with `preview_open`.
3. Measure the columns with `preview_evaluate`. Each column total must be close to the others:
   ```js
   [...document.querySelectorAll(".edition")].map(ed => [ed.dataset.section,
     [...ed.querySelectorAll(".flow.packed > .col")].map(c => [...c.children].reduce((s, x) => s + x.scrollHeight, 0))])
   ```
4. Look at the page with `preview_snapshot`. Check the front page of each edition and the end of each flow.
5. Set `preview_set_appearance` to `dark` and look again. Then set it to `system`.
6. Set `preview_resize` to the `iphone-12-pro` preset. Check that the page does not scroll sideways. Then set it to `fill`.
7. If a box holds one line, or a column ends far above the others, change the picks and render again.

## The weekly issue on news.yarden-zamir.com

A weekly T3 schedule makes this issue from changelorg. The site folder is `~/.local/share/news.yarden-zamir.com/`:

- `desk/<date>/`: the items file and the picks file of each issue.
- `site/index.html`: the newest issue. `site/issues/<date>/index.html`: every issue.
- `wrangler.jsonc`: a Cloudflare Worker with static assets only, on the custom domain `news.yarden-zamir.com`.

To publish, run `npx --yes wrangler@4.150.0 deploy --config ~/.local/share/news.yarden-zamir.com/wrangler.jsonc`. The site is public.
If wrangler reports an expired login, run `npx --yes wrangler@4.150.0 login` and ask the user to approve in the browser.
