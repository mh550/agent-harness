# Evals to run (Michael's, by hand)

Each eval replays the 5 tasks of `--set default` (7 features) with one harness version's driver, on throwaway
clones, nothing posted or merged. They are real Claude sessions and they cost money. **The overnight run never runs
these.** Run them when no harness run is going: they share the plan's 7-day usage window, and `harness eval run`
stops starting tasks past `WEEKLY_STOP_AT` or its `EVAL_BUDGET_USD`.

## Expected cost per eval

Per task: features × $2.50 × 1.3 (retries) + $1.00 (one verify). The $2.50 is a coding session's average cost
(portfolio_site's 126 real coding sessions averaged $2.49; this run's 9 averaged $1.97); $1.00 is the verify
session rounded up from this run's $0.40.

Set `default`: 7 features × $2.50 × 1.3 + 5 tasks × $1.00 = $22.75 + $5.00 ≈ **$28 per eval**; three evals ≈ $83.
`--repeat N` multiplies it by N. Each probe is one Haiku turn, about $0.05 (15 task results ≈ $0.75 in all).
The default `EVAL_BUDGET_USD=10` is only a safety cap, so every command below sets it to the estimate plus a
margin ($35). A running task is never cut off: the overshoot is at most one task.

## 1. Baseline (the harness as of E2)

```bash
EVAL_BUDGET_USD=35 harness eval run --set default --harness run/agent-harness-2026-10-21-measure/E2 --label baseline
```

## 2. After E3 and after E4

```bash
EVAL_BUDGET_USD=35 harness eval run --set default --harness run/agent-harness-2026-10-21-measure/E3 --label e3
EVAL_BUDGET_USD=35 harness eval run --set default --harness run/agent-harness-2026-10-21-measure/E4 --label e4
```

Results land in `evals/results/<stamp>-<sha>-<label>/` (not committed). Below, `baseline`, `e3` and `e4` stand for
those directory names (or their paths); `compare` takes either.

## 3. Compare

```bash
harness eval compare baseline e3
harness eval compare e3 e4
harness eval compare baseline e4
```

Spends nothing. Each metric shows B's verdict against A: better, worse, within noise or one sample (run with
`--repeat 3` for a verdict that is not "one sample").

## 4. Probes

For each task result directory of each eval (`<results>/<task>`, or `<task>/r<N>` with `--repeat`):

```bash
for d in evals/results/*-baseline/ah-*; do harness eval probes "$d"; done
for d in evals/results/*-e3/ah-*;       do harness eval probes "$d"; done
for d in evals/results/*-e4/ah-*;       do harness eval probes "$d"; done
```

Each prints `score <n>/<m>` and writes `probes.json` beside the result. Expect baseline and E3 near 0: the probe
sees the coding prompt but not `progress.md`. E4's `context.md` is what should raise the score: for E4 results `harness eval probes` pastes the saved pack after the probe prompt.

**What the E4 comparison should show** (`harness eval compare e3 e4`, and `baseline e4`): orientation cost (`orient_tokens`, `orient_turns`, `orient_s`) and `context_peak` down, since the session reads one bounded file instead of the whole progress log; probe score up; pass rate and cost per pass not worse. A worse pass rate with lower orientation cost means the pack cut something it needed: read `context.md` in that task's result.

## 5. M6: the review gate

The harness before the review gate (tag `run/agent-harness-2026-10-25-memory/M5`, the last tree before M6) against
M6 as merged (tag `run/agent-harness-2026-10-25-memory/M6`, set when verify M6 holds and the milestone merges, its
review M6-05 included). Michael runs these by hand; the
build never does. Two evals ≈ $56:

```bash
EVAL_BUDGET_USD=35 harness eval run --set default --harness run/agent-harness-2026-10-25-memory/M5 --label pre-m6
EVAL_BUDGET_USD=35 harness eval run --set default --harness run/agent-harness-2026-10-25-memory/M6 --label m6
harness eval compare pre-m6 m6
```

**No cost claim for the review gate stands before these have run.** What they should show: $ per verified feature
down, verify-fail rate not up. The default set's tasks are 1–3 features each, so few of them reach a milestone
review; read each result's `summary.json` (`review.cost_pct`; `review.found_nothing`, the reviews whose every round
reported `0 Critical, 0 Important`) to see whether a review ran at all, and judge the gate on the real runs' ledger rows (`review_cost_pct`) as they accumulate if none did.
