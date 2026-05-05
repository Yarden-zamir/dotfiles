---
name: opencode-day-summary
description: Summarize today's OpenCode session history into a Markdown note in the Obsidian vault repo.
license: MIT
---

# opencode-day-summary

Use this skill when the user asks for a summary of what they worked on today, a daily work log, or an Obsidian note based on OpenCode session history.

## Defaults

- OpenCode data directory: `~/.local/share/opencode`
- OpenCode database: `~/.local/share/opencode/opencode.db`
- Session diffs: `~/.local/share/opencode/storage/session_diff/*.json`
- Obsidian vault repo: `~/GitHub/me.v2`
- Default note path: `~/GitHub/me.v2/Daily/YYYY-MM-DD.md`
- Date basis: local time

## Workflow

1. Verify the OpenCode database exists before querying it.
2. Verify the Obsidian vault repo exists before writing a note.
3. Query sessions by `time_updated` for the requested local date, not only `time_created`, because sessions are often resumed across days.
4. Prefer read-only SQLite access with `mode=ro` while gathering history.
5. Include sessions from all repos unless the user asks to filter by repo.
6. For resumed sessions, summarize only message and part rows created on the requested local date. Use older rows only as context when needed.
7. Cross-check session summaries with `session_diff` JSON files when available, but do not treat diff files as today-scoped or authoritative.
8. Read message and part data only as needed to understand intent, final outcomes, commands, test results, blockers, commits, and PR/Jira decisions.
9. Prefer final assistant answers, successful git commits, and successful verification outputs over intermediate patches or reasoning.
10. Write or update a Markdown note under the Obsidian vault repo.

## Accuracy Rules

- Query sessions by `time_updated`, but build summaries from same-day `message` and `part` rows.
- Build timeline start/end times from same-day part timestamps, not from session created/updated timestamps.
- Treat `session_diff/*.json` as a noisy cross-check. It may be cumulative for a resumed session, stale, empty, or include generated files unrelated to today's actual work.
- When summarizing changed files, require evidence from a same-day patch part, git diff/status output, commit output, or final assistant summary. Otherwise classify the work as discussed, reviewed, investigated, or planned.
- If a change was made and later reverted or superseded in the same day, summarize the final state and decision, not the intermediate implementation.
- Separate code changes from analysis/admin work. Jira review, PR linkage, planning, and code review should be listed as worked on or left open unless they produced a file change or commit.
- Use this evidence priority: commits and verification outputs, final assistant summaries, same-day patch parts, same-day tool outputs, session diffs, session titles.

## Useful Queries

List sessions updated on a local date:

```sh
sqlite3 'file:/Users/kcw/.local/share/opencode/opencode.db?mode=ro' \
"SELECT id, directory, title,
 datetime(time_created/1000,'unixepoch','localtime') AS created,
 datetime(time_updated/1000,'unixepoch','localtime') AS updated,
 COALESCE(summary_files,0) AS files,
 COALESCE(summary_additions,0) AS additions,
 COALESCE(summary_deletions,0) AS deletions
 FROM session
 WHERE date(time_updated/1000,'unixepoch','localtime') = date('now','localtime')
 ORDER BY time_updated;"
```

List message rows for one session:

```sh
sqlite3 'file:/Users/kcw/.local/share/opencode/opencode.db?mode=ro' \
"SELECT id,
 datetime(time_created/1000,'unixepoch','localtime') AS created,
 data
 FROM message
 WHERE session_id = 'SESSION_ID'
 ORDER BY time_created, id;"
```

List part rows for one session:

```sh
sqlite3 'file:/Users/kcw/.local/share/opencode/opencode.db?mode=ro' \
"SELECT id, message_id,
 datetime(time_created/1000,'unixepoch','localtime') AS created,
 data
 FROM part
 WHERE session_id = 'SESSION_ID'
 ORDER BY time_created, id;"
```

Extract today's useful part data across sessions:

```sh
sqlite3 'file:/Users/kcw/.local/share/opencode/opencode.db?mode=ro' \
"SELECT session_id,
 datetime(time_created/1000,'unixepoch','localtime') AS created,
 json_extract(data,'$.type') AS type,
 substr(json_extract(data,'$.text'),1,1200) AS text,
 json_extract(data,'$.tool') AS tool,
 substr(json_extract(data,'$.state.output'),1,1200) AS tool_output
 FROM part
 WHERE date(time_created/1000,'unixepoch','localtime') = date('now','localtime')
 ORDER BY session_id, time_created, id;"
```

## Note Format

Use this structure unless the user asks for a different template:

```md
# Work Summary - YYYY-MM-DD

## Overview

- One concise paragraph or 3-5 bullets summarizing the day.

## Projects

### repo-name

- Worked on: short task names based on session titles and prompts.
- Changed: meaningful code/config/docs changes proven by same-day patches, git output, commits, or final summaries.
- Verified: tests, builds, commands, or manual checks observed in history.
- Left open: blockers, follow-ups, failed commands, or unresolved questions.

## Timeline

- HH:MM-HH:MM `repo-name` - concise session title/outcome.

## Raw Session References

- `SESSION_ID` - `repo path` - session title.

## Possible Todos

- Concrete follow-ups inferred from blockers, failed checks, unresolved questions, TODO comments, PR/Jira decisions, or explicit next steps.
- If none are identified, write `- None identified.`
```

## Writing Rules

- Keep the note factual and concise.
- Do not include secrets, tokens, raw credentials, or full private command output.
- Do not paste full diffs unless explicitly requested; summarize changed files and intent.
- Keep `Possible Todos` at the end of the note, and only include evidence-backed follow-ups. Do not invent generic next steps.
- Preserve existing note content when updating an existing daily note; append a clearly titled section unless the user asks to replace it.
- Create `~/GitHub/me.v2/Daily` if it does not exist and the default path is used.
- If the vault path is missing, stop and ask for the correct Obsidian vault repo path.

## Verification

- Confirm the Markdown file exists after writing.
- Report the final note path to the user.
- Mention any sessions that could not be parsed or any missing diff files as residual risk.
