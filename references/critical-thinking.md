# Critical Thinking Checkpoints

Source: Addy Osmani, "Critical thinking when agents do the work" (Nov 3, 2026).
Core idea: agents make output cheap and polished, so nothing forces you to think. Build the checks in. You can offload the work and much of the auditing, never the accountability.

Load this file at three gates: **plan lock**, **before declaring a milestone complete**, and **whenever Abheejit is about to approve something he cannot explain**.

---

## The spectrum (name where we are)

| Level | What it looks like | OK when |
|---|---|---|
| Offloading | Delegate the task, keep ownership of the result | Always |
| Deferral | The agent's output becomes the next input; no longer a hypothesis | Stakes are low |
| Surrender | Output quietly becomes yours; no check | Only where being wrong is cheap |

**Test:** if Abheejit cannot explain the answer, even with an agent's help, ownership has been ceded. Hotel pick: delegate. Architecture, money, safety to ship, what users are affected: keep the reasoning.

---

## Gate 1: Plan lock (before coding)

Mr Fox asks Abheejit, and records the answers in the plan:

1. **Hypothesis**: what do you think the answer or approach is, before I propose one? (A bad guess is fine. If none, run a *blind spot pass*: share what is known and have the model surface unknown unknowns.)
2. **Think or offload?** Is this me helping you think, or taking thinking off you? Either is fine, but say which.
3. **Definition of "verified"**: what tangible artifact ends this work (passing test, screenshot, log, trace)? Fixed now, because afterward any outcome gets rationalized.
4. **What would make this wrong?** Name the test that would show it, not the model's confidence.
5. **Counter-argument**: for any hard stance on something open-ended, get the opposing case from a different angle before committing.

Intent debt guard: Abheejit writes the request brief in his own words (audience, out of scope, definition of done). If two correction rounds have not landed it, stop tweaking and rewrite the brief. If it is fuzzy, Mr Fox interviews him instead of filling gaps silently.

---

## Gate 2: Milestone complete (before merge)

Run in this order:

1. **Evidence before summary.** Show the command that ran and its output first. Read the summary last.
2. **Green check audit.** For every passing check: what did it prove, and what did it not? A test written with the same mistake as the feature will pass.
3. **Decisions ledger.** Ask the agent to list the decisions and assumptions it made for us: defaults, scope calls, which requirement it reinterpreted when two clashed. Summaries that say "all went well" hide these.
4. **Read the diff as if the AI did not write it**, then look past the diff at what was decided.
5. **Quiz.** Pick a few random lines and ask what each does and why. For a document, close it and state the main argument from memory. Optional strict mode: the milestone report ends with a short quiz and merge waits for a perfect score.
6. **Source spot-check** for non-code work. If an agent synthesized calls, research, or a competitive analysis, open a couple of source documents and recompute one number the recommendation depends on.
7. **Did I miss anything?** Ask once more at the end. It often returns two or three more items.

Rule of thumb: *if you cannot say what the checks would miss, ask for a real review rather than a quick approval.*

---

## Gate 3: Bar for shipping

- Would I bet on this in front of the person who has to maintain it?
- Would I put my name on it? Polish is no longer a signal, since everything arrives formatted and confident.
- Can I defend it if someone asks?

If any answer is no, it does not go out. When something misses the bar, record why in shared config, a hook, or a test so it does not recur. That is how taste compounds.

---

## Orchestration tax (volume check)

If finished work piles up faster than Abheejit can stand behind it, another session does not help. Tighten the checks so less needs him, or slow down. Producing more than you can stand behind means hoping, not reviewing.

Agents may narrow where attention goes (triage, flag guideline violations). They do not decide it.

Handoff hygiene: when agents chain, the third agent must read the original document, not just the previous agent's summary.

---

## Staying calibrated (periodic, not every session)

- Weekly: do one real thing without an agent that would hurt to forget.
- Monthly: write down what has stopped being practiced and decide which of it is intentional.
- Schedule checking as a line item; it is real work, not free.
- Ask: how lost would I be if AI did not exist?

---

## One-line version

Before asking, write what you expect. After the agent finishes, write one thing it did not check.
