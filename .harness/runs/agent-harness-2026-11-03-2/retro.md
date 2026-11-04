## Outcome
The run delivered all of lane U1. 6/6 features passed on the first attempt (`first_attempt_pass_rate` 1, `verify_fail_rate` 0, no rework). U1 was verified and merged as PR #84. It took 8 sessions, $26.56 and 3.6 h wall time (3.15 h in sessions). Nothing was left undelivered. The main cost was suite time, not failures.

## Non-passing features by cause
None. No feature had cause "not done". Tests rose from 1146 to 1165.

## Harness behaviour
- **Guards:** repairs, red_unpass, verify_failed, limit_waits and verify_escalations were all 0. The only merge was U1's, at the end. Nothing fired, and nothing needed to.
- **Review routing:** U1-06's 2925 changed lines were at or over the 400 threshold, so the review went to opus. That is correct.
- **Suite cost:** each coding session ran the full suite about 800 s (about 13 min).
  - U1-01 ran it twice (1621 s). That is the only session above one run.
  - U1-05 ran 0 times, on sonnet, and still passed.
  - Six sessions at ~800 s is roughly 1.3 h of the 2.44 h build time. `summary.json` reports `full_per_session` 1, so the harness's one-run-last request was honoured. The cost is the suite's length.
  - The 10–11 min figure in CLAUDE.md is stale. This run's numbers fit that range, so it is only slightly low.
- **Verify:** it ran the suite fresh ("suite cache cleared"). It took 0.03 h and $0.25. `entries.jsonl` holds no evidence rows, so I can't confirm it re-ran each step. That is the existing `verify-evidence-rows` gap.
- **Question for Michael:** U1-02 recorded one question, about naming checks split across two fixture names. It had a default, the session continued, and the question cost no time. I did not check whether anyone answered it.
- **Init:** the init session ran on fable and cost $4.26 (16% of the run). That seems fine for a 6-feature plan, but I have no baseline from earlier runs to compare it with.

## Proposed harness changes
1. **`suite-time-budget`** (proposed, seen 3, now 4). Warn or cap on session suite runs. Evidence: U1-01 ran the suite 2x for 1621 s, and the other sessions took ~800 s each. A cheaper option is to let sessions run a subset (`tests/run.sh <topic>`) and leave the one full run to the driver or verify.
2. **`verify-evidence-rows`** (proposed, seen 5, now 6). Record per-step evidence rows from verify sessions in `entries.jsonl`. Evidence: the verify session took 0.03 h and left no auditable rows.

Both are written to `retro-proposals.json`. I proposed only two changes because nothing else in this run called for a harness change.
