---
name: dotfiles-installer-blocks
description: Use when converting installer-added shell blocks in .zshenv, .zprofile, .zshrc, PATH exports, completion snippets, SDK init snippets, or generated marker blocks into this dotfiles repo's split zsh file format.
---

# Dotfiles Installer Blocks

Use this when the user wants to clean up shell content that installers or setup scripts appended directly to base dotfiles.

Look for generated blocks and one-off additions such as:

- Marker comments like `# >>> tool >>>` and `# <<< tool <<<`
- PATH exports appended to `.zshenv`, `.zprofile`, or `.zshrc`
- Installer-generated completion snippets
- SDK/tool init snippets copied from install instructions
- Hardcoded home paths like `/Users/kcw/...`

Example input:

```zsh
# >>> coursier install directory >>>
export PATH="$PATH:/Users/kcw/Library/Application Support/Coursier/bin"
# <<< coursier install directory <<<
```

Follow the normal repo instructions in `AGENTS.md` and the existing split zsh layout. Move the snippet into the smallest appropriate file under `zshenv/`, `zprofile/`, `zshrc/`, or `completions/`, then remove the generated block from the base dotfile.
