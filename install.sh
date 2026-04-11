#!/bin/bash
# =============================================================================
# Shipwright — Installer (Mac/Linux)
#
# Creates symlinks from the engine into ~/.claude/ so Claude Code loads
# Shipwright's workflow, commands, agents, skills, rules, and stacks.
#
# WHAT IT DOES:
#   - Symlinks engine-owned directories (agents, commands, prompts, skills)
#     as whole directories into ~/.claude/
#   - Symlinks rules/ and stacks/ files INDIVIDUALLY (per-file merge) so
#     user-created files in those dirs are never overwritten
#   - Symlinks CLAUDE.md (the workflow engine)
#   - Writes a version marker to ~/.claude/.shipwright-version
#
# WHAT IT NEVER TOUCHES:
#   - ~/.claude/CLAUDE.local.md (personal overrides)
#   - ~/.claude/settings.json / settings.local.json
#   - ~/.claude/plugins/
#   - ~/.claude/projects/ (memories)
#   - User-created files in rules/ and stacks/
#
# NETWORK REQUESTS: None. This script is fully offline.
#
# SAFE TO RE-RUN: Yes. Idempotent — updates existing symlinks, skips user files.
# =============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENGINE_DIR="$SCRIPT_DIR/engine"
CLAUDE_DIR="$HOME/.claude"

echo "Shipwright — Installer (Mac/Linux)"
echo "===================================="
echo ""
echo "Source:  $ENGINE_DIR"
echo "Target:  $CLAUDE_DIR"
echo ""

# Ensure ~/.claude/ exists (no-op if already present)
mkdir -p "$CLAUDE_DIR"

# backup_if_exists — handles pre-existing files/dirs before symlinking
#   - Real file/dir → renamed to .bak (preserves user data)
#   - Existing symlink → removed (will be recreated)
#   - Nothing there → no-op
backup_if_exists() {
    local target="$1"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        echo "  Backup: $target → ${target}.bak"
        mv "$target" "${target}.bak"
    elif [ -L "$target" ]; then
        rm "$target"
    fi
}

# --- Phase 1: Directory symlinks ---
# These dirs are fully engine-owned. Users don't add files here.
# The entire directory is symlinked as one unit.
dir_items=("agents" "commands" "prompts" "skills")

for item in "${dir_items[@]}"; do
    src="$ENGINE_DIR/$item"
    dest="$CLAUDE_DIR/$item"

    if [ ! -e "$src" ]; then
        echo "  Skip: $item (not found in engine/)"
        continue
    fi

    backup_if_exists "$dest"
    ln -sf "$src" "$dest"
    echo "  Linked: $item/ → $src"
done

# --- Phase 2: File symlink (CLAUDE.md) ---
# The main workflow file. User overrides go in CLAUDE.local.md (never touched).
backup_if_exists "$CLAUDE_DIR/CLAUDE.md"
ln -sf "$ENGINE_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
echo "  Linked: CLAUDE.md → $ENGINE_DIR/CLAUDE.md"

# --- Phase 3: Per-file merge (rules/ and stacks/) ---
# These dirs can contain BOTH engine files AND user files.
# Engine files are symlinked individually. User files are left untouched.
#
# How it distinguishes:
#   - Symlink → engine-owned (update it)
#   - Real file → user-owned (skip it)
#   - New file from engine → create symlink
merge_items=("rules" "stacks")

for item in "${merge_items[@]}"; do
    src_dir="$ENGINE_DIR/$item"
    dest_dir="$CLAUDE_DIR/$item"

    if [ ! -d "$src_dir" ]; then
        echo "  Skip: $item (not found in engine/)"
        continue
    fi

    # If dest is currently a directory symlink (from old install), convert to real dir
    if [ -L "$dest_dir" ]; then
        rm "$dest_dir"
        mkdir -p "$dest_dir"
        echo "  Converted: $item/ from directory symlink to per-file merge"
    fi

    # Ensure destination directory exists
    mkdir -p "$dest_dir"

    # Symlink each engine .md file individually
    engine_count=0
    user_count=0
    for f in "$src_dir"/*.md; do
        [ -f "$f" ] || continue
        fname=$(basename "$f")
        dest_file="$dest_dir/$fname"

        if [ -L "$dest_file" ]; then
            # Existing engine symlink — update it
            rm "$dest_file"
            ln -sf "$f" "$dest_file"
        elif [ -e "$dest_file" ]; then
            # Real file — user-owned, never touch
            ((user_count++))
            continue
        else
            # New engine file — create symlink
            ln -sf "$f" "$dest_file"
        fi
        ((engine_count++))
    done

    echo "  Merged: $item/ — $engine_count engine file(s) symlinked, $user_count user file(s) preserved"
done

# --- Phase 4: Verify ---
echo ""
echo "Verifying installation..."
fail=0
all_items=("CLAUDE.md" "${dir_items[@]}" "${merge_items[@]}")
for item in "${all_items[@]}"; do
    dest="$CLAUDE_DIR/$item"
    if [ ! -e "$dest" ]; then
        echo "  FAIL: $dest does not exist"
        fail=1
    fi
done
if [ $fail -eq 0 ]; then
    echo "  All items verified."
fi

# --- Phase 5: Version marker ---
# Records installed version and repo path for update.sh and /update-shipwright
VERSION=$(cat "$SCRIPT_DIR/VERSION" 2>/dev/null || echo "unknown")
cat > "$CLAUDE_DIR/.shipwright-version" <<VEOF
version=$VERSION
repo=$SCRIPT_DIR
installed=$(date -u +%Y-%m-%dT%H:%M:%S)
VEOF
echo "  Version: $VERSION (recorded in $CLAUDE_DIR/.shipwright-version)"

echo ""
echo "Done. The following were NOT touched:"
echo "  - $CLAUDE_DIR/CLAUDE.local.md (personal overrides)"
echo "  - $CLAUDE_DIR/settings.json"
echo "  - $CLAUDE_DIR/settings.local.json"
echo "  - $CLAUDE_DIR/plugins/"
echo "  - $CLAUDE_DIR/projects/"
echo "  - User files in $CLAUDE_DIR/rules/ and $CLAUDE_DIR/stacks/"
echo ""
echo "Next steps:"
echo "  1. Install the ralph-loop plugin (recommended for iterative TDD):"
echo "     In Claude Code, run: /plugin install ralph-loop"
echo "  2. cd /path/to/your/project && /init-project"
echo "  3. Fill in any {PLACEHOLDER} values in .claude/project.md"
echo "  4. Connect MCP integrations via /mcp in Claude Code (optional)"
