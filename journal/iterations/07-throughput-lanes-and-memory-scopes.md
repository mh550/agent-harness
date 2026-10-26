# Iteration 7 — Throughput: measure first, then parallel lanes, a split suite and memory with scopes

**Dates:** 2026-10-25 → in progress. Written 10-26 at 13:30 EDT. At that point the retro run is at 12/12 with its last
verify still to run, and the lanes run is blocked, waiting on its continuation.
**Sessions:** five interactive sessions and four harness runs. The sessions:
- the status check that turned into a measurement (10-25 14:23 → 16:32);
- the design session (10-25 22:00 → 10-26 12:59);
- two morning status checks;
- the chunk 4/5 sessions that queued the first run.

[`sessions/2026-10-25-throughput-design.md`](../sessions/2026-10-25-throughput-design.md) has my messages verbatim
and what came out of each.
**Plan of record:**
- `docs/specs/2026-10-25-throughput-and-memory-design.md`: the design, approved;
- `docs/plans/2026-10-25-throughput-rollout.md`: the order, with my six decisions;
- the build specs `docs/specs/2026-10-26-lanes.md` and `2026-10-26-suite-split.md`;
- `~/Downloads/harness-master-todo-2026-10-26.md`: my paste-ready commands, kept outside the repo.

## Context
Iteration 6 ended with fixes queued as three specs: resource lifecycle, then retro fixes, then memory. The queue started
at 11:50 on 10-25 with the first of them, and it worked:
- **`agent-harness-2026-10-25-lifecycle` built L1–L5 and ended `done` at 02:50 on 10-26.** It passed 25/25, and all
  five milestones were verified and merged by the harness itself (PRs #19–#21, #25, #26). The first-attempt pass rate
  was 1.00, with no rework and no failed verify. It cost **$83.17** ($3.33 per feature) and ran **15 h** over 32
  sessions. What it built:
  - L1: a memory-capped systemd scope for every session and suite run (6 GB and 3 GB), plus a memory gate before
    each session.
  - L2: the run's services stop at every stop point.
  - L3: scratch is deleted at the end of a run, and a tmux reaper closes finished runs' sessions.
  - L4: the queue runner runs `harness gc --all-merged --deps` itself.
  - L5: the runner re-reads its config on every poll.
  - Each change has a decision file: `decisions/2026-10-25-*` and `2026-10-26-gc-unattended-guards`.
- **The box stayed healthy.** The night of 10-25/26 had **no real OOM kill**, against 10 in the week before
  iteration 6. The kernel logged 136 kills, and all of them were inside the suite's own deliberately tiny 64 MB test
  scopes. The largest session peak was 3,855 MB (rane-one-mixxx, M6-03), under the 6 GB cap.

So the harness was now safe to run longer and wider. It was also slow. The lifecycle run was at 4/25 when I checked
at 14:23 and at 9/25 at 16:22. Two more agent-harness runs, retro and memory, waited behind it, a night each.

## Trigger
At 16:25 on 10-25, watching it crawl, I asked how to speed up the next runs, "considering good design principles that
scale and would work into the future… and avoid creating duplicate/cleanup work"
([prompt](../evidence/prompts/2026-10-25-improve-parallelization.md)).

**My expectation going in:** more runs in parallel. Runs had been serial since D-H18 (10-17), when two runs used up
the five-hour usage window in 2 h 49 min, and `MAX_PARALLEL_RUNS` was the obvious setting to change.

## Diagnosis: measure before parallelizing
The session measured first, read-only, and the setting I expected to change turned out not to matter:

| Suspect | Measured (10-25 afternoon) |
|---|---|
| Usage limits | **Not limiting.** The five-hour window was at 12 %, and the seven-day window moved from 82 % to 83 % in 4.5 h. D-H18's reason no longer held. |
| `MAX_PARALLEL_RUNS` | **Irrelevant to these runs.** The queue allows one run per project, and all three were agent-harness runs. |
| The driver | **Serial inside a run.** The dependency lists already marked milestones as independent (lifecycle L3–L5; retro F1–F3; memory M1, M2, M5, M6), yet none of them ran side by side. |
| The harness's own suite | **About 8 min, single-threaded**: some 270 checks in one 1,078-line `tests/run.sh`. Suite runs took 8–19 min of each 17–30 min session. L2-01 only wrote a plan and still spent 19 of its 28 min in the suite. Lifecycle session time split into model 40 %, suite 31 % and other tools 26 %. |
| Merge conflicts in waiting | `tests/run.sh` was the most-changed file since 10-17 (47 commits), so parallel branches would collide on it. |
| Merge bookkeeping | Each run had one linear branch, so a milestone's tag carried earlier milestones' unverified work. The `tainted`/`held` rules and list-order merging existed only to cope with that. |
| Memory | 15 GB box. L1's caps (6 GB a session, 3 GB a suite, a 5 GB free floor) fit two sessions at once. |
| Verify context | 25–29 items were left out of every verify pack, because the whole milestone was squeezed into a pack sized for coding. |

**Root cause:** the harness was **serial by construction, not by necessity**. It had one branch, one worktree and one
suite file per run. Every session's longest wait was the harness's own test suite. The model and the usage limit
weren't the bottleneck.

## Design (approved 10-26 00:05)
At 22:00 I asked for the recommendations to be built, and I set the constraints
([prompt](../evidence/prompts/2026-10-25-parallel-without-new-work.md)):
- more parallel, less redundant and faster;
- "a system that doesn't create more work — so avoids messy manually-fixed merge conflicts, orphaned worktrees and
  branches, and orphaned data";
- more targeted testing;
- memory designed by CoALA bucket and scope, "an architecture that will grow with me".

Three minutes later I added: plan the order, account for the runs in flight, and prepare now whatever shortens the
turnaround.

The design has three parts. Its goals name two invariants every part has to keep: **what lands on `main` is byte for
byte what was verified**, and **the driver is the only writer of refs, merges and the run record**. Its
**anti-goals**, failures even if the code works, are:
- a night that ends with a merge conflict I have to fix by hand;
- a lane worktree or branch left behind after a normal end;
- two writers of one record file;
- any relaxation that lets unverified code reach `main`;
- a memory rule that lives in two places.

### 1. Parallel milestone lanes
```
harness start ─► record worktree on harness/<run>   (the run record only; the driver is its one writer)
  ─► initializer (plans features and milestones, as today)
  ─► coordinator: open a lane for every milestone whose dependencies are verified,
                  within MAX_LANES and the memory / five-hour-window admission gate
       lane <m> = worktree slot k, branch harness-lane/<run>/<m> from main + its dependencies' verified tags,
                  own port, scratch, memory scope
                  features (serial) → verify → tag → PR → merge in dependency order → branch deleted, slot freed
  ─► finish: slots removed, one record PR (.harness/runs/<run>/ only), retro, ledger
```
- **A lane is one milestone:** its features, its verify and its merge. Code lives only on lane branches.
- **The record is single-writer.** Before a session, the lane copies the record into its worktree, and git ignores
  that copy in this worktree only. After the session, under one lock, the driver applies the session's `passes` flip
  and appends its inbox lines to the real record. It never copies the lane's file over the record.
- **Tags can't carry unverified work** (a tag is its base plus the milestone's own commits). So the taint, hold and
  list-order merge rules go away, and merges follow the dependency order.
