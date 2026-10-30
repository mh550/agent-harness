## Outcome
Delivered: 23/23 features passed, verified and merged (R3 via PR #61, R4 via PR #62). The run cost $91.07 over 11.7 h wall time and 42 sessions. Build was $44.41 and review $24.25. The first-attempt pass rate was 0.65 and the verify fail rate 0.21. Eight features needed rework: R1-02, R2-01 and R3-01 to R3-06. The main cost of rework was a red suite under load, not bad code.

## Non-passing features by cause
No feature ended "not done", and `summary.json` has `causes: null`. These features were un-passed along the way:
- R2-01 and R1-02 were un-passed with "suite red after the session". That is environment (suite flakiness under load). Evidence: "R2-01 un-passed: suite red after the session".
- R1-02 was reset to `passes false` again after R1-03 (13:33). That is environment, not model quality. Evidence: "restored the feature list after R1-03: R1-02: passes true → false".
- The 6 verify failures and 1 verify escalation were recovered. I did not trace their causes individually.

## Harness behaviour
- **Suite flakes:** the driver logged at least 7 "flaky: … (red, then green on a rerun)" notes, at load 1.4 to 8.2. Examples are `13-run-2-michael-sets-desk` (twice), `47-lanes-two` (twice), `28-run-14d-harness-merge` (twice) and `32-l5-queue-runner-re`. The rerun logic worked at the end-of-session gate. The two un-passes (R2-01 and R1-02) show it did not cover the per-session check.
- **Driver-owned files:** sessions edited `entries.jsonl` and `progress-archive.md` about 10 times (R1-01, R2-01, R1-02, R2-02, R2-04, R1-03, R2-05, R1-04, R4-04, R4-05). The driver restored them each time, which was correct, but the sessions kept doing it.
- **Merges and conflicts:** R4 hit a `CLAUDE.md` conflict with main. The resolve session took 1 min and cost $1.06 in total for 3 resolves. That was cheap and correct.
- **Context packs:** every one left out 1 to 13 items. I saw no failure caused by this.
- **Verify evidence:** I did not audit evidence rows against steps. `entries.jsonl` carries `verified_how` but no per-step rows, so that audit is not possible. The `verify-evidence-rows` item is still unfixed.

## Proposed harness changes
1. **`suite-flake-retry`** (proposed, seen 3 → 4): rerun failed test files serially before un-passing a feature. Evidence: the R2-01 and R1-02 un-passes, and 7+ flaky notes at load 5 to 8.
2. **`verify-evidence-rows`** (proposed, seen 3 → 4): record per-step evidence rows from verify sessions. Evidence: 6 verify sessions and 6 verify failures, with nothing to audit.
3. **`session-entry-write-guard`** (new): state in the session prompt that `entries.jsonl` and `progress-archive.md` are driver-only. Evidence: about 10 "edited by the session; restored" events.

The proposals are written to `retro-proposals.json`.
