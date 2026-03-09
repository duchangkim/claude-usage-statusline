# claude-usage-statusline

Claude Code status line plugin that displays API usage with a color-coded progress bar.

```
~/project | main * | Claude Opus 4.6 | ctx 12% | 5h: ━━━━░░░░░░░░░░░░░░░░ 20% (3h 22m) | Duchang
```

## Features

- **5-Hour usage bar** — real-time API utilization from OAuth endpoint
- **Color-coded** — green (< 50%) / cyan (50-69%) / yellow (70-89%) / red (>= 90%)
- **Reset timer** — time remaining until rate limit resets
- **Account name** — display name from your Claude profile
- **Non-blocking** — background fetch with 30s cache, no status line lag
- **Cross-platform** — macOS (Keychain + file) and Linux (file) credential support
- **Smart install** — detects existing statusline and appends usage segments instead of replacing

## Prerequisites

- [Claude Code](https://claude.ai/code) with OAuth login (Pro/Max plan)
- `jq` and `curl` (pre-installed on most systems)

## Install

### As a plugin (recommended)

```bash
claude /install-plugin https://github.com/duchangkim/claude-usage-statusline
```

Then run the skill:

```
/setup-usage-statusline
```

### Manual

```bash
# Clone
git clone https://github.com/duchangkim/claude-usage-statusline.git

# Test locally
claude --plugin-dir ./claude-usage-statusline
```

Then run `/setup-usage-statusline` inside Claude Code.

## Uninstall

```
/setup-usage-statusline --uninstall
```

## How it works

1. Reads OAuth credentials from macOS Keychain (`Claude Code-credentials`) or `~/.claude/.credentials.json`
2. Calls `GET /api/oauth/usage` to get 5-hour utilization (cached for 30s)
3. Calls `GET /api/oauth/profile` to get account display name (cached for 24h)
4. Renders a progress bar with ANSI colors in the Claude Code status line

## Install modes

### Full mode (no existing statusline)

Sets up a complete status line with all segments:

```
~/project | main * | Claude Opus 4.6 | ctx 12% | 5h: ━━░░░░░░░░ 10% (3h 22m) | Duchang
```

| Segment   | Example                       | Description                   |
| --------- | ----------------------------- | ----------------------------- |
| Directory | `~/project`                   | Current working directory     |
| Git       | `main *`                      | Branch name, `*` if dirty     |
| Model     | `Claude Opus 4.6`             | Active model                  |
| Context   | `ctx 12%`                     | Context window usage          |
| 5h Usage  | `5h: ━━░░░░░░░░ 10% (3h 22m)` | API usage bar + reset time    |
| Account   | `Duchang`                     | Account display name (dimmed) |

### Addon mode (existing statusline detected)

Appends only usage segments to your current status line:

```
<your existing statusline> | 5h: ━━░░░░░░░░ 10% (3h 22m) | Duchang
```

## License

MIT
