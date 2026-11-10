# The memory reviewer counted: its cost and time beside its verdict, the ledger's rows by tier, and the rule that earns `auto`

*(2026-11-09, run agent-harness-2026-11-09, R2 (the fields and the report by R2-01); spec
`docs/specs/2026-11-08-memory-reviewer.md` §R2; the run's brief (2026-11-09 22:45: proceed on the defaults the spec marks
*default*, never park); R1's names as built: decisions/2026-11-09-memory-reviewer.)*

- **Finding:** after R1 every memory PR carries a second reader's verdict on each operation, and the report already
  shows what the curator costs by role. Nothing yet says what the reviewer costs beside what it found, the ledger's
  `memory.jsonl` rows carry no verdict for `harness memory` to count, and the run.log parser knew no `memory review · `
  line, so the session was matched to its metrics row only by being left over.
- **Choice (R2-01):**
  - `memory.json` gains the session's `review_cost_usd` (its transcript's cost, `metrics.mjs cost`, as the metrics row
    reads it), `review_s` (its wall, `S_WALL`) and `review_model` (the resolved model id), `0`, `0` and null when no
    session ran (nothing to review, an input that failed), plus `reviewed_ids` (the input's ids) and `failed_ids` (the
    failed ones with their question, `facts/2:q2`; a bare id for an op not reviewed or reviewed too thin, which fails on
    no question). `memreview.mjs verdicts` gives each op its failing row's `q` for that, its `reason` unchanged.
    `summary.json`'s `memory` carries every key; a `memory.json` without `reviewed` gets none of them.
  - *Default*: the cost and time in the `Memory` row, `· review 3 held · 0 failed · $0.42 · 4 min` (minutes rounded),
    not a row of their own: one row per concern, and the reviewer is the memory concern's. `· review none (<why>)`
    when no review happened, and nothing after `rules PR …` for a summary written before R1, so an old report prints as
    before. `Spend by role` lists `memory-review` after `curator`; `Time` follows run.log, where the reviewer's line
    comes after the curator's.
  - *Default*: the bound is the session's `$3` and 40 turns (R1-01) and the spec's Predictions row (the reviewer at or
    under the curator's cost on the median run, its wall under 6 minutes). A run whose reviewer cost more than its
    curator gets one note after the review's counts, `memory review: cost $<r> over the curator's $<c>`, never a stop:
    the falsifier reads the notes, and one dear review is not a reason to leave a PR unreviewed.
  - `ledger/memory.jsonl`'s rows gain `reviewed`, `held`, `failed`, `review`, `failed_ids`, `merged_by` and
    `review_cost_usd`; the facts row and the rules row of one run each count their own tier's ops from the input's
    `facts/*` or `rules/*` ids (none held or failed without a review). *Default*: `merged_by` is the facts row's alone
    (`driver` or null); the rules row's is always null, since the driver never merges the rules PR (invariant 3) and a
    copied `driver` would hide Michael's merge of it from R2-02's override reading. `review_cost_usd` is the one
    session's, in both rows: never summed across a run's two rows. A row whose summary has `reviewed` but no ids (a run
    between R1 and R2) gets no review fields and reads as unreviewed, rather than a split it cannot make.
  - `parseRunLog` reads `memory review · ` and `  memory-review exit <n>` as one `memory-review` session, matched to its
    metrics row as the curator's is.
- **Rejected:** a `Review` row of its own for cost and time (two rows for one concern); a stop or an unmerged PR on a
  dear reviewer (the cost is read, not enforced, until the Predictions are); the run's whole review counts in both
  ledger rows (the rules PR's held and failed would count the facts' ops); parsing the question out of the reason's
  `(q<n>)` (the verdict knows it); a sub-command in `lib/metrics.mjs` (`cost` already reads a transcript's cost).
