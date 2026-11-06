#!/usr/bin/env bash
# Mr Fox — context guard (global UserPromptSubmit hook, installed by fox-optimize.sh).
# When a session's transcript gets big or old, it adds one line of context so Claude
# suggests /clear (new task) or /compact (same task) before carrying on.
# Warns once per size step and once for age, per session. Never blocks a prompt.
set -u
KB="${FOX_GUARD_KB:-800}"        # warn each time the transcript grows by this much (~100k tokens)
HOURS="${FOX_GUARD_HOURS:-8}"    # warn once when a session is older than this
STATE="${FOX_HOME:-$HOME/.claude}/.fox-guard"; mkdir -p "$STATE"
input=$(cat)
get() { if command -v jq >/dev/null 2>&1; then printf '%s' "$input" | jq -r --arg k "$1" '.[$k] // empty'
        else printf '%s' "$input" | python3 -c 'import sys,json;print(json.load(sys.stdin).get(sys.argv[1],"") or "")' "$1"; fi; }
sid=$(get session_id); tp=$(get transcript_path)
[ -n "$sid" ] && [ -f "$tp" ] || exit 0
f="$STATE/$sid"; now=$(date +%s)
[ -f "$f" ] || printf '%s 0 0\n' "$now" > "$f"
read -r first step aged < "$f"
size=$(( $(wc -c < "$tp") / 1024 )); cur=$(( size / KB )); age=$(( (now - first) / 3600 ))
msg=""
if [ "$cur" -gt "$step" ]; then
  step=$cur; if [ "$size" -ge 1024 ]; then hs="$((size/1024)) MB"; else hs="$size KB"; fi
  msg="transcript is ~$hs"
fi
# age: once at FOX_GUARD_HOURS, again at 7 days (long-lived orchestrators: refresh weekly)
if [ "$age" -ge 168 ] && [ "$aged" -lt 2 ]; then aged=2; msg="${msg:+$msg and }session is over a week old — time for /mr-fox-refresh (or /clear with a handoff)"
elif [ "$age" -ge "$HOURS" ] && [ "$aged" -lt 1 ]; then aged=1; msg="${msg:+$msg and }session has run ${age}h+"; fi
printf '%s %s %s\n' "$first" "$step" "$aged" > "$f"
find "$STATE" -type f -mtime +14 -delete 2>/dev/null
[ -n "$msg" ] && echo "[Mr Fox context guard] This $msg. If this prompt starts a different task, first tell the user in one line to run /clear (state survives via Mr Fox auto-sync / session-log). If it continues the same task, suggest /compact at a natural break. Then carry on."
exit 0
