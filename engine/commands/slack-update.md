---
description: Post update to existing Slack thread
---

# Slack Update Command

## Step 0: Load Config
Read `.claude/project.md` for: `SLACK_CHANNEL`, `SLACK_TOOL`.

## Step 1: Find Thread File

```bash
THREAD_FILE=$(ls .slack-thread .slack-thread-* 2>/dev/null | head -1)
```

If not found → ERROR. Run `/start-task` first.

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
