# Run-time budget: dj-crate-streaming and hit_list

Date: 2026-10-30. Host: pop-os, i7-6700K (4 cores, 8 threads), 15.5 GB. Read-only on every input. Plan
`docs/plans/2026-10-29-suite-time.md` §5 asks this table for dj and hit_list before any fix is applied to them; the
method and the bucket definitions are `2026-10-29-run-time-budget.md`'s.

Runs: dj-crate-streaming's last three, `dj-soulsync-review-2026-10-22` (06:37–16:16), `dj-crate-streaming-2026-10-22-fixes`
(16:17–21:37) and `dj-crate-streaming-2026-10-22-build` (10-22 21:38 to 10-23 09:36), back to back, one lane each.
hit_list has **two runs, not three**: `hit_list-2026-10-20` (two segments, 10-20 12:54–13:10, then 10-21 10:50–14:39)
and `hit_list-2026-10-22-sharing` (10-22 19:28 to 10-23 13:02). 167 coding sessions, 174,934 lane-seconds, 346 full
suite runs inside sessions.

## TL;DR

- **The journal holds nothing for these runs.** It still covers the window (the boot that holds it runs from 10-13
  to 10-24), but `lib/scope.sh` landed on 10-25 and every one of these runs is older: no `harness-<run>-*` scope exists
  for any of them, and so no CPU figure anywhere. `budget.mjs` on them puts every lane-second in `idle`. The tables
  below come from a companion script, `budget-runlog.mjs`, which builds the same buckets from the clocks these runs
  did keep: `run.log`, the stream logs, and the `green-<key>` markers.
- **dj: the suite is where the lane time goes.** Over the three runs: model 33 %, **the sessions' own suite runs
  59 %**, other tools 3 %, the harness before a session 3 %, after it 1 %, verify 2 %, waiting 0 %, idle 0 %. Counting
  every caller, the suite takes **62 %** of lane time (55 %, 79 % and 61 % per run).
- **hit_list: the suite is not where the lane time goes.** Model 67 %, the sessions' suite runs 16 %, other tools 13 %,
  harness 1 %, verify 2 %. Counting every caller, the suite takes **17 %**, and full runs are 38 % of the sessions'
  share (4,719 s of 12,476 s). Most of it is direct `npx jest`/`tsc`/`expo lint` calls, some of them chained after an edit.
- **The dj suite alone is 580–930 s**, and its wall grows with the test count within a run: 580–663 s at 1,615–1,757
  tests (soulsync-review), 651–692 s at 1,757–1,906 (fixes), 690–928 s at 1,933–2,369 (build). Two dj full suites
  never ran at once (one lane, runs in sequence), so there is no paired figure for dj. 21 of 57 green dj runs
  overlapped a hit_list suite for 0–12 % of their wall. **The hit_list suite** is 8–30 s by check.sh's own clock:
  a median of 11 s at 360–656 tests and 19 s at 656–1,937 tests when it ran alone, 17 s when it overlapped a dj suite.
- **Full runs per coding session:** dj 1.6–1.8 (1.05–1.5 green), with 3, 7 and 8 runs per run started and then
  stopped by the session (399, 1,752 and 2,871 s); hit_list 1.95 and 2.4 (1.8 and 2.1 green). The harness's
  post-session suite was a cache hit after 48 of 49 dj sessions and 99 of 118 hit_list sessions.

## Sources and method

