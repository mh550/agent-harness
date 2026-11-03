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

## 5. Why the excuse in default 3 is keyed to evidence (fail-closed gates)

- **Concept:** one symptom, "a name in the fixture was not printed", has two causes: the check was deleted (the suite
  shrank; must go red) or its file was killed before reaching it (no loss; rerun that file). The symptom cannot tell
  them apart, so the runner needs evidence: the name is still in a check file's source (not deleted) *and* that file
  was cut (the kill explains the absence). Excusing every missing name whenever any file was cut would hide a
  deletion that happened on the same night as a hang. Rule: a gate's excuse is keyed to the evidence that explains
  the failure, never to the presence of some other failure. When a gate cannot tell, it fails (**fail-closed**); the
  cost is a wasted rerun, the alternative is a shrunken suite merged as green.
- **Field term:** *test collection* versus *test execution*. pytest and Jest first collect what tests exist, then run
  them; the fixture is a hand-kept collection. The 30 run-time-built names are the gap a real collection pass would
  close (future spec: a list mode of `check()` that prints names without running, and a generated fixture).

## 6. Where an LLM belongs in a test gate: propose, never decide

- **Concept:** the suite exists to check an LLM's claim. An LLM judging whether a red is "real" puts the defendant on
  the jury. A gate must be deterministic (the same tree gives the same verdict, or `green-<key>` means nothing),
  cheap (it runs about 1.7 times per session), and auditable (a rule in `tests/run.sh` can be read; a judgment cannot
  be replayed). The repo's own evidence of plausible-but-wrong: the gh stub that answered every field and hid the gc
  bug (PR #70); the guessed usage-limit stub line (2026-10-17).
- **Where it fits:** after the deterministic verdict, as diagnosis and proposal: explain a fail-closed rerun, draft
  the fixture line, pick the inner-loop subset. The harness already works this way: `lib/resolve.sh` lets a session
  propose a conflict resolution and the driver checks it (markers, unmerged paths) before committing. Synthesis, not
  a source's claim: "LLM proposes, bash disposes."

## 7. Fixtures, subsets, and selecting tests for a change

- **Fixture:** any fixed, known data a test relies on. `tests/fixtures/`: real CLI lines captured and replayed by the
  stub (`usage-limit.jsonl`, `usage-tokens.jsonl`; the "fakes mirror the live API" rule), the expected check-name
  list, the status JSON key paths.
- **Subset:** `tests/run.sh:29-32`: each argument is a substring; a file runs if its name contains it
  (`run.sh gc`). Selection is by name, typed by a person or a session, not by what changed. Files run as separate
  processes, largest first (`ls -S`, line 34), `TEST_JOBS` at a time, each under a watchdog (`one()`, lines 49-55).
- **Test impact analysis:** `lib/check.sh`'s partial run with `CHECK_KEY_MAP` in `.harness/config.sh`
  (`CLAUDE.md:39-memlint-m4:37-memory-prompts-m2:79-suite-length`): a change to only that path runs only those files.
  One hand-written row so far. The industry versions (Bazel/Nx dependency graphs, Meta's predictive test selection
  trained on change-to-failure history) need a dependency map or a per-test failure history keyed to changed files,
  which the repo lacks; `flakes.jsonl` and `check-runs.log` are a start.
- **The default-4 scenario:** file 15 hangs at 8 jobs; a session had added a check past the hang and not its name to
  the fixture. The full run never printed it; check.sh reran file 15 alone; before default 4 the subset skipped
  conformance, the check passed, the tree was marked green, and only the next full run on main would have said `new`.
- **An LLM picking the subset:** safe only in the inner loop, with the full run still the gate (fix 4: subsets while
  iterating, one full run at the end). A wrong pick then costs time, not an escape.

## 8. The framework's shape, and where the time goes

- **Parts:** `tests/run.sh` (146 lines, the runner: pick files, one process per file with a watchdog, `TEST_JOBS`
  at a time, collect, conformance, totals); `tests/lib.sh` (221: `check()`, the throwaway environment, helpers);
  `tests/checks/` (86 files, 1,233 check lines, one topic per file, each from a fresh state); the stubs
  (`stub-claude.sh` 408 lines acting out sessions from the prompt's first line; `stub-gh`, `stub-curl`,
  `stub-systemctl`, `stub-systemd-run`); `tests/fixtures/`; `lib/check.sh` (203: the gate the driver calls: tree key,
  green/red markers, partial, rerun guard). Not all bash: 108 `node --input-type=module` evals inside 35 check files
  unit-test the pure `.mjs` functions.
- **Shape:** mostly end-to-end (a stub run of the whole driver per behaviour), a thin unit layer, almost nothing
  between. Each end-to-end file costs 3–3.5k node starts; node startup was 67 s of one file's 123 s CPU.
- **Numbers (2026-10-30):** solo full suite 817–835 s at 4 jobs, CPU about 3,300 s; 1/2/4/8 jobs
  2,866/1,459/805/599 s; two suites paired at 8 jobs 1,192 s each with file 15 hitting its timeout; slowest files
  15-run-4 232 s, 13-run-2 205 s, 08-scope 203 s; suite wall 58 % of lane time with fixes 1–3 live (77 % before).
- **Levers, my order:** (1) new behaviour in a pure function gets a node eval, not a stub run (push the shape down);
  (2) split the three longest files so the critical path (the longest file) drops, since wall at 4 jobs is set by it;
  (3) fix 6, fewer process starts in the driver; (4) grow `CHECK_KEY_MAP` from one row toward a map of which lib
  files each check file exercises; (5) never run paired suites at 8 jobs.

## 9. Why bash plus node, and whether another language would help

- **Division of labour:** bash does what shells are good at (processes, signals, `setsid`, `flock`, tmux, git), and
  node's standard library does what bash cannot do safely: JSON (the CLI's stream-json, `entries.jsonl`,
  `feature_list.json`), rendering, hashing. `jq` covers the small cases. Node is already on the box because
  Claude Code needs it, and "node ≥ 20 standard library only, no npm" keeps installs to zero. No decision file records
  the language choice; the CLAUDE.md rule is its record.
