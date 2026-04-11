# Shipwright Hooks

Add this to your `~/.claude/settings.json` (or project-level `.claude/settings.json`) to enable background version checking.

The hook runs `check-update.sh` in the background at the start of each conversation. Results are cached in `~/.claude/.shipwright-update` and read by `/start-task`.

## Setup

Add to your `settings.json` under the `hooks` key:

```json
{
  "hooks": {
    "PreToolCall": [
      {
        "matcher": "Task",
        "hooks": [
          {
            "type": "command",
            "command": "bash $SHIPWRIGHT_REPO/check-update.sh &",
            "timeout": 1000
          }
        ]
      }
    ]
  }
}
```

Replace `$SHIPWRIGHT_REPO` with the absolute path to your Shipwright clone (e.g., `~/dotfiles/shipwright`).

The path is also recorded in `~/.claude/.shipwright-version` after running `install.sh`.

## How it works

1. On the first tool call of a conversation, `check-update.sh` runs in the background (`&`)
2. The script does `git fetch --tags` (with 5s timeout) and compares `VERSION` against the latest tag
3. Results are written to `~/.claude/.shipwright-update`
4. `/start-task` reads this file and shows a one-line notice if an update is available
5. The check never blocks your workflow
