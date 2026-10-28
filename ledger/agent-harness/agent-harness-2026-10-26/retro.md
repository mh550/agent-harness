## Outcome
All 17 features passed, were verified and were merged: P0, P1 and P2 went into main as PR #40, PR #41 and the P0 merge. Tests went from 419 to 602. The run cost $127.81 over 14.2 h wall time ($7.52 per feature). It was blocked or stopped four times (`continuations: 4`), and each stop needed Michael:
- P0-02 blocked (08:30 on 10-26).
- P1-03 blocked (18:53 on 10-26).
- Stopped for a rebase onto main (conflicts in `lib/driver.sh`, 10-27 00:13).
- Stopped to merge main's flake fix, PR #39 (10-27 17:11).

## Non-passing features by cause
None are left. Three needed rework: P0-02, P1-03 and P1-04.
- **P0-02, spec problem.** The step demanded under 150 s, and the session said: "step 5 (<150 s) can't be met inside a suite split. Measured: per-file slot times add up to 636 s". Michael then ruled that a time is "measured and recorded, not a gate", and the third session passed.
- **P1-03, harness bug.** Two sessions ended with "entry.json missing; recorded a minimal entry" (18:38 and 18:53) and `passes=false`, after 39 min and 11 min. The session had been "waiting for the review" in the foreground. The run then went to `blocked`.
- **P1-04, environment.** "un-passed: suite red after the session" (00:13), then it passed after the main flake fix. I did not confirm the flake itself.

## Harness behaviour
- `red_unpass` fired once, on P1-04, and was correct. `repairs`, `verify_failed`, `limit_waits` and `verify_escalations` were all 0.
- **Blocking on a failed feature:** the driver gave up after 2–3 sessions on P0-02 and P1-03 and ended the run as blocked. It then waited hours for Michael, and none of that wait was productive. That is about 8.5 h of the 14.2 h wall time, against 1.35 h of driver time.
- **Main conflicts:** "main conflicts with harness/agent-harness-2026-10-26; carrying on without it" appeared on 10-26 22:40 and 10-27 16:55. The run then stopped twice for rebases, so the warning was not enough on its own.
- **Entry rejected:** P2-01's `entry.json` was rejected for a 413-character summary (limit 400). A minimal entry replaced it and the session's real summary was lost.
- **Verify:** the verify sessions were cheap ($0.63 in total, 3 sessions). P2's verify ran the full suite after a cache clear, and its commit message reads "7 hold, 0 fail". I did not compare evidence rows against steps. The 0% verify fail rate and the 7-of-7 result make it hard to tell whether verify checks anything the build didn't already check.
- **Review and plan overhead:** review cost $19.82 (2.24 h) and plan cost $17.59 (0.96 h). Both are real but were not wasted.
- **Orientation:** 2.3 M tokens over 23 turns, which is small.

## Proposed harness changes
1. **Validate `entry.json` in the session, not afterwards** (the validator or stop-hook path in `lib/`). The 400-character summary limit and a missing file should block the session from ending, so the session can fix the entry. Evidence: P1-03 was "entry.json missing" twice in a row and led to a blocked run, and P2-01 lost its summary. I have not checked whether an earlier retro proposed this.
2. **Treat "blocked on a spec step" as a question, not a run end** (`lib/driver.sh`). When a feature's steps contain a threshold the session measured as unreachable, continue with the independent features (those with no `after` link) and park the blocked one. Evidence: the P0-02 block stopped the run for 2.8 h. P0-03 had `after: P0-01` only, so it could have run alongside. The same applies to the P1-03 block. I did not check earlier retros for this.
3. **Escalate a main conflict early** (`lib/driver.sh`, near the "carrying on without it" note). If the branch conflicts with main, send an ntfy notification and attempt an automatic merge of main into the branch. Evidence: P2 did get "merged main into harness/…" at 01:02, but only after two manual stops on 10-27. I did not check whether an earlier retro proposed it.
