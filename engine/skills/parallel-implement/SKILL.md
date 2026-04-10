---
name: parallel-implement
description: Implement multiple JIRA tickets in parallel using isolated git worktrees. Use when 2+ ticket IDs are provided for implementation.
---

# Parallel Multi-Ticket Implementation

Orchestrate parallel implementation of multiple JIRA tickets using git worktrees for isolation. Each ticket gets its own worktree and Slack thread. Agents do **file edits only** — the orchestrator handles all git, build, and gh operations.

## Usage

```
/parallel-implement TICKET-1 TICKET-2 [TICKET-3 ...] [--dry-run]
```

## Constraints

- **Minimum**: 2 ticket IDs required
- **Maximum**: 5 parallel agents (prevents memory/API exhaustion)
- **Stagger**: 2-second delay between launches when 4+ agents

## Prerequisites

Read `.claude/project.md` for:
- `SLACK_CHANNEL`, `SLACK_TOOL`
- `BASE_BRANCH`
- Branch convention (fix/ vs feat/ based on JIRA type)
- Repo mapping (ticket prefix → repo path)
- Build/test/lint commands
- Stack name (for code quality rules)

## Responsibility Split

| Who | What |
|-----|------|
| **Orchestrator** (this session) | git fetch/pull, worktree creation, branch creation, git push, build/test, git commit, gh pr create |
| **Agents** | Read files, analyze JIRA, write/edit source and test files, return a file-edit manifest |

Agents MUST NOT run any shell commands. All git, build, and gh operations happen in the orchestrator after agents return.

---

## Orchestration Steps

### Step 1: Parse and Validate

1. Parse ticket IDs from `$ARGUMENTS` (space-separated)
2. Reject if fewer than 2 tickets
3. Reject if more than 5 tickets
4. If `--dry-run` flag present, print plan and stop
5. Generate orchestration ID: `parallel-{YYYYMMDD-HHmmss}`

### Step 2: Map Tickets to Repos

Read the repo mapping table from `.claude/project.md`. For each ticket ID, match the prefix to determine the source repo path.

If a prefix has no match, use the current working directory as default.

### Step 3: Fetch Latest Base Branch

For each **unique** repo (deduplicate if multiple tickets share a repo), run sequentially to avoid git lock conflicts:

```bash
git -C <REPO_PATH> fetch origin
git -C <REPO_PATH> pull origin {BASE_BRANCH}
```

### Step 4: Create Worktrees

Create one worktree per ticket using a shared orchestration directory:

```bash
ORCH_DIR="$HOME/claude-parallel/{ORCHESTRATION_ID}"
mkdir -p "$ORCH_DIR"

# For each ticket:
git -C <REPO_PATH> worktree add --detach "$ORCH_DIR/{TICKET_ID}" origin/{BASE_BRANCH}
```

**MANDATORY verification** after each worktree add:
```bash
git -C <REPO_PATH> worktree list | grep "{TICKET_ID}"
```
If NOT found → **STOP immediately** with error.

### Step 5: Fetch JIRA Ticket Types

For each ticket, fetch issue type from JIRA to determine branch prefix:
- `"Bug"` → `fix/`
- Anything else → `feat/`

### Step 6: Create Branches

For each ticket, create and push the branch:
```bash
git -C "$ORCH_DIR/{TICKET_ID}" checkout -b {prefix}/{TICKET_ID}
git -C "$ORCH_DIR/{TICKET_ID}" push -u origin {prefix}/{TICKET_ID}
```

### Step 7: Create Orchestration Slack Thread

Post ONE master thread to track overall progress:
```
{SLACK_TOOL}:slack_post_message(
  channel_id: "{SLACK_CHANNEL}",
  text: "*Parallel Implementation Started*\n\n*Orchestration*: {ORCHESTRATION_ID}\n*Tickets*: {list}\n*Agents*: {count}"
)
```

### Step 8: Create Individual Slack Threads

For EACH ticket, create a dedicated Slack thread and save it to `.slack-thread` inside the worktree:

```json
{
  "timestamp": "<thread_ts>",
  "channel": "{SLACK_CHANNEL}",
  "task_id": "<TICKET_ID>",
  "orchestration_id": "<ORCHESTRATION_ID>"
}
```

### Step 9: Launch Agents in Parallel

Launch ALL agents in a **SINGLE message** (multiple Agent tool calls) for true parallelism. If 4+ tickets, stagger with 2-second delay.

Each agent gets `subagent_type: "general-purpose"` with this prompt template (fill ALL placeholders):

