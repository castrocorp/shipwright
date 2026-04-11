#!/bin/bash
# Shipwright — Background version check
# Writes result to ~/.claude/.shipwright-update
# Designed to run non-blocking (via hook or cron)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
UPDATE_FILE="$CLAUDE_DIR/.shipwright-update"
VERSION_FILE="$SCRIPT_DIR/VERSION"

# Bail silently if no VERSION file
[ -f "$VERSION_FILE" ] || exit 0

CURRENT=$(cat "$VERSION_FILE" | tr -d '[:space:]')

# Fetch tags (best-effort, timeout 5s)
git -C "$SCRIPT_DIR" fetch --tags --quiet 2>/dev/null &
FETCH_PID=$!

# Wait with timeout
( sleep 5 && kill $FETCH_PID 2>/dev/null ) &
TIMEOUT_PID=$!
wait $FETCH_PID 2>/dev/null
kill $TIMEOUT_PID 2>/dev/null

# Find latest tag
LATEST_TAG=$(git -C "$SCRIPT_DIR" tag -l 'v*' --sort=-v:refnum 2>/dev/null | head -1)
LATEST=${LATEST_TAG#v}

# No tags found — nothing to compare
[ -z "$LATEST" ] && exit 0

# Write result
if [ "$CURRENT" != "$LATEST" ]; then
    cat > "$UPDATE_FILE" <<EOF
status=available
current=$CURRENT
latest=$LATEST
checked=$(date -u +%Y-%m-%dT%H:%M:%S)
repo=$SCRIPT_DIR
EOF
else
    cat > "$UPDATE_FILE" <<EOF
status=up-to-date
current=$CURRENT
latest=$LATEST
checked=$(date -u +%Y-%m-%dT%H:%M:%S)
repo=$SCRIPT_DIR
EOF
fi
