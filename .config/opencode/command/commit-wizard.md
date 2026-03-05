---
description: Create descriptive conventional commits from uncommitted changes
agent: build
---

Analyze uncommitted changes and create separate, descriptive commits using conventional commits format.

User guidance: $ARGUMENTS

## Instructions

1. Run `git status` to see all uncommitted changes
2. Run `git diff` to understand what changed
3. Based on the user's prompt, group related changes logically
4. For each logical group, BEFORE committing:
   - Use `gh issue list --state open --limit 100` (and `gh issue view` if needed) to check if the changes or proposed commit message match any open issues
   - If a likely match exists, ask the user if the commit resolves it
   - If the user says yes, ask whether to append `/close #n` to the commit message
   - Use the question tool to show the user:
     - Files to be included
     - Proposed commit message (with `/close #n` appended if approved)
     - Options: "Commit", "Skip", "Edit message"
   - If user selects "Edit message", ask for new message
   - Only proceed with `git add` and `git commit` if user approves
5. Commit format (conventional commits):
   - `feat:` for new features
   - `fix:` for bug fixes
   - `docs:` for documentation
   - `refactor:` for refactoring
   - `chore:` for maintenance
   - `style:` for formatting
   - `test:` for tests
   - Single-line messages only, but make them detailed and changelog-worthy
   - Include what, why, and key details in one descriptive line
6. Do NOT:
   - Commit `.opencode/` or `.claude/` directories
   - Commit unrelated files not matching the prompt
   - Add AI credits or co-author tags to commits
7. Show a summary of commits created

If no prompt given, intelligently group all changes into logical commits.
