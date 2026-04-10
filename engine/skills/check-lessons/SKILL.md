---
name: check-lessons
description: Review lessons learned from past incidents before implementation. Use before writing any implementation code.
---

Before writing implementation code, review all lessons-learned memory files to avoid repeating past mistakes.

## Steps

1. **Find all lessons-learned files** across project memory directories:
   - Search `~/.claude/projects/*/memory/lessons-learned.md`
   - Also check `./.claude/memory/` in the current project if it exists
   - If no files found: report "No lessons-learned files found" and continue — this is not an error

2. **Read every file found** and extract all patterns, fixes, and prevention rules. If no files were found in step 1, skip to step 4 and report that no lessons were available.

3. **Cross-reference with the current task**:
   - Proxying or streaming? → Check CORS/header patterns
   - Database migrations? → Check transaction patterns
   - Permissions or context? → Check context-gap patterns
   - New fields or entities? → Check row-mapper/DAO patterns
   - Any other match? → Apply the relevant prevention rules

4. **Report findings** to the Slack thread (if active):
   - How many lessons reviewed
   - Which ones apply to current task
   - Specific precautions to take

## Rules

- ALWAYS run before `/tdd-ralph`
- Read ALL lessons-learned files, not just the current project's
- Never skip even if the task seems simple
- If a lesson applies, explicitly note it in the implementation plan
