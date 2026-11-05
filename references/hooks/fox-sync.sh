#!/usr/bin/env bash
# Mr Fox — auto-sync. Runs like auto-compact: no prompting.
# Hooks: Stop (every turn), PreCompact (before context is compacted), SessionEnd.
# Writes a mechanical snapshot to .claude/.fox-sync.md (local, gitignored).
# fox-boot.sh re-injects it on the next SessionStart — including right after a compact.
set -u
PROJ="${CLAUDE_PROJECT_DIR:-$PWD}"
[ -d "$PROJ/.claude" ] || exit 0
input=$(cat)
if command -v jq >/dev/null 2>&1; then event=$(printf '%s' "$input" | jq -r '.hook_event_name // empty')
else event=$(printf '%s' "$input" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("hook_event_name",""))' 2>/dev/null); fi

g() { git -C "$PROJ" "$@" 2>/dev/null; }
branch=$(g symbolic-ref --short -q HEAD); branch=${branch:-detached}
{
  echo "# Mr Fox auto-sync snapshot"
  echo "- When: $(date '+%Y-%m-%d %H:%M') (${event:-manual})"
  echo "- Branch: $branch @ $(g log -1 --format='%h %s')"
  echo "- Uncommitted files: $(g status --porcelain | wc -l | tr -d ' ')"
  g status --porcelain | head -10 | sed 's/^/    /'
  echo "- Last 3 commits on branch:"
  g log -3 --format='    %h %s (%cr)'
  resume=$(grep -h 'RESUME:' "$PROJ/.claude/session-log.md" 2>/dev/null | head -1)
  if [ -n "$resume" ]; then echo "- Latest resume marker: $resume"; fi
} > "$PROJ/.claude/.fox-sync.md.tmp" && mv "$PROJ/.claude/.fox-sync.md.tmp" "$PROJ/.claude/.fox-sync.md"
exit 0
