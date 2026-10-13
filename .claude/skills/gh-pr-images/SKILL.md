---
name: gh-pr-images
description: Add screenshots, images or videos to a GitHub pull request, issue or comment from the command line.
---

Run `gh pr edit|create|comment <n> --body-file body.md --attach './shot.png#alt text'` from the image folder; `gh` uploads each file and swaps `![alt](./shot.png)` in the body for its URL.
