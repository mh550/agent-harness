# Test suite redesign: warm workers, tiers, a slim suite, and a process that keeps it slim (2026-11-03)

**Goal.** The suite is the lane's main cost (58 % of lane time with fixes 1–3 live, 77 % before;
`findings-and-research/2026-10-29-run-time-budget.md` §11) and it grows about 3 CPU-s per check (335 → 1,084 checks in
two weeks). Redesign it for speed and quality, iteratively, each step measured against the step before: first the
process model (one warm process serving many checks instead of one process per check), then the suite's shape (a
fast pre-merge tier and a slow nightly tier; fewer, better checks), then the development process that keeps it that
way, and a view of how every project of Michael's should test. Speed and efficiency are the priority; best practice
stays in view even where it is not the next step.

**Who runs this.** A Fable session as **orchestration planner**, started interactively by Michael
(`docs/specs/2026-11-03-test-suite-redesign-start.md` is its opening prompt). It explores the key issues, plans
first, writes no code, and hands every piece of work to other sessions as copy-and-paste commands. Phases are built
one at a time from its specs, each merged with its numbers, under a supervisor session it also defines.

## How the planning session works

1. **Explore before planning.** Read the sources below and the code they name; run the phase 0 measurements; search
   and cite for the survey. Ask Michael only where two readings lead to different plans, in one batch.
2. **Deliverable 1: the plan**, `docs/plans/2026-11-xx-test-suite-redesign.md`: the baseline, the survey table, the
   language recommendation, the order of phases with predictions, and for each phase a spec section (or a spec file
   under `docs/specs/`) a fresh session can build from without this conversation.
3. **Deliverable 2: the dispatch list**, `docs/plans/2026-11-xx-test-suite-redesign-dispatch.md`: one block per
   piece of work, in order, each a fenced bash command Michael pastes as is. A piece that is a spec to build is a
   harness run (`harness start`/`harness queue add` with the spec and a brief, the repo's own workflow); a piece
   that is exploration, measurement or review is a `claude --model claude-fable-5-1 "<prompt>"` command (or the
   model the piece needs, said why) whose prompt is complete in the block: the files to read, the question, the
   output file, the rules that bind. Every block says what it produces and what the supervisor should check.
4. **Deliverable 3: the supervisor**, `docs/plans/2026-11-xx-test-suite-redesign-supervisor.md`, and one bash
   command in the dispatch list that starts it (`claude --model claude-fable-5-1 "$(cat <that file>)"`). The
   supervisor's prompt: read the dispatch list and the plan; find each dispatched piece's results (`harness status`,
   `harness report <run>`, the output files, the PRs); verify the numbers against the predictions; decide what must be
   dispatched before the next step (a fix, a re-measure, a review) and give Michael the next copy-and-paste command;
   update the dispatch list's status column; never run a harness command itself except `status`, `report`,
   `parked`, `sync` (user `CLAUDE.md`); never touch real runs or real state.
5. **Iterative and measured.** Each phase shows its improvement before the next starts: a before/after table in
   `findings-and-research/`, cited in the dispatch list's status. If a phase's numbers miss its prediction, the
   supervisor dispatches a diagnosis before the next phase.
6. **Worktree only**, as `CLAUDE.md` binds; the planner commits its plan on a branch, opens a PR and merges it.

**Source.** `journal/learning/2026-10-30-test-engineering.md` (the concepts, the four defaults, Michael's reasoning:
entries 5–16 are the argument for this spec); `findings-and-research/2026-10-29-run-time-budget.md` (§10–11 numbers,
the strace: 28,325 execs per large file, 2,239 node starts of which 1,684 the driver's own; fix 6 "process starts"
not yet built); `findings-and-research/2026-10-30-suite-load-curve.md` (1/2/4/8 jobs 2,866/1,459/805/599 s solo;
paired at 8 jobs 1,192 s each with file 15 at its timeout); `decisions/2026-10-26-suite-split` (why 86 files; the
file is the unit of parallelism, isolation and timeout); `decisions/2026-10-30-cpu-time-bound-and-stopped-files`;
`docs/specs/2026-10-30-suite-time.md` (fixes 1–3, live).

**Rules.** `CLAUDE.md` binds: worktree only; never touch real runs or real state; fakes mirror the live API; every
behaviour test-first in `tests/checks/` with its name in the fixture (until this spec's phases change that mechanism,
and then under whatever replaces it, with a decision file); `bash -n`, `node --check`; one decision file per behaviour;
`docs/architecture.md` and `README.md` in the same milestone. The invariant of `docs/specs/2026-10-30-suite-time.md`
holds throughout: **a tree is never marked green by anything but a green run of every check that reads what changed
in it.** The gate stays deterministic: no LLM decides a verdict (`decisions/2026-10-26-suite-split` S3; learning
entry 6). Every phase ends with a before/after table in `findings-and-research/` (solo wall at 4 jobs, CPU, node
starts per large file, flake rows per run, checks run per tier).

## Phase 0 · Baseline and survey (the planning session's own work, no code)

1. **Baseline.** One solo full run's numbers as they stand (wall, CPU, the three slowest files, execs and node starts
   per large file from `strace -f -c` or `-e trace=execve` on file 15), written down before anything changes.
