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

```
~/workspace/project | main * | Claude Opus 4.6 | ctx 12% | 5h: ━━░░░░░░░░░░░░░░░░░░ 10% (3h 22m) | Duchang
```

Segments (separated by `|`):

1. **Directory** — current path (`~` abbreviated)
2. **Git branch** — branch name + `*` if dirty
3. **Model** — Claude model display name
4. **Context** — context window usage %
5. **5h usage** — color-coded progress bar + % + time until reset
6. **Account** — display name (dimmed)

Color levels for usage bar:

- Green: < 50% (low)
- Cyan: 50-69% (medium)
- Yellow: 70-89% (high)
- Red: >= 90% (critical)

## Instructions

Determine if the user wants to install or uninstall based on `$ARGUMENTS`.

### Install (default, no arguments or anything other than `--uninstall`)

1. Read the shell script at `${CLAUDE_SKILL_DIR}/../../scripts/statusline-command.sh`
2. Copy it to `~/.claude/statusline-command.sh`
3. Make it executable: `chmod +x ~/.claude/statusline-command.sh`
4. Read `~/.claude/settings.json`
5. Add or update the `statusLine` field:
   ```json
   {
     "statusLine": {
       "type": "command",
       "command": "bash ~/.claude/statusline-command.sh"
     }
   }
   ```
6. Verify by checking that `~/.claude/settings.json` has the correct `statusLine` config
7. Tell the user:
   - Installation complete. Restart Claude Code to see the status line.
   - Dependencies: `jq`, `curl` (usually pre-installed)
   - Cache location: `~/.cache/claude-statusline/`
   - Usage data refreshes every 30 seconds (non-blocking background fetch)
   - Profile data refreshes every 24 hours

### Uninstall (`--uninstall`)

1. Read `~/.claude/settings.json`
2. Remove the `statusLine` field
3. Remove `~/.claude/statusline-command.sh` if it exists
4. Remove `~/.cache/claude-statusline/` if it exists
5. Tell the user the status line has been removed
