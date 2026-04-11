#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
VERSION_FILE="$SCRIPT_DIR/VERSION"

echo "Shipwright — Updater"
echo "====================="
echo ""

# Parse args
CHECK_ONLY=false
TARGET_VERSION=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --check) CHECK_ONLY=true; shift ;;
        --version) TARGET_VERSION="$2"; shift 2 ;;
        *) echo "Usage: update.sh [--check] [--version vX.Y.Z]"; exit 1 ;;
    esac
done

# Current version
if [ -f "$VERSION_FILE" ]; then
    CURRENT=$(cat "$VERSION_FILE" | tr -d '[:space:]')
else
    CURRENT="unknown"
fi

echo "Current version: $CURRENT"
echo "Repo: $SCRIPT_DIR"
echo ""

# Fetch latest tags
echo "Fetching remote tags..."
git -C "$SCRIPT_DIR" fetch --tags --quiet 2>/dev/null || {
    echo "WARNING: Could not fetch remote tags (no network?)"
    echo "Comparing against locally available tags only."
}

# Determine target
if [ -n "$TARGET_VERSION" ]; then
    TARGET_TAG="$TARGET_VERSION"
    # Ensure v prefix
    [[ "$TARGET_TAG" != v* ]] && TARGET_TAG="v$TARGET_TAG"
else
    TARGET_TAG=$(git -C "$SCRIPT_DIR" tag -l 'v*' --sort=-v:refnum 2>/dev/null | head -1)
fi

if [ -z "$TARGET_TAG" ]; then
    echo "No version tags found. Nothing to update."
    exit 0
fi

TARGET=${TARGET_TAG#v}
echo "Target version:  $TARGET ($TARGET_TAG)"
echo ""

# Check only mode
if [ "$CHECK_ONLY" = true ]; then
    if [ "$CURRENT" = "$TARGET" ]; then
        echo "Already up to date."
    else
        echo "Update available: $CURRENT → $TARGET"
        echo ""
        echo "Changelog:"
        git -C "$SCRIPT_DIR" log --oneline "v$CURRENT..$TARGET_TAG" 2>/dev/null || \
            echo "  (could not determine changelog)"
    fi
    exit 0
fi

# Already up to date
if [ "$CURRENT" = "$TARGET" ]; then
    echo "Already up to date."
    exit 0
fi

# Check for local modifications in engine/
DIRTY=$(git -C "$SCRIPT_DIR" diff --name-only HEAD -- engine/ 2>/dev/null)
if [ -n "$DIRTY" ]; then
    echo "WARNING: You have local modifications in engine/:"
    echo "$DIRTY"
    echo ""
    echo "These will be stashed before updating and restored after."
    echo ""
    read -p "Continue? [y/N] " -n 1 -r
    echo ""
    [[ $REPLY =~ ^[Yy]$ ]] || { echo "Aborted."; exit 1; }
    git -C "$SCRIPT_DIR" stash push -m "shipwright-update-backup" -- engine/
    STASHED=true
fi

# Show changelog
echo ""
echo "Changelog ($CURRENT → $TARGET):"
git -C "$SCRIPT_DIR" log --oneline "v$CURRENT..$TARGET_TAG" 2>/dev/null || \
    echo "  (could not determine changelog)"
echo ""

# Checkout target tag
echo "Updating to $TARGET_TAG..."
git -C "$SCRIPT_DIR" checkout "$TARGET_TAG" --quiet 2>/dev/null

# Restore stashed changes if any
if [ "${STASHED:-false}" = true ]; then
    echo "Restoring local modifications..."
    git -C "$SCRIPT_DIR" stash pop --quiet 2>/dev/null || {
        echo ""
        echo "WARNING: Could not auto-restore your local modifications."
        echo "Your changes are saved in git stash. Run:"
        echo "  cd $SCRIPT_DIR && git stash pop"
    }
fi

# Re-run installer
echo ""
echo "Re-running installer..."
bash "$SCRIPT_DIR/install.sh"

echo ""
echo "Updated: $CURRENT → $TARGET"
