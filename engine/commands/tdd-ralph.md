---
description: Unified TDD + ralph-loop — auto-generates prompt with full quality checklists and invokes ralph-loop
---

# TDD Ralph Command

## Purpose
Combine strict TDD methodology with ralph-loop iterative execution. Automatically generates a comprehensive prompt from context gathered in prior steps.

## Step 0: Load Config
Read `.claude/project.md` for: build/test/lint commands, stack name, `SLACK_CHANNEL`, `SLACK_TOOL`.
Read `~/.claude/stacks/{STACK}.md` for: language-specific code quality rules.
Read `.slack-thread` for: thread timestamp.

## Step 1: Gather Context

From the current conversation, extract:

| Variable | Source | Example |
|----------|--------|---------|
| `TICKET_ID` | Branch name or JIRA analysis | `ART-7601` |
| `SUMMARY` | JIRA summary or user description | Short task description |
| `ACCEPTANCE_CRITERIA` | JIRA ticket or user requirements | Bulleted list |
| `MODULE` | Affected build module | `artengine` |
| `TEST_CLASS` | Primary test class name | `DmsFolderServiceTest` |
| `LESSONS` | Findings from `/check-lessons` | Relevant patterns |
| `BUG_CONTEXT` | From `/bug-analyze` (bugs only) | Root cause analysis |
| `BUILD_TEST_CMD` | From `project.md` | `gw :artengine:test --tests` |
| `BUILD_LINT_CMD` | From `project.md` | `gw :artengine:ktlintCheck` |
| `BUILD_COMPILE_CMD` | From `project.md` | `gw :artengine:compileKotlin` |
| `STACK_RULES` | From `stacks/{STACK}.md` | Code quality checklist |

If a value is ambiguous, infer from the codebase — do NOT stop to ask.

## Step 2: Post Slack Update
Notify the existing thread that the TDD loop is starting.

## Step 3: Compose Prompt and Invoke Ralph Loop

Use the Skill tool to invoke `ralph-loop:ralph-loop`. Fill ALL placeholders from Step 1.

**Skill invocation:**
```
skill: "ralph-loop:ralph-loop"
args: "<COMPOSED_PROMPT> --completion-promise DONE --max-iterations 30"
```

**PROMPT TEMPLATE:**

```
Implement {TICKET_ID}: {SUMMARY}

Acceptance criteria:
{ACCEPTANCE_CRITERIA}

Lessons learned to apply:
{LESSONS}

{BUG_CONTEXT — include only for bug tickets}

--- TDD CYCLE ---

RED (write failing unit tests):
- UNIT tests only (never integration for TDD)
- Mock all external dependencies
- Cover: happy path, edge cases, validation errors
- Run: {BUILD_TEST_CMD} "*{TEST_CLASS}*"
- Verify tests FAIL before proceeding

GREEN (make tests pass):
- Implement MINIMUM code to pass all tests
- Follow code quality rules from stack adapter:
{STACK_RULES}
- Run: {BUILD_TEST_CMD} "*{TEST_CLASS}*"
- If tests fail, fix and re-run

REFACTOR (clean while green):
- Eliminate duplication (DRY)
- Improve naming
- Run tests after each change

VERIFY (compilation + lint):
- Run: {BUILD_COMPILE_CMD}
- Run: {BUILD_LINT_CMD}
- Fix lint violations manually (never auto-format if forbidden by project config)

--- COMPLETENESS CHECK ---
- [ ] All acceptance criteria implemented
- [ ] Unit tests cover all acceptance criteria
- [ ] All tests pass
- [ ] Compilation clean
- [ ] Lint passes on changed files

--- SLACK UPDATES ---
Post phase transitions to existing Slack thread:
- Read thread info from .slack-thread or .slack-thread-* file
- If missing, continue without Slack

--- COMPLETION ---
Output <promise>DONE</promise> ONLY when ALL checkboxes are true.
```

## Step 4: After Ralph Loop Exits

Post result to Slack thread (success or max-iterations reached).
If max iterations reached without completion, STOP and report to user.

## Rules
- Fill ALL placeholders before invoking ralph-loop
- Include lessons learned in the prompt
- Use build commands from `project.md` (never hardcode)
- Use code quality rules from `stacks/{STACK}.md`
- Let ralph-loop handle retries

## Next Steps
After successful completion → `/code-review`
