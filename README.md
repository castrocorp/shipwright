# Claude Workflow Engine

Reusable AI-powered development workflow for Claude Code. Provides a complete pipeline from JIRA ticket to Pull Request, with TDD, code review, and Slack tracking.

## What's included

```
engine/
  CLAUDE.md          — Workflow rules and pipeline definition
  commands/          — Pipeline steps (start-task, tdd-ralph, code-review, etc.)
  skills/            — Reusable skills (check-lessons, slack-rules)
  stacks/            — Language/framework adapters (kotlin-spring, etc.)
template/
  project.md         — Template for per-project configuration
install.sh           — Mac/Linux installer
install.ps1          — Windows installer (requires Developer Mode)
```

## Quick start

```bash
# 1. Clone
git clone <this-repo> ~/dotfiles/claude-workflow

# 2. Install (creates symlinks into ~/.claude/)
cd ~/dotfiles/claude-workflow

# Mac/Linux
chmod +x install.sh && ./install.sh

# Windows (PowerShell as admin or with Developer Mode)
.\install.ps1

# 3. Configure your project
cp template/project.md /path/to/your/project/.claude/project.md
# Edit project.md with your Slack channel, JIRA cloud ID, build commands, etc.
```

## Pipeline

```
/start-task → /analyze-jira → /bug-analyze (bugs only)
  → /create-branch → /check-lessons → /tdd-ralph
  → /code-review → STOP
  → [user requests] → /git-commit → /create-pr
```

## Per-project configuration

Every command reads `.claude/project.md` in the project root for:
- Slack channel and tool name
- JIRA cloud ID and project prefixes
- Build/test/lint commands
- Branch naming convention
- Base branch
- PR template path and JIRA link format

See `template/project.md` for the full reference.

## Stack adapters

Stack adapters live in `engine/stacks/` and provide language-specific code quality rules. Commands reference `stacks/<stack>.md` based on what's declared in `project.md`.

Available stacks:
- `kotlin-spring` — Kotlin functional style, SOLID, ktlint, Spring Boot conventions

To add a new stack, create `engine/stacks/<your-stack>.md` following the same format.

## Architecture: commands vs agents vs skills

Claude Code has three extension types. Each serves a different purpose:

| Type | Runs in | Context | Best for |
|------|---------|---------|----------|
| **Command** | Current session | Sees full conversation history | Pipeline steps that build on each other |
| **Agent** | Fresh session | Isolated — receives context via prompt only | Independent work, fresh perspective, parallelism |
| **Skill** | Current session | Loaded on demand, not a pipeline step | Reusable snippets, rules, templates |

### Why pipeline steps are commands

The pipeline is sequential and cumulative:

```
/start-task      → creates Slack thread, saves ticket ID
/analyze-jira    → reads ticket ID from context, adds AC and findings
/check-lessons   → reads task description from context, adds precautions
/tdd-ralph       → reads AC + lessons + bug analysis from context, composes ralph-loop prompt
/git-commit      → reads what was changed from context
/create-pr       → reads all commits from context
```

Each step depends on what the previous steps produced. Commands share the conversation, so this context flows naturally. If these were agents, every step would need the full context serialized into the prompt — redundant and fragile.

### Why code-reviewer is an agent

The reviewer must give an **independent assessment**. If it ran as a command in the same session, it would be biased by the implementation decisions it watched being made. Isolation is the feature — the reviewer only sees the diff and the standards, not the reasoning behind shortcuts.

### Why tech-lead is an agent

Ticket creation is a **separate concern** from the pipeline. The tech-lead refines requirements, creates JIRA tickets, and optionally kicks off the pipeline. It doesn't need implementation context — it needs a clean slate to ask good clarifying questions. It can also run in parallel (create ticket while exploring codebase).

### Why check-lessons and slack-rules are skills

They're **reusable fragments** loaded into commands and agents, not standalone pipeline steps. `slack-rules` is a template injected into agent prompts so they post to the right thread. `check-lessons` is invoked before implementation to scan memory files.

### Decision guide for new extensions

```
Need prior pipeline context?
  YES → Command
  NO  → Does it need a fresh perspective or parallelism?
          YES → Agent
          NO  → Is it a reusable snippet/template/rule set?
                  YES → Skill
                  NO  → Command (default)
```

## What stays local (never symlinked)

- `~/.claude/settings.json` — personal permissions
- `~/.claude/settings.local.json` — local overrides
- `~/.claude/plugins/` — installed plugins cache
- `~/.claude/projects/` — per-project memory

## Requirements

- [Claude Code](https://claude.ai/code) CLI installed
- MCP servers configured for your integrations (Slack, JIRA, etc.)
- [ralph-loop plugin](https://github.com/anthropics/claude-code-plugins) installed (for `/tdd-ralph`)
