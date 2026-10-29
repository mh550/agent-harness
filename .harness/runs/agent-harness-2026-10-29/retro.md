## Outcome
10 of 11 features passed. N1 (N1-01 to N1-05) was verified and merged as PR #48. N2 is 6/6 built, but the N2 verify failed N2-02 on the re-check. A second attempt (2 min) parked it as waiting on Michael. Cost was $52.91 over 7.5 h wall (6.6 h in sessions). The main reason is a contradiction in the N2-02 step wording. The code does what the spec intends.

## Non-passing features by cause
- **N2-02 (parked, one feature): spec or feature-list problem.**
  - Its last entry says: "Parked: step 2's 'exit 1 with A untouched' contradicts its own '(git reports the conflict as usual)'. git 2.43 keeps A as the result whatever the driver's exit…"
  - The first attempt passed at 06:07. The N2 milestone verify then failed it at 08:46.
  - The INBOX asks Michael to reword step 2 to "a conflict exits 1 with its markers in A".
- **Rework without a final failure:** N1-03 failed its first attempt (77 min, `passes=false`) and passed on the retry (1 min).
- No other non-passing features. `causes` in `summary.json` is null.

## Harness behaviour
- **Guards:** `verify_failed` fired once, correctly. It caught a real spec contradiction that the build session's own pass had missed. There were no repairs, red un-passes, limit waits or escalations.
- **Review routing:** N1-05 (667 changed lines) and N2-06 (1413) were both routed to opus. Review cost $9.64 of the $52.91, and the log doesn't say what it found.
- **Waste:** the retry of N2-02 cost 2 minutes and changed no code. The session only confirmed the contradiction, which was inevitable.
  - The spec contradiction cost the run its last feature.
  - N1-03's first attempt took 77 min and failed. The log doesn't say why.
- **Verify evidence:** verify sessions were cheap (2 sessions, $0.44, 0.07 h, sonnet). No per-step evidence rows are in `entries.jsonl`, so I can't confirm each step was actually re-run. The N2 verify did catch a real defect, which suggests it did re-run the steps.
- **Cache and context:** cache hit rate was 97.2%. Context peak was 228k tokens.

## Proposed harness changes
1. **`step-lint`** (merged as retro-fixes R3, which lints the form of steps). Extend it to flag a step whose clauses contradict each other, or to have the init session cross-check each step against the behaviour it describes. Evidence: N2-02 step 2 contradicts itself. The contradiction cost one parked feature, a failed verify and about $1 of retry.
2. **`verify-evidence-rows`** (proposed, seen 1, now seen 2). Have verify sessions record one evidence row per step in `entries.jsonl` so re-runs can be audited. Evidence: no rows exist for either N1 or N2 verify.

Proposals are written to `retro-proposals.json`.
