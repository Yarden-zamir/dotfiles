---
name: gh-pr-images
description: Add screenshots, images or videos to a GitHub pull request, issue or comment from the command line.
---

Run `gh pr edit|create|comment <n> --body-file body.md --attach './shot.png#alt text'` from the image folder; `gh` uploads each file and swaps `![alt](./shot.png)` in the body for its URL.

`--attach` needs `gh` 2.99 or later. If the host has an older `gh`, download the release archive and its checksums file from `github.com/cli/cli/releases` into a temporary folder. Check the checksum, then run that `gh` by path.

To take the screenshots in T3 Code, use the preview tools (`preview_open`, then `preview_snapshot` with `save=true`). They also work on a headless machine, such as a VPS: each T3 server has its own headless browser. They work only in a T3 thread with an active run, so a native subagent cannot use them; use `delegate_task` for a child that takes screenshots. If a Linux host reports a sandbox or library error, run `sudo t3 browser setup` there once.

If the preview tools cannot run, use `bin/t3-shot.mjs` in this repository. It drives the Playwright headless shell that a T3 Code checkout already has, so it needs no sudo and no install:

1. In the T3 Code worktree, seed `.t3` with `vp run migrate-dev-db`. Remove the inherited `T3CODE_*` variables, then start `vp run dev` with its output in a log file. Keep the PID.
2. Write a `shots.json` in an empty folder outside the repository. The header of the script lists the fields: page path, viewport, `localStorage` values, clicks, crop, and CSS that hides noise.
3. Run `node $DOTFILES/bin/t3-shot.mjs <worktree> <dev-log> <shots.json>`. The script pairs with the token from the log once, and keeps the session in `.t3-shot-state.json` next to the shots. Never commit or share that file.
4. If pairing fails because the token is used up, restart the dev server for a new token.

For each visible change, attach light and dark screenshots. In a public repo, leave out screenshots that show work thread titles.