```
You are implementing JIRA ticket {TICKET_ID} as part of a parallel orchestration.

WORKING DIRECTORY: {ORCH_DIR}/{TICKET_ID}

BRANCH: {prefix}/{TICKET_ID} (already created — do NOT run any git commands)

YOUR ROLE: File edits only. You MUST NOT run any shell commands (no git, no build tools, no gh).
The orchestrator handles all git, test, commit, and PR operations after you return.

WORKFLOW — Execute without stopping:

1. CHECK LESSONS LEARNED
   - Read: ~/.claude/projects/*/memory/lessons-learned.md
   - Post relevant findings to Slack thread

2. ANALYZE JIRA TICKET
   - Use Atlassian MCP to fetch ticket details
   - Extract: summary, description, type, acceptance criteria
   - Post analysis to Slack thread

3. BUG ANALYSIS (only if ticket type is Bug)
   - Investigate codebase for root cause using Read and Grep only
   - Document findings in Slack thread

4. TDD IMPLEMENTATION
   - Write unit tests FIRST (never integration for TDD)
   - Implement code to pass tests
   - Refactor
   - Post progress to Slack thread

5. SELF-REVIEW
   - Re-read every file you modified
   - Check for: security issues, missing edge cases, code style
   - Fix issues found
   - Only output <promise>DONE</promise> when satisfied

STACK RULES:
Read ~/.claude/stacks/{STACK}.md for language-specific code quality rules.

SLACK THREAD:
- Read timestamp from .slack-thread file in your working directory
- Tool: {SLACK_TOOL}
- Method: slack_reply_to_thread
- Channel: {SLACK_CHANNEL}
- NEVER create a new thread

NO AI REFERENCES in code or comments.

WHEN DONE, return a JSON manifest:
{
  "ticket_id": "{TICKET_ID}",
  "status": "success|failure",
  "files_modified": ["path/to/file1", "path/to/file2"],
  "error": null
}
```

### Step 10: Post-Agent Operations

After ALL agents return, process each ticket sequentially:

#### 10a. Lint Check
Run the lint command from `project.md`. Fix violations manually, re-run until clean.

#### 10b. Run Tests (with retry loop)
Run the test command from `project.md`.

- **Pass** → proceed to commit
- **Fail (retry 1 or 2)**: Re-launch agent with test failure output injected. Wait, re-run lint + tests.
- **Fail after 2 retries** → mark FAILED, post to Slack, continue with others.

#### 10c. Compile Check
Run the compile command from `project.md`.

#### 10d. Commit
```bash
git -C "$ORCH_DIR/{TICKET_ID}" add <files from manifest>
git -C "$ORCH_DIR/{TICKET_ID}" commit -m "{type}({TICKET_ID}): <descriptive message>"
git -C "$ORCH_DIR/{TICKET_ID}" push
```

#### 10e. Create PR
```bash
cat <REPO_PATH>/.github/pull_request_template.md

gh pr create \
  --title "{type}({TICKET_ID}): <summary>" \
  --body "<filled template>" \
  --base {BASE_BRANCH} \
  --head {prefix}/{TICKET_ID}
```

Post PR URL to the ticket's Slack thread.

### Step 11: Summary

Post to the **orchestration** Slack thread:
```
*Parallel Implementation Complete* — {success_count}/{total} succeeded

✅ *{TICKET_1}* `{branch_1}` — <{pr_url_1}|PR #{pr_number_1}>
❌ *{TICKET_2}* `{branch_2}` — failed: {error_summary}
```

### Step 12: Present to User

Display a summary table in the terminal with ticket, status, branch, and PR URL.

---

## Error Handling

| Situation | Action |
|-----------|--------|
| Fewer than 2 tickets | STOP — reject with usage message |
| Worktree not created | STOP immediately — fatal setup error |
| Agent returns failure | Skip post-agent steps, mark FAILED, continue others |
| Tests fail after 2 retries | Mark FAILED, post to Slack, continue others |
| Lint violations | Fix manually, re-run |
| Slack MCP failure | Retry once, continue if still failing |
| Branch already exists | Delete and recreate from origin/{BASE_BRANCH} |
| PR creation fails | Retry once; if still failing, post branch name to Slack |

---

## Cleanup

After PRs are merged, clean up worktrees:

```bash
# For each ticket worktree:
git -C <REPO_PATH> worktree remove "$ORCH_DIR/{TICKET_ID}" --force

# Prune stale references
git -C <REPO_PATH> worktree prune

# Remove orchestration directory
rm -rf "$ORCH_DIR"
```
