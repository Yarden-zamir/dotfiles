---
name: gh-pr-images
description: Add screenshots, images or videos to a GitHub pull request, issue or comment from the command line.
---

Run `gh pr edit|create|comment <n> --body-file body.md --attach './shot.png#alt text'` from the image folder; `gh` uploads each file and swaps `![alt](./shot.png)` in the body for its URL.

To take the screenshots in T3 Code, use the preview tools (`preview_open`, then `preview_snapshot` with `save=true`). They also work on a headless machine, such as a VPS: each T3 server has its own headless browser. They work only in a T3 thread with an active run, so a native subagent cannot use them; use `delegate_task` for a child that takes screenshots. If a Linux host reports a sandbox or library error, run `sudo t3 browser setup` there once.
