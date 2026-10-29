# Run-time budget: where a harness run's wall-clock time goes

Date: 2026-10-29, 17:00–19:00 EDT, with `agent-harness-2026-10-29-2` alive (its first segment and the finished part of
its second are measured; nothing of it was touched). Host: pop-os, i7-6700K (4 cores, 8 threads), 15.5 GB. Read-only on
every input. Phase 1 of the task in `docs/plans/2026-10-29-suite-time.md`: the plan there carries the predictions.

Runs: `agent-harness-2026-10-26-2` (one lane, the suite still serial), `-10-28` (lanes U1–U3 one at a time),
`-10-29` (N1, N2 one at a time), `-10-29-2` (R1 and R2 at once, then R1 and R3). 71 coding sessions, 179,425
lane-seconds, about 140 full suite runs.

## TL;DR

- **Every second of every lane is assigned; nothing is unexplained.** Over the four runs: model 20 %, **the sessions'
  own suite runs 58 %**, the sessions' other tools 6 %, the harness before a session 2 %, after it 6 %, verify 3 %,
  waiting (pause, stop, a limit) 4 %, idle 0 %. The suite, all callers counted, is **67 % of lane time**; the model is
  busy one fifth of it.
- The hypothesis was half right. The suite is the cost, but **the orchestrator's runs are 11 % of lane time and the
  sessions' own full runs 58 %**: 1.5–2.1 full runs per coding session, 970–1,840 s per session. The harness's
  post-session run was a **cache hit after 50 of 54 passing sessions**; the misses are below.
- **The "3.5 minute" suite is 10–11 minutes.** Alone, `bash tests/run.sh` is 600–665 s wall and 2,350–2,640 CPU-s at
  859–925 checks (3.9 cores busy on `TEST_JOBS=4`). CLAUDE.md's 208 s was 392 checks on 10-26. The suite has grown 2.4×
  in three days and its time 3×. Two at once: 850–1,000 s each, 3,100–3,400 CPU-s.
- **No spin-waits.** CPU per suite grows 25–40 % under overlap, wall 30–60 %; that is hyperthread sharing of 4 cores
  by 8 jobs plus the kernel, not polling: the checks poll with 0.1–1 s sleeps and the CPU is 28,000 process starts
  per large check file (half of it `node` startup, measured on 10-26). The "47 CPU-minutes against a 28 maximum" sum
  assumed a 3.5-minute suite; alone it is already 40 CPU-minutes.
- **Three times in one run, one Gotchas line in CLAUDE.md cost a full suite or a feature.** CLAUDE.md is in the cache
  key (memlint reads it), the prompts ask sessions to add Gotchas lines, and the 15-line cap makes the 16th red. R1-01
  (a plan session) ran 1,531 s of suite for a line it then removed; R2-01 and R1-02 added theirs after their last full
  run, so the harness's run missed the cache, went red, and each feature cost a retry: ~2,500 s of lane time per line.
- **The 09:32→09:48 gap is a second full run of a tree already known red** (`run_init` before the retry session: the
  cache keeps green markers only). 953 s there, 993 s for R1-02's retry at 12:31, 824 s in run 10-29. The 761 s versus
  145 s retry is the session's suite run in a background task: `duration_ms` counts active turns only.
