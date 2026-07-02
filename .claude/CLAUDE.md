User Info:  
name: Yarden-zamir  
github-name: Yarden-zamir  
domain: yarden-zamir.com  
email: dev@yarden-zamir.com  
prefered-license: MIT  
dotfiles and configs: ~/Github/dotfiles   
agent instructions: ~/Github/dotfiles/AGENTS.md  

If multiple possibilities or answers benefit the user, share them, otherwise stick to direct straight answers. If it's crucial to ask the user for more info, do so using tools available or directly. If the user asks for something that is overly complex compared to a simple alternative express that before continuing and use the 🟠 emoji. 

Make sure code is simple as possible when it can be. Readable and extendible. Prefer generic solutions over specific ones, but don't do so blindly and when it makes the code too complex or ugly. Avoid complex patterns, factories, and indirection unless they remove duplication that actually exists or are required by the environment.

Do not introduce additional dependencies if keeping things simple is possible. Don't over-engineer.

Before adding a new import or dependency, check the currently available package versions first. Use the project package manager when possible; for Python, prefer `uv` commands to verify available versions before choosing a version constraint.

Do not add legacy or old code support/migration unless explicitly requested. Make sure the user knows when a change is breaking and suggest legacy support but never do it automatically.

Python execution
- ALWAYS: uv run 
- NEVER: python, python3, python3.x, pip, pip3
**All Python code execution must go through uv. Never use the python command directly**

Apply defensive defaults in code. Null checks, type guards, boundary conditions. No runtime surprises.  Make sure that unexpected cases crash instead of failing silently or causing undefined behavior. We want the code to be itself resilient.

When calling an existing function or API make sure to check it's definition first for type annotation (verify enums vs strings, optional vs required, etc), boundary conditions, and other requirements. If it's not clear, check other calls to the same function or API to establish a pattern before proceeding. Adhering to type rules is mandatory. examine existing usage patterns in the codebase before proceeding.

Before implementing changes that reference existing code structure (routes, API endpoints, component names,
configuration):
- Read the relevant source files to verify actual implementation
- Don't assume - check the code for ground truth

When accessing dictionary/object keys from external sources (API responses, JWT payloads, database
results, function returns), never assume key names. Before accessing:
1. Check the source definition (schema, type annotation, docs, or where the dict is constructed)
2. Or print/log the keys if uncertain

Use emoji only as structural markers or to signal important meta-information, not for tone:
🟢 for primary answers or recommended path
⚪ for neutral alternatives or variants
🟠 when pointing out that the requested approach is more complex than a simpler viable alternative (and briefly state the simpler option before continuing with the requested one). Use this often, because the user may be wrong and would like to learn of alternatives
🔴 only when describing hard blockers, breaking changes, or critical risks
🧪 for repetitive mistakes that require a change to (this) base prompt or the project's base prompt


1. Verification First
Verify before linking: Never import, reference, or link to a new file or resource until
you have explicitly confirmed its existence with a tool.

2. Context Awareness
Read the room: When modifying logic flow or moving code blocks, you must read the full
function or container scope first to ensure variable availability and correct execution
order. Don't edit blind. Don't save on tokens at the cost of quality.

3. Explicit Failure Handling
Respect tool feedback: If a tool operation fails (like a failed edit or missing file),
stop immediately. Fix the root cause before proceeding. Do not assume "it probably worked."

always double check when refactoring that you refactor all usages and calls, all cases and all code paths related to the current change. Refactoring is very risky if not done properly.

Use the askquestion tool or similar to ask for clarification or direction when the user request is ambiguous, complex, or when there are multiple viable approaches. Always provide a recommended path when doing so.

Do not use regex unless absolutely necessary. Always check if a simpler string method or existing utility function can achieve the same result before resorting to regex, which can be complex and error-prone.

Tests
- Tests should be contract-focused and source-of-truth focused. 
- They should verify stable behavior that can break silently, not mirror identical copy, formatting, layout, or implementation details. 
- Exact-output assertions should live only where that output is produced; 
- Callers should assert behavior, shape, or key fields unless exact output is their contract.

Parallel verification workflow:
- When a task asks to test the same behavior across many local SDEs, kubeconfigs, branches, repos, or similar targets, do the checks concurrently with bounded per-target timeouts instead of serial one-by-one commands.
- Prefer source-of-truth checks and isolated caches/config dirs so previous local state cannot mask failures.
- Flush or collect per-target results so long-running/offline targets do not hide progress; summarize successes and failures separately.
- Treat unreachable/offline targets as expected when the user says they may be off; do not spend time debugging each one unless asked.

Worktree workflow preferences:
- Prefer repo container layouts with `.bare/`, `_shared/`, and sibling worktrees such as `main/` or branch-name folders.
- Treat the container directory as organizational only, not as a checkout.
- Put shared local-only files in `_shared/` and symlink them into worktrees when needed.
- Keep stashes untouched during migration; create worktrees for relevant branches but do not auto-apply stashes.
- Use branch folder names based on the last branch path segment by default; use the full branch name with `/` replaced by `-` only when names conflict.

Dotfiles stow workflow:
- Use `make stow-adopt`
- Surface any stow warnings to the user with likely causes and potential actions, instead of hiding or summarizing them away.
- When new dotfiles are created or adopted in this repo, ask the user whether they want to run the stow workflow.

Commit and branch preferences:
- Never credit yourself in commit messages, if I mention working with someone else, suggest crediting them.
- Unless the repo has other instructions
    - use conventional commits
    - if in a qlik repo, each commit must reference a QCDI ticket in the format: "QCDI-XXXX | conventional commit message". If not the case before merge, suggest rebase.
    - description with references and notes, not too big, only when relevant, avoid generic. If other tickets or markdown documents are involved reference them here.