- **`MAX_LANES=1` is today's behaviour in structure,** with no separate serial code path. Lanes open by headroom (free
  memory and the five-hour window) as well as by count.
- **"Main moved" without a wait.** Say lane A merges while lane B is being verified. Lane B merges `main` in. If the
  files `main` brought in are disjoint from B's, a green suite is enough, and B is re-tagged and merged. If they
  overlap, B gets one more verify round. A true conflict goes to me, as before.
- **Cleanup by construction.**
  - Worktree slots are reused from one milestone to the next (installs survive), and they exist only while the run
    is alive.
  - A lane branch lives only until its PR merges.
  - Every unit is named `harness-<run>-…`, so the lifecycle run's stop points and `gc` already clean it up. No new
    cleanup code is needed.
- **The run record reaches `main` through one record PR at the end of the run,** never inside a code PR.
- Lanes also cover most of R10 from the retro fixes: a given-up feature now stops only its own lane and the lanes
  that depend on it. The retro run shrank from F1–F3 to F1 and F2.

### 2. A split, parallel suite: a move, not a rewrite
- A script (`tests/split.sh`) cuts the one file at its existing `# ----` section markers into `tests/checks/*.sh`,
  with a shared `tests/lib.sh`. A **conformance check** against a fixture of check names proves that no check was
  lost. Every assertion stays byte for byte.
- The files run `TEST_JOBS` wide **inside the one check scope**, because systemd scopes don't nest and inner scopes
  would escape the 3 GB cap.
- Sessions iterate on one file (`check.sh 40-gc`) and run everything once before they flip `passes`.
- The suite's cache key ignores what the suite never reads (plans, the run record, the journal), so a plan-only
  feature no longer pays for a full suite run.

