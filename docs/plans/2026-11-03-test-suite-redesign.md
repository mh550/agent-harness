# Test suite redesign: the plan (2026-11-03)

*(The orchestration planner's deliverable 1 for `docs/specs/2026-11-03-test-suite-redesign.md`. Written in one Fable
session on 2026-11-03 with Michael present for the questions. Deliverable 2, the dispatch list:
`docs/plans/2026-11-03-test-suite-redesign-dispatch.md`; deliverable 3, the supervisor:
`docs/plans/2026-11-03-test-suite-redesign-supervisor.md`. The raw numbers:
`findings-and-research/2026-11-03-redesign-baseline.md`; the cited survey:
`findings-and-research/2026-11-03-test-runner-survey.md`.)*

## 0. What changed between the spec and this plan

Run `agent-harness-2026-11-03` was alive on the box all afternoon (`docs/specs/2026-10-31-suite-cpu.md`: Q1 merged as
PR #75; C1 at its review feature when this was written). Its C1 is **phase 2's first move**: C1-01 produced the exec
table by script, subcommand and caller that phase 0.2 asked for; C1-02 and C1-03 built the batching (the in-process
memo, `F poll`, the idle coordinator's single start); C1-04 proved it solo: **CPU −6.7 %** (3,361.8 → 3,136.1 s), wall
854.1 → 803.8 s, against a −20 % target. So the question phase 0.2 was to decide, batching or a resident helper, is
answered by measurement: batching is spent (most call sites are subshells the memo cannot serve; most questions are not
pure), and what is left needs a process that outlives one question. Phase 2 below is the resident helper alone.

A solo full run could not be measured today (a run alive, load average 4–6); the baseline uses C1-04's two solo rows,
measured this afternoon by the run with no other suite alive. The first dispatch piece re-measures on `main` once C1
has merged and the box is quiet, so every later before/after table has a baseline on `main`.

Michael answered the plan's four questions on 2026-11-03 (§5).

## 1. Baseline (phase 0.1, 0.2; the raw file has every number and its source)

| measure | value | where |
|---|---|---|
| solo full suite, `TEST_JOBS=4` | **803.8 s wall, 3,136.1 CPU-s, 1,129 checks** (C1's tree, 2026-11-03); 854.1 s / 3,361.8 CPU-s / 1,102 on main before C1 | baseline §1 |
| the three slowest files | `15-run-4-…` 232 s, `13-run-2-…` 205 s, `08-scope-…` 203 s (4 jobs solo, 10-30) | load curve §1 |
| slot time by file | 52 files ≤ 30 s: 580 slot-s; 34 files ≥ 33 s: 2,604 slot-s; sum 3,184 | baseline §1 |
| execs per large file (13) | 35,647; **node 3,139 (49 % of 170.6 CPU-s)**; git 7,754; cat 3,422; date 2,412; bash 1,419 | baseline §2 |
| node starts by caller (file 13) | driver 975 + lane 1,945 = **2,920 (93 %)**; cli 162; stub 48; the checks' own lines 9 | baseline §2 |
| one stub `harness start` | 19.0 s wall, 20.4 CPU-s, 402 node starts (53 % of its CPU) | baseline §2 |
| top node callers (file 13) | `features.mjs` lane 720, driver 420; `metrics.mjs` lane 314; `treekey.mjs` 205 (193 ms each: 30–40 s of the file); `entries.mjs` 191 | baseline §2, §3 |
| node start / list question / in-process request | 27 ms idle (37 loaded) / 45 ms / **0.1 ms** | baseline §3 |
| per real session | the driver's few hundred starts are 10–20 s of a 400–4,700 s session: **the cost is the suite's stub runs, not live runs** | baseline §2 |
| lane time | sessions' suite 58 % (fixes 1–3 live), 29,511 suite lane-s per 20 sessions, 1.3 full runs per session | budget §11 |
| the unit layer | 108 evals in 35 files, 1 node start each: ~3 CPU-s of 3,136 | plan §Phase 1 |

## 2. The survey (phase 0.3): what small teams use now

The full rows with every citation are in `findings-and-research/2026-11-03-test-runner-survey.md`. In one line each:

| runner | the one fact that decides it here |
|---|---|
| **`node --test`** (built in; `--test-isolation=none` since v22.8.0) | one process for the whole unit tier, `node:assert/strict` diffs, a 15-line custom reporter prints `PASS <name>`; zero install, everything on this box's 24.21; no list-only mode (the names fixture stays) |
| Vitest 5.1.0 | a warm worker pool and `--changed`/`related` selection, for `vitest` + 13 deps + `vite` in a `node_modules` per worktree, a lockfile, Node ≥ 22.12: **breaks "no npm" for nothing the unit tier needs** |
| bats-core 1.14.0 | the same one-process-per-test model `tests/run.sh` already has, fewer features (no group kill at a file timeout, no conformance), 86 files to rewrite into `@test`, three helper repos to vendor |
| `cargo test` / cargo-nextest 0.9.151 | threads in one binary / a process per test with filtersets, retries, per-test timeouts; only relevant if the hot path is Rust (§3) |

**"No npm packages" stays** (recommendation; Michael's to relax): relaxing it buys Vitest's module-graph selection,
which the bash suite (every scenario drives the whole driver) cannot use, and costs an install per worktree.

## 3. The language question (phase 0.4), answered with the numbers

| | node, spawned (today) | node, warm process (phase 2) | Rust static binary |
|---|---|---|---|
| start per question | 27–41 ms | 0 (one start per driver/lane process) | 1.2 ms |
| per-request work (a list question) | – | **0.1 ms** | ~0.1 ms (not measured; sub-millisecond either way) |
| build per worktree | none | none | 3.6 s cold (debug), 4.2 s release; 0.14–0.55 s incremental; **0.17 s for a second checkout with a shared `CARGO_TARGET_DIR`** |
| toolchain | node (already required by Claude Code) | the same | 2 GB (`~/.cargo` 457 MB + `~/.rustup` 1.5 GB), installed; **this box only** (Michael) |
| the model's edit loop | edit, run | edit, run | edit, 0.2–0.5 s compile, run |
| code to write | – | ~150 lines (`helper.mjs`, `ask`), a `main(argv, io)` per served script | a port of ~820 lines byte-for-byte with a differential check |
| what it removes per large file | – | ~2,900 of 3,139 node starts: **75–110 CPU-s of 170** | the same |
| what it brings | – | lifecycle (a child per shell, EOF-bound, spawn fallback) | no lifecycle; the compiler |

**Recommendation: stay on node and build the warm process.** Once it exists, start-up leaves the comparison and the
per-request work is 0.1 ms, which no language makes measurably smaller in a 3,100 CPU-s suite. Rust's gain is the same
as the helper's and only without the helper; its costs are a port, a toolchain and a build per tree. It is not dropped:
it is the **recorded fallback** in `docs/specs/2026-11-03-resident-helper.md` with these numbers, chosen if the helper
cannot pass its lane and lifecycle checks, and the compile-time safety Michael wants is pursued first where the error
budget actually is: the bash (`CLAUDE.md`'s Gotchas are bash traps), by phase 4's purity work. Michael accepted this on
2026-11-03 (§5, question 3).

## 4. The phases, in the order they are dispatched, with predictions

Michael chose the order **1 → 3 → 2 → 4 → 5** over the spec's 1 → 2 → 3 → 4 → 5 (§5, question 1): the unit tier first
(small, one night, the mechanism the others stand on), then tiers (the biggest lane-time lever), then the helper (the
biggest solo-wall lever, which also shrinks the slow tier), then the trim, then the design for every project. Each
phase is a harness run from its spec file; each ends with a before/after table in `findings-and-research/`; the
supervisor compares it with the prediction before the next piece is dispatched.

| # | phase | spec | nights | the measure that decides it | predicted |
|---|---|---|---|---|---|
| 1 | **Unit tier**: the 108 evals → `tests/unit/*.test.mjs` under `node --test --test-isolation=none`, a reporter into the same runner, names unchanged | `docs/specs/2026-11-03-unit-tier.md` (U1) | 1 | node starts of the unit layer; `node --test tests/unit/` wall | 108 → **1**; **< 1.5 s**; suite wall unchanged; names unchanged |
| 3 | **Tiers**: `# tier:` headers, `--tier fast|slow`, per-tier conformance, the 30 s rule; `check.sh --fast`, `fast-<key>`, `run_init fast`, `green_fast`, the prompt rule; **`passes` on fast-green, the full suite at verify** | `docs/specs/2026-11-03-suite-tiers.md` (T1, T2) | 1–2 | fast tier solo wall; sessions' suite share; full runs per session | **≤ 180 s** (~150); **58 % → 20–30 %**; 1.3 → ≤ 0.2; ≤ 1 verify red per milestone |
| 2 | **Resident helper**: `lib/helper.mjs` + `ask` over a `coproc` per driver/lane shell, EOF-bound, spawn fallback; `treekey`'s git cut | `docs/specs/2026-11-03-resident-helper.md` (H1) | 1 | node starts per large file; solo CPU and wall | 3,139 → **≤ 300**; CPU **−25 %** (≤ 2,300 s); wall **≤ 600 s**; 0 note changes |
| 4 | **Slim suite**: coverage map (xtrace + `NODE_V8_COVERAGE`), 40-mutant sample, trim with no coverage loss, files named for the unit, push-down, the `checks: +a ~b −c` retro line and `check_budget`, purity moves | `docs/specs/2026-11-03-slim-suite.md` (S1–S4) | 2–3 | names; coverage union; mutants caught; unit tests; bash lines removed | **−15 % names**, union ≥ before, caught ≥ before; +40 unit tests; CPU −10–20 %; ≥ 150 bash lines moved |
| 5 | **Every project**: a design (no code) of what is reusable (the runner, tiers, conformance, the stubs' rule, the per-run numbers), one runner or one per language, the rules per project | a `claude` session writing `docs/specs/2026-11-xx-every-project-testing.md` | 0 (a session) | the design's presence and Michael's read | – |

**The whole, if every prediction holds:** solo full suite 804 → ~500 s and 3,136 → ~1,900 CPU-s (phases 2 and 4); a
coding session's gate 805 → ~150 s (phase 3; the full suite once per milestone); the sessions' suite share of lane time
58 % → ~20 %, about 15,000 lane-s per 20 sessions back to the model; the suite growing by unit tests, not stub runs.

### Phase 1 · Unit tier (spec: `2026-11-03-unit-tier.md`)

Why first: cheap (one night), no driver change, and it is the tier phase 3's fast tier starts from and phase 4 pushes
behaviours down into. Its speed gain is ~3 CPU-s and the spec says so; its gain is a unit tier a session runs in under
a second with real assertion diffs. Names reach the fixture as today through the reporter (Node's runner has no
collection mode; recorded as rejected-for-now). The node floor rises to 22.8 for `--test-isolation=none`.

### Phase 3 · Tiers (spec: `2026-11-03-suite-tiers.md`)

The fast tier is `00-unit-tier` + the 52 files under 30 s solo + `39-memlint-m4` (the one file that caught a real
regression outside its feature, twice); ~150 s solo. The gate: **`passes` stands on a fast-tier green** (Michael,
question 2); the verify's `run_init fresh` full run and the merge stand on green as today, so the slow tier runs once
per milestone instead of 1.3–1.7 times per feature. The invariant is restated for two markers (`fast-<key>` is never
read as `green-<key>`). The prompt tells a session to also run the slow file its change touches when it edits the
driver's scenario paths; a verify red is the gate's measured cost (≤ 1 per milestone predicted). Other projects:
`check.sh --fast` with no `CHECK_FAST_CMD` is the full form, nothing to configure.

### Phase 2 · Resident helper (spec: `2026-11-03-resident-helper.md`)

Each shell that sources `lib/record.sh` (the coordinator, each lane) starts one `node lib/helper.mjs` lazily with
`coproc`; `ask <script> <args…>` writes a request line and reads a length-prefixed reply byte for byte; a backgrounded
job of the same shell, a timeout, an EOF or a bad header falls back to a spawn and restarts the helper (bounded; logged);
the helper dies on stdin EOF when its shell exits. Served scripts gain `main(argv, io)` and lose CLI side effects on
import; no module-level state. `treekey`'s own 193 ms (git over the whole tree, 205 calls per file) gets its cut in the
same run. The checks compare a stub run with and without the helper (`HARNESS_HELPER=0`): identical logs. C1's rejected
"long-lived server" paragraph is updated in place: a per-shell coproc is not a server.

### Phase 4 · Slim suite (spec: `2026-11-03-slim-suite.md`)

S1 measures with what is on the box (`set -x` through `BASH_XTRACEFD` into the driver under a variable, `NODE_V8_COVERAGE`,
a seeded 40-mutant sample run against the covering files only). S2 trims and renames with the evidence (a removal names
its successor; the coverage union may not shrink). S3 proposes the rules for `CLAUDE.md` (Michael's) and builds the
`checks:` retro line and `check_budget` note. S4 moves the bash decision tables into pure functions with unit tests.
The purity candidates, from a read of `lib/*.sh` on 2026-11-03 (file:line as of `main` then):

1. `lib/check.sh` 58–65, 97–123, 129–151, 196–201: the cache, partial and rerun decision core (~60 lines; only stub suites reach it).
2. `lib/debrief.sh` 272–294, 335–341: the parse of the model's note (`CONTINUE:`, headline, "Needs Michael"; ~35 lines, locale-bound classes).
3. `lib/lane.sh` 111–151, 224–233 (`lane_done`), `lib/driver.sh` 108–113 (`reap`), `lane.sh` 185–201: the verify verdict and lane exit table (~45 lines).
4. `lib/driver.sh` 570–582, 303–305, 330–332: how a run ends, the reason → kind and priority maps (~25 lines).
5. `bin/harness` 214–219, 148–156, 330–334; `lib/queue.sh` 37–66, 94: the queue entry format, encoded in one file and decoded in another (~35 lines; a CLAUDE.md gotcha).
6. `lib/record.sh` 201–213 and `bin/harness` 399–401: INBOX `status:` and stop-why parsing, twice (~15 lines; belongs in `inbox.mjs`).
7. `lib/record.sh` 348, `lib/lane.sh` 369, `lib/resolve.sh` 89–120: the final-message marker regex, three copies (`sed | head -1`, a SIGPIPE shape).
8. `lib/record.sh` 505–516: `pr_body` (a jq per feature, two awks; ~12 lines; only the merge path).
9. `lib/lane.sh` 349–350, 92; `lib/resolve.sh` 82; `lib/debrief.sh` 258–260: the usage-limit backoff arithmetic, four copies.
10. `lib/lane.sh` 279–283, 300–315, 376–382: the review-gate model choice (~20 lines).
11. `lib/check.sh` 143–148 and `lib/record.sh` 84–96: the flake row, written in one file and read in another.
12. `lib/record.sh` 369–402: the journal ingest protocol and `questions_` (`[[ $(jq …) == 0 ]]`, beside the gotcha).
13. `lib/debrief.sh` 62–74, 92, 133–138, 151–157: debrief context assembly (~30 lines of jq).
14. `lib/record.sh` 252–257, `lib/desk.sh` 36–40, `lib/scope.sh` 32–35, 101–113, `lib/config.sh` 90–96, `bin/harness` 182–183: time and size formatting, `admit`, `weekly_over` (pure once "now" is passed).
15. `lib/eval.sh` 31–61, 144–173, 209, 255: data shaping beside the existing `lib/eval.mjs`.

Gotcha-shaped lines seen: `(( $(jq …) >= MAX ))` at `lane.sh` 320, 399, 400 and `eval.sh` 255; `| head` after a
multi-write producer at `record.sh` 202, 210, 514, 527, 596, `lane.sh` 369, `driver.sh` 283. Counts: 53 `jq` and 93
`node` occurrences in `lib/*.sh` + `bin/harness`, plus ~136 call sites of the `F`/`MET`/`SUM`/`EV` wrappers.

### Phase 5 · Every project (a design session, dispatch piece D7)

The cases: pathways (`tests/*.test.ts`), dj-crate-streaming (pytest; **live**, its `CLAUDE.md` binds), hit_list
(`npx expo lint && npx tsc --noEmit && npx jest --silent`), n8n-home (`tests/checks` + `tests/fakes`, this repo's
shape; **live**). The design answers: which parts of this suite travel (the runner and its tier/conformance rules for
bash suites; the `CHECK_FAST_CMD` idea for every runner: `pytest -m "not slow"`, `jest --selectProjects`; the stubs'
"mirror the live API" rule; the per-run counts and the `checks:` line), whether one shared runner (a `templates/project/tests/`
kit for bash suites) or one per language (the native runner with the tiering convention), and the rules that keep each
suite growing well (tiers from day one, a count in every run's log, a trim pass per iteration, a budget per milestone).

## 5. What Michael decided (2026-11-03, in the planning session)

1. **Order:** 1 → 3 → 2 → 4 → 5.
2. **The gate under tiers:** a feature's `passes` stands on a fast-tier green; the slow tier runs at verify; the merge
   gate stays the full suite.
3. **Language:** node, with the coproc helper; Rust recorded as the measured fallback.
4. **Boxes:** the harness runs on this box only, right now.

Still his after reading: relax or keep "no npm packages" (the plan keeps it); the tier rules' wording in
`CLAUDE.md`; the phase 4 process rules (proposed in that run's entry); and when to queue each run (the dispatch list).

## 6. How each phase is run and measured

- A phase is one `harness queue add ~/projects/agent-harness --spec <spec> --brief "<brief>"` (the repo's own
  workflow; `harness start` refuses a spec absent from `origin/main`, so this plan merges first). Milestones in series
  where the spec says so; the run's last build feature is its measurement; its review feature is the last.
- The measurement feature of every build phase runs two solo suites (C1-04's method) with no other suite alive, and
  writes a before/after table in `findings-and-research/2026-11-03-<phase>.md`; phase 3's lane-time numbers need a real
  run under the tiers, so they are read off the phase 2 run by a `budget.mjs` session (dispatch piece D5).
- The supervisor (`…-supervisor.md`) reads each run's record (`harness status`, `harness report <run>`, the PRs, the
  findings file) against the prediction, dispatches a diagnosis before the next phase when a number misses, and keeps
  the dispatch list's status column current.
- The two open `harness needs` questions of run `agent-harness-2026-11-03` (Q1-02's absolute-spec default, C1-05's
  `TEST_JOBS=2` sentence placement) are Michael's; neither blocks this plan.

## 7. Not in this plan

Raising `TEST_JOBS` or pairing suites at 8 jobs (the load curve); LLM-chosen verdicts or gate subsets; any change to
the live checkout or a real run by the planner or the supervisor; Rust now; Vitest; bats.
