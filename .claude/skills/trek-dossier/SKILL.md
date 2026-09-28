---
name: trek-dossier
description: Build and deploy a trek dossier site for a multi-day hike (like gr52.yarden-zamir.com and yam2yam.yarden-zamir.com) from the trek-site-template. Day plan in English and Hebrew, live map from the real GPX, per-day weather with a day simulator, offline mode, GPX for OsmAnd, deployed with KitSHn. Use when the user asks for a trek plan site, hiking dossier, GPX plus map page, or "the same thing as the GR52 site" for another trail.
---

# Trek dossier

You write two files, `trek.json` and `content.yaml`, and run tools. The template
(`~/Github/trek-site-template/main`, repo `Yarden-zamir/trek-site-template`; `git pull` it first)
holds the app, the build, the deploy recipe and the tools. Read its README once: it lists every
config key and the waypoint naming the app depends on. Never edit HTML, JavaScript or CSS for a
trek; if something in the template is wrong, fix it there, push, and copy it into the trek repo.

## Inputs to collect

Required: trail, start, end, direction; the dates (arrival day plus each walking day, or a start
date and a day split); the party (size, pace relative to guidebook times, tent or huts, appetite
for technical ground, names to use); the hostname (`<slug>.yarden-zamir.com`; wildcard DNS exists).
Inferred: route from OpenStreetMap, languages (English and Hebrew), timezone, elevation dataset,
weather model, treeline, heat limit, start hour, the trail's marking colour.

The live weather and its checks work only within Open-Meteo's 16-day horizon. For a test run,
choose dates inside it; for a real trek further out, `doctor` warns and the cards say "not yet
available" until then.

## Steps

1. **Scaffold.** `uv run tools/new.py --slug <slug> --name "<Name>" --hostname <slug>.yarden-zamir.com --start YYYY-MM-DD --days N [--arrival YYYY-MM-DD]`
   from the template folder. It copies the template to `~/Github/<slug>`, writes skeleton
   `trek.json` and `content.yaml` with one day per date, rewrites the README intro, commits,
   creates the public GitHub repo and runs `kitshn recipe auth`, so the first push deploys.
   Work in `~/Github/<slug>` from here on.
2. **Route.** `uv run tools/find_route.py --near "<start>" --near "<end>" --name "<regex>"` lists
   OpenStreetMap hiking relations in the box with names in every language, length, endpoints and
   chain gaps. Pick the chain that runs start to end and write it with `--pick id,id`. Check
   `route.start` is the trailhead. If nothing fits, ask the user for a GPX and set `route.gpx_in`.
3. **Waypoints.** Fill `trek.json` waypoints: `NIGHT 0 · <date> · <place>: <note>` for the arrival
   night, `NIGHT n · …` per night, `FINISH · …`, `PASS · <name> <ele> m - <note>` for cols and
   summits on the line, `ESCAPE · …` for roads and stations, `Info` notes for fords, gates and
   danger spots, `NIGHT n option B · …` for alternatives. Every coordinate comes from OpenStreetMap
   (Nominatim or Overpass nodes: camps, huts, springs, peaks). Never guess a position.
4. **Data.** `uv run tools/build_gpx.py && uv run tools/elevation.py && uv run tools/derive.py &&
   uv run tools/maps.py`. `derive` fills `places`, `sectionMaps` and location defaults; review
   them. Copy the GPX to `~/Downloads/<slug>-<trail>-<year>.gpx`.
5. **Research.** `uv run tools/research.py`, `uv run tools/dates.py`, `uv run tools/climate.py`
   write `research/`. Read `research/osm.md` first: T-grades and hazards on the route's own ways,
   protected areas (where the camping rules live), huts with hours and phones, water with drinking
   tags, bus stops and stations, fords, peaks, via ferrata, shops. Merge the useful lines of
   `research/waypoints.proposed.json` into `trek.json` waypoints and rebuild the GPX. Then web
   search for what OSM cannot know, guided by `research/README.md`: rules and gate hours, opening
   dates and prices, water reliability in this season, trip reports from the same month, transport
   on the dates, holidays (calendar.md flags them), emergency numbers, official weather warning
   pages. Write `research/findings.md` with a source per line.
6. **Content.** Fill `content.yaml` for every language: header facts (six tiles a walker uses), a
   plan intro, each day (`title`, `label`, `stats` chips, `hours`, two to four sentences of `text`:
   water, the hard bit, the option, the fallback), the rules, the refuges table, technical options,
   practical lists (season, transport, gear), extra sections if needed, links with the sources.
   Hebrew is written by you as a Hebrew hiker would say it, with Latin place names. Set `accent`
   to the trail's marking colour, `exposed` for open ridges below the treeline, and `strings` if the
   default warning wording does not fit the terrain.
7. **Build and check.** `uv run tools/all.py --from build` runs build, doctor and the headless
   checks and writes `checks/phone-day-and-map.png`. Fix every doctor error; look at the
   screenshot once. Rerun until clean.
8. **Deploy.** `git add -A && git commit && git push -u origin main`, `gh run watch`, then
   `uv run tools/check.py --url https://<hostname>/`. Confirm the GPX downloads as
   `application/gpx+xml`. Convert the repo with `$DOTFILES/bin/wt-migrate --yes ~/Github/<slug>`.
9. **Report.** The URL, the GPX path in Downloads, the day split and why, holidays or closures on
   the dates, what could not be verified, and the sources.

## Quality bar

- Every number a walker acts on has a source: hut dates, bus times, water gaps, rules, prices.
- Warnings come from data; the text adds only what the data cannot know.
- Nothing per-trek lives outside `trek.json`, `content.yaml`, `research/` and the README intro.
- Conventional commits. No Claude or session credits in commits or pull requests.

## Gotchas

- Overpass mirrors time out often; the tools rotate and back off. Keep queries bounded.
- OpenTopoData allows 1 call per second and 1000 per day; `elevation.py` is resumable.
- A route length far above the trail's means a chaining problem: check `route.start` and gaps.
- Headless Chrome lays out at 500 px minimum; phone checks and screenshots use that width.
- `recipe auth` reads the git remote, so worktree layouts are fine. The first push deploys.
- Trip-log editing (optional): list GitHub logins in `trek.json` `"editors"`. Create a GitHub App with the
  `github-app-setup` skill: callback `https://<hostname>/auth/callback`, permission `emails: read`. Put its
  client id, client secret and a cookie secret in the `prod` environment as `KITSHN_OAUTH2_PROXY_CLIENT_ID`,
  `KITSHN_OAUTH2_PROXY_CLIENT_SECRET` and `KITSHN_OAUTH2_PROXY_COOKIE_SECRET`. Then set `"auth": true` and
  build. `src/build.py` writes `compose.override.yml` with the editors and the oauth2-proxy service; a repo
  `.env` does nothing under KitSHn. Any GitHub user can sign in; only the editors can edit.
