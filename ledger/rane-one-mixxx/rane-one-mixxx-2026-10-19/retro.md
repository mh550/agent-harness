## Outcome
Not delivered. 11 of 28 features pass, 6 are verified (all of M1) and 0 are merged. Michael stopped the run at 09:18 on 2026-10-20. It had used 18 sessions, 3.4 h and $49.29 ($4.48 per passing feature). The main reason is a stall in the first segment. M1-04 was parked on a step that could not be satisfied, and the run sat until Michael answered at 08:14 the next morning. About 14 hours of wall time passed with no work done. M2 then ran 4 features in 52 minutes. M1's tag is held because it contains M3-01's unverified work, so nothing has merged.

## Non-passing features by cause
All 17 non-passing features have cause "not reached" and 0 sessions: M2-05..08, M3-02..06 and M4-01..08. Each carries the detail "run ended: stopped by Michael". None failed.
- Stopped by Michael, not by a defect: 17.
- M2-05..08 were next in the queue when the run stopped, and the log has no blocker for them.
- M3-02..06 and M4-01..08 are the same, but I did not confirm that nothing else gated them.
- Cause counts for the other categories: spec 0, too big 0, dependency 0 (apart from M3-02..06 and M4, which never started), denial 0, environment 0, model quality 0, harness bug 0.

## Harness behaviour
- **Guards:** `verify_failed` fired twice, on M1-04 and M1-05 at 18:00. Both were correct. The log shows both steps could not be satisfied as written (M1-04 step 3 and M1-05 step 5). The cost was one Sonnet session at $0.46. Other guards were 0.
- **Blocked scheduling:** M3-01 ran at 18:17 while M1-04 was parked. Everything else, including M2, waited for Michael, so the stall cost about 14 h.
- **Re-verify:** it ran 15 turns in 146 s and re-ran every step, including a live Mixxx start and replay, a hot reload, a clean stop and `npm test` 202/202. It also flagged two caveats it did not check. One was that `reviews/M1.diff` had drifted by 779 lines. The other was that it did not replay the "failing test first" step.
- **Wasted work:** the M1-06 review ($5.70) ran before M1 had been verified, and verify then failed two of its features. M1-05's verify retry waited 14 h.
- **Merge hold:** M1 verified at 08:21 but its tag was held because M3-01's unverified work came before it in history. M3-01 ran out of order, which caused this.
- **Evidence rows:** the first verify session appears to have run steps (22 turns, 201 s). I did not count its rows against the steps.

## Proposed harness changes
1. **Skip parked features and run independent ones** (driver scheduler). Evidence: after M1-04 parked at 18:02, only M3-01 ran. M2 and M4 waited about 14 h. This is a repeat of `pathways/threads-2026-10-17`, `dj-2026-10-17` and the first-segment retro of this run. It is the fourth time, so it is the top priority.
2. **Run a smoke check of each feature's steps before building** (init and plan prompt). Alternatively, let a build session mark a step "unsatisfiable" and park the feature immediately instead of passing it. Evidence: both verify failures were steps the build could not literally satisfy. The first-segment retro of this run proposed this, and `portfolio_site-2026-10-20` repeated it (VC2-06).
3. **Skip the per-milestone review when verify has failed or the milestone is small** (driver config). Evidence: review cost $5.70 for M1-06 and 12% of spend this run. The proposal first appeared in `v2-2026-10-18`, and every later run has repeated it.
