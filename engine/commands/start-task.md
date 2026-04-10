---
description: Initialize a new task with Slack thread creation, file persistence, and JIRA transition
---

# Start Task Command

## Step 0: Load Project Config
Read `.claude/project.md` and extract: `SLACK_CHANNEL`, `SLACK_TOOL`, `JIRA_CLOUD_ID`.

## Step 1: Create Slack Thread

Post to the Slack channel using the configured tool:
```
{SLACK_TOOL}:slack_post_message(
  channel_id: "{SLACK_CHANNEL}",
  text: "🚀 *{TICKET_ID}: {Task Title}*\n\nStarting complete implementation..."
)
```

**SAVE THE TIMESTAMP** from the response immediately.

## Step 2: Thread Title Format
Use a comprehensive title covering the ENTIRE task:
- CORRECT: `🚀 ART-5311: [Full ticket title]`
- WRONG: `Analysis: ART-5311` (too specific to one phase)

## Step 3: Persist Thread Timestamp to File

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

## Step 4: Transition JIRA Ticket to "In Progress"

If a JIRA ticket ID is available:
1. `getTransitionsForJiraIssue(issue_key: "{TICKET_ID}")`
2. Find the transition with name containing "In Progress"
3. `transitionJiraIssue(issue_key: "{TICKET_ID}", transition_id: "{FOUND_ID}")`

If the transition fails, log it to the Slack thread and continue — do NOT stop the workflow.

## Step 5: Post Initial Status Update

Reply to the thread with initial status:
```
{SLACK_TOOL}:slack_reply_to_thread(
  channel_id: "{SLACK_CHANNEL}",
  thread_ts: "{SAVED_TIMESTAMP}",
  text: "📋 *Task Initialization*\n\n• JIRA ticket transitioned to In Progress\n• Analyzing requirements\n• Preparing to execute task..."
)
```

## Rules

### DO:
- Create ONE thread per task
- Save timestamp to `.slack-thread` immediately
- Transition JIRA before any dev work
- Use comprehensive title covering entire task

### DO NOT:
- Create multiple threads for one task
- Use phase-specific titles
- Proceed without creating Slack thread first
- Hardcode Slack channel — always read from `project.md`

## Thread Lifecycle
**ONE TASK = ONE THREAD = ONE TIMESTAMP** — used for analysis, implementation, testing, code review, and completion.

## Next Steps
1. If JIRA ticket → `/analyze-jira`
2. If creating branch → `/create-branch`
