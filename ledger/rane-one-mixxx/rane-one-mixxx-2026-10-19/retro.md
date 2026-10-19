## Outcome
Not delivered. 5 of 28 features pass and 0 are verified or merged. The run ended at 18:17 with "waiting on Michael: M1-04" after 10 sessions, 2.3 h and $33.54 (about $6.71 per passing feature). M1-01..03, M1-06 and M3-01 passed. The main reason is a spec defect: M1-04 step 3 cannot be satisfied under `--controller-debug`. It parked M1-04, and the driver then blocked all of M2 and M4 behind it.

## Non-passing features by cause
- **M1-04**: spec or feature-list problem. Progress: "step 3: no Mixxx version line in mixxx.log; it is in mixxx-dev.stdout". It took 2 sessions and $6.85.
- **M1-05**: spec or feature-list problem. Progress: "step 5: `stop` is a hard kill, no `RaneOne: shutdown` in the log". The verify session was right. Its single retry did not happen before the run ended.
- **M2-01..08, M4-01..08 (16 features) and M3-02..06 (5 features)**: depend on a failed feature. The summary says "waits on M1-04, which is waiting on Michael". Only M3-01 ran before the stall. The M3-02..06 reason is inferred from the same pattern. I did not confirm it in `summary.json`.

## Harness behaviour
- **Verify:** it ran once, as a Sonnet session costing $0.46, and failed M1-04 and M1-05. Both failures were legitimate and found real unsatisfiable steps. The evidence table for M1-05 has per-step rows, with its steps 1–3 as separate rows, so verify did re-run steps. Verify cost 1.4% of spend and caught both defects. Building M1-04 and M1-05 cost $9.99, so the first-pass "passes=true" claims were false.
- **Review:** M1-06 cost $5.70, 17% of spend, on a milestone that was already failing verify.
- **Wasted work:** the first M1-04 session marked it passing after 37 min ($6.85 across 2 sessions). The retry lasted 1 min and only parked it.
- **Parking:** the driver parked M1-04 correctly. It ran M3-01 (14 min) but then ended the run. The queue did not continue with M1-05's retry or other independent work.
- **Guards:** `verify_failed` fired twice (correct). No other guard fired, and there were no limit waits.

## Proposed harness changes
1. **Skip parked features and continue independent work** (driver scheduler). Evidence: M2 and M4 were blocked, and M1-05's pending retry went unattempted, at 2.3 h of a run that otherwise had headroom. Already proposed by `pathways/threads-2026-10-17` and `dj-crate-streaming/dj-2026-10-17` (28 h lost there). This is the third repeat, so it should be treated as the top priority.
2. **Validate feature steps against the environment in init or plan, with a smoke run before building** (init and plan prompt). Evidence: both verify failures came from steps the build session could not literally satisfy, which the build then marked passing. Not proposed before. As a cheaper alternative, have build sessions record "step unsatisfiable" and park the feature to INBOX at once rather than marking it passing.
3. **Skip or cap review for milestones that fail verify** (driver config). Evidence: M1-06 review cost $5.70. Already proposed by `v2-2026-10-18` and `agent-harness-2026-10-19`, so this is the third repeat.
