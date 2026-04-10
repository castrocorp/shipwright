---
description: Create and checkout development branch with proper naming from JIRA ticket type
---

# Create Branch Command

## Step 0: Load Config
Read `.claude/project.md` for: `BASE_BRANCH`, branch convention, `SLACK_CHANNEL`, `SLACK_TOOL`.
Read `.slack-thread` for: thread timestamp.

## Step 1: Determine Branch Type from JIRA

Fetch ticket type: `getJiraIssue(issue_key: "{TICKET_ID}")`

Apply branch convention from `project.md`:
- Default: Bug → `fix/{TICKET_ID}`, Other → `feat/{TICKET_ID}`

## Step 2: Update Slack Thread
Post branch creation intent to existing thread.

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
Post confirmation to Slack thread.

## Rules
- ALWAYS branch from the base branch in `project.md`
- NEVER work directly on the base branch
- Check JIRA ticket type FIRST — never guess the prefix
- Notify in Slack BEFORE and AFTER

## Next Steps
1. Check lessons → `/check-lessons`
2. Start TDD → `/tdd-ralph`
