---
description: Post update to existing Slack thread
---

# Slack Update Command

## Step 0: Load Config
Read `.claude/project.md` for: `SLACK_CHANNEL`, `SLACK_TOOL`.

## Step 1: Find Thread File

```bash
THREAD_FILE=$(ls .slack-thread 2>/dev/null | head -1)
```

If not found → log `WARN: No .slack-thread file found — Slack updates skipped.` and exit gracefully. Do NOT error.

## Step 2: Extract Thread Info

Read `timestamp`, `channel`, `task_id` from the thread file.

## Step 3: Post to Thread

```
{SLACK_TOOL}:slack_reply_to_thread(
  channel_id: "{CHANNEL}",
  thread_ts: "{TIMESTAMP}",
  text: "{MESSAGE}"
)
```

If the Slack MCP call fails, log `WARN: Slack post failed — continuing without notification.` and exit gracefully. Do NOT retry more than once. Do NOT stop the calling workflow.

## Formatting
- Bold: `*text*`
- Code: `` `inline` ``
- Bullets: `•`
- Status emojis: pass, fail, in progress, warning

## Rules
- NEVER create new thread (always reply to existing)
- ALWAYS read timestamp from `.slack-thread` file
- Use `slack_reply_to_thread` (NOT `slack_post_message`)
- Use the Slack tool name from `project.md`
- If `.slack-thread` is absent, skip silently — never fail
- If Slack MCP is unreachable, skip silently — never block the pipeline
