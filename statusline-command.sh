#!/usr/bin/env bash
# Claude Code status line
# robbyrussell-style prompt with plan usage, context, cost, CPU, and model

input=$(cat)

# --- Plan usage via Anthropic OAuth API ---
# Endpoint: https://api.anthropic.com/api/oauth/usage
# Cache: ~/.cache/claude-dashboard/usage.json (60s TTL)
USAGE_CACHE_DIR="${HOME}/.cache/claude-dashboard"
USAGE_CACHE_FILE="${USAGE_CACHE_DIR}/usage.json"
USAGE_CACHE_TTL=60

_get_oauth_token() {
  # Try credentials file first (used by isolated HOME instances like claude-personal)
  local creds_file="${HOME}/.claude/.credentials.json"
  if [ -f "$creds_file" ]; then
    local tok
    tok=$(jq -r '.claudeAiOauth.accessToken // empty' "$creds_file" 2>/dev/null)
    [ -n "$tok" ] && echo "$tok" && return
  fi
  # Fallback: macOS keychain (used by default claude instance)
  local raw
  raw=$(security find-generic-password -s 'Claude Code-credentials' -w 2>/dev/null) || return 1
  echo "$raw" | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null
}

_fetch_usage() {
  local token="$1"
  curl -sf --max-time 5 \
    -H "Authorization: Bearer ${token}" \
    -H "Accept: application/json" \
    -H "anthropic-beta: oauth-2025-04-20" \
    'https://api.anthropic.com/api/oauth/usage' 2>/dev/null
}

limits_out=""
_usage_json=""

# Check cache freshness
if [ -f "$USAGE_CACHE_FILE" ]; then
  _cache_age=$(( $(date +%s) - $(stat -f %m "$USAGE_CACHE_FILE" 2>/dev/null || echo 0) ))
  if [ "$_cache_age" -lt "$USAGE_CACHE_TTL" ]; then
    _usage_json=$(cat "$USAGE_CACHE_FILE" 2>/dev/null)
  fi
fi

# Cache miss — fetch from API
if [ -z "$_usage_json" ]; then
  _token=$(_get_oauth_token)
  if [ -n "$_token" ]; then
    _usage_json=$(_fetch_usage "$_token")
    if [ -n "$_usage_json" ]; then
      mkdir -p "$USAGE_CACHE_DIR"
      echo "$_usage_json" > "$USAGE_CACHE_FILE"
    fi
  fi
fi

# Render plan usage bars
if [ -n "$_usage_json" ]; then
  _render_plan_bar() {
    local label="$1" pct="$2"
    [ "$pct" -gt 100 ] && pct=100
    local label_len fill_chars filled_text empty_text
    local slabel=" ${pct}% "
    label_len=${#slabel}
    fill_chars=$(( (label_len * pct) / 100 ))
    filled_text="${slabel:0:$fill_chars}"
    empty_text="${slabel:$fill_chars}"
    local fc ec bg
    if [ "$pct" -le 50 ]; then fc="\033[32m"; bg="\033[42m"; ec="\033[32m"
    elif [ "$pct" -le 80 ]; then fc="\033[33m"; bg="\033[43m"; ec="\033[33m"
    else fc="\033[31m"; bg="\033[41m"; ec="\033[31m"; fi
    printf '%b' " ${fc}${label}:${bg}\033[30m${filled_text}\033[48;2;0;45;0m\033[97m${empty_text}\033[0m"
  }

  _5h_util=$(echo "$_usage_json" | jq -r '.five_hour.utilization // empty')
  _7d_util=$(echo "$_usage_json" | jq -r '.seven_day.utilization // empty')

  if [ -n "$_5h_util" ]; then
    _5h_pct=$(printf "%.0f" "$_5h_util")
    limits_out="${limits_out}$(_render_plan_bar "5h" "$_5h_pct")"
  fi
  if [ -n "$_7d_util" ]; then
    _7d_pct=$(printf "%.0f" "$_7d_util")
    limits_out="${limits_out}$(_render_plan_bar "7d" "$_7d_pct")"
  fi
fi

# --- robbyrussell-style prompt prefix ---
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
[ -z "$cwd" ] && cwd="$(pwd)"
dir=$(basename "$cwd")
prompt_prefix="\033[1;32m➜\033[0m  \033[36m${dir}\033[0m"
# git branch + dirty state
git_part=""
if git_branch=$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null); then
  if git -C "$cwd" --no-optional-locks status --porcelain 2>/dev/null | grep -q .; then
    git_part=" \033[1;34mgit:(\033[31m${git_branch}\033[1;34m)\033[0m \033[33m✗\033[0m"
  else
    git_part=" \033[1;34mgit:(\033[31m${git_branch}\033[1;34m)\033[0m"
  fi
