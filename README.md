# Mr Fox OS

**A CTO operating system for founders who are building alone.**

Mr Fox is a persistent engineering leadership layer that runs inside Claude Code. It gives you session continuity, milestone governance, and a team of eight senior specialists who review your work before you ship — covering security, architecture, product, strategy, engineering craft, UX, DevOps, and plan quality.

You get the institutional memory, discipline, and review depth of a senior engineering team. Without the headcount.

---

## What It Does

Most solo founders build in a loop: decide, code, ship, regret. Mr Fox breaks that loop.

Every session starts with a brief — where you are, what's blocking you, what the last audit found. Every milestone begins with a plan that a senior EM stress-tests before a line of code is written. Every milestone ends with seven specialists reviewing your work in parallel before you're allowed to merge.

The system maintains its own memory: milestone registry, session logs, audit trail, version history, living docs. You can context-switch, take a week off, hand work to someone else — and come back to a complete picture of where things stand.

---

## The Team

Eight specialists. Each brings a distinct lens. None of them care about your feelings.

| Specialist | Role | When | Verdict |
|---|---|---|---|
| **Vikram** | Principal EM, 15yr | Before coding starts | READY / REFINE / REWORK_PLAN |
| **Priya** | Principal AppSec, 16yr | After milestone | PASS / WARN / FAIL |
| **Kavitha** | Sr. TPM, 14yr | After milestone | ON_TRACK / DRIFTED / BLOCKED |
| **Rajan** | Distinguished Eng, 18yr | After milestone | SOUND / REVIEW_NEEDED / REWORK |
| **Meera** | Venture Partner, 2x Founder, 20yr | After milestone | ALIGNED / DISCUSS / PIVOT_NEEDED |
| **Arjun** | Staff SWE, 13yr | After milestone | CLEAN / NEEDS_WORK / REFACTOR |
| **Divya** | Principal UX, 11yr | After milestone | APPROVED / ITERATE / REDESIGN |
| **Sanjay** | Platform/SRE, 12yr | After milestone | SHIP_READY / OPERATIONAL_RISK / NOT_SHIPPABLE |

**Vikram** reviews your plan before you write code. He checks that every acceptance criterion is actually testable, scope is protected, the milestone is right-sized, and the downstream auditors have enough context to do their jobs.

**Priya** thinks like an attacker. She reads every changed file. She traces data flow end-to-end. She checks what's missing as much as what's there — missing rate limiting is a finding, not a suggestion.

**Kavitha** treats every acceptance criterion as a contract. "80% done" is not done. She diffs the plan against reality line by line and tells you whether you'd be comfortable showing this to a funder today.

**Rajan** reads the code like someone who'll have to debug it at 3am. He checks module boundaries, data models, API contracts, and error handling — calibrated to your actual scale, not theoretical future scale.

**Meera** doesn't care about elegant code. She cares whether this milestone creates a demonstrable asset. She reads your README, milestones, session logs, and funding context before every audit. She catches the builder's trap.

**Arjun** checks whether the next engineer can understand, modify, and test your code without asking you questions. He verifies test fidelity by asking: if I delete the feature this test covers, does the test fail?

**Divya** evaluates every user-facing change as a first-time user with no internal knowledge. She checks the unhappy paths — empty states, error messages, loading states — the things engineers consistently skip.

**Sanjay** asks the question nobody else asks: can you actually ship this, observe it in production, and recover when it breaks at 2am? He checks deployability, logging, health endpoints, graceful failure, rollback paths.

---

## Milestone Lifecycle

```
Draft Plan → Vikram Reviews Plan → Confirm → Branch → Build
                                                          ↓
                              Merge ← CTO Consolidated ← 7 Parallel Audits
```

### Before You Write Code

1. Draft a milestone plan (template provided)
2. Vikram reviews it — every criterion must be verifiable by code and tests
3. Returns READY, REFINE, or REWORK_PLAN
4. Coding doesn't start until it's READY

### After You Build

