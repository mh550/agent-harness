## Outcome
All 8 features passed, were verified and merged: N1 in PR #151, N2 in PR #152. The run cost $54.20 over 6.0 h wall (5.0 h in sessions). The first pass ended early. At 05:39 N1 verify found "evidence still short of the steps (N1-03 6/7; N1-02 6/7; N1-01 7/8)" and the run stopped waiting on Michael. It resumed at 22:09, which added about 16 h of idle time. A second verify then failed N1-04, which was redone in one more 15 min attempt and passed. First-attempt pass rate was 0.88 and the verify fail rate 0.11. The only feature needing rework was N1-04.

checks: +33 ~18 −1 (N1 +14 ~18 −1, budget 50; N2 +19 ~0 −0, budget 30)

## Non-passing features by cause
No feature ended non-passing. N1-04 failed one verify and then passed on retry. I put it down to model quality, because its first attempt spent 46 min and 2 full suite runs. I did not read its transcript.

## Harness behaviour
- **Guards:** `verify_failed` fired once, correctly. There were 0 repairs, 0 red_unpass, 0 limit waits and 0 escalations. Both merges succeeded.
- **Verify evidence gate:** it stopped the run for a human at 05:39 because evidence counts fell short of step counts. Because of that, N1 was verified twice and needed a second verify pass at 22:09. Cost: a verify session of about $2.50 plus a dead overnight window.
- **Suite time:** N1-04 attempt 1 ran the full suite twice (1491 s). Attempt 2 ran it twice (846 s). N2-04 ran it once (740 s). CLAUDE.md documents about 10–11 min per full run, so these are consistent with it. The coding prompt asks for one fast-tier run. Suite runs per coding session were 0.4 full and 1.1 fast.
- **Re-verification:** I could not audit this from the evidence rows, because none are recorded. The only signal is the "evidence short of steps" count. The N1-04 re-check was a full coding retry.

## Proposed harness changes
1. **`suite-time-budget`** (proposed, seen 10). Warn or cap session suite runs. N1-04 ran the full suite twice in one session, 1491 s in total.
2. **`verify-failed-recheck`** (proposed, seen 2). After a verify failure, re-check only the failed steps. N1-04 failed, was redone as a full coding session, and N1 was then re-verified in full.
3. **`verify-evidence-rows`** (proposed, seen 11). Record per-step evidence rows in `entries.jsonl`. The 05:39 stop was driven by evidence counts that cannot be audited today.