- **The Claude Code Bash tool's 600 s default timeout is under the suite's wall time.** Five full runs hit it ("moved
  to the background"); one was killed at 602 s after 36 CPU-minutes and re-run (1,180 s lost). Nothing tells a session
  how long the suite takes.
- **In run 10-28, sessions ran the suite with `TEST_JOBS=2` or `3`** (870–1,000 s instead of 480 s): a 10-28 session's
  own idea, later rejected in `decisions/2026-10-29-check-timeout-25m`. Half of that run's 48,000 s of session suite
  time was that.
- **Flakes:** 9 rerun-guard rows in 10-29-2 (two lanes at once), 0 in 10-28 and 10-29 (one lane at a time; the guard
  landed during 10-29). Each costs a 160–290 s rerun; none un-passed a feature. The un-passes (4 in 71 sessions) were
  memlint (2), one real red and one API error, not flakes. The contention→flake→rework loop exists as a cost (2,000 s of
  reruns per two-lane run) but has not yet thrown a feature out.
- **A file-based subset** (run the check files that name a changed file, plus the session's own check files) would
  have run 73 % of the check files for the median session (quartiles 24–90 %): nearly every check drives `bin/harness`
  and `lib/driver.sh`. It would have missed 2 of 83 reds the sessions' full runs caught (2.4 %); the other two
  "misses" are the runner's own `03-c` fixture. 22 of 60 sessions would have run under half the suite.
- **Main was never red after a milestone merge** in the four runs (no `red on the verified tree` or
  `red after merging main` line). The verify's full run is the guard that does that work.

## Sources and method

Three clocks, none of which the harness adds up:

1. **The user journal.** Every session, suite and services scope is `harness-<run>[-<lane>]-(s<n>|check-<pid>|svc)`
   (`lib/scope.sh`); systemd logs `Started …`, `Stopped …` (a kill) and `… Consumed <t> CPU time, <m> memory peak`.
   A cached green makes no scope (check.sh exits before `run()`), so one `check-<pid>` scope is one real suite run;
   check.sh's rerun of a red starts the same unit a second time. `journalctl --user --since 2026-10-26 -o json`,
   filtered to `harness-` lines: 1,884 lines in `journal.jsonl`.
2. **`run.log` in each run's state dir**: lanes opened and closed, `session <n> · <id>`, `verify`, `resolve`,
   `paused`, limits, `un-passed`, `flaky:`. The committed `harness-log.md` is a subset of it.
3. **The stream logs** (`<state>/logs/*.jsonl`): every `tool_use` and its `tool_result` carry timestamps (a subagent's
   calls carry `parent_tool_use_id` and sit inside the Agent call); the `result` event carries `duration_ms` and
   `duration_api_ms`.

`budget.mjs` (in `findings-and-research/2026-10-29-run-time-budget/`) joins them: per lane window (`lane X opened` →
`closed`; a pre-lane run is one window), sessions are the `s<n>` scopes, their kind and feature the nearest `run.log`
line of that lane; a session's suite time is the union of the check scopes inside it and its foreground `check.sh`/
`tests/run.sh` calls; its other tool time the union of its other top-level tool intervals; its model time the rest.
A check scope outside every session is the harness's: `after` when it starts within 15 s of a session's end, `verify`
when it follows the `suite cache cleared` note or a verify session, else `before`. Gaps overlapping a pause, limit or
"waiting on Michael" window are `waiting`; a gap under 300 s next to a session or check is harness overhead
(`before`/`after`); anything else is `idle` and listed. `totals.mjs` sums it; `escapes.mjs` does §7. The outputs of
2026-10-29 are beside the scripts.

Reproduce (read-only; the journal keeps about two weeks on this box):

```
journalctl --user --since "2026-10-26 05:00" -o json --no-pager | grep -E '"MESSAGE":"[^"]*harness-' > $TMP/journal.jsonl
D=findings-and-research/2026-10-29-run-time-budget S=~/.local/state/harness/agent-harness
R="agent-harness-2026-10-26-2 agent-harness-2026-10-28 agent-harness-2026-10-29 agent-harness-2026-10-29-2"
node $D/budget.mjs $TMP/journal.jsonl $S $R                 # the tables below
node $D/budget.mjs $TMP/journal.jsonl $S $R --json > $TMP/budget.json && node $D/totals.mjs $TMP/budget.json
node $D/escapes.mjs . $S $R                                # §7
```

Limits of the method: a session's `bash tests/run.sh <subset>` run directly (not through check.sh) makes no scope and
counts as suite time only when its tool call stayed in the foreground; a subagent's suite run counts as the Agent
call's time unless it went through check.sh. The 10-29-2 lanes R1 and R3 were still open when measured. Times are the
box's local clock; journal and stream times are UTC converted.

## 1. What `api_s` measures

`lib/metrics.mjs:96` sums the results' `duration_ms`; `duration_api_ms` is dropped. Verified on
`01-R1-01.jsonl`: `duration_ms` 2,729,255, `duration_api_ms` 373,716, scope wall 2,730 s. So `api_s` = wall, and the
model was busy 14 % of that session. The stream's `duration_api_ms` is cumulative across a resumed session's results
(66, 75, 97 s in `03-R2-01.jsonl`: take the last, not the sum). `duration_ms` leaves out time a backgrounded tool runs
after the turn ends: `03-R2-01` has `duration_ms` 145 s for a 761 s scope because its suite ran as a background task
(648 s, `toolu_011Zg4rA…`, timeout 1,800,000 ms). Model time and tool time have never been separated; §2 separates them
from the tool_use/tool_result timestamps instead.

## 2. The per-lane budget

Lane-seconds and shares (`totals.mjs`; a lane's window is from `opened` to `closed`, the live lanes to the measurement):

| Run | lane-s | model | session suite | session other tools | harness before | harness after | verify | waiting | idle |
|---|---|---|---|---|---|---|---|---|---|
| 10-26-2 (one lane, serial suite) | 18,183 | 25 % | 64 % | 6 % | 3 % | 0 % | 1 % | 0 % | 0 % |
| 10-28 (U1, U2, U3 in turn) | 76,004 | 25 % | 63 % | 3 % | 1 % | 4 % | 3 % | 1 % | 1 % |
| 10-29 (N1, N2 in turn) | 29,225 | 18 % | 60 % | 3 % | 3 % | 12 % | 3 % | 0 % | 0 % |
| 10-29-2 (two lanes at once) | 56,013 | 12 % | 48 % | 14 % | 4 % | 7 % | 4 % | 12 % | 0 % |
| **all** | **179,425** | **20 %** | **58 %** | **6 %** | **2 %** | **6 %** | **3 %** | **4 %** | **0 %** |

Per lane (10-29-2, the run the task named; the full table for every run is in `budget-output-2026-10-29.txt`):

| Lane | window | s | model | session suite | other tools | before | after | verify | waiting |
|---|---|---|---|---|---|---|---|---|---|
| R2 | 09:12–11:36 | 8,622 | 10 % | 35 % | 1 % | 12 % | 9 % | 0 % | 34 % |
| R1 | 09:12–11:36 | 8,641 | 6 % | 28 % | 10 % | 1 % | 10 % | 0 % | 45 % |
| R2 | 12:31–14:56 | 8,698 | 17 % | 55 % | 9 % | 0 % | 11 % | 8 % | 0 % |
| R1 | 12:31–17:53 (live) | 19,348 | 12 % | 40 % | 29 % | 5 % | 5 % | 8 % | 0 % |
| R3 | 14:56–17:53 (live) | 10,646 | 13 % | 85 % | 2 % | 0 % | 0 % | 0 % | 0 % |

The 09:12–11:36 "~8,600 s per lane against ~3,800–4,000 s of sessions" splits as: sessions 3,976 s (R2) and 3,813 s
(R1); the harness's own suites 1,755 s and 959 s; the pause from 10:29 and the stop at 11:36, 2,890 s and 3,868 s.
Nothing is left over. R1's 29 % "other tools" in the second segment is `tests/run.sh --repeat` runs (R1-04 to R1-06
reproduce flakes under load; those bypass check.sh and so make no scope).

The largest unexplained bucket is `idle`: 433 s in all four runs (10-28 02:34–02:52, the `EAI_AGAIN` API error's
retry wait, which `run.log` records as a limit without a resume line).

Session internals (coding sessions, `budget-output-2026-10-29.txt`): wall 400–4,700 s; model 50–1,700 s; the session's
suite 0–4,300 s. The model's share of a session is 5–40 %; sessions that only wrote a plan (R1-01 aside) are the
model-heavy ones.

## 3. The suite itself

**Size and solo cost** (every row a full `bash tests/run.sh`, `TEST_JOBS=4`, the harness's own run with no other
suite in the journal at the time):

| Date | checks | wall alone | CPU alone | source |
|---|---|---|---|---|
| 10-26 (P0-02) | 392 | 207 s | ~810 CPU-s slot time | `decisions/2026-10-26-suite-split` |
| 10-26-2 (serial, before P0-02 merged) | ~375 | 596–741 s | 549–683 s | journal |
| 10-28 01:12 | 859 | 476 s | 1,789 s | journal |
| 10-28 22:17 | 859 | 603 s | 2,343 s | journal |
| 10-29 01:19–11:16 (N1, N2) | 859–925 | 599–665 s (median 624) | 2,349–2,643 s (median 2,452) | journal, 33 runs |
| 10-29-2 (live, 2 lanes) | 886–976 | 750–1,240 s (overlap ≥ 0.9: median 904) | 2,750–3,850 s (median 3,220) | journal, 30 runs |

So the solo suite is **~624 s and ~2,450 CPU-s**: 3.9 of 4 jobs busy for the whole run, which is why `TEST_JOBS` above
4 and sleeps make little difference. The 10-28 growth from 476 s to 603 s within one run at a constant 859 checks is the
suite's own commits landing on main during the day (U1 → U3 added 70 checks' worth of stub runs; the count in
`check-last.out` lags).

**Under contention** (`totals.mjs`, the journal's own load curve: for each full run, the mean number of other full
suites overlapping it):

| overlap (other suites running) | n | wall median | CPU median | wall max |
|---|---|---|---|---|
| none | 33 | 624 s | 2,452 s | 1,047 s |
| under 0.5 | 7 | 856 s | 3,230 s | 1,237 s |
| 0.5–0.9 | 12 | 812 s | 3,102 s | 1,032 s |
| 0.9 and over | 11 | 904 s | 3,220 s | 1,121 s |

CPU per suite rises 26–32 % and wall 30–45 % with a second suite beside it. Two overlapped suites finish in ~904 s
together; two in series take ~1,248 s: the box does more work overlapped (what `decisions/2026-10-29-check-timeout-25m`
measured by hand: 857 s each against 601 s alone). The 1,047 s "alone" maximum (13:50, R2-05) ran beside R1-04's
`--repeat` subset runs, which the journal doesn't see.

**Where the CPU goes, and the spin-wait hypothesis.** `tests/lib.sh` polls with `sleep 0.1` (`in_has`), `sleep 0.2`
(`settle`, a `pgrep -f` each), and the driver under test polls at `HARNESS_PAUSE_POLL=1`, `HARNESS_LANE_POLL=1`,
`HARNESS_MEM_POLL=1`: sleeps, not spins. The 10-26 `strace` of the largest file (`decisions/2026-10-26-suite-split`,
P0-02 attempt 2): 28,325 execs per file, 5,461 `git`, 2,239 `node` at 30 ms startup each, ~10,000 one-millisecond
utilities; node startup alone was 67 s of that file's 123 s of CPU, and 1,684 of the node calls were the driver's own
(`features.mjs`, `metrics.mjs`, one process per question). The CPU swell under overlap is consistent with eight busy
threads on four physical cores (each thread runs slower, so the same work bills more CPU) plus more context switches;
it is not consistent with a spin-wait, which would show CPU ≫ wall × jobs when alone, and alone CPU = 3.9 × wall.
*Hypothesis, not measured here:* a `perf`/`strace -c` of one solo run would put a number on scheduler and fork cost;
Phase 2.

**The 10-28 `TEST_JOBS` episode.** The 10-28 sessions' own full runs alternate 467–491 s with 866–1,000 s at *lower*
CPU (1,640 s against 1,830 s). Their commands (stream logs): `TEST_JOBS=2 …/check.sh`, `TEST_JOBS=3 bash tests/run.sh`
in U1-03, U1-06, U1-07, U2-02 to U2-05 and on. The harness's own runs in the same lanes stayed at 475–607 s. A session
had proposed `TEST_JOBS=2` "while lanes run"; the 10-29 decision measured and rejected it. Roughly half of 10-28's
47,739 s of session suite time is that choice. By 10-29 the sessions were back to the default.

## 4. Full-suite runs per feature, the cache, and what invalidates it

| Run | coding sessions | full runs inside sessions | per session | session suite s per session | harness runs before / after / verify | post-session cache hits of passing sessions |
|---|---|---|---|---|---|---|
| 10-26-2 | 12 | 18 | 1.5 | 973 | 1 / 0 / 0 | 7 of 7 |
| 10-28 | 26 | 54 | 2.1 | 1,836 | 2 / 5 / 3 | 20 of 22 |
| 10-29 | 15 | 23 | 1.5 | 1,168 | 2 / 5 / 1 | 9 of 11 |
| 10-29-2 (so far) | 18 | 34 | 1.9 | 1,494 | 3 / 4 / 1 | 14 of 14 |

(`harness after` counts every post-session run including the ones after a verify; the reruns of reds are not counted
as runs.)

**The cache works when the session's last full run was on the tree it committed.** Recomputing `treekey.mjs` on each
session's commit (the tree exported with `git archive`, same `CHECK_KEY_IGNORE`) against the `green-<key>` markers the
run wrote: 7e3311b (R2-02) = `bcdf32d6…` ✓, 49bf908 (R2-03) = `9a0ec5ae…` ✓, dfd5bc3 (R2-01 retry) = `1cdcda20…` ✓,
86f17e1 (R1-03) = `f14dc1c5…` ✓, 3654c5c (R2-04) = `31e56639…` ✓, 5c25146 (R1-02 retry) = `5a6a8a8d…` ✓. Nothing the
driver does between the session's end and `green` (commit, push, journal, `restrict`, `gotchas`) changes the key:
`.harness/runs` is excluded whatever the list says.

**What invalidated it, every case in the four runs:**

1. **A Gotchas line added to CLAUDE.md after the session's last full run** (CLAUDE.md is in the key: `39-memlint-m4`
   reads it, and the suite-split decision keeps README and architecture docs in). 6e6e924 (R2-01) keys to
   `5d522ce7…`, c319ca4 (R1-02) to `b822a82e…`: neither has a marker. Both sessions' last green run was on the tree
   *without* the line (R1-02's marker `5a6a8a8d…` is exactly its retry's commit, the one with the line removed). The
   harness's run then went red at `memlint: Gotchas at most 15 lines`. Cost per case: the post-session full run
   (747 s + 35 s rerun; 884 s + 65 s) + the retry's pre-session run on the same red tree (743 + 210 s; 784 + 209 s) +
   the retry session (761 s; 166 s) ≈ **2,500 s and 2,100 s of lane time**, plus the attempt. R1-01 is the third: a
   plan session added a Gotchas line by `sed`, ran check.sh (full, 602 s, killed at the tool timeout; again 769 s +
   159 s rerun), then removed the line; its commit 48948a0 keys back to the init's marker `4101a845…`. **1,531 s for
   one line that didn't ship.**
