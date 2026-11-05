# Mr Fox OS

**A CTO operating system for founders who are building alone.**

Mr Fox is a persistent engineering leadership layer that runs inside Claude Code. It gives you session continuity, milestone governance, and a team of eight senior specialists who review — and fix — your work before you ship. Covering security, architecture, product, strategy, engineering craft, UX, DevOps, and plan quality.

You get the institutional memory, discipline, and review depth of a senior engineering team. Without the headcount.

---

## What It Does

Most solo founders build in a loop: decide, code, ship, regret. Mr Fox breaks that loop.

Every session starts with a brief — where you are, what's blocking you, what the last audit found. Every milestone begins with a plan that a senior EM stress-tests before a line of code is written. Every milestone ends with specialists reviewing your work in parallel (3, 5 or all 8, depending on mode), and the auto-fix specialists don't just report, they fix. Missing rate limits get patched. Vague variable names get renamed. Missing error states get added. Each fix lands on its own branch for your review before merging.

What requires a human decision — broken auth, architectural rethinks, strategic pivots — gets escalated with full context. You decide on the things that matter. The rest is handled.

The system maintains its own memory: milestone registry, session logs, audit trail, version history, living docs. It boots itself, keeps itself in sync and updates itself, with no prompting. You can context-switch, take a week off, hand work to someone else, or run several sessions at once, and come back to a complete picture of where things stand.

---

## The Team

Eight specialists. Each brings a distinct lens. None of them care about your feelings.

| Specialist | Role | When | Verdict | Auto-fixes |
|---|---|---|---|---|
| **Vikram** | Principal EM, 15yr | Before coding starts | READY / REFINE / REWORK_PLAN | Plan doc rewrites |
| **Priya** | Principal AppSec, 16yr | After milestone | PASS / WARN / FAIL | Rate limits, CORS, input validation, .gitignore |
| **Kavitha** | Sr. TPM, 14yr | After milestone | ON_TRACK / DRIFTED / BLOCKED | Missing test stubs, changelog gaps |
| **Rajan** | Distinguished Eng, 18yr | After milestone | SOUND / REVIEW_NEEDED / REWORK | Escalates only |
| **Meera** | Venture Partner, 2x Founder, 20yr | After milestone | ALIGNED / DISCUSS / PIVOT_NEEDED | Escalates only |
| **Arjun** | Staff SWE, 13yr | After milestone | CLEAN / NEEDS_WORK / REFACTOR | Renames, dead code, test fixes, function extraction |
| **Divya** | Principal UX, 11yr | After milestone | APPROVED / ITERATE / REDESIGN | Error states, empty states, aria labels, button text |
| **Sanjay** | Platform/SRE, 12yr | After milestone | SHIP_READY / OPERATIONAL_RISK / NOT_SHIPPABLE | Health endpoints, logging, .env.example, runbooks |

**Vikram** reviews your plan before you write code. He checks that every acceptance criterion is actually testable, scope is protected, the milestone is right-sized, and the downstream auditors have enough context to do their jobs. Ambiguous criteria? He rewrites them in the plan document and commits.

**Priya** thinks like an attacker. She reads every changed file. She traces data flow end-to-end. She checks what's missing as much as what's there — missing rate limiting is a finding, not a suggestion. WARN-level issues she fixes directly. FAIL-level issues (exposed secrets, broken auth) she escalates to you.

**Kavitha** treats every acceptance criterion as a contract. "80% done" is not done. She diffs the plan against reality line by line. Missing test stubs for acceptance criteria? She scaffolds them so you don't ship unverified features.

**Rajan** reads the code like someone who'll have to debug it at 3am. He checks module boundaries, data models, API contracts, and error handling — calibrated to your actual scale, not theoretical future scale. Rajan escalates — structural decisions need the founder's eye.

**Meera** doesn't care about elegant code. She cares whether this milestone creates a demonstrable asset. She reads your README, milestones, session logs, and funding context before every audit. She catches the builder's trap. Meera escalates — strategic decisions need you.

