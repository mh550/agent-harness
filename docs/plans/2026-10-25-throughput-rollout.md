# Rollout: getting lanes and the split suite in before the retro and memory runs (2026-10-25)

Design: `docs/specs/2026-10-25-throughput-and-memory-design.md` (awaiting Michael's approval). This file is the
order of operations, what each step needs from the step before, what can be prepared tonight while the lifecycle
run is live, and Michael's commands. Tick steps here, on `main`, as they land.

## Where things stand (22:15 on 10-25)

- `agent-harness-2026-10-25-lifecycle` is live at 18/25: L3-05 (the L3 review) is in session; then L4-01…05 and
  L5-01, each 17–66 min so far, plus three verifies and the retro. Expect it to end around **02:00–03:00 on 10-26**
  (an estimate from the log's pace). It edits `lib/driver.sh`, `lib/check.sh`, `bin/harness` (`cmd_gc`),
  `lib/queue.sh` and `tests/run.sh`, and merges `origin/main` into its branch before every verify.
- The queue holds the retro run (F1–F3) and then the memory run (M1–M6). The runner starts the retro run **the
  moment the lifecycle run ends**, after syncing the live checkout.
- Every suite the lifecycle run's sessions ran took about 8 minutes; the next two runs add checks to the same file.

## The order, and why

| # | What | Who | When | Needs |
|---|---|---|---|---|
| 0 | **Hold the queue** so nothing starts after the lifecycle run (step 0 below) | Michael | tonight, before ~02:00 | — |
| 1 | Design and this plan on `main` (new files: no conflict with the live run) | this session | tonight | — |
| 2 | On approval: the two build specs (`suite-split`, `lanes`), the amendments to the retro-fixes and memory specs (§8 of the design), the superseding decision for D-H18, the queue brief texts | a harness session | tonight or first thing 10-26; about 40 min | Michael's yes |
| 3 | **Suite split** (§5.1–§5.2), interactive in a worktree, PR, merged | a harness session | right after the lifecycle run ends; about 1.5 h | the lifecycle run merged (its L4/L5 checks are in `tests/run.sh`); step 2's spec |
| 4 | **Queue**: lanes run → retro run (F1, F2) → memory run; start the runner | Michael | after step 3 merges; 2 min | step 3 |
| 4b | If rane-one-mixxx-2026-10-24 should finish on today's driver: answer M5-06 and `harness continue` it in the daytime window of 10-26 (decision 4 below) | Michael | before step 5 merges | — |
| 5 | **Lanes run** (§4), serial, on the current driver | the harness | night of 10-26, about 7 h | step 4 |
| 6 | `MAX_LANES=2` in `~/.config/harness/config.sh`; the retro run opens F1 and F2 side by side | Michael, then the harness | after step 5 merges, before the retro run starts (the runner syncs before each start; the config is read at run start) | step 5 |
| 7 | **Memory run** with four lanes (M1, M2, M5, M6; then M3, M4) | the harness | after the retro run, same night if the window allows | step 6 |
| 8 | `MAX_PARALLEL_RUNS=2` so other projects' runs go beside agent-harness work | Michael | after one night at two lanes shows the memory headroom (`mem_peak_mb`, `lanes` in the summary) | step 7 |

**Why the suite split is interactive, not a run.** It is a move with a conformance check (same check names before
and after), no design judgment; a run would spend an initializer and 30 min a feature on it; and it has to land
before the lanes run, whose checks would otherwise join the monolith.

**Why lanes is a run, not an interactive build.** It is concurrency code with new guards; the harness's own
verify-then-merge is the review it should get, and the journal's point is that the harness builds the harness. If
Michael wants it sooner, the same spec is two chunks for interactive sessions (P1 lane process + scheduling; P2
merge, cleanup, status), each one session with a stated stop.

**Why lanes before retro and memory, at the cost of one night.** The retro run is two independent milestones and
the memory run four; on lanes they take roughly half the wall time, and R10 (a third of the retro run) is subsumed
by lanes, so the retro run shrinks. Every run after them gets the same gain. The alternative is below.

### The alternative (B): retro and memory first, lanes after

Keep the queue as it is. Retro runs 10-26 early morning (about 5 h), memory the night of 10-26 (about 12 h, serial),
lanes on 10-27. Nothing extra for Michael tonight. The cost: the two runs are slower, R10 is built and then
replaced by lanes, and their 40-odd new checks go into the monolith before the split. **Recommendation: A**, with
step 0 tonight.

## Step 0, tonight (Michael, 2 min): hold the queue

Park both entries with a reason, so the runner finds nothing to start when the lifecycle run ends, exits, and runs
the debrief over the lifecycle run as usual. `harness queue stop` would also work but would start a debrief now,
with the lifecycle run still going.

```bash
harness queue list                       # note the numbers of the retro and memory entries (1 and 2 unless something changed)
harness queue park 1 "held for the lanes run (docs/plans/2026-10-25-throughput-rollout.md)"
harness queue park 1 "held for the lanes run (docs/plans/2026-10-25-throughput-rollout.md)"   # the memory entry is now 1
harness queue list                       # both under "parked", each with its reason; the lifecycle run still running
```

`park` is a plain `mv` into `held/` (R11), but a collision needs the same number and project name, and the only
held entry is n8n-home's, so these two can't overwrite it. If anything looks off in the second `queue list`, use
`harness queue stop` instead and say so.

## Step 2 (after approval): the specs and amendments

One harness session, in a worktree, merged as one PR (docs only, so safe while the lifecycle run is live):

- `docs/specs/2026-10-26-suite-split.md`: §5.1 and §5.2 of the design as a build spec with its checks (the
  conformance list, `TEST_JOBS`, the per-file isolation, `CHECK_KEY_IGNORE`), sized for one interactive session.
- `docs/specs/2026-10-26-lanes.md`: §4 as a run spec. Milestones: **P1** `lib/lane.sh` and the record
  materialization and lock (§4.3, §4.5), `features.mjs lanes` (§4.4), the coordinator with `MAX_LANES=1` (the
  serial case end to end: a run on lanes passes every existing check, with the record-on-main checks rewritten as
  design §9 says); **P2** `MAX_LANES>1`: admission, the re-base rule (§4.6), slots and cleanup (§4.7), status and
  summary (§4.8), gc's `harness-lane/*` pass, the record PR (§4.2), the legacy-run refusal (§4.10), `harness
  merge`'s re-base (§4.6), the D-H18 superseding decision, architecture §12/§15 and README. P2 after P1.
- `docs/specs/2026-10-21-retro-fixes.md`: a dated line at the top: F3 (R10) is subsumed by lanes except change 2
  (the initializer's `after` rule), which moves into F2 beside R3; the milestone table loses F3.
- `docs/specs/2026-10-25-memory.md`: a dated line at the top with §8's additions (scope column and rules in M2;
  `"project"` affects and "Promote to Gotchas" in M3; `CONTEXT_PACK_BYTES_VERIFY` in M3) and the note that M1,
  M2, M5 and M6 run as four lanes.
- `docs/architecture.md`: no edit yet (the lifecycle run is editing it; the lanes run owns that change).

## Step 3 (after the lifecycle run ends): the suite split

```bash
harness status agent-harness-2026-10-25-lifecycle    # ended, L3–L5 merged (or what was); harness sync says level
cd ~/projects/agent-harness && claude "Read docs/specs/2026-10-26-suite-split.md and build it in a worktree: test-first, the conformance check first. Merge the PR when the suite is green. Stop at your report."
```

If the lifecycle run ends with L4 or L5 not merged, the split still goes ahead; the lanes spec says to build on
`main` as it stands.

## Step 4 (Michael, after step 3 merges): the queue

```bash
harness sync
harness queue add ~/projects/agent-harness --spec docs/specs/2026-10-26-lanes.md \
  --brief "Build P1 then P2 as the spec says. The suite is tests/run.sh over tests/checks/ now: add each new check in the file of its topic, or a new file; never a monolith. MAX_LANES stays 1 by default."
harness queue list                                   # the lanes entry first; retro and memory parked
harness queue unpark 1                               # retro back, at the end
harness queue unpark 1                               # memory back, after it
harness queue list                                   # lanes, retro, memory, in that order; n8n-events still parked with its reason
harness queue start
```

The retro entry's brief should be re-stated when unparked if it names F3: `harness queue rm` and `add` it again
with `--brief "F1 and F2 only; F3 (R10) is subsumed by lanes, see the spec's top line. Independent milestones: two lanes."`

## Step 6 (Michael, after the lanes run merges): turn lanes on

Add to `~/.config/harness/config.sh`:

```bash
MAX_LANES=2   # 2026-10-26: first night with lanes; raise to 3 after a night without memory waits in harness-log.md
```

Check the first lane night the next morning: `grep -c "lane .* waiting" <run dir>/harness-log.md` (admission waits),
`jq '.lanes' <run dir>/summary.json`, and `mem_peak_mb` in `metrics.jsonl`. No OOM lines in `journalctl --user -b`
and no `harness-*` units after the run (`systemctl --user list-units 'harness-*'`).

## Step 8 (Michael, later): two runs at once

`MAX_PARALLEL_RUNS=2` in the same file. L5 makes the runner read it without a restart. Memory is the limit: with
two lanes each, two runs can mean four sessions and four suites; the admission gate is per box, so the second run's
lanes wait when the first's hold the headroom, but the floor is one session per run.

## Decisions that are Michael's (asked 2026-10-25; the design proceeds on the first option of each until he says otherwise)

1. **Order:** A (lanes run before the retro and memory runs, one extra night) or B (retro and memory first on the
   serial driver, lanes after).
2. **How lanes get built:** as a harness run (P1 then P2, one night) or as two chunked interactive sessions (faster
   if he is around to start them; no independent verify).
3. **The record on `main`:** one record PR per run at `finish` (`RECORD_PR=end`, the design's default), or none,
   the ledger being the only copy.
4. **`rane-one-mixxx-2026-10-24`** (9/19, waiting on him at M5-06, code on its branch): answer and
   `harness continue` it **before the lanes run merges** (the serial driver can still drive it; there is a daytime
   window on 10-26 after the lifecycle run ends), or let it be refused later and re-plan what is left as a new run.
5. **The disjoint re-base rule** (design §4.6): accept that a verified milestone plus disjoint `main` changes with
   a green suite is "verified", or require a verify session every time (`LANE_REBASE=verify`).
6. **First lane night at `MAX_LANES=2`** (the box's headroom says two; three would wait on memory most of the time).

## What is deliberately not prepared tonight

- Any edit to `lib/`, `bin/harness` or `tests/run.sh`: the lifecycle run merges `origin/main` into its branch before
  each verify, and a conflict there would end its milestone "needs Michael".
- The specs and amendments (step 2): they follow the design's approval. They are about 40 minutes of one session.
- `~/.claude` and `~/.config` edits: Michael's.
