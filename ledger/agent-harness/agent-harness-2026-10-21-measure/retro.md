## Outcome
All 29 features passed and were verified (E1 9, E2 8, E3 5, E4 7). E4 was proposed as PR #10, and 0 were merged. The run took 12.6 h wall time, 37 sessions and $99.89 ($3.44 per passing feature). It stopped once at 18:34 ("blocked on E2-02", 11/29 passing). Michael's answer in `INBOX.md` at 19:57 let it continue. The block cost about 1.4 h of idle time. Main also conflicted at 17:22 and again needed a merge at 19:57.

## Non-passing features by cause
None ended "not done". E2-02 failed twice (13 min each, 3 sessions, $4.97) before passing at 20:08.
- **E2-02: spec or feature-list problem**, with a permission denial as a trigger. Evidence: Michael's answer "E2-02 = agent-harness only. I amended steps 1-2".
- **Other causes:** the 17 features waiting behind it were "depends on a failed feature". E3-02..05 lacked an `after`, so they waited for no real reason. Other causes: 0.

## Harness behaviour
- **Guards:** repairs, red_unpass, verify_failed, limit_waits and verify_escalations are all 0. The "given up" rule fired after 2 attempts, which was correct. Ending the whole run did not follow, since E2-03..06 and E3-02..05 were runnable. The 18:34 run ran E3-01 and then stopped.
- **Wasted money:** review cost $21.33 (21%). E1-09 cost $3.45 and E2-08 took 72 min, both after clean builds. The 4 verify sessions cost $1.45 in total, which is cheap.
- **Verify evidence:** `progress.md` shows evidence tables with one row per feature, for example "E1-05 | 3 | read run.sh:163; metrics output; suite". Rows are not per step, so I cannot confirm each step was re-run. `feature_list.json` holds no evidence field.
- **Missing numbers:** `tests.start` and `tests.end` are null in `summary.json`.
- **Merges:** `merged` is 0 for all 29 features, as designed.

## Proposed harness changes
1. **Don't end the run when a feature is given up** (driver, next-feature selection). Skip it and keep going with every feature that does not depend on it (via `after`), and end only when nothing is runnable. Evidence: the 18:34 stop left 8 features runnable, and 3 of them ran after the resume without the failed one's help. This is new.
2. **Skip or cap per-milestone review for small or clean milestones** (driver config). Evidence: review was $21.33, 21% of the run. Already proposed by `v2-2026-10-18`, `rane-one-mixxx-2026-10-19`, `portfolio_site-2026-10-20` and `voice-concierge-2026-10-20`, so this is at least the fifth repeat.
3. **Record test counts in `summary.json`** (summary generator). Evidence: `tests` is null/null. Already proposed by `v2-2026-10-18` and `voice-concierge-2026-10-20`, so this is a repeat.
