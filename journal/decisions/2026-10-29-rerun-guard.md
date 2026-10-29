# The rerun guard: a red full suite is rerun once; a flake is green, named and counted, never quarantined

*(2026-10-29, run `agent-harness-2026-10-29`, N1-02; spec `docs/specs/2026-10-29-unattended-night.md` §N1, plan
`docs/plans/2026-10-29-N1-rerun-guard.md`)*

- **Finding:** the harness asks "is the suite green?" at four points, all through `$CHECK` (`lib/check.sh`) and
  `green()`, and a red that was only a flake costs each one:

  | Where | A red | Cost of a false red |
  |---|---|---|
  | after a coding session (`lib/lane.sh`, `F passes … && ! green`) | the feature is un-passed | another session (U1-07 on 2026-10-28: 39 min) |
  | before a session (`run_init`) | "suite red before the session" | the session chases a red that isn't there |
  | at verify (`hold && ! green` → `red`) | `needs-<m>`, a `verify_red` record | the milestone waits for Michael until morning |
  | at a disjoint re-base (`green \|\| rebase_fail`) | `verify_red`, needs Michael | the same |

  The 2026-10-26 to 10-28 sessions saw one or two timing flakes per run (28, 32, 38, 44, 46, 48, 08, 15), each green
  alone or on the next run. `tests/run.sh` already named its red files and took names as arguments.
- **Choice:** `check.sh`'s full form reruns a red once, by `CHECK_RERUN` (`lib/config.sh`, default `auto`, exported as
  `HARNESS_CHECK_RERUN`):

  | `CHECK_RERUN` | the output has `HARNESS_FAILED=<names>` | it has none |
  |---|---|---|
  | `auto` | rerun the named files | rerun the whole suite |
  | `failed` | rerun the named files | no rerun |
  | `suite` | rerun the whole suite | rerun the whole suite |
  | `off` | no rerun | no rerun |

  Never after a timeout (124, or a 137 that took the whole `CHECK_TIMEOUT`) or a kill at the memory cap: the rerun
  would cost the whole timeout again, or be killed again. The subset form (`check.sh <args>`) never reruns. The rerun's
  output is `check-rerun.out`; `check.out` keeps the first run whole. A green rerun prints `check: green after a rerun
  (flaky: <names | whole suite>), <n> tests`, exits 0, writes the tree's green marker with the **first** run's total
  (`testcount.mjs --total`: the rerun's count is its subset's, the red run's `N` its passes) and appends one row to
  `$HARNESS_CHECK_CACHE/flakes.jsonl` (`at, key, names, rerun, first, load, lane`; lanes export `HARNESS_LANE`). A red
  rerun prints `check: RED (…; red again on a rerun of <names | the whole suite>)` with the rerun's tail and exits as
  the rerun did: a real red still un-passes, stops a verify, fails a re-base. `tests/run.sh` prints
  `HARNESS_FAILED=<basenames>` on a red run only when every failure is inside a named file (a red conformance check, or
  a FAIL in a file that exited 0, leaves the line out, so `auto` reruns the whole suite). Every flake is counted, never
  hidden.
- **Rejected:**
  - **Quarantine** (skip or exclude a check that flaked): a quarantined check stops guarding, and an intermittent real
    bug (the P2 review's "47 flake" was a coordinator ordering bug) would be hidden for good. Repeat flakers are fix
    work, not exemptions.
  - **A rerun inside `tests/run.sh` only:** other projects' suites wouldn't get it, and the harness couldn't count it.
  - **Rerunning on a timeout:** a second full `CHECK_TIMEOUT` (25 min here) for a suite that is likely to time out again.
  - **One full suite at a time across lanes** (a box-wide lock): two suites in series take longer than two at once
    (`decisions/2026-10-29-check-timeout-25m`), and it would not stop the flakes the 2026-10-29 single suite had.

Updated in place 2026-10-29: N1-03: the driver notes each new `flakes.jsonl` row once in `harness-log.md`, `flaky:
<names | whole suite> (red, then green on a rerun; load <1-min>)` (`flakes_note`, its byte offset in
`$STATE/flakes-noted`, under its own lock), after each coding session's un-pass check, verify and disjoint re-base, and
in `finish` before `run ended`; `run_init`'s `tests-start` takes the tree's marker first, so a flake on the run's first
suite records its total, not the red run's passes.

Updated in place 2026-10-29: N1-04: counted where Michael reads: `summary.json`'s `flakes` (`{count, names}` from the
state dir's `green/flakes.jsonl`, a whole-suite rerun under `whole suite`), `report.md`'s `Flakes` row after `Tests`
(`<n> · <name> ×<k>, …`, `0` for none), and the debrief's `#### flakes` block: the names in two or more of the
project's last five ledgered summaries (`summary.mjs flakers`), the repeat flakers that are fix work.

Updated in place 2026-10-29: N1-05 (the milestone review): `finish` notes flakes again after its own last suite run,
so a flake there is in `harness-log.md` as well as in the summary; a `flakes.jsonl` row that is JSON but not an object
(a stray `null`) is passed over by `flakes_note` and `summary.mjs` alike. *Default, Michael's to confirm:* a file
`tests/run.sh` stopped at `TEST_FILE_TIMEOUT` stays in `HARNESS_FAILED=`, so `auto` reruns it; that costs at most one
more `TEST_FILE_TIMEOUT` (10m), and a hang under load is the likeliest flake. Leaving its name out would let a rerun of
the other files go green over it, and leaving the whole line out would rerun the whole suite.
