## Outcome
All 13 features passed (VC4: 6, VC5: 7) in 21 sessions, $38.13 and 3.1 h. VC4 was verified and tagged, and PR #19 was proposed. VC5 was not verified, so it is left for Michael. The cause was the verify session recording 7 evidence rows for VC5-01's 8 steps, twice, even after an opus rerun. The run ended "done" with nothing merged. The cost was $2.93 per feature.

## Non-passing features by cause
No feature has cause "not done". Two other causes: 3 features failed their first verify (VC5-01, VC5-03, VC5-04) and passed on the retry; 1 feature (VC5-01) has an evidence-count problem that looks like a harness or verify-prompt bug.

## Harness behaviour
- **Guards:** `verify_failed` fired 3 times, and each feature then passed on its retry. `verify_escalations` fired once. Repairs, red_unpass and limit_waits were all 0.
- **Evidence-short guard:** it fired correctly on the evidence count, but the cause is probably a mismatch in how rows are counted. The first table in progress.md shows VC5-01 with 7 numbered rows (steps 1–7) and the second table also has 7 rows. Either the feature list holds 8 steps and the verifier merged two, or the guard counts steps differently than the rows are written. Either way the escalation spent an extra opus session and ended with "needs Michael" for a milestone whose checks all read "hold". This is not confirmed from the logs; I did not open the verify transcripts.
- **Retries:** the three re-queued features cost about $5 in rebuild sessions. The log gives no reason for the three failures.
- **Verify depth:** verify did re-run steps. For example, it ran jest and the full suite (81 suites, 1115 tests). The VC5-02 step 5 row says check.sh was "green, cached", so it did not rebuild.
- **Tests counter:** summary.json shows `tests` 6→6, while verify saw 1115. This is the same bug seen in earlier portfolio_site runs.
- **Review and plan cost:** review was $5.47 and plan $6.42 of $38.13. Plan cost covers VC4-01 and VC5-01, which was $4.86 over 2 sessions.

## Proposed harness changes
1. **Fix the tests counter in the summary generator** so it reads the jest "Tests:" total. Evidence: 6→6 against 1115 here. The retros for `v2-2026-10-18` and `portfolio_site-2026-10-20-2` both proposed it, so this is a repeat.
2. **Make the evidence-vs-steps check tolerant and explain itself** (verify guard in the driver). It should log which step is missing and accept a row that groups steps. Failing that, it should run a cheap sonnet check rather than an opus rerun. Evidence: VC5-01 7/8 twice, with no explanation in harness-log.md. No earlier retro proposed it.
3. **Make verify rebuild instead of trusting a cached check** (`.harness/check.sh` or the verify prompt). Evidence: "green, cached" in the VC5-02 step 5 row. `portfolio_site-2026-10-20-2` proposed this, so it is a repeat.
