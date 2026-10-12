# T3 Code setup

A minimal map of how Yarden runs T3 Code. Secrets are not in this repo. They are in `~/Github/t3code/_shared/` on the Mac.

## Machines

| Machine | T3 server | Public URL | Tunnel |
| --- | --- | --- | --- |
| Mac | desktop app, server code from `~/Github/t3code/live/current` | `https://t3-mac.yarden-zamir.com` | launchd job `com.yarden.cloudflared-t3-mac` |
| VPS (`ssh yarden-zamir-vps-2`) | systemd `t3-server`, code in `/opt/t3code` (link to `/opt/t3code-a` or `-b`) | `https://t3-vps.yarden-zamir.com` | systemd `cloudflared-t3` |
| Windows | not installed | `https://t3-win.yarden-zamir.com` | token only |

- Each server listens on `127.0.0.1:3773`. Only the Cloudflare tunnel reaches it.
- The Cloudflare Access app "T3 Code servers" protects all three hosts.
- The login is the Access email code. The server trusts the `Cf-Access-Jwt-Assertion` header.
- The desktop app reaches other machines with the service token "t3-desktop-mac" as request headers.
- A browser page on one host pairs the other hosts automatically. The server setting `trustedBrowserOrigins` lists them.

## Code

- The fork is [Yarden-zamir/t3code](https://github.com/Yarden-zamir/t3code). Its fork notes are in `docs/fork.md`.
- Every fork behaviour is a setting, and each setting is off by default. A feature that Yarden asks for is turned on for Yarden.
- Each change goes through a branch worktree and a PR on the fork, then a merge to main. Never open upstream PRs.
- Fork main only moves forward. Nothing rebases or force-pushes it.
- Checkouts use the worktree layout: `~/Github/t3code/{.bare,_shared,main}` on the Mac and `/root/Github/t3code/` on the VPS.

## Updates

- "Fork Sync" (GitHub workflow) merges upstream main into fork main every day, typechecks and pushes. The changelog has a "Start Fork Sync" button.
- "Fork Release" builds the desktop apps when a push changes the app shell (`apps/desktop`, icons, build config, dependencies), and once a day.
- Mac, server and web code: a launchd job (`com.t3code.fork-live-build`) builds each new main commit in about a minute into `~/Github/t3code/live/{a,b,c}`. The update button then offers it in blue as a server-only update: the server restarts, the app keeps running. Log: `~/Library/Logs/t3-live-build.log`.
- Mac, app shell: a full app update through the same button, in the normal color.
- The install dialog shows running agents and offers "Install when idle". After a restart, "Recover interrupted agents" sends "Recover and continue" to cut-off threads.
- VPS: `t3-deploy.timer` follows fork main every minute and switches only when no agent runs. Log: `journalctl -u t3-deploy.service`.
- If a sync or a release fails, the workflow calls the webhook task "Fork repair" on the VPS T3 server. It starts a repair agent in the VPS project "t3code fork", which fixes the fork through a PR.
- The webhook URL is in the repository secret `T3_AGENT_WEBHOOK_URL` and in `_shared/cloudflared/t3-vps-fork-repair-webhook.url`. The agent prompt source is `_shared/tools/fork-repair-agent-prompt.md`.
- Details: `docs/fork.md` in the fork.

## Settings

- Server settings: `~/.t3/userdata/settings.json`. The server applies an edit at once.
- Desktop client settings: `~/.t3/userdata/client-settings.json`. Reload the window (Cmd+R) after an edit.
- Back up a settings file as `<file>.bak-<date>-<topic>` before an edit.

## VPS details

- The drop-in `/etc/systemd/system/t3-server.service.d/shell.conf` sets `SHELL=/usr/bin/zsh`, so T3 terminals load these dotfiles.
- Claude Code settings on the VPS are a copy of the Mac settings, with the VPS hooks kept.
- `/etc/systemd/system/t3-server.service.d/claude-root.conf` and `/etc/zsh/zshenv` set `IS_SANDBOX=1`. Without it, Claude Code refuses full access as root.
- To call T3 tools on the VPS without the MCP sign-in, run `cd /root/Github && /opt/node/bin/node /opt/t3code/apps/server/dist/bin.mjs tool call <tool> --input '<json>'`.
