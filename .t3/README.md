# T3 Code setup

Yarden runs the [T3 Code fork](https://github.com/Yarden-zamir/t3code) on several machines. Secrets are not in this repo.

- The fork's `docs/fork/features.md` describes the fork features, and `docs/fork/operations.md` the releases, installs and deploys. `docs/fork-agents.md` is the task-to-tool table for agents.
- The machine map portal (https://t3.yarden-zamir.com) syncs settings and custom themes between machines. Change a shared setting there, in T3 Settings with "All environments", or with `machines_set_setting`.
- Each machine keeps its own `~/.t3/userdata`. Its `themes` folder is a real folder that the map fills; do not link it to this repo.
- Servers without a display run the upstream background service (`t3 service install`) and update themselves from fork releases (`forkAutoUpdate`).

The old settings tool (`bin/t3-settings`, `shared-settings.json`) and the linked themes folder were retired on 2026-10-15, because they fought map sync: a pull turned every differing key into a per-machine override. Git history keeps them.
