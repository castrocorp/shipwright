---
description: Request comprehensive code review from project's reviewer agent with Slack updates
---

# Code Review Command

## Step 0: Load Config
Read `.claude/project.md` for: `SLACK_CHANNEL`, `SLACK_TOOL`, reviewer agent name, stack name.
Read `~/.claude/stacks/{STACK}.md` for: review criteria.
Read `.slack-thread` for: thread timestamp.

## Prerequisites
- Slack thread exists (from `/start-task`)
- Implementation complete (from `/tdd-ralph`)
- All tests passing

## Step 1: Notify in Slack Thread
Post that code review is starting.

## Step 2: Call Reviewer Agent

Use the Agent tool with the reviewer agent configured in `project.md`. Include:
- List of changed files and what changed
- Review criteria from `stacks/{STACK}.md`
- Slack thread instructions (timestamp, channel, tool name)

The agent MUST review for ALL criteria defined in the stack adapter, which typically includes:
- Language-specific style and idioms
- SOLID principles
- DRY, KISS, YAGNI
- Comments as last resort (prefer better names, extracted functions)
- Business logic and edge cases
- Test coverage

## Step 3: Address Agent Findings

For each finding:
1. **Critical issues** (security, logic errors) → Fix immediately
2. **Code quality** (naming, clarity) → Fix and improve
3. **Suggestions** (alternatives, optimizations) → Evaluate and apply if valuable

Re-run tests after making changes.

## Step 4: Document Actions Taken
Post summary to Slack thread: suggestions addressed, tests still passing.

## Rules
- Notify in EXISTING thread before calling agent
- Pass thread timestamp to agent
- Address ALL suggestions (fix or explain why not)
- Re-run tests after changes
- NEVER run auto-format if forbidden by `project.md`

## Next Steps
STOP and wait for user to request `/git-commit` or `/create-pr`.
