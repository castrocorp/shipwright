#!/bin/bash
# =============================================================================
# Shipwright — Uninstaller (Mac/Linux)
#
# Removes ONLY engine-owned symlinks from ~/.claude/. User files, settings,
# plugins, projects, and memories are never touched.
#
# HOW IT IDENTIFIES ENGINE FILES:
#   - A symlink whose target path contains this repo's engine/ directory
#     is engine-owned → removed
#   - A regular file (not a symlink) is user-owned → preserved
#   - A symlink pointing elsewhere (different tool) → preserved
#
# NETWORK REQUESTS: None. This script is fully offline.
# DESTRUCTIVE: Only removes symlinks. No file content is ever deleted.
# =============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENGINE_DIR="$SCRIPT_DIR/engine"
CLAUDE_DIR="$HOME/.claude"

echo "Shipwright — Uninstaller (Mac/Linux)"
echo "======================================"
echo ""
echo "Engine:  $ENGINE_DIR"
echo "Target:  $CLAUDE_DIR"
echo ""

if [ ! -d "$CLAUDE_DIR" ]; then
    echo "Nothing to uninstall — $CLAUDE_DIR does not exist."
    exit 0
fi

removed=0
kept=0

# --- Remove CLAUDE.md symlink (only if it points to OUR engine) ---
claude_md="$CLAUDE_DIR/CLAUDE.md"
if [ -L "$claude_md" ]; then
    link_target=$(readlink "$claude_md")
    if [[ "$link_target" == *"$ENGINE_DIR"* ]]; then
        rm "$claude_md"
        echo "  Removed: CLAUDE.md (symlink to engine)"
        ((removed++))
    else
        echo "  Kept:    CLAUDE.md (symlink to different source)"
        ((kept++))
    fi
elif [ -e "$claude_md" ]; then
    echo "  Kept:    CLAUDE.md (not a symlink — user-owned)"
    ((kept++))
fi

# --- Remove directory symlinks (engine-owned: agents, commands, prompts, skills) ---
dir_items=("agents" "commands" "prompts" "skills")

for item in "${dir_items[@]}"; do
    dest="$CLAUDE_DIR/$item"
    if [ -L "$dest" ]; then
        link_target=$(readlink "$dest")
        if [[ "$link_target" == *"$ENGINE_DIR"* ]]; then
            rm "$dest"
            echo "  Removed: $item/ (symlink to engine)"
            ((removed++))
        else
            echo "  Kept:    $item/ (symlink to different source)"
            ((kept++))
        fi
    elif [ -e "$dest" ]; then
        echo "  Kept:    $item/ (not a symlink — user-owned)"
        ((kept++))
    fi
done

# --- Remove per-file symlinks in rules/ and stacks/ (preserve user files) ---
# Only removes symlinks pointing to our engine. Real files are user-owned.
merge_items=("rules" "stacks")

for item in "${merge_items[@]}"; do
    dest_dir="$CLAUDE_DIR/$item"

    # Handle old-style directory symlink (from pre-1.2.0 installs)
    if [ -L "$dest_dir" ]; then
        link_target=$(readlink "$dest_dir")
        if [[ "$link_target" == *"$ENGINE_DIR"* ]]; then
            rm "$dest_dir"
            echo "  Removed: $item/ (directory symlink to engine)"
            ((removed++))
        fi
        continue
    fi

    if [ ! -d "$dest_dir" ]; then
        continue
    fi

    # Walk each .md file: remove engine symlinks, keep user files
    engine_removed=0
    user_kept=0

    for f in "$dest_dir"/*.md; do
        [ -f "$f" ] || [ -L "$f" ] || continue

        if [ -L "$f" ]; then
            link_target=$(readlink "$f")
            if [[ "$link_target" == *"$ENGINE_DIR"* ]]; then
                rm "$f"
                ((engine_removed++))
            else
                ((user_kept++))
            fi
        else
            # Real file — user-owned, never touch
            ((user_kept++))
        fi
    done

    # Remove directory only if completely empty after cleanup
    if [ "$user_kept" -eq 0 ] && [ -d "$dest_dir" ]; then
        rmdir "$dest_dir" 2>/dev/null && echo "  Removed: $item/ (empty after cleanup)" || true
        ((removed++))
    else
        echo "  Cleaned: $item/ — $engine_removed engine symlink(s) removed, $user_kept user file(s) preserved"
        ((removed++))
    fi
done

# --- Remove version markers ---
for marker in "$CLAUDE_DIR/.shipwright-version" "$CLAUDE_DIR/.shipwright-update"; do
    if [ -f "$marker" ]; then
        rm "$marker"
        echo "  Removed: $(basename "$marker")"
        ((removed++))
    fi
done

echo ""
echo "Uninstall complete."
echo "  Removed: $removed item(s)"
echo "  Kept:    $kept item(s)"
echo ""
echo "The following were NOT touched:"
echo "  - $CLAUDE_DIR/CLAUDE.local.md"
echo "  - $CLAUDE_DIR/settings.json"
echo "  - $CLAUDE_DIR/settings.local.json"
echo "  - $CLAUDE_DIR/plugins/"
echo "  - $CLAUDE_DIR/projects/"
echo "  - User-created files in rules/ and stacks/"
echo ""
echo "To restore backups (if any): rename *.bak files back to their original names."
