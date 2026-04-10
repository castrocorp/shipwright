---
description: Deeply analyze bug through JIRA analysis and codebase investigation (static analysis only)
---

# Bug Analyze Command

**Mode**: READ-ONLY static analysis. This command never modifies code.

## Step 0: Load Config
Read `.claude/project.md` for: `SLACK_CHANNEL`, `SLACK_TOOL`.
Read `.slack-thread` for: thread timestamp (if file exists).

## Workflow

1. Post analysis start to Slack thread
2. Apply investigation methodologies from lessons learned
3. Analyze JIRA ticket with context focus
4. Check for reproduction steps → map to code paths statically
5. Analyze codebase for root cause
6. Identify context gaps
7. Check for red flags and anti-patterns
8. Generate structured report

## Investigation Patterns

### Pattern Recognition
- **"Works Elsewhere"** → Comparison Method (diff working vs failing flows)
- **"Permission Denied"** → Context Question Method (what context is expected vs available?)
- **"It Used To Work"** → Check what changed (data/config/dependencies)
- **"Only Some Users"** → Compare user contexts

### Red Flags
- Generic errors in specific contexts
- Different permission checks for similar operations
- Missing fields in request payloads
- Components reused in different contexts without adaptation

## Report Template

If `.slack-thread` exists, post to Slack thread. Always output to the conversation.
1. **Symptom**: What user sees, where, who
2. **Expected vs Actual**: Key divergence
3. **Context Analysis**: Present, missing, assumed context
4. **Root Cause**: What failed, why, violated assumption, code location
5. **Fix Strategy**: Recommended approach with file:line references
6. **Prevention**: How to avoid similar issues
7. **Confidence**: Honest percentage with supporting/uncertain factors

## Rules
- NEVER modify code during analysis
- Apply investigation methodologies from lessons learned
- Question context — never assume it's complete
- Compare working vs failing flows when possible
- Honest confidence assessment
- If `.slack-thread` is absent, skip Slack — do not fail