### 3. One memory model: CoALA bucket × scope
Every store gets one row: its bucket, its scope, its one kind of writer and its mutation rule. The full table is in
design §6. Condensed:

| Scope | Working (derived) | Episodic (append-only) | Semantic (in place) | Procedural (in place, reviewed) |
|---|---|---|---|---|
| Session | the prompt, `context.md` | transcript, metrics row, `entry.json` | none: it only *proposes* | none |
| Lane | — | lane notes, its metrics column | none (operational state, deleted with the lane) | none |
| Run | per-session context pack | `entries.jsonl`, `harness-log.md`, retro | `INBOX.md` answers, `passes` | the run's `brief.md` |
| Project | — | the run records, plans, specs | the decisions store, `## Gotchas` | `CLAUDE.md`, `.harness/*`, settings gates |
| Harness | calibration line, debrief pack | `ledger/runs.jsonl`, `journal/` | the retro backlog, `debrief.md` | `lib/`, `prompts/`, `decisions/`, `architecture.md` |
| User | — | — | — | `~/.claude/CLAUDE.md`, settings, harness config |

The rules that follow from the table:
1. **The bucket decides append or in place,** not the file type. Episodic stores only grow. Semantic stores are
   rewritten in place with a dated line.
2. **One writer kind per store.**
3. **Scope is declared, not inferred.** A discovery gains `affects: "project"`, and the context pack lists it under
   "Promote to Gotchas".
4. **Derive, don't store:** counts, calibration and the debrief are computed.
5. **Working memory has a budget per role.** Verify gets a 16 KB pack.
6. **Lanes add no store.**

How it grows: a new scope (a teammate, a second box) is a new column with the same four buckets. A new store must name
its bucket, scope, writer and rule before it exists.

### What was rejected, and why
- **More parallel runs as the speed-up.** It doesn't touch the bottleneck, and two runs on one project make
  conflicting PRs (`decisions/2026-10-21-queue-one-run-per-project`).
- **Running the post-session suite asynchronously** while the next session starts. Once a later session has built on a
  tree, it's no longer clear which session broke it. Lanes give the same overlap across milestones without that cost.
- **Having tests "adjusted automatically" by an LLM.** I asked this one myself. Tests encode intent, so they are
  procedural memory, and the session that builds a feature writes its test first. The deterministic version of the
  idea is kept as optional S4: each check file declares the source paths it covers, and the runner picks the files a
  change touches.
- **Parallel features inside a milestone.** Left for later. The design says what would make it safe.
- **A frozen legacy driver for runs started before lanes.** Instead, an old run with unmerged code is refused, with
  three ways forward printed.
- **An LLM curator, embeddings or a facts database for memory**, and a second scheduler between runs.

## How it was driven (the method)
- **A status question became a measurement session.** The 16:32 answer changed nothing. It only read and timed, and it
  ended with a question back to me: lanes before or after the memory run?
- **Design document first, then a cold review.** A fresh builder-check agent read the design and raised six
  questions. Four were settled from the code: merge gating under the `pr` policy, systemd scopes don't nest, slots
  instead of a worktree per milestone, and a per-worktree exclude. The other two became decisions for me. All of this
  happened before any code was written.
- **I approved with questions** ([prompt](../evidence/prompts/2026-10-26-approve-with-questions.md)). Why rewrite the
  tests at all? Is the CoALA bucket for tests right? How do we make sure the night has no blockers? And explain the
  decisions in the chat "as an early-career software engineer". The answer made the split a move rather than a
  rewrite and added S4. The decisions came back with their trade-offs, and I answered them in one message:

  | # | Decision | Chosen | Rejected, and why |
  |---|---|---|---|
  | 1 | Order | **A: lanes before the retro and memory runs** | B (retro and memory first on the serial driver): retro would build R10 only for lanes to replace it, and memory's four independent milestones would run one at a time |
  | 2 | How lanes get built | **as a harness run** (initializer, a session per feature, an independent verify per milestone) | two interactive sessions: faster, but the only verifier is me, on code full of locks, child processes and git refs |
  | 3 | The run record on `main` | **one record PR per run, merged, and its branch deleted by the runner's gc** | no record on `main` (the ledger as the only copy) |
  | 4 | rane-one-mixxx, parked at 9/19 since 10-24 | **answer M5-06 and continue it** on today's driver, ahead of lanes | let lanes refuse it later and re-plan it as a new run |
  | 5 | Merging after `main` moves | **the disjoint re-base** (disjoint files + green suite = still verified) | `LANE_REBASE=verify`: a verify session on every collision |
  | 6 | First lane night | **`MAX_LANES=2`** (a lane reserves 4 GB above the 5 GB floor, so a second opens at 9 GB free) | 3: it would mostly wait on memory |

  The rollout order and its reasons are in `decisions/2026-10-26-lanes-first-rollout`.
