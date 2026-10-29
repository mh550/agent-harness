# N1 · The rerun guard: a red is rerun once, a flake is green and counted, a real red stays red: plan

Spec: `docs/specs/2026-10-29-unattended-night.md` §N1 items 1–5 and its checks. This file is N1-01; N1-02 builds
`HARNESS_FAILED=` and the rerun in `check.sh`, N1-03 `flakes_note` and the invariant, N1-04 the summary, report and
debrief fields, N1-05 reviews. Every site is named by function and file as the code stands at `6ffecbb`. Nothing here
changes code: the suite is as the init left it (859 checks, green).

Facts checked for this plan, so the builders needn't re-derive them:

- `check.sh` deletes every `check-*.out` but the newest tree's right after the full run (the `find … -delete` after
  `run "$cmd" > "$scratch/check.out"`). `check-rerun.out` matches that glob, so it must be written **after** that line
  (it is, below) and removed before the first run, so a `check-rerun.out` always belongs to the `check.out` beside it.
- `run()` reuses `$unit` safely for a second call: `scope_run` clears `<unit>.started` and `.show` before each call.
- `run_init` (`lib/record.sh`) writes `tests-start` from `$SCRATCH/check.out` (`testcount.mjs`), once per run. After a
  rerun-green, `check.out` is the **red** first run, whose `N/M` gives N (the passes), not the total. `tests_end` reads
  the marker first, so it is right. See §check.sh *The count* and §Checks (N1-03).
- The stub project's `CHECK_CMD` (`test ! -f BROKEN`, `tests/lib.sh`) prints no `HARNESS_FAILED=` line, so in stub runs
  `auto` reruns the whole suite and a flake is `flaky: whole suite`. A stub run's red is deterministic (BROKEN), so the
  rerun is red too: today's outcomes hold, one more `scope_run` call per red.
- `tests/checks/08-scope-sh-l1-02-run-capped-services-gc-scratch.sh`'s `ck()` calls `check.sh` with `exit 3` and
  `exit 137` (short of the cap) and greps `— last lines of $T/ck/check.out:`; under the default `auto` those would rerun
  and name `check-rerun.out`. N1-02 pins `HARNESS_CHECK_RERUN=off` in that `ck()` (they test the first run's lines).
- A `tests/lib.sh` file exits `fails > 0`, so a FAIL line is always inside a file `run.sh` lists as broken; a file
  written outside `lib.sh` could print FAIL and exit 0, which the guard below treats as a failure outside every file.
- `HARNESS_LANE` is exported nowhere today; `$LANE` and `$M` exist in `lib/lane.sh`.

## check.sh

**Where.** `lib/check.sh`, full form, right after the two lines

```bash
run "$cmd" > "$scratch/check.out" 2>&1; rc=$?
[[ -n $key ]] && cp "$scratch/check.out" "$scratch/check-$key.out" && find … -delete
```

and before today's `if (( rc == 0 ))`. Before the first `run`, `rm -f "$scratch/check-rerun.out"`. The subset form
(`(( $# ))`, above the key) is left as it is: **`check.sh <args>` never reruns** (its caller is iterating, and a session
reads its output itself).

**The setting.** `rerun=${HARNESS_CHECK_RERUN:-auto}`; `lib/config.sh` sets `CHECK_RERUN=auto` beside `CHECK_TIMEOUT`,
`prompt_env` (`lib/prompt.sh`) exports `HARNESS_CHECK_RERUN=$CHECK_RERUN`. An unknown value is `auto` (the default:
one wasted rerun at worst). The four values, on a red first run:

| `CHECK_RERUN` | the output has `HARNESS_FAILED=<names>` | it has none |
|---|---|---|
| `auto` (default) | rerun `$cmd <names>` (`rerun: failed`) | rerun `$cmd` (`rerun: suite`) |
| `failed` | rerun `$cmd <names>` | no rerun: red as today |
| `suite` | rerun `$cmd` (`rerun: suite`) | rerun `$cmd` |
| `off` | no rerun | no rerun |

**What never reruns.** The first run's reason is `first=$(why $rc <s>)`, computed once. No rerun when `rc == 0`, when
`rc == 124`, or when `first` says `timed out` or `killed at its … memory cap` (a 137 that took the whole timeout or
peaked at the cap: `why` already tells them from a 137 of the suite's own, which **is** rerun). A rerun after a timeout
would cost the whole `CHECK_TIMEOUT` again (`decisions/2026-10-29-check-timeout-25m`); a cap kill would repeat.

**The names.** The last line of `check.out` matching `^HARNESS_FAILED=` (`sed -n 's/^HARNESS_FAILED=//p' | tail -1`,
from a file, never a pipe into `head`), split on whitespace; an empty value is no line. They go to the rerun as
arguments, the subset form's way (`run "$cmd \"\$@\"" _ "${names[@]}"`): never spliced into the command string.

**The rerun.** `run … > "$scratch/check-rerun.out" 2>&1; rc2=$?`: the same `run()`, so the same scope name, cap and
`timeout -k 30s $to`. `check.out` is never appended to: the generic count rule takes the last `N/M checks passed`, and
the rerun's is the subset's.

**Rerun green** (`rc2 == 0`):
- the marker `$cache/green-$key` is written (when `$key` is set) from the **first** run's total:
  `node testcount.mjs --total "$scratch/check.out"` (new flag, below) → `5 tests`, or empty when the output has no `N/M`
  line (an empty marker, as older markers are). With an empty marker, `check-$key.out` is removed too: the cached line
  and `tests_end` fall back to that file, and its count is the red run's passes (unknown beats wrong);
- one row appended to `$cache/flakes.jsonl` (§flakes.jsonl);
- the line `check: green after a rerun (flaky: <names>)<, n tests>` (`<names>` is `whole suite` for a suite rerun with
  no names; the count from the marker), exit 0.

**Rerun red:** `check: RED (<why $rc2 <s since start>>; red again on a rerun of <names | the whole suite>) — last lines
of $scratch/check-rerun.out:`, then `tail -25` of that file, exit `$rc2`. The seconds are the whole call's (both runs:
what the caller waited). No marker, no row.

**No rerun:** today's lines and exits, unchanged (`check.out`'s tail).

