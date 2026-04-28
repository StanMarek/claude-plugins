#!/bin/bash
# Claude Code Multi-Line Statusline — UNIQUE COLOR PER FIELD edition
#
# Layout (3 lines, each field gets its own 256-color code):
#   LINE 1 [IDENTITY]  : vim_mode | model | output_style | version | agent | session | date | time
#   LINE 2 [WORKSPACE] : cwd | git_branch+status | ahead/behind | stash | last_commit | project_type
#   LINE 3 [RESOURCES] : context_bar | 5h_limit | 7d_limit | cost | lines_added | lines_removed | cpu | memory | battery
#
# Stdin: Claude Code statusline JSON payload.

set -uo pipefail

# ==============================================================================
# Color palette — each field gets a unique xterm-256 color
# ==============================================================================
readonly C_RESET=$'\033[0m'
readonly C_DIM=$'\033[2m'

# Identity line — soft warm pastels
readonly C_MODEL=$'\033[38;5;216m'           # peach
readonly C_STYLE=$'\033[38;5;218m'           # pale pink
readonly C_VERSION=$'\033[38;5;245m'         # muted gray
readonly C_AGENT=$'\033[38;5;183m'           # lavender
readonly C_SESSION=$'\033[38;5;152m'         # dusty blue
readonly C_DATE=$'\033[38;5;223m'            # cream
readonly C_TIME=$'\033[38;5;229m'            # pale yellow

# Workspace line — soft cool pastels
readonly C_CWD=$'\033[38;5;153m'             # baby blue
readonly C_GIT_CLEAN=$'\033[38;5;151m'       # sage green
readonly C_GIT_DIRTY=$'\033[38;5;222m'       # soft amber
readonly C_GIT_CONFLICT=$'\033[38;5;210m'    # dusty rose
readonly C_GIT_DETACHED=$'\033[38;5;217m'    # pale coral
readonly C_AHEAD_BEHIND=$'\033[38;5;159m'    # ice blue
readonly C_STASH=$'\033[38;5;224m'           # peach blossom
readonly C_COMMIT=$'\033[38;5;250m'          # warm gray
readonly C_PROJECT=$'\033[38;5;219m'         # soft mauve

# Resources line — gentle indicator pastels
readonly C_BAR_HIGH=$'\033[38;5;151m'        # sage green
readonly C_BAR_MID=$'\033[38;5;222m'         # soft amber
readonly C_BAR_LOW=$'\033[38;5;210m'         # dusty rose
readonly C_BAR_EMPTY=$'\033[38;5;238m'       # dim gray (track)
readonly C_5H=$'\033[38;5;186m'              # pale olive
readonly C_7D=$'\033[38;5;181m'              # rose taupe
readonly C_COST=$'\033[38;5;157m'            # mint
readonly C_LINES_ADDED=$'\033[38;5;150m'     # pale green
readonly C_LINES_REMOVED=$'\033[38;5;217m'   # pale coral
readonly C_CPU=$'\033[38;5;195m'             # pale cyan
readonly C_MEMORY=$'\033[38;5;189m'          # periwinkle
readonly C_BATT_HIGH=$'\033[38;5;151m'       # sage green
readonly C_BATT_MID=$'\033[38;5;223m'        # cream
readonly C_BATT_LOW=$'\033[38;5;210m'        # dusty rose

# Separator color
readonly C_SEP_DIM=$'\033[38;5;239m'         # quiet gray

# Vim pills — soft fills with dark-gray text
readonly BG_INSERT=$'\033[48;5;151m\033[38;5;235m\033[1m'
readonly BG_NORMAL=$'\033[48;5;216m\033[38;5;235m\033[1m'

# Field separator (vertical bar) and label glyphs — pad on both sides
readonly SEP=" ${C_SEP_DIM}▏${C_RESET} "

# ==============================================================================
# Input — parse the whole JSON in ONE jq call to avoid 20+ subprocess spawns
# ==============================================================================
INPUT_JSON=$(cat)