**Arjun** checks whether the next engineer can understand, modify, and test your code without asking you questions. He verifies test fidelity by asking: if I delete the feature this test covers, does the test fail? NEEDS_WORK issues — misleading names, dead code, false-positive tests — he fixes on his own branch.

**Divya** evaluates every user-facing change as a first-time user with no internal knowledge. She checks the unhappy paths — empty states, error messages, loading states — the things engineers consistently skip. ITERATE-level issues she patches directly (aria labels, missing error copy, vague button text). Structural redesigns she escalates.

**Sanjay** asks the question nobody else asks: can you actually ship this, observe it in production, and recover when it breaks at 2am? He checks deployability, logging, health endpoints, graceful failure, rollback paths. Missing a health endpoint? He adds one. Missing env var docs? He writes them.

---

### Modes

Dial audit depth to the work. Default is `min`. Switch with `/mr-fox-mode normal` (or `min`, `full`); stored in `.claude/team.md`.

| Mode | Agents | Use for |
|---|---|---|
| `min` | Vikram, Priya, Arjun | Hotfixes, spikes, tiny milestones |
| `normal` | + Kavitha, Rajan | Standard milestones |
| `full` | All 8 | Pre-release, launch, fundraising |

Specialty profiles (`backend`, `frontend`, `mvp`, `stealth`, `custom`) still work via `team.md`.

### Guardrails

"Never commit to main" is enforced by a `PreToolUse` hook (`.claude/hooks/block-main.sh`), not by a sentence in CLAUDE.md. Instructions are context; hooks are enforcement.

---

## Auto-Boot, Auto-Sync, Auto-Update

You don't run anything. Four hooks are installed into every project on first run:

| Hook | Fires on | Does |
|---|---|---|
| `fox-boot.sh` | Session start, resume, `/clear`, after compact | Briefs Mr Fox (milestone, last session, mode, orchestra, inbox). Pulls skill updates (once/24h, fast-forward only) and syncs hook scripts. If the skill is newer than the project, Mr Fox re-syncs agents and commands on his own. |
| `fox-sync.sh` | End of every turn, before compact, session end | Snapshots branch, commits, uncommitted files and resume marker to `.claude/.fox-sync.md`. It runs on the same lifecycle events as auto-compact, so a compact never loses where you were. |
| `fox-voice.sh` | Any session needs input or permission | Logs to the cross-session inbox; speaks it if voice is on. |
| `block-main.sh` | Every Bash call | Blocks commits and pushes to `main`/`master`. |

Opt out of auto-update with `FOX_AUTO_UPDATE=0`. The brief arrives with your first message; a hook can't make Claude speak first.

---

## Voice Flags & Inbox (optional)

Running several sessions? Mr Fox can tell you, out loud, when one needs you.

- `/mr-fox-voice on` uses your OS default voice: macOS `say`, Linux `spd-say`/`espeak`, Windows `System.Speech`. It's global and off by default.
- It speaks only what needs you: escalations, FAIL-level verdicts, blocked or finished workers, permission prompts, and direct questions. It never reports routine progress.
- Every flag lands in `~/.claude/fox-inbox.tsv`, so the inbox works without audio too (for example, in cloud sessions).
- `/mr-fox-inbox` lists unread flags with project, branch and session id. Jump back with `claude --resume <session>`, then run `/mr-fox-inbox mark here`.

---

## Orchestrator Mode (optional)

For milestones with parallel, separable work. Your main session becomes the **orchestrator**. It splits the plan into workstreams and starts a **worker session** for each. Every worker has its own agent tree, and the orchestrator reviews and merges their work.

```
You
 │
Orchestrator (Mr Fox · Opus · plan mode) — owns plan, orchestra.md, shared files, merges
 ├── Worker WS1 (Sonnet · own worktree · ws/{N}-1-*)
 │     ├── Explore subagents (Haiku) — read/grep fan-out
 │     └── /advisor (Opus) — decision points, repeated failures
 ├── Worker WS2 …
 ├── Judge pass (orchestrator) — "assume it's wrong" review + tests before each merge
 └── Active-team audit — once, on the merged milestone
```