- **The harness builds its own parallelism.** Asked "is it possible/wise to add the lanes build to the harness now",
  the session made the suite split milestone **P0 of the lanes run**. That removed the one human step between the
  lifecycle run and the lanes run, so the whole chain could run unattended overnight:
  1. the lifecycle run;
  2. the rane continuation;
  3. lanes (P0 split, P1, P2);
  4. retro (F1 ∥ F2);
  5. memory (M1–M6).
- **A master to-do outside the repo,** in `~/Downloads`. It has paste-ready commands in the order to run them, and
  every decision is written next to the command it changes.
- **Merge conflicts are a scheduling input.** The memory run must come after lanes, because its M1 edits
  `lib/driver.sh`, which lanes' P1 rewrites.

## Evidence
- **PRs on agent-harness** (merge times EDT):
  - 10-25: #17 (journal, iteration 6, 01:23) · #18 (chunk 4: the three specs and the queue, 02:04) · lifecycle L1–L3
    #19 (15:34), #20 (19:38), #21 (22:19) · #22 (the design and the rollout plan, 22:27).
  - 10-26: #23 (approval, the lanes and suite-split specs, the retro and memory amendments, 00:20) · #24 (answers
    recorded, the split folded in as P0, 00:46) · lifecycle L4, L5 #25 (02:08), #26 (02:49) · #27 (retro F1, 11:37).
- **The runs of the chain** ([night evaluation](../runs/2026-10-26-evaluation.md)):

  | Run | Window (EDT) | Result | Spend | Notes |
  |---|---|---|---|---|
  | lifecycle | 10-25 11:50 → 10-26 02:50 | **25/25**, all verified and merged | $83.17 | first-attempt 1.00, 32 sessions |
  | rane-one-mixxx continuation | 02:50 → 05:29 | **19/19** (from 9/19), tests 868 → 1,262 | $111.08 (whole run) | one `harness answer` unparked it |
  | lanes | 05:29 → 08:30 | **blocked on P0-02 at 2/17**, nothing merged | $22.87 | suite 589 s → 165 s, target was 150 s |
  | retro | 08:51 → running | **12/12** at 13:30, F1 merged (#27) | $35.25 so far | first-attempt 1.00 |
- **The suite:** 236 checks (10-24) → 325 (after L5) → 335 in **29 files**. A full run fell from **589 s to 165 s**
  with `TEST_JOBS=4`, peaking at 390 MB.

## What worked / what broke
**Worked**
- **Measuring before choosing.** The fix I expected, more parallel runs, would have changed nothing.
- **The lifecycle run.** It delivered 25 features in five verified milestones, merged them itself and needed nothing
  from me. Iteration 6's resource leaks are now fixed in code, not cleaned up by hand.
- **One answer unparked a stuck run.** `rane-one-mixxx-2026-10-24` had been parked at 9/19 since 10-24. With the M5-06
  answer and a continuation, it finished 19/19 overnight.
- **A cold reviewer before code.** The builder check caught six design gaps.
- **The "move, not rewrite" call paid off the next day.** When retro's checks collided with the split, the fix was to
  re-run the same deterministic script, not to hand-merge 335 checks.

**Broke**
1. **A soft target written as a hard gate blocked the run.** My design said "Target: under 2.5 minutes". The
   initializer turned that into P0-02's step 5: "under 150 s with `TEST_JOBS=4`".
   - The session cut the suite from 589 s to 165 s and showed that 150 s was out of reach. The files add up to 636 s
     of CPU-bound work, so four jobs can't finish in under about 159 s, and one chain of dependent checks takes 150 s
     on its own.
   - Following "never park", it left `passes` false and asked whether 165 s would do. After two attempts the driver
     gave the feature up, and the 14 features that depended on it were blocked: 2/17, $22.87, nothing merged.
   - **Rule from 10-26:** a performance number in a step is "measured and recorded", never a gate, unless it protects
     the box. It goes into `prompts/initializer.md` in lanes' P2.
   - The real guards had stayed out of the way: 100 min per session, 15 min per suite run, two attempts per feature.
     The continuation adds a 10-minute timeout per test file, and the driver will note how many times the suite ran in
     each session.
2. **The queue kept the order, but not the assumption behind it.** Retro was queued after lanes so it could use
   `tests/checks/`. When lanes blocked at 08:30, the runner started retro at 08:51 on the old single-file suite
   (about 10 min per full run, F1 and F2 one after the other). Retro put its checks into the old `tests/run.sh`, so
   merging `main` into the lanes branch now conflicts in four files. Left alone, the lanes verify would hit that
   conflict and end "needs Michael". The fix (master to-do §B) is one session on the lanes branch:
   - re-run `tests/split.sh` against `main`'s `tests/run.sh`;
   - regenerate the check-name fixture;
   - reword P0-02's steps in `feature_list.json` itself, because the verifier re-runs steps as written and an INBOX
     answer alone wouldn't satisfy it.
3. **The memory run nearly started before lanes.** With retro ending at about 14:15 and memory next in the queue, the
   runner would have started it automatically, and it would have collided with lanes' driver rewrite. I parked it
   (master to-do §A).
4. **Two runs at once never happened.** I set `MAX_PARALLEL_RUNS=2` so that rane's continuation and lanes would run
   side by side. Commit times show they ran one after the other: rane 02:50 → 05:29, then lanes from 05:29. *(inferred
   cause: the runner was started before L5, the config reload, merged at 02:49, so it still held the old value.)*
   The 10:15 status report said the two runs had overlapped from 05:50 to 08:30. The commit times show they didn't.
5. **Agents near the live system.**
   - The 16:32 measuring session briefly ran `tests/run.sh` inside the live lifecycle worktree. It stopped within
     about two minutes and flagged the slip itself.
   - A `git pull --rebase` fast-forwarded the live checkout's `main` at 23:53 while the lifecycle run was alive (the
     reflog shows it).
   - Neither did harm, and both break the rule "never touch the live checkout while a run is alive". The runner syncs
     the checkout itself when no run is alive.

