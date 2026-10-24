# `harness eval compare` judges B against A per metric: better, worse, within noise, one sample or no data

*(2026-10-21, E2-05 of run agent-harness-2026-10-21-measure; plan `docs/plans/2026-10-21-E2-evals.md` §4; builds on
`decisions/2026-10-21-eval-budget-window-repeat`)*

- **Finding:** an eval result is a dir of `summary.json` files, one per task and repeat. Two of them (a baseline and
  a harness change) can't be read side by side by eye: eight metrics times every task, and with two or three repeats
  a difference may be only the spread between runs of the same version. After a budget or weekly stop the last
  repeat can also be partial, so a total summed over "every task in repeat r" would compare fewer tasks with more.
- **Choice:** `lib/eval.mjs` `loadResult(dir)` reads `{ tasks: { <id>: [summary of r1, r2 …] } }` (`spent` now uses
  it too). The eval makes a unit's dir before its run starts, so a dir without a readable `summary.json` is a run that
  failed: it loads as `{ missing: true }`, counts as not passing (null for the other metrics) and the output names
  it; a repeat with no dir (a budget or weekly stop) is absent. Then the pure `compare(A, B)` returns rows `{ task, metric, a, b, verdict, a_values, b_values }` for every
  task in both results and each of eight metrics read from summary.json: pass rate (`features.verified ==
  features.total`), `per_verified_feature.cost` and `.tokens`, `tokens.cache_hit_rate`, `orientation.tokens`,
  `tokens.context_peak`, `time.wall_h` and `rework.length`. A task's value is **pass^N** for pass rate (1 only if
  every repeat passed) and the mean of the repeats otherwise (nulls dropped). The totals use only the repeats every
  compared task has (a partial last repeat is left out, and the output says so): pass rate is the share of tasks with
  pass^N 1, per verified feature is the sums over tasks divided by their verified features, the rest the mean over
  tasks; their noise is the spread of the per-repeat totals. The verdict: `no data` when a side has no value (the
  per-verified-feature metrics are null when nothing verified), `one sample` when a side has one value, `within
  noise` when |B − A| ≤ the larger of the two spreads (max − min across repeats), else `better` or `worse` for B in
  the metric's direction (higher pass rate and cache hit rate, lower everything else). `harness eval compare <A> <B>`
  (`lib/eval.sh`; a path or a name under `evals/results/`) prints the table, the totals block, notes (the tasks found in
  only one result, failed runs, repeats left out of the totals, and unequal repeat counts: pass^3 is harder than
  pass^2), and one `<metric>: <verdict> (A <a>, B <b>)` line per metric. It reads files and spends nothing.
  *Default:* `no data` is a fifth verdict besides the spec's four, and "one sample" counts a side's non-null values,
  not its repeats.
- **Rejected:** a statistical test (two or three repeats are too few for one to mean anything; the spread is the
  spec's rule and errs towards "within noise"); totals over every repeat a task has (a partial repeat would weigh the
  tasks that ran in it twice); judging by the mean of per-repeat pass rates (hides a task that fails one run in two,
  which pass^N exists to show); skipping a unit dir without a summary (a crashed run would read as "not in the set"
  and its side would look better).
