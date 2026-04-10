---
description: Create and checkout development branch with proper naming from JIRA ticket type
---

# Create Branch Command

## Step 0: Load Config
Read `.claude/project.md` for: `BASE_BRANCH`, branch convention, `SLACK_CHANNEL`, `SLACK_TOOL`.
Read `.slack-thread` for: thread timestamp (if file exists).

## Step 1: Determine Branch Type

**Primary method** — from JIRA (if Atlassian MCP is available):

Fetch ticket type: `getJiraIssue(issue_key: "{TICKET_ID}")`

Apply branch convention from `project.md`:
- Bug → `fix/{TICKET_ID}`
- Other → `feat/{TICKET_ID}`

**Fallback** — when Atlassian MCP is unavailable:

1. Check if `/analyze-jira` or `/bug-analyze` already identified the ticket type in the conversation → use that.
2. Check if the user explicitly mentioned "bug", "fix", "defect" in their request → use `fix/`.
3. Otherwise, default to `feat/` and log: `WARN: Atlassian unavailable — defaulting to feat/ prefix. Use fix/ if this is a bug.`

## Step 2: Update Slack Thread (if available)
If `.slack-thread` exists, post branch creation intent to existing thread. Otherwise, skip.

## Step 3: Branch Creation

```bash
git checkout {BASE_BRANCH}
git pull origin {BASE_BRANCH}
git checkout -b {prefix}/{TICKET_ID}
```

## Step 4: Verify and Notify
```bash
git branch --show-current
```
If `.slack-thread` exists, post confirmation to Slack thread. Otherwise, output to terminal.

## Rules
- ALWAYS branch from the base branch in `project.md`
- NEVER work directly on the base branch
- Check JIRA ticket type FIRST when Atlassian is available
- When Atlassian is unavailable, infer from context or default to `feat/`
- If `.slack-thread` exists, notify in Slack BEFORE and AFTER. Otherwise, skip.

## Next Steps
1. Check lessons → `/check-lessons`
2. Start TDD → `/tdd-ralph`
