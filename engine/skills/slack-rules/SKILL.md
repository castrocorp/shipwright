---
name: slack-rules
description: Slack thread management rules and agent communication template. Use whenever posting to Slack or spawning subagents that need Slack access.
user-invocable: false
---

# Slack Thread Management

## Core Rules

- **ONE TASK = ONE THREAD = ONE TIMESTAMP**
- Thread timestamp stored in `.slack-thread` file
- NEVER create multiple threads for same task
- ALL commands read from same `.slack-thread` file

## Tool Configuration

Read Slack tool name and channel from `.claude/project.md`.
- **Initial Thread**: Created by `/start-task` only
- **All Updates**: Via `/slack-update` (uses `slack_reply_to_thread`)
- **Thread State**: Persisted in `.slack-thread` file

## Agent Communication Template

When calling ANY agent that needs Slack, include this in the prompt:

```
SLACK THREAD MANAGEMENT:
1. Read thread timestamp from .slack-thread file:
   - File location: ./.slack-thread
   - Extract: timestamp and channel fields

2. Use these EXACT parameters for ALL Slack posts:
   - Tool: {SLACK_TOOL from project.md}
   - Method: slack_reply_to_thread
   - Thread timestamp: [value from .slack-thread]
   - Channel: {SLACK_CHANNEL from project.md}

3. CRITICAL RULES:
   - DO NOT create new thread under ANY circumstances
   - DO NOT use slack_post_message (only slack_reply_to_thread)
   - DO NOT guess or generate timestamps
   - If .slack-thread missing, FAIL with clear error

4. Message formatting:
   - Use *bold* for emphasis, `code` for inline code
   - Use • for bullet points, \n for line breaks
```
