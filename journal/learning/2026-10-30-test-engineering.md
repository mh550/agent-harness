# Test engineering, learned in the field (agent-harness)

*(Michael's study log, written during a tutoring session on 2026-10-30. One concept per entry: the idea in plain
words, where it lives in this repo, the trade, and the answer taken. Source material for a talk on the harness.)*

## 1. Performance assertions: CPU time versus wall time

- **Concept:** a test that says "under 1 s" has a hidden input: how busy the machine is. Wall time is a stopwatch and
  counts the time spent waiting for the CPU behind other test files. CPU time (user + system) counts only the time the
  CPU spent on the command. Wall measures "the command plus the box's queue"; CPU measures "the command".
- **In the repo:** `tests/checks/52-*` and `53-*`, the `time J` line with `TIMEFORMAT="%3U %3S %3R"` (user, system,
  real). Evidence: `findings-and-research/2026-10-30-suite-load-curve.md`, red only at 8 paired jobs (1367 ms and
  1151 ms wall, load average above 24 %) while `harness status` had not changed.
- **Trade:** lose "what the user feels at the terminal"; gain a check that fails only when the code got slower.
  Headroom about 438 ms CPU against 1000.
- **Answer (default 1):** keep. Resource-use bounds are how mature suites keep performance assertions alive under
  parallel runs. The rejected ratio-against-a-baseline is as noisy as wall and loses the 1 s meaning.

## 0. What a check is here (the whole framework in two lines)

- `tests/lib.sh:55-56`: `check "<name>" '<command>'` counts one, `eval`s the command, prints `PASS <name>` on exit 0
  and `FAIL <name>` otherwise. A test is a name plus a shell expression whose exit status is the verdict. The command
  sits in single quotes so nothing expands until `eval` runs it. `tests/run.sh` runs the files in parallel, collects
  the PASS/FAIL lines, and prints `N/M checks passed`.

## 2. A resource bound needs a stall bound beside it (timeout versus budget)

- **Concept:** CPU time has a blind spot: waiting costs no CPU. A deadlock, a lock another process holds, a hung `gh`
  call: zero CPU, infinite wall. So a timing check pairs a *budget* (CPU, catches slowness) with a *timeout* (wall,
  catches stalls). "Best of 3" estimates the command's floor, what it costs when nothing interferes; a one-off
  outlier (cold cache, a pause) then cannot fail the check on its own.
- **In the repo:** `tests/checks/52-*:74-76`: three timed runs of `harness status --json`, user+system summed in ms
  (`10#${u//[!0-9]/}` strips the dot and forces base 10), minima kept in `best` and `wall`, a diagnostic line with the
  numbers, then the assertion `best < 1000 && wall < 5000` and the correctness check (38 runs), so a fast wrong answer
  cannot pass.
- **Trade:** 5 s is loose (a 3 s stall passes); the curve's worst wall was 1.4 s. The wall bound is a guard rail, not a
  measurement.
- **Answer (default 2):** keep. A tighter stall bound would be its own check, not this one.

## 3. A conformance check, and why a killed file must not void it

- **Concept:** a *conformance* (manifest) check compares the names a run printed against a fixed list,
  `tests/fixtures/check-names.txt` (1083 names). Without it a deleted or silently skipped test is invisible: the suite
  just reports one fewer. The failure the run fixed: a file killed at `TEST_FILE_TIMEOUT` never printed its later names,
  conformance read them as "missing", which looked like deleted tests, and `lib/check.sh` reran the whole suite (25 min).
- **In the repo:** `tests/run.sh`: `cut=()` collects files stopped (`.timedout`, line 70) or killed (no `.end`, line 109);
  `comm -23 fixture uniq` = missing, `comm -13` = new, `uniq -d` = doubled (line 121); a missing name found literally
  (`grep -qF --`) in a cut file's source is excused with one printed line (127-134); every other missing, new or
  doubled name still fails and sets `outside=1`, which suppresses `HARNESS_FAILED=` (142), the line check.sh reads to
  rerun only the named files.
- **Trade:** 30 names are built at run time and literal nowhere; a cut file holding one still reruns the whole suite.
  A check deleted elsewhere while a file is cut is still caught.
- **Answer (default 3):** keep. The excuse is narrow and keyed to evidence (the name is in the dead file's source).

## 4. The subset run checks the manifest too

- **Concept:** a subset run (`bash tests/run.sh gc`) is the fast feedback loop. It cannot judge "missing" (it did not run
  everything) but it can judge "new" and "doubled". The gap it closes (found by an Opus review): a check added past a
  hang and never added to the fixture passed on check.sh's rerun, the tree was marked green, and only the next full
  run would have gone red. Field term: a registration gate moved earlier, from the nightly to the inner loop.
- **In the repo:** `tests/run.sh:123`: `(( $# )) && missing="" name="conformance: every check a subset ran is in the
  fixture, once"`. The FAIL prints `new (add each to tests/fixtures/check-names.txt):` so the fix is one line.
- **Trade:** friction while iterating; a new check is red in the subset until its name is in the (C-sorted) fixture.
  Two signals share one verdict (code wrong versus name unregistered), but the message tells them apart.
- **Answer (default 4):** keep.

## The four defaults: how to answer

- All four stand as built; "keep" needs no action. The run is finished, so INBOX.md answers would not be read by a
  session; a change to any of them is a follow-up spec. The one worth a future spec: the 30 run-time-built names
  (3), so a cut file never triggers a whole-suite rerun.
