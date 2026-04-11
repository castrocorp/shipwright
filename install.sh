#!/bin/bash
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

# Ensure ~/.claude/ exists
mkdir -p "$CLAUDE_DIR"

backup_if_exists() {
    local target="$1"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        echo "  Backup: $target → ${target}.bak"
        mv "$target" "${target}.bak"
    elif [ -L "$target" ]; then
        rm "$target"
    fi
}

# --- Directory symlinks (engine-owned, no user files expected) ---
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

# --- File symlink (CLAUDE.md) ---
backup_if_exists "$CLAUDE_DIR/CLAUDE.md"
ln -sf "$ENGINE_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
echo "  Linked: CLAUDE.md → $ENGINE_DIR/CLAUDE.md"

# --- Per-file merge (rules/ and stacks/) ---
# Symlinks individual engine files, preserves user-created files
merge_items=("rules" "stacks")

for item in "${merge_items[@]}"; do
    src_dir="$ENGINE_DIR/$item"
    dest_dir="$CLAUDE_DIR/$item"

    if [ ! -d "$src_dir" ]; then
        echo "  Skip: $item (not found in engine/)"
        continue
    fi

    # If dest is a symlink to a directory, replace with real directory
    if [ -L "$dest_dir" ]; then
        rm "$dest_dir"
        mkdir -p "$dest_dir"
        echo "  Converted: $item/ from directory symlink to per-file merge"
    fi

    # If dest is a real directory with a .bak pending, skip backup (already migrated)
    mkdir -p "$dest_dir"

    # Symlink each engine file individually
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
            # Real file — user-owned, skip
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

# Verify
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

# Write version marker
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
echo "  1. cd /path/to/your/project && /init-project (or copy template/project.md to .claude/project.md)"
echo "  2. Fill in any {PLACEHOLDER} values in .claude/project.md"
echo "  3. Connect MCP integrations: copy template/mcp.json to your project, or use /mcp in Claude Code"
