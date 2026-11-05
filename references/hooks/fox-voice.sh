#!/usr/bin/env bash
# Mr Fox — voice flags + cross-session inbox.
#
#   fox-voice.sh say "<message>" [level]   flag a message (logs to inbox; speaks if voice is on)
#   fox-voice.sh hook                      Notification hook: reads hook JSON on stdin
#   fox-voice.sh session                   SessionStart hook: records this dir's session id
#   fox-voice.sh list [--all|--here]       show unread flags (all sessions, or this dir only)
#   fox-voice.sh mark <id>|--here|--all    mark flags as seen
#   fox-voice.sh on | off | status | test  toggle the system voice (global, all sessions)
#
# Inbox: ~/.claude/fox-inbox.tsv (shared by every session on this machine)
#   id  time  state(new|seen)  level  project_dir  branch  session_id  message
# Voice is OFF by default. Flags are always logged, so the inbox works without audio
# (e.g. cloud sessions). Speech uses the OS default voice: macOS `say`,
# Linux `spd-say`/`espeak-ng`/`espeak`, Windows/WSL PowerShell System.Speech.

set -u
FOX_HOME="${FOX_HOME:-$HOME/.claude}"
INBOX="$FOX_HOME/fox-inbox.tsv"
VOICE_FLAG="$FOX_HOME/fox-voice.on"
LOCK="$FOX_HOME/.fox-inbox.lock"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
mkdir -p "$FOX_HOME"; touch "$INBOX"

clean() { printf '%s' "$1" | tr '\t\r\n' '   ' | cut -c1-300; }

lock()   { local i=0; until mkdir "$LOCK" 2>/dev/null; do i=$((i+1)); [ $i -gt 50 ] && break; sleep 0.1; done; }
unlock() { rmdir "$LOCK" 2>/dev/null || true; }

speak() {
  [ -f "$VOICE_FLAG" ] || return 0
  local text="$1"
  (
    if command -v say >/dev/null 2>&1; then printf '%s' "$text" | say -f -
    elif command -v spd-say >/dev/null 2>&1; then printf '%s' "$text" | spd-say -e
    elif command -v espeak-ng >/dev/null 2>&1; then printf '%s' "$text" | espeak-ng --stdin
    elif command -v espeak >/dev/null 2>&1; then printf '%s' "$text" | espeak --stdin
    elif command -v powershell.exe >/dev/null 2>&1; then
      printf '%s' "$text" | powershell.exe -NoProfile -Command \
        'Add-Type -AssemblyName System.Speech; (New-Object System.Speech.Synthesis.SpeechSynthesizer).Speak([Console]::In.ReadToEnd())'
    fi
  ) >/dev/null 2>&1 &
  disown 2>/dev/null || true
}

json_get() { # $1 = json, $2 = key
  if command -v jq >/dev/null 2>&1; then printf '%s' "$1" | jq -r --arg k "$2" '.[$k] // empty'
  else printf '%s' "$1" | python3 -c 'import sys,json; print(json.load(sys.stdin).get(sys.argv[1],"") or "")' "$2" 2>/dev/null; fi
}

flag() { # $1 message, $2 level, $3 session id, $4 project dir
  local msg level sid dir branch id name
  msg=$(clean "$1"); level=$(clean "${2:-info}"); sid=$(clean "${3:-}"); dir="${4:-$PROJECT_DIR}"
  [ -z "$sid" ] && [ -f "$dir/.claude/.fox-session" ] && sid=$(cat "$dir/.claude/.fox-session")
  branch=$(git -C "$dir" symbolic-ref --short -q HEAD 2>/dev/null); branch=$(clean "${branch:--}"); dir=$(clean "$dir")
  id=$(printf '%04x%04x' "$RANDOM" "$RANDOM")
  lock
  printf '%s\t%s\tnew\t%s\t%s\t%s\t%s\t%s\n' "$id" "$(date '+%Y-%m-%d %H:%M')" "$level" "$dir" "$branch" "${sid:--}" "$msg" >> "$INBOX"
  unlock
  name=$(basename "$dir")
  speak "Mr Fox. $name. $msg"
  echo "flagged $id"
}

list() {
  local mode="${1:-}"
  awk -F'\t' -v mode="$mode" -v here="$PROJECT_DIR" '
    (mode=="--all" || $3=="new") && (mode!="--here" || $5==here) {
      n++; printf "%s  %s  [%s] %-6s %s @ %s  session:%s\n      %s\n", $1, $2, $3, $4, $5, $6, $7, $8 }
    END { if (!n) print "Inbox clear." }' "$INBOX"
}

mark() {
  local target="${1:-}"
  [ -z "$target" ] && { echo "usage: mark <id>|--here|--all" >&2; exit 1; }
  lock
  awk -F'\t' -v OFS='\t' -v t="$target" -v here="$PROJECT_DIR" '
    $3=="new" && (t=="--all" || (t=="--here" && $5==here) || $1==t) { $3="seen"; c++ }
    { print } END { print c+0 > "/dev/stderr" }' "$INBOX" > "$INBOX.tmp" 2> "$INBOX.count" && mv "$INBOX.tmp" "$INBOX"
  unlock
  echo "marked $(cat "$INBOX.count") as seen"; rm -f "$INBOX.count"
}

case "${1:-status}" in
  say)     shift; flag "${1:-}" "${2:-info}" "" "$PROJECT_DIR" ;;
  hook)    in=$(cat)
           flag "$(json_get "$in" message)" "input" "$(json_get "$in" session_id)" "$(json_get "$in" cwd)" >/dev/null ;;
  session) in=$(cat); sid=$(json_get "$in" session_id)
           [ -n "$sid" ] && mkdir -p "$PROJECT_DIR/.claude" && printf '%s' "$sid" > "$PROJECT_DIR/.claude/.fox-session"
           n=$(awk -F'\t' '$3=="new"{c++} END{print c+0}' "$INBOX")
           [ "$n" -gt 0 ] && echo "Mr Fox inbox: $n unread flag(s) across sessions — run /mr-fox-inbox"
           exit 0 ;;
  list)    list "${2:-}" ;;
  mark)    mark "${2:-}" ;;
  on)      touch "$VOICE_FLAG"; echo "Voice: on" ;;
  off)     rm -f "$VOICE_FLAG"; echo "Voice: off" ;;
  test)    [ -f "$VOICE_FLAG" ] || echo "Voice is off — run: fox-voice.sh on"; speak "Mr Fox voice check." ;;
  status)  [ -f "$VOICE_FLAG" ] && echo "Voice: on" || echo "Voice: off"
           echo "Unread: $(awk -F'\t' '$3=="new"{c++} END{print c+0}' "$INBOX")" ;;
  *)       sed -n '2,10p' "$0"; exit 1 ;;
esac
