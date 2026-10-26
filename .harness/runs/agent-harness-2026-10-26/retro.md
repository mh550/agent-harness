## Outcome
The run delivered 6 of 17 features, and only P0 (4 features) was verified and merged (PR #30). P1-01 and P1-02 pass but are unverified. It ended "blocked on P1-03" after 13 sessions, $52.81 and 5.4 h of session time. P1-03 (the record moves to its own branch, with lane branches) is a large cross-cutting change: 19 files, a new decision file and rewritten record checks. Both P1-03 sessions ended while an Opus review subagent was still running. The 10 features after P1-03 were blocked behind it, so P1-04 to P2-07 never started.

## Non-passing features by cause
- **P1-03: too big for one session.** It took 2 sessions and $11.67. Evidence: the 18:38 entry reads "The Opus review of the P1-03 diff is still running. I'll wait for its findings…". The 19-file diff made the review long enough to outlast the session. Both transcripts end with `[Request interrupted by user]` on the "Review P1-03 lanes record diff" subagent. The agent never wrote `entry.json` (the log says "entry.json missing; recorded a minimal entry" twice). Session 05 cost $8.77 and session 06 cost $2.90. Session 06 only added the decision file. It never fixed anything or ran the suite.
- P1-04 to P1-06 and P2-01 to P2-07 (10 features): depends on a failed feature. The log says "blocked: the remaining features wait on P1-03 (given up; needs Michael)".

## Harness behaviour
- The blocked guard fired after P1-03 failed twice with no progress. That was correct, and it stopped further spend. `repairs`, `red_unpass`, `verify_failed` and `verify_escalations` were all 0. `first_attempt_pass_rate` was 0.71 (P0-02 and P1-03 needed rework).
- P0-02 also ended "given up" at 08:30 after 3 sessions. The run then sat idle until 15:59, when Michael answered. The idle gap is wall time, not spend.
- Waste:
  - P1-03 session 06 started with a fresh 7.9 KB context. It spent $2.90 and produced nothing but a decision file, because the driver restarted the same too-big task instead of splitting it.
  - Orientation cost 1.05M tokens over 16 turns (278 s).
  - "test count: no match in the suite's output" means `tests.start` and `tests.end` are null.
- Verify: only one verify session ran (P0, $0.24, 24 turns). That is too few to judge whether it re-ran steps. I did not compare evidence rows with steps.

## Proposed harness changes
1. **Driver/prompt: stop sessions from ending on a background review subagent** (`lib/prompt.sh`, `lib/driver.sh`). The prompt should say: don't end the turn while a review subagent runs; run the review in the foreground, or write `entry.json` first with the state so far. The driver should also write a partial `entry.json` if a subagent is running when the session exits. Evidence: both P1-03 sessions ended on an interrupted review subagent, and both lost their `entry.json`. No earlier retro proposed this (I did not read the ledger).
2. **Split a feature automatically after a session with no pass** (`lib/driver.sh`, `lib/features.mjs`). After the first non-passing session on a feature whose diff exceeds roughly 10 files, the driver should have the next session spend its effort on a smaller slice. Alternatively, plan-kind features should cap the number of steps per build feature. Evidence: P1-03 had 7 steps over 19 files and was given up after $11.67.
3. **Fix the test-count parser** (`lib/record.sh`/`lib/eval.sh`) so it recognises `N/M checks passed`. Evidence: "test count: no match in the suite's output". This is minor.
