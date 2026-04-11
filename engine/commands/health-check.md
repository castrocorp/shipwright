---
description: Verify Shipwright installation, integrations, and project configuration
---

# Health Check Command

## Purpose
Test all integrations and validate project configuration after install or when debugging issues.

## Step 1: Check Shipwright Installation

Read `~/.claude/.shipwright-version`:
- If present → extract `version=` and `repo=`
- If missing → WARN: "Shipwright version marker missing. Run install.sh."

Verify symlinks exist:
```bash
for item in CLAUDE.md agents commands prompts rules skills stacks; do
    [ -e "$HOME/.claude/$item" ] && echo "OK: $item" || echo "MISSING: $item"
done
```

## Step 2: Check Version

Read `{REPO_PATH}/VERSION` and compare with `~/.claude/.shipwright-version`:
- Match → OK
- Mismatch → WARN: "Installed version differs from repo. Run install.sh."

Check for updates:
```bash
bash {REPO_PATH}/check-update.sh
cat ~/.claude/.shipwright-update 2>/dev/null
```

## Step 3: Check Project Configuration

Read `.claude/project.md`:
- If missing → ERROR: "No project config. Run /init-project."
- If present → scan for `{PLACEHOLDER}` patterns (any value still in braces)

Report:
- Complete fields (count)
- Incomplete placeholders (list each one)

## Step 4: Check Stack Adapter

Extract `STACK` from `.claude/project.md`.
Check if `~/.claude/stacks/{STACK}.md` exists:
- Present → OK
- Missing → WARN: "No stack adapter for '{STACK}'. Code quality rules won't be injected."

## Step 5: Probe Integrations

Test each integration with a lightweight call:

### Slack MCP
- Read `SLACK_TOOL` and `SLACK_CHANNEL` from `.claude/project.md`
- Try: `{SLACK_TOOL}:slack_list_channels(limit: 1)`
- Available → OK (report tool name)
- Unavailable → WARN: "Slack MCP not available"

### Atlassian MCP
- Try: `getAccessibleAtlassianResources()`
- Available → OK (report cloud ID)
- Unavailable → WARN: "Atlassian MCP not available"

### GitHub CLI
```bash
gh auth status 2>&1
```
- Authenticated → OK (report user)
- Not authenticated → WARN: "`gh` CLI not authenticated"

### ralph-loop Plugin
- Check if the plugin is installed and responsive
- Available → OK
- Unavailable → WARN: "ralph-loop not available — /tdd-ralph will use manual fallback"

## Step 6: Check PR Template

Extract PR template path from `.claude/project.md`.
```bash
[ -f "{PR_TEMPLATE_PATH}" ] && echo "OK" || echo "MISSING"
```

## Step 7: Check Lessons Learned

```bash
ls ~/.claude/projects/*/memory/lessons-learned.md 2>/dev/null | wc -l
```
- Found → OK (report count)
- None → INFO: "No lessons-learned files. Use /record-lesson after incidents."

## Step 8: Report Summary

Print a dashboard:

```
Shipwright Health Check
========================

Installation:
  Version:      1.1.0                    OK
  Symlinks:     7/7                      OK

Project Config:
  project.md:   .claude/project.md       OK
  Placeholders: 0 remaining              OK
  Stack:        kotlin-spring            OK
  PR Template:  .github/pr_template.md   OK

Integrations:
  Slack:        slack-bot                OK
  Atlassian:    cloud-id-xxx             OK
  GitHub CLI:   PeCastro16               OK
  ralph-loop:   installed                OK

Knowledge:
  Lessons:      3 files                  OK

Overall: ALL CHECKS PASSED
```

Use these status indicators:
- `OK` — working correctly
- `WARN` — degraded but workflow will function
- `ERROR` — must be fixed before using Shipwright
- `INFO` — informational, no action required

## Rules
- NEVER stop on WARN — report everything, then summarize
- ERROR items should be listed at the end with fix instructions
- This command is read-only — it does NOT modify any files
