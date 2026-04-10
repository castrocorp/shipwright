#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENGINE_DIR="$SCRIPT_DIR/engine"
CLAUDE_DIR="$HOME/.claude"

echo "Claude Workflow Engine — Installer (Mac/Linux)"
echo "================================================"
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

items=("CLAUDE.md" "commands" "skills" "stacks")

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

echo ""
echo "Done. The following were NOT touched:"
echo "  - $CLAUDE_DIR/settings.json"
echo "  - $CLAUDE_DIR/settings.local.json"
echo "  - $CLAUDE_DIR/plugins/"
echo "  - $CLAUDE_DIR/projects/"
echo ""
echo "Next steps:"
echo "  1. Copy template/project.md to your project's .claude/project.md"
echo "  2. Fill in the project-specific values"
echo "  3. Configure MCP servers (Slack, JIRA) in settings.json"
