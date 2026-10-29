# This repo's suite gets a 25-minute check timeout; TEST_JOBS stays at its default

*(2026-10-29, interactive session on `spec/2026-10-28-reliability`, measured on this box with no run alive; spec
`docs/specs/2026-10-29-unattended-night.md` § Before the run)*

- **Finding:** `CHECK_TIMEOUT` (15m, `lib/config.sh`) bounds every `check.sh` run. Measured on 2026-10-29 at 00:05–01:00,
  each figure the full `bash tests/run.sh` (859 checks) in this worktree:

  | Form | Wall | Failures |
  |---|---|---|
  | one suite alone, `TEST_JOBS=4` (the default on 8 cores) | 601 s | 1 (`the weekly budget ends a run after the session that crossed it`) |
  | two suites at once, `TEST_JOBS=4` each (two lanes) | 857 s each, load 9–10 | 0 |
  | two suites at once, `TEST_JOBS=2` each | 1172 s and 1210 s | 2, both in `44-lanes-record` |

  Two lanes leave 43 s of the 15 minutes, before any session's own load; a timeout is a red (`check: RED (timed out
  …)`), which un-passes a feature, or stops a verify for Michael. `CLAUDE.md`'s "208 s" predates the suite's growth to
  859 checks.
- **Choice:** `CHECK_TIMEOUT=25m` in `.harness/config.sh` (the project layer, so it rides with `main` and reaches every
  lane). `TEST_JOBS` stays unset (half the cores, at most 4): halving it made two suites at once slower (about 1200 s
  against 857 s) and did not stop the flakes.
- **Rejected:**
  - **`TEST_JOBS=2`** while lanes run (proposed by a 10-28 session): slower and as flaky, above.
  - **One full suite at a time across lanes** (a box-wide lock in `check.sh`): two suites in series take about
    1200 s, two at once 857 s; the box does more work running them together.
  - **The timeout in the user config:** it is this suite's size, not the box's policy; other projects keep 15m.
