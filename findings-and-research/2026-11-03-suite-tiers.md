# Suite tiers: measured solo walls (T1-03, 2026-11-04)

Six runs in series on the tree after T1-02 (`1fb13b5`), each `TEST_JOBS=4 bash tests/run.sh [--tier …]`, timed with
`TIMEFORMAT="%R wall %U user %S sys"`, output in `/tmp/harness/agent-harness/agent-harness-2026-11-04/t103-<n>-<tier>.out`.

## No other suite alive

`harness status` before the first run (this run's own session was the only thing running):

```
NEEDS YOU 0 · 2 questions · harness needs
RUNNING 1 ──────────────────────────────────────────────────────────────────────────────────────────
● agent-harness-2026-11-04    T1-03 · session 3 · sonnet                                2/8  $10  1h
QUEUED 0 · runner going
```

## The runs

| # | tier | wall | user + sys | checks | slowest line |
|---|---|---|---|---|---|
| 1 | fast | 152.8 s | 372.3 + 222.5 = 594.8 s | 537/537 checks passed | 39-memlint-m4 41.5 s, 84-node-memo 31.5 s, 63-question-locations 28.6 s |
| 2 | fast | 151.5 s | 371.6 + 221.4 = 593.0 s | 537/537 checks passed | 39-memlint-m4 41.2 s, 84-node-memo 31.5 s, 63-question-locations 28.7 s |
| 3 | slow | 670.7 s | 1586.9 + 974.0 = 2560.9 s | 645/645 checks passed | 15-run-4-same-but-queue-parked-debrief-tmux 222.1 s, 13-run-2-michael-sets-desk 194.5 s, 08-scope-sh-l1-02-run-capped-services-gc-scratch 192.6 s |
| 4 | slow | 659.7 s | 1593.4 + 975.0 = 2568.4 s | 645/645 checks passed | 15-run-4-… 222.4 s, 13-run-2-… 193.9 s, 08-scope-sh-… 193.1 s |
| 5 | full | 809.9 s | 1957.0 + 1190.8 = 3147.8 s | 1181/1181 checks passed | 15-run-4-… 222.8 s, 13-run-2-… 195.2 s, 08-scope-sh-… 193.1 s |
| 6 | full | 794.1 s | 1961.5 + 1197.7 = 3159.3 s | 1181/1181 checks passed | 15-run-4-… 222.0 s, 13-run-2-… 195.1 s, 08-scope-sh-… 191.7 s |

All six ended `N/M checks passed` with no FAIL line (`grep -c '^FAIL'` = 0 in each), so no red-versus-flake
`--repeat 3` was needed.

## Check count per tier

- fast: `grep -c '' tests/fixtures/check-names-fast.txt` = 536 names, plus the tier's conformance line = 537 checks (54 files).
- slow: 1181 − 536 = 645 checks (34 files); the full fixture has 1180 names + its conformance line = 1181.
- 537 + 645 = 1182 = 1181 + 1: each tier run prints its own conformance line, the full run prints one.

The fast tier's longest file: **39-memlint-m4, 41.5 s and 41.2 s**.

## Spec Predictions table (docs/specs/2026-11-03-suite-tiers.md)

- *fast tier solo wall at 4 jobs*: predicted ≤ 180 s (~150 s), 560–620 checks. **Measured 152.8 s and 151.5 s, 537 checks**
  (the count is 23 below the predicted range; the wall is on the prediction).
- *full suite solo wall*: predicted unchanged from 804 s. **Measured 809.9 s and 794.1 s.**
- Time-to-signal for a coding session's last run: a fast run, ~152 s, against 805 s for a full run.
- The rows on runs per session, share of lane time, lane-seconds and un-passes need real runs on the tiered harness (T2 and after): not fillable here.

The brief's gate, restated: a feature's `passes` stands on a fast-tier green; verify and merge stand on the full suite;
a fast green is never read as a green.

## Target check (180 s)

Met in both runs (152.8 s, 151.5 s). Files over 30 s in both fast runs, as the next moves under
`journal/decisions/2026-11-03-suite-tiers.md`'s rule (no move in this feature): **39-memlint-m4** (41.5 / 41.2 s, a
standing spec exception, *default*) and **84-node-memo** (31.5 / 31.5 s, over the line in both runs; the next re-timing
moves it to slow). 63-question-locations (28.6 / 28.7 s) is the next closest under it.

## Measured (agent-harness-2026-11-05, 2026-11-05)

