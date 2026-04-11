---
description: Auto-detect project configuration and generate .claude/project.md by scanning the codebase, git config, and MCP servers
---

# Init Shipwright Command

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
- If detected stack is `kotlin-spring` → always mark as `FORBIDDEN` (convention: never auto-format Kotlin)
- If `format` script found in `package.json` → use that command
- Otherwise → leave as `{FORMAT_POLICY}` placeholder for manual input

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

## Step 6: Detect MCP Integrations (silent probe — never ask)

Probe each integration silently. Do NOT ask the user about MCPs. If unavailable, leave placeholders and report at the end.

Two sources are possible:
- **Claude.ai managed** (OAuth via browser): tools prefixed with `mcp__claude_ai_*`
- **Local `.mcp.json`**: tools prefixed with `mcp__<server-name>__*`

### JIRA / Atlassian

1. Try `getAccessibleAtlassianResources()` — works with either managed or local MCP
2. If available, call `getVisibleJiraProjects` to list projects and extract prefixes
3. Detect which tool name works: `atlassian` (local) or `claude_ai_atlassian` (managed)
4. If not available or errors, leave placeholders silently

### Slack

1. Try `slack_list_channels` with `slack-bot` tool name
2. If that fails, try with `slack` tool name
3. If that fails, try with `claude_ai_Slack` tool name (managed)
4. If available, extract channel list for the report
5. If not available, leave placeholders silently

### Notion

Try a lightweight Notion call (e.g., `search`).
- If available, note the tool name
- If not available, skip silently

## Step 7: Configure Agents

Check both levels for available agents:

```bash
# 1. Project-level agents (repo-specific)
ls .claude/agents/*.md 2>/dev/null

# 2. User-level agents (installed by Shipwright's install.sh)
ls ~/.claude/agents/*.md 2>/dev/null
```

**Resolution order**:
1. If a project-level code reviewer exists → use it (project overrides engine)
2. If engine agents exist at `~/.claude/agents/` → use `code-reviewer` (engine default)
3. If neither found → warn: `install.sh may not have run. Run it from the Shipwright repo to install engine agents.`

Never leave the reviewer as a placeholder — the engine always provides a default.

Report all available agents (from both levels) in the final summary.

## Step 8: Detect Language/Framework Versions

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

## Step 9: Ensure Stack Adapter Exists

```bash
STACK_FILE="$HOME/.claude/stacks/${DETECTED_STACK}.md"
```

If the stack adapter exists, use it.

If it does NOT exist, **generate a base adapter** from the template:
1. Read `~/.claude/stacks/_template.md` for the skeleton structure
2. Fill in the detected stack name, language, and framework
3. Add sensible defaults for the detected ecosystem:
   - Language style conventions (e.g., Java: prefer immutability, use Optional, etc.)
   - Framework conventions (e.g., Spring: constructor injection, @Service/@Repository, etc.)
   - Testing patterns (e.g., JUnit 5, Mockito, etc.)
   - Linting section (populate from Step 5 detection, or leave as TODO)
4. Write to `~/.claude/stacks/${DETECTED_STACK}.md`

This ensures `/tdd-ralph` and `/code-review` always have stack-specific rules to work with, even on first run.

## Step 9.5: Detect ralph-loop Plugin

Check if the ralph-loop plugin is **actually installed** (not just referenced in engine skills):

```bash
# Check for plugin files on disk — this is the ONLY reliable method
ls ~/.claude/plugins/*/ralph-loop/ 2>/dev/null
ls ~/.claude/plugins/cache/*/ralph-loop/ 2>/dev/null
```

**IMPORTANT**: Do NOT check the skills list in your system prompt to determine if ralph-loop is installed. The engine references ralph-loop skills (`ralph-loop:help`, `ralph-loop:ralph-loop`) regardless of whether the plugin is installed. The skill references are always visible — they do NOT prove the plugin exists.

**Only report as installed if plugin files exist on disk.**

If not found → **install it automatically**:
1. Run: `Skill("ralph-loop:help")` — if it errors with "plugin not found" or similar, the plugin is truly missing
2. Install it: suggest the user run `/plugin install ralph-loop` (plugins require interactive installation through Claude Code's plugin UI — they cannot be installed programmatically from a command prompt)
3. After user confirms installation, run `/reload-plugins` to activate

ralph-loop is the iterative TDD engine that powers `/tdd-ralph`. Without it, TDD falls back to manual Red-Green-Refactor (functional but significantly less powerful — no automatic retry loops, no iteration tracking, no completion detection).

**Note**: This is the ONE step in init-project where user interaction is required — plugin installation goes through Claude Code's plugin UI.

## Step 10: MCP Configuration (no prompts)

Do NOT ask the user about MCP setup. Just detect and report.

- If managed MCPs were detected in Step 6, report them as active (no `.mcp.json` needed)
- If local `.mcp.json` already exists, report it as configured
- If no MCPs detected and no `.mcp.json`, leave placeholders and note in the final report that MCPs can be connected later via `/mcp` in Claude Code

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
description: Project-specific configuration for Shipwright. Auto-generated by /init-shipwright.
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

- **Code reviewer**: `{DETECTED_REVIEWER or code-reviewer}`
```

## Step 12: Report Results

Print a summary of what was detected and what needs manual input:

```
Init Project — Results
======================
Detected:
  ✅ Stack: kotlin-spring
  ✅ Build tool: ./gradlew
  ✅ Base branch: dev
  ✅ Test command: ./gradlew :<module>:test
  ✅ PR template: .github/pull_request_template.md
  ✅ JIRA cloud ID: <your-cloud-id>
  ✅ Slack channel: <your-channel-id>
  ✅ MCP servers: .mcp.json (Slack, Atlassian, Notion)

Plugins:
  ✅ ralph-loop: installed          # or:
  ⚠️  ralph-loop: NOT INSTALLED
     └ /tdd-ralph will fall back to manual TDD (no iterative loop).
       Install ralph-loop for automatic Red-Green-Refactor cycles
       with retry, iteration tracking, and completion detection.
       Run: /plugin install ralph-loop

Needs manual input:
  ⚠️  Lint format policy (FORBIDDEN or command)
  ⚠️  Additional repo mappings for parallel-implement

Generated: .claude/project.md
Review and adjust values marked with {PLACEHOLDER}.
```

## Rules

- NEVER overwrite an existing `project.md` without asking
- NEVER guess values — use `{PLACEHOLDER}` for anything not detectable
- NEVER ask about MCP setup — probe silently, report at the end
- Detect from files first, MCP calls second
- Report what was detected vs what needs manual input
- If no stack adapter exists, generate a base one from the template
- Always default the code reviewer to `code-reviewer` (engine default)
