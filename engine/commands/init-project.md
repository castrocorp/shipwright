---
description: Auto-detect project configuration and generate .claude/project.md by scanning the codebase, git config, and MCP servers
---

# Init Project Command

## Purpose
Scan the current project to auto-detect configuration values and generate `.claude/project.md`. Eliminates manual setup.

## Step 1: Check for Existing Config

```bash
if [ -f .claude/project.md ]; then
  echo "project.md already exists"
fi
```

If it exists, ask the user: update existing or skip.

## Step 2: Detect Repository Info

```bash
# Base branch (check for dev, then main, then master)
git rev-parse --verify origin/dev 2>/dev/null && BASE_BRANCH="dev"
git rev-parse --verify origin/main 2>/dev/null && BASE_BRANCH="${BASE_BRANCH:-main}"
git rev-parse --verify origin/master 2>/dev/null && BASE_BRANCH="${BASE_BRANCH:-master}"

# Remote URL
GIT_REMOTE=$(git remote get-url origin 2>/dev/null)

# Org and repo name
REPO_NAME=$(basename -s .git "$GIT_REMOTE" 2>/dev/null)
```

## Step 3: Detect Stack and Build Tool

Check for build files in priority order:

| File | Stack | Build Tool |
|------|-------|------------|
| `build.gradle.kts` or `build.gradle` | `kotlin-spring` or `java` | `./gradlew` |
| `package.json` | `typescript` or `javascript` | `npm` or `yarn` or `pnpm` |
| `Cargo.toml` | `rust` | `cargo` |
| `pyproject.toml` or `setup.py` | `python` | `pip` or `poetry` or `uv` |
| `go.mod` | `go` | `go` |
| `pom.xml` | `java` | `mvn` |
| `Gemfile` | `ruby` | `bundle` |
| `mix.exs` | `elixir` | `mix` |
| `Package.swift` | `swift` | `swift` |

**Refine stack detection:**
- `build.gradle.kts` + grep `kotlin` in file → `kotlin-spring`
- `package.json` + grep `typescript` in devDependencies → `typescript`
- `package.json` + grep `react` or `next` → `typescript-react`
- `package.json` + grep `angular` → `typescript-angular`
- `pyproject.toml` + grep `django` → `python-django`
- `pyproject.toml` + grep `fastapi` → `python-fastapi`

**Detect package manager (JS/TS):**
- `pnpm-lock.yaml` exists → `pnpm`
- `yarn.lock` exists → `yarn`
- `bun.lockb` exists → `bun`
- `package-lock.json` exists → `npm`

**Detect build wrapper:**
- `scripts/gw` exists → build tool is `gw` (not `./gradlew`)
- `gradlew` exists → build tool is `./gradlew`
- `mvnw` exists → build tool is `./mvnw`

## Step 4: Detect Test and Lint Commands

**From build files:**
```bash
# Gradle — check for test tasks and ktlint
grep -l "ktlint" build.gradle.kts */build.gradle.kts 2>/dev/null && LINT_CMD="{BUILD_TOOL} :ktlintCheck"
grep -l "detekt" build.gradle.kts */build.gradle.kts 2>/dev/null && LINT_CMD="{BUILD_TOOL} detekt"

# package.json — read scripts
grep '"test"' package.json 2>/dev/null && TEST_CMD="npm test"
grep '"lint"' package.json 2>/dev/null && LINT_CMD="npm run lint"
grep '"format"' package.json 2>/dev/null && FORMAT_CMD="npm run format"

# Python
[ -f "pyproject.toml" ] && grep "pytest" pyproject.toml && TEST_CMD="pytest"
[ -f "pyproject.toml" ] && grep "ruff" pyproject.toml && LINT_CMD="ruff check"

# Rust
[ -f "Cargo.toml" ] && TEST_CMD="cargo test" && LINT_CMD="cargo clippy"

# Go
[ -f "go.mod" ] && TEST_CMD="go test ./..." && LINT_CMD="golangci-lint run"
```

**Detect lint format policy:**
- If `ktlintFormat` found in gradle config → mark as FORBIDDEN (Kotlin convention)
- Otherwise → detect from available scripts

**Detect modules (monorepo):**
```bash
# Gradle modules
grep "include(" settings.gradle.kts 2>/dev/null | sed "s/include(\"//;s/\")//"

# npm workspaces
grep -A 10 '"workspaces"' package.json 2>/dev/null
```

## Step 5: Detect PR Template

```bash
# Check common locations
for path in .github/pull_request_template.md .github/PULL_REQUEST_TEMPLATE.md docs/pull_request_template.md; do
  [ -f "$path" ] && PR_TEMPLATE="$path" && break
done
```

## Step 6: Detect JIRA Integration

