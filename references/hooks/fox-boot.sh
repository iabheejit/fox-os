#!/usr/bin/env bash
# Mr Fox — SessionStart hook: auto-boot + auto-sync. Stdout is added to Claude's context.
#  1. Pulls skill updates (fast-forward only, at most once per FOX_UPDATE_HOURS, default 720 = 30 days)
#  2. Syncs hook scripts from the skill into this project (.claude/hooks/)
#  3. Flags when the project's commands/agents are older than the skill version
#  4. Prints a boot brief (milestone, last session, inbox) so Mr Fox needs no extra reads
#  5. Re-injects the last auto-sync snapshot (after /compact, resume, or a new session)
#  6. Records this session id for the voice inbox
set -u
SKILL="${FOX_SKILL_DIR:-$HOME/.claude/skills/mr-fox}"
PROJ="${CLAUDE_PROJECT_DIR:-$PWD}"
HOURS="${FOX_UPDATE_HOURS:-720}"   # 30 days; 0 = now; FOX_AUTO_UPDATE=0 = manual only
REPO="${FOX_SKILL_REPO:-https://github.com/iabheejit/fox-os}"
input=$(cat)
ver() { sed -n 's/.*\*\*Version\*\*: *\([0-9.]*\).*/\1/p' "$1" 2>/dev/null | head -1; }

echo "## Mr Fox boot (auto)"

if command -v timeout >/dev/null 2>&1; then T="timeout 20"; else T=""; fi

# 0. No skill on this machine (cloud session, new laptop): install it from GitHub
if [ ! -d "$SKILL" ] && [ "${FOX_AUTO_UPDATE:-1}" = "1" ]; then
  mkdir -p "$(dirname "$SKILL")"
  if $T git clone -q --depth 1 "$REPO" "$SKILL" >/dev/null 2>&1; then
    touch "$SKILL/.git/fox-last-pull"; echo "- Skill installed from $REPO."
  else echo "- Skill not installed and $REPO unreachable — running on project files only."; fi
fi

# 1. Self-update the skill (throttled; FOX_UPDATE_HOURS=0 forces it; offline-safe)
if [ -d "$SKILL/.git" ] && [ "${FOX_AUTO_UPDATE:-1}" = "1" ]; then
  stamp="$SKILL/.git/fox-last-pull"
  if [ "$HOURS" = "0" ] || [ -z "$(find "$stamp" -mmin -$((HOURS*60)) 2>/dev/null)" ]; then
    before=$(git -C "$SKILL" rev-parse HEAD 2>/dev/null)
    if $T git -C "$SKILL" pull --ff-only -q >/dev/null 2>&1; then touch "$stamp"
    else [ "$HOURS" = "0" ] && echo "- Skill update failed (offline, or local changes in $SKILL block a fast-forward)."; fi
    after=$(git -C "$SKILL" rev-parse HEAD 2>/dev/null)
    if [ "$before" != "$after" ]; then echo "- Skill updated: $(git -C "$SKILL" log --oneline "$before..$after" | wc -l | tr -d ' ') new commit(s), now v$(ver "$SKILL/SKILL.md")."
    elif [ "$HOURS" = "0" ]; then echo "- Skill already up to date (v$(ver "$SKILL/SKILL.md"))."; fi
  fi
fi

# 2. Sync hook scripts (Mr Fox-owned files only; state files are never touched)
if [ -d "$SKILL/references/hooks" ] && [ -d "$PROJ/.claude/hooks" ]; then
  for f in "$SKILL"/references/hooks/*.sh; do
    dst="$PROJ/.claude/hooks/$(basename "$f")"
    if ! cmp -s "$f" "$dst"; then cp "$f" "$dst" && chmod +x "$dst" && echo "- Synced hook: $(basename "$f")"; fi
  done
fi

# 3. Version drift: commands/agents/settings are written by Claude from infrastructure-setup.md
sv=$(ver "$SKILL/SKILL.md"); pv=$(cat "$PROJ/.claude/.fox-version" 2>/dev/null)
if [ ! -f "$PROJ/.claude/milestones.md" ]; then
  echo "- Project not set up. ACTION: run first-time setup from references/infrastructure-setup.md."
elif [ -n "$sv" ] && [ "$sv" != "$pv" ]; then
  echo "- Project is on Mr Fox v${pv:-unknown}, skill is v$sv. ACTION (do it now, no prompt needed): re-sync .claude/agents/, .claude/commands/, .claude/settings.json hooks and team.md comment block from references/infrastructure-setup.md. Never touch milestones, plans, audit-trail, session-log, versions or the Active Agents list. Then write '$sv' to .claude/.fox-version and report what changed in one line."
fi

# 4. Boot brief
if [ -f "$PROJ/.claude/milestones.md" ]; then
  cur=$(grep -E '\| *(IN_PROGRESS|BLOCKED) *\|' "$PROJ/.claude/milestones.md" | head -1)
  echo "- Current milestone: ${cur:-none in progress}"
  last=$(grep -m1 '^## ' "$PROJ/.claude/session-log.md" 2>/dev/null)
  echo "- Last session: ${last#\#\# }"
  mode=$(sed -n 's/^## Current Profile: *//p' "$PROJ/.claude/team.md" 2>/dev/null)
  echo "- Mode: ${mode:-unknown}"
  [ -f "$PROJ/.claude/orchestra.md" ] && echo "- Orchestra: $(grep -cE '\| *(RUNNING|BLOCKED|REVIEW) *\|' "$PROJ/.claude/orchestra.md") active workstream(s) — see .claude/orchestra.md"
fi

# 5. Auto-sync snapshot (written by fox-sync.sh on Stop / PreCompact / SessionEnd)
if command -v jq >/dev/null 2>&1; then src=$(printf '%s' "$input" | jq -r '.source // empty')
else src=$(printf '%s' "$input" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("source",""))' 2>/dev/null); fi
if [ -f "$PROJ/.claude/.fox-sync.md" ]; then
  echo "- Last auto-sync:"; sed '1d; s/^/  /' "$PROJ/.claude/.fox-sync.md"
fi
if [ "$src" = "compact" ]; then
  echo "- Context was just compacted. ACTION (no prompt needed): append a short session-log.md entry with a <!-- RESUME: --> marker for the task in progress, using the snapshot above and what you still know, then continue the task."
fi

# 6. Voice inbox: record session id, report unread
if [ -x "$PROJ/.claude/hooks/fox-voice.sh" ]; then
  printf '%s' "$input" | "$PROJ/.claude/hooks/fox-voice.sh" session | sed 's/^/- /'
fi
echo "Brief Abheejit from this block on the first reply; read the latest CTO Consolidated only if asked or if the milestone status needs it."
exit 0