The first real run on the tiered harness: `agent-harness-2026-11-05` (the resident helper, `docs/specs/2026-11-03-resident-helper.md`),
driver `f6f5960` (T1 and T2 in it), 09:56–13:47, one lane (H1, 10:19:51–13:46:39, **12,408 lane-s**), one milestone,
**6 coding sessions** (H1-01, -02, -02b, -03; H1-04 the proof, no code change; H1-05 the review), 6/6 passing, tests
1,332 → 1,455, 0 flakes. Method: `findings-and-research/2026-10-29-run-time-budget.md` §11's, scripts unchanged; outputs
`*-output-2026-11-05-tiers.txt` beside them. A per-20 value scales the run's sum by 20/6.

**The answer first.** The gate did what it was built for: 1 full run and 7 fast runs in 6 coding sessions, every
session's last run 100–160 s, no un-pass, no red at verify. Two predictions about amounts missed. The suite wall of every
caller is 17,015 lane-s per 20 sessions against 12,000–16,000. The share row holds as worded (the sessions' suite is
27 % of lane time) and misses against the 58 % it cites, which is §11's every-caller share: that is 41 % here.

| Measure | predicted | measured | held / missed |
|---|---|---|---|
| fast tier solo wall at 4 jobs | ≤ 180 s (~150 s), 560–620 checks | 7 runs, no other check scope beside any: **158, 160, 160 s** at 618–668 checks (H1-01, H1-02), **101, 99, 100, 101 s** at 678–689 checks (from H1-02b on, the helper serving the driver's calls) | wall held; count missed, above |
| full suite solo wall | 804 s, unchanged | **957 s** at the run's start (1,332 checks; H1-04's own solo run of the base tree 974.2 s), **618 s** in H1-02b, **591 s** at verify (1,455 checks) | missed, above at the start; the run's own subject then cut it |
| time-to-signal for a coding session's last run | ≤ 180 s | 158, 160, 101, 100, none (H1-04: `fast green (cached …)`), 101 s | held |
| full runs per coding session (`Suite runs`) | ≤ 0.2 | **0.17** (1 in 6; the report prints `0.2 full and 1.2 fast per coding session (1 full, 7 fast in 6; 8 runs in all)`) | held |
| fast runs per coding session | 1.5–2.5 | **1.17** (7 in 6: 1, 2, 1, 2, 0, 1) | missed, below |
| sessions' suite share of lane time | 20–30 % (from 58 %) | sessions' suite bucket **27 %** (3,306 s; 10-30's was 43 %); every caller **41 %** (5,105 lane-s; 10-30's was the 58 %) | held as worded; missed like for like |
| suite wall per 20 coding sessions, every caller | 12,000–16,000 lane-s (from 29,511) | 5,105 lane-s = **17,015 per 20** (CPU 3.4 CPU-h = 11.2 per 20, from 28.9) | missed, above by 6 % |
| `red on the verified tree` per milestone | ≤ 1 | **0** (H1: `check: green in 591 s, 1455 tests`; no such line in `harness-log.md` or `run.log`) | held |
| un-passes `fast tier red after the session` per 20 sessions | 0–2 | **0** in 6; no check scope after any session, so the post-session gate was a cache hit 6 of 6 | held |
| main green after milestone merges | 100 % | **100 %** (1 of 1: H1, PR #104, merged on the green verify of the tree with main merged in; no `red after merging main` line) | held |

One line per miss:

- **Fast-tier check count (689, above 560–620).** The tier had 618 checks at this run's start (537 at T1-03) and the run
  added 71 (`91-resident-helper` is fast, the unit tier grew). The wall did not follow the count: 158–160 s before the
  helper, 99–101 s after.
- **Full suite wall (957 s at the start, above 804 s).** The suite had 1,332 checks against T1-03's 1,181, and
  `88-origin-outage` (slow tier, 260.2 s) now heads the `slowest:` line where `15-run-4…` (222 s) did. The tiers still
  reorder nothing (T1-03: 809.9 and 794.1 s). The 618 and 591 s are the resident helper's effect, not the tiers'.
- **Fast runs per session (1.17, below 1.5–2.5).** The sessions ran the fast tier once, last, and a second time only
  after a red first run (H1-02 and H1-03, both `39-memlint-m4`, each with a rerun scope and no flake row). They iterated on subsets
  (`bash tests/run.sh <names>`): about 1,645 s of foreground subset calls in the coding sessions against 934 s of
  fast-tier scopes. H1-04 changed no code and ran none.
- **Share, like for like (41 %, above 20–30 %).** The row's 58 % is §11's `suite wall, every caller` share, not the
  sessions' suite bucket, which was 43 % in that run. Bucket to bucket the share went 43 % → 27 %; every caller 58 % → 41 %.
- **Suite wall per 20 sessions (17,015, above 16,000).** The 5,105 lane-s are: full runs through `check.sh` 2,275 s
  (the baseline 957, H1-02b's 618 + 109 rerun, the verify's 591), fast runs 934 s (7 runs and 2 reruns), and 1,896 s
  of foreground calls naming `tests/run.sh` or `lib/check.sh` (coding 1,645, verify 239, init 12). The baseline alone,
  at the pre-helper suite's length, is 19 % of the sum. The sessions' own part is 3,306 s = 11,020 per 20 (551 s per
  session, from 1,112).

What else the data shows:

- **The one full run in a session was H1-02b's**, which changed `lib/record.sh`, `lib/lane.sh`, `lib/driver.sh`,
  `lib/check.sh`, `bin/harness` and `08-scope…` (slow). The prompt's rule asks for the touched slow file; the session ran
  the whole suite in the background: `check: RED (exit 1 after 727 s; red again on a rerun of 08-scope… 39-memlint-m4)`.
  It fixed both, ran the two files, and ended on `check: fast green in 101 s, 678 tests`. That tree's full run was the
  verify's, green.
- **Where the reds were caught** (`escapes-output-2026-11-05-tiers.txt`: 7 reds, 4 in the session's own check file, 1
  selected by name, 2 missed by a file-based subset). Both missed ones are `39-memlint-m4` (H1-02, H1-03), the file the
  assignment keeps fast for that reason, and the fast tier caught both. The slow tier caught one red file no fast run
  would have (`08-scope…`, in the session that edited it) and none at verify.
- **Non-session time** is 12 % of the lane (before 22 s, after 627 s, verify 897 s by the script). The 591 s under
  "after" is the verify's `suite cache cleared` run (§10's known label), so the harness's own time after sessions is 36 s.

