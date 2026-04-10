---
description: Clean up git worktrees from completed parallel-implement orchestrations
---

# Cleanup Worktrees Command

## Purpose
Remove worktrees and branches from parallel-implement runs whose PRs have been merged. Prevents accumulation of orphaned worktrees in `~/claude-parallel/`.

## Step 0: Probe `gh` CLI

Run `gh auth status` to verify authentication.

- **Available** → use `gh pr view` to check PR status automatically
- **Unavailable** → set `GH_AVAILABLE = false`, log: `WARN: gh CLI not available — cannot check PR status automatically. Will list worktrees for manual review.`

## Step 1: Scan Orchestration Directories

```bash
PARALLEL_DIR="$HOME/claude-parallel"
ls -d "$PARALLEL_DIR"/parallel-* 2>/dev/null
```

If no directories found, report "No orchestration directories to clean up" and exit.

## Step 2: Inventory Each Orchestration

For each orchestration directory, list the worktree subdirectories:

```bash
for ticket_dir in "$ORCH_DIR"/*/; do
  TICKET_ID=$(basename "$ticket_dir")
  BRANCH=$(git -C "$ticket_dir" rev-parse --abbrev-ref HEAD 2>/dev/null)
  echo "$TICKET_ID  $BRANCH"
done
```

## Step 3: Check PR Status

**If `GH_AVAILABLE`:**

For each ticket worktree, determine if its PR has been merged:

```bash
PR_STATE=$(gh pr view "$BRANCH" --json state --jq '.state' 2>/dev/null)
```

Classify each:
- `MERGED` → safe to remove
- `OPEN` → keep, report as pending
- `CLOSED` (not merged) → safe to remove
- No PR found → safe to remove (branch was never pushed or PR was deleted)

**If `NOT GH_AVAILABLE`:**

Cannot determine PR status. Present the list to the user and ask:

```
gh CLI is not available. I found these worktrees:

  1. XPTO-101  fix/XPTO-101
  2. XPTO-102  feat/XPTO-102
  3. XPTO-103  feat/XPTO-103

Which should I remove? (e.g., "1,2" or "all" or "none")
```

Only remove worktrees the user explicitly approves.

## Step 4: Remove Approved Worktrees

For each worktree classified (or approved) for removal:

```bash
# Find the parent repo that owns this worktree
REPO_PATH=$(git -C "$ticket_dir" rev-parse --path-format=absolute --git-common-dir 2>/dev/null | sed 's|/.git$||')

# Remove the worktree
git -C "$REPO_PATH" worktree remove "$ticket_dir" --force

# Prune stale worktree references
git -C "$REPO_PATH" worktree prune

# Delete the remote branch only if gh confirmed MERGED
if [ "$GH_AVAILABLE" = true ] && [ "$PR_STATE" = "MERGED" ]; then
  git -C "$REPO_PATH" push origin --delete "$BRANCH" 2>/dev/null || true
fi
```

## Step 5: Clean Up Empty Orchestration Directories

```bash
# Remove orchestration dir if all worktrees were cleaned
rmdir "$ORCH_DIR" 2>/dev/null

# Remove parent if empty
rmdir "$PARALLEL_DIR" 2>/dev/null
```

## Step 6: Report Results

Print a summary table:

**With `gh`:**
```
Worktree Cleanup Results
========================
Orchestration: parallel-20260410-143022

  ✅ XPTO-101  fix/XPTO-101   MERGED   → removed (branch deleted)
  ✅ XPTO-102  feat/XPTO-102  CLOSED   → removed
  ⏳ XPTO-103  feat/XPTO-103  OPEN     → kept (PR still open)

Removed: 2 worktrees
Kept: 1 worktree (PR still open)
```

**Without `gh`:**
```
Worktree Cleanup Results (manual mode — gh CLI unavailable)
===========================================================
Orchestration: parallel-20260410-143022

  ✅ XPTO-101  fix/XPTO-101   → removed (user approved)
  ✅ XPTO-102  feat/XPTO-102  → removed (user approved)
  ⏭️  XPTO-103  feat/XPTO-103  → kept (user chose to skip)

Removed: 2 worktrees
Kept: 1 worktree
Note: Remote branches NOT deleted (could not verify merge status)
```

## Step 7: Slack Notification (if available)

If `.slack-thread` exists in the current directory, post cleanup summary to the thread. Otherwise, skip silently.

## Rules
- With `gh`: NEVER remove worktrees with OPEN PRs
- Without `gh`: NEVER remove worktrees without user approval
- ALWAYS use `git worktree remove` (not `rm -rf` on the directory directly)
- ALWAYS run `git worktree prune` after removals
- Only delete remote branches when `gh` confirmed MERGED
- Report what was kept and why
- Safe to run repeatedly — idempotent
