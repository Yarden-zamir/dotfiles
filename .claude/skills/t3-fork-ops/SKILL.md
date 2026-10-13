---
name: t3-fork-ops
description: Operate the user's T3 Code machines and the T3 Code fork (Yarden-zamir/t3code) - the machine map (machines_* and machine_tool_call tools), access between machines, commands such as restart or stop agents, and the fork deploys and updates (Mac live builds, VPS deploy, portal deploy, Fork Sync, Fork Release, Fork CI). Use when the user asks to change what a machine can do on another, run something on another T3 machine, stop agents, update or deploy T3, or fix a failed fork workflow.
license: MIT
---

# T3 fork operations

The guide is `docs/fork-agents.md` in the fork. Read it before you act. Local checkout: `~/Github/t3code/main`. Online: https://github.com/Yarden-zamir/t3code/blob/main/docs/fork-agents.md

## Steps

1. Read `docs/fork-agents.md`. It maps each task to a tool and lists the safety rules.
2. For the machine map, call `machines_read` first. Take machine ids, revision numbers and command ids from its result. Do not guess them.
3. Read the description of a tool before the first call. In a terminal, run `t3 tool describe <name>`.
4. To change the fork, open a pull request on `Yarden-zamir/t3code` and merge to main. Main deploys itself. Do not deploy by hand.
5. To stop every agent on every machine, ask the user to press the emergency pause in the portal. Agents cannot press it.

## Rules

- Never kill a process that you found by a name or a pattern.
- Never write to `~/.t3/userdata`. It is the live install.
- Stage files by path only.
- Put each fork behaviour behind a setting that is off by default.
- Never put secrets in a commit, a pull request or a comment.
