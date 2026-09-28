# dotfiles

Zsh, [Ghostty](https://ghostty.org) and [herdr](https://herdr.dev)
configuration for daily work on macOS, with the same shell on a Linux VPS.
Terminal, editor keys, AI agent tooling and the git worktree layout all live
here.

## How it fits together

```
Ghostty  runs herdr as its command; relays a few keys, owns the global toggle
  └─ herdr  workspaces (spaces), tabs, panes, agents; config.toml + plugins
       └─ zsh  phase-loaded config; ZLE editor with VS Code-like keys
            └─ claude / opencode / codex / navgator / sessiongator in panes
```

- [`.config/ghostty/config`](.config/ghostty/config): runs `~/.local/bin/herdr`,
  releases the keys herdr binds, relays `cmd+1-9` and `cmd+alt+1-9` as CSI-u,
  pseudo fullscreen with a padded notch, F17 and § show or hide the window.
- [`.config/herdr/config.toml`](.config/herdr/config.toml): `cmd` manages tabs
  and panes, `cmd+alt` manages spaces, `ctrl` stays with the shell, `cmd+b` is
  the prefix for rare actions. Space names come from the repo (` dotfiles`)
  with one sidebar row per checkout in the space.
- [`.config/herdr/plugins/`](.config/herdr/plugins): local herdr plugins,
  linked with `herdr plugin link` (see the
  [herdr plugin docs](https://herdr.dev/docs/plugins/)).

| plugin | what it does | key |
| --- | --- | --- |
| [archive](.config/herdr/plugins/archive) | move a pane to an archive space instead of closing it; quits an idle agent and resumes it on restore; reaper after 14 days | `cmd+w`, `cmd+shift+t` |
| [spaces](.config/herdr/plugins/spaces) | name spaces by repo, one row per checkout, sync on `cd`, on start and on pane events | |
| [palette](.config/herdr/plugins/palette) | fuzzy palette over every plugin action and [socket API](https://herdr.dev/docs/socket-api/) method, with key hints and a schema preview | `cmd+shift+p` |
| [worktree](.config/herdr/plugins/worktree) | new worktree through [`bin/wt-new`](bin/wt-new), opened as a space | `cmd+alt+n` |
| [gators](.config/herdr/plugins/gators) | [navgator](https://github.com/Yarden-zamir/navgator) projects, [sessiongator](https://github.com/Yarden-zamir/sessiongator) sessions and sibling checkouts as popups | |
| [links](.config/herdr/plugins/links) | open URLs, files and folders from pane text | `cmd+shift+o` |
| [transcripts](.config/herdr/plugins/transcripts) | copy agent transcripts to `_shared` so a reboot cannot lose them | |

herdr itself is a fork build:
[Yarden-zamir/herdr](https://github.com/Yarden-zamir/herdr), branch `main`,
[upstream](https://github.com/herdrdev/herdr) plus a few generic features
(clickable toasts, `pane.seen.set`, path links, scrollback search keys).
[Collie](https://github.com/AltanS/collie) mirrors the panes to a phone.

## Shell

[`.zshenv`](.zshenv), [`.zprofile`](.zprofile) and [`.zshrc`](.zshrc) each
source three phase directories in order: `pre-init` (PATH, completion
prerequisites), `init` (aliases, functions, tools) and `post-init` (widgets,
keybindings, hooks). Add behavior as one focused file in the right phase
directory: [`zshenv/`](zshenv), [`zprofile/`](zprofile), [`zshrc/`](zshrc).

- [`zshrc/post-init/zle-editor.zsh`](zshrc/post-init/zle-editor.zsh): VS
  Code-like line editing (word and line movement, selection, undo, cut).
- [`zshrc/post-init/zle-kitty-protocol.zsh`](zshrc/post-init/zle-kitty-protocol.zsh):
  the ZLE pushes the
  [kitty keyboard protocol](https://sw.kovidgoyal.net/kitty/keyboard-protocol/)
  while it edits and pops it before a command runs, so modified keys arrive as
  CSI-u sequences in Ghostty and in herdr panes, local or over ssh.
- [`zshrc/post-init/bindings.zsh`](zshrc/post-init/bindings.zsh):
  `ctrl+space` navgator, `ctrl+n` new project, `ctrl+s` AI sessions, and the
  rest.
- [`zshrc/post-init/herdr.zsh`](zshrc/post-init/herdr.zsh): tells the spaces
  plugin about every `cd`.
- Plugins load with [gh_source](https://github.com/yarden-zamir/gh-source),
  which bootstraps itself from
  [`zshenv/pre-init/_gh_source.zsh`](zshenv/pre-init/_gh_source.zsh). In use:
  [fzf](https://github.com/junegunn/fzf),
  [fzf-tab](https://github.com/Aloxaf/fzf-tab) with
  [fzf-tab-source](https://github.com/yarden-zamir/fzf-tab-source),
  [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions),
  [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting),
  [zsh-history-substring-search](https://github.com/zsh-users/zsh-history-substring-search),
  [zsh-autopair](https://github.com/hlissner/zsh-autopair),
  [evalcache](https://github.com/mroth/evalcache),
  [jq-zsh-plugin](https://github.com/reegnz/jq-zsh-plugin),
  [shell-completions](https://github.com/perlpunk/shell-completions); also
  [atuin](https://atuin.sh) and [starship](https://starship.rs).

## Repos: bare + container layout

Every repo is a container directory:

```
~/Github/<project>/
├── .bare/     the git directory
├── _shared/   local-only files (secrets, env), symlinked into each checkout
├── main/      one checkout per branch, named after the branch's last segment
└── <branch>/
```

- [`bin/wt-migrate <dir>`](bin/wt-migrate) converts a clone (dry run by
  default, `--yes` to apply).
- [`bin/wt-new <branch> [base]`](bin/wt-new) adds a checkout; in herdr,
  `cmd+alt+n` runs it and opens the checkout as a space.
- [`bin/git-shared-link`](bin/git-shared-link) links `_shared/` files into a
  checkout; the global
  [`post-checkout`](.config/git/hooks/post-checkout) hook runs it on every
  checkout, clone and `worktree add`.
- [`bin/herdr-open-path <path> [command]`](bin/herdr-open-path) focuses the
  space that holds a path, or opens one; navgator and Raycast use it.

`bin/` is not on `PATH`; call these by path. The
[worktree-repo skill](.claude/skills/worktree-repo/SKILL.md) describes the
layout for agents.

## Bootstrap

Needs `zsh`, `git`, [GNU Stow](https://www.gnu.org/software/stow/) and a
[Nerd Font](https://www.nerdfonts.com) (JetBrains Mono).

```sh
git clone https://github.com/Yarden-zamir/dotfiles ~/Github/dotfiles
cd ~/Github/dotfiles && bin/wt-migrate --yes .
cd main && make stow-adopt-dry-run && make stow-adopt
```

`$DOTFILES` is `~/Github/dotfiles/main`. Stow ([`Makefile`](Makefile)) links
the `main/` checkout into `$HOME`;
[`.stow-local-ignore`](.stow-local-ignore) keeps repo-internal paths out of
`$HOME`, and [`.gitignore`](.gitignore) keeps runtime state (agent caches,
herdr sockets and logs) out of git. Secrets live in `_shared/` and match
`*secret*`, so they never enter git.

## Also here

- [`.claude/`](.claude): [`CLAUDE.md`](.claude/CLAUDE.md) instructions (the
  same text as [`AGENTS.md`](AGENTS.md)), [skills](.claude/skills) and
  settings for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).
- [`.config/opencode`](.config/opencode) ([OpenCode](https://opencode.ai)),
  [`.config/codex`](.config/codex)
  ([Codex](https://developers.openai.com/codex)),
  [`.config/navgator`](.config/navgator),
  [`.config/sessiongator`](.config/sessiongator): agent and tool configs.
- [`raycast/`](raycast): [Raycast script commands](https://github.com/raycast/script-commands)
  (Dock slots, navgator, GatorPad); point Raycast's script directory at
  `$DOTFILES/raycast`.
- [`Library/Application Support/Code/User/`](Library/Application%20Support/Code/User):
  VS Code settings and keys.
- [`tests/`](tests): [`zle-editor.zsh`](tests/zle-editor.zsh) drives the ZLE
  widgets under `zsh/zpty`;
  [`herdr-archive-fake.py`](tests/herdr-archive-fake.py) and
  [`herdr-links.sh`](tests/herdr-links.sh) test plugins against a fake herdr
  socket; [`wt-migrate.sh`](tests/wt-migrate.sh) tests the layout conversion.
  No test sends keystrokes to a real terminal.
