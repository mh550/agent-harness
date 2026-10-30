# The review gate: a milestone review's model by its measured diff, one Opus round after a Sonnet finding

*(2026-10-27, run agent-harness-2026-10-25-memory, features M6-02, M6-03 and M6-04; spec `docs/specs/2026-10-25-memory.md`
§ M6 = `docs/specs/2026-10-22-retro-followups.md` § D, plan `docs/plans/2026-10-26-M6-review-gate.md`)*

- **Finding:** the milestone review feature is 14–34 % of a run (24.5 % across the 12 runs with data) and always ran
  on Opus; "cap or route per-milestone review" is the most-repeated retro proposal (8 retros). It is not waste: it
  caught at least one Critical (rane M3-06) and ~45 Important findings no in-session review could see. So it stays
  for milestones of three or more build features (R2, `decisions/2026-10-26-reviews-sized-to-milestone`) and gets
  cheaper, not absent.
- **Choice:** for a `review` feature the driver measures the milestone diff (main fetched first, then `git diff --shortstat
  origin/<main>...HEAD -- . ':!.harness/runs'`, insertions plus deletions) and runs the session on Sonnet under
  `REVIEW_OPUS_LINES` (400) changed lines, on Opus at or over, overriding the feature's own model; the prompt's
  `Review diff:` line gives the counts, and its `Review findings:` line asks for the entry summary's `<n> Critical,
  <n> Important, <n> Minor`, the one form the driver reads. A Sonnet review whose entry summary (else its final message) reports
  `<n> Critical` or `<n> Important` above 0 gets one more session on `REVIEW_ESCALATE_MODEL` (opus) before the next
  pick, costing no attempt, noted `review <id>: sonnet found <c> Critical, <i> Important; one round on opus`; its
  clock line says `Review round 2 of 2 (escalated: …)`. Defaults taken (*default*, Michael's to change):
  1. *default* The Opus round un-passes the review first and owns the verdict, so verify can't run on the Sonnet
     verdict while the round is pending. A deadline between the two sessions leaves the review unpassed; the pending
     round (`review-escalate` in the state dir) runs first on a continue.
  2. *default* Once per feature per run (`review-escalated-<id>`): a later attempt (the round parked or didn't pass)
     runs on `REVIEW_ESCALATE_MODEL` and never escalates, so the round's model keeps the verdict. `harness continue`
     keeps the marker.
  3. *default* No counts found → no round, noted `review <id>: no "<n> Critical, <n> Important" in its summary or
     final message; not escalated`.
  4. *default* A failed diff measure → Opus, noted `review <id>: diff not measured (no origin/<main>); opus`. A failed
     fetch measures from the ref the worktree has.
  5. *default* The review session's own reviewer subagent is unchanged (`prompts/coding.md` §2 still sends reviews to
     Opus subagents), so a Sonnet review session saves less than its model suggests; whether to change that line is
     asked in M6-03's entry. Michael's answer (2026-10-28): change it. The reviewer subagent follows the review
     session's model (Sonnet under `REVIEW_OPUS_LINES`, Opus at or over it and in the escalation round), judged by
     the ledger's `review_cost_pct` and verify-fail rate. To be built by `docs/specs/2026-10-28-reliability.md`;
     this default stands until then.
  6. *default* A review that already ran on Opus (at or over the threshold, or the round itself) never escalates.
  7. *default* (M6-04) What it saves is measured, not claimed: `summary.json` gains `review.cost_pct` (the review
     role's cost over the run's, in % with one decimal, null without a review session) and `review.found_nothing`
     (review features whose every entry giving counts, one at least, reports `0 Critical, 0 Important`, out of
     `review.reviews` with an entry: an escalated review's clean Opus verdict doesn't make it one that found nothing);
     `report.md` shows both in a `Review share` row, the ledger row adds `review_cost_pct` (`harness trends` keeps
     its columns), and `rework` no longer counts the Opus round as a second try. The cost claim waits for the evals
     in `evals/NEXT.md` § 5, which Michael runs.
- **Rejected:** skipping the milestone review when in-session reviews found nothing (§ D: unsafe, the rane Critical
  was cross-feature); measuring from the milestone's first commit (the driver keeps no per-milestone start marker; the
  merge base is what main lacks, which is what a review should read); re-using `verify()`'s two-model loop (the coding
  loop's limit, park and repair handling would be duplicated; a pending-round file sends the round through the same
  loop); escalating on silence (most summaries, the stub's included, give no counts, so every review would escalate);
  measuring from the newer of the merge base and the previous milestone's `run/<run>/<m>` tag (the M6 review's
  suggestion: under `MERGE_POLICY=pr` an earlier milestone waiting in its PR still counts, which leans to Opus, the
  safe side; one more base rule isn't worth it until a real run shows the cost).

Updated in place 2026-10-27 (M6-05, the M6 review, `docs/plans/2026-10-26-M6-review.md`): main is fetched before the
measure (a self-merged milestone stayed in it until the next verify); the prompt asks for the counts in one form and
`reviewFindings` reads only that (capitalised, pair first, never `M3-06 Critical` or `step 1 important`);
`found_nothing` reads every entry of a review, not its last; defaults 2 and 4 as above; the round's `Review diff:` line
ends `; escalated to <model>`.

Updated in place 2026-10-28 (Michael's answers to the memory run's M6 questions): default 5 as above. Review Minor 8
(`docs/plans/2026-10-26-M6-review.md`) gets a fix only if it is cheap beside other review leftovers; until then the
`one round on opus` note is the signal. No review-bearing eval task for now: the gate's cost is judged on the real
runs' `review_cost_pct` (`evals/NEXT.md` § 5's fallback) until a first eval baseline has run.

Updated in place 2026-10-29: built (R3-04, decisions/2026-10-29-lanes-leftovers) the reviewer on the session's own
model: `prompts/coding.md` sends reviews to subagents on `{{MODEL}}` (`HARNESS_MODEL`, the session's model after the
gate's sizing; `lib/prompt.sh` by hand fills the feature's), so a Sonnet review's reviewers are Sonnet and an
escalated or at-size one's are Opus, judged by the ledger's `review_cost_pct` and the verify-fail rate. And Minor 8:
the gate now runs before the session's record flip, metrics row and `passes=` note, so an escalated review's first
row and note say `passes=false` (`passed=false` in place of a later `record F unpass`); the park's records follow the
note as before.
