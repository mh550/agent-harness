## Outcome
All 23 of 23 features passed, were verified, and were merged (M1–M6, PRs up to #37). The run ended `done` after 6.88 h wall time and cost $57.93 ($2.52 per feature). Tests went from 395 to 501. There was no continuation, no limit wait, no repair and no environmental session. The only rework was M5-01, which failed M5 verify once.

## Non-passing features by cause
No feature ended non-passing. The one rework, M5-01, failed on the first attempt and was classed as a **spec or feature-list problem**. The step said the fixture should give 395, "this run's scratch check.out". The fixture held 474 and the check asserted 474. Evidence: verify's M5 summary reads "M5-01 step 2 fails: … yields 474 … the step says 395". The rework (18 min) rebuilt the fixture from the start tree `ac49ba8`. One session in that rework tried `git archive` into scratch and hit dead ends, and the full suite then took 378 s. The cost was about one extra build session plus one extra verify.

## Harness behaviour
- **Guards:** `verify_failed` fired once, correctly, and it caught a real spec mismatch. All other guards (repairs, red_unpass, escalations, limit_waits) stayed at 0.
- **Verify depth:** verify evidence rows were 36, 16, 26, 12, 11, 11 and 24 across M1–M6, roughly one or more rows per step. Verify re-ran the suite and named subsets (for example "38-run-17 12/12 re-run") and recomputed fixtures by hand. The verify sessions did re-run steps.
- **Cost and time with no gain:**
  - init cost $8.03 on fable and 0.24 h.
  - Orientation took 1.31 M tokens over 20 turns (296 s).
  - The suite cache is cleared before every milestone verify, so the full suite runs again each time. The init suite (13, 66 checks) went red once and passed alone, which suggests flakiness.
  - Review sessions cost $10.71 in total (M1-06 $3.16, M3-05 $3.50, M6-05 $4.05, the latter 28 min). Cost is concentrated in builds ($32.68).
- **Context pack:** `context.md` stayed at 7–8 KB but left out up to 20 items at the M6 verify (`20 items left out`). That is probably fine, but it is unmeasured.
- **Driver overhead:** 0.73 h of the 6.88 h.

## Proposed harness changes
1. **Feature-list/plan step lint for run-local artifacts** (the plan prompt or a check in `lib/`). Reject, or flag, a verify step that cites a scratch or ephemeral value ("this run's scratch check.out") which the verifier cannot reproduce from git. Evidence: the M5-01 spec/fixture mismatch cost about $2 and 25 min of rework. No earlier retro proposed this that I checked; I read only the list of earlier retros, not their contents.
2. **Pre-verify self-check** (`lib/driver.sh`, build-session exit). Before marking a feature as passing, run the first assertion of each of its verify steps that is a literal number or string compared to a command's output. This would have caught the 474-vs-395 mismatch at build time. It is the same evidence as change 1, but it works at the driver level.
3. **Retry only the flaky file** (`tests/run.sh` or the verify prompt). When one suite file is red at init or verify and passes alone, record it as a flake note and re-run only that file, not a full re-run. Evidence: init file 13 went red and passed alone, and the full suite takes ~378 s on every verify. No earlier retro match was found.
