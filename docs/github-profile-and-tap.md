# GitHub profile card and Homebrew tap site

Two Cloudflare systems feed the GitHub profile README:

- The **profile card** Worker draws the stats receipt, the live site tickets and the ON TAP card.
- The **tap site** at [brew.yarden-zamir.com](https://brew.yarden-zamir.com) lists the formulae in [Yarden-zamir/homebrew-tap](https://github.com/Yarden-zamir/homebrew-tap).

## Profile card

- Worker: `github-stats` on `github-stats.yarden-zamir.com`.
- Source: `stats/worker.js` and `stats/wrangler.jsonc` in [Yarden-zamir/Yarden-zamir](https://github.com/Yarden-zamir/Yarden-zamir), the profile repo.
- Deploy: run `npx wrangler deploy` in `stats/`. No CI deploys this Worker.

```
cron every 30 minutes ──► github-stats Worker ──► KV namespace github-stats
   ├─ GitHub GraphQL (GITHUB_TOKEN): contributions, pull requests, issues, stars, repos
   ├─ Cloudflare API (CLOUDFLARE_API_TOKEN): DNS records and DNS analytics on all zones
   │     └─ HTTPS check on each host: live, redirect, login or down
   ├─ Cert Spotter and crt.sh: first certificate date of each host
   └─ brew.yarden-zamir.com/formulae.json: the tap list

README image request ──► github-stats Worker ──► reads KV only ──► SVG
```

### KV keys

| Key | Content |
|---|---|
| `snapshot` | All data that the images draw |
| `sites` | The check state of each host |
| `certs` | Certificate dates and the Cert Spotter cursor of each zone |
| `born` | Hand-set start dates of sites, taken from repo creation dates |

### Routes

| Route | Content |
|---|---|
| `/` | The receipt card |
| `/site/<n>.svg` | Ticket image for site slot `n`, newest site first |
| `/go/<n>` | Redirect to the site in slot `n`, or to the profile if the slot is empty |
| `/tap.svg` | The ON TAP card |

GitHub does not allow links inside an SVG image. Thus each site is a separate image in a `/go/<n>` link.

### Site rules

- The site start date is the first of: the `born` entry, the first certificate date, the first time the check saw the site live.
- The constant `HIDDEN` in `worker.js` hides hosts and their subdomains. It holds `example.yarden-zamir.com` and `shahar-zamir.com`.
- A new site on any Cloudflare zone appears without code changes.

### Limits

- The free plan allows 50 subrequests per run. Thus one run checks 22 sites and sends 6 certificate requests.
- crt.sh often returns 502. Each run tries crt.sh once for one zone without history.
- GitHub caches README images through its camo proxy. Changes can take some minutes to show.

### Secrets

Put each secret in with a pipe, for example `pbpaste | npx wrangler secret put GITHUB_TOKEN`.

| Secret | Scope |
|---|---|
| `GITHUB_TOKEN` | Personal access token with all scopes |
| `CLOUDFLARE_API_TOKEN` | Zone, DNS and analytics read on all zones |

## Tap site

- Worker: `homebrew-tap-site`, static assets only. No code runs on a request.
- Source: `site/build.mjs`, `site/page.html` and `site/wrangler.jsonc` in [Yarden-zamir/homebrew-tap](https://github.com/Yarden-zamir/homebrew-tap).
- Deploy: the `site.yml` workflow. It runs on each push to `main` that changes `Formula/**` or `site/**`. You can also start it by hand.

```
project release ──► formula sync pull request ──► automerge (merges with TOKEN) ──► push to main
                                                                                    └─► site.yml: node site/build.mjs ──► wrangler deploy
```

`build.mjs` reads three sources:

- `Formula/*.rb` for name, description, version, license, dependencies and caveats.
- git history for the date of the last formula change.
- The GitHub release feed of each project for the release date and name.

It writes `site/dist/index.html` and `site/dist/formulae.json`.

### Secrets and variables

| Name | Kind | Use |
|---|---|---|
| `CLOUDFLARE_API_TOKEN` | Secret | wrangler deploy: Workers Scripts edit, Workers Routes edit, Account Settings read |
| `CLOUDFLARE_ACCOUNT_ID` | Variable | wrangler deploy target |
| `TOKEN` | Secret | automerge. A push with `GITHUB_TOKEN` does not start other workflows, so `site.yml` would not run. |

## Polling that remains

- The profile card data refreshes only on the 30-minute cron.
- The ON TAP card lags a tap deploy by up to 30 minutes, because the Worker reads the tap list on the cron.

To remove the polling, add triggers that call the Worker: a GitHub App webhook for own repos, a call from `site.yml` after deploy, and a call from KitSHn deploys. Keep a slow cron as a backstop, because activity in other repos, DNS changes and certificate logs send no events.

## Troubleshooting

- This Mac keeps old DNS answers after DNS changes. Test a host with `curl --resolve <host>:443:<ip>` and an IP from `dig @1.1.1.1 <host>`.
- If a run fails with "A stalled HTTP response was canceled", look for a response body that the code does not read or cancel.
- Read Worker logs with `npx wrangler tail github-stats`.
