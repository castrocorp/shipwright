#!/bin/bash
# =============================================================================
# Shipwright — Updater
#
# Updates the local Shipwright clone to a target version (default: latest tag).
# Re-runs install.sh after checkout to pick up new engine directories.
#
# USAGE:
#   ./update.sh                  # Update to latest version
#   ./update.sh --check          # Check for updates without applying
#   ./update.sh --version v1.3.0 # Update to a specific version
#   ./update.sh --skip-verify    # Skip GPG signature verification (not recommended)
#
# SECURITY:
#   Before applying any changes, verifies the GPG signature on the target tag.
#   Three outcomes:
#     VERIFIED    — signed tag, trusted key → proceeds automatically
#     NOT SIGNED  — unsigned tag → warns, asks confirmation
#     FAILED      — bad signature → blocks update, warns of compromise
#
# NETWORK REQUESTS:
#   - git fetch --tags (to check for new versions)
#   No other network activity.
#
# SAFE TO RE-RUN: Yes. Idempotent.
# =============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
VERSION_FILE="$SCRIPT_DIR/VERSION"

echo "Shipwright — Updater"
echo "====================="
echo ""

# --- Parse arguments ---
CHECK_ONLY=false
TARGET_VERSION=""
SKIP_VERIFY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --check) CHECK_ONLY=true; shift ;;
        --version) TARGET_VERSION="$2"; shift 2 ;;
        --skip-verify) SKIP_VERIFY=true; shift ;;
        *) echo "Usage: update.sh [--check] [--version vX.Y.Z] [--skip-verify]"; exit 1 ;;
    esac
done

# --- Read current version ---
if [ -f "$VERSION_FILE" ]; then
    CURRENT=$(cat "$VERSION_FILE" | tr -d '[:space:]')
else
    CURRENT="unknown"
fi

echo "Current version: $CURRENT"
echo "Repo: $SCRIPT_DIR"
echo ""

# --- Fetch remote tags ---
# This is the ONLY network request in the entire script.
echo "Fetching remote tags..."
git -C "$SCRIPT_DIR" fetch --tags --quiet 2>/dev/null || {
    echo "WARNING: Could not fetch remote tags (no network?)"
    echo "Comparing against locally available tags only."
}

# --- Determine target version ---
if [ -n "$TARGET_VERSION" ]; then
    TARGET_TAG="$TARGET_VERSION"
    # Ensure v prefix for consistency
    [[ "$TARGET_TAG" != v* ]] && TARGET_TAG="v$TARGET_TAG"
else
    # Find latest semver tag (sorted by version, descending)
    TARGET_TAG=$(git -C "$SCRIPT_DIR" tag -l 'v*' --sort=-v:refname 2>/dev/null | head -1)
fi

if [ -z "$TARGET_TAG" ]; then
    echo "No version tags found. Nothing to update."
    exit 0
fi

