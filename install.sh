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

items=("CLAUDE.md" "agents" "commands" "prompts" "skills" "stacks")

for item in "${items[@]}"; do
    src="$ENGINE_DIR/$item"
    dest="$CLAUDE_DIR/$item"

    if [ ! -e "$src" ]; then
        echo "  Skip: $item (not found in engine/)"
        continue
    fi

    backup_if_exists "$dest"
    ln -sf "$src" "$dest"
    echo "  Linked: $item → $src"
done

# Verify critical symlinks
echo ""
echo "Verifying symlinks..."
fail=0
for item in "${items[@]}"; do
    dest="$CLAUDE_DIR/$item"
    if [ ! -e "$dest" ]; then
        echo "  FAIL: $dest does not exist"
        fail=1
    fi
done
if [ $fail -eq 0 ]; then
    echo "  All symlinks verified."
fi

echo ""
echo "Done. The following were NOT touched:"
echo "  - $CLAUDE_DIR/settings.json"
echo "  - $CLAUDE_DIR/settings.local.json"
echo "  - $CLAUDE_DIR/plugins/"
echo "  - $CLAUDE_DIR/projects/"
echo ""
echo "Next steps:"
echo "  1. cd /path/to/your/project && /init-project (or copy template/project.md to .claude/project.md)"
echo "  2. Fill in any {PLACEHOLDER} values in .claude/project.md"
echo "  3. Connect MCP integrations: copy template/mcp.json to your project, or use /mcp in Claude Code"
