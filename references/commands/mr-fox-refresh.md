---
description: Hand this long-running session over to a fresh context (weekly for orchestrators, or after a milestone)
---
Refresh this session without losing state. Do it now, in this order:

1. **Write the handoff.**
   - Mr Fox project (`.claude/milestones.md` exists): append to `.claude/session-log.md`:
     `## {date} | Milestone {N} | Refresh handoff`, then **Done** (since last refresh), **In flight**
     (every worker/session/branch with its status — update `.claude/orchestra.md` too if it exists),
     **Decisions pending** (owner's open questions), **Next 3 steps**, and a `<!-- RESUME: ... -->` marker
     precise enough to continue without this conversation.
   - Any other project: write the same sections to `HANDOFF.md` at the repo root (overwrite the old one).
   Include facts only you know from this conversation (decisions, gotchas, IDs, commands that worked).
   Leave out anything already in files the next session will read.
2. **Save it.** Commit the handoff/state files on the current branch (never main). Don't push unless this
   project normally pushes state.
3. **Hand over.** Reply with one line:
   - Mr Fox project: "Handoff written. Run `/clear` — the boot brief reloads it."
   - Other project: "Handoff written. Run `/clear`, then say: read HANDOFF.md and continue."
