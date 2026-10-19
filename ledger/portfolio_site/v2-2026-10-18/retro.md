## Outcome
All 46 of 46 features passed and all 13 milestones (M0–M9, S1–S3) were verified and tagged. PRs #1–#13 were proposed, and none are merged yet. The run cost $113.95 over 7.79 h wall time, with 60 sessions, none environmental. It ended "done" at 01:52 local time. Nothing was left undelivered. The main reason it went smoothly is that features were small: most build sessions took 3–15 minutes at $0.9–1.4 each.

## Non-passing features by cause
There are none. Every feature has `cause: null`, and the guards in `summary.json` are all zero (0 repairs, 0 red_unpass, 0 verify_failed, 0 limit_waits).

## Harness behaviour
- **Guards:** None fired. This is plausible, because no build went red or hit a usage limit. The one verify hold, on S3-01, was noted as "1 hold, 0 fail", yet `verify_failed` is 0. That is consistent but worth confirming.
- **Summary bugs:**
  - `end_reason` reads "session cap", but `harness-log.md` says "run ended (done): 46/46 passing". The label is wrong.
  - `tests` reads start 70, end 6. CLAUDE.md says the suite has 643 tests across 57 suites. The counter looks like it parsed the wrong number.
  - `summary.json` `started` is 22:05 while `harness-log.md` starts at 18:19. This is a UTC versus local-time mismatch, with no effect on cost.
- **Cost mix:** Review took $33.51 (29%) and plan $23.05 (20%). Together they cost more than build ($38.09). Check took $9.33. Verify cost only $2.93 for 13 sessions, which is cheap.
- **Verify:** The progress.md evidence tables have per-step rows with "What you ran or read / What you saw / Holds" columns. Late rows are grouped, for example "S1 OG images · S2 card note · S3 print CSS | 3 | S1-01, S2-01, S3-01". That grouping looks like one row per cross-cutting check, not one per step. I did not count rows against steps, so I can't confirm each step was re-run.
- **Waste:** A fable init session cost $6.70. The 7 plan-kind features (for example M1-01 at $2.10) are fine.

## Proposed harness changes
1. **Fix the summary generator** (`summary` script). Take `end_reason` from the last driver event, and parse `tests.end` from the final jest "Tests:" total. Evidence: "session cap" against "done", and tests 70→6 against 643 in CLAUDE.md. Not proposed before, though the dj-2026-10-17 retro raised a similar `end_reason` mislabel (point 2), so this is a repeat.
2. **Make verify evidence per step** (verify prompt and a driver check). Require one evidence row per feature step, and have the driver reject grouped rows. Evidence: the S1/S2/S3 grouped row. Not proposed before.
3. **Review spend** (driver config). Skip or cap the per-milestone review sessions for small milestones (M8, M9, S1–S3, with 1–2 features each). Evidence: review was $33.51 for features that had already passed verify. Not proposed before.