**The count.** `lib/testcount.mjs` gains `export function total(text)`: the total of the last
`(\d+)/(\d+) (?:tests? |checks )?passed` match, else `null`; `testcount.mjs <file> --total` prints `<n> tests` or
nothing. (`HARNESS_TESTS=<n>` is not a total: on a red run it is the passes.)

**Shape.** The first run and the rerun share the tail (marker, line, exit); N1-05's simplification pass folds them into
one function (`report <out file> <rc> <reason suffix>`), so write the rerun as a second call of what the first does, not
a copy.

**Lanes.** `lib/lane.sh` exports `HARNESS_LANE=$M` beside `HARNESS_SCOPE_PREFIX`, so a lane's rows (and its sessions'
`{{CHECK}}` calls, which share `HARNESS_CHECK_CACHE=$STATE/green`) name it. `templates/user/config.sh` gets, under the
`CHECK_TIMEOUT` line: `# CHECK_RERUN=auto                   # a red full suite is rerun once: auto (the HARNESS_FAILED=
files, else the whole suite) · failed · suite · off`.

## tests/run.sh

After `(( ${#broken[@]} )) && echo "files that exited non-zero: ${broken[*]}"`, the line

```bash
(( ${#broken[@]} && ! outside )) && echo "HARNESS_FAILED=${broken[*]}"
```

