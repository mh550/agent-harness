# A slim suite, and a process that keeps it slim: coverage, mutation, trim, shape, purity (2026-11-03)

**Goal.** Phase 4 of `docs/plans/2026-11-03-test-suite-redesign.md`. The suite grew 335 → 1,129 checks in two weeks
with no rule for removing or merging one, and its shape is mostly end-to-end (a stub run of the whole driver per
behaviour) over a thin unit layer. Measure what each check file exercises and which checks catch nothing, then trim and
reshape with the evidence, then propose the rules that keep it that way, then move the bash logic that burns the suite
into pure functions in the unit tier. Four milestones in series: **S1** measure, **S2** trim and shape, **S3** process,
**S4** purity.

**Source.** `docs/specs/2026-11-03-test-suite-redesign.md` (Phase 4); `journal/learning/2026-10-30-test-engineering.md`
entries 8, 9, 10, 15; `findings-and-research/2026-11-03-redesign-baseline.md`; the pure-logic candidate list in
`docs/plans/2026-11-03-test-suite-redesign.md` §Phase 4 (fifteen candidates with file:line, from a read of `lib/*.sh`
on 2026-11-03); `CLAUDE.md` *Gotchas* (the bash traps); `tests/fixtures/check-names.txt` and `check-names-fast.txt`;
`tests/unit/` (phase 1); `decisions/2026-10-26-suite-split` (why the files are what they are; names carry history).

**Rules.** `CLAUDE.md` binds: worktree only; never touch real runs or real state; fakes mirror the live API; test-first
in `tests/checks/` and `tests/unit/`, names in the fixtures; `bash -n`, `node --check`; one decision file per behaviour;
`docs/architecture.md` and `README.md` in the same milestone. **Proceed on the defaults written here; record them
marked *default*; never park.** **A removed check is named in a decision file with the check that now covers its
lines**, never removed silently; the fixtures shrink with it in the same feature. The invariant holds (the full suite
at verify). The gate stays deterministic. **No `harness-log.md` note text changes in S4** (the moved logic answers the
same; the checks that compare notes are the proof).

## Depends on

- `main` at or after the merge of phases 1, 3 and 2 (the unit tier, the tiers, the helper). S1 measures the suite as
  it then is.
- No other suite alive during S1's measurement runs (one lane).

---

## S1 · Measure: what each check file exercises, and which checks catch nothing

### S1-01 · The coverage map

**Choice.** Two built-in sources, no tool to install (`kcov`, `bashcov` and `perf` are not on the box):

