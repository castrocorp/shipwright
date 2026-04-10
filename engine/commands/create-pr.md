---
description: Create pull request following project PR template with Slack notifications and JIRA transition
---

# Create Pull Request Command

## Step 0: Load Config
Read `.claude/project.md` for: `SLACK_CHANNEL`, `SLACK_TOOL`, `BASE_BRANCH`, PR template path, JIRA link format.
Read `.slack-thread` for: thread timestamp.

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

## Step 3: Push Branch
```bash
git push -u origin {BRANCH_NAME}
```

## Step 4: Create PR

Extract ticket ID and type from branch:
```bash
BRANCH=$(git rev-parse --abbrev-ref HEAD)
TICKET_ID=$(echo "$BRANCH" | grep -oE '[A-Z]+-[0-9]+')
TYPE=$(echo "$BRANCH" | grep -oE '^[a-z]+')
```

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

**No AI references** in PR title or body.

## Step 5: Notify in Slack
Post PR URL and details to existing thread.

## Step 6: Transition JIRA Ticket to "Code Review"

1. `getTransitionsForJiraIssue(issue_key: "{TICKET_ID}")`
2. Find transition containing "Code Review" or "Review"
3. `transitionJiraIssue(issue_key: "{TICKET_ID}", transition_id: "{FOUND_ID}")`

If transition fails, log and continue.

## Step 7: Return PR URL
Display the PR URL to the user.

## Rules
- Analyze ALL commits (not just latest)
- Follow PR template EXACTLY
- Push branch before creating PR
- No AI references
- Transition JIRA after PR creation
- Use JIRA link format from `project.md`
