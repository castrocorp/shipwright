---
description: Record a lesson learned from an incident, bug fix, or code review to prevent recurrence
---

# Record Lesson Command

## Purpose
Capture lessons from incidents, bugs, or code review findings so `/check-lessons` can surface them before future implementations.

## Step 0: Load Config
Read `.claude/project.md` for: `SLACK_CHANNEL`, `SLACK_TOOL`.
Read `.slack-thread` for: thread timestamp (if file exists).

## Step 1: Gather Lesson Context

Determine the source — one of:
- **Code review finding**: Extract from the current conversation (agent feedback)
- **Bug fix**: Extract from `/bug-analyze` output or the fix itself
- **Incident**: User describes what happened
- **Manual**: User explicitly tells you what to record

For each lesson, extract:
- **Category**: One of `proxying`, `streaming`, `migrations`, `permissions`, `fields`, `security`, `testing`, `integration`, `performance`, `other`
- **Rule**: What to do (or not do) next time
- **Context**: What happened that prompted this lesson
- **Prevention**: Specific checks to apply before similar changes

## Step 2: Find or Create Lessons File

```bash
# Project-specific memory directory
MEMORY_DIR="$HOME/.claude/projects/$(pwd | sed 's|/|-|g')/memory"
LESSONS_FILE="$MEMORY_DIR/lessons-learned.md"

mkdir -p "$MEMORY_DIR"
```

If `lessons-learned.md` does not exist, create it with the header:
```markdown
# Lessons Learned

Patterns and prevention rules from past incidents. Read by `/check-lessons` before implementation.
```

## Step 3: Append Lesson

Append to the file using this format:

```markdown

## {Category}: {Short title}

**Date**: {YYYY-MM-DD}
**Source**: {code-review | bug-fix | incident | manual}
**Ticket**: {TICKET_ID} (if applicable)

**What happened**: {Brief description of what went wrong or what was discovered}

**Rule**: {What to do or avoid next time}

**Prevention checklist**:
- [ ] {Specific check 1}
- [ ] {Specific check 2}
```

## Step 4: Confirm and Report

Print the recorded lesson to the user for verification.

If `.slack-thread` exists, post a brief update:
```
Lesson recorded: {Category} — {Short title}
```

## Rules

- NEVER overwrite existing lessons — always append
- Use a clear, searchable title
- Include the ticket ID if this came from a JIRA task
- Categories must match the ones `/check-lessons` cross-references
- Keep each lesson self-contained — someone reading it months later should understand the context
- If the user provides vague input, ask clarifying questions before recording
