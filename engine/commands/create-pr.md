---
description: Create pull request following project PR template with Slack notifications and JIRA transition
---

# Create Pull Request Command

## Step 0: Load Config
Read `.claude/project.md` for: `SLACK_CHANNEL`, `SLACK_TOOL`, `BASE_BRANCH`, PR template path, JIRA link format.
Read `.slack-thread` for: thread timestamp (if file exists).

## Step 0.5: Probe Integrations

1. **`gh` CLI**: Run `gh auth status` to verify authentication.
   - Available → proceed with `gh pr create`
   - Unavailable → set `GH_AVAILABLE = false`, log: `WARN: gh CLI not available or not authenticated.`

2. **Atlassian MCP**: Attempt a lightweight call.
   - Available → proceed with JIRA transition
   - Unavailable → set `JIRA_AVAILABLE = false`, log: `WARN: Atlassian MCP not available — skipping JIRA transition.`

## Step 1: Understand Full Change Context

Run in parallel:
```bash
git status
git diff
git log {BASE_BRANCH}...HEAD --oneline
git diff {BASE_BRANCH}...HEAD
```

**CRITICAL**: Review ALL commits in the branch, not just the latest one.

## Step 2: Read PR Template
```bash
cat {PR_TEMPLATE_PATH}
```

If template file not found, use a minimal format: title, summary, test plan.

## Step 3: Push Branch
```bash
git push -u origin {BRANCH_NAME}
```

This step works with or without `gh` — it's standard git.

## Step 4: Create PR

Extract ticket ID and type from branch:
```bash
BRANCH=$(git rev-parse --abbrev-ref HEAD)
TICKET_ID=$(echo "$BRANCH" | grep -oE '[A-Z]+-[0-9]+')
TYPE=$(echo "$BRANCH" | grep -oE '^[a-z]+')
```

**If `GH_AVAILABLE`:**

Create with HEREDOC:
```bash
gh pr create \
  --title "${TYPE}(${TICKET_ID}): <concise summary>" \
  --body "$(cat <<'EOF'
<PR body following the project's template EXACTLY>
EOF
)" \
  --base {BASE_BRANCH}
```

**If `NOT GH_AVAILABLE`:**

Construct the PR URL manually and present it to the user:
```bash
REMOTE_URL=$(git remote get-url origin | sed 's/\.git$//' | sed 's|git@github.com:|https://github.com/|')
echo "Create PR manually: ${REMOTE_URL}/compare/${BASE_BRANCH}...${BRANCH_NAME}?expand=1"
```

Output the PR body (filled template) so the user can paste it.

**No AI references** in PR title or body.

## Step 5: Notify in Slack (if available)
If `.slack-thread` exists, post PR URL and details to existing thread. Otherwise, skip.

## Step 6: Transition JIRA Ticket to "Code Review" (if Atlassian available)

If `JIRA_AVAILABLE`:
1. `getTransitionsForJiraIssue(issue_key: "{TICKET_ID}")`
2. Find the transition whose name best represents "code review" (case-insensitive). Common names across Scrum/Kanban/custom workflows:
   - "Code Review", "In Review", "In Code Review"
   - "Peer Review", "Review", "Reviewing"
   - "Ready for Review", "Awaiting Review"
   - "PR Review", "Pull Request Review"
   Pick the first match. If multiple match, prefer the one containing "Code Review" or "Review".
3. If no match found, log all available transitions and skip — do NOT stop the workflow.
4. `transitionJiraIssue(issue_key: "{TICKET_ID}", transition_id: "{FOUND_ID}")`

If transition fails, log and continue.

## Step 7: Return PR URL
Display the PR URL (or manual creation URL) to the user.

## Step 8: Report Degraded State (if any integration was unavailable)
```
PR created with degraded integrations:
  gh CLI:    {used|manual URL provided}
  Atlassian: {transitioned|skipped}
  Slack:     {notified|skipped}
```

## Rules
- Analyze ALL commits (not just latest)
- Follow PR template EXACTLY (when available)
- Push branch before creating PR
- No AI references
- When `gh` is unavailable, ALWAYS push branch and provide manual PR URL
- When Atlassian is unavailable, skip JIRA transition silently
- Use JIRA link format from `project.md` (when Atlassian is available)