2. **A red tree is never cached**, so the retry's `run_init` reruns the full suite on the tree the post-session run just
   found red: 953 s (R2-01, the 09:32→09:48 gap), 993 s (R1-02, 12:31→12:48), 824 s (N2-02 in 10-29, 10:40→10:53).
3. **`run_init fresh`** at verify clears the marker by design (`decisions/2026-10-26-verify-runs-the-suite`): 965 s (R2),
   1,014 s + 125 s (R1, live), 605 s (N1), 472–607 s (U1–U3). One per milestone.
4. **Two keys that should not have differed:** none found. The lane base cbdc580 and the feature-list commit cdff5e6 key
   to the init's marker, so R2-01's first call was a hit.

So the harness's post-session run is cached whenever the session ended on the tree it last tested. The sessions' own
runs are where the 1.5–2.1 full runs per feature come from: a red (their own new check in its red phase, a real break,
or a flake), then a fix, then the full suite again; or a run killed by the tool timeout, then again.

**The tool timeout.** The Claude Code Bash tool defaults to 600,000 ms; `prompt-coding.md` says nothing about how long
the suite takes, and CLAUDE.md says 3.5 minutes. Full runs that hit it: R1-01 09:17:56 (killed: scope `Stopped` at
602 s after 36.5 CPU-minutes, re-run at 09:37:40 with a 2,400 s background timeout: **1,180 s lost**), R1-02, R2-02,
R2-03 (10-29-2) and N2-06 (10-29), each "moved to the background" at 601 s and finished there (the scope lived on; the
session waited for the task's notification). Why the first was killed and the others not: *hypothesis*, the `| tail`
pipeline in R1-01's call versus a redirect to a file in the others.

## 5. Un-passes and flakes

**Un-passed for "suite red after the session"**: 4 in 71 sessions. R2-01 and R1-02 (10-29-2): memlint's 15-line cap.
N2-02 (10-29, 10:21): a 107 s session that claimed a pass with a cached green while the tree was red on main's merge
(997 s post-session run, 788 s pre-retry run, 741 s retry). U1-07 (10-28): a real red in its own check file, 39 min
of rework (the case `decisions/2026-10-29-rerun-guard` cites). **None was a flake.**

**Flakes** (`green/flakes.jsonl`, one row per red-then-green): 10-29-2: 9 rows, 14 names, in 20 sessions: `08-scope`
×3, `13-run-2-desk` ×2, `28-run-14d` ×2, `32`, `46`, `47`, `48`, `52`, `74`; first-run walls 821–1,238 s; loads 1.4–8.2.
Runs 10-28 and 10-29: no rows (the guard was built in 10-29's N1 lane; in-session the guard rescued N1-03 and N1-05
once each, as the stream logs show). Each flake costs its rerun, 160–290 s, inside whichever call hit it: ~2,000 s per
two-lane run. Of the 9, 7 were in sessions' own calls and 2 in the harness's.

**The loop hypothesis** (contention → slow suites → flakes → un-passes → rework → contention): the first three links
hold (flakes appear only with two suites running; the 13:33 row at load 1.38 is the exception), the fourth does not,
yet: the rerun guard turned every flake green and no feature was thrown out for one. The rework that did happen came
from the Gotchas cap and one real red. *Hypothesis for the next runs:* a flake that reruns red twice (two flakers in
one run, `first` red on both) would be the first un-pass by flake; 10-29-2 had three rows with two or three names.

## 6. The guards behind every full suite run

| Call | Where | Guards against | Decision |
|---|---|---|---|
| `run_init` before the initializer | `lib/driver.sh:477` | a run that starts on a red main: `tests-start` baseline, the init prompt's "suite red" | `decisions/2026-10-26-test-count-contract`; the pre-session init in `docs/architecture.md` |
| `run_init` before every coding session | `lib/lane.sh:319` | a session told the tree is green when it isn't (its first act would be to chase it); the init output in the prompt | the same |
| `green` after a coding session (`F passes && ! green`) | `lib/lane.sh:362` | a session's own `passes` on a tree it didn't test, or tested before its last edit (§4 case 1 is this guard working) | D-H3/D-H4 "guard, don't trust" |
| `run_init fresh` at verify | `lib/lane.sh:72` | a stale or forged green marker carrying a red tree to a tag and a merge (portfolio_site-2026-10-20: it happened) | `decisions/2026-10-26-verify-runs-the-suite` |
| `green` after "holds" at verify | `lib/lane.sh` (`result=hold && ! green`) | the verifier's own edits (cached by then: same tree) | the same |
| `run_init fresh` after a disjoint re-base | `lib/lane.sh:190` | a merge of main that compiles but breaks | `decisions/2026-10-26-lane-rebase-disjoint` |
| the rerun of a red | `lib/check.sh` | a flake un-passing a feature, stopping a verify or failing a re-base | `decisions/2026-10-29-rerun-guard` (quarantine rejected) |
| the scope and timeout | `lib/check.sh` | a runaway test taking the box (6.5–9.6 GB diffs on 10-24); a hung suite | `decisions/2026-10-25-capped-suites`, `-scoped-sessions` |
| the cache key over the whole tree | `lib/treekey.mjs` | a green from another tree; `CHECK_KEY_IGNORE` names only what the suite never reads | `decisions/2026-10-26-suite-split` S3 (LLM-driven selection rejected: the gate must be a deterministic function of the tree) |

Only the verify run and the pre-init run are full runs by design. The pre-session and post-session runs are meant to be
cache hits, and are, except in §4's cases.

## 7. Escape rate: what a file-based subset would have missed

`escapes.mjs`: for every coding session, the files it changed (`entries.jsonl`) against the check files that went red in
its own suite calls (the stream logs' `HARNESS_FAILED=`, `red again on a rerun of`, `flaky:`, `files that exited
non-zero` lines). A red is *selected* when the check file's text names a changed file's basename or the session changed
that check file; *flaker* when it is a repeat flaker; *missed* otherwise.

**85 reds: own check file 35, selected by name 38, repeat flaker 8, missed 4.** The four: `03-c` twice (the runner's
own fixture name in `33-suite-runner`, an artefact of the parse), `16-run-6-limit-cuts` in U1-05 (the weekly-budget
check, the one red of the 25m decision's solo run: a flaker not yet on the list), `39-memlint-m4` in R1-01 (the
Gotchas line; CLAUDE.md wasn't in the entry's files because the line was removed). So **0–2 of 83 real reds (0–2.4 %)
would have escaped a name-based subset**, and both are of the kind a declared map (CLAUDE.md → memlint) catches.

**But the subset is most of the suite.** Under the name rule the median session's subset is **73 % of the check files**
(quartiles 24–90 %): a change to `lib/driver.sh`, `lib/record.sh`, `lib/lane.sh` or `bin/harness` is named by nearly
every check file, because nearly every check file runs a stub `harness start`. 22 of 60 sessions would have run under
half the suite: the plan features (0–19 files), the pure-module features (`lib/view.mjs`, `lib/metrics.mjs`,
`tests/stub-claude.sh`: 14–39 files). For agent-harness's profile, "the relevant tests per feature" is the full suite
for the driver features and a small subset for the rest; the saving is in the small-subset half.

Caveat: these are the reds the sessions' *own* runs caught, the only reds the data holds per feature; the harness's
post-session reds (§5) are the memlint pair, also CLAUDE.md-mapped. What a subset would have *let through to verify*
is bounded by the same 0–2.4 %, with the verify's full run behind it.

## 8. Prior art, and what carries over to one 8-core box with two lanes

(From memory; no source re-read for this note.)

- **Content-hash caching (Bazel's action and test cache):** every test target is keyed on the digest of its transitive
  inputs, so an unchanged target is never re-run and the key is exact, not heuristic. The harness already does this at
  whole-tree granularity (`treekey.mjs`). Finer keys need a dependency graph; this suite has none (bash + stubs, and
  every check file reads `bin/harness` and `lib/*`), so a per-check-file key would equal the whole-tree key for every
  driver change and differ only for docs and fixtures. *Carries over as a declared map, not a graph:* "a tree that
  differs from a green tree only in CLAUDE.md needs only memlint" is a one-line Bazel dependency, written by hand.
- **Merge queues with batched full runs and bisection (bors, Zuul, GitHub's merge queue):** changes are tested
  individually with a cheaper check, batched, the batch gets the full run, and a red batch is bisected. The milestone
  *is* the batch here (5–7 features), the verify's `run_init fresh` the batch run, and "an agent fixing what breaks
  there" the bisection; the resolve session already exists for the merge-conflict case. On one box the batch run
  costs 620–1,000 s per milestone, once, instead of per feature.
- **Meta's Predictive Test Selection (Machalica et al., 2019):** a learned model ranks tests by failure probability for
  a change and runs enough to reach a recall target (over 95 % of failures per change), with periodic full runs to
  catch the rest. §7's 0–2.4 % miss rate is that recall measurement for a trivial selector. With twenty changes a night
  and no training set, the learned model is the wrong tool; the policy (bounded recall per change, full runs at a
  cadence) is the right one.
- **Google TAP:** presubmit runs the affected targets from the dependency graph; postsubmit runs continuous batched
  builds at trunk; flaky tests are retried and tracked, not trusted. The affected-targets half needs the graph; the
  postsubmit half is the milestone run.
- **Flaky-test quarantine:** known flakers are moved to a lane that cannot block merges, with a dashboard and an owner.
  The rerun guard rejected quarantine and chose rerun-and-count (`decisions/2026-10-29-rerun-guard`); R1's flaker table
  is the dashboard. What carries over is the *count* as a gate on the fix work, not the exemption.

What does not carry over: the economics of a build farm. Those systems trade CPU for latency across thousands of
cores; here two suites already saturate four cores, and the only CPU to be saved is CPU not spent.

## 9. What the data cannot show (hypotheses) and Phase 2

- The solo-vs-paired load curve at `TEST_JOBS` 1, 2, 4 (and 8, see the plan) with `/usr/bin/time` and
  `/proc/pressure/cpu`: not run (a run is alive). The journal gives wall and CPU per overlap bin (§3) but no pressure,
  no controlled pairing, no jobs variation.
- The per-process CPU split (fork/exec, node startup, git, the suite's own sleeps) of one solo run: the 10-26 strace is
  the only measurement and the suite has doubled since.
- Why most in-session full runs happen: the stream logs cut the suite's output (`> check.out`, `| tail -3`), so of
  151 full `check.sh` calls, 13 show "cached", 5 "green", 1 "flake", 6 "red", 4 "moved" and 122 nothing. The scopes count
  them but don't say why. R3-04 (in flight) counts suite runs per session; a note of each run's first line (cached /
  green / red / flake) would answer it in the next run.
- The stub-overhead share inside `tests/run.sh`'s throwaway environment (how much of a check file is `harness start`
  and its stub sessions, how much the assertions): P0-02's "the cost is `harness start`, not its checks" stands but is
  unmeasured on the current suite.
- Whether the Gotchas-line pattern recurs under the current prompts: three cases in one run says yes; the next run will
  say.