- **A faster language would not fix the cost.** The cost is process *starts* (node about 30 ms each, 2,239 per large
  check file), not run time. Rust or Go start in about 1 ms but add a toolchain and a build step, and the model writes
  bash and JS more reliably. The lever is the process model: fewer, larger questions, or one warm process (entry 12).
- **Bash is error-prone, and the repo shows it:** the Gotchas list is mostly bash traps (`pipefail` SIGPIPE, `set -u`
  on a jq null, locale-bound regexes). Best practice for that is to keep the shell thin and push logic into pure
  functions in the structured language, which the `.mjs` layer already starts.

## 10. Why 86 check files, and how growth is kept in check

- **History:** one 1,634-line `tests/run.sh` with 50 sections and 325 checks (10 min single-threaded) was cut on
  2026-10-26 into one file per section, grouped where a section read another's state
  (`decisions/2026-10-26-suite-split`). The file is the unit of parallelism, isolation (a fresh `$T`, a private tmux
  server, stub environment, `tests/lib.sh suite_setup`) and timeout. Now 86 files, 1,233 checks, about 14 per file;
  the largest (`15-run-4-…`, 130 checks) runs five stub `harness start` runs.
- **What differs between files:** each is a scenario (a stub run with certain `STUB_*` behaviours) or a `-pure` file of
  node evals over one `.mjs`. Names carry history (`run-2b-stop-records`) rather than the unit under test.
- **Best practice:** one test file per unit or feature, named for what it tests, mirroring the source layout;
  every test independent; shared setup in fixtures; tiers (fast pre-merge, slow nightly).
- **Growth:** 335 → 859 → 1,084 checks in two weeks, about 3.1 CPU-s each. The design counts (conformance fixture,
  `tests-start`/`tests-end` markers, a count in every run's log) but has no rule for removing or merging checks.
  The field's tools for that: coverage to find redundant tests, mutation testing to find tests that catch nothing,
  periodic pruning. The cost per check, not the count, is the problem to attack first.

## 11. What the `.mjs` files and the node evals are

- `.mjs` is an ES-module JavaScript file. `lib/*.mjs` (about 5,200 lines, `needs.mjs` 750, `status.mjs` 489,
  `features.mjs` 484, …) hold the harness's data logic. A **pure function** takes inputs and returns an output with no
  file, clock or network read, so a test can call it with a made-up input and compare the result.
- A **node eval** is `node --input-type=module -e "<code>"`: run a string of JS as a program. The check imports the
  function from `lib/x.mjs`, calls it on literal data, and exits 0 or 1 (`tests/checks/03-…-pure-report.sh:4-9`,
  `parkedReport` over two fake parked entries). It is the unit-test layer: one node start (30 ms) against a stub run's
  seconds. 108 of them in 35 files today.

## 12. Thousands of process starts, and the warm-process answer

- **Where they come from:** per large check *file*, not per check: a 2026-10-26 strace of the biggest file counted
  28,325 execs, 5,461 `git`, 2,239 `node`, about 10,000 one-millisecond utilities; 1,684 of the node starts were the
  driver's own (`features.mjs`, `metrics.mjs`: bash asks node one question per process). The suite pays mostly for
  the harness's own process model.
- **Industry answer:** one warm process serving many requests. Jest/Vitest run every test file inside a few long-lived
  workers; Bazel has persistent workers; Gradle and Nx run daemons; Watchman and language servers are the same idea.
  For a small team with no npm: `node:test` (built in since node 18) runs every unit test in one process.
- **For this repo, in order:** (1) move the 108 evals into `.test.mjs` files under `node --test`: one start instead of
  108; (2) fix 6: batch the driver's questions (one `features.mjs` call returning every field) before any daemon;
  (3) only then consider a resident helper process, which brings lifecycle, crash and lane-concurrency problems the
  driver would have to own.