- **Workers:** 2–3 (max 4), each owning disjoint files and committing only to its own `ws/*` branch. The orchestrator owns lockfiles, migrations and root config.
- **Backends:**
  - local: a git worktree plus `claude` in a new tab, or headless `claude -p`
  - cloud: Claude Code remote sessions
  - inline: worktree subagents, the cheapest option
- **Reporting:** workers report through the inbox (`blocked`, `done`); with voice on, you hear it. State lives in `.claude/orchestra.md`.
- **When not to use it:** a single-workstream milestone. One session is cheaper.

---

## How to Use

**1. Install once** (see Installation below), then open any project and say *"Mr Fox, set up this project."* Hooks, agents, commands and state files are created. From then on every session boots itself.

**2. Plan a milestone.** Run `/mr-fox-plan`. Describe what you're building; Vikram reviews the plan; you confirm; Mr Fox branches `milestone/{N}-{slug}`.

**3. Pick the audit depth.** Default is `min`.
```
/mr-fox-mode min      # Vikram, Priya, Arjun — hotfixes, spikes
/mr-fox-mode normal   # + Kavitha, Rajan — standard milestones
/mr-fox-mode full     # all 8 — before launch or a raise
```

**4. Build.** Either:
- *Single session (default)*: just work with Mr Fox.
- *Orchestrated*: `/mr-fox-orchestrate start` → approve the workstream split → open the worker tabs it gives you (or let it run them headless or in the cloud) → `/mr-fox-orchestrate status` to check in → `/mr-fox-orchestrate review ws1` to judge and merge each one.

**5. Stay in the loop without watching.** `/mr-fox-voice on`, then switch away. When you hear *"Mr Fox. my-app. WS2 blocked: …"*, run `/mr-fox-inbox`, resume that session, unblock it, and `/mr-fox-inbox mark here`.

**6. Finish.** Run `/mr-fox-milestone-complete`. The active team audits, then you get the CTO Consolidated. Run `/mr-fox-apply-fixes` to review the auto-fix branches, then merge via PR.

**7. Walk away.** Auto-sync has your state. Next session, the brief picks up where you left off, even after a compact.

---

## Milestone Lifecycle## Milestone Lifecycle

```
Draft Plan → Vikram Reviews Plan → Confirm → Branch → Build
                                                          ↓
                                  Active-team audits (min 3 · normal 5 · full 8)
                                                          ↓
                                    auto-fix specialists fix on branches
                                    Rajan and Meera (when active) escalate
                                                          ↓
                                             CTO Consolidated
                                    (Auto-Fixed + Escalations to decide)
                                                          ↓
                    /mr-fox-apply-fixes → Review branches → Merge → Ship
```

### Before You Write Code

1. Draft a milestone plan (template provided)
2. Vikram reviews it — every criterion must be verifiable by code and tests
3. Returns READY, REFINE, or REWORK_PLAN
4. Coding doesn't start until it's READY

### After You Build

The active team reviews in parallel (`full` covers all seven post-build lenses):
- Security, delivery, architecture, strategy, code quality, UX, operational readiness
- Each appends structured findings to `.claude/audit-trail.md`

Mr Fox synthesises into a CTO Consolidated (example below is `full` mode):

