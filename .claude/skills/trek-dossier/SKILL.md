---
name: trek-dossier
description: Build and deploy a trek dossier site for a multi-day hike, like gr52.yarden-zamir.com. Day plan in English and Hebrew, live map from the real GPX, elevation profile, per-day live weather with warnings, offline mode, position snapshot, section maps, GPX for OsmAnd, deployed with KitSHn. Use when the user asks for a trek plan site, hiking dossier, GPX plus map page, or "the same thing as the GR52 site" for another trail.
---

# Trek dossier

Produce a deployed site and a GPX for one trek, from the template repo
`Yarden-zamir/trek-site-template` (local clone at `~/Github/trek-site-template/main`; pull it
first). The template holds the app, the build and the tools; this skill is the order of work, the
inputs, and the quality bar. Read the template README first: it defines the waypoint naming the
app depends on and lists every `trek.json` key. Reference outputs: gr52.yarden-zamir.com (alpine,
7 days) and yam2yam.yarden-zamir.com (Israel, 4 days).

## Inputs

Collect these before writing anything. Ask only for what cannot be inferred.

Required:
- Trail name, start and end points, direction.
- Dates: arrival day and the date of each walking day, or a start date plus the day split.
  The live weather and its check only work for dates within Open-Meteo's 16-day horizon; for a
  trek further out, the cards show "not yet available" and `check.py` reports that state as
  expected. For a test run, choose dates inside the window.
- The party: how many, pace relative to guidebook times, sleeping style (tent, huts, mix),
  appetite for technical terrain, names to use on the page.
- Hostname, for example `<slug>.yarden-zamir.com`. Wildcard DNS already points at the VPS.

Inferred unless the user says otherwise:
- Route geometry: an OpenStreetMap hiking relation for the trail, or several in walking order.
  Nominatim rarely finds trails, and the OSM name is often not the common one (the Sea to Sea is
  `מסע מים אל ים`, `name:en` "Sea to Sea Hiking Trail"). Query Overpass for `route=hiking`
  relations in the trail's bounding box, list their `name`, `name:en`, `ref`, and pick by
  inspection; check for a superroute. Confirm the chained result reaches the end. Fall back to a
  GPX the user provides.
- Languages: English and Hebrew. Timezone of the trail. Elevation dataset: `eudem25m` in
  Europe, `srtm30m` elsewhere.
- Booked accommodation, transport bookings, and any fixed times the user mentions.

## Steps

1. **Research** with web search: official trail sources, park or reserve rules (camping hours,
   protected zones, dogs, fires, gate closing times), hut and campsite opening dates, prices and
   booking, water reliability per stage, trip reports from the same season, transport to the
   start and from the end, emergency numbers, official weather warning pages for the region.
   Check the calendar: public and religious holidays on the trek dates change transport and
   opening hours (Israel: Hebcal for Shabbat and holidays). Note every source URL.
2. **Scaffold**: copy the template (everything except `.git`, `.tiles`, `trek.example.json`)
   into `~/Github/<slug>` (not `<slug>-build`: the worktree conversion happens in place and the
   folder name becomes the container). Write `trek.json` starting from `trek.example.json`.
   Rewrite the README heading and intro for the trek as its "Per-trek README" section says.
   Then `git init -b main`, commit, `gh repo create Yarden-zamir/<slug> --public`, add the
   remote, and run `kitshn recipe auth --vps-host root@89.233.108.13` BEFORE the first push.
   After the first push, `$DOTFILES/bin/wt-migrate --yes ~/Github/<slug>` converts to the bare
   plus worktree layout, leaving the checkout at `~/Github/<slug>/main`.
3. **Data**: `uv run tools/build_gpx.py`, then `uv run tools/elevation.py`. Waypoints in
   `trek.json` follow the README naming: `NIGHT n · <date> · <place>: <note>`, `FINISH · …`,
   `PASS · <name> <ele> m - <note>`, plus Escape, Info (fords, gates, danger notes), Water where
   reports name a source OpenStreetMap lacks, `NIGHT n option B · …` for alternatives. Take every
   coordinate from OpenStreetMap (Nominatim or Overpass nodes: camps, huts, springs, peaks);
   never guess a position. Optional: `tools/side_trips.py` for summits off the line. Set
   `enrich` so water, huts and shelters come from OpenStreetMap. Copy the GPX to `~/Downloads/`
   under a descriptive name.
4. **Section maps**: choose `sectionMaps` in `trek.json` (one overview at zoom 11, one map per
   two or three days at zoom 13), run `uv run tools/maps.py`.
5. **Content**: write `src/body.html` for every language following the skeleton comments. Day
   cards need `data-day`, `data-date`, a planned-hours chip, and the empty `.wx` div. Write the
   Hebrew as a Hebrew hiker would say it, with Latin place names. Fill `places` in `trek.json` so
   place names link to the map. Keep the header facts to six tiles that a walker uses. Set
   `plannedStart` to the realistic start hour (6 in heat, 8 in the Alps), `treeline` where one exists, and `strings` when the
   app's default warning wording does not fit the terrain (the defaults are alpine).
6. **Build and check**: `uv run src/build.py`, then `uv run tools/check.py`. Fix until it passes.
   It renders the site in headless Chrome and asserts: tiles and route drawn, weather rows and
   place links (or the beyond-horizon state), day links, a simulated snapshot marks day 1 done,
   an hourly chart draws. A single failed weather run can be the API; rerun once before digging.
7. **Deploy**: commit, push to `main`, `gh run watch`, then `uv run tools/check.py --url
   https://<hostname>/`. Confirm the GPX downloads with `application/gpx+xml`.
8. **Report**: the URL, the GPX path in Downloads, the day split and why, what could not be
   verified, and the sources. Flag anything on the dates that changes the plan (holidays,
   closures, border or fire restrictions).

## Quality bar

- Every number a walker acts on has a source: hut dates, bus times, water gaps, camping rules.
- Warnings are derived from data, not typed: the app computes storm, rain, snow, wind, frost,
  heat, fog, UV and late-arrival from Open-Meteo. The text adds only what the data cannot know.
- Nothing hardcoded per trek outside `trek.json`, `src/body.html` and the README intro. If the
  template itself needs a fix, make it in `~/Github/trek-site-template/main` and push it, then
  copy into the trek repo, so the next trek gets it.
- No Claude or session credits in commits or the PR. Conventional commits.

## Gotchas

- Overpass mirrors time out for long stretches; `common.overpass()` rotates three and backs
  off. Keep queries small and bounded. OpenTopoData allows 1 call per second and 1000 per day;
  `elevation.py` is resumable.
- OpenStreetMap relations contain short alternates; the app chains only connected segments for
  the profile, so a route length far above the trail's means a chaining problem in the GPX.
- Headless Chrome cannot lay out narrower than 500 px; phone layouts are checked at 500.
- `recipe auth` reads the git remote, so worktree layouts are fine. The first push deploys.
- Docker Desktop is often off locally; test a container on the VPS in `/tmp` over SSH instead.