Caveats of the method that apply:

- **One lane, one milestone, six sessions**, two of them not ordinary build sessions. The per-20 scaling multiplies the
  per-run full runs (baseline and verify, 1,548 s) by 3.3 as if every six sessions had their own.
- **The run changed the suite it was measured with.** Full 957 → 591 s and fast 158 → 100 s partway through, so the
  seconds mix two suites. The counts of runs do not depend on it.
- **The scripts predate the tiers.** `totals.mjs` prints `full-suite scopes inside them 4 (0.7 per session)`: it counts
  check scopes over 120 s, and three of the four are fast runs of 158–160 s. The `F:` tags and the `full calls by
  outcome` line count `sed`/`bash -n` commands on `lib/check.sh` (this run edited it) and miss `check.sh --fast`. The
  kinds here come from the metrics rows (`suite_full`, `suite_fast`, written from `check-runs.log`, which went with the
  scratch dir) and the `check:` lines in the stream logs; they agree with the journal (11 scope starts in coding
  sessions = 1 full + 7 fast + 3 reruns).
- **Suite runs outside `check.sh` in the background are not suite time.** H1-04's two solo full suites (974.2 and
  608.1 s, the spec's proof, under `systemd-run` and `time -v`) sit in its 2,562 s of "other tools". Counted as suite
  they make the sessions' share 39 %, every caller 54 % and the per-20 sum 22,290. They are that spec's measurement,
  not gate runs, and the `Suite runs` row does not count them either.
- **Foreground "suite" seconds are an upper bound**: any call whose command names `tests/run.sh` or `lib/check.sh`,
  with whatever else was chained to it.
- **"Solo" means no other harness check scope** (overlap 0 for all six scopes over 120 s). A suite run by a session
  outside the harness makes no scope and would not show.

Reproduce (read-only; `$T` a scratch dir; the `check:` lines are `tool_result` lines of `$S/<run>/logs/*.jsonl`):

```
journalctl --user --since "2026-11-05 09:56" -o json --no-pager | grep -E '"MESSAGE":"[^"]*harness-' > $T/journal.jsonl
D=findings-and-research/2026-10-29-run-time-budget S=~/.local/state/harness/agent-harness
R="agent-harness-2026-11-05"
node $D/budget.mjs $T/journal.jsonl $S $R
node $D/budget.mjs $T/journal.jsonl $S $R --json > $T/budget.json && node $D/totals.mjs $T/budget.json
node $D/escapes.mjs . $S $R
harness report $R --md | grep 'Suite runs'
grep -c 'red on the verified tree\|un-passed' .harness/runs/$R/harness-log.md
```