**The journal.** `journalctl --user --since "2026-10-20 12:54:49" -o json` (the earliest run's first `run.log` line)
returns 34,493 lines, 2,585 of them with `harness-`. The first harness scope is `harness-probe-834633.scope` on 10-25
01:56 (the L1-02 probe of `lib/scope.sh`, added that day in 7e4eb47); the first run scopes are agent-harness's of
10-25. None of the 2,585 lines names dj-crate-streaming, dj-soulsync or hit_list. The journal still holds the window,
then, but holds no scope in it. `budget.mjs` and `totals.mjs` run on it as asked: 0 sessions, 100 % idle in every
lane (`2026-10-30-run-time-budget-dj-hitlist/budget-output-2026-10-30.txt`).

**What these runs kept instead**, read by `budget-runlog.mjs` (in `findings-and-research/2026-10-30-run-time-budget-dj-hitlist/`):

1. `run.log`: a session runs from its start line (`session <n> · <feature> · <model>`, `verify <M> · claude…`,
   `initializer · `, `retro · `) to the next `  <kind> exit` line; run windows, pauses and limits as in budget.mjs.
2. The stream logs: every top-level `tool_use` → `tool_result`. A backgrounded call, whether `run_in_background` or
   moved there at Claude Code's 600 s tool timeout, ends at its task's `task_updated` `end_time` (a `system` event
   that carries the `task_id` that `task_started` tied to the `tool_use_id`), not at its immediate tool_result. A suite
   call is check.sh (the harness's or the project's `.harness/check.sh`), `pytest`, `npx jest`/`tsc`/`expo lint`, or
   `npm test`, run at a command position. A full call is a check.sh run with no subset argument.
3. The `green/green-<key>` markers. `lib/check.sh` of that period (4050adb) touches one at the end of every green full
   run and none on a red one, and never re-runs a tree that has one. A marker inside a session is one of that
   session's green full runs, and those markers are the green count used below (5 of 346 hid behind a session's
   `until grep …` wait loop; the calls alone would miss them). A marker outside every session is a harness suite:
   it ran from the gap's start (the previous session's exit line, or the run's start) to the marker. That is an upper
   bound, which includes the driver's few seconds of commit and push and, for hit_list, its `.harness/init.sh`.
   Neither run.log has a `suite red before the session`, an `un-passed` or a `suite is red on the verified tree` line,
   so no harness suite went red unseen.

Each bucket and rule is the same as budget.mjs's. A session's suite time is the union of its suite calls, its other
tools the union of the rest, its model time the remainder. A harness suite is `after` when it follows a coding
session's exit line within 15 s, `verify` when it follows a verify session or precedes one, and `before` otherwise. A
gap of up to 300 s next to a session or a suite is harness overhead. `budget-runlog.mjs --json` writes budget.mjs's
shape, so `totals.mjs` runs on it unchanged.

Reproduce (read-only):

```
D=findings-and-research/2026-10-30-run-time-budget-dj-hitlist S=~/.local/state/harness
R="$S/dj-crate-streaming/dj-soulsync-review-2026-10-22 $S/dj-crate-streaming/dj-crate-streaming-2026-10-22-fixes
   $S/dj-crate-streaming/dj-crate-streaming-2026-10-22-build $S/hit_list/hit_list-2026-10-20 $S/hit_list/hit_list-2026-10-22-sharing"
node $D/budget-runlog.mjs $R                                            # budget-runlog-output-2026-10-30.txt
node $D/budget-runlog.mjs $R --json > $TMP/b.json && node findings-and-research/2026-10-29-run-time-budget/totals.mjs $TMP/b.json
journalctl --user --since "2026-10-20 12:54:49" -o json --no-pager | grep -E '"MESSAGE":"[^"]*harness-' > $TMP/journal.jsonl
node findings-and-research/2026-10-29-run-time-budget/budget.mjs $TMP/journal.jsonl $S/dj-crate-streaming <run>…   # all idle
```

## 1. The per-run budget

Lane-seconds and shares (`totals-output-2026-10-30.txt`). Each run is one lane, from its `run … on` line to
`run ended`.

