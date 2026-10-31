## Outcome
The run delivered everything. All 6 features of milestone F1 passed and were verified. F1 merged to main as PR #71. The run cost $22.61 over 4.7 h of session time (5.4 h wall) and used 9 sessions. Tests went from 1080 to 1084. First-attempt pass rate was 1.0 and verify_fail_rate was 0. Build sessions were the main cost: $12.65 of $22.61, with the suite itself taking much of their wall time.

## Non-passing features by cause
None had cause "not done". F1-06 was the only feature that needed a second session. The review found 1 Important issue, so the review session was marked passes=false at 21:25. A second session on opus then passed it. That is one review round, not a failure. The other counts are 0.

## Harness behaviour
- **Guards:** none fired. Repairs, red_unpass, verify_failed, limit_waits and verify_escalations were all 0, and there was 1 merge.
- **Flake:** `08-scope-sh-l1-02-run-capped-services-gc-scratch` was red and then green on a rerun (load 1.34). The driver recorded it as a flake and didn't un-pass F1-05, which was correct. This is still the same manual rerun pattern as `suite-flake-retry`.
- **Suite time:** in-session suite runs took 1220 s (F1-04), 1002 s (F1-05) and 839 s (F1-06). The first F1-06 session ran 0x. The verify step then cleared the cache and ran the full suite again. CLAUDE.md quotes 10–11 min, so these runs were slower, and each one is a large share of a 25–76 min feature. This is `suite-time-budget`.
- **Verify:** it re-ran steps. Its entry carries 42 evidence rows, each with ran/saw/holds, and the verify session cost only $0.24.
- **Evidence quality:** F1-01 steps 1 and 2 have identical `saw` text. The rows exist, but the audit trail is coarse, so `verify-evidence-rows` is partly in place.
- **Question for Michael:** F1-06 left one open question about whether subset `tests/run.sh` should be red on a missing check name. A default was taken and the run did not stall.

## Proposed harness changes
1. **`suite-time-budget`** (proposed, seen 1 before this run). Warn or cap on session suite runs, and have the prompt steer sessions to subset runs. Evidence: the 839–1220 s runs above.
2. **`suite-flake-retry`** (proposed, seen 4 before this run). Rerun failed files serially before treating the suite as red. Evidence: the F1-05 flake above. The driver already reran it, so the remaining work is to formalise that.

I made no third proposal. Nothing else in this run showed a harness cost. I wrote the two proposals to `retro-proposals.json`.
