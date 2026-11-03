# One full run per coding session, last: the prompt's rule and §3 order, and `Suite runs` in the report

*(2026-11-03, run `agent-harness-2026-11-03`, C1-05; spec `docs/specs/2026-10-31-suite-cpu.md` C1 fix 4)*

- **Finding:** 10-29-3 ran 19 full suites in 11 coding sessions (1.73 each, 1,393 s of suite per session), mostly
  red-driven: a red full run, a fix, another full run; 10-30 ran 1.3 per session (budget §10, §11). The coding prompt said
  "Run it in full once before you flip `passes`", and §3 put the `## Gotchas` line (step 3) after the suite (step 2), so
  a session that followed it edited `CLAUDE.md` after its last full run: the tree that ended the session was a new key.
  10-28 paid about 20,000 s for a session's `TEST_JOBS=2` proposal, rejected since
  (`decisions/2026-10-29-check-timeout-25m`), and nothing in the prompt said so. Nothing measured full runs per session:
  the `<id>: suite ran <n>x` note counts every non-cached call, full and subset alike.
- **Choice:**
  - `prompts/coding.md`'s *The suite* rule: run it in full once, last, after the final edit of any file, `CLAUDE.md`
    included (an earlier full run is paid twice); a red check that check.sh reran green is a flake it has recorded, never
    rerun by hand; a red after its rerun is real; never lower the suite's parallelism for other lanes (`TEST_JOBS=2` on
    this box: slower and as flaky). The timeout clause stays. §3 *Finish*: the `## Gotchas` step (now 2) before the
    suite step (now 3), "so the tree you tested is the tree that ends the session"; `entry.json` and the commit after (the
    run directory is outside the key).
  - *Default:* the `TEST_JOBS=2` sentence is in the shared prompt, phrased as the general rule with this box's
    measurement as its example: the lesson is every project's (a lane's suite is never slowed for another's), and this
    repo has no `.harness/project.md`.
  - `lib/lane.sh` counts, from the same `check-runs.log` rows between `t0` and `t1` as the note, the ones whose kind is
    `full` (a `partial` or `subset` call is not), and passes `suite_runs` and `suite_full` as two more trailing
    arguments to `MET append` on both coding rows (the limit branch's too). `metrics.mjs metricsRow` writes them, `null`
    on every other row and when the log is missing. The note's text is unchanged.
  - `summary.mjs suiteRuns`: `suite_runs: { sessions, full, runs, full_per_session }` over the real (not environmental)
    coding rows that carry `suite_full`; a row from before C1-05, or one rebuilt from `run.log`, counts nothing.
    `full_per_session` to one decimal, `0` for none. The report's `Suite runs` row after `Flakes`
    (`2 full per coding session (2 in 1; 3 runs in all)`, `0` for none, no row for an older summary), `--md` and the
    TTY card alike; the retro prompt's `{{SUITE_RUNS}}` (`summary.mjs suite-runs`) prints the same value (`not
    counted` for a summary without it).
    *Default:* a row in the report and a field in the summary, no new note and no `trends` column.
  - The stub's suite calls (`STUB_RUN_SUITE`, `STUB_RUN_SUITE2`) run under `set +e`: the stub project's subset
    (`test ! -f BROKEN x`) exits 2, which ended the stub session under its `set -e` before its entry. So
    `77-leftovers.sh`'s `sr` run's A session now reaches its entry and commit instead of ending as a limit retry.
  - §3 step 1 names the suite step as step 3's run, so verifying every step is not a full run of its own.
- **Rejected:**
  - A driver-enforced cap on full runs per session: the session's judgment is what the rule asks for; a cap would turn a
    needed second run into a red end.
  - Counting from `harness-log.md`'s note: the note would have to change, and note text is what checks compare.
  - The rule in `CLAUDE.md` alone: it reaches one project.
