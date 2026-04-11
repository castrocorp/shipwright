---
description: Check for Shipwright updates and install the latest version
---

# Update Shipwright Command

## Step 1: Find Installation

Read `~/.claude/.shipwright-version` to extract `repo=` path and `version=`.

If the file does not exist, ask the user where they cloned Shipwright.

## Step 2: Check for Updates

Run:
```bash
bash {REPO_PATH}/update.sh --check
```

This compares the current version against the latest remote tag and shows the changelog.

## Step 3: Prompt for Confirmation

If an update is available, show the user:
- Current version → target version
- Changelog (commit list)
- Ask: "Update now?"

If already up to date, report and stop.

## Step 4: Run Update

```bash
bash {REPO_PATH}/update.sh
```

This will:
1. Checkout the latest tag
2. Re-run `install.sh` (handles new directories)
3. Update `~/.claude/.shipwright-version`

## Step 5: Report Results

Print the new version and any notable changes.

If the update added new engine directories, they are automatically symlinked by `install.sh`.

## Rules

- NEVER update without user confirmation
- If `update.sh` fails, report the error — do NOT retry
- If the user wants a specific version: `bash {REPO_PATH}/update.sh --version vX.Y.Z`
