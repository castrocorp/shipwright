---
name: project-config
description: Project-specific configuration for Shipwright. Every workflow command reads this file.
---

# Project: {PROJECT_NAME}

<!-- Values in {BRACES} are placeholders — replace them with your project's values.
     Values without braces are sensible defaults — review and change if needed. -->

## Infrastructure

- **Slack channel**: `{CHANNEL_ID}`
- **Slack tool**: `slack-bot` <!-- default; change if your Slack MCP server has a different name -->
- **JIRA cloud ID**: `{CLOUD_ID}`
- **JIRA site**: `{SITE}.atlassian.net`

## Repository

- **Base branch**: `{BASE_BRANCH}` <!-- e.g., dev, main, develop -->
- **Branch convention**:
  - Bug ticket → `fix/<TICKET-ID>`
  - Any other type → `feat/<TICKET-ID>`
- **Repo mapping** (for parallel-implement):

| Prefix | Path | Git URL |
|--------|------|---------|
| `{PREFIX}-*` | `/path/to/repo` | `git@github.com:org/repo.git` |

## Build

- **Build tool**: `{BUILD_CMD}` <!-- e.g., gw, npm, cargo -->
- **Test**: `{BUILD_CMD} {TEST_ARGS}` <!-- e.g., gw :<module>:test --tests "*<TestClass>*" -->
- **Lint check**: `{BUILD_CMD} {LINT_ARGS}` <!-- e.g., gw :<module>:ktlintCheck -->
- **Lint format**: `FORBIDDEN` | `{BUILD_CMD} {FORMAT_ARGS}` <!-- set FORBIDDEN to block auto-format, or provide the command -->
- **Compile gate**: `{BUILD_CMD} {COMPILE_ARGS}`

## Code Standards

- **Stack**: `{STACK}` <!-- must match a file in ~/.claude/stacks/<stack>.md, e.g., kotlin-spring -->
- **Language**: `{LANGUAGE} {VERSION}`
- **Framework**: `{FRAMEWORK} {VERSION}`

## PR Template

- **Path**: `.github/pull_request_template.md`
- **Title format**: `<type>(<TICKET-ID>): <description>`
- **JIRA link format**: `https://{SITE}.atlassian.net/browse/<TICKET-ID>`

## Jira Defaults

- **Team**: `{TEAM_NAME}` — custom field ID: `customfield_10001`, value: `{TEAM_ID}`
- **Component / Session**: `{COMPONENT}` — custom field ID: `customfield_10048`
- **Sprint resolution JQL**: `"Team[Team]" = "{TEAM_ID}" AND sprint in openSprints() ORDER BY created DESC`
- **Assignee account ID**: `{ACCOUNT_ID}`
- **Reporter account ID**: `{ACCOUNT_ID}` <!-- default same as assignee -->
- **Default priority**: `Low`

## Agents

- **Code reviewer**: `code-reviewer` <!-- default generic reviewer from Shipwright -->
- **Cross-repo oracles**: (list agent names, or "none")
