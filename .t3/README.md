# T3 Code setup

A minimal map of how Yarden runs T3 Code. Secrets are not in this repo. They are in `~/Github/t3code/_shared/` on the Mac.

## Machines

| Machine | T3 server | Public URL | Tunnel |
| --- | --- | --- | --- |
| Mac | inside the desktop app | `https://t3-mac.yarden-zamir.com` | launchd job `com.yarden.cloudflared-t3-mac` |
| VPS (`ssh yarden-zamir-vps-2`) | systemd `t3-server`, code in `/opt/t3code` | `https://t3-vps.yarden-zamir.com` | systemd `cloudflared-t3` |
| Windows | not installed | `https://t3-win.yarden-zamir.com` | token only |

- Each server listens on `127.0.0.1:3773`. Only the Cloudflare tunnel reaches it.
- The Cloudflare Access app "T3 Code servers" protects all three hosts.
- The login is the Access email code. The server trusts the `Cf-Access-Jwt-Assertion` header.
- The desktop app reaches other machines with the service token "t3-desktop-mac" as request headers.
- A browser page on one host pairs the other hosts automatically. The server setting `trustedBrowserOrigins` lists them.

## Code

- The fork is [Yarden-zamir/t3code](https://github.com/Yarden-zamir/t3code). Its fork notes are in `docs/fork.md`.
- Every fork behaviour is a setting, and each setting is off by default.
- Put patches directly on fork main. Do not open upstream PRs.
- Checkouts use the worktree layout: `~/Github/t3code/{.bare,_shared,main}` on the Mac and `/root/Github/t3code/` on the VPS.

## Updates

- The "Fork Release" GitHub workflow rebases the fork onto upstream on each push to main and every day. Then it publishes a release.
- The desktop app updates itself from the fork releases.
- If a run fails, the workflow calls the webhook task "Fork release repair" on the VPS T3 server. That task starts a repair agent in the VPS project "t3code fork".
- The webhook URL is in the repository secret `T3_AGENT_WEBHOOK_URL` and in `_shared/cloudflared/t3-vps-fork-repair-webhook.url`.
- The agent prompt source is `_shared/tools/fork-repair-agent-prompt.md`.
- Each push to fork main publishes a release. The Mac app takes it on its next update check.
- The VPS deploys the newest release once a day, only when no agent runs. See "Deploy to the VPS" in `docs/fork.md` of the fork.

## VPS details

- The drop-in `/etc/systemd/system/t3-server.service.d/shell.conf` sets `SHELL=/usr/bin/zsh`, so T3 terminals load these dotfiles.
- Claude Code settings on the VPS are a copy of the Mac settings, with the VPS hooks kept.
- `/etc/systemd/system/t3-server.service.d/claude-root.conf` and `/etc/zsh/zshenv` set `IS_SANDBOX=1`. Without it, Claude Code refuses full access as root.
- To call T3 tools on the VPS without the MCP sign-in, run `cd /root/Github && /opt/node/bin/node /opt/t3code/apps/server/dist/bin.mjs tool call <tool> --input '<json>'`.