If Atlassian MCP is available:
1. Call `getVisibleJiraProjects` to list available projects
2. Extract project prefixes (e.g., ART, FIRM, PP)
3. Call `getAccessibleAtlassianResources` to get cloud ID and site name

If not available, leave placeholders.

## Step 7: Detect Slack Integration

If Slack MCP is available:
1. Call `slack_list_channels` to list available channels
2. Determine which MCP tool name works (`slack-bot` vs `slack`)
3. Ask user which channel to use for task tracking

If not available, leave placeholders.

## Step 8: Detect Existing Agents

```bash
# Check for project-level agents
ls .claude/agents/*.md 2>/dev/null
```

If a code reviewer agent exists, extract its name.

## Step 9: Detect Language/Framework Versions

```bash
# Kotlin
grep "kotlin.*version" build.gradle.kts 2>/dev/null | head -1

# Java
grep "java.*version\|jvmTarget\|sourceCompatibility" build.gradle.kts 2>/dev/null | head -1

# Node
node --version 2>/dev/null

# Python
python3 --version 2>/dev/null

# Rust
rustc --version 2>/dev/null

# Go
go version 2>/dev/null

# Spring Boot
grep "spring-boot.*version\|org.springframework.boot" build.gradle.kts 2>/dev/null | head -1
```

## Step 10: Check for Existing Stack Adapter

```bash
STACK_FILE="$HOME/.claude/stacks/${DETECTED_STACK}.md"
if [ -f "$STACK_FILE" ]; then
  echo "Stack adapter found: $STACK_FILE"
else
  echo "No stack adapter for: $DETECTED_STACK"
  echo "You may want to create: ~/.claude/stacks/${DETECTED_STACK}.md"
fi
```

## Step 11: Generate project.md

Create `.claude/project.md` with all detected values:

```bash
mkdir -p .claude
```

Write the file using all detected values. For any value that could NOT be detected, use a `{PLACEHOLDER}` with a comment explaining what's needed.

**Template with detected values:**

```markdown
---
name: project-config
description: Project-specific configuration for Claude Workflow Engine. Auto-generated by /init-project.
---

# Project: {REPO_NAME}

## Infrastructure

- **Slack channel**: `{DETECTED_CHANNEL or {CHANNEL_ID}}`
- **Slack tool**: `{DETECTED_TOOL or slack-bot}`
- **JIRA cloud ID**: `{DETECTED_CLOUD_ID or {CLOUD_ID}}`
- **JIRA site**: `{DETECTED_SITE or {SITE}}.atlassian.net`

## Repository

- **Base branch**: `{BASE_BRANCH}`
- **Branch convention**:
  - Bug ticket → `fix/<TICKET-ID>`
  - Any other type → `feat/<TICKET-ID>`
- **Repo mapping**:

| Prefix | Path | Git URL |
|--------|------|---------|
| `{JIRA_PREFIX}-*` | `{PROJECT_PATH}` | `{GIT_REMOTE}` |

## Build

- **Build tool**: `{BUILD_TOOL}`
- **Test**: `{TEST_CMD}`
- **Lint check**: `{LINT_CMD}`
- **Lint format**: `{FORMAT_POLICY}`
- **Compile gate**: `{COMPILE_CMD}`

## Code Standards

- **Stack**: `{DETECTED_STACK}`
- **Language**: {LANGUAGE} {VERSION}
- **Framework**: {FRAMEWORK} {VERSION}

## PR Template

- **Path**: `{PR_TEMPLATE}`
- **Title format**: `<type>(<TICKET-ID>): <description>`
- **JIRA link format**: `https://{SITE}.atlassian.net/browse/<TICKET-ID>`

## Agents

- **Code reviewer**: `{DETECTED_REVIEWER or {REVIEWER_AGENT}}`
```

## Step 12: Report Results

Print a summary of what was detected and what needs manual input:

```
Init Project — Results
======================
Detected:
  ✅ Stack: kotlin-spring
  ✅ Build tool: gw
  ✅ Base branch: dev
  ✅ Test command: gw :artengine:test
  ✅ PR template: .github/pull_request_template.md
  ✅ JIRA cloud ID: 91eefacc-...
  ✅ Slack channel: U077ADYKWKV

Needs manual input:
  ⚠️  Lint format policy (FORBIDDEN or command)
  ⚠️  Additional repo mappings for parallel-implement

Generated: .claude/project.md
Review and adjust values marked with {PLACEHOLDER}.
```

## Rules

- NEVER overwrite an existing `project.md` without asking
- NEVER guess values — use `{PLACEHOLDER}` for anything not detectable
- Detect from files first, MCP calls second
- Report what was detected vs what needs manual input
- If no stack adapter exists, suggest creating one
