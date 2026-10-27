# The review gate: a milestone review's model by its measured diff, one Opus round after a Sonnet finding

*(2026-10-27, run agent-harness-2026-10-25-memory, features M6-02 and M6-03; spec `docs/specs/2026-10-25-memory.md`
§ M6 = `docs/specs/2026-10-22-retro-followups.md` § D, plan `docs/plans/2026-10-26-M6-review-gate.md`)*

- **Finding:** the milestone review feature is 14–34 % of a run (24.5 % across the 12 runs with data) and always ran
  on Opus; "cap or route per-milestone review" is the most-repeated retro proposal (8 retros). It is not waste: it
  caught at least one Critical (rane M3-06) and ~45 Important findings no in-session review could see. So it stays
  for milestones of three or more build features (R2, `decisions/2026-10-26-reviews-sized-to-milestone`) and gets
  cheaper, not absent.
- **Choice:** for a `review` feature the driver measures the milestone diff (`git diff --shortstat
  origin/<main>...HEAD -- . ':!.harness/runs'`, insertions plus deletions) and runs the session on Sonnet under
  `REVIEW_OPUS_LINES` (400) changed lines, on Opus at or over, overriding the feature's own model; the prompt's
  `Review diff:` line gives the counts. A Sonnet review whose entry summary (else its final message) reports
  `<n> Critical` or `<n> Important` above 0 gets one more session on `REVIEW_ESCALATE_MODEL` (opus) before the next
  pick, costing no attempt, noted `review <id>: sonnet found <c> Critical, <i> Important; one round on opus`; its
  clock line says `Review round 2 of 2 (escalated: …)`. Defaults taken (*default*, Michael's to change):
  1. *default* The Opus round un-passes the review first and owns the verdict, so verify can't run on the Sonnet
     verdict while the round is pending. A deadline between the two sessions leaves the review unpassed; the pending
     round (`review-escalate` in the state dir) runs first on a continue.
  2. *default* Once per feature per run (`review-escalated-<id>`): a later attempt is sized by its diff again and
     never escalates.
  3. *default* No counts found → no round, noted `review <id>: no "<n> Critical, <n> Important" in its summary or
     final message; not escalated`.
  4. *default* A failed diff measure (no `origin/<main>`) → Opus, noted `review <id>: diff not measured (<why>); opus`.
  5. *default* The review session's own reviewer subagent is unchanged (`prompts/coding.md` §2 still sends reviews to
     Opus subagents), so a Sonnet review session saves less than its model suggests; whether to change that line is
     asked in M6-03's entry.
  6. *default* A review that already ran on Opus (at or over the threshold, or the round itself) never escalates.
- **Rejected:** skipping the milestone review when in-session reviews found nothing (§ D: unsafe, the rane Critical
  was cross-feature); measuring from the milestone's first commit (the driver keeps no per-milestone start marker; the
  merge base is what main lacks, which is what a review should read); re-using `verify()`'s two-model loop (the coding
  loop's limit, park and repair handling would be duplicated; a pending-round file sends the round through the same
  loop); escalating on silence (most summaries, the stub's included, give no counts, so every review would escalate).