fi
shell_prompt="${prompt_prefix}${git_part}"

# --- Token formatter (used by ctx bar) ---
fmtk() {
  local n=$1
  if [ "$n" -ge 1000000 ]; then printf "%.1fM" "$(echo "scale=1; $n/1000000" | bc)"
  elif [ "$n" -ge 1000 ]; then printf "%.1fk" "$(echo "scale=1; $n/1000" | bc)"
  else printf "%d" "$n"; fi
}

# --- Context usage (green background fill behind token text) ---
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
ctx=""
if [ -n "$used_pct" ]; then
  p=$(printf "%.0f" "$used_pct")
  if [ "$p" -le 50 ]; then fg="\033[32m"
  elif [ "$p" -le 80 ]; then fg="\033[33m"
  else fg="\033[31m"; fi
  _tin=$(echo "$input" | jq -r '.context_window.total_input_tokens // empty')
  _tout=$(echo "$input" | jq -r '.context_window.total_output_tokens // empty')
  if [ -n "$_tin" ] && [ -n "$_tout" ]; then
    label=" $(fmtk "$_tin")in/$(fmtk "$_tout")out "
  else
    label=" ctx "
  fi
  label_len=${#label}
  fill_chars=$(( (label_len * p) / 100 ))
  filled_text="${label:0:$fill_chars}"
  empty_text="${label:$fill_chars}"
  ctx=" ${fg}ctx:\033[42m\033[30m${filled_text}\033[48;2;0;45;0m\033[97m${empty_text}\033[0m ${fg}${p}%\033[0m"
fi

# --- Cost ---
cost=""
cost_usd=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
if [ -n "$cost_usd" ] && [ "$cost_usd" != "0" ]; then
  cost_fmt=$(printf "%.3f" "$cost_usd")
  cost=" \033[33mcost:\$${cost_fmt}\033[0m"
fi

# --- Agent ---
agent=""
agent_name=$(echo "$input" | jq -r '.agent.name // empty')
if [ -n "$agent_name" ]; then
  agent=" \033[36m⚡${agent_name}\033[0m"
fi

# --- CPU (load average, instant unlike top) ---
cpu=""
if load=$(sysctl -n vm.loadavg 2>/dev/null); then
  # macOS
  load1=$(echo "$load" | awk '{gsub(/[{}]/,""); print $1}')
  ncpu=$(sysctl -n hw.ncpu 2>/dev/null || echo 1)
  pct=$(awk "BEGIN {printf \"%.0f\", ($load1/$ncpu)*100}")
  if [ "$pct" -le 50 ]; then cc="\033[36m"
  elif [ "$pct" -le 80 ]; then cc="\033[33m"
  else cc="\033[31m"; fi
  cpu=" ${cc}cpu:${pct}%\033[0m"
elif [ -f /proc/loadavg ]; then
  # Linux
  load1=$(awk '{print $1}' /proc/loadavg)
  ncpu=$(nproc 2>/dev/null || echo 1)
  pct=$(awk "BEGIN {printf \"%.0f\", ($load1/$ncpu)*100}")
  if [ "$pct" -le 50 ]; then cc="\033[36m"
  elif [ "$pct" -le 80 ]; then cc="\033[33m"
  else cc="\033[31m"; fi
  cpu=" ${cc}cpu:${pct}%\033[0m"
fi

# --- Model ---
model=""
model_name=$(echo "$input" | jq -r '.model.display_name // empty')
if [ -n "$model_name" ]; then
  model=" \033[90m${model_name}\033[0m"
fi

SEP="\033[90m |\033[0m"
_join() {
  local out=""
  for part in "$@"; do
    [ -n "$part" ] && out="${out:+${out}${SEP}}${part}"
  done
  printf '%b' "$out"
}
printf '%b' "${shell_prompt}$(_join "${ctx}" "${limits_out}" "${cost}" "${agent}" "${cpu}" "${model}")"
