#!/usr/bin/env bash
# Claude Code status line wrapper
# Runs the original statusline command and appends usage + account segments
# Usage: ORIGINAL_STATUSLINE_CMD="..." bash statusline-wrapper.sh

input=$(cat)

# Run original statusline command
original_output=$(echo "$input" | eval "$ORIGINAL_STATUSLINE_CMD" 2>/dev/null)

# Run usage addon
addon_output=$(echo "$input" | bash ~/.claude/statusline-usage-addon.sh 2>/dev/null)

printf "%s%s" "$original_output" "$addon_output"
