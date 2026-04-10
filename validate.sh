#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENGINE_DIR="$SCRIPT_DIR/engine"
TEMPLATE="$SCRIPT_DIR/template/project.md"
INSTALLER="$SCRIPT_DIR/install.sh"

ERRORS=0
WARNINGS=0

error() { echo "  ERROR: $1"; ((ERRORS++)); }
warn()  { echo "  WARN:  $1"; ((WARNINGS++)); }
ok()    { echo "  OK:    $1"; }

echo "Shipwright — Validator"
echo "======================"
echo ""

# ---------- 1. Commands: frontmatter ----------
echo "[1/9] Checking command frontmatter..."

for f in "$ENGINE_DIR"/commands/*.md; do
    name=$(basename "$f")
    if ! head -1 "$f" | grep -q "^---$"; then
        error "$name — missing frontmatter (no opening ---)"
        continue
    fi
    if ! grep -q "^description:" "$f"; then
        error "$name — missing 'description' in frontmatter"
    else
        ok "$name"
    fi
done
echo ""

# ---------- 2. Agents: frontmatter ----------
echo "[2/9] Checking agent frontmatter..."

for f in "$ENGINE_DIR"/agents/*.md; do
    name=$(basename "$f")
    if ! head -1 "$f" | grep -q "^---$"; then
        error "$name — missing frontmatter (no opening ---)"
        continue
    fi
    missing=""
    grep -q "^name:" "$f"  || missing="$missing name"
    grep -q "^model:" "$f" || missing="$missing model"
    if [ -n "$missing" ]; then
        error "$name — missing frontmatter fields:$missing"
    else
        ok "$name"
    fi
done
echo ""

# ---------- 3. Skills: frontmatter ----------
echo "[3/9] Checking skill frontmatter..."

for f in "$ENGINE_DIR"/skills/*/SKILL.md; do
    name=$(echo "$f" | sed "s|$ENGINE_DIR/skills/||" | sed 's|/SKILL.md||')
    if ! head -1 "$f" | grep -q "^---$"; then
        error "skill/$name — missing frontmatter (no opening ---)"
        continue
    fi
    if ! grep -q "^name:" "$f"; then
        error "skill/$name — missing 'name' in frontmatter"
    else
        ok "skill/$name"
    fi
done
echo ""

# ---------- 4. Template placeholders vs command references ----------
echo "[4/9] Checking placeholder coverage..."

# Extract placeholders that commands expect from project.md
# These are the config keys commands read via "Read .claude/project.md for: X, Y, Z"
EXPECTED_KEYS=("SLACK_CHANNEL" "SLACK_TOOL" "JIRA_CLOUD_ID" "BASE_BRANCH" "STACK")

for key in "${EXPECTED_KEYS[@]}"; do
    if grep -qi "$key\|$(echo "$key" | tr '_' ' ')" "$TEMPLATE" 2>/dev/null; then
        ok "template has $key"
    else
        warn "template may be missing $key (commands reference it)"
    fi
done
echo ""

# ---------- 5. Prompts: existence check ----------
echo "[5/9] Checking prompt templates..."

if [ -d "$ENGINE_DIR/prompts" ]; then
    for f in "$ENGINE_DIR"/prompts/*.md; do
        [ -f "$f" ] || continue
        name=$(basename "$f")
        ok "$name"
    done
    # Verify worker-agent.md exists (required by parallel-implement)
    if [ ! -f "$ENGINE_DIR/prompts/worker-agent.md" ]; then
        error "prompts/worker-agent.md — missing (required by parallel-implement)"
    fi
else
    error "prompts/ directory missing"
fi
echo ""

# ---------- 6. Stacks: frontmatter ----------
echo "[6/9] Checking stack adapter frontmatter..."

if [ -d "$ENGINE_DIR/stacks" ]; then
    for f in "$ENGINE_DIR"/stacks/*.md; do
        [ -f "$f" ] || continue
        name=$(basename "$f")
        if ! head -1 "$f" | grep -q "^---$"; then
            error "$name — missing frontmatter (no opening ---)"
            continue
        fi
        if ! grep -q "^name:" "$f"; then
            error "$name — missing 'name' in frontmatter"
        else
            ok "$name"
        fi
    done
else
    warn "stacks/ directory missing — no stack adapters available"
fi
echo ""

# ---------- 7. install.sh references all engine dirs ----------
echo "[7/9] Checking install.sh coverage..."

for dir in "$ENGINE_DIR"/*/; do
    dirname=$(basename "$dir")
    # Skip hidden dirs
    [[ "$dirname" == .* ]] && continue
    if grep -q "\"$dirname\"" "$INSTALLER"; then
        ok "install.sh includes $dirname"
    else
        warn "install.sh does not reference $dirname — it won't be symlinked"
    fi
done

# Also check CLAUDE.md is in the items list
if grep -q '"CLAUDE.md"' "$INSTALLER"; then
    ok "install.sh includes CLAUDE.md"
else
    warn "install.sh does not reference CLAUDE.md"
fi
echo ""

# ---------- 8. Engine CLAUDE.md: required sections ----------
echo "[8/9] Checking engine CLAUDE.md..."

ENGINE_CLAUDE="$ENGINE_DIR/CLAUDE.md"
if [ -f "$ENGINE_CLAUDE" ]; then
    REQUIRED_SECTIONS=("Automatic Workflow Execution" "Graceful Degradation" "Error Recovery" "Critical Universal Rules" "Prohibited Actions")
    for section in "${REQUIRED_SECTIONS[@]}"; do
        if grep -qi "$section" "$ENGINE_CLAUDE"; then
            ok "CLAUDE.md has '$section'"
        else
            error "CLAUDE.md — missing required section: '$section'"
        fi
    done
else
    error "engine/CLAUDE.md — file missing"
fi
echo ""

# ---------- 9. Stack references in template ----------
echo "[9/9] Checking stack references in template..."

if [ -f "$TEMPLATE" ] && [ -d "$ENGINE_DIR/stacks" ]; then
    # Extract stack names referenced as defaults in the template
    STACKS_REFERENCED=$(grep -oP '(?<=Stack.*: `)[^`{]+' "$TEMPLATE" 2>/dev/null || true)
    if [ -n "$STACKS_REFERENCED" ]; then
        while IFS= read -r stack; do
            if [ -f "$ENGINE_DIR/stacks/${stack}.md" ]; then
                ok "stack '$stack' referenced in template exists"
            else
                warn "stack '$stack' referenced in template but engine/stacks/${stack}.md not found"
            fi
        done <<< "$STACKS_REFERENCED"
    else
        ok "template uses placeholder for stack (no hardcoded stack to validate)"
    fi
else
    ok "skipped (template or stacks dir missing)"
fi
echo ""

# ---------- Summary ----------
echo "==================================="
if [ $ERRORS -gt 0 ]; then
    echo "FAILED: $ERRORS error(s), $WARNINGS warning(s)"
    exit 1
elif [ $WARNINGS -gt 0 ]; then
    echo "PASSED with $WARNINGS warning(s)"
    exit 0
else
    echo "PASSED: all checks clean"
    exit 0
fi
