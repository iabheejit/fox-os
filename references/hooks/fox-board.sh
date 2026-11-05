#!/usr/bin/env bash
# Mr Fox — on-demand orchestra Kanban. Nothing runs until you call it.
#   fox-board.sh [open]   render .claude/fox-board.html and open it in the browser
#   fox-board.sh render   render only (print the path)
#   fox-board.sh text     print the board in the terminal
#   fox-board.sh watch    re-render every 10s in the background (page auto-refreshes)
#   fox-board.sh stop     stop watch mode
# Reads .claude/orchestra.md, .claude/milestones.md, .claude/team.md, git, and ~/.claude/fox-inbox.tsv.
set -u
PROJ="${CLAUDE_PROJECT_DIR:-$PWD}"
OUT="$PROJ/.claude/fox-board.html"
PIDF="$PROJ/.claude/.fox-board.pid"
INBOX="${FOX_HOME:-$HOME/.claude}/fox-inbox.tsv"
command -v python3 >/dev/null 2>&1 || { echo "fox-board needs python3" >&2; exit 1; }
[ -f "$PROJ/.claude/orchestra.md" ] || { echo "No .claude/orchestra.md — run /mr-fox-orchestrate start first." >&2; exit 1; }

render() { # $1 = html|text, $2 = refresh seconds (0 = none)
python3 - "$PROJ" "$INBOX" "$1" "${2:-0}" <<'PY'
import sys, os, re, html, subprocess, datetime
proj, inbox, fmt, refresh = sys.argv[1], sys.argv[2], sys.argv[3], int(sys.argv[4])
def read(p):
    try: return open(p, encoding="utf-8").read()
    except OSError: return ""
def git(*a):
    try: return subprocess.run(["git","-C",proj,*a],capture_output=True,text=True,timeout=5).stdout.strip()
    except Exception: return ""

orch = read(os.path.join(proj,".claude","orchestra.md"))
title = (re.search(r"^# (.+)$", orch, re.M) or [None,"Orchestra"])[1]
m = re.search(r"Milestone\s+(\d+)", title); N = m.group(1) if m else None
rows=[]; header=None
for line in orch.splitlines():
    if not line.strip().startswith("|"): continue
    cells=[c.strip() for c in line.strip().strip("|").split("|")]
    if all(re.fullmatch(r":?-+:?",c) for c in cells if c): continue
    if header is None: header=[c.lower() for c in cells]; continue
    rows.append(dict(zip(header,cells)))
def col(r,*names):
    for n in names:
        for k,v in r.items():
            if k.startswith(n): return v
    return ""

mode = (re.search(r"^## Current Profile:\s*(\S+)", read(os.path.join(proj,".claude","team.md")), re.M) or [None,"?"])[1]
mbranch = ""
for b in git("branch","--format=%(refname:short)").splitlines():
    if N and b.startswith(f"milestone/{N}-"): mbranch=b
flags=[]
for line in read(inbox).splitlines():
    f=line.split("\t")
    if len(f)>=8: flags.append(dict(id=f[0],time=f[1],state=f[2],level=f[3],dir=f[4],branch=f[5],session=f[6],msg=f[7]))
base=proj.rstrip("/")
mine=lambda d: d==base or d.startswith(base+"-ws")   # this repo + its sibling worker worktrees
unread=[f for f in flags if f["state"]=="new" and mine(f["dir"])]

COLS=["QUEUED","RUNNING","BLOCKED","REVIEW","MERGED","DROPPED"]
cards={c:[] for c in COLS}
for r in rows:
    st=col(r,"status").upper() or "QUEUED"
    br=col(r,"branch").strip("` ")
    ahead=git("rev-list","--count",f"{mbranch}..{br}") if mbranch and br else ""
    last=git("log","-1","--format=%h %s · %cr",br) if br else ""
    fl=[f for f in flags if br and f["branch"]==br]
    latest=fl[-1] if fl else None
    cards.setdefault(st,[]).append(dict(ws=col(r,"ws"),goal=col(r,"goal"),owns=col(r,"owns"),branch=br,
        backend=col(r,"backend"),session=col(r,"session"),check=col(r,"last"),ahead=ahead,last=last,flag=latest,
        unread=sum(1 for f in fl if f["state"]=="new")))
now=datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")

if fmt=="text":
    print(f"{title}  ·  mode {mode}  ·  base {mbranch or '?'}  ·  {now}")
    for c in COLS:
        if not cards.get(c): continue
        print(f"\n[{c}]")
        for k in cards[c]:
            print(f"  {k['ws']:<5} {k['goal'][:60]}")
            print(f"        {k['branch']} · {k['backend']} · +{k['ahead'] or 0} commits · {k['last'][:50]}")
            if k['flag']: print(f"        ⚑ {k['flag']['level']}: {k['flag']['msg'][:70]}")
    sys.exit(0)

e=html.escape
def card(k):
    flag=""
    if k["flag"]:
        f=k["flag"]; flag=f'<div class="flag {e(f["level"])}{" seen" if f["state"]!="new" else ""}">⚑ {e(f["level"])} · {e(f["time"][11:])}<br>{e(f["msg"])}</div>'
    sess=f'<code title="claude --resume {e(k["session"])}">{e(k["session"][:14])}</code>' if k["session"] and k["session"]!="-" else ""
    return f'''<article class="card">
  <header><b>{e(k["ws"])}</b>{f'<span class="badge">{k["unread"]}</span>' if k["unread"] else ""}<span class="be">{e(k["backend"])}</span></header>
  <p>{e(k["goal"])}</p>
  <dl><dt>owns</dt><dd>{e(k["owns"])}</dd><dt>branch</dt><dd><code>{e(k["branch"])}</code></dd>
  <dt>progress</dt><dd>+{e(k["ahead"] or "0")} commits{(" · "+e(k["last"])) if k["last"] else ""}</dd>
  {f"<dt>session</dt><dd>{sess}</dd>" if sess else ""}{f'<dt>checked</dt><dd>{e(k["check"])}</dd>' if k["check"] else ""}</dl>
  {flag}</article>'''
colhtml="".join(f'<section class="col {c.lower()}"><h2>{c}<span>{len(cards.get(c,[]))}</span></h2>{"".join(card(k) for k in cards.get(c,[])) or "<p class=empty>—</p>"}</section>' for c in COLS)
meta=f'<meta http-equiv="refresh" content="{refresh}">' if refresh else ""
print(f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">{meta}
<title>Mr Fox Board</title><style>
:root{{--bg:#f6f5f2;--fg:#1d1d1b;--mut:#6b6a66;--card:#fff;--line:#e2e0da;--acc:#d9622b;--ok:#2f7d4f;--warn:#b7791f;--bad:#c0392b;--info:#3b6ea8}}
@media (prefers-color-scheme:dark){{:root{{--bg:#151514;--fg:#ecebe7;--mut:#9a9893;--card:#201f1d;--line:#34322e;--acc:#f08048;--ok:#5cb37f;--warn:#e0a43c;--bad:#e5675a;--info:#79a6dc}}}}
*{{box-sizing:border-box}}body{{margin:0;background:var(--bg);color:var(--fg);font:14px/1.45 ui-sans-serif,system-ui,-apple-system,"Segoe UI",sans-serif}}
.top{{display:flex;flex-wrap:wrap;gap:8px 20px;align-items:baseline;padding:18px 20px;border-bottom:1px solid var(--line)}}
.top h1{{margin:0;font-size:18px}}.top h1 b{{color:var(--acc)}}.top span{{color:var(--mut)}}
.board{{display:grid;grid-template-columns:repeat(6,minmax(230px,1fr));gap:14px;padding:16px 20px;overflow-x:auto}}
@media (max-width:760px){{.board{{grid-template-columns:1fr}}}}
.col h2{{font-size:12px;letter-spacing:.08em;margin:0 0 10px;display:flex;justify-content:space-between;color:var(--mut)}}
.col h2 span{{background:var(--line);border-radius:10px;padding:0 8px;color:var(--fg)}}
.col.running h2{{color:var(--info)}}.col.blocked h2{{color:var(--bad)}}.col.review h2{{color:var(--warn)}}.col.merged h2{{color:var(--ok)}}
.card{{background:var(--card);border:1px solid var(--line);border-radius:10px;padding:12px;margin-bottom:10px}}
.col.blocked .card{{border-left:3px solid var(--bad)}}.col.review .card{{border-left:3px solid var(--warn)}}.col.running .card{{border-left:3px solid var(--info)}}.col.merged .card{{opacity:.75}}
.card header{{display:flex;gap:8px;align-items:center}}.be{{margin-left:auto;font-size:11px;color:var(--mut)}}
.badge{{background:var(--acc);color:#fff;border-radius:9px;font-size:11px;padding:0 6px}}
.card p{{margin:6px 0 8px}}dl{{display:grid;grid-template-columns:auto 1fr;gap:2px 10px;margin:0;font-size:12px}}dt{{color:var(--mut)}}dd{{margin:0;overflow-wrap:anywhere}}
code{{font:12px ui-monospace,SFMono-Regular,Menlo,monospace}}
.flag{{margin-top:8px;font-size:12px;padding:6px 8px;border-radius:6px;background:var(--line)}}.flag.blocked,.flag.escalate{{color:var(--bad)}}.flag.done{{color:var(--ok)}}.flag.seen{{opacity:.6}}
.empty{{color:var(--mut);text-align:center}}
</style></head><body>
<div class="top"><h1><b>Mr Fox</b> · {e(title)}</h1><span>mode <b>{e(mode)}</b></span><span>base <code>{e(mbranch or "?")}</code></span>
<span>{len(unread)} unread flag(s)</span><span>updated {now}{" · auto-refresh "+str(refresh)+"s" if refresh else ""}</span></div>
<main class="board">{colhtml}</main></body></html>''')
PY
}

open_file() {
  if command -v open >/dev/null 2>&1; then open "$1"
  elif command -v xdg-open >/dev/null 2>&1; then xdg-open "$1" >/dev/null 2>&1
  elif command -v cmd.exe >/dev/null 2>&1; then cmd.exe /c start "" "$(wslpath -w "$1" 2>/dev/null || echo "$1")"
  else echo "No browser found — open $1 yourself"; fi
}

case "${1:-open}" in
  render) render html 0 > "$OUT" && echo "$OUT" ;;
  open)   render html 0 > "$OUT" && open_file "$OUT"; echo "Board: $OUT" ;;
  text)   render text 0 ;;
  watch)  [ -f "$PIDF" ] && kill "$(cat "$PIDF")" 2>/dev/null
          ( while true; do render html 10 > "$OUT.tmp" && mv "$OUT.tmp" "$OUT"; sleep 10; done ) >/dev/null 2>&1 &
          echo $! > "$PIDF"; sleep 1; open_file "$OUT"; echo "Board (live, 10s): $OUT — stop with: fox-board.sh stop" ;;
  stop)   [ -f "$PIDF" ] && kill "$(cat "$PIDF")" 2>/dev/null; rm -f "$PIDF"; echo "Board watch stopped" ;;
  *)      sed -n '2,8p' "$0"; exit 1 ;;
esac
