---
name: setup-usage-statusline
description: Set up Claude Code status line with API usage progress bar and account name. Displays 5-hour utilization with color-coded bar (green/cyan/yellow/red), remaining time, and account display name.
user-invocable: true
allowed-tools: Read, Edit, Write, Bash
argument-hint: "[--uninstall]"
---

# Setup Usage Status Line

Configure the Claude Code status line to show API usage with a color-coded progress bar.

## What it displays

Full mode (no existing statusline):
```
~/workspace/project | main * | Claude Opus 4.6 | ctx 12% | 5h: ━━░░░░░░░░░░░░░░░░░░ 10% (3h 22m) | Duchang
```

Addon mode (existing statusline detected):
```
<existing statusline output> | 5h: ━━░░░░░░░░░░░░░░░░░░ 10% (3h 22m) | Duchang
```

### Full mode segments (separated by `|`):

1. **Directory** — current path (`~` abbreviated)
2. **Git branch** — branch name + `*` if dirty
3. **Model** — Claude model display name
4. **Context** — context window usage %
5. **5h usage** — color-coded progress bar + % + time until reset
6. **Account** — display name (dimmed)

### Addon mode segments (appended to existing statusline):

1. **5h usage** — color-coded progress bar + % + time until reset
2. **Account** — display name (dimmed)

Color levels for usage bar:

- Green: < 50% (low)
- Cyan: 50-69% (medium)
- Yellow: 70-89% (high)
- Red: >= 90% (critical)

## Instructions

Determine if the user wants to install or uninstall based on `$ARGUMENTS`.

### Install (default, no arguments or anything other than `--uninstall`)

1. Read `~/.claude/settings.json` to check if a `statusLine` field already exists.

2. **If `statusLine` does NOT exist** (full mode):
   1. Read the shell script at `${CLAUDE_SKILL_DIR}/../../scripts/statusline-command.sh`
   2. Copy it to `~/.claude/statusline-command.sh`
   3. Make it executable: `chmod +x ~/.claude/statusline-command.sh`
   4. Add the `statusLine` field to `~/.claude/settings.json`:
      ```json
      {
        "statusLine": {
          "type": "command",
          "command": "bash ~/.claude/statusline-command.sh"
        }
      }
      ```

3. **If `statusLine` already exists** (addon mode):
   1. Read the shell script at `${CLAUDE_SKILL_DIR}/../../scripts/statusline-usage-addon.sh`
   2. Copy it to `~/.claude/statusline-usage-addon.sh`
   3. Make it executable: `chmod +x ~/.claude/statusline-usage-addon.sh`
   4. Read the shell script at `${CLAUDE_SKILL_DIR}/../../scripts/statusline-wrapper.sh`
   5. Copy it to `~/.claude/statusline-wrapper.sh`
   6. Make it executable: `chmod +x ~/.claude/statusline-wrapper.sh`
   7. Save the current `statusLine.command` value as the original command.
   8. Update the `statusLine` field in `~/.claude/settings.json`:
      ```json
      {
        "statusLine": {
          "type": "command",
          "command": "ORIGINAL_STATUSLINE_CMD='<original command here>' bash ~/.claude/statusline-wrapper.sh"
        }
      }
      ```
      Replace `<original command here>` with the actual original `statusLine.command` value. Use single quotes around the original command value to prevent premature expansion.

4. Verify by checking that `~/.claude/settings.json` has the correct `statusLine` config.
5. Tell the user:
   - Installation complete. Restart Claude Code to see the status line.
   - Which mode was used (full or addon)
   - Dependencies: `jq`, `curl` (usually pre-installed)
   - Cache location: `~/.cache/claude-statusline/`
   - Usage data refreshes every 30 seconds (non-blocking background fetch)
   - Profile data refreshes every 24 hours

### Uninstall (`--uninstall`)

1. Read `~/.claude/settings.json`
2. Check the current `statusLine.command` value.
3. **If it uses the wrapper** (addon mode was used):
   - Extract the original command from the `ORIGINAL_STATUSLINE_CMD='...'` part.
   - Restore `statusLine` to the original command:
     ```json
     {
       "statusLine": {
         "type": "command",
         "command": "<original command>"
       }
     }
     ```
   - Remove `~/.claude/statusline-usage-addon.sh` if it exists
   - Remove `~/.claude/statusline-wrapper.sh` if it exists
4. **If it uses the full statusline-command.sh**:
   - Remove the `statusLine` field entirely
   - Remove `~/.claude/statusline-command.sh` if it exists
5. Remove `~/.cache/claude-statusline/` if it exists
6. Tell the user the status line has been removed (or restored to original if addon mode)
