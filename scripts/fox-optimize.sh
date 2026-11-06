#!/usr/bin/env bash
# Mr Fox — local usage optimizer. Dry run by default; --apply writes changes.
#
#   fox-optimize.sh [--apply] [--name NAME] [--model sonnet|haiku]
#                   [--disable-plugins "a,b,c"] [--no-guard]
#
#   1. Cheaper subagents: CLAUDE_CODE_SUBAGENT_MODEL in ~/.claude/settings.json, plus
#      Haiku agents scout / summarizer / log-reader in ~/.claude/agents/, and routing
#      rules in ~/.claude/CLAUDE.md (with your name, so Mr Fox greets you).
#   2. Fewer MCP servers: disables the plugins you list (enabledPlugins → false),
#      and reports every other MCP server with how to turn it off.
#   3. /clear on task switch: registers the context guard (UserPromptSubmit hook)
#      that nudges /clear or /compact when a session gets big, 8h+ old, or a week old,
#      and installs /mr-fox-refresh globally (handoff → /clear, for long-lived sessions).
# Backs up every file it changes to <file>.bak-fox. Safe to re-run.
set -euo pipefail
APPLY=0; NAME=""; MODEL="sonnet"; NOGUARD=0
PLUGINS="brand-voice,common-room,data,design,marketing,product-management,operations,engineering"
while [ $# -gt 0 ]; do case "$1" in
  --apply) APPLY=1 ;; --name) NAME="$2"; shift ;; --model) MODEL="$2"; shift ;;
  --disable-plugins) PLUGINS="$2"; shift ;; --no-guard) NOGUARD=1 ;;
  -h|--help) sed -n '2,16p' "$0"; exit 0 ;; *) echo "unknown option: $1" >&2; exit 1 ;;
esac; shift; done
case "$MODEL" in sonnet|haiku) ;; *) echo "--model must be sonnet or haiku" >&2; exit 1 ;; esac
command -v python3 >/dev/null || { echo "needs python3" >&2; exit 1; }

C="$HOME/.claude"; S="$C/settings.json"; G="$C/CLAUDE.md"
HERE="$(cd "$(dirname "$0")" && pwd)"; SKILL="$(dirname "$HERE")"
GUARD="$SKILL/scripts/fox-guard.sh"
[ $APPLY = 1 ] && echo "== Mr Fox optimize (APPLY) ==" || echo "== Mr Fox optimize (dry run — add --apply to write) =="
backup() { [ -f "$1" ] && [ ! -f "$1.bak-fox" ] && cp "$1" "$1.bak-fox" || true; }

# ---------- 1 + 2 + 3 (settings.json edits, one pass) ----------
mkdir -p "$C"; [ -f "$S" ] || { [ $APPLY = 1 ] && echo '{}' > "$S"; }
python3 - "$S" "$APPLY" "$MODEL" "$PLUGINS" "$GUARD" "$NOGUARD" <<'PY'
import json, os, sys
path, apply, model, plugins, guard, noguard = sys.argv[1], sys.argv[2]=="1", sys.argv[3], sys.argv[4], sys.argv[5], sys.argv[6]=="1"
d = json.load(open(path)) if os.path.exists(path) else {}
changes = []
env = d.setdefault("env", {})
if env.get("CLAUDE_CODE_SUBAGENT_MODEL") != model:
    changes.append(f"1. subagent model: {env.get('CLAUDE_CODE_SUBAGENT_MODEL','(main model)')} → {model}")
    env["CLAUDE_CODE_SUBAGENT_MODEL"] = model
else: print(f"1. subagent model already {model}")

want = [p.strip() for p in plugins.split(",") if p.strip()]
ep = d.get("enabledPlugins", {})
hit = [k for k, v in ep.items() if v and k.split("@")[0] in want]
for k in hit: ep[k] = False
if hit: changes.append("2. disable plugins: " + ", ".join(hit))
else: print("2. none of the listed plugins are enabled in settings.json")
keep = [k for k, v in ep.items() if v]
if keep: print("   still enabled plugins: " + ", ".join(keep))

if not noguard:
    hooks = d.setdefault("hooks", {}).setdefault("UserPromptSubmit", [])
    cmd = f'"{guard}"'
    if not any(cmd in h.get("command","") for e in hooks for h in e.get("hooks", [])):
        hooks.append({"hooks": [{"type": "command", "command": cmd}]})
        changes.append("3. register context guard (UserPromptSubmit)")
    else: print("3. context guard already registered")

