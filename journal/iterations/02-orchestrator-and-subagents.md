# Iteration 2 — The main session orchestrates; subagents implement, test and review

**Hypothesis check:** *confirmed, refined on where and when.* The design is as hypothesised (Opus implementers from
written specs, Sonnet verifiers, Opus reviewers reading diffs from files, the main context kept small). The
history differs in three ways. (1) It **started in hit_list on 2026-10-15 afternoon**, from one sentence of Michael's,
not with Pathways `cd3eacb`. (2) It **ran for real in dj-crate-streaming on 2026-10-16** (M6–M8,
"subagent-driven", with Opus or Sonnet chosen **per task** in the plans). (3) In **Pathways it was never run**:
`cd3eacb` (09:44) wrote the orchestration rules, and `889f5fe` (21:11 the same day) replaced the loop with the
harness before T0 started.

## Dates

- 2026-10-15 ~16:17–16:40: first traces in the Pathways loop ("Opus implementer" for the Mixxx spike, "Sonnet tester"
  for the M4 headless re-check). No instruction is recorded there.
- **2026-10-15 17:39–20:10: hit_list**, the first explicit and sustained use.
- **2026-10-16 01:05–21:18: dj M6–M8** (OVERNIGHT-2), subagent-driven.
- **2026-10-16 09:44: Pathways OVERNIGHT-3** runbook (`cd3eacb`), the written-down version; never executed.

## Context

- Iteration 1 worked but hit three walls: usage limits across parallel loops, a loop thread running out of context
  after three milestones, and Opus reviews being the step that kept finding real bugs.
- One thread per milestone (1.5) had made each thread short, but it needed Michael to paste a handoff every milestone.

## Trigger

- **Context.** "context usage too high" (ON2, 2026-10-15 ~08:50), and the M0–M3 thread "ran out of context" (HANDOFF-M4).
  ON3 states the goal directly: "Keep your own context small… Do not read large diffs, transcripts or screenshots
  yourself when an agent can report the conclusion."
- **Model cost and limits.** Opus hit usage limits mid-night (ON2, HL-RB). Splitting work by model (Opus where
  judgement matters, Sonnet for tests, docs and simplify angles) spends Opus only where needed *(inferred)*.
- **The direct ask** (HL-RB, 2026-10-15 afternoon): "delegate implementation to an Opus subagent and testing to a
  Sonnet subagent, each with a clear spec."

## Design

| Part | What it was |
|---|---|
| **Memory** | Unchanged: the runbook (`OVERNIGHT*.md`) is the memory; the Status log is what Michael reads. dj adds per-milestone ledgers in `.superpowers/sdd/` (git-ignored; ON2 16:15). Plans carry "rulings that bind" later milestones (M8 plan: "Rulings that bind M8: the M6 ledger…"). |
| **Discipline** | Same superpowers set; plans now say "REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended)". **Gates re-run by the orchestrator** (hit_list: "gates re-run here"; ON3: "Verify every claim with one cheap command… before ticking a box"). RED tests written first by a separate agent (hit_list). |
| **Models** | **Opus**: implementation of risky code, every whole-milestone review, `/simplify` cleanup. **Sonnet**: RED tests, headless/verification passes, the four `/simplify` reviewer angles (hit_list), docs and mechanical tasks. dj M7/M8 plans give the reason per task, e.g. "(model: **Opus**: the one code path that deletes)", "(model: **Sonnet**)". |
| **Roles** | **Orchestrator / controller** (main session): plans, writes each subagent's spec, dispatches, verifies, logs, commits. **Implementer** (Opus): "a written spec in the scratchpad: goal, files to read first, exact behaviour, tests to write first, what not to touch, a timebox, report ≤ 300 words". **Tester** (Sonnet): "told what to test and why, what PASS looks like, the scratch DB… and port". **Reviewers** (Opus): "read the diff from a file in the scratchpad… and return findings only". "Never two agents on the same files." |
| **Michael** | Answers the design questions himself (Pathways §11, dj ownership pass), then hands off implementation. He still approves deploys, merges and the first real download. |

## How it was prompted

