---
name: project-config
description: Project-specific configuration for Claude Workflow Engine. Every workflow command reads this file.
---

# Project: {PROJECT_NAME}

## Infrastructure

- **Slack channel**: `{CHANNEL_ID}`
- **Slack tool**: `slack-bot`
- **JIRA cloud ID**: `{CLOUD_ID}`
- **JIRA site**: `{SITE}.atlassian.net`

## Repository

- **Base branch**: `dev`
- **Branch convention**:
  - Bug ticket → `fix/<TICKET-ID>`
  - Any other type → `feat/<TICKET-ID>`
- **Repo mapping** (for parallel-implement):

| Prefix | Path | Git URL |
|--------|------|---------|
| `{PREFIX}-*` | `/path/to/repo` | `git@github.com:org/repo.git` |

## Build

- **Build tool**: `{BUILD_CMD}` (e.g., `gw`, `npm`, `cargo`)
- **Test**: `{BUILD_CMD} {TEST_ARGS}` (e.g., `gw :<module>:test --tests "*<TestClass>*"`)
- **Lint check**: `{BUILD_CMD} {LINT_ARGS}` (e.g., `gw :<module>:ktlintCheck`)
- **Lint format**: `FORBIDDEN` | `{BUILD_CMD} {FORMAT_ARGS}`
- **Compile gate**: `{BUILD_CMD} {COMPILE_ARGS}`

## Code Standards

- **Stack**: `kotlin-spring` (references `~/.claude/stacks/{stack}.md`)
- **Language**: {LANGUAGE} {VERSION}
- **Framework**: {FRAMEWORK} {VERSION}

## PR Template

- **Path**: `.github/pull_request_template.md`
- **Title format**: `<type>(<TICKET-ID>): <description>`
- **JIRA link format**: `https://{SITE}.atlassian.net/browse/<TICKET-ID>`

## Agents

- **Code reviewer**: `{REVIEWER_AGENT}` (agent name in `.claude/agents/`)
- **Cross-repo oracles**: (list agent names, or "none")
