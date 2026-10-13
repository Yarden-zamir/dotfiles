---
name: changelorg
description: Read the user's changelorg data (profiles such as dev and games, feed changes, shelf items, notes) from changelorg.yarden-zamir.com through agent access, read only by default. Use when the user asks about their changelorg, their feed, desk or shelf, asks to build something from those items, or asks to change sources, profiles, or shelf items. The first use needs one browser approval by the user.
license: MIT
---

# changelorg

Read the data through the changelorg CLI. Do not ask the user for cookies, tokens, exports, or console snippets.

Run the CLI as `uvx --from git+https://github.com/Yarden-zamir/changeLorg changelorg`. This file calls it `changelorg`.

## Steps

1. Run `changelorg auth status`. If it exits `0` and shows the access that the task needs, go to step 4.
2. Run `changelorg auth login --name "<agent> on <machine>"` in the background. If the task changes data, add `--write`. It prints a link and a code, then waits up to 10 minutes.
3. Send the user the link and the code. Tell the user to open the link in the usual browser, compare the code, and approve. Wait until the command exits. If it exits `1`, report its message.
4. Read data with `changelorg api "<path>"`. Put the path in quotes, because it contains `&`.
5. With write access, change data with `changelorg api -X PATCH "/changes/<id>" -d '{"saved": true}'`. `POST` and `DELETE` work the same way.

## Paths

- `/profiles`: profile names and enabled source counts. Take profile names from here. Do not guess them.
- `/changes?profile=<name>&since=10d&include_dismissed=true&limit=500`: the changes of one profile.
- `/changes?saved=true&since=30d`: shelf items only.
- `/sources`: the subscriptions, including disabled ones.
- `/me`: the account.

`since` takes a duration such as `24h` or `10d`, or an ISO date. `until` sets the window end. Without `include_dismissed=true`, items that the user cleared stay hidden.
Each change has `title`, `url`, `summary`, `content`, `published_at`, `source_name`, `source_profile`, `saved`, `dismissed`, and `note`.

## Rules

- A read token gets `403` on writes. Ask for `--write` only when the task changes data.
- Before a write that deletes data or changes many items, confirm the change with the user.
- If a response holds exactly 500 items, the window is cut. Split the window with `since` and `until`.
- If a command reports an expired or revoked token, do steps 2 and 3 again.
- The token lives in `~/.config/changelorg/credentials.json`. Never print it, and never copy it into files, chats, or commits.
- The user revokes agents in the GitHub account menu on the site. `changelorg auth logout` revokes the token of this machine.
