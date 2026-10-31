# Timing checks bound CPU time; a stopped file's missing names don't void `HARNESS_FAILED=`

*(2026-10-30, run `agent-harness-2026-10-30`, F1-02 and F1-05, written in F1-06; plan
`docs/plans/2026-10-30-F1-flakes.md`, "The two timing checks" and "The `whole suite` rerun")*

## 1. The two status timing checks (52, 53)

- **Finding:** `harness status --json` / `--all` over 38 stub runs "under 1 s (best of 3)" went red only at high box load
  (`some avg60` above 24 %; 1367 ms and 1151 ms at 8 jobs paired,
  `findings-and-research/2026-10-30-suite-load-curve.md`). Wall time measures the box's queue as much as the command.
- **Choice (*default*):** the bound stays 1000 ms but measures the call's CPU time (bash `time`, `TIMEFORMAT='%3U %3S'`,
  user plus system, in ms; best of three), and the check also keeps a 5 s wall bound, so a status that stalls on a
  lock or on git/gh (no CPU) still fails. A real slowdown (a quadratic read, a node start per run) still turns it red.
  `--repeat 10` of 52, 53 and 28 before and after: 10/10 green (the flake did not reproduce at idle). Headroom: about
  438 ms CPU (node's threads) against 1000 ms.
- **Rejected:** a ratio against a one-run baseline (taken under the same load, as noisy as the wall, and no longer
  "under 1 s", the status UX's promise); CPU alone, with no wall bound (passes a stall).

## 2. The runner after a stopped or killed file (`tests/run.sh`)

- **Finding:** a file stopped at `TEST_FILE_TIMEOUT` (or killed before its `.end`) never prints its remaining names;
  conformance then listed them `missing`, set `outside=1`, `HARNESS_FAILED=` was not printed, and `lib/check.sh`
  reran the whole suite (up to 25 min; `flaky: whole suite`, 29-3:42; both 8-job runs of the load curve).
- **Choice (*default*):** a `missing` name found literally (`grep -F`) in the source of a stopped or killed file is
  printed, with one line saying it is not counted; it no longer sets `outside`, so `HARNESS_FAILED=` names the files
  and check.sh reruns just them. Any other `missing`, every `new` and every `doubled` name still fails and reruns the
  whole suite. A `TEST_CHECKS` directory with its own `check-names.txt` gets conformance against it (no new variable).
  Narrower than the plan's first default (all missing names uncounted while a file was stopped), so a check deleted
  elsewhere is still caught.
- **Left as it was:** a name built at run time (30 of the 1082 names are literal nowhere; a cut file holding one keeps
  the whole-suite rerun), and a file that exits non-zero partway (`set -u`, a stray `exit`), which is not in `cut`: its
  unprinted names still count as missing.
- **Rejected:** mapping names to files (a second fixture to keep in step, or parsing the check files); a second
  conformance pass after the rerun (check.sh would have to merge two runs' names for a fault that lives in the runner);
  raising `TEST_JOBS` or the file timeout (`decisions/2026-10-29-check-timeout-25m`).
