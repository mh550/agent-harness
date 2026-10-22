# compare's per verified feature is Σ spent / Σ verified over every repeat, not a mean of the repeats that verified

*(2026-10-21, E2-08 of run agent-harness-2026-10-21-measure, review finding F2 in `docs/plans/2026-10-21-E2-review.md`;
amends `decisions/2026-10-21-eval-compare-verdicts`)*

- **Finding:** a task's `$ per verified feature` and `tokens per verified feature` were the mean of its repeats'
  `per_verified_feature`, which is null when a repeat verified nothing, so that repeat's spend vanished. The total was
  the mean of per-repeat Σ/Σ, dropping a repeat in which no task verified. A version whose third repeat spent $20 and
  verified nothing read as $1.05 per verified feature and "better" than a steady $2, when it really cost $11.05.
- **Choice:** the value of a side is pooled: per task, Σ `cost.total` (or Σ tokens) over its repeats / Σ
  `features.verified`; in total, the same over every complete repeat of every task. The per-repeat ratios stay the
  side's values, so the noise and the one-sample and no-data rules are unchanged. Also: an empty feature list
  (`features.total` 0) is no pass. Checked by `eval.mjs: per verified feature counts every repeat's cost`.
- **Rejected:** counting a zero-verified repeat as an infinite ratio (every verdict "within noise"); counting it as
  its cost over one feature (an invented number).
