# T3 Code setup

How Yarden runs [T3 Code](https://github.com/Yarden-zamir/t3code) on three machines. Secrets are not in this repo.

## Machines

| Machine | T3 server | URL | Tunnel |
| --- | --- | --- | --- |
| Mac | desktop app | `https://t3-mac.yarden-zamir.com` | launchd job `com.yarden.cloudflared-t3-mac` |
| VPS | systemd `t3-server`, code in `/opt/t3code` | `https://t3-vps.yarden-zamir.com` | systemd `cloudflared-t3` |
| Windows | desktop app | `https://t3-win.yarden-zamir.com` | Windows service `cloudflared` |

- Each server listens on `127.0.0.1:3773`. Only its Cloudflare tunnel reaches it.
- One Cloudflare Access app protects the three URLs. The servers trust its login header.
- Each desktop app sets tunnel pairing, trusted web origins and the Cloudflare Access values in Settings > Connections. The VPS sets them as `T3CODE_*` variables in its systemd unit.
- A desktop app connects to the other machines with a Cloudflare service token, sent as request headers.
- A browser page on one machine pairs the other machines by itself.

To add a machine to a desktop app, request a pairing credential with the service token, then open the pairing link in the app. The credential expires after 2 minutes.

```sh
curl -X POST -H "CF-Access-Client-Id: <id>" -H "CF-Access-Client-Secret: <secret>" \
  https://t3-<machine>.yarden-zamir.com/api/auth/cloudflare-access/pairing-credential
# then open https://t3-<machine>.yarden-zamir.com/pair#token=<credential>
```

## Code

- The fork is [Yarden-zamir/t3code](https://github.com/Yarden-zamir/t3code). Its own `README.md` lists the fork features, and `docs/fork.md` describes its build and release setup.
- Checkouts use the worktree layout: `~/Github/t3code/{.bare,_shared,main}`.

## Updates

- The "Fork Sync" workflow merges upstream main into fork main every day.
- The "Fork Release" workflow builds the desktop apps when the app shell changes, and once a day.
- Mac: the launchd job `com.t3code.fork-live-build` builds each new fork main commit into `~/Github/t3code/live`. The update button offers it as a server-only update. Log: `~/Library/Logs/t3-live-build.log`.
- VPS: `t3-deploy.timer` deploys fork main when no agent runs. Log: `journalctl -u t3-deploy.service`.
- Windows: full app updates from the fork releases.

## Settings and themes

- Each machine keeps server settings in `~/.t3/userdata/settings.json` and desktop settings in `~/.t3/userdata/client-settings.json`.
- `shared-settings.json` holds the settings that are the same on every machine. Paths, projects, providers and Mac-only keys stay local.
- To apply them, run `bin/t3-settings pull`, or `bin\t3-settings.ps1` on Windows. To publish this machine's values, run `bin/t3-settings push` and commit.
- `userdata/themes` holds the published themes. On each machine, `~/.t3/userdata/themes` links to it (a junction on Windows).

## VPS

- A drop-in sets `SHELL=/usr/bin/zsh` for `t3-server`, so terminals load these dotfiles.
- T3 runs as root. Claude Code needs `IS_SANDBOX=1` for that, set in a `t3-server` drop-in and in `/etc/zsh/zshenv`.
- To call T3 tools without the MCP sign-in, run `node /opt/t3code/apps/server/dist/bin.mjs tool call <tool> --input '<json>'` from `/root/Github`.