| Run | lane-s | model | session suite | session other tools | harness before | harness after | verify | waiting | idle |
|---|---|---|---|---|---|---|---|---|---|
| dj soulsync-review (18 coding sessions) | 34,744 | 39 % | 51 % | 3 % | 2 % | 2 % | 2 % | 0 % | 0 % |
| dj fixes (10) | 19,177 | 19 % | 71 % | 1 % | 7 % | 0 % | 3 % | 0 % | 0 % |
| dj build (21) | 43,077 | 34 % | 59 % | 3 % | 2 % | 0 % | 2 % | 0 % | 0 % |
| **dj, three runs** | **96,998** | **33 %** | **59 %** | **3 %** | **3 %** | **1 %** | **2 %** | **0 %** | **0 %** |
| hit_list 10-20, segment 1 (1) | 963 | 86 % | 1 % | 2 % | 4 % | 1 % | 0 % | 6 % | 0 % |
| hit_list 10-20, segment 2 (41) | 13,728 | 64 % | 16 % | 11 % | 1 % | 2 % | 6 % | 0 % | 0 % |
| hit_list sharing (76) | 63,245 | 67 % | 16 % | 14 % | 0 % | 1 % | 2 % | 0 % | 0 % |
| **hit_list, two runs** | **77,936** | **67 %** | **16 %** | **13 %** | **0.5 %** | **1 %** | **2 %** | **0.1 %** | **0 %** |

The suite counted over every caller (the sessions' runs, the harness's own suites, and the suite calls inside verify
sessions): dj 62.2 % (60,330 s), hit_list 16.8 % (13,132 s).

**dj's harness suites** come to 3,194 s in five runs: one at each run's start, before the initializer (585, 587 and
712 s; it counts the tests for `tests-start`), one after the fixes initializer (655 s), and one after soulsync-review's
V1-02 (654 s). Every other post-session suite was a cache hit, since each session's last full run was already green on
the tree it handed over. The 7 % "before" in fixes is two of these in a 5.3 h run. The fixes initializer also ran the
full suite itself (649 s, counted as session suite).

**hit_list's harness suites**: one before the first session (35 and 53 s, including init) and 9 and 10 after sessions
(9–20 s each). The 60 s of waiting is the 10-20 pause before Michael stopped the run.

Where the dj model time sits: 13,058, 3,437 and 13,624 s over 18, 10 and 21 coding sessions. dj sessions are 700–4,060
s wall, of which the suite is 580–2,900 s. hit_list sessions are 57–2,072 s wall, with 2–667 s of suite.

## 2. The suite itself: solo and paired

**CPU: none.** Only a scope's `Consumed … CPU time` line recorded it, and these runs have none.

**Wall, dj** (check.sh's own `green in N s, M tests` lines; the green runs' tool intervals, start to the task's end, are
581–926 s):

| Run | tests | full suite, green | note |
|---|---|---|---|
| soulsync-review | 1,615 → 1,757 | 580–663 s (median 650) | alone throughout |
| fixes | 1,757 → 1,906 | 651–692 s | 4 of 11 overlapped hit_list's sharing run |
| build | 1,933 → 2,369 | 690–928 s | 17 of 19 overlapped hit_list's sharing run |

The wall tracks the test count: +142 tests added ~70 s (soulsync-review), +149 added ~40 s (fixes), +436 added
~238 s (build). **Paired (two dj suites at once): never.** The three runs ran one after another, each a single lane.
What did overlap was 21 of the 57 green dj runs with a hit_list suite (a 10–40 s run, so 2–12 % of the dj run's wall,
mean 6 %); they fall on the same wall-against-tests line as the runs that ran alone. The repo's git history shows one
other run ending in the window, `n8n-home-2026-10-22` at 19:27 on 10-22. Its start and its suites aren't visible to
this method.

