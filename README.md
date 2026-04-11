# Shipwright

Ticket in, PR out. Shipwright is a development workflow engine for [Claude Code](https://claude.ai/code) that automates the entire pipeline — from JIRA ticket to Pull Request — with TDD, code review, and Slack tracking built in.

## What it does

Give Claude a ticket ID and Shipwright runs the full pipeline automatically:

```
/start-task          Slack thread + JIRA → In Progress
    ↓
/analyze-jira        Fetch AC, linked tickets, attachments
    ↓
/create-branch       fix/ or feat/ based on JIRA type
    ↓
/check-lessons       Review past incidents before coding
    ↓
/tdd-ralph           Red → Green → Refactor (up to 30 iterations)
    ↓
/code-review         Independent 6-dimension review
    ↓
/create-pr           Push, PR, JIRA → Code Review
```

Multiple tickets? They run in parallel with isolated git worktrees:

```
/parallel-implement XPTO-101 XPTO-102 XPTO-103
```

## What's included

```
engine/
  CLAUDE.md          — Workflow pipeline and orchestration
  agents/            — Isolated agents (code-reviewer, tech-lead)
  commands/          — Pipeline steps (start-task, tdd-ralph, code-review, etc.)
  prompts/           — Reusable prompt templates (worker-agent)
  rules/             — Universal rules auto-loaded by Claude Code
  skills/            — Reusable skills (check-lessons, slack-rules, parallel-implement)
  stacks/            — Language/framework adapters (kotlin-spring, etc.)
template/
  project.md         — Template for per-project configuration
  mcp.json           — Pre-configured MCP servers (Slack, Atlassian, Notion)
  user-claude.md     — Template for personal overrides (~/.claude/CLAUDE.local.md)
install.sh           — Mac/Linux installer
install.ps1          — Windows installer
validate.sh          — Validates engine structure
```

## Quick start

```bash
# Clone
git clone <this-repo> ~/dotfiles/shipwright

# Install (creates symlinks into ~/.claude/)
cd ~/dotfiles/shipwright
chmod +x install.sh && ./install.sh    # Mac/Linux
.\install.ps1                           # Windows (PowerShell)

# Initialize your project
cd /path/to/your/project
/init-project

# Fill in any {PLACEHOLDER} values
$EDITOR .claude/project.md
```

## Key features

- **Full pipeline automation** — one command triggers the entire flow from ticket to PR
- **TDD-first** — unit tests before implementation, every time
- **Independent code review** — isolated agent that never sees implementation decisions
- **Parallel execution** — 2-5 tickets simultaneously via git worktrees
- **Slack tracking** — one thread per task, every step posts updates
- **JIRA transitions** — automatic In Progress / Code Review state changes
- **Graceful degradation** — every integration (Slack, JIRA, `gh`, ralph-loop) is optional; the core pipeline works with zero MCP servers
- **Stack adapters** — language-specific rules injected into TDD and review (ships with `kotlin-spring`, extensible)

## Dependencies

All optional. The engine degrades gracefully without any of them.

| Dependency | What it enables |
|------------|----------------|
| **Slack MCP** | Thread tracking, status updates |
| **Atlassian MCP** | JIRA analysis, transitions, ticket creation |
| **`gh` CLI** | Automated PR creation |
| **ralph-loop plugin** | Iterative TDD loop |

## Configuration

Three layers, from general to specific:

| Layer | File | Scope |
|-------|------|-------|
| Engine workflow | `~/.claude/CLAUDE.md` (symlinked) | All projects |
| Universal rules | `~/.claude/rules/*.md` (symlinked) | All projects, auto-loaded |
| Personal overrides | `~/.claude/CLAUDE.local.md` | All projects |
| Project config | `.claude/project.md` | One project |

Run `/init-project` to auto-detect stack, build tool, base branch, and MCP servers.

## License

[MIT](LICENSE)
