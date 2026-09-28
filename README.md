# dotfiles

Zsh, Ghostty and herdr configuration for daily work on macOS, with the same
shell on a Linux VPS. Terminal, editor keys, AI agent tooling and the git
worktree layout all live here.

## How it fits together

```
Ghostty  runs herdr as its command; relays a few keys, owns the global toggle
  └─ herdr  workspaces (spaces), tabs, panes, agents; config.toml + plugins
       └─ zsh  phase-loaded config; ZLE editor with VS Code-like keys
            └─ claude / opencode / codex / navgator / sessiongator in panes
```

- `.config/ghostty/config`: runs `~/.local/bin/herdr`, releases the keys
  herdr binds, relays `cmd+1-9` and `cmd+alt+1-9` as CSI-u, pseudo fullscreen
  with a padded notch, F17 and § show or hide the window.
- `.config/herdr/config.toml`: `cmd` manages tabs and panes, `cmd+alt`
  manages spaces, `ctrl` stays with the shell, `cmd+b` is the prefix for rare
  actions. Space names come from the repo (` dotfiles`) with one sidebar
  row per checkout in the space.
- `.config/herdr/plugins/`: local herdr plugins, linked with
  `herdr plugin link`.

| plugin | what it does | key |
| --- | --- | --- |
| archive | move a pane to an archive space instead of closing it; quits an idle agent and resumes it on restore; reaper after 14 days | `cmd+w`, `cmd+shift+t` |
| spaces | name spaces by repo, one row per checkout, sync on `cd`, on start and on pane events | |
| palette | fuzzy palette over every plugin action and socket API method, with key hints and a schema preview | `cmd+shift+p` |
| worktree | new worktree through `bin/wt-new`, opened as a space | `cmd+alt+n` |
| gators | navgator projects, sessiongator sessions and sibling checkouts as popups | |
| links | open URLs, files and folders from pane text | `cmd+shift+o` |
| transcripts | copy agent transcripts to `_shared` so a reboot cannot lose them | |

herdr itself is a fork build: `github.com/Yarden-zamir/herdr`, branch
`main`, upstream plus a few generic features (clickable toasts, `pane.seen.set`,
path links, scrollback search keys).

## Shell

`.zshenv`, `.zprofile` and `.zshrc` each source three phase directories in
order: `pre-init` (PATH, completion prerequisites), `init` (aliases,
functions, tools) and `post-init` (widgets, keybindings, hooks). Add behavior
as one focused file in the right phase directory.

- `zshrc/post-init/zle-editor.zsh`: VS Code-like line editing (word and line
  movement, selection, undo, cut).
- `zshrc/post-init/zle-kitty-protocol.zsh`: the ZLE pushes the kitty keyboard
  protocol while it edits and pops it before a command runs, so modified keys
  arrive as CSI-u sequences in Ghostty and in herdr panes, local or over ssh.
- `zshrc/post-init/bindings.zsh`: `ctrl+space` navgator, `ctrl+n` new
  project, `ctrl+s` AI sessions, and the rest.
- `zshrc/post-init/herdr.zsh`: tells the spaces plugin about every `cd`.
- Plugins load with `gh_source`, which bootstraps itself from
  `zshenv/pre-init/_gh_source.zsh`.

## Repos: bare + container layout

Every repo is a container directory:

```
~/Github/<project>/
├── .bare/     the git directory
├── _shared/   local-only files (secrets, env), symlinked into each checkout
├── main/      one checkout per branch, named after the branch's last segment
└── <branch>/
```

- `bin/wt-migrate <dir>` converts a clone (dry run by default, `--yes` to
  apply).
- `bin/wt-new <branch> [base]` adds a checkout; in herdr, `cmd+alt+n` runs
  it and opens the checkout as a space.
- `bin/git-shared-link` links `_shared/` files into a checkout; the global
  `post-checkout` hook runs it on every checkout, clone and `worktree add`.
- `bin/herdr-open-path <path> [command]` focuses the space that holds a
  path, or opens one; navgator and Raycast use it.

`bin/` is not on `PATH`; call these by path.

## Bootstrap

Needs `zsh`, `git`, GNU `stow` and a Nerd Font (JetBrains Mono).

```sh
git clone https://github.com/Yarden-zamir/dotfiles ~/Github/dotfiles
cd ~/Github/dotfiles && bin/wt-migrate --yes .
cd main && make stow-adopt-dry-run && make stow-adopt
```

`$DOTFILES` is `~/Github/dotfiles/main`. Stow links the `main/` checkout into
`$HOME`; `.stow-local-ignore` keeps repo-internal paths out of `$HOME`, and
`.gitignore` keeps runtime state (agent caches, herdr sockets and logs) out of
git. Secrets live in `_shared/` and match `*secret*`, so they never enter git.

## Also here

- `.claude/`: `CLAUDE.md` instructions (the same text as `AGENTS.md`), skills
  and settings for Claude Code.
- `.config/opencode`, `.config/codex`, `.config/navgator`,
  `.config/sessiongator`: agent and tool configs.
- `raycast/`: script commands (Dock slots, navgator, GatorPad); point
  Raycast's script directory at `$DOTFILES/raycast`.
- `Library/Application Support/Code/User/`: VS Code settings and keys.
- `tests/`: `zle-editor.zsh` drives the ZLE widgets under `zsh/zpty`;
  `herdr-archive-fake.py` and `herdr-links.sh` test plugins against a fake
  herdr socket; `wt-migrate.sh` tests the layout conversion. No test sends
  keystrokes to a real terminal.