`broken` holds basenames (`03-c`, `44-lanes-record`), which the runner's own argument matching takes (a name matches
every file containing it; with two-digit prefixes that is the file alone, and a wider match only reruns more).
`outside=0` is set before the conformance block and becomes 1 when (a) the conformance check FAILs (full runs only), or
(b) a file's output has a `^FAIL ` line and the file isn't in `broken` (a file outside `lib.sh`'s exit rule). The promise
the line makes: **every failure of the run is inside a named file**; when one isn't, there is no line and `auto` reruns
the whole suite. The guard can't be exercised inside the suite (conformance runs only on the real checks dir, full):
N1-02's step says read it. The header comment gains one line naming `HARNESS_FAILED=`.

## flakes.jsonl and flakes_note

**The row** (N1-02, `check.sh`), one JSON line appended with `>>` (one short `write` under `O_APPEND`: lanes appending
at once don't interleave), built with `jq -nc`:

```json
{"at":"2026-10-29T03:12:44Z","key":"<tree key or \"\">","names":["a","b"],"rerun":"failed","first":"exit 1 after 0 s",
 "load":"0.52 0.61 0.70","lane":"M1"}
```

`at` is `date -u +%FT%TZ`; `names` is `[]` for a suite rerun with no names (a `suite` rerun **with** names keeps them,
`rerun: suite`); `first` is the first run's `why`; `load` the first three fields of `/proc/loadavg` (empty when
unreadable); `lane` `$HARNESS_LANE` or `""`. The file is `$HARNESS_CHECK_CACHE/flakes.jsonl`: the state dir's `green/`
for a run, scratch for a bare call.

**`flakes_note`** (N1-03), in `lib/record.sh` beside `green()`:
- reads `$STATE/green/flakes.jsonl` from the byte offset in `$STATE/flakes-noted` (0 when absent), takes the complete
  lines only (a lane may be mid-append: bytes after the last newline wait for the next call), and for each row
  `note "flaky: <names joined by a space, or whole suite> (red, then green on a rerun; load <load's first field>)"`
  (a row that isn't JSON is skipped, its bytes still consumed); then writes the new offset (the bytes consumed) to
  `$STATE/flakes-noted`;
- runs under `flock "$STATE/flakes-noted.lock"`: two lanes noting at once must not note a row twice;
- no file, or nothing past the offset: nothing, and no `flakes-noted` written;
- read into a variable or a temp file and loop with `while … done < <(…)` or `<<<`, so `note` runs in this shell; no
  producer piped into `head` (`pipefail`).

**Where the driver calls it:**
- `lib/lane.sh`, the coding loop: right after `if F passes "$SLIST" "$id" && ! green; then … un-passed …; fi` (rows from
  that suite and from the session's own `{{CHECK}}` calls);
- `verify()`: right after `if [[ $result == hold ]] && ! green; then result=red; fi` (the init's fresh suite, the
  session's calls and that one);
- `rebase()`: right after the disjoint branch's `green` (call it, keep its status, `flakes_note`, then branch on the
  status); the overlapping branch goes through `verify "$m" rebase`, already covered;
- `lib/driver.sh` `finish`: right before `note "run ended (…)"`, so the summary built after it counts every row and the
  log names them all.

**The invariant** (a red that is red twice still un-passes): nothing changes in `lane.sh`'s un-pass line; `green()` is
`"$CHECK"`'s exit, and a rerun-red exits non-zero. N1-03 shows it in a stub run (§Checks).

**`tests-start` after a flake** (N1-03): `run_init` takes the count from the tree's marker
(`$STATE/green/green-<key>`) when it has one, else from `check.out` as today, the way `tests_end` does. Without this a
flake on the run's first suite records its passes as the baseline.

## summary, report, debrief

**`summary.json`** (N1-04, `lib/summary.mjs` `build`): a new key `flakes: {count, names}` read from
`join(state, "green", "flakes.jsonl")` with a tolerant reader (a line that isn't JSON is skipped; the module's `jsonl`
throws): `count` the rows, `names` `{"<name>": <rows naming it>}`, a row with `names: []` counted under `whole suite`.
No file → `{count: 0, names: {}}`. No other key changes.

**`report.md` and the TTY card** (`reportRows`, so both agree): right after `["Tests", …]`,
`...(s.flakes ? [["Flakes", flakesText(s.flakes), "flakes"]] : [])` where `flakesText` is `0` for `count == 0`, else
`<count> · <name>[ ×<n> when n > 1], …`, names by count descending, then `LC_ALL=C` order: `3 · 28-run-14d-harness-merge
×2, 44-lanes-record`. An older summary (no key) prints no row. `tests/fixtures/summary-report.json` has no `flakes`, so
`summary-report.md` renders as before; don't add the key to the fixture.

**Debrief** (`lib/debrief.sh` `run_context`): in the `for f in summary.json:… report.md:… …` loop, right after the
`report.md` item prints, `echo; echo "#### flakes"` and the output of `node "$HARNESS_HOME/lib/summary.mjs" flakers
"$LEDGER/$proj"`. `flakers` is a new CLI command over a new pure `export function flakers(summaries, last = 5, min = 2)`:
the `summary.json` of each `<dir>/*/summary.json` that parses, newest `ended_at` first (a missing one oldest), the first
five; a name counts once per run whose `flakes.names` has it; the names in two or more, by runs descending then name,
one line each `<name> ×<runs>`; none → `(none)`. Summaries without `flakes` count as runs with none.

## Checks

Written first and watched failing, each in the file named; every name below gets its line in
`tests/fixtures/check-names.txt` (`LC_ALL=C` sorted, copied from the PASS lines).

**The stub suite for `73-check-rerun.sh`** (N1-02): one script `$T/rr-suite.sh` that `HARNESS_CHECK_CMD` names, run in
one throwaway git repo `$T/rr` (one commit, so `treekey.mjs` gives a key). Per case, its own directory `$T/rr-<case>/`
holds the counter `n`, the arguments of every call (`args`, one line per call, `$*`), and the case's
`HARNESS_SCRATCH=$T/rr-<case>/s` and `HARNESS_CHECK_CACHE=$T/rr-<case>/c`, so markers never cross cases. `RR` names
the case directory, `RR_MODE` the behaviour; the script bumps `n`, appends `$*` to `args`, then:

| `RR_MODE` | call 1 | later calls |
|---|---|---|
| `once` | `FAIL a`, `FAIL b`, `HARNESS_FAILED=a b`, `3/5 checks passed`, exit 1 | green |
| `always` | `FAIL a`, `HARNESS_FAILED=a`, `4/5 checks passed`, exit 1 | the same |
| `noline` | `FAIL x`, `4/5 checks passed`, exit 1 (no `HARNESS_FAILED=`) | green |
| `sleep` | `sleep 5` | – |

Green prints `PASS <arg>` per argument and `<#args>/<#args> checks passed` with arguments, `5/5 checks passed` without
(so the rerun's `2/2` differs from the first run's total). `HARNESS_SCOPE_PREFIX` unset (bare runs) except in the cap
case, which uses 08's scope stub (`STUB_DIR/scope/$STUB_SCOPE_UNIT.oom`).

`tests/checks/73-check-rerun.sh` (new, N1-02):
- `check rerun: red once with HARNESS_FAILED=a b, then green: exit 0 and the green-after-a-rerun line with the full count`
  (`check: green after a rerun (flaky: a b), 5 tests`)
- `check rerun: the rerun gets exactly the named files as arguments` (`args` line 2 is `a b`, line 1 empty)
- `check rerun: check.out is the first run byte for byte; check-rerun.out holds the rerun` (`cmp` against a copy of the
  stub's first output; `2/2 checks passed` in `check-rerun.out`)
- `check rerun: the green marker holds the first run's total, and the next call is cached with it` (`green-<key>` is
  `5 tests`; the third call `check: green (cached for this code tree, 5 tests)`, `n` still 2)
- `check rerun: a rerun-green appends one flakes.jsonl row with at, key, names, rerun, first, load and lane`
  (`jq -e '.names == ["a","b"] and .rerun == "failed" and .lane == "" and .first == "exit 1 after 0 s"'`, one line)
- `check rerun: red every time exits 1 with red again on a rerun of a and the rerun's tail; no marker, no flakes row`
- `check rerun: auto with no HARNESS_FAILED line reruns the whole suite (flaky: whole suite)`
- `check rerun: CHECK_RERUN=failed with no line, or off, runs the suite once and is red as today`
- `check rerun: CHECK_RERUN=suite reruns the whole suite even with the line`
- `check rerun: a timeout is never rerun` (`HARNESS_CHECK_TIMEOUT=2s`, `sleep`: `check: RED (timed out after 2s, exit 124
  after <n> s)`, `n` is 1)
- `check rerun: a kill at the memory cap is never rerun` (one `--unit=` call in the scope stub's log)
- `check rerun: the subset form never reruns` (`check.sh a` with `once`: exit 1, `n` 1, no `after a rerun`)
- `testcount.mjs: --total is the last N/M line's total; nothing without one`
- `check rerun: CHECK_RERUN=auto in config.sh, exported as HARNESS_CHECK_RERUN; the template has it; lanes export HARNESS_LANE`

`tests/checks/33-suite-runner.sh` (N1-02), on the existing three-file stub dir `$RC` (03-c red) plus a green copy:
- `suite runner: a red full run prints HARNESS_FAILED=<the red files> right after the files-that-exited-non-zero line`
- `suite runner: a green run prints no HARNESS_FAILED= line`

Changed, not new (N1-02): `08-scope-…`'s `ck()` passes `HARNESS_CHECK_RERUN=off`; its names stay.

`tests/checks/74-flakes-run.sh` (new). Two stub runs (`tests/lib.sh`), each from a reset `main` (`update-ref`, Gotchas).
The flaky run's project `CHECK_CMD`, written into `$T/proj/.harness/config.sh` by the check with `$T` expanded: red
once, on the first suite call after A's first session, e.g. `if [ "$(git log -1 --format=%s)" = "A: stub work (1)" ] &&
mkdir <T>/flaked 2> /dev/null; then exit 1; fi; test ! -f BROKEN` (`mkdir` is the atomic once; the builder confirms the
slot's HEAD subject at that call from the stub and adjusts the test, never the stub's commit). The invariant run is the
stub's default (C leaves BROKEN on its first try) with the default `CHECK_CMD`; it is also the run with no flake.
- N1-03: `flakes run: a suite red once after A's session is noted flaky: whole suite with its load, and A stays passed`
  (exactly one `flaky: whole suite \(red, then green on a rerun; load [0-9.]+\)` line, no `A un-passed: suite red`,
  `ended` starts with `done`)
- N1-03: `flakes run: flakes-noted holds flakes.jsonl's size after the note`
- N1-03: `flakes run: a red every time still un-passes C with today's note after a rerun (the invariant)` (`C un-passed:
  suite red after the session`, no `flaky:`, `$T/scratch/proj/<run>/lanes/M1/check-rerun.out` exists, ends `done`)
- N1-03: `flakes run: a run with no flake writes no flaky: line and no flakes.jsonl`
- N1-03: `flakes run: tests-start after a flake on the first suite is the marker's total, not the red run's passes` (no
  check sources `run_init` alone today, so a third stub run whose `CHECK_CMD` is red once on its first call; or a
  smaller harness for `run_init` if the builder finds one cheaper)
- N1-04: `summary.mjs: flakes counts flakes.jsonl's rows by name (whole suite for no names); every fixture key still built`
- N1-04: `report: the Flakes row after Tests (n · name ×k), 0 for none, none for an older summary`
- N1-04: `flakes run: summary.json flakes and report.md's Flakes row (1 · whole suite); the invariant run's Flakes 0`
- N1-04: `debrief: the flakes block names a check that flaked in two of the last five ledgered runs (×2), not one in one`
  (three fixture `summary.json` under `$HARNESS_LEDGER/proj/<r>/`, `harness debrief --dry-run`)

Cost: each stub run is ~20–40 s; 74 stays at two runs plus unit checks. Suite time on this box is ~10 min a full run
(init: 604 s), so a build feature runs it in full once, iterating on `bash tests/run.sh check-rerun suite-runner flakes
scope-sh` (the `08` file).

## Docs

- N1-02: `journal/decisions/2026-10-29-rerun-guard.md` (finding: the four points of the spec's table and what a false
  red costs at each · choice: the table above, the never-rerun exits, the marker's full count, counted never
  quarantined · rejected: quarantine; a rerun inside `tests/run.sh` only; rerunning on a timeout; one full suite at a
  time across lanes, per `decisions/2026-10-29-check-timeout-25m`); `templates/user/config.sh`'s `CHECK_RERUN` line;
  `tests/run.sh`'s and `lib/check.sh`'s header comments.
- N1-03 and N1-04 edit the decision in place (an `Updated in place 2026-10-29:` line) only if they change what it says
  (e.g. the `tests-start` fix).
- N1-05: `docs/architecture.md` §3's `lib/check.sh` row (the rerun, `CHECK_RERUN`, `check-rerun.out`, the marker's
  full-run count, the subset form never reruns), §4's state table (`green/flakes.jsonl`, `flakes-noted`), §7 a `Rerun
  guard` row beside `Suite cache`, §10's settings table (`CHECK_RERUN`); `README.md`: `CHECK_RERUN` with its four values
  in the box settings, and beside the `HARNESS_TESTS=<n>` paragraph the `HARNESS_FAILED=<name> <name>…` line and its
  promise (every failure of the run is inside a named file; a suite omits the line when one isn't, so `auto` reruns the
  whole suite).