# Extract every field we care about in a single jq invocation.
# Output is bash assignments separated by newlines, evaluated below.
_JQ_OUT=$(printf '%s' "$INPUT_JSON" | jq -r '
  def n(p): (p // "" | tostring);
  [
    "MODEL=" + (n(.model.display_name) | @sh),
    "STYLE=" + (n(.output_style.name) | @sh),
    "VERSION=" + (n(.version) | @sh),
    "AGENT=" + (n(.agent.name) | @sh),
    "SESSION_NAME=" + (n(.session_name) | @sh),
    "WT_NAME=" + (n(.worktree.name) | @sh),
    "WT_BRANCH=" + (n(.worktree.branch) | @sh),
    "SESSION_ID=" + (n(.session_id) | @sh),
    "VIM_MODE=" + (n(.vim.mode) | @sh),
    "WSCWD=" + (n(.workspace.current_dir) | @sh),
    "CTX_USED_PCT=" + (n(.context_window.used_percentage) | @sh),
    "COST_USD=" + (n(.cost.total_cost_usd) | @sh),
    "LINES_ADDED=" + (n(.cost.total_lines_added) | @sh),
    "LINES_REMOVED=" + (n(.cost.total_lines_removed) | @sh),
    "FIVE_PCT=" + (n(.rate_limits.five_hour.used_percentage) | @sh),
    "FIVE_RESET=" + (n(.rate_limits.five_hour.resets_at) | @sh),
    "SEVEN_PCT=" + (n(.rate_limits.seven_day.used_percentage) | @sh),
    "SEVEN_RESET=" + (n(.rate_limits.seven_day.resets_at) | @sh)
  ] | join("\n")
' 2>/dev/null) || _JQ_OUT=""
eval "$_JQ_OUT"
CWD="${WSCWD:-$PWD}"

paint() {
  printf '%s%s%s' "$1" "$2" "$C_RESET"
}

# Append to a parts array safely
join_with_sep() {
  local out="" first=1 p
  for p in "$@"; do
    [[ -z "$p" ]] && continue
    if (( first )); then
      out="$p"; first=0
    else
      out="${out}${SEP}${p}"
    fi
  done
  printf '%s' "$out"
}

# Defaults for any field jq couldn't fill (in case of bad/missing JSON)
: "${MODEL:=}" "${STYLE:=}" "${VERSION:=}" "${AGENT:=}" "${SESSION_NAME:=}" "${WT_NAME:=}" "${WT_BRANCH:=}"
: "${SESSION_ID:=}" "${VIM_MODE:=}" "${CTX_USED_PCT:=}" "${COST_USD:=}" "${LINES_ADDED:=}" "${LINES_REMOVED:=}"
: "${FIVE_PCT:=}" "${FIVE_RESET:=}" "${SEVEN_PCT:=}" "${SEVEN_RESET:=}"

# ==============================================================================
# LINE 1 helpers
# ==============================================================================
fmt_vim_mode() {
  [[ -z "$VIM_MODE" ]] && return
  if [[ "$VIM_MODE" == "INSERT" ]]; then
    printf '%s INSERT %s' "$BG_INSERT" "$C_RESET"
  else
    printf '%s NORMAL %s' "$BG_NORMAL" "$C_RESET"
  fi
}

fmt_session() {
  local d=""
  if [[ -n "$SESSION_NAME" ]]; then
    d="$SESSION_NAME"
  elif [[ -n "$WT_NAME" ]]; then
    if [[ -n "$WT_BRANCH" ]]; then d="wt:${WT_NAME}(${WT_BRANCH})"; else d="wt:${WT_NAME}"; fi
  elif [[ -n "$SESSION_ID" ]]; then
    d="${SESSION_ID:0:8}"
  fi
  [[ -z "$d" ]] && return
  paint "$C_SESSION" "$d"
}

build_line1() {
  local parts=()
  local vm; vm=$(fmt_vim_mode); [[ -n "$vm" ]] && parts+=("$vm")
  [[ -n "$MODEL" ]]                            && parts+=("$(paint "$C_MODEL"   "$MODEL")")
  [[ -n "$STYLE" && "$STYLE" != "default" ]]   && parts+=("$(paint "$C_STYLE"   "$STYLE")")
  [[ -n "$VERSION" ]]                          && parts+=("$(paint "$C_VERSION" "v$VERSION")")
  [[ -n "$AGENT" ]]                            && parts+=("$(paint "$C_AGENT"   "λ $AGENT")")
  local sess; sess=$(fmt_session); [[ -n "$sess" ]] && parts+=("$sess")
  parts+=("$(paint "$C_DATE" "$(date '+%a %b %d')")")
  parts+=("$(paint "$C_TIME" "$(date '+%H:%M:%S')")")
  join_with_sep "${parts[@]}"
}

# ==============================================================================
# LINE 2 helpers
# ==============================================================================
fmt_cwd() {
  local full="$CWD" git_root display
  git_root=$(git -C "$full" rev-parse --show-toplevel 2>/dev/null) || git_root=""

  if [[ -n "$git_root" ]]; then
    local repo rel
    repo=$(basename "$git_root")
    rel="${full#"$git_root"}"
    rel="${rel#/}"
    if [[ -n "$rel" ]]; then display="${repo}/${rel}"; else display="${repo}"; fi
  else
    local norm
    norm=$(printf '%s' "$full" | sed "s|^${HOME}|~|")
    display=$(basename "$norm")
    local parent
    parent=$(basename "$(dirname "$norm")")
    if [[ "$parent" != "~" && "$parent" != "/" && "$parent" != "." ]]; then
      display="${parent}/${display}"
    elif [[ "$parent" == "~" ]]; then
      display="~/${display}"
    fi
  fi
  paint "$C_CWD" "$display"
}

fmt_git() {
  local cwd="$CWD"
  git -C "$cwd" -c core.fileMode=false rev-parse --git-dir >/dev/null 2>&1 || return 0

  local branch color="$C_GIT_CLEAN" label
  branch=$(git -C "$cwd" -c core.fileMode=false branch --show-current 2>/dev/null)
  if [[ -n "$branch" ]]; then
    label="$branch"
  else
    label="detached"; color="$C_GIT_DETACHED"
  fi

  local indicators=""
  # dirty
  if ! git -C "$cwd" -c core.fileMode=false diff --quiet 2>/dev/null \
     || ! git -C "$cwd" -c core.fileMode=false diff --cached --quiet 2>/dev/null; then
    indicators+="*"
    [[ "$color" == "$C_GIT_CLEAN" ]] && color="$C_GIT_DIRTY"
  fi
  # untracked
  if [[ -n "$(git -C "$cwd" ls-files --others --exclude-standard 2>/dev/null | head -1)" ]]; then
    indicators+="?"
    [[ "$color" == "$C_GIT_CLEAN" ]] && color="$C_GIT_DIRTY"
  fi
  # conflict
  if git -C "$cwd" -c core.fileMode=false diff --name-only --diff-filter=U 2>/dev/null | grep -q .; then
    indicators+="!"
    color="$C_GIT_CONFLICT"
  fi

  [[ -n "$indicators" ]] && label="${label} ${indicators}"
  paint "$color" "⎇ $label"
}

fmt_ahead_behind() {
  local cwd="$CWD" ab behind ahead
  ab=$(git -C "$cwd" rev-list --left-right --count "@{upstream}...HEAD" 2>/dev/null) || return
  [[ -z "$ab" ]] && return
  behind=$(printf '%s' "$ab" | awk '{print $1}')
  ahead=$(printf '%s'  "$ab" | awk '{print $2}')
  [[ "$ahead" == "0" && "$behind" == "0" ]] && return
  local out=""
  [[ "$ahead"  != "0" ]] && out+="⇡${ahead}"
  [[ "$behind" != "0" ]] && out+="⇣${behind}"
  paint "$C_AHEAD_BEHIND" "$out"
}

fmt_stash() {
  local cwd="$CWD" n
  n=$(git -C "$cwd" stash list 2>/dev/null | wc -l | tr -d ' ')
  [[ -z "$n" || "$n" == "0" ]] && return
  paint "$C_STASH" "stash:$n"
}

fmt_last_commit() {
  local cwd="$CWD" sha msg
  git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1 || return
  sha=$(git -C "$cwd" log -1 --pretty=format:'%h' 2>/dev/null) || return
  [[ -z "$sha" ]] && return
  msg=$(git -C "$cwd" log -1 --pretty=format:'%s' 2>/dev/null)
  # Trim message to 40 chars
  if [[ ${#msg} -gt 40 ]]; then msg="${msg:0:37}…"; fi
  paint "$C_COMMIT" "$sha $msg"
}

fmt_project_type() {
  local d="$CWD" git_root
  git_root=$(git -C "$d" rev-parse --show-toplevel 2>/dev/null) || true
  local checks=("$d")
  [[ -n "$git_root" && "$git_root" != "$d" ]] && checks+=("$git_root")
  local c label=""
  for c in "${checks[@]}"; do
    if   [[ -f "$c/Cargo.toml" ]];        then label="rust";   break
    elif [[ -f "$c/package.json" ]];      then label="node";   break
    elif [[ -f "$c/go.mod" ]];            then label="go";     break
    elif [[ -f "$c/pyproject.toml" || -f "$c/requirements.txt" || -f "$c/setup.py" ]]; then label="python"; break
    elif [[ -f "$c/Gemfile" ]];           then label="ruby";   break
    elif [[ -f "$c/pom.xml" ]];           then label="maven";  break
    elif [[ -f "$c/build.gradle" || -f "$c/build.gradle.kts" ]]; then label="gradle"; break
    elif [[ -f "$c/mix.exs" ]];           then label="elixir"; break
    elif [[ -f "$c/Makefile" ]];          then label="make";   break
    fi
  done
  [[ -z "$label" ]] && return
  paint "$C_PROJECT" "$label"
}

build_line2() {
  local parts=()
  parts+=("$(fmt_cwd)")
  local g; g=$(fmt_git);          [[ -n "$g" ]] && parts+=("$g")
  local ab; ab=$(fmt_ahead_behind);[[ -n "$ab" ]] && parts+=("$ab")
  local s; s=$(fmt_stash);        [[ -n "$s" ]] && parts+=("$s")
  local lc; lc=$(fmt_last_commit);[[ -n "$lc" ]] && parts+=("$lc")
  local pt; pt=$(fmt_project_type); [[ -n "$pt" ]] && parts+=("$pt")
  join_with_sep "${parts[@]}"
}

# ==============================================================================
# LINE 3 helpers
# ==============================================================================
fmt_context_bar() {
  [[ -z "$CTX_USED_PCT" ]] && return
  local pct="$CTX_USED_PCT"
  [[ "$pct" =~ ^[0-9]+(\.[0-9]+)?$ ]] || pct=0
  local int_used=${pct%%.*}
  local int_rem=$(( 100 - int_used ))
  (( int_rem < 0 )) && int_rem=0

  local bar_color="$C_BAR_HIGH"
  if   (( int_rem < 20 )); then bar_color="$C_BAR_LOW"
  elif (( int_rem < 50 )); then bar_color="$C_BAR_MID"
  fi

  local width=12
  local filled=$(( int_rem * width / 100 ))
  local empty=$(( width - filled ))
  local f="" e="" i
  for (( i = 0; i < filled; i++ )); do f+="█"; done
  for (( i = 0; i < empty;  i++ )); do e+="░"; done

  printf 'ctx %s%s%s%s%s %s%%%s' \
    "$bar_color" "$f" "$C_BAR_EMPTY" "$e" \
    "$bar_color" "$int_rem" "$C_RESET"
}

_fmt_epoch_reset() {
  local epoch="$1" include_date="${2:-}"
  [[ -z "$epoch" || "$epoch" == "null" ]] && return
  local fmt
  if [[ "$(defaults read -g AppleICUForce24HourTime 2>/dev/null)" == "1" ]]; then
    fmt="%H:%M"; [[ -n "$include_date" ]] && fmt="%b %d %H:%M"
  else
    fmt="%I:%M%p"; [[ -n "$include_date" ]] && fmt="%b %d %I:%M%p"
  fi
  date -r "$epoch" "+${fmt}" 2>/dev/null || true
}

fmt_5h_limit() {
  [[ -z "$FIVE_PCT" || ! "$FIVE_PCT" =~ ^[0-9]+(\.[0-9]+)?$ ]] && return
  local i=${FIVE_PCT%%.*} reset=""
  [[ -n "$FIVE_RESET" ]] && reset=" → $(_fmt_epoch_reset "$FIVE_RESET")"
  paint "$C_5H" "5h:${i}%${reset}"
}

fmt_7d_limit() {
  [[ -z "$SEVEN_PCT" || ! "$SEVEN_PCT" =~ ^[0-9]+(\.[0-9]+)?$ ]] && return
  local i=${SEVEN_PCT%%.*} reset=""
  [[ -n "$SEVEN_RESET" ]] && reset=" → $(_fmt_epoch_reset "$SEVEN_RESET" "date")"
  paint "$C_7D" "7d:${i}%${reset}"
}

fmt_cost() {
  [[ -z "$COST_USD" ]] && return
  [[ "$COST_USD" =~ ^[0-9]+(\.[0-9]+)?$ ]] || return
  local formatted
  formatted=$(printf '%.2f' "$COST_USD" 2>/dev/null) || formatted="$COST_USD"
  paint "$C_COST" "\$$formatted"
}

fmt_lines_diff() {
  local out=""
  if [[ -n "$LINES_ADDED" && "$LINES_ADDED" =~ ^[0-9]+$ && "$LINES_ADDED" -gt 0 ]]; then
    out="$(paint "$C_LINES_ADDED" "+${LINES_ADDED}")"
  fi
  if [[ -n "$LINES_REMOVED" && "$LINES_REMOVED" =~ ^[0-9]+$ && "$LINES_REMOVED" -gt 0 ]]; then
    [[ -n "$out" ]] && out+=" "
    out+="$(paint "$C_LINES_REMOVED" "-${LINES_REMOVED}")"
  fi
  printf '%s' "$out"
}

fmt_cpu() {
  local load
  load=$(uptime 2>/dev/null | awk -F'load average[s]?: ' '{print $2}' | awk -F'[, ]' '{print $1}' | tr -d ' ')
  [[ -z "$load" ]] && return
  paint "$C_CPU" "load:${load}"
}

fmt_memory() {
  local pct
  pct=$(vm_stat 2>/dev/null | awk '
    /Pages free/                      { f=$3 }
    /Pages active/                    { a=$3 }
    /Pages inactive/                  { i=$3 }
    /Pages speculative/               { s=$3 }
    /Pages wired down/                { w=$4 }
    /Pages occupied by compressor/    { c=$5 }
    END {
      gsub(/\./,"",f); gsub(/\./,"",a); gsub(/\./,"",i); gsub(/\./,"",s); gsub(/\./,"",w); gsub(/\./,"",c)
      used  = a + w + c
      total = a + i + s + w + f + c
      if (total > 0) printf "%.0f", used/total*100
    }') || pct=""
  [[ -z "$pct" ]] && return
  paint "$C_MEMORY" "mem:${pct}%"
}

fmt_battery() {
  local out pct color label
  out=$(pmset -g batt 2>/dev/null) || return
  pct=$(printf '%s' "$out" | grep -Eo '[0-9]+%' | head -1 | tr -d '%')
  [[ -z "$pct" ]] && return

  if   printf '%s' "$out" | grep -q "AC Power";    then label="ac"
  elif printf '%s' "$out" | grep -q "discharging"; then label="batt"
  elif printf '%s' "$out" | grep -q "charging";    then label="chg"
  elif printf '%s' "$out" | grep -q "charged";     then label="full"
  else                                                  label="batt"
  fi

  if   (( pct >= 60 )); then color="$C_BATT_HIGH"
  elif (( pct >= 25 )); then color="$C_BATT_MID"
  else                       color="$C_BATT_LOW"
  fi
  paint "$color" "${label}:${pct}%"
}

build_line3() {
  local parts=()
  local cb; cb=$(fmt_context_bar);  [[ -n "$cb" ]] && parts+=("$cb")
  local f5; f5=$(fmt_5h_limit);     [[ -n "$f5" ]] && parts+=("$f5")
  local s7; s7=$(fmt_7d_limit);     [[ -n "$s7" ]] && parts+=("$s7")
  local co; co=$(fmt_cost);         [[ -n "$co" ]] && parts+=("$co")
  local ld; ld=$(fmt_lines_diff);   [[ -n "$ld" ]] && parts+=("$ld")
  local cp; cp=$(fmt_cpu);          [[ -n "$cp" ]] && parts+=("$cp")
  local mm; mm=$(fmt_memory);       [[ -n "$mm" ]] && parts+=("$mm")
  local bt; bt=$(fmt_battery);      [[ -n "$bt" ]] && parts+=("$bt")
  join_with_sep "${parts[@]}"
}

# ==============================================================================
# Main
# ==============================================================================
LINE1=$(build_line1)
LINE2=$(build_line2)
LINE3=$(build_line3)

# Print non-empty lines, separated by newline
first=1
for L in "$LINE1" "$LINE2" "$LINE3"; do
  [[ -z "$L" ]] && continue
  if (( first )); then
    printf '%s' "$L"; first=0
  else
    printf '\n%s' "$L"
  fi
done
printf '\n'
