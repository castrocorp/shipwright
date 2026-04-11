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

## Input modes

### With Atlassian MCP (full RAG pipeline)

With MCP servers connected, Shipwright pulls acceptance criteria, linked tickets, and sprint context directly from JIRA — a full retrieval-augmented pipeline from your project management tool to implementation.

```
implement XPTO-5311
```

That's it. The engine fetches everything it needs from JIRA, transitions the ticket, and tracks progress in Slack.

### Without JIRA (prompt-based)

No MCP servers? No problem. Provide a structured prompt and the same pipeline runs with context from your description:

```
implement Add rate limiting to the /api/documents endpoint.
Limit: 100 req/min per API key.

## Acceptance Criteria
- Return 429 with Retry-After header
- Rate tracked per API key, not per IP
- Configurable via environment variable
- Existing tests must not break

## Technical Notes
- Use Redis for distributed counting
- Follow middleware pattern in src/api/
```

The engine derives the branch name and context from your prompt. Same TDD loop, same code review, same quality — just without the JIRA automation.

## What's included

```
engine/
  CLAUDE.md          — Workflow pipeline and orchestration
  agents/            — Isolated agents (code-reviewer, tech-lead)
  commands/          — Pipeline steps (start-task, tdd-ralph, health-check, etc.)
  prompts/           — Reusable prompt templates (worker-agent)
  rules/             — Universal rules auto-loaded by Claude Code
  skills/            — Reusable skills (check-lessons, slack-rules, parallel-implement)
  stacks/            — Language/framework adapters (kotlin-spring, etc.)
VERSION              — Current version number
update.sh            — Update to latest version
check-update.sh      — Background version check (non-blocking)
template/
  project.md         — Template for per-project configuration
  mcp.json           — Pre-configured MCP servers (Slack, Atlassian, Notion)
  user-claude.md     — Template for personal overrides (~/.claude/CLAUDE.local.md)
install.sh           — Mac/Linux installer (per-file merge for rules/stacks)
install.ps1          — Windows installer
uninstall.sh         — Mac/Linux uninstaller (removes only engine symlinks)
uninstall.ps1        — Windows uninstaller
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
/init-shipwright

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
| Stack adapters | `~/.claude/stacks/{stack}.md` (symlinked) | Per-stack, referenced by project config |
| Personal overrides | `~/.claude/CLAUDE.local.md` | All projects |
| Project config | `.claude/project.md` | One project |

Run `/init-shipwright` to auto-detect stack, build tool, base branch, and MCP servers.

## Updating

```bash
# Check for updates (includes signature verification)
./update.sh --check

# Update to latest version
./update.sh

# Update to a specific version
./update.sh --version v1.2.0
```

For automatic background checks, add the hook from `template/hooks.md` to your `settings.json`. Shipwright will show a one-line notice at `/start-task` when an update is available.

### Security

Every release tag is GPG-signed. The updater verifies the signature before applying any changes:

- **Signed tag + valid signature**: update proceeds automatically
- **Unsigned tag**: updater warns and asks for confirmation
- **Invalid/untrusted signature**: updater blocks and warns of potential compromise

You can bypass verification with `--skip-verify` (not recommended for public forks).

**To verify signatures**, import the maintainer's public key:

```bash
# From the repo
gpg --import PUBKEY.asc

# Or from a keyserver
gpg --keyserver keys.openpgp.org --recv-keys A8697988B2D8E6C579651CE03DCF9E5E79224F67
```

**For maintainers** — to sign a release:

```bash
# Ensure git is configured with your GPG key
git config user.signingkey <YOUR_GPG_KEY_ID>

# Create a signed tag
git tag -s v1.3.0 -m "v1.3.0"
git push origin v1.3.0
```

## Uninstalling

```bash
./uninstall.sh       # Mac/Linux
.\uninstall.ps1      # Windows (PowerShell)
```

The uninstaller removes only engine-owned symlinks. Your personal files (`CLAUDE.local.md`, user rules, settings, projects, plugins) are never touched.

## Extending Shipwright

### Adding a stack adapter

1. Copy `engine/stacks/_template.md` to `engine/stacks/{your-stack}.md`
2. Fill in language-specific rules (style, linting, testing, conventions)
3. Set `Stack: {your-stack}` in your project's `.claude/project.md`
4. The adapter is automatically injected into `/tdd-ralph` and `/code-review`

### Adding a command

1. Create `engine/commands/{your-command}.md` with frontmatter:
   ```yaml
   ---
   description: What this command does
   ---
   ```
2. Follow the standard pattern: load config → probe integrations → execute → fallback → report
3. If it's part of the pipeline, add it to the workflow sequence in `engine/CLAUDE.md`
4. Run `./validate.sh` to verify

### Adding an agent

1. Create `engine/agents/{your-agent}.md` with frontmatter:
   ```yaml
   ---
   name: your-agent
   description: "When to use this agent"
   model: opus
   ---
   ```
2. Agents receive ALL context via the prompt — they do NOT read config files or run shell commands
3. Reference the agent in commands via `Agent({ subagent_type: "your-agent" })`

### Adding a rule

1. Create `engine/rules/{your-rule}.md` (no frontmatter required)
2. For file-type-specific rules, add `paths:` frontmatter:
   ```yaml
   ---
   paths:
     - "**/*.py"
   ---
   ```
3. Rules are auto-loaded by Claude Code after `install.sh` symlinks them

## License

[MIT](LICENSE)
