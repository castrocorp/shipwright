# Shipwright

## Version Check (on session start)

At the start of each conversation, read `~/.claude/.shipwright-update` (if it exists). If `status=available`, print a single line:

```
Shipwright update available: {current} → {latest}. Run /update-shipwright to update.
```

If the file is missing or `status=up-to-date`, say nothing.

## Project Config

**CRITICAL**: Before ANY workflow step, read `.claude/project.md` for project-specific values (Slack channel, JIRA cloud ID, build commands, base branch, etc.). Never hardcode these values.

For language/framework-specific code quality rules, read `~/.claude/stacks/<stack>.md` where `<stack>` is declared in `project.md` under "Code Standards".

## Automatic Workflow Execution

> ### CHECK TICKET COUNT FIRST — BEFORE ANYTHING ELSE
> - **2+ ticket IDs** → invoke `/parallel-implement TICKET-1 TICKET-2 ...` — STOP, do nothing else
> - **1 ticket ID** → follow the sequential workflow below

**CRITICAL**: When user requests to "implement", "work on", "start", or "fix" a ticket, **AUTOMATICALLY RUN THE ENTIRE WORKFLOW** through `/code-review` without stopping between commands.

**Sequence for a SINGLE ticket** (run without stopping):
```
/start-task → [Jira → In Progress] → /analyze-jira (if JIRA) → /bug-analyze (bugs only) → /create-branch → /check-lessons → /tdd-ralph → /code-review → STOP
```
After user requests `/create-pr` → create PR → **[Jira → Code Review]**

### TDD Ralph (Development Phase)

After `/check-lessons`, invoke `/tdd-ralph` to start iterative TDD implementation. This command:
1. Gathers context from prior steps (JIRA analysis, lessons learned, bug analysis)
2. Builds a comprehensive ralph-loop prompt with TDD + quality checklists
3. Invokes `ralph-loop` automatically with `--completion-promise "DONE" --max-iterations 30`
4. Ralph-loop iterates Red-Green-Refactor cycles until all criteria are met

**Do NOT manually build ralph-loop prompts** — `/tdd-ralph` handles this automatically.

After the loop exits, continue to `/code-review`.

**Non-JIRA tasks**: Skip `/analyze-jira` and `/bug-analyze`. Derive branch name and context from user's description. Still use `/tdd-ralph` for implementation.

**Multiple tickets (2+)**: ALWAYS use `/parallel-implement TICKET-1 TICKET-2 [TICKET-3 ...]`. Never run the sequential workflow for multiple tickets.

**Single ticket**: STOP after `/code-review` — wait for user to request `/git-commit` or `/create-pr`.

### Pre-flight (Run Before Any Step)
1. Count ticket IDs — 2+ → `/parallel-implement`, stop there
2. Did any setup tool/plugin fail? → Surface error to user, STOP, ask how to proceed
3. Are there extra instructions in the request? → Understand them before acting
4. Is there a stale branch or worktree from a previous attempt? → Clean it up first

### Graceful Degradation

External integrations (Slack, Atlassian, `gh` CLI, ralph-loop) are **enhancements, not requirements**. The core pipeline (branch → code → test → commit → PR) must work with zero MCP servers.

**Detection**: At the start of each command, probe for the integration. If unavailable, log a warning and use the fallback path — never stop the pipeline for a non-essential dependency.

| Integration | When unavailable |
|-------------|-----------------|
| **Slack MCP** | Skip thread creation and all Slack updates. Don't create `.slack-thread`. All commands check for `.slack-thread` before posting — if absent, skip silently. |
| **Atlassian MCP** | Skip JIRA analysis, transitions, and ticket type lookups. Use context from user's request for AC. Default to `feat/` branch prefix unless user specifies a bug. |
| **`gh` CLI** | Push branch via `git push`. Output the PR creation URL for the user to open manually. Skip PR status checks in cleanup. |
| **ralph-loop plugin** | `/tdd-ralph` falls back to manual TDD implementation (Red-Green-Refactor without iterative loop). Log warning. |

**Principle**: A command should do everything it CAN do, skip what it CAN'T, and report what was skipped — never block the user's work because an optional integration is down.

### Error Recovery
- **Tool/plugin setup failure**: STOP immediately, report error to user, do NOT substitute a different approach silently
- **Test failure**: Fix failing tests, re-run. Inside ralph-loop, the loop handles retries automatically. If stuck after max-iterations, STOP and report.
- **Build error**: Diagnose root cause, attempt fix. If environmental, STOP and ask user.
- **Slack failure**: Continue workflow, retry once. Log failure but don't block work.
- **Branch conflict**: STOP and ask user how to resolve.
- **Unknown error**: Post error details to Slack thread, STOP, and ask user.

### Jira Ticket Transitions
- **In Progress**: Transition ticket IMMEDIATELY after `/start-task`. Use `transitionJiraIssue`.
- **Code Review**: Transition ticket AFTER `/create-pr` completes successfully. Use `transitionJiraIssue`.

### Cross-Cutting Commands
- `/slack-update`: Post updates to existing thread (called by ALL commands)

---

## Universal Rules

The engine installs universal rules to `~/.claude/rules/` (symlinked from `engine/rules/` by `install.sh`). These are loaded automatically by Claude Code and cover: no AI references, testing standards, branch management, PR requirements, code quality, and prohibited actions.

### Slack Thread Management
- **ONE TASK = ONE THREAD = ONE TIMESTAMP**
- Thread state persisted in `.slack-thread` file — all commands read from it
- Read Slack channel and tool name from `.claude/project.md`

---

## Lessons Learned

Detailed patterns stored in project memory files. See `memory/lessons-learned.md` in each project's memory directory.