**Wall, hit_list** (check.sh's own line):

| Run | tests | alone: n, median (range) | overlapping a dj suite: n, median (range) |
|---|---|---|---|
| 10-20 | 360 → 656 | 74, 11 s (8–19) | none (no dj run was alive) |
| sharing | 656 → 1,937 | 93, 19 s (11–30) | 63, 17 s (13–25) |

A hit_list suite overlapping a 10–15 minute dj suite was not slower than one running alone. Again there is no CPU to
say what either cost.

## 3. Full-suite runs per coding session

Full runs inside coding sessions. Green = markers touched inside the session. Stopped = a backgrounded full run the
session stopped (task status `stopped`) before it ended. Other = a backgrounded full run that ended with no marker and
no stop: in dj-build, 296–453 s each, shorter than a full run, and at least one of them (S4-02) ended by a separate
`kill`.

| Run | coding sessions | full runs | green | stopped | red | other | per session | green per session | sessions with 0 / 1 / 2 / 3+ green |
|---|---|---|---|---|---|---|---|---|---|
| dj soulsync-review | 18 | 30 | 27 | 3 (399 s) | 0 | 0 | 1.67 | 1.50 | 0 / 9 / 9 / 0 |
| dj fixes | 10 | 18 | 11 | 7 (1,752 s) | 0 | 0 | 1.80 | 1.10 | 0 / 9 / 1 / 0 |
| dj build | 21 | 34 | 22 | 8 (2,871 s) | 0 | 4 (1,121 s) | 1.62 | 1.05 | 0 / 20 / 1 / 0 |
| hit_list 10-20 | 42 | 82 | 74 | 0 | 4 | 4 | 1.95 | 1.76 | 1 / 20 / 11 / 10 |
| hit_list sharing | 76 | 182 | 158 | 0 | 20 | 4 | 2.39 | 2.08 | 0 / 22 / 34 / 20 |

The suite time per coding session is dj 992, 1,291 and 1,210 s, and hit_list 54 and 134 s. In dj that time is
full runs: all of it in soulsync-review, 9,141 of ~13,150 s in fixes and 19,637 of ~25,980 s in build (call seconds,
summed before the union). The rest is subset runs, `.harness/check.sh tests/…` or `lib/check.sh tests/…`. In
hit_list, full runs are 1,194 of ~2,270 s and 3,525 of ~10,260 s. The rest is direct `npx jest <files>`, `npx tsc`
and `npx expo lint` calls, some chained after an edit, and each counts whole.

Stopped runs follow one pattern in the dj sessions: a full run starts in the background, the session finds something
to change, stops the run, edits, and starts it again. That is 5,022 s across the three runs (5 % of dj lane time),
all counted as session suite.

Post-session cache hits (a passing session with no harness suite after it): dj 17 of 18, 10 of 10 and 21 of 21;
hit_list 33 of 42 and 66 of 76. No session was un-passed for a red suite, and no run had a flake (`green/flakes.jsonl`
did not exist yet).

## 4. Is the suite where the lane time goes? (plan §5)

- **dj-crate-streaming: yes.** The suite is 62 % of lane time over the three runs (55 %, 79 %, 61 %), and 59 % is the
  sessions' own runs. The model is 33 %; the harness's own suites are 3 %, almost all of them a full run at each run's
  start. A full run is 10–15 minutes and grows with the test count (0.36 s per test at 1,615 tests; the build run's
  436 new tests averaged 0.55 s). The sessions run 1.6–1.8 full runs each, of which 1.05–1.5 go green; the rest are
  runs the session stopped and started again.
- **hit_list: no.** The suite is 17 % of lane time, full runs 6 %. The model is 67 % and other tools 13 %. A full run
  is 8–30 s. The plan's "the suite is not where its lane time goes" now has a measurement behind it.

## 5. What the data cannot show

- **CPU, and so the cost of overlap.** There is no scope, so there is no CPU figure for any run. A dj suite was never
  paired with another dj suite, so the 10-29 findings' contention curve has no dj counterpart.
- **Model and suite running at the same time.** When a session waits on a backgrounded suite, the model may still
  be working; the suite interval is counted first and the model is the remainder, as in budget.mjs. The 10-29 numbers
  have the same convention, so the two sets compare.
- **The harness suites are upper bounds** (from the gap's start to the marker). The three run-start dj suites
  (585–712 s) match a full run's length, so that bound is tight for them.
- **A subagent's suite runs** count as the Agent call's time, as in budget.mjs.
- **The earlier dj runs** (`dj-2026-10-17`, `dj-crate-streaming-2026-10-21`) are not measured.
- **budget.mjs's full-call test**, which `budget-runlog.mjs` doesn't share: it reads `check.sh 2>&1 | tail` as a
  subset (the redirection's `2` passes its `[A-Za-z0-9]`), and reads a chain as a subset when any check.sh in it has
  an argument. That only touches the full-call outcome tally in `totals.mjs`. The 10-29 run counts came from scopes.