```
### CTO Consolidated — Milestone 3
Date: 2026-04-07
Mr Fox's Call: PROCEED

Executive Summary: Auth flow is solid and PM criteria are met. Priya patched the
rate limiting on /auth/reset and Sanjay added a health endpoint — both already
committed to their branches for your review. Rajan flagged an API contract question
that needs your call before Milestone 4.

From Priya (Security):     WARN → auto-fixed — rate limit added to /auth/reset
From Kavitha (PM):         ON_TRACK — all 4 criteria met, tests exist
From Rajan (Architecture): SOUND — module boundaries clean, schema appropriate
From Meera (Strategy):     ALIGNED — demo-ready for grant report
From Arjun (Engineering):  NEEDS_WORK → auto-fixed — 2 renames + false-positive test fixed
From Divya (Design):       APPROVED — primary flow frictionless, error states handled
From Sanjay (DevOps):      OPERATIONAL_RISK → auto-fixed — /health endpoint + .env.example added

Auto-Fixed:
- audit/fix-priya-m3: rate limit middleware on POST /auth/reset
- audit/fix-arjun-m3: renamed processUsr→processUser, fixed false-positive auth test
- audit/fix-sanjay-m3: added GET /health, documented 3 missing env vars in .env.example

Escalations Requiring Decision:
- Rajan: API versioning strategy — /v1/ prefix now or later? Decide before Milestone 4.

Mr Fox's Note to Abheejit: Run /mr-fox-apply-fixes to merge the three auto-fix branches.
One architectural decision to make (Rajan's note above) — five minutes of thought now
saves a painful migration later. Everything else is green.
```

---

## Institutional Memory

Mr Fox maintains four living documents in `.claude/`:

**`milestones.md`** — lightweight registry. One row per milestone, scannable in two seconds.

**`audit-trail.md`** — every plan review and post-milestone audit, appended in order. Complete decision history.

**`session-log.md`** — reverse chronological session summaries. Date, milestone, what was done, what's next. Resume markers for mid-task interruptions.

**`versions.md`** — version history. Major on milestone completion, minor on significant progress, patch on fixes.

Plus auto-generated docs at milestone completion: API reference, architecture decisions (append-only ADR log), and changelog.

---

## Installation

### One-Time Setup

```bash
mkdir -p ~/.claude/skills
git clone https://github.com/iabheejit/fox-os ~/.claude/skills/mr-fox
```

Works across Claude Code CLI, VS Code (Claude Code extension), and Cursor. The skill directory is shared across all platforms.

### First Session in a New Project

Say "Mr Fox, set up this project" (or run `/mr-fox`). The `/mr-fox-*` slash commands don't exist yet on a fresh project — the boot creates them.

Mr Fox creates the full project structure:

```
[project root]/
├── CLAUDE.md                    # Auto-boots Mr Fox in every session
└── .claude/
    ├── milestones.md
    ├── audit-trail.md
    ├── versions.md
    ├── session-log.md
    ├── team.md                  # Audit mode: min | normal | full | profile
    ├── settings.json            # Hook registration
    ├── hooks/                   # fox-boot, fox-sync, fox-voice, block-main (auto-synced)
    ├── agents/                  # 8 specialists as native Claude Code subagents
    │   ├── plan-reviewer.md     # Vikram
    │   ├── security-auditor.md  # Priya
    │   ├── project-manager.md   # Kavitha
    │   ├── system-architect.md  # Rajan
    │   ├── founder-strategist.md # Meera
    │   ├── software-engineer.md # Arjun
    │   ├── ux-designer.md       # Divya
    │   └── devops-engineer.md   # Sanjay
    ├── commands/                # Slash commands for VS Code / Cursor / CLI
    ├── plans/
    └── docs/
```

After setup, the project is self-contained. Mr Fox works on any platform — even without the skill installed — via `CLAUDE.md` and `.claude/agents/`.

---

## Commands

| Command | What it does |
|---|---|
| `/mr-fox-boot` | Re-brief mid-session. (Boot runs automatically at session start.) |
| `/mr-fox-status` | One-liner: current milestone, status, blockers. |
| `/mr-fox-mode` | Set audit depth: `min` (3 agents), `normal` (5), `full` (8). |
| `/mr-fox-voice` | Voice flags: `on`, `off`, `test`, `status`. Off by default. |
| `/mr-fox-inbox` | Unread flags from every session. `mark here` / `mark <id>` / `mark all` to clear. |
| `/mr-fox-orchestrate` | Run a milestone across worker sessions: `start`, `status`, `review <ws>`, `stop <ws>`. |
| `/mr-fox-plan` | Start a new milestone: draft plan → Vikram reviews → confirm → branch. |
| `/mr-fox-plan-review` | Spawn Vikram against the current milestone plan. |
| `/mr-fox-audit` | Spawn the active team's auditors. Auto-fix specialists fix on branches; all append to audit-trail. |
| `/mr-fox-apply-fixes` | Review auto-fix branches from last audit. Show diffs. Merge approved. |
| `/mr-fox-milestone-complete` | Mark done → spawn audits → CTO consolidated → apply-fixes prompt → docs. |
| `/mr-fox-log` | Append session summary to session-log.md. |