- [2026-10-15 — "delegate implementation to an Opus subagent and testing to a Sonnet subagent"](../evidence/prompts/2026-10-15-delegate-opus-sonnet.md)
- [2026-10-16 — dj "Let's do this before M6/M7 and make the plan align"; per-task models in plans](../evidence/prompts/2026-10-16-dj-ownership-direction.md)
- [2026-10-16 — Pathways OVERNIGHT-3: Michael's §11 answers and the Orchestration section](../evidence/prompts/2026-10-16-pathways-overnight3.md)

## Evidence

- **hit_list, 2026-10-15 17:39–20:10:** 40 commits; tests **220 → 374** (37 suites), CI green. Each item is
  logged as "RED tests by Sonnet, code by Opus, gates re-run here"; Opus reviews found, for example, a Critical layout
  bug Jest can't see (S2: "the chip row would take about half the Spots screen") and a library bug that hid map
  clusters (S1).
- **dj, 2026-10-16:** **108 dj commits**; suite **256 → 785** (ON2 Status log 16:15) → "about 1,100 tests" (dj
  README). M6 live (worker container, approvals, beets filing). M7 "reviewed twice on Opus", "4 Important + 1
  Important in round 2". Read-only identity proposal over 831 files: "confirmed 77, isrc 172, search 239, ambiguous
  116, conflict 24, none 203". M8 Tasks 1–4 by 16:15, play-now and proposals by ~20:45.
  Plans: `docs/plans/2026-10-16-m7-identity.md` (`48d8050`), `…-m8-lifecycle.md` (`d4c1000`).
- **No `HANDOFF-M7.md` or `HANDOFF-M8.md` exists**, although the M6 handoff protocol required one at each milestone
  end. *(inferred: with subagents doing the work, one controller thread lasted M6 → M8.)*
- **Pathways:** `cd3eacb` ON3 "### Orchestration (this session is the orchestrator)"; queue T0–T7 all unchecked;
  `889f5fe` "Driver (changed 2026-10-16): the long-running harness… replaces the self-paced `/loop`."

## What worked / what broke

**Worked**
- Throughput: hit_list +154 tests in ~2.5 h; dj 108 commits and roughly 4× the test suite in one day.
- Michael's design input moved earlier and got sharper (ownership-of-facts doc before M6; his own quoted answers on
  threads). The agents built from written specs.
- Matching model to risk in writing ("Opus: this is the one code path that writes library tags") makes the
  delegation reviewable.

**Broke / limits**
- **Permission walls, not context walls.** "`docker compose up -d --build crates worker` was denied by the classifier
  ('production deploy'), so the live images predate M7" (ON2 16:15; `971f6a7`). Merges and branch deletes are also
  blocked for agents (`889f5fe` Needs Michael).
- **Still one session holding the loop.** A crash, limit or compaction of the orchestrator still stops everything.
  Pathways' answer the same day was a harness that runs a fresh session per feature (iteration 3, out of scope here).
- **Design churn upstream of the code.** dj's queue was rewritten on 2026-10-16 and then pivoted by a later spec
  (`2026-10-17-amperfy-pivot.md`, commit `328eca5` on 2026-10-16 21:17), which superseded D15/D16/D17/D21. Fast
  delegated building made the cost of a wrong spec bigger *(inferred)*.

## Led to

The same day, Pathways moved from "one orchestrator session in a `/loop`" to `harness/run.sh`: an initializer session
turns the runbook queue into `harness/feature_list.json`, and then "one **fresh coding session per feature** (Opus or
Sonnet, set per feature)" runs until all features pass or 8 h are up (`889f5fe`). Iteration 3 is covered elsewhere.

## Questions for Michael (from memory)

1. What made you ask hit_list's loop to delegate on 2026-10-15 afternoon: the 08:50 context problem in dj, the
   usage limits, an article, or watching review subagents work?
2. Did you tell the Pathways loop the same thing? Its "Opus implementer" and "Sonnet tester" show up around 16:17–16:40
   with no recorded instruction.
3. Was dj M6–M8 (2026-10-16) one controller thread, or several? Was it under `/loop` or interactive with you present?
4. Why was OVERNIGHT-3 never run as a loop? What happened between 09:44 and 21:11 on 2026-10-16 that made you build
   the harness instead?
5. Did splitting by model actually change your usage? Do you remember hitting limits on 2026-10-16?
