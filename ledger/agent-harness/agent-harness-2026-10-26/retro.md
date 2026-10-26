## Outcome
Not delivered. 2 of 17 features passed (P0-01, P0-03). Nothing was verified or merged. The run ended "blocked on P0-02" after 5 sessions, 2.8 h and $22.76 ($11.38 per passing feature). The 14 other features waited on P0-02 and never started. The cause is a measured-performance step in P0-02 that the box could not meet.

## Non-passing features by cause
- **P0-02 (not done): spec or feature-list problem.** Step 5 required a wall time under 150 s with `TEST_JOBS=4`. The suite was green (335/335) in 165 s, and the session wrote "I left `passes` false because step 5… isn't met". Two sessions (87 min, $10.44) went to a step that is a measurement, not a behaviour.
- **P0-04, P1-01 to P1-06, P2-01 to P2-07 (12 features): depends on a failed feature.** The detail reads "waits on P0-02, which was given up". I checked 4 of them. The `summary.json` listing I printed was cut off, so I did not check the rest. P0-04, P1-01 and P1-02 were also not touched.
- I only read the end of P0-02's last progress entry, not its final result event.

## Harness behaviour
- All guard counters were 0: repairs, red_unpass, verify_failed, limit_waits, verify_escalations and merges. Nothing misfired.
- **Dependency blocking cost the whole run.** The driver treats "given up" on P0-02 as blocking every later feature. That includes P1 and P2 features that cannot plausibly depend on suite speed, such as P1-02 to P1-04.
- **Verify never ran, so I can't say whether verify re-ran steps.** `verified` is 0 and `verify_fail_rate` is null. Milestone verification only happens when a milestone completes.
- **Orientation was costly.** It took 843k tokens over 15 turns (186 s). Context peaked at 206k, and the cache hit rate was 97.4%.
- **P0-01 took 54 min.** P0-03 took 14 min and cost $2.69.
- **A session ended with uncommitted work.** `f382a3c WIP: P0-03 — uncommitted at session end` means a session ended without committing, and the driver rescued it. The cause of that is unconfirmed.
- The init session ran on fable ($4.71). The init progress entry records two open questions for Michael with defaults taken (S4 skipped; lane port unchanged).

## Proposed harness changes
1. **Give a feature a measured-target escape.** In `lib/features.mjs` and the init prompt, a step that is a threshold on a measurement (wall time, memory) needs a fallback: record the measurement in the decision file and pass if every behavioural step holds. Alternatively, init splits the measurement into a separate `review` feature. Evidence: P0-02 held steps 1–4, 6 and 7 and was blocked on 165 s against a 150 s target. I did not check earlier retros for this proposal.
2. **Block only on real dependencies.** In the driver's blocked logic, add `depends_on` to the feature list and block only a feature's declared dependents. When a feature is given up, continue with the independent features. Evidence: 12 features were blocked at $0 spend after 2 sessions on P0-02. I did not check earlier retros for this proposal.
3. **Cap sessions on a feature that is only missing a measurement.** Add a guard in the driver that gives up a feature after one session in which every step except a threshold step holds. Evidence: the second P0-02 session ran 37 min and cost about $5 without changing the outcome. I did not check earlier retros for this proposal.