Or just talk naturally. Mr Fox activates on: *"what's our status"*, *"run the audit"*, *"complete milestone"*, *"what are we building"*, *"what's blocking us"*, and most messages that begin a coding session.

---

## Design Principles

**Decisions over discussion.** Every session ends with something built, decided, or explicitly deferred. No open loops.

**Read state first.** Mr Fox reads your milestones and session log before saying anything. No repeating what's in the files.

**Plans before code.** For anything touching 3+ files, there's a plan. Plans prevent expensive rework. Vikram stress-tests the plan before a line of code is written.

**Shipped work only.** Building feels like progress. Shipped, deployed, funded work is progress. Mr Fox flags the builder's trap.

**Simple over clever.** No over-engineering for scale you haven't earned. No under-thinking for problems that are real. The right amount of complexity is what the task actually requires.

**Honest audits.** The specialists don't soften findings. A missing rate limit is a WARN. A hardcoded secret is a FAIL. "80% done" is DRIFTED. The value is in the honesty.

**Audits execute.** Six of eight specialists don't just report — they fix. Lower-severity issues (WARN, NEEDS_WORK, ITERATE, OPERATIONAL_RISK) are resolved on dedicated branches. You review diffs and merge. Structural decisions (FAIL, REWORK, NOT_SHIPPABLE) are escalated for your call. You spend time on decisions, not cleanup.

---

## Repository Structure

```
fox-os/
├── SKILL.md                    # Skill entrypoint — Mr Fox's core identity and lifecycle
├── CLAUDE.md                   # Cross-platform bootstrap via @SKILL.md import
└── references/
    ├── infrastructure-setup.md # First-run setup — the single source for every agent,
    │                           #   command and state-file template installed into a project
    ├── plan-template.md        # Milestone plan template
    ├── hooks/                  # Hook scripts copied into each project (auto-synced on boot)
    │   ├── fox-boot.sh         #   SessionStart: auto-boot, auto-update, drift sync
    │   ├── fox-sync.sh         #   Stop / PreCompact / SessionEnd: state snapshot
    │   ├── fox-voice.sh        #   Voice flags + cross-session inbox
    │   └── block-main.sh       #   PreToolUse: never commit to main
    └── personas/               # Long-form specialist backstories (reference only, not executed)
        ├── plan-reviewer.md
        ├── security-auditor.md
        ├── project-manager.md
        ├── system-architect.md
        ├── founder-strategist.md
        ├── software-engineer.md
        ├── ux-designer.md
        └── devops-engineer.md
```

The agents that actually run live in each project's `.claude/agents/`, written by `infrastructure-setup.md` on first boot. The six auto-fix specialists run on `haiku`; Rajan and Meera (read-only, structural reasoning) run on the session model.

---

## Platform Compatibility

| Platform | Auto-boot | Slash commands | Subagents | State files |
|---|---|---|---|---|
| Claude Code CLI | via skill | `/mr-fox-*` | `.claude/agents/` | `.claude/` |
| VS Code (Claude extension) | via CLAUDE.md | `/` menu | `.claude/agents/` | `.claude/` |
| Cursor | via CLAUDE.md | `/` menu | `.claude/agents/` | `.claude/` |
| Claude.ai (web/desktop) | via CLAUDE.md | natural language | `.claude/agents/` | `.claude/` |

---

> Built by Abheejit Khandagale. Mr Fox OS v1.4.0.
