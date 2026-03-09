#!/usr/bin/env bash
# Claude Code status line
# Segments: dir | git branch (*dirty) | model | context usage | API usage bar | account name
# Dependencies: jq, curl

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
model=$(echo "$input" | jq -r '.model.display_name // ""')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# Shorten $HOME to ~
short_dir="${cwd/#$HOME/~}"

# Git branch and dirty flag
git_part=""
if git_branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null || \
                git -C "$cwd" rev-parse --short HEAD 2>/dev/null); then
  git_dirty=""
  if ! git -C "$cwd" diff --quiet 2>/dev/null || \
     ! git -C "$cwd" diff --cached --quiet 2>/dev/null; then
    git_dirty=" *"
  fi
  git_part=" | ${git_branch}${git_dirty}"
fi

# Context usage
ctx_part=""
if [ -n "$used_pct" ]; then
  used_int=${used_pct%.*}
  ctx_part=" | ctx ${used_int}%"
fi

# --- API Usage Bar ---
CACHE_DIR="${HOME}/.cache/claude-statusline"
CACHE_FILE="${CACHE_DIR}/usage.json"
PROFILE_FILE="${CACHE_DIR}/profile.json"
CACHE_TTL=120  # seconds

mkdir -p "$CACHE_DIR"

# Read OAuth token (macOS Keychain first, then file fallback)
get_oauth_token() {
  local creds=""
  creds=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null) || true
  if [ -z "$creds" ] && [ -f "${HOME}/.claude/.credentials.json" ]; then
    creds=$(cat "${HOME}/.claude/.credentials.json")
  fi
  if [ -z "$creds" ]; then
    return 1
  fi
  echo "$creds" | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null
}

# Fetch usage + profile data (with caching)
fetch_usage() {
  local token
  token=$(get_oauth_token) || return 1
  if [ -z "$token" ]; then
    return 1
  fi

  local auth_headers=(-H "Authorization: Bearer ${token}" -H "anthropic-beta: oauth-2025-04-20" -H "Content-Type: application/json")

  # Usage
  local response
  response=$(curl -sf --max-time 2 "${auth_headers[@]}" \
    "https://api.anthropic.com/api/oauth/usage" 2>/dev/null) || return 1
  echo "$response" > "$CACHE_FILE"

  # Profile (cache for 1 day)
  local profile_age=999999
  if [ -f "$PROFILE_FILE" ]; then
    if [[ "$OSTYPE" == darwin* ]]; then
      profile_age=$(( $(date +%s) - $(stat -f %m "$PROFILE_FILE") ))
    else
      profile_age=$(( $(date +%s) - $(stat -c %Y "$PROFILE_FILE") ))
    fi
  fi
  if [ "$profile_age" -gt 86400 ]; then
    local profile
    profile=$(curl -sf --max-time 2 "${auth_headers[@]}" \
      "https://api.anthropic.com/api/oauth/profile" 2>/dev/null) || return 0
    echo "$profile" > "$PROFILE_FILE"
  fi
}

# Check if cache is fresh
need_refresh=false
if [ ! -f "$CACHE_FILE" ]; then
  need_refresh=true
else
  if [[ "$OSTYPE" == darwin* ]]; then
    cache_age=$(( $(date +%s) - $(stat -f %m "$CACHE_FILE") ))
  else
    cache_age=$(( $(date +%s) - $(stat -c %Y "$CACHE_FILE") ))
  fi
  if [ "$cache_age" -gt "$CACHE_TTL" ]; then
    need_refresh=true
  fi
fi

if [ "$need_refresh" = true ]; then
  fetch_usage
fi

# ANSI color codes
ESC=$'\033'
RST="${ESC}[0m"
DIM="${ESC}[2m"

# Color by utilization percentage (4 levels)
#   < 50%  -> bright green  (low)
#   50-69% -> bright cyan   (medium)
#   70-89% -> bright yellow (high)
#   >= 90% -> bright red    (critical)
color_by_pct() {
  local pct=$1
  if [ "$pct" -ge 90 ]; then
    echo "${ESC}[91m"
  elif [ "$pct" -ge 70 ]; then
    echo "${ESC}[93m"
  elif [ "$pct" -ge 50 ]; then
    echo "${ESC}[96m"
  else
    echo "${ESC}[92m"
  fi
}

# Render progress bar: usage_bar <percentage> <bar_width>
usage_bar() {
  local pct=$1
  local width=${2:-20}
  local filled=$(( pct * width / 100 ))
  local empty=$(( width - filled ))
  local color
  color=$(color_by_pct "$pct")

  local bar=""
  bar+="${color}"
  local i
  for ((i = 0; i < filled; i++)); do bar+="━"; done
  bar+="${RST}${DIM}"
  for ((i = 0; i < empty; i++)); do bar+="░"; done
  bar+="${RST}"
  echo -n "$bar"
}

# Format time remaining from ISO date
format_remaining() {
  local reset_at="$1"
  if [ -z "$reset_at" ] || [ "$reset_at" = "null" ]; then
    echo ""
    return
  fi

  local reset_epoch now_epoch diff_s
  if [[ "$OSTYPE" == darwin* ]]; then
    reset_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${reset_at%%.*}" +%s 2>/dev/null) || return
  else
    reset_epoch=$(date -d "$reset_at" +%s 2>/dev/null) || return
  fi
  now_epoch=$(date +%s)
  diff_s=$(( reset_epoch - now_epoch ))

  if [ "$diff_s" -le 0 ]; then
    echo "now"
    return
  fi

  local days=$(( diff_s / 86400 ))
  local hours=$(( (diff_s % 86400) / 3600 ))
  local mins=$(( (diff_s % 3600) / 60 ))

  if [ "$days" -gt 0 ]; then
    echo "${days}d ${hours}h"
  elif [ "$hours" -gt 0 ]; then
    echo "${hours}h ${mins}m"
  else
    echo "${mins}m"
  fi
}

# Build usage part from cache
usage_part=""
if [ -f "$CACHE_FILE" ]; then
  five_util=$(jq -r '.five_hour.utilization // empty' "$CACHE_FILE" 2>/dev/null)
  five_reset=$(jq -r '.five_hour.resets_at // empty' "$CACHE_FILE" 2>/dev/null)

  if [ -n "$five_util" ]; then
    five_pct=$(printf "%.0f" "$five_util" 2>/dev/null || echo "0")
    bar=$(usage_bar "$five_pct" 20)
    color=$(color_by_pct "$five_pct")
    remaining=$(format_remaining "$five_reset")
    time_part=""
    if [ -n "$remaining" ]; then
      time_part=" ${DIM}(${remaining})${RST}"
    fi
    usage_part=" | 5h: ${bar} ${color}${five_pct}%${RST}${time_part}"
  fi
fi

# Account name from profile cache
account_part=""
if [ -f "$PROFILE_FILE" ]; then
  account_name=$(jq -r '.account.display_name // .account.full_name // .account.email // empty' "$PROFILE_FILE" 2>/dev/null)
  if [ -n "$account_name" ]; then
    account_part=" | ${DIM}${account_name}${RST}"
  fi
fi

printf "%s%s | %s%s%s%s" "$short_dir" "$git_part" "$model" "$ctx_part" "$usage_part" "$account_part"