2. **Where the node starts come from, by caller.** Split the driver's node calls by `.mjs` file and verb (`features.mjs`
   `next`/`lanes`/`pass`/…, `metrics.mjs`, `entries.mjs`, `treekey.mjs`), per stub run and per real session. This
   decides whether batching (fewer, larger calls) or a resident helper (one warm process the driver talks to over a
   pipe) is the first move for the driver.
3. **Survey, cited.** What small teams use now for a bash-plus-node project, with primary sources opened and checked
   (project docs, READMEs, release notes), not listicles: at least `node --test` (built in), Vitest, bats-core for bash,
   and `cargo test`/`cargo-nextest` for the Rust question. For each: start-up model (one process per file, worker
   pool, daemon), assertion and reporting output, parallelism, filtering, what it costs to adopt here (the "no npm
   packages" rule is Michael's to relax; say what relaxing it buys), and how a harness session would run a subset.
4. **The language question, answered with numbers, not taste.** Once a warm process exists, start-up leaves the
   comparison; what is left is per-request work. State the measured per-request cost in node after phase 1, the
   estimated cost in Rust, the build cost per worktree (cold and incremental; `CARGO_TARGET_DIR` shared or not), the
   toolchain cost on every box the harness runs on, and the model's edit-compile loop cost. Recommend one of: stay
   on node; node now, Rust for the driver's hot path (`treekey`, `features`) as one static binary later; Rust now.
   Michael's stated priority is speed and quality with bigger fish first; do not drop Rust for being the smaller fish,
   put it in the plan where its numbers say it belongs.
5. **Output.** `docs/plans/2026-11-xx-test-suite-redesign.md`: the baseline, the survey table, the language
   recommendation, and one spec per phase below with predictions the retro can compare.

## Phase 1 · One warm process for the unit layer

The 108 `node --input-type=module -e` evals in 35 check files each start node. Move them to test files run in one
process (`node --test` or the surveyed choice), with real assertions (`node:assert`) in place of hand-built exit codes.
Keep every behaviour they check. Decide and record how their names reach the fixture (or what replaces the fixture
for this tier: a collection pass, learning entry 5). Measure: node starts and CPU of the pure files before and after.

## Phase 2 · The driver's own process starts (fix 6)

The harness under test pays most of a stub run's node starts. Build the first move phase 0.2 chose: batching
(`features.mjs` answers several questions per call; `metrics.mjs` one row per session, not one process per field) or
a resident helper. A resident helper must own its lifecycle (start with the driver, die with it, restart on crash),
be safe under lanes (one per lane or one shared with serialised requests), and fall back to a spawn when absent.
Measure per large file and per real session.

## Phase 3 · Tiers: pre-merge and nightly

Split the suite into a fast tier every session runs before it claims a feature (target: a few minutes solo at 4 jobs;
the pure files, the short scenario files, every check that has caught a real regression) and a slow tier the verify
and the merge gate run (the long stub runs: files 15, 13, 08 and their kin). Rules to settle in the spec: what a
session's `check.sh` call runs by default; what marks a tree green for a merge (the invariant above: the full suite,
or the slow tier on top of a green fast tier with the same key); how a check is assigned a tier and who may move it.
Measure: lane time share, time-to-signal for a session.

## Phase 4 · A slim suite, and a process that keeps it slim

- **Trim.** Find redundant checks (coverage of the bash and `.mjs` lines each file exercises; checks that assert the
  same lines of the same log) and checks that catch nothing (mutation: break a line, see what goes red). Merge or
  remove, with a decision file naming what was removed and why; the conformance fixture shrinks with it.
- **Shape.** Push checks down the pyramid: a behaviour of a pure function gets a unit test, not a stub run; a scenario
  file tests one scenario and is named for the unit under test, not its history (`run-2b-stop-records`).
- **Process.** Rules for every future session, proposed for `CLAUDE.md` (Michael's to accept): a new behaviour in a
  pure function gets a unit test; a stub run is added only for a driver behaviour no unit test can see; a check that
  duplicates an existing assertion replaces it; a retro line reports checks added, replaced and removed per run; a
  check-count budget per milestone with an explicit over-budget reason.
- **Purity.** Which driver logic still lives in bash and could be a pure function (candidates: anything the Gotchas
  list has burned the suite on), so it moves to the unit tier.

## Phase 5 · Every project

A short design, not code: which parts of this suite are reusable across Michael's projects (the runner, the tiering,
the conformance idea, the stubs' "mirror the live API" rule, the per-run numbers) and which are per project; whether
one shared runner or one per language; the rules that keep each project's suite growing in a manageable, organised,
effective way (tiers from day one, a count in every run's log, a trim pass per iteration). Pathways, dj-crate-streaming,
hit_list and n8n-home are the cases; their live-system rules in each `CLAUDE.md` bind.

## Not in this spec

- Raising `TEST_JOBS` or pairing suites at 8 jobs (the load curve says no).
- LLM-chosen verdicts or LLM-chosen gate subsets (an LLM may pick an inner-loop subset; the gate is the full tier).
- Changing the live checkout or any real run.

## After the plan (Michael)

Read the plan, accept or change the language recommendation and the tier rules, relax or keep "no npm packages", and
queue the phases as runs.
