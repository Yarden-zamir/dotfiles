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
4. Commit format (conventional commits):
   - `feat:` for new features
   - `fix:` for bug fixes
   - `docs:` for documentation
   - `refactor:` for refactoring
   - `chore:` for maintenance
   - `style:` for formatting
   - `test:` for tests
   - Single-line messages only, but make them detailed and changelog-worthy
   - Include what, why, and key details in one descriptive line
5. Do NOT:
   - Commit `.opencode/` or `.claude/` directories
   - Commit unrelated files not matching the prompt
   - Add AI credits or co-author tags to commits
6. Show a summary of commits created

If no prompt given, intelligently group all changes into logical commits.
