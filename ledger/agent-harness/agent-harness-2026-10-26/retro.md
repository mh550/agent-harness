## Outcome
Delivered 8 of 17 features. P0 (4 features) was verified and merged as PR #30. P1-01 to P1-04 pass, but P1 was never verified or merged. P1-05, P1-06 and all 7 P2 features were not reached. The run cost $69.99 over 18 sessions and 7.85 h wall, across 3 continuations. Michael stopped it three times. The last stop was "merge main's flake fix (PR #39) first". The first two were a blocked P1-03 and a rebase onto main (conflicts in lib/driver.sh). Most of the loss was the wait between continuations (driver_h 0.88, but about 15 h of calendar gaps), not session quality.

## Non-passing features by cause
No feature has cause "not done". The 9 non-passing features all read "not reached": P1-05, P1-06, P2-01 to P2-07. Three features needed rework and ended passing: P0-02 (3 sessions), P1-03 (3 sessions, $16.11) and P1-04 (2 sessions, $12.50).
- P1-03, harness bug: "P1-03: entry.json missing; recorded a minimal entry" appeared twice (18:38 and 18:53). The session was still waiting on an Opus review when it ended, and it said "I'll wait for its findings before I fix anything".
- P1-04, environment: "P1-04 un-passed: suite red after the session". Cause: a stale probe prompt scratch, plus a flake that main fixed in PR #39.

## Harness behaviour
- Guards: red_unpass fired once, on P1-04. The suite really was red, so it was correct.
- The "blocked: the remaining features wait on P1-03 (given up; needs Michael)" stop fired after only two sessions. The second session was 11 min and ended with no entry. Michael resumed it later and P1-03 passed in 22 min. That gave up too early, and it cost about 4 h of idle time.
- "main conflicts with harness/agent-harness-2026-10-26; carrying on without it" appeared twice. The run kept building on a base that main had moved past. That is why Michael stopped it to rebase and then to merge the flake fix. Both stops cost a full continuation.
- Orientation cost 1.24M tokens over 16 turns (280 s), and the largest context peak was 314k.
- Plan sessions cost $10.58 for one feature (P1-01).
- Verify ran once, on P0, and cost $0.24. Evidence rows were present for P0-02 and P0-03 across steps, but I did not count rows against steps in full. Verify fail rate was 0 and first-attempt pass rate was 0.63.
- Cache hit rate was 0.971, which is fine.

## Proposed harness changes
1. lib/driver.sh, session end: when entry.json is missing but a background review or subagent is still pending, don't record a minimal entry and don't count it toward the "given up" block. Resume the same session once instead, or write the entry from the session's last message. Evidence: both P1-03 failures. I can't tell from the ledger files I checked whether an earlier retro proposed this.
2. lib/sync.sh and lib/driver.sh: when main has conflicts or has moved on, stop at the next feature boundary and notify Michael once. Today the run carries on and the merge conflict grows. Alternatively, rebase onto main between milestones when the tree is clean. Evidence: two "carrying on without it" lines, then two Michael stops. I haven't checked earlier retros for this.
3. A flaky-check guard: if the suite goes red, rerun the failing check once before un-passing the feature. Quarantine a check that passes on rerun and record it with `note`. Evidence: the PR #39 stop came from a flaky check. Not checked against earlier retros.
