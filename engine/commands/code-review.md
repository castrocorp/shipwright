---
description: Request comprehensive code review from project's reviewer agent with Slack updates
---

# Code Review Command

## Step 0: Load Config
Read `.claude/project.md` for: `SLACK_CHANNEL`, `SLACK_TOOL`, reviewer agent name, stack name, `BASE_BRANCH`.
Read `~/.claude/stacks/{STACK}.md` for: review criteria.
Read `.slack-thread` for: thread timestamp (if file exists).

## Step 0.5: Probe Integrations

1. **Slack MCP**: Check if `.slack-thread` exists.
   - Present → post phase updates to Slack thread
   - Absent → skip all Slack posts, continue silently

2. **Stack adapter**: Check if `~/.claude/stacks/{STACK}.md` exists.
   - Present → include stack-specific rules in agent prompt
   - Absent → proceed with generic review criteria only

## Prerequisites
- Implementation complete (from `/tdd-ralph`)
- All tests passing

## Step 1: Notify in Slack Thread (if available)
If `.slack-thread` exists, post that code review is starting. Otherwise, skip.

## Step 2: Gather Context for the Agent

Collect ALL context the reviewer agent needs — the agent does NOT read config files itself.

Run in parallel:
```bash
git diff {BASE_BRANCH}...HEAD --name-only    # Changed files
git diff {BASE_BRANCH}...HEAD                # Full diff
git log {BASE_BRANCH}..HEAD --oneline        # Commits on this branch
```

Read all CLAUDE.md files relevant to the changed directories.

Assemble the agent prompt with these sections:

| Section | Source |
|---------|--------|
| `DIFF` | `git diff {BASE_BRANCH}...HEAD` |
| `CHANGED_FILES` | `git diff {BASE_BRANCH}...HEAD --name-only` |
| `COMMIT_LOG` | `git log {BASE_BRANCH}..HEAD --oneline` |
| `STACK_RULES` | Contents of `~/.claude/stacks/{STACK}.md` |
| `PROJECT_STANDARDS` | Relevant CLAUDE.md sections |
| `JIRA_CONTEXT` | Acceptance criteria from `/analyze-jira` (if available in conversation) |
| `SLACK_THREAD` | `{ "tool": "{SLACK_TOOL}", "channel": "{SLACK_CHANNEL}", "timestamp": "{THREAD_TS}" }` (omit if `.slack-thread` absent) |
| `ORACLE_AGENTS` | Cross-repo oracle agent names from `project.md` (if any) |

## Step 3: Launch Reviewer Agent

Use the Agent tool with the reviewer agent configured in `project.md`:

```
Agent({
  subagent_type: "{REVIEWER_AGENT}",
  prompt: "<assembled prompt with all sections above>"
})
```

The agent receives everything it needs in the prompt. It will:
- Review all 6 dimensions
- Apply stack-specific rules
- Post findings to Slack thread
- Return findings report

## Step 4: Address Agent Findings

For each finding:
1. **Critical issues** (security, logic errors) → Fix immediately
2. **Code quality** (naming, clarity) → Fix and improve
3. **Suggestions** (alternatives, optimizations) → Evaluate and apply if valuable

Re-run tests after making changes.

## Step 5: Document Actions Taken
If `.slack-thread` exists, post summary to Slack thread: suggestions addressed, tests still passing. Otherwise, output to terminal.

## Rules
- If `.slack-thread` exists, notify in EXISTING thread before calling agent
- If `.slack-thread` is absent, skip all Slack — do not fail
- Inject ALL context into agent prompt — agent must NOT need to read config files
- Address ALL suggestions (fix or explain why not)
- Re-run tests after changes
- NEVER run auto-format if forbidden by `project.md`

## Next Steps
STOP and wait for user to request `/git-commit` or `/create-pr`.
