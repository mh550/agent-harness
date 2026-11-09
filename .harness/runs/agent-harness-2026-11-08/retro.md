## Outcome
The run delivered N1's four features (N1-01 to N1-04), all with `passes=true`, but none verified or merged. N2 (four features) was not reached. Verify N1 ran the full suite fresh, but its evidence fell short of the steps in all three features it checked (N1-03 6/7, N1-02 6/7, N1-01 7/8). It re-ran on opus, still came up short, and closed the lane as "needs Michael". Cost was $31.83 over 2.85 h wall time: 4 of 8 features passing, $7.96 per passing feature. First-attempt pass rate was 1, with no rework, no flakes and no guard repairs. The main reason for the stop is the verify evidence gap. Three coding sessions also left design questions for Michael (N1-03, N1-02, N1-04), recorded in `needs.md`.

checks: +13 (the suite's count, 1898 → 1911)

## Non-passing features by cause
The four N2 features (N2-01 to N2-04) are the only non-passing ones. Their cause is "not reached" (0 sessions): `depends on a failed feature`, since they wait on N1. Evidence: `run ended: waiting on Michael: N1`. No other causes occurred.

## Harness behaviour
- **Guards:** none fired. There were 0 repairs, 0 red-unpass, 0 limit waits and 0 merges. The verify evidence check fired and stopped the lane. It is correct that the step gap was caught, but it cost the whole N2 milestone.
- **Verify evidence:** verify did not demonstrably re-run every step. There were 7 steps against 6 rows for N1-03, 6 against 5 for N1-02, and 8 against 7 for N1-01. The summary does not say which step each row was missing or why. The escalation to opus (about $2.50 for verify) did not close the gap. Rows are not recorded per step in `entries.jsonl`, so I cannot say whether the steps were skipped or just not logged.
- **Suite time:** N1-04 ran the suite twice in the session, 1491 s in total. N1-02 ran it 5 times (388 s) while the suite_runs counter shows 0.5 full runs per session. CLAUDE.md says to run the fast tier last, and sessions ran the suite more than that. Orientation cost 8.4M tokens over 79 turns (about 21 min).
- **Review:** one review, 18% of cost ($5.79). It found something, so it was not wasted.
- **Memlint:** the init session logged "CLAUDE.md:98 gotchas: 16 lines, over 15". Sessions do not run memlint at the end, so overflow is only caught by the driver (`memlint-before-session-end`, seen once).

## Proposed harness changes
1. `verify-evidence-rows` (proposed, seen 10). Have verify sessions record one evidence row per step in `entries.jsonl`, and report the missing step by name. Evidence: all three features were short by one step, with nothing saying which.
2. `verify-failed-recheck` (proposed, seen 1). After thin verify evidence, re-verify only the short steps instead of closing the lane for Michael. Evidence: one opus retry, then lane closed, N2 never started.
3. `suite-time-budget` (proposed, seen 9). Warn or cap repeated full-suite runs in coding sessions. Evidence: N1-04 spent 1491 s on 2 suite runs and N1-02 ran the suite 5 times.

Proposals written to `retro-proposals.json`.
