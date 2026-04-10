# Claude Workflow Engine

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

## Critical Universal Rules

### 1. Slack Thread Management
- **ONE TASK = ONE THREAD = ONE TIMESTAMP**
- Thread state persisted in `.slack-thread` file — all commands read from it
- Read Slack channel and tool name from `.claude/project.md`

### 2. No AI References
- NO AI references anywhere whatsoever
- NO Claude attributions in commits or PRs
- NO "Generated with Claude Code" footers
- NO "Co-Authored-By: Claude" lines

### 3. Testing Standards
- TDD tests MUST be unit tests (faster feedback)
- Never integration tests for TDD Red phase
- Mock external dependencies
- Integration tests only for end-to-end verification AFTER unit tests

### 4. Branch Management
- ALWAYS branch from the base branch declared in `project.md` (never main/master unless configured)
- Branch naming convention from `project.md`
- Check JIRA ticket type to determine prefix

### 5. PR Requirements
- MUST follow the PR template declared in `project.md`
- All sections required
- Document testing with actual commands
- Link JIRA tickets with full URL

### 6. Code Quality
- Read `~/.claude/stacks/<stack>.md` for language-specific rules
- Run lint check on YOUR files only (command from `project.md`)
- NEVER run lint format if `project.md` marks it FORBIDDEN
- NEVER fix pre-existing violations in unrelated files

---

## Prohibited Actions

- Create multiple threads for one task
- Put AI references in commits/PRs/code
- Work on the base branch directly
- Skip any PR template sections
- Skip `/check-lessons` before implementation
- Hardcode project-specific values — always read from `project.md`

---

## Lessons Learned

Detailed patterns stored in project memory files. See `memory/lessons-learned.md` in each project's memory directory.
