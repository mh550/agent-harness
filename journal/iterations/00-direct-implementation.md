# Iteration 0 — Direct implementation (the model builds and tests, Michael reviews and answers)

**Hypothesis check:** *partly confirmed, refined.* Fable was the model (the transcript banner says "Fable 5.1 ·
Claude Max"), and it wrote and tested the code itself. Three things differ from the hypothesis:
(1) the work was already spec-first (`ideas/<project>/spec.md · research.md · decisions.md`, Michael answering
inline); (2) Pathways Phase 1 came out of an **"autonomous session"**, not a long back-and-forth; (3) the model was
already sending research to **background subagents**. The repos record **no token or context limit** in this period;
the first recorded limits come on 2026-10-14/15 (iteration 1).

## Dates

- Prelude: 2026-02-12 → 02-14 (hit_list, laptop: spec + "Sprints 1–4").
- Main: **2026-09-17 → 2026-09-23** (ideas, Pathways Phase 1, DJ crate layer, Flyer).
- Ends 2026-10-13 02:25, when the laptop session writes the desktop handoff and the first overnight runbook (`27efc89`).

## Context

- Solo builder, ~10 h/week, "both personal utility *and* portfolio/career" (`ideas/ROADMAP.md`, "Michael's inputs
  (2026-09-17)"). Laptop with WSL2 (`HANDOFF.md`: "the Claude session on Michael's laptop (WSL2)").
- Five ideas live in `~/projects/ideas/`, each with `spec.md` (source of truth), `research.md`, `decisions.md`
  ("Michael answers open questions inline in this file", `ideas/README.md`).
- One board for all projects, `ideas/PROGRESS.md`, with a session log written by Claude ("Updated by whoever works
  on the projects (Claude sessions included)").

## Trigger

None recorded. This is the starting point. *(inferred)* The February hit_list work (a spec "refined… ambiguity
resolved through discussion", then four sprint commits in 8 minutes on 2026-02-13) suggests the spec-then-build
habit came before Fable.

## Design

| Part | What it was |
|---|---|
| **Memory** | The `ideas/` docs plus `PROGRESS.md` session log; per-repo `docs/STATUS.md` "review guide" (Pathways). A conversation transcript was kept once (`ideas/dj-crate-streaming/convo-1.txt`). Backups of `ideas/` before an autonomous run (`backups/ideas-backup-20260917-220513/`, with a one-line revert command in PROGRESS.md). |
| **Discipline** | Tests and a headless-browser pass before claiming done (Pathways STATUS "Validation performed"); a "Gaps — things only you can resolve" list; "Per Michael's request, **no code until he's read it.**" (Flyer, PROGRESS 2026-09-17). No superpowers skills named in any committed doc of this period. |
| **Models** | Fable 5.1 on Claude Max (convo-1 banner, `/model` "saved as your default"). |
| **Roles** | One session = researcher + architect + implementer + tester. Research fanned out to 4 background agents (convo-1: "Next I'll launch four research agents… while I review the existing Pathways stack"). Michael = reviewer, decision-maker, learner ("to be close to the 'ground truth' as opposed to just an overseer"). |

## How it was prompted

- [2026-09-17 — DJ Phase 0 clarifications, then "use your best judgement"](../evidence/prompts/2026-09-17-dj-phase0-clarifications.md):
  numbered review notes, a docs-update instruction, then permission to implement.
- [2026-09-17 → 09-23 — Flyer, answered inline in decisions.md](../evidence/prompts/2026-09-23-flyer-inline-answers.md):
  question rounds, including the one that ended the project without code.
- The Pathways Phase 1 "autonomous session" prompt is **not recorded**. PROGRESS.md says only "Continued per the
  roadmap".

## Evidence

- Pathways Phase 1: `6b38e83` 2026-09-17 22:18, 24 files / 2,204 lines (graph store, notes importer, editor UI,
  CLI) + `9dfe745` 22:25 (README, STATUS, 5 screenshots, 24 playwright snapshots). **30 tests.** STATUS.md:
  "Date: 2026-09-17 (autonomous session)", "Phase 1 landed as one commit plus follow-ups".
- DJ: `71536d1` 09-17 22:33 sourcing prototype; `0fdf5de` 09-18 00:07 crate layer, "27 new tests" (35 total);
  `d7f1812` 09-18 00:28, 37 tests, Dockerfile built and served.
- convo-1.txt: turn 1 "Churned for 20m 20s", turn 2 "Baked for 3m 49s"; 4 subagent research briefs come back
  inside the transcript ("[Subagent hand-back]").
- Flyer: five decision rounds 09-17 → 09-23, ending "resolved without a build" (ROADMAP "Flyer — closed without a build").

## What worked / what broke

- **Worked:** big, fast single-session builds (2,204 lines + 30 tests in one commit); research in parallel while
  coding; docs Michael could review from a "Review in 10 minutes" block; questions that killed scope (Flyer).
- **Broke or stayed open:** built against invented data. STATUS.md: "Everything above was built against the spec's
  one example plus my reconstruction… **This is the #1 next action.**" (real notes; still in Needs Michael on 2026-10-16).
  Every session needed Michael present to start it and answer questions.
- **Not visible in git/docs:** any token, context or usage limit in this period. HOME-SETUP.md (2026-10-13) turns
  auto-compact **on** for the desktop "(a long night outgrows the context window)", which shows the concern was
  anticipated. It does not show it was hit.

## Led to

Iteration 1. On 2026-10-13 the laptop session moved everything to the home desktop and wrote `OVERNIGHT.md`, the
first runbook for an unattended self-paced `/loop` (`27efc89`). *(inferred)* The pull was hardware and time (an
always-on box, "Michael is asleep or away"), plus the projects' new need to run services (Navidrome, slskd) on that box.

## Questions for Michael (from memory)

1. Did you actually hit token, context or usage limits in September? On which session, and what did you see
   (compaction, "context low", a plan limit)? The repos record none before 2026-10-14.
2. What did you type to start the 2026-09-17 "autonomous session" that built Pathways Phase 1? How long did it run,
   and were you watching?
3. Why did you commit `convo-1.txt`? Was it a context-saving trick (a transcript to hand the next session) or a record?
4. What model and tool built hit_list in February (the four sprint commits in 8 minutes on 2026-02-13)?
5. Was the move to an unattended overnight loop driven by limits, by your time, or by the new home server?
