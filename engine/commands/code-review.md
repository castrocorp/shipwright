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
git log {BASE_BRANCH}..HEAD --format=%B      # Full commit bodies (used as PR_DESCRIPTION hypothesis)
```

**Pre-compute git history** for the reviewer agent (the agent cannot run shell commands):

For each changed file, collect:
```bash
git log -5 --oneline -- <file>               # Recent history per file
git blame -L <changed-ranges> <file>         # Authorship of surrounding code
```

**Pre-compute PR context** (if `gh` CLI is available):
```bash
gh pr list --state merged --search "<filename>" --limit 3 --json title,url,number
gh pr view --json body,title                 # Current PR body (if a PR already exists)
```
If `gh` is unavailable, omit `RECENT_PRS` from the prompt — the agent handles its absence gracefully. For `PR_DESCRIPTION`, fall back to the full commit bodies collected above.

Read all CLAUDE.md files relevant to the changed directories.

Assemble the agent prompt with these sections:

| Section | Source |
|---------|--------|
| `DIFF` | `git diff {BASE_BRANCH}...HEAD` |
| `CHANGED_FILES` | `git diff {BASE_BRANCH}...HEAD --name-only` |
| `COMMIT_LOG` | `git log {BASE_BRANCH}..HEAD --oneline` |
| `GIT_HISTORY` | Pre-computed `git log` + `git blame` per changed file |
| `RECENT_PRS` | Pre-computed from `gh pr list` (omit if `gh` unavailable) |
| `STACK_RULES` | Contents of `~/.claude/stacks/{STACK}.md` |
| `PROJECT_STANDARDS` | Relevant CLAUDE.md sections |
| `TICKET_CONTEXT` | Acceptance criteria from `/analyze-jira` or equivalent (if available in conversation) |
| `PR_DESCRIPTION` | Current PR body from `gh pr view` if present, else full commit bodies. Fed to the agent as a hypothesis to falsify, not a summary to accept. |
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
- Run the nine-dimension adversarial review
- Run the adversarial audit pass (generating at least five concrete failure modes)
- Apply stack-specific rules
- Post a tier-bucketed summary to the Slack thread
- Return findings report with `[BLOCKER]`, `[FINDING]`, `[SUSPICION]`, `[ADVERSARIAL]` tags

## Step 4: Address Agent Findings

Every returned finding carries exactly one tier tag. Treat each tier differently:

1. **`[BLOCKER]`** (confidence 90+) → Fix immediately. Do not proceed to `/git-commit` or `/create-pr` with an unaddressed blocker.
2. **`[FINDING]`** (confidence 75–89) → Fix before merge unless explicitly scoped out. If scoping out, document the reason in the PR description.
3. **`[SUSPICION]`** (confidence 50–74) → Verify the concern. If the reviewer was wrong, note why (in conversation or PR body). If the reviewer was right, fix it.
4. **`[ADVERSARIAL][score]`** (generated failure modes) → For each, either add the proposed test, fix the gap, or justify why the failure mode cannot occur in practice.

Re-run tests after making changes. Do not suppress a tier by silently ignoring it — every tag must be addressed or explicitly scoped out.

## Step 5: Document Actions Taken
If `.slack-thread` exists, post summary to Slack thread: findings addressed per tier, tests still passing, any suspicions scoped out with justification. Otherwise, output to terminal.

## Rules
- If `.slack-thread` exists, notify in EXISTING thread before calling agent
- If `.slack-thread` is absent, skip all Slack — do not fail
- Inject ALL context into agent prompt — agent must NOT need to read config files
- Address every returned finding by tier (fix, verify, or scope out with justification)
- Never silently drop a `[SUSPICION]` — either verify or document why it is dismissed
- Re-run tests after changes
- NEVER run auto-format if forbidden by `project.md`

## Next Steps
STOP and wait for user to request `/git-commit` or `/create-pr`.
