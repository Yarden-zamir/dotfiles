---
name: gh-pr-images
description: Add screenshots, images or videos to a GitHub pull request, issue or comment from the command line with `gh --attach`. Use for PR evidence, before and after images, and any "attach the screenshot to the PR" request. Never commit images to the repository for this.
license: MIT
---

# gh-pr-images

`gh` 2.99 and later upload files to GitHub's own attachment storage (`github.com/user-attachments/assets/...`). This is the same storage that a drag and drop in the browser uses. It needs no extra tool, token or branch.

## Commands

The flag works on `gh pr create`, `gh pr edit`, `gh pr comment`, and the matching `gh issue` commands.

```sh
gh --version   # must be 2.99 or later
gh pr edit 68 -R owner/repo --attach './after.png#Join dialog after the change'
gh pr comment 68 -R owner/repo --attach ./before.png --attach ./after.png
```

- Write alt text after `#`. Without it, `gh` uses the file name.
- Repeat `--attach` for each file. The limit is 50 files per command.
- A video renders as a player.

## Place images in the body

1. Save the current body before you edit it: `gh pr view <n> --json body -q .body > /tmp/pr-<n>-body.md`.
2. Check that the saved file is not empty.
3. Write the new body with relative references, for example `![Before](./before.png)`.
4. Run the command from the folder of the images, with `--body-file` and one `--attach` per referenced file.

`gh` replaces each relative reference with the uploaded URL. It appends a file that the body does not reference to the end.

```sh
gh pr edit 68 -R owner/repo --body-file /tmp/pr-68-new.md --attach ./before.png --attach ./after.png
```

## Rules

- If some uploads fail, `gh` still updates the pull request and exits with a non-zero status. Then check the body and retry only the missing files.
- Never commit PR-only images to the repository, a branch or a release.
