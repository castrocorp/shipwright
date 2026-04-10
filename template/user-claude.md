# Personal Claude Code Instructions

> **DO NOT duplicate workflow rules here.** Shipwright's `CLAUDE.md` (symlinked to `~/.claude/CLAUDE.md` by `install.sh`) is the single source of truth for the pipeline, commands, error recovery, and prohibited actions.
>
> This file is for **personal overrides only** — preferences that are specific to YOU, not to the workflow.

## What belongs here

- Your communication preferences (language, verbosity, style)
- Personal Slack channel ID (if different from project default)
- Personal JIRA account ID (for assignee/reporter defaults)
- Tool-specific preferences (editor, terminal, shell)
- Any rule that applies to ALL your projects but is NOT part of Shipwright

## Example

```markdown
# Personal Overrides

## Identity
- **JIRA account ID**: `abc123def456`
- **Slack DM channel**: `U077ADYKWKV`

## Preferences
- Respond in Portuguese when I write in Portuguese
- Keep responses concise — no trailing summaries
- Use `gw` wrapper instead of `./gradlew` when available

## Project-Specific
- For repos under `~/work/`, default stack is `kotlin-spring`
- For repos under `~/personal/`, default stack is `typescript-react`
```

## What does NOT belong here

- Workflow pipeline definition → `engine/CLAUDE.md`
- Command sequences → `engine/CLAUDE.md`
- Error recovery rules → `engine/CLAUDE.md`
- Testing standards → `engine/CLAUDE.md`
- Branch management → `engine/CLAUDE.md`
- PR requirements → `engine/CLAUDE.md`
- Prohibited actions → `engine/CLAUDE.md`
- Code quality rules → `engine/stacks/<stack>.md`
- Project-specific config → `.claude/project.md` (per repo)