Seven specialists review in parallel:
- Security, delivery, architecture, strategy, code quality, UX, operational readiness
- Each appends structured findings to `.claude/audit-trail.md`

Mr Fox synthesises into a CTO Consolidated:

```
### CTO Consolidated — Milestone 3
Date: 2026-04-07
Mr Fox's Call: FIX_REQUIRED

Executive Summary: Auth flow is solid and PM criteria are met, but Priya found
a missing rate limit on the password reset endpoint and Sanjay flagged no rollback
path for the database migration. Both are blocking.

From Priya (Security):   WARN — rate limit missing on /auth/reset
From Kavitha (PM):       ON_TRACK — all 4 criteria met, tests exist
From Rajan (Architecture): SOUND — module boundaries clean, schema appropriate
From Meera (Strategy):   ALIGNED — demo-ready for grant report
From Arjun (Engineering): NEEDS_WORK — 2 functions over 40 lines, test coverage partial
From Divya (Design):     APPROVED — primary flow frictionless, error states handled
From Sanjay (DevOps):    OPERATIONAL_RISK — no rollback path for migration

Blocking Issues:
- Priya: Add rate limiting to POST /auth/reset (file:line)
- Sanjay: Document rollback procedure for migration-004

Action Items:
- [ ] Add rate limit middleware to password reset endpoint
- [ ] Write migration rollback runbook in .claude/docs/

Mr Fox's Note to Abheejit: Two specific fixes, both under an hour. Clean them up
and this milestone is clear to merge. The auth architecture is solid — Rajan's
green light here means the next milestone can build on it confidently.
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
git clone https://github.com/iabheejit/mr-fox-os ~/.claude/skills/mr-fox
```

Works across Claude Code CLI, VS Code (Claude Code extension), and Cursor. The skill directory is shared across all platforms.

### First Session in a New Project

Run `/mr-fox-boot` or say "Mr Fox, set up this project."

Mr Fox creates the full project structure:

```
[project root]/
├── CLAUDE.md                    # Auto-boots Mr Fox in every session
└── .claude/
    ├── milestones.md
    ├── audit-trail.md
    ├── versions.md
    ├── session-log.md
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
| `/mr-fox-boot` | Full boot: reads milestone status, last 3 sessions, latest audit. Briefs you. |
| `/mr-fox-status` | One-liner: current milestone, status, blockers. |
| `/mr-fox-plan` | Start a new milestone: draft plan → Vikram reviews → confirm → branch. |
| `/mr-fox-plan-review` | Spawn Vikram against the current milestone plan. |
| `/mr-fox-audit` | Spawn all 7 post-milestone auditors immediately. |
| `/mr-fox-milestone-complete` | Mark done → spawn audits → CTO consolidated → generate docs. |
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

---

## Repository Structure

```
mr-fox-os/
├── SKILL.md                    # Skill entrypoint — Mr Fox's core identity and lifecycle
├── CLAUDE.md                   # Cross-platform bootstrap via @SKILL.md import
├── references/
│   ├── infrastructure-setup.md # First-run setup — creates all templates
│   ├── plan-template.md        # Milestone plan template
│   └── agents/                 # Full specialist definitions and invocable skill files
│       ├── plan-reviewer.*
│       ├── security-auditor.*
│       ├── project-manager.*
│       ├── system-architect.*
│       ├── founder-strategist.*
│       ├── software-engineer.*
│       ├── ux-designer.*
│       └── devops-engineer.*
```

---

## Platform Compatibility

| Platform | Auto-boot | Slash commands | Subagents | State files |
|---|---|---|---|---|
| Claude Code CLI | via skill | `/mr-fox-*` | `.claude/agents/` | `.claude/` |
| VS Code (Claude extension) | via CLAUDE.md | `/` menu | `.claude/agents/` | `.claude/` |
| Cursor | via CLAUDE.md | `/` menu | `.claude/agents/` | `.claude/` |
| Claude.ai (web/desktop) | via CLAUDE.md | natural language | `.claude/agents/` | `.claude/` |

---

> Built by Abheejit Khandagale. Mr Fox OS v1.2.0.
