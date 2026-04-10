---
description: Analyze JIRA ticket thoroughly using Atlassian MCP with Slack notifications
---

# Analyze JIRA Ticket Command

## Step 0: Load Config
Read `.claude/project.md` for: `SLACK_CHANNEL`, `SLACK_TOOL`, `JIRA_CLOUD_ID`.
Read `.slack-thread` for: thread timestamp.

## Prerequisites
- Slack thread exists (from `/start-task`)
- JIRA ticket ID provided

## Step 1: Notify Start
Reply to EXISTING Slack thread — NEVER create a new one.

## Step 2: Retrieve JIRA Ticket
Use Atlassian MCP to fetch: summary, description, status, priority, acceptance criteria, linked tickets.

## Step 3: Review ALL Support Materials

**MANDATORY** — examine every resource attached to the ticket:
- [ ] Loom videos (summarize findings)
- [ ] Notion documents (read thoroughly)
- [ ] Screenshots/images (analyze visual context)
- [ ] Comments and discussions (review all threads)
- [ ] Attachments (examine all files)
- [ ] Related/linked tickets (understand dependencies)

**CRITICAL**: For EVERY ticket in `issuelinks[]`, fetch it and read its description. Understanding the ecosystem of related tickets IS the analysis.

## Step 4: Context from Cross-Repo Agents (if applicable)
If the ticket involves frontend/backend integration, call relevant oracle agents listed in `project.md`. Pass the Slack thread timestamp so agents post to the SAME thread.

## Step 5: Document Findings in Slack Thread
Post comprehensive analysis including: ticket summary, acceptance criteria, support materials reviewed, technical impact, and next steps.

## Rules
- Use EXISTING Slack thread (SAME timestamp from `/start-task`)
- Review ALL support materials
- Extract clear acceptance criteria
- NEVER create new thread for analysis

## Next Steps
1. Create branch → `/create-branch`
2. Check lessons → `/check-lessons`
3. Start TDD → `/tdd-ralph`
