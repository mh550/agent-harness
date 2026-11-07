# Handoff: the memory curator's follow-up — for a fresh orchestrator session (2026-11-07, 16:40)

*Written by the walkthrough session that taught Michael the memory curator design and took his answers to the run's
nine questions. The orchestrator session reads this first, then decides how the follow-up is planned and sequenced
against the run in flight. Nothing here is started; the orchestrator gives Michael commands, he pastes them.*

## 1. State on the box right now

- **The memory curator is built and on `main`**: run `agent-harness-2026-11-07-2` (M1 one writer PR #125, M2 the curator
  PR #126, M3 the gate and `MEMORY_POLICY` PR #127, record PR #128), 12/12 first attempt, $59.51, 4.3 h, suite
  1,721 → 1,791. `MEMORY_POLICY=pr` is the default: the curator's tier-1 facts go to a `memory: <run>` PR left for
  Michael; nothing is applied to a project file without him. **The curator has not run yet**: that run's `finish` ran
  the driver it started with (the live checkout syncs only when no run is alive).
- **One run is alive: `agent-harness-2026-11-07-3`**, the harness side of the n8n events spec
  (`docs/specs/2026-10-22-n8n-events.md`: A1 the event hook with an ntfy fallback, merged PR #129; A2 the context bundle
  and ID glossary, 3/5 at 16:30; A3 the request inbox that turns n8n's verbs into `harness answer` / `harness queue add
  --continue`; A4 docs). 14 features, $27 and 6/14 at 16:30. The live checkout synced to the memory code before it
  started (15:28; `main` had M3 at 15:05), so **this run's `finish` is the first real curator run**, under `pr`: expect
  a `memory: agent-harness-2026-11-07-3` PR on this repo's `CLAUDE.md` (97 lines, 14 Gotchas, under the cap) and the
  first row of `ledger/memory.jsonl` (`harness memory` lists it). Michael's n8n-home side of the events spec is live
  (`mh550/n8n-home`, its own deploy protocol: never from an agent-harness session).
- **The queue runner is going**, `MAX_PARALLEL_RUNS=2`, queue empty, but a second run of the same project is held until
  the first ends (`decisions/2026-10-21-queue-one-run-per-project`): a memory follow-up run on agent-harness waits for
  the n8n run.

## 2. What Michael decided today (the record is on `main`)

- **`journal/learning/2026-11-07-memory-curator.md`**: the design, the whys, the narrative, the measurement points and why
  each (§10), the nine answers (§11), his reasoning trail (§12), the follow-up list (§13), provenance of every choice.
- **One `Updated in place 2026-11-07: Michael …` line per question** in `journal/decisions/2026-11-07-memory-one-writer.md`,
  `-memory-tiers.md` and `-memory-policy.md`. (The run's `harness needs` items were collected with its state; the
  decision files are the record.)

The answers in one table:

| # | question | answer |
|---|---|---|
| 1, 4 | tier 2 (conventions, workflow) body-only or a commit | **its own branch and PR**, a diff Michael merges, counted separately; `auto` never reaches it; tier 3 stays text |
| 2 | the M3 review's model | handled in another session; Opus stays the default for reviews |
| 3 | guard `.claude/CLAUDE.md` too | **yes** (check whether `.claude/rules/*.md` loads the same way) |
| 5 | the cap on an over-cap file | **default** (improve, not grow); **todo: prune the three over-cap files by hand** |
| 6 | may a `proposed_changes` string land in Gotchas | **default**: never |
| 7 | a deny list on the curator session | **build it** (`Bash(git push:*)`, `Bash(gh:*)`) |
| 8 | `auto` merges after a failed body refresh | **flipped**: skip the merge, leave the PR open |
| 9 | the decisions-store lint with no suite successor | **default** |
| 10 | tier 1 auto-apply at all | **`pr` stays default**; `auto` earned per project on `harness memory`'s count; approval one click from the n8n/ntfy flow |

His direction, in his words' sense: as hands-off as possible over time, with visibility before any switch to `auto`;
graduation by evidence (the acceptance counter, extended to tier 2 per section), never by loosening the tiers; one-click
approvals through the n8n review flow rather than more manual work.

## 3. The follow-up work (learning file §13), grouped by where it lands

**A. Harness code, one spec's worth (agent-harness, a harness run):**
1. Tier 2 on its own branch and PR (`harness-memory/<run>/rules` or similar), `harness memory` counting it separately,
   `auto` never touching it (reworks `memory_pr` in `lib/record.sh` and the M3 counter).
2. `.claude/CLAUDE.md` (and `.claude/rules/*.md` if Claude Code loads it) in `restrict memory` and the curator's `FILES`.
3. The curator session's deny list, passed by the driver.
4. `MEMORY_POLICY=auto` skips the merge after a failed `gh pr edit`, leaves the PR open with one note.
5. `capCheck` per-op: apply the ops that fit, drop the breaching ones with the reason (today `apply` drops the whole
   tier-1 commit, `lib/curator.mjs` `apply`).
6. An accept / decline verb with `--why` for tier 2 and 3 proposals (`harness memory accept|decline <run>/<n>`), the
   `--why` fed to the next curator so a rejected rule is not proposed again.

**B. The review surface (touches both repos):**
7. The memory PR's notification carrying the tally (`merged unchanged a · edited b`) and merge / decline actions; the
   n8n run-review card showing the memory PR's ops (applied, proposed, dropped with reasons) beside the record PR. This
   sits on the n8n events spec in flight: A1's event hook can carry a `memory_pr` kind, and A3's request inbox is where
   a "merge the memory PR" verb would land. The contract there is v1 and n8n-home builds to it, so a new kind or verb
   is a contract change (a new `v`), and the n8n-home half is a change to a live project under its own protocol.

**C. Measurement (harness, after A):**
8. The recurrence metric from the entries (a fact that landed still appearing in later runs' `dead_ends` /
   `discoveries`); then acceptance per tier and per section.

**D. Design, later:**
9. A project-start review of pending proposals by the initializer; a cross-project memory desk de-duplicating a rule
   several projects proposed into `~/.claude/CLAUDE.md` or the prompts.
11. A jev-style classifier (a decision model Michael named: cheap judgment, not text) for model routing and
    fact-or-rule scoring, above the gate, never as the gate.

**E. By hand, Michael with a session in each project (any time, before a curator run on that project):**
10. Prune `hit_list` (181 lines, 15 Gotchas), `n8n-home` (134) and `portfolio_site` (127, 15 Gotchas) under the
    120-line cap: stale Gotchas out, general facts up to `~/.claude/CLAUDE.md`, duplicates collapsed. The curator can
    only trade line-for-line inside an over-cap file, so it will work inside a bad shape until this is done. Not urgent
    for the n8n run's curator pass (agent-harness is under the cap).

## 4. Where this lives in the effort

The memory curator is **piece F3** of the test-suite redesign effort (`docs/plans/2026-11-03-test-suite-redesign-dispatch.md`,
Status row F3 and Decision 4). Its row still says *proposed (Michael to confirm)* and *spec, then a harness run*: the
spec (PR #123) and the run (#125–#128) have happened, and the row has not been updated. The orchestrator decides
whether the follow-up is new rows of that list (F3b the code, F3c the prune, F3d the review surface) or its own effort;
either way F3's row needs its result and today's decisions.

## 5. What the orchestrator is asked to figure out

1. **Sequencing against the n8n run.** The code (group A) is one agent-harness run and must wait for
   `agent-harness-2026-11-07-3` to end (or be queued behind it: `harness queue add`). The spec can be written now, in a
   `claude` session, from §13 of the learning file and the three decision files. Does the review surface (group B) go
   into the same spec, or wait for A3's contract to land and then become a v2 of the events contract with its n8n-home
   half as a separate piece on that live project?
2. **One spec or two.** Items 1–6 are coherent and small (a half-day run; each is a few functions plus checks). Item 8
   is separate (reads the ledger and entries, no driver change). Item 7 crosses repos.
3. **The first curator PR.** When the n8n run ends, a `memory: agent-harness-2026-11-07-3` PR appears. Michael wants to
   see it, judge it, and have that judgment counted (`harness memory`). Put the one command to list it, and the merge
   or close, under what is his to do.
4. **The prune (E).** Three hand sessions, one per project, from a session in that project's directory. Propose when,
   and whether a short checklist for those sessions is worth writing.
5. **Keep the measurement points honest.** The learning file §10 says which numbers decide `auto`: `merged unchanged`
   per project (about five earns it), the drop/refuse rate per rule, recurrence. A plan row that promises a memory
   improvement should name which of these it moves.

## 6. Rules that bind the orchestrator here

- The user's and this project's `CLAUDE.md`: work only in a worktree; never touch real runs or real state; start,
  continue, queue, answer, stop and merge are Michael's (`harness status`, `report`, `needs`, `queue list`, `memory` are
  read-only and fine); never a real notification; no `~/.claude` edits; one decision file per behaviour change;
  `docs/architecture.md` and `README.md` in the same milestone as the code.
- n8n-home is live: nothing there from this repo's session; a piece on it is a session in that project under its
  `## Live system` protocol.
- Plain names (the supervise skill's rule): say what a piece is, then its code.

## 7. Pointers

| what | where |
|---|---|
| the walkthrough's record, the answers, the follow-ups, provenance | `journal/learning/2026-11-07-memory-curator.md` |
| the three memory decisions, with today's lines at the end of each | `journal/decisions/2026-11-07-memory-{one-writer,tiers,policy}.md` |
| the spec the run built | `docs/specs/2026-11-07-memory-curator.md` (PR #123) |
| the run's record (plans, reviews, retro, needs) | `.harness/runs/agent-harness-2026-11-07-2/`; `docs/plans/2026-11-07-M{1,2,3}-*.md` |
| the curator's rules and CLI | `lib/curator.mjs`; `curator()` in `lib/driver.sh`; `memory_pr`, `memory_guard`, `restrict` in `lib/record.sh`; `lib/memory.sh` |
| the n8n events spec the live run builds | `docs/specs/2026-10-22-n8n-events.md` (contracts §, A1–A4); its n8n side `mh550/n8n-home` `docs/specs/2026-10-22-harness-reporter.md` |
| the effort's dispatch list | `docs/plans/2026-11-03-test-suite-redesign-dispatch.md` (row F3, Decision 4, Log) |
| the research | `findings-and-research/Agent Memory Field Guide.md` |