## Status and what I expect (written before the results)
The plan is in the master to-do, with the 13:10 update first:
- **A.** Park the memory run until after the lanes continuation.
- **B.** When retro ends: the branch fix above, then `harness answer` (accept 165 s and the reworded steps), then
  `harness queue add --continue` with a brief that adds the per-file timeout, the per-session suite note and the
  initializer rule. Then unpark memory.
- **C.** Optional: a real jest `check.out` as the fixture for retro's R1.
- **Then:** lanes from about 15:00 to about 01:00 (some 15 features), followed by the memory run on two lanes.

What I expect, so the results can be checked against it:
- **Lanes:** P0, P1 and P2 merge; the record PR merges; no `harness-lane/*` branch or `lanes/` slot is left after gc.
- **Memory run, the first real use of lanes:** `jq .lanes summary.json` shows `max_open` 2, and its admission waits
  are logged.
- **Speed:** wall time per feature on agent-harness runs about 25–40 % lower. That is the 16:32 session's estimate,
  not a measurement yet. The memory run should take about half its serial time *(inferred)*.
- **Memory:** zero real OOM kills over two or three nights; then decide whether `MAX_PARALLEL_RUNS=2` stays.

## Led to
- Harness v4 is lanes (`docs/architecture.md` §15's first bullet is replaced when P2 lands). D-H18 ("runs serial")
  gets a superseding decision file citing the 10-25 usage numbers (lanes P2 item 7).
- After the memory run: `harness memlint` per project, the retro backlog seeded from
  `docs/specs/2026-10-25-memory.backlog-seed.jsonl`, and the parked n8n-events run unparked.

## How to tell it (2 minutes)
1. **Problem:** the harness had just become safe. Memory caps and cleanup were in place, 25/25 features were verified,
   and there were no OOM kills. But a 25-feature run took 15 hours, and my next two improvement runs were queued one
   after the other behind it.
2. **Measure before parallelizing:** I expected the usage limit and serial runs to be the problem. The data said
   otherwise: the harness's own 8-minute test suite took 31 % of session time, and the driver was serial by
   construction.
3. **Design for no new work:** parallel lanes that keep the two invariants (what merges is what was verified; one
   writer for the record), cleanup that falls out of names the existing gc already knows, a suite split by a
   deterministic script, and one memory model, CoALA bucket by scope, with a writer and a rule for every store.
4. **Let the harness build its own parallelism, and learn from where it stopped:** it cut its suite from 589 s to
   165 s and then blocked, because my soft target of "about 2.5 minutes" was written down as a hard gate. Performance
   numbers are now "measured and recorded", and the run continues from where it stopped.
