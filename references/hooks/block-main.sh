#!/usr/bin/env bash
# Mr Fox — PreToolUse hook (matcher: Bash).
# Blocks git commit/push/merge/rebase/reset/cherry-pick/am while on main/master,
# and any push whose refspec targets main/master.
# Exit 2 = block; stderr is shown to Claude. Enforced by the harness, not by prompt.
input=$(cat)

if command -v jq >/dev/null 2>&1; then
  cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
elif command -v python3 >/dev/null 2>&1; then
  cmd=$(printf '%s' "$input" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("tool_input",{}).get("command",""))')
else
  echo "block-main.sh: neither jq nor python3 found — main-branch guard is OFF" >&2
  exit 1   # non-blocking warning
fi
[ -z "$cmd" ] && exit 0

# Only inspect git write operations (portable ERE: no \b)
printf '%s' "$cmd" | grep -Eq '(^|[;&|[:space:]])git[[:space:]]+([^;&|]*[[:space:]])?(commit|push|merge|rebase|reset|cherry-pick|am)([[:space:]]|$)' || exit 0

branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

# 1. Writing while checked out on a protected branch
case "$branch" in
  main|master)
    echo "BLOCKED: on '$branch'. Mr Fox never commits to main. Create milestone/{N}-{slug} first." >&2
    exit 2 ;;
esac

# 2. Push whose refspec targets main/master: 'origin main', 'HEAD:main', '+main', 'refs/heads/main'
#    ('feature/main' and 'origin/main' as a source are not matched)
if printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+([^;&|]*[[:space:]])?push([[:space:]][^;&|]*)?([[:space:]]|:|\+)(refs/heads/)?(main|master)([[:space:]]|$|[;&|])'; then
  echo "BLOCKED: push targets main/master. Push your milestone branch and merge via PR." >&2
  exit 2
fi
exit 0
