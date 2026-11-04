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
