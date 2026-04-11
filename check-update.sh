#!/bin/bash
# =============================================================================
# Shipwright — Background Version Check
#
# Lightweight script designed to run non-blocking (via Claude Code hook or cron).
# Compares the local VERSION file against the latest remote git tag and writes
# the result to ~/.claude/.shipwright-update for /start-task to read.
#
# DOES NOT update anything. Only writes a status file.
#
# NETWORK REQUESTS:
#   - git fetch --tags (with 5-second timeout)
#   No other network activity.
#
# OUTPUT: ~/.claude/.shipwright-update (key=value format)
#   status=available|up-to-date
#   current=1.2.0
#   latest=1.3.0
#   checked=2026-04-11T03:00:00
#   repo=/path/to/shipwright
#
# USAGE:
#   bash check-update.sh          # Run directly
#   bash check-update.sh &        # Run in background (from hook)
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
UPDATE_FILE="$CLAUDE_DIR/.shipwright-update"
VERSION_FILE="$SCRIPT_DIR/VERSION"

# Bail silently if no VERSION file (not a proper install)
[ -f "$VERSION_FILE" ] || exit 0

CURRENT=$(cat "$VERSION_FILE" | tr -d '[:space:]')

# Fetch tags with a 5-second timeout to avoid blocking
# This is the ONLY network request in the script
git -C "$SCRIPT_DIR" fetch --tags --quiet 2>/dev/null &
FETCH_PID=$!

# Kill fetch if it takes longer than 5 seconds
( sleep 5 && kill $FETCH_PID 2>/dev/null ) &
TIMEOUT_PID=$!
wait $FETCH_PID 2>/dev/null
kill $TIMEOUT_PID 2>/dev/null

# Find latest semver tag from locally available tags
LATEST_TAG=$(git -C "$SCRIPT_DIR" tag -l 'v*' --sort=-v:refnum 2>/dev/null | head -1)
LATEST=${LATEST_TAG#v}

# No tags found — nothing to compare
[ -z "$LATEST" ] && exit 0

# Write result file for /start-task to read
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
