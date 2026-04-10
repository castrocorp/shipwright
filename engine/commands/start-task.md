---
description: Initialize a new task with Slack thread creation, file persistence, and JIRA transition
---

# Start Task Command

## Step 0: Load Project Config
Read `.claude/project.md` and extract: `SLACK_CHANNEL`, `SLACK_TOOL`, `JIRA_CLOUD_ID`.

## Step 0.5: Probe Integrations

Check which integrations are available. Do NOT stop if any is missing — adapt the workflow.

1. **Slack MCP**: Attempt a lightweight call (e.g., channel info for `{SLACK_CHANNEL}`).
   - Available → proceed with thread creation
   - Unavailable → set `SLACK_AVAILABLE = false`, log: `WARN: Slack MCP not available — skipping thread creation. Workflow will continue without Slack updates.`

2. **Atlassian MCP**: Attempt `getAccessibleAtlassianResources()`.
   - Available → proceed with JIRA transition
   - Unavailable → set `JIRA_AVAILABLE = false`, log: `WARN: Atlassian MCP not available — skipping JIRA transition.`

## Step 1: Create Slack Thread (if Slack available)

If `SLACK_AVAILABLE`:

Post to the Slack channel using the configured tool:
```
{SLACK_TOOL}:slack_post_message(
  channel_id: "{SLACK_CHANNEL}",
  text: "🚀 *{TICKET_ID}: {Task Title}*\n\nStarting complete implementation..."
)
```

**SAVE THE TIMESTAMP** from the response immediately.

If `NOT SLACK_AVAILABLE`:

Skip thread creation. Do NOT create `.slack-thread`. All downstream commands will detect the missing file and skip Slack posts silently.

## Step 2: Thread Title Format
Use a comprehensive title covering the ENTIRE task:
- CORRECT: `🚀 XPTO-5311: [Full ticket title]`
- WRONG: `Analysis: XPTO-5311` (too specific to one phase)

## Step 3: Persist Thread Timestamp to File (if Slack available)

If `SLACK_AVAILABLE`:

Write the timestamp to `.slack-thread` so ALL subsequent commands can read it:
```bash
cat > .slack-thread << EOF
{
  "timestamp": "{SAVED_TIMESTAMP}",
  "channel": "{SLACK_CHANNEL}",
  "task_id": "{TICKET_ID}"
}
EOF
```

Ensure `.slack-thread` is git-ignored:
```bash
grep -q "^\.slack-thread$" .gitignore 2>/dev/null || echo ".slack-thread" >> .gitignore
```

## Step 4: Transition JIRA Ticket to "In Progress" (if Atlassian available)

If `JIRA_AVAILABLE` and a JIRA ticket ID is available:
1. `getTransitionsForJiraIssue(issue_key: "{TICKET_ID}")`
2. Find the transition with name containing "In Progress"
3. `transitionJiraIssue(issue_key: "{TICKET_ID}", transition_id: "{FOUND_ID}")`

If the transition fails, log it and continue — do NOT stop the workflow.

## Step 5: Post Initial Status Update (if Slack available)

If `SLACK_AVAILABLE`:

Reply to the thread with initial status:
```
{SLACK_TOOL}:slack_reply_to_thread(
  channel_id: "{SLACK_CHANNEL}",
  thread_ts: "{SAVED_TIMESTAMP}",
  text: "📋 *Task Initialization*\n\n• JIRA ticket transitioned to In Progress\n• Analyzing requirements\n• Preparing to execute task..."
)
```

## Step 6: Report Degraded State

If any integration was unavailable, print a summary to the user:
```
Task initialized with degraded integrations:
  Slack:     {available|skipped}
  Atlassian: {available|skipped}
```

## Rules

### DO:
- Create ONE thread per task (when Slack is available)
- Save timestamp to `.slack-thread` immediately (when Slack is available)
- Transition JIRA before any dev work (when Atlassian is available)
- Use comprehensive title covering entire task
- Continue the pipeline even if integrations are unavailable

### DO NOT:
- Create multiple threads for one task
- Use phase-specific titles
- Stop the pipeline because Slack or Atlassian is down
- Hardcode Slack channel — always read from `project.md`

## Thread Lifecycle
When Slack is available: **ONE TASK = ONE THREAD = ONE TIMESTAMP** — used for analysis, implementation, testing, code review, and completion.

When Slack is unavailable: progress is reported to the user in the terminal only.

## Next Steps
1. If JIRA ticket and Atlassian available → `/analyze-jira`
2. If creating branch → `/create-branch`