for c in changes: print(("   ✔ " if apply else "   would: ") + c)
if apply and changes:
    if os.path.exists(path) and not os.path.exists(path + ".bak-fox"):
        open(path + ".bak-fox", "w").write(open(path).read())
    json.dump(d, open(path, "w"), indent=2); open(path, "a").write("\n")
PY

# ---------- 1. Haiku agents ----------
for a in scout summarizer log-reader; do
  src="$SKILL/references/agents/$a.md"; dst="$C/agents/$a.md"
  if cmp -s "$src" "$dst" 2>/dev/null; then echo "1. agent $a already installed"
  elif [ $APPLY = 1 ]; then mkdir -p "$C/agents"; backup "$dst"; cp "$src" "$dst"; echo "   ✔ 1. installed agent $a (haiku)"
  else echo "   would: 1. install agent $a (haiku) → $dst"; fi
done

# ---------- 3. /mr-fox-refresh as a global command (works in every project) ----------
src="$SKILL/references/commands/mr-fox-refresh.md"; dst="$C/commands/mr-fox-refresh.md"
if cmp -s "$src" "$dst" 2>/dev/null; then echo "3. /mr-fox-refresh already installed"
elif [ $APPLY = 1 ]; then mkdir -p "$C/commands"; backup "$dst"; cp "$src" "$dst"; echo "   ✔ 3. installed global /mr-fox-refresh"
else echo "   would: 3. install global /mr-fox-refresh → $dst"; fi

# ---------- 1. Global CLAUDE.md: name + routing ----------
if [ -n "$NAME" ] && ! grep -q '^My name is ' "$G" 2>/dev/null; then
  if [ $APPLY = 1 ]; then backup "$G"; printf '\nMy name is %s.\n' "$NAME" >> "$G"; echo "   ✔ 1. name '$NAME' added to ~/.claude/CLAUDE.md"
  else echo "   would: 1. add 'My name is $NAME.' to ~/.claude/CLAUDE.md"; fi
elif grep -q '^My name is ' "$G" 2>/dev/null; then echo "1. name already set: $(grep -m1 '^My name is ' "$G")"; fi
if ! grep -q 'Subagent routing' "$G" 2>/dev/null; then
  if [ $APPLY = 1 ]; then backup "$G"; cat >> "$G" <<'EOT'

## Subagent routing
- Finding things only → `Explore` or `scout` (read-only, cheap). Not `general-purpose`.
- Summaries of long docs/diffs/threads → `summarizer`. Logs, CI output, stack traces → `log-reader`.
- `general-purpose` only for multi-step work that needs edits or judgment.
- Switching to an unrelated task → suggest /clear first; Mr Fox state survives it.
EOT
  echo "   ✔ 1. routing rules added to ~/.claude/CLAUDE.md"
  else echo "   would: 1. add subagent routing rules to ~/.claude/CLAUDE.md"; fi
else echo "1. routing rules already in ~/.claude/CLAUDE.md"; fi

# ---------- 2. Report other MCP servers (never auto-removed) ----------
python3 - "$HOME/.claude.json" <<'PY'
import json, os, sys
p = sys.argv[1]
if not os.path.exists(p): print("2. no ~/.claude.json (no CLI-added MCP servers)"); sys.exit()
d = json.load(open(p)); rows = []
for n in (d.get("mcpServers") or {}): rows.append(("user", n, ""))
for proj, cfg in (d.get("projects") or {}).items():
    for n in (cfg.get("mcpServers") or {}): rows.append(("local", n, proj))
if not rows: print("2. no CLI-added MCP servers"); sys.exit()
print(f"2. {len(rows)} CLI-added MCP server(s) — each one's tool list loads on every request:")
for scope, n, proj in rows:
    print(f"   - {n:<28} [{scope}] {proj}  → remove: claude mcp remove {n} -s {scope}")
PY
echo "2. claude.ai connectors (Gmail, Vercel, Notion…) are account-level: turn off the ones you don't use weekly in claude.ai → Settings → Connectors."
[ $APPLY = 1 ] && echo "Done. Backups: *.bak-fox. Restart Claude Code; check with /agents, /mcp and /context." || echo "Nothing written. Re-run with --apply."
