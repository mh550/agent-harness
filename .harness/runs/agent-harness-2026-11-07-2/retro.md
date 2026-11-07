## Outcome
All 12 features passed on the first attempt (`first_attempt_pass_rate` 1, `verify_fail_rate` 0). M1, M2 and M3 were verified and merged as PRs #126 and #127, plus the M1 PR. The run cost $59.51 over 5.05 h wall time ($4.96 per passing feature). Build took $32.44, review $12.25 and verify $0.75. No repairs, limit waits or escalations occurred. The one real inefficiency was two sessions that ran the full suite twice, at 1436 s and 2074 s. checks: +75 ~7 −5 (M1 +12 ~5 −5, budget 30; M2 +47 ~0 −0, budget 60; M3 +16 ~2 −0, budget 35)

## Non-passing features by cause
None. Every feature passed, so there are no "not done" features to assign a cause.

## Harness behaviour
- **Guards:** `repairs`, `red_unpass`, `verify_failed`, `limit_waits` and `verify_escalations` are all 0. Only the 3 milestone merges fired, and those were correct. The review-size guard fired on M2-05 (1855 changed lines) and M3-04 (640 lines), both ≥400, and routed both to opus as designed.
- **Suite time:** a single suite run took about 113 s in every other session. Two sessions ran it twice:
  - M2-05: 1436 s.
  - M3-04: 2074 s.
  The prompt asks for one fast-tier run last, so these runs exceeded it. Together they cost about 55 min of the 4.29 h of session time. This is `suite-time-budget` again.
- **Suite counts:** `suite_runs` is 4 full and 9 fast across 12 sessions (0.3 and 0.8 per session). That is within the prompt's ask apart from the two sessions above.
- **Verify evidence:** the verify entries carry evidence rows: M1 has 20, M2 has 30 and M3 has 22. I did not match them to the feature steps, so I can't say whether verify re-ran every step. The M1 and M2 verifies cleared the suite cache and ran the suite in full, as `verify-fresh-suite` (merged) requires. Linking evidence rows to steps is still `verify-evidence-rows`.
- **Questions:** sessions left 1 question each for Michael on M2-05, M3-02 and M3-04. They did not block the run.

## Proposed harness changes
1. **`suite-time-budget`** (proposed, seen 7): cap or warn on a session's second full suite run in `lib/check.sh` or the coding prompt. Evidence: M2-05 (1436 s) and M3-04 (2074 s) each ran the suite twice.
2. **`verify-evidence-rows`** (proposed, seen 8): record, per verify entry, which step each evidence row covers. Evidence: the 3 verify sessions cost $0.76 combined and left 72 evidence rows that can't be matched to steps.