1. **bash lines**: the driver and its lanes run with `set -x` when `HARNESS_XTRACE=<dir>` is set: `lib/driver.sh` and
   `lib/lane.sh` (and `bin/harness` for CLI calls) do, once, `exec {BASH_XTRACEFD}>> "$HARNESS_XTRACE/$$.xtrace";
   PS4='+${BASH_SOURCE##*/}:${LINENO}: '; set -x` (*default*: a guarded three-line addition, off unless the variable
   is set; the suite's own stub runs never set it). The map feature runs each check file with the variable set to a
   directory per file (`TEST_XTRACE_DIR`, exported through `tests/lib.sh` into the stub runs), then reduces the traces
   to the set of `<file>:<line>` pairs per check file.
2. **`.mjs` lines**: `NODE_V8_COVERAGE=<dir>` (built into node: one JSON per process) set the same way; reduced with a
   small `tests/tools/coverage.mjs` (standard library: reads the V8 JSON, maps ranges to lines of `lib/*.mjs`; `node
   --test --experimental-test-coverage` for the unit tier's own files).
3. **Output**: `findings-and-research/2026-11-03-suite-coverage.md` with the tables: per check file, lines covered in
   `lib/` and `bin/`; per `lib/` line, how many files cover it; **files whose covered set is a subset of another file's**
   (candidates to merge); lines covered by 20 or more files (the stub start's path: every scenario pays it); lines
   covered by no file (dead, or untested: each listed); and the raw per-file sets as `.txt` beside it (for S2). The
   measurement runs take about two full suites of CPU (`set -x` slows bash; the numbers are counts, not times).

### S1-02 · The mutation sample

**Choice.** Forty mutants, chosen by a seeded random pick (the seed in the findings file) over lines of `lib/*.sh` and
`lib/*.mjs` that S1-01 found covered by at least one file, four kinds: delete the line; `&&` ↔ `||`; a comparison
operator (`-ge` → `-gt`, `<=` → `<`, `==` → `!=`); a literal (`true` → `false`, a constant +1). For each mutant: the
files that cover the line (S1-01's map), run with `bash tests/run.sh <those files>`; **caught** if any check went red,
**survived** otherwise. The table in the findings file: mutant, line, kind, files run, caught by (the check names) or
survived. A survived mutant is a line no check asserts on: S2's list. Cost: 40 × a few files × 20–200 s ≈ 1–3 h of
suite, in the background, the session doing S1-01's write-up meanwhile. *Default:* the sample is of covered lines only
(an uncovered line survives trivially and is already listed).

### S1-review

Folded into S1-02 (two measurement features): a reader checks the maps' reductions on one hand-traced file.

---

## S2 · Trim and shape

**Choice.**

1. **Trim**, from S1's tables, in this order, each removal one row of the decision file (`check name · file · why ·
   the check that covers its lines now`): (a) two checks in one scenario that assert the same `harness-log.md` line
   (the same `hlog | grep` on the same run): keep one, the more specific; (b) a check file whose covered set is a subset
   of another's and whose assertions that other file also makes: merge the assertions that differ into the other file,
   delete it; (c) a check whose lines no mutant could fail and that asserts only that a command exited 0 after a stub
   run another check already drives: remove; (d) a behaviour of a pure function asserted through a stub run (an
   `.mjs` function's branch reached only by a scenario): a unit test in `tests/unit/` replaces the check, the stub run
   stays if other checks need it. **Target: −15 % names** with **no coverage loss**: the union of covered lines after
   S2 (S1-01's method, rerun) is a superset of the union before, and every S1-02 mutant caught before is caught after.
   A removal that would lose a line stays.
2. **Shape.** A scenario file is named for the unit under test, not its history: `14-run-2b-stop-records` →
   `stop-records`, `15-run-4-same-but-queue-parked-debrief-tmux` → split along its sections into `queue`, `parked`,
   `debrief`, `tmux` where the replay cost (one stub start, ~19 s) is under the file's gain in parallel slot time, else
   renamed whole. The number prefix goes (the runner orders by size, not name; `ls -S`); `tests/run.sh <name>` still
   matches by substring. Check names (the fixture) do not change for a rename. Each file's header keeps its tier
   (phase 3's rule; a split file is re-timed).
3. **Push down.** Every unit-sized assertion found in (d) becomes a `tests/unit/` test; the pyramid's counts before and
   after go in the decision file (checks in `tests/unit/`, in fast scenario files, in slow scenario files).

**Checks (written first).** The suite itself: a full run green with the shrunken fixtures; the coverage superset check
is a step with the two unions' line counts in the decision file; every renamed file has its tier header and its names
unchanged (`comm` of the names before and after a rename is empty).

### S2-review

Sized to the milestone: a reader of the removals against the coverage tables (a removal that lost a line is the finding).

---

## S3 · The process that keeps it slim

**Choice.**

1. **Rules proposed for `CLAUDE.md`** (Michael's to accept: the session writes them in its entry's `proposed_changes`
   and in the decision file, verbatim, not into `CLAUDE.md`): a new behaviour in a pure function gets a unit test in
   `tests/unit/`, never a stub run; a stub run is added only for a driver behaviour no unit test can see, and goes in
   the file named for its unit; a check that duplicates an existing assertion replaces it (the old name leaves the
   fixture in the same commit); a feature's checks are named for the behaviour, not the feature id; every retro reports
   checks added, replaced and removed; a check-count budget per milestone with an explicit over-budget reason.
2. **The machinery** (built, since it is the harness's): the retro line **`checks: +<a> ~<b> −<c>`** from the diff of
   `tests/fixtures/check-names*.txt` between the run's base and tip for this repo (and from `tests-start`/`tests-end`
   for a project without a fixture: `+<n>` only), in `summary.mjs` (`checks: { added, replaced, removed }`), one
   `reportView` row `Checks` after `Suite runs`, `harness report`, and the retro prompt's `{{CHECKS}}`; **the budget**:
   a milestone's `check_budget` in the feature list (the planner's spec may set it; the initializer copies it; default
   none), and at verify the driver notes `<m>: checks +<n> against a budget of <b>` and, over it, appends
   `(over budget: <the reason from the last coding entry's "checks" field, or none given>)`. *Default:* a note, never a
   gate (a performance or count number is measured and recorded, never a gate: `decisions/2026-10-26-suite-split`,
   P0-02 attempt 3).
3. **Decision and docs.** `journal/decisions/2026-11-03-check-budget.md`; `docs/architecture.md` (`summary.mjs`'s field,
   the verify note), `README.md` (the report row, `check_budget`), `prompts/retro.md` (the line), `prompts/initializer.md`
   (copy `check_budget`).

**Checks (written first)**: a stub run whose session adds two names and removes one → `summary.json` has `checks: {added:
2, replaced: 0, removed: 1}` and the report row; a stub project with no fixture → `+<n>` from the counts; a milestone
with `check_budget: 3` and four names added → the verify note with `over budget: <reason>`; under budget → the note
without the parenthesis; the retro prompt carries the line.

### S3-review

Folded into the build feature.

---

## S4 · Purity: the bash logic that burns the suite moves to the unit tier

**Finding.** The candidates, from a read of `lib/*.sh` on 2026-11-03 (file:line as of `main` then; re-locate by
function name): (1) `lib/check.sh`'s cache and rerun decision core (`why`, `partial`'s rows 4–11, `guard`'s choice,
the cached-red read: ~60 lines, the riskiest decision table in the repo, reached only by stub suites); (2) the debrief's
parse of the model's note (`lib/debrief.sh` `continue_check`, the headline and "Needs Michael" awk: ~35 lines,
locale-bound bracket expressions); (3) the lane's verify verdict and exit table (`lib/lane.sh` 111–151, `lane_done`,
`lib/driver.sh` `reap`: ~45 lines, each branch a long stub run); (4) how a run ends (`lib/driver.sh` 570–582 and the
reason → kind and priority maps: ~25 lines); (5) the queue entry format, encode in `bin/harness` and decode in
`lib/queue.sh` (CLAUDE.md's gotcha: they must match); (6) INBOX status and stop-why parsing, twice (`lib/record.sh`
201–213, `bin/harness` 399–401); (7) the final-message marker regex written three times (`record.sh` 348, `lane.sh` 369,
`resolve.sh` 89–120); (8) `pr_body`; (9) the usage-limit backoff arithmetic, four copies; (10) the review-gate model
choice; (11) the flake row written in `check.sh` and read in `record.sh`; (12) the journal ingest protocol; (13)
debrief context assembly; (14) time and size formatting (`clock`, `age`, `dur_s`, `admit`); (15) `eval.sh` data
shaping. Gotcha hits: `(( $(jq …) >= MAX ))` at `lane.sh` 320, 399, 400 and `eval.sh` 255; `| head` SIGPIPE shapes at
`record.sh` 202, 210, 514, 527, 596, `lane.sh` 369, `driver.sh` 283.

**Choice.** In value order, as many as the milestone's four features hold, each the same shape: the logic becomes an
exported pure function in the `.mjs` that owns the data (`inbox.mjs` for 6, `queue.mjs` new for 5, `lane.mjs` new for 3
and 4, `checkdecide.mjs` new for 1, `entries.mjs` for 7 and 12), with a `tests/unit/` test per branch (equivalence
partitioning: one input per behaviour, learning entry 15); the bash calls it once through `ask` (phase 2) or a spawn
and reads labelled lines; **every note and every log line is unchanged** (the existing checks are the proof); the
Gotcha-shaped lines (`(( $(jq …) ))`, `| head`) in the touched functions are rewritten to the safe shape named in
`CLAUDE.md`. Candidates 1, 3, 4, 5 and 6 first (*default*: the decision tables and the twice-written parsers). Each
move is one line in `journal/decisions/2026-11-03-purity.md` with the lines of bash removed and the tests added.

**Checks (written first)**: the unit tests of each moved function (every branch), and the whole suite green with no
fixture change except the new unit names.

### S4-review

Sized to the milestone: a reader of each moved function against the bash it replaced, branch by branch.

---

## Milestones

| M | Contents | After |
|---|---|---|
| S1 | `HARNESS_XTRACE`, `TEST_XTRACE_DIR`, `tests/tools/coverage.mjs`; the coverage map and the mutation sample in `findings-and-research/2026-11-03-suite-coverage.md` | `[]` |
| S2 | the trim with its decision file (`2026-11-03-trim`), the renames and splits, the push-down; the coverage superset proof; S2-review | `["S1"]` |
| S3 | the `checks:` retro line, the report row, `check_budget` and the verify note; the proposed rules in the entry; `2026-11-03-check-budget`; docs | `["S2"]` |
| S4 | the purity moves, `2026-11-03-purity`; S4-review | `["S3"]` |

## Predictions

| Measure | before S1 | after S4 |
|---|---|---|
| check names (full fixture) | the count at the run's start | **−15 % or more**, coverage union ≥ before |
| mutants caught (S1-02's forty) | n caught | ≥ n |
| checks in `tests/unit/` | ~110 (phase 1) | **+40 or more** |
| stub `harness start` lines in `tests/checks/` | the count at the run's start | −10 % or more |
| full suite solo CPU | the phase 2 after row | **−10 to −20 %** |
| `harness-log.md` note texts changed by S4 | – | 0 |
| lines of bash removed by S4 | – | ≥ 150 |

Falsifiers: a coverage union smaller after S2 (a removal lost a line: restore it); a note text change in S4; a mutant
caught before and survived after.

## Not in this run

`TEST_JOBS`; the tiers' assignment rule; the helper; LLM-chosen anything; phase 5's cross-project design; rewriting
the stubs; `kcov` or any tool to install.

## After the run (Michael)

- Read the proposed rules in the S3 entry and the decision file; accept the ones you want into `CLAUDE.md` (the one
  command: none; they are text).
- The next spec you write may set `check_budget` per milestone.
