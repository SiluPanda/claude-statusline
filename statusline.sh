#!/bin/bash
# Statusline — single jq call, direct git ops with -C for correct directory

input=$(cat)

# Single jq invocation extracts ALL fields at once
eval "$(echo "$input" | jq -r '
  @sh "MODEL=\(.model.display_name)",
  @sh "DIR=\(.workspace.current_dir // .cwd)",
  @sh "COST=\(.cost.total_cost_usd // 0)",
  @sh "DURATION_MS=\(.cost.total_duration_ms // 0)",
  @sh "API_DURATION_MS=\(.cost.total_api_duration_ms // 0)",
  @sh "LINES_ADDED=\(.cost.total_lines_added // 0)",
  @sh "LINES_REMOVED=\(.cost.total_lines_removed // 0)",
  @sh "PCT=\(.context_window.used_percentage // 0)",
  @sh "CTX_SIZE=\(.context_window.context_window_size // 200000)",
  @sh "EXCEEDS_200K=\(.exceeds_200k_tokens // false)",
  @sh "VIM_MODE=\(.vim.mode // "")",
  @sh "AGENT_NAME=\(.agent.name // "")",
  @sh "WORKTREE_NAME=\(.worktree.name // "")",
  @sh "WORKTREE_BRANCH=\(.worktree.branch // "")"
' | tr '\n' ';')"

PCT=${PCT%%.*}

# --- Colors ---
BOLD='\033[1m'; DIM='\033[2m'
CYAN='\033[36m'; GREEN='\033[32m'; YELLOW='\033[33m'; RED='\033[31m'
MAGENTA='\033[35m'; BLUE='\033[34m'; WHITE='\033[37m'; RESET='\033[0m'

# --- Git info (always targets workspace directory) ---
GIT_BRANCH="" GIT_STAGED=0 GIT_MODIFIED=0 GIT_REMOTE=""
if git -C "$DIR" rev-parse --git-dir > /dev/null 2>&1; then
  GIT_BRANCH=$(git -C "$DIR" branch --show-current 2>/dev/null)
  GIT_STAGED=$(git -C "$DIR" diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
  GIT_MODIFIED=$(git -C "$DIR" diff --numstat 2>/dev/null | wc -l | tr -d ' ')
  GIT_REMOTE=$(git -C "$DIR" remote get-url origin 2>/dev/null | sed 's/git@github\.com:/https:\/\/github.com\//' | sed 's/\.git$//')
fi

# --- Context bar (color-coded) ---
if [ "$PCT" -ge 90 ]; then BAR_COLOR="$RED"
elif [ "$PCT" -ge 70 ]; then BAR_COLOR="$YELLOW"
else BAR_COLOR="$GREEN"; fi

BAR_WIDTH=15
FILLED=$((PCT * BAR_WIDTH / 100))
EMPTY=$((BAR_WIDTH - FILLED))
BAR=""
[ "$FILLED" -gt 0 ] && BAR=$(printf "%${FILLED}s" | tr ' ' '█')
[ "$EMPTY" -gt 0 ] && BAR="${BAR}$(printf "%${EMPTY}s" | tr ' ' '░')"

# --- Durations ---
MINS=$((DURATION_MS / 60000)); SECS=$(((DURATION_MS % 60000) / 1000))
API_MINS=$((API_DURATION_MS / 60000)); API_SECS=$(((API_DURATION_MS % 60000) / 1000))

# --- Context size label ---
if [ "$CTX_SIZE" -ge 1000000 ]; then CTX_LABEL="1M"; else CTX_LABEL="200K"; fi

# === LINE 1: Model, directory, git, agent/worktree ===
L1="${CYAN}${BOLD}[${MODEL}]${RESET} ${DIM}(${CTX_LABEL})${RESET}"
L1="${L1} ${WHITE}📁 ${DIR##*/}${RESET}"

if [ -n "$GIT_BRANCH" ]; then
  GIT_INFO=" ${DIM}|${RESET} 🌿 ${GREEN}${GIT_BRANCH}${RESET}"
  [ "$GIT_STAGED" -gt 0 ] 2>/dev/null && GIT_INFO="${GIT_INFO} ${GREEN}+${GIT_STAGED}${RESET}"
  [ "$GIT_MODIFIED" -gt 0 ] 2>/dev/null && GIT_INFO="${GIT_INFO} ${YELLOW}~${GIT_MODIFIED}${RESET}"
  L1="${L1}${GIT_INFO}"
fi

if [ -n "$WORKTREE_NAME" ]; then
  WT_LABEL="${WORKTREE_NAME}"
  [ -n "$WORKTREE_BRANCH" ] && WT_LABEL="${WORKTREE_BRANCH}"
  L1="${L1} ${DIM}|${RESET} ${MAGENTA}🌲 ${WT_LABEL}${RESET}"
fi

if [ -n "$AGENT_NAME" ]; then
  L1="${L1} ${DIM}|${RESET} ${BLUE}🤖 ${AGENT_NAME}${RESET}"
fi

if [ -n "$VIM_MODE" ]; then
  if [ "$VIM_MODE" = "NORMAL" ]; then
    L1="${L1} ${DIM}|${RESET} ${CYAN}[N]${RESET}"
  else
    L1="${L1} ${DIM}|${RESET} ${GREEN}[I]${RESET}"
  fi
fi

if [ -n "$GIT_REMOTE" ]; then
  REPO_NAME=$(basename "$GIT_REMOTE")
  L1="${L1} ${DIM}|${RESET} $(printf '%b' "\033]8;;${GIT_REMOTE}\a🔗 ${REPO_NAME}\033]8;;\a")"
fi

printf '%b\n' "$L1"

# === LINE 2: Context bar, cost, duration, lines changed ===
COST_FMT=$(printf '$%.2f' "$COST")

LINES_INFO=""
if [ "$LINES_ADDED" -gt 0 ] || [ "$LINES_REMOVED" -gt 0 ]; then
  LINES_INFO=" ${DIM}|${RESET} ${GREEN}+${LINES_ADDED}${RESET}${RED}-${LINES_REMOVED}${RESET}"
fi

WARN=""
if [ "$EXCEEDS_200K" = "true" ]; then
  WARN=" ${RED}${BOLD}⚠ >200K${RESET}"
fi

L2="${BAR_COLOR}${BAR}${RESET} ${PCT}%${WARN}"
L2="${L2} ${DIM}|${RESET} ${YELLOW}${COST_FMT}${RESET}"
L2="${L2} ${DIM}|${RESET} ⏱️  ${MINS}m${SECS}s ${DIM}(api ${API_MINS}m${API_SECS}s)${RESET}"
L2="${L2}${LINES_INFO}"

printf '%b\n' "$L2"