TARGET=${TARGET_TAG#v}
echo "Target version:  $TARGET ($TARGET_TAG)"
echo ""

# --- GPG signature verification ---
# Verifies the tag is signed by a trusted maintainer before applying changes.
# This prevents supply-chain attacks where a compromised repo pushes
# malicious prompts (engine files are markdown that instruct Claude).
verify_tag() {
    local tag="$1"

    # Allow bypassing for development (not recommended for public forks)
    if [ "$SKIP_VERIFY" = true ]; then
        echo "  Signature verification skipped (--skip-verify)"
        return 0
    fi

    # Check if gpg is installed
    if ! command -v gpg &>/dev/null; then
        echo "  WARNING: gpg not installed — cannot verify tag signature."
        echo "  Install GPG or use --skip-verify to bypass (at your own risk)."
        echo ""
        read -p "  Continue without verification? [y/N] " -n 1 -r
        echo ""
        [[ $REPLY =~ ^[Yy]$ ]] || { echo "Aborted."; exit 1; }
        return 0
    fi

    # Attempt signature verification
    if git -C "$SCRIPT_DIR" tag -v "$tag" &>/dev/null; then
        local signer
        signer=$(git -C "$SCRIPT_DIR" tag -v "$tag" 2>&1 | grep "^gpg:.*Good signature" || true)
        if [ -n "$signer" ]; then
            echo "  Signature: VERIFIED"
            echo "  $signer"
            return 0
        fi
    fi

    # Analyze why verification failed
    local verify_output
    verify_output=$(git -C "$SCRIPT_DIR" tag -v "$tag" 2>&1 || true)

    # Case: tag exists but has no signature at all
    if echo "$verify_output" | grep -q "no signature"; then
        echo "  Signature: NOT SIGNED (tag has no GPG signature)"
        echo ""
        echo "  This tag was not signed by the maintainer."
        echo "  This is safe for personal/private repos but risky for public ones."
        echo ""
        read -p "  Continue with unsigned tag? [y/N] " -n 1 -r
        echo ""
        [[ $REPLY =~ ^[Yy]$ ]] || { echo "Aborted."; exit 1; }
        return 0
    fi

    # Case: signature exists but is invalid or from untrusted key
    echo "  Signature: FAILED"
    echo ""
    echo "$verify_output" | head -5
    echo ""
    # Check if it's a missing key vs actual bad signature
    if echo "$verify_output" | grep -qi "no public key\|not found\|unknown"; then
        echo "  The signing key is not in your keyring. Import it with:"
        echo "    gpg --import $SCRIPT_DIR/PUBKEY.asc"
        echo "  Or from a keyserver:"
        echo "    gpg --keyserver keys.openpgp.org --recv-keys A8697988B2D8E6C579651CE03DCF9E5E79224F67"
    else
        echo "  The tag signature could not be verified."
        echo "  This may indicate a compromised release."
        echo "  DO NOT proceed unless you trust the source."
    fi
    echo ""
    read -p "  Continue anyway? (NOT RECOMMENDED) [y/N] " -n 1 -r
    echo ""
    [[ $REPLY =~ ^[Yy]$ ]] || { echo "Aborted."; exit 1; }
    return 0
}

# --- Check-only mode ---
if [ "$CHECK_ONLY" = true ]; then
    if [ "$CURRENT" = "$TARGET" ]; then
        echo "Already up to date."
    else
        echo "Update available: $CURRENT → $TARGET"
        echo ""
        verify_tag "$TARGET_TAG"
        echo ""
        echo "Changelog:"
        git -C "$SCRIPT_DIR" log --oneline "v$CURRENT..$TARGET_TAG" 2>/dev/null || \
            echo "  (could not determine changelog)"
    fi
    exit 0
fi

# --- Already up to date ---
if [ "$CURRENT" = "$TARGET" ]; then
    echo "Already up to date."
    exit 0
fi

# --- Verify signature BEFORE making any changes ---
echo "Verifying release signature..."
verify_tag "$TARGET_TAG"
echo ""

# --- Stash local modifications if any ---
# Users shouldn't modify engine/ files (use CLAUDE.local.md instead),
# but if they did, we preserve their changes via git stash.
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

# --- Show changelog ---
echo ""
echo "Changelog ($CURRENT → $TARGET):"
git -C "$SCRIPT_DIR" log --oneline "v$CURRENT..$TARGET_TAG" 2>/dev/null || \
    echo "  (could not determine changelog)"
echo ""

# --- Checkout target tag ---
echo "Updating to $TARGET_TAG..."
git -C "$SCRIPT_DIR" checkout "$TARGET_TAG" --quiet 2>/dev/null

# --- Restore stashed changes if any ---
if [ "${STASHED:-false}" = true ]; then
    echo "Restoring local modifications..."
    git -C "$SCRIPT_DIR" stash pop --quiet 2>/dev/null || {
        echo ""
        echo "WARNING: Could not auto-restore your local modifications."
        echo "Your changes are saved in git stash. Run:"
        echo "  cd $SCRIPT_DIR && git stash pop"
    }
fi

# --- Re-run installer to pick up any new directories/files ---
echo ""
echo "Re-running installer..."
bash "$SCRIPT_DIR/install.sh"

echo ""
echo "Updated: $CURRENT → $TARGET"
