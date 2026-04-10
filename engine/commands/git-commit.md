---
description: Create git commit with proper message format and Slack notifications
---

# Git Commit Command

## Step 0: Load Config
Read `.claude/project.md` for: `SLACK_CHANNEL`, `SLACK_TOOL`.
Read `.slack-thread` for: thread timestamp.

## NO ROLLBACK POLICY

**NEVER** use destructive git operations:
- `git reset` (any form)
- `git commit --amend`
- `git checkout -- <file>`
- `git restore <file>` (without --staged)
- `git clean -fd`
- `git rebase -i`

**ALWAYS fix forward**: mistakes are corrected with NEW commits, never by rewriting history.

## Step 1: Review Changes
```bash
git status
git diff
git log -5 --oneline
```

Check for secrets (`.env`, `credentials.json`, API keys). Warn if found.

## Step 2: Draft Commit Message

**Format**: `<type>(TICKET-ID): <concise summary in present tense>`

Types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`

Extract ticket ID from branch name:
```bash
TICKET_ID=$(git rev-parse --abbrev-ref HEAD | grep -oE '[A-Z]+-[0-9]+')
```

## Step 3: Stage and Commit

Stage specific files (prefer explicit paths over `git add .`):
```bash
git add <specific files>
git commit -m "$(cat <<'EOF'
fix(TICKET-ID): description of why this change was made

Optional body explaining the reasoning.
EOF
)"
```

**NO AI references** in commit messages.

## Step 4: Handle Pre-commit Hooks (Fix Forward)

If hook modifies files → create NEW commit: `chore(TICKET-ID): apply pre-commit formatting`
If hook fails → fix issues, create NEW commit. NEVER amend.

## Step 5: Verify
```bash
git log -1 --stat
git status
```
Post commit details to Slack thread.

## Rules
- Review changes before committing
- No secrets in commits
- Meaningful messages (focus on WHY, not WHAT)
- Fix forward ALWAYS — never rollback
- No AI references
- No interactive git commands (-i flag)
