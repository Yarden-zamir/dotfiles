---
name: disk-cleanup
description: Find large disposable files on this Mac. Use for disk cleanup, low disk space, a full startup disk, or unexplained disk growth. Inspect first; delete only with approval.
---

# Disk cleanup

## Fast inspection

1. Check actual free space before you scan folders:
   ```sh
   df -h / /System/Volumes/Data
   tmutil listlocalsnapshots /
   ```
2. Measure these targets with `du -sh`. Inspect the largest targets with `du -k -d 1`.
   - `~/Library/{Caches,Logs,Application Support}/JetBrains`: old plugins, indexes, and logs.
   - `~/Library/Caches/{VisualStudio,VisualStudioInstaller,Homebrew,*.ShipIt,t3code-updater}`: installer payloads.
   - `~/Downloads` and `/private/tmp`: installer archives and abandoned test artifacts.
   - `~/Library/Application Support/Claude/vm_bundles`: optional Claude VM images.
   - `~/Library/Containers/com.docker.docker/Data/vms/0/data/Docker.raw`: Docker disk.
   - `~/.gradle`, `~/.android/avd`, `~/Library/Developer`: Android and Xcode outputs.
   - `~/Library/pnpm`, `~/.cache`, `~/.cargo`, `~/.npm`: dependency caches and test browsers.
   - `~/.local/share/opencode`, `~/.t3`: databases, backups, snapshots, and worktrees.
   - `~/Github/*/*/target` and `node_modules`: per-worktree build outputs and dependencies.
3. Skip protected paths. Avoid a full-home scan unless targeted checks fail.
4. Inspect contents, dates, installed versions, and open files before you classify a target.
5. For Docker, check `docker system df` and `docker ps -a`. Do not start Docker without approval.
6. If totals do not explain usage, check `diskutil apfs list` and `lsof -nP +L1`.

## Safety and cleanup

- Treat inactivity as evidence, not proof that the user does not need data.
- Distinguish installer archives from personal ZIP files. Inspect archive entry names first.
- Preserve current software, settings, local history, secrets, databases, and Docker data volumes.
- Preserve `_shared/` and repositories with uncommitted work. Do not stop processes or VMs without approval.
- Recheck current state before deletion. Past approval does not authorize a later cleanup.
- Prefer tool cleanup commands. Preview Homebrew cleanup with `brew cleanup --dry-run --prune=all`.
- After approval, use Docker prune commands for the approved resource types. Preserve volumes by default.
- For direct deletion, use inspected, exact paths. Exclude open files and active update payloads.
- APFS clones share blocks. Do not sum `du` results as guaranteed recoverable space.
- For sparse images, compare logical size with allocated blocks. Never delete a live VM disk directly.

Report the largest candidates by size: path, purpose, evidence, risk, and cleanup command.
Recommend a small first batch and wait for approval. After cleanup, report the actual `df` change.
If an app still reports a full disk, identify its exact error and filesystem before more deletion.
