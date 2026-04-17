---
description: Unified TDD + ralph-loop — auto-generates prompt with full quality checklists and invokes ralph-loop
---

# TDD Ralph Command

## Purpose
Combine strict TDD methodology with ralph-loop iterative execution. Automatically generates a comprehensive prompt from context gathered in prior steps.

## Step 0: Load Config
Read `.claude/project.md` for: build/test/lint commands, stack name, `SLACK_CHANNEL`, `SLACK_TOOL`.
Read `~/.claude/stacks/{STACK}.md` for: language-specific code quality rules.
Read `.slack-thread` for: thread timestamp (if file exists).

## Step 0.5: Probe Dependencies

1. **ralph-loop plugin**: Attempt to resolve the `ralph-loop:ralph-loop` skill.
   - Available → use ralph-loop for iterative TDD (Step 3)
   - Unavailable → log warning and fall back to manual TDD (Step 3b):
     ```
     WARNING: ralph-loop plugin is not installed. Falling back to manual TDD implementation.
     For iterative TDD with automatic retries, install from: https://github.com/anthropics/claude-code-plugins
     ```

2. **Slack MCP**: Check if `.slack-thread` exists.
   - Present → post phase updates to Slack thread
   - Absent → skip Slack, continue silently

## Step 1: Gather Context

From the current conversation, extract:

| Variable | Source | Example |
|----------|--------|---------|
| `TICKET_ID` | Branch name or JIRA analysis | `XPTO-7601` |
| `SUMMARY` | JIRA summary or user description | Short task description |
| `ACCEPTANCE_CRITERIA` | JIRA ticket or user requirements | Bulleted list |
| `MODULE` | Affected build module | `my-module` |
| `TEST_CLASS` | Primary test class name | `MyServiceTest` |
| `LESSONS` | Findings from `/check-lessons` | Relevant patterns |
| `BUG_CONTEXT` | From `/bug-analyze` (bugs only) | Root cause analysis |
| `BUILD_TEST_CMD` | From `project.md` | `{BUILD_CMD} :{MODULE}:test --tests` |
| `BUILD_LINT_CMD` | From `project.md` | `{BUILD_CMD} :{MODULE}:lintCheck` |
| `BUILD_COMPILE_CMD` | From `project.md` | `{BUILD_CMD} :{MODULE}:compile` |
| `STACK_RULES` | From `stacks/{STACK}.md` | Code quality checklist |

If a value is ambiguous, infer from the codebase — do NOT stop to ask.

## Step 2: Post Slack Update (if available)
If `.slack-thread` exists, notify the existing thread that TDD is starting. Otherwise, skip.

## Step 3: Invoke Ralph Loop (if available)

Use the Skill tool to invoke `ralph-loop:ralph-loop`. Fill ALL placeholders from Step 1.

**Skill invocation:**
```
skill: "ralph-loop:ralph-loop"
args: "<COMPOSED_PROMPT> --completion-promise READY_FOR_REVIEW --max-iterations 30"
```

## Step 3b: Manual TDD (fallback when ralph-loop unavailable)

If ralph-loop is not installed, execute the TDD cycle manually using the same prompt template from Step 3:

1. **RED** — Write failing unit tests based on acceptance criteria
2. **GREEN** — Implement minimum code to pass all tests
3. **REFACTOR** — Clean up while keeping tests green
4. **VERIFY** — Run compile gate and lint check

Run build/test/lint commands from `project.md` after each phase. Repeat until all acceptance criteria are met and the completeness checklist passes.

## Prompt Template

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
- Read thread info from .slack-thread file
- If missing, continue without Slack

--- COMPLETION ---
Output <promise>READY_FOR_REVIEW</promise> ONLY when ALL checkboxes are true.
```

## Step 4: After Ralph Loop Exits

Post result to Slack thread (if available): success or max-iterations reached.
If max iterations reached without completion, STOP and report to user.

## Rules
- ralph-loop is preferred but not required — fall back to manual TDD if unavailable
- Fill ALL placeholders before invoking ralph-loop
- Include lessons learned in the prompt
- Use build commands from `project.md` (never hardcode)
- Use code quality rules from `stacks/{STACK}.md`
- Let ralph-loop handle retries

## Next Steps
After successful completion → `/code-review`
