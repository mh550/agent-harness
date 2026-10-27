## Outcome
The run was stopped by Michael at 00:13 with 7 of 17 features passing (P0-01..04, P1-01..03). It ran 16 sessions in 7.57 h and cost $68.95 ($9.85 per passing feature). Only P0 was verified and merged (PR #30). P1-04 was un-passed because the suite was red after its 58 min session. The 10 features after it were not started. The stop itself was Michael's, to rebase onto main after conflicts in `lib/driver.sh`. The run had already been blocked twice before that, on P0-02 and P1-03.

## Non-passing features by cause
There are no "not done" features in the summary, and `cause` is null. Reading the log, P1-04 is the only feature that did not pass at the end. Ten features were never started.
- **P1-04, too big for one session.** `lib/lane.sh` and the `lib/driver.sh` rewrite were combined with a `lib/record.sh` extraction, per-lane units and scratch, and a new check file. The session's last entry ends with "per-lane units, scratch, prompt files; metrics…", then "suite red after the session".
- **P0-02, spec problem.** Resolved later, once a rule was added that a time is measured rather than gated. Evidence: "step 5 (<150 s) can't be met… per-file slot times add up to 636 s".
- **P1-03, harness bug.** Two failed sessions (39 and 11 min) had no `entry.json` ("entry.json missing; recorded a minimal entry"). Its last entry before passing described a review that was "still running", so the session probably ended before it wrote its entry.
- **Never started:** 10 features, all dependents of P1-04.

## Harness behaviour
- **Guards:** `red_unpass` fired once, on P1-04, correctly. There were no repairs, limit waits or verify escalations.
- **"Blocked… needs Michael" gave up too early.** The driver ended the run twice (08:30 and 18:53), each time after only two failed attempts on one feature. Each time the run sat idle for hours until Michael resumed it, which is 7.57 h of wall time against 6.8 h of sessions. The P0-02 retry passed in 21 min once the spec changed.
- **Merge conflict.** At 22:40 "main conflicts… carrying on without it" meant a branch that diverged from main while `lib/driver.sh` was rewritten. That led to Michael's stop.
- **Plan role:** $10.58 for 0.57 h, which is more than review and verify combined.
- **Context.md:** "test count: no match in the suite's output" at 16:03, so test counts went unrecorded.
- **Verify:** only one verify session ran, for P0 ($0.24, 4.3k output tokens). `verify_fail_rate` is 0. Evidence rows against steps can't be judged from that. This looks like a spot check, not a re-run of the steps.
- **Rework:** P0-02, P1-03 and P1-04. First-attempt pass rate was 0.63.

## Proposed harness changes
1. **Warn about size before a feature starts.** In the context-pack or planning step, flag a feature that touches the driver core plus a refactor plus new checks, and split it before the session. Evidence: P1-04 ran 58 min and ended red. No earlier retro seen.
2. **Ask for `entry.json` when it is missing.** In the session-end handler, resume the session once for the entry instead of recording a minimal one. Evidence: P1-03 lost 50 min across two sessions. I did not check earlier retros.
3. **Merge main into the run branch at milestone boundaries.** In the driver, merge main at each milestone, not only after a block. Evidence: `lib/driver.sh` conflicts surfaced at 22:40 and ended the run. I did not check earlier retros.
