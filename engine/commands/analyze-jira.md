---
description: Analyze JIRA ticket thoroughly using Atlassian MCP with Slack notifications
---

# Analyze JIRA Ticket Command

## Step 0: Load Config
Read `.claude/project.md` for: `SLACK_CHANNEL`, `SLACK_TOOL`, `JIRA_CLOUD_ID`.
Read `.slack-thread` for: thread timestamp (if file exists).

## Step 0.5: Probe Atlassian MCP

Attempt `getAccessibleAtlassianResources()` or a lightweight call.

- **Available** → proceed with full JIRA analysis (Step 1–5)
- **Unavailable** → jump to [Fallback: Manual Context](#fallback-manual-context)

## Step 1: Notify Start
If `.slack-thread` exists, reply to EXISTING Slack thread. Otherwise, skip.

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
If the ticket involves frontend/backend integration, call relevant oracle agents listed in `project.md`. Pass the Slack thread timestamp so agents post to the SAME thread (if available).

## Step 5: Document Findings
If `.slack-thread` exists, post comprehensive analysis to Slack thread.
Always output findings to the conversation: ticket summary, acceptance criteria, support materials reviewed, technical impact, and next steps.

---

## Fallback: Manual Context

When Atlassian MCP is unavailable:

1. Log: `WARN: Atlassian MCP not available — cannot fetch JIRA ticket automatically.`
2. Check the conversation for context the user already provided (description, AC, requirements).
3. If the user provided enough context, summarize it and proceed.
4. If context is insufficient, ask the user:
   ```
   Atlassian is unavailable. To proceed, I need:
   1. What is the task? (brief summary)
   2. What are the acceptance criteria? (bulleted list)
   3. Is this a bug fix or a new feature?
   4. Any edge cases or constraints to consider?
   ```
5. Once context is gathered, continue the pipeline with user-provided AC instead of JIRA-sourced AC.

---

## Rules
- If `.slack-thread` exists, use EXISTING Slack thread (SAME timestamp from `/start-task`)
- If `.slack-thread` is absent, skip Slack — do not fail
- Review ALL support materials (when Atlassian is available)
- Extract clear acceptance criteria (from JIRA or from user)
- NEVER create new thread for analysis
- NEVER stop the pipeline because Atlassian is down — use fallback

## Next Steps
1. Create branch → `/create-branch`
2. Check lessons → `/check-lessons`
3. Start TDD → `/tdd-ralph`
