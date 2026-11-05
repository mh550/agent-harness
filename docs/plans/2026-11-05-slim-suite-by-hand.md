# The slim suite by hand: phase 4 built in five milestone sessions (2026-11-05)

*(Written by the redesign's supervisor, session 9, as the dispatch list's D6 row asks. Michael, 2026-11-04: the slim
suite is built by hand like run resilience (F1), one interactive session per milestone, and the supervisor checks each
like a run's. Spec: `docs/specs/2026-11-03-slim-suite.md`. The session's prompt:
`docs/plans/2026-11-05-slim-suite-by-hand-session.md`. Dispatch row D6, block `## D6b`. The pattern it follows:
`docs/plans/2026-11-04-f1-by-hand.md`.)*

## What it starts from (`origin/main` at `7c0e508`, 2026-11-05)

- 1,463 check names in 97 check files (57 fast, 40 slow), 692 of them in the fast tier's fixture; 196 `test(` calls in
  20 files under `tests/unit/`. The last full suite on this tree: 1,464 checks green in 587.3 s at 4 jobs (PR #111's
  own run, not the solo method). The resident helper's after row, the spec's "before" for CPU: 608.1 s and 2,107.9 CPU-s
  at 1,450 checks on `de51e2f`; two PRs landed since, so S1 measures its own before row.
- No feature list: the spec was never given to a run's initializer. Each session plans its features from its
  milestone's section of the spec and shows Michael the plan before it builds.
- `CLAUDE.md`'s `## Gotchas` holds 14 facts and memlint counts 15 lines with the comment: a new fact replaces a line or
  goes in the PR body. Two sessions of the resident helper run went red on exactly this (`39-memlint-m4`'s self-lint).

## What by hand means here

As for F1 (`docs/plans/2026-11-04-f1-by-hand.md`, *What by hand means here*): one interactive `claude` session per
milestone with Michael at the terminal, one commit per feature, a read-only reviewer with a clean context, the full
suite once, last, on the final tree, a PR the session merges, and the PR's body in place of the run's entries. What is
different from F1:

| | F1 | the slim suite |
|---|---|---|
| the features | the dead run's `feature_list.json` | planned by the session from the spec at its first step, listed in the PR body |
| the full suite, once, last | `bash tests/run.sh` | the solo method's command (below), so every milestone leaves a wall and a CPU number |
| a measurement | none | S1 measures the before row first; S4's last run is the after row |
| who reads it before the next one | the supervisor, after all three | the supervisor after the shape session (S2b) and after S4; the others hand on directly |

**The solo method** (the re-baseline's, D1): `harness status` shows RUNNING 0 and QUEUED 0, no other suite runs, then

```bash
systemd-run --user --scope -p MemoryMax=3G /usr/bin/time -v env TEST_JOBS=4 bash tests/run.sh > <scratch>/<name>.out 2> <scratch>/<name>.time
```

in the background with a timeout of at least 1,800,000 ms, never polled. The runner's `wall … s` line is the wall;
user + sys of `time -v` is the CPU; the last line is the check count. About 10 min on this box.

## The five sessions

S2 of the spec is two sessions here (**proposed, Decision 10 of the dispatch list**: Michael's to say; one session if
he says so, with both lists below): the trim changes which checks exist and must be read against the coverage tables;
the shape renames every check file and changes no check. One PR for both would bury the first in the second.

| session | what it builds (the spec's section) | on `origin/main` when | about |
|---|---|---|---|
| **S1** the measurement | the before row; `HARNESS_XTRACE` and `TEST_XTRACE_DIR`; `tests/tools/coverage.mjs`; the coverage map; the 40-mutant sample (spec S1) | `findings-and-research/2026-11-03-suite-coverage.md` | 3–5 h, most of it suite time in the background |
| **S2** the trim | the removals, each with its successor; the push-down into `tests/unit/`; the coverage and mutant proof (spec S2, items 1 and 3) | `journal/decisions/2026-11-03-trim.md` | 2–3 h |
| **S2b** the shape | the renames and splits; Decision 3's four items; the runner prints each file's tier (spec S2, item 2) | `journal/decisions/2026-11-05-suite-shape.md` | 1.5–2.5 h |
| **S3** the process | the `checks: +a ~b −c` line, the report's `Checks` row, `check_budget` and its verify note; the rules proposed for `CLAUDE.md` (spec S3) | `journal/decisions/2026-11-03-check-budget.md` | 1.5–2 h |
| **S4** the purity moves | bash decision logic moved into pure `.mjs` functions with unit tests; the after row (spec S4) | `journal/decisions/2026-11-03-purity.md` | 2–3 h |

The times are estimates (F1's sessions took 1–2 h each on a 14 min suite; the suite is about 10 min now).

### Per session, on top of the spec

**S1 · the measurement.**
- *First, before any edit:* the before row on the session's base tree. One solo suite (the command above): wall, CPU,
  checks. Then the counts every later session repeats with the same commands, each command written into the findings
  file: check names (`wc -l < tests/fixtures/check-names.txt`), fast names, unit tests (the unit tier's reported
  count), check files per tier, and the stub `harness start` lines in `tests/checks/` (the session defines the grep,
  says what it counts, and S4 reuses it verbatim).
- `HARNESS_XTRACE` is a behaviour the driver gains: it gets its check (off unless set: a stub run without the variable
  writes no trace file and its `harness-log.md` is unchanged), and by `CLAUDE.md` a decision file; the spec names none
  for S1 (*default*: `journal/decisions/2026-11-03-suite-coverage.md`, short).
- *Size the mutation sample before it starts.* Lines covered by 20 or more files (a stub start's path) make a mutant
  cost most of a suite. With the map done, say to Michael how many of the forty sit on such lines and the suite hours
  the sample will take, then run it. The spec's default stands (every covering file runs for every mutant); a cap is a
  change to the spec and his to allow.
- The mutants are applied in the worktree only, one at a time, reverted after each (`git diff --stat` empty between
  two mutants), and never committed.

**S2 · the trim.**
- The names arithmetic, so nobody is surprised at the end: the spec's −15 % is read on the full fixture after S4
  against the count at S1's base (1,463 → 1,243 or fewer). S1, S3 and S4 add names (S4 alone 40 or more unit tests),
  and a push-down replaces a check one for one. So the trim's own cut has to be larger than 15 %, or the shortfall is
  said with its reason. The decision file states both: names before and after S2, and what S3 and S4 are expected to
  add.
- A mutant is run again only if a check that caught it was removed, merged or moved; one whose catching checks all
  stand unchanged is caught as before (*default*; say which were rerun).
- The coverage union is rerun whole by S1's method after the last removal.
- The supervisor checks every removal's row mechanically: the removed name is in `git diff` of the fixture, its
  successor's name is in the fixture on `main`.

**S2b · the shape.**
- Check names do not change: the full fixture's diff adds only (the runner's new check) and removes nothing. The fast
  fixture changes only by the tier moves below, each accounted for in the decision file.
- Decision 3 of the dispatch list (Michael, 2026-11-05, yes to all four), built here:
  1. `39-memlint-m4` split: its 16 pure cases to `tests/unit/memlint.test.mjs` (names unchanged), the self-lint
     one-liner stays a fast gate (it is what caught the two reds above), its two stub runs become a slow file;
     `CHECK_KEY_MAP` and `82-key-map-lint` follow;
  2. `84-node-memo` (31.5 s solo) to the slow tier;
  3. the tiers' assignment table (`journal/decisions/2026-11-03-suite-tiers.md`) lists every check file: nine are
     missing today (`86-fast-gate`, `87-fast-gate-run`, `88-origin-after-gc`, `88-origin-outage`, `89-night-words`,
     `89-no-deadline`, `90-fix-rounds`, `91-resident-helper`, `92-resident-helper-run`), not the two Decision 3 named;
  4. the two fast-gate files renamed so the name does not read as a tier (`session-gate`, `run-session-gate`, or
     better), and the runner's per-file line prints the file's tier (Michael, 2026-11-04).
- The number prefix goes (the spec). Every place that names a check file follows in the same PR: `CHECK_KEY_MAP`,
  `tests/fixtures/`, `docs/architecture.md`, `README.md`, the prompts, and the lines of `CLAUDE.md` that name a file
  (*How to verify*'s `00-unit` and the Gotchas' `08/13/14/15` and `82-key-map-lint`): file names only, each changed
  line listed in the PR body, no rule reworded. History (specs, plans, findings, decision files) keeps the old names;
  the shape's decision file carries the old → new table.
- A split file is re-timed solo and gets its tier by the 30 s rule; the fast tier's wall after the session is in the
  PR body against the 180 s bound.

**S3 · the process.**
- The rules for `CLAUDE.md` go verbatim into the PR body under `## Proposed rules for CLAUDE.md` and into the decision
  file, never into `CLAUDE.md`: they are Michael's to accept.
- There is no run and no retro here, so the spec's "the retro's `checks:` line" is proved by its stub-run checks; the
  first real run after the merge shows the `Checks` row in `harness report`.

**S4 · the purity moves.**
- No `harness-log.md` note text changes. Two proofs in the PR body: the dispatch block's grep
  (`git diff <base> HEAD -- lib/*.sh bin/harness | grep '^[-+].*note "'`) with each printed pair shown identical in
  its quoted text, and the comparison that prints nothing when no text changed (Decision 6 (i) of the dispatch list):

  ```bash
  d=$(git diff <base> HEAD -- lib/*.sh bin/harness)
  diff <(sed -n 's/^-\(.*[^-a-z]\)\{0,1\}\(note ".*\)$/\2/p' <<< "$d" | sort) <(sed -n 's/^+\(.*[^-a-z]\)\{0,1\}\(note ".*\)$/\2/p' <<< "$d" | sort)
  ```

  (tried on PR #111's diff by the supervisor, 2026-11-05: it prints that PR's one new note, `note "$hn"`, and
  nothing else; a note S4 adds would print the same way and is a miss.)
- A mutant of S1's forty whose line this session moved is applied to the line's new home and must be caught there
  (by the unit test); the table of the forty is restated after S4 in the decision file: caught before, caught after.
- *Last:* the after row, by the same commands as S1's before row (the session's one full suite is the solo run), and
  the spec's Predictions table filled in against it in the decision file and the PR body: names, mutants caught, unit
  tests, stub `harness start` lines, solo CPU and wall, note texts changed, lines of bash removed.

## The steps (Michael)

Before S1: `harness status` shows RUNNING 0 and QUEUED 0 (S1's timings need the box to itself for its whole length).

Each session, in order (the last line names the milestone: `S1`, `S2`, `S2b`, `S3`, `S4`):

```bash
cd ~/projects/agent-harness && git fetch -q origin && claude --model claude-opus-5-5 "$(git show origin/main:docs/plans/2026-11-05-slim-suite-by-hand-session.md)

Milestone: S1"
```

Each session ends by naming the next command: after S1 the same command with `S2`; after S2 with `S2b`; **after S2b
the supervisor's** (it checks the trim and the shape before anything builds on them); after S3 the same command with
`S4`; after S4 the supervisor's.

```bash
cd ~/projects/agent-harness && claude --model claude-fable-5-1 "$(cat docs/plans/2026-11-03-test-suite-redesign-supervisor.md)"
```

## Rules for the sessions (the prompt carries them)

- A session starts only when the milestone before it is on `origin/main` and `harness status` shows RUNNING 0 and
  QUEUED 0.
- One suite at a time on this box; `TEST_JOBS` as the solo method sets it (4, this box's default) and never raised;
  the full suite once per session, last.
- A session stops and asks Michael at these points only: before it starts building (its features and plan); before
  S1's mutation sample (its size); a spec default it would contradict; a step it cannot build as written; a red
  outside its change it cannot explain; a second red full suite; anything a deny blocks.
- Subagents read and review; they never build. No `claude` started from bash.
- A removed check is never silent: its row in the decision file names the check that covers its lines now.

## What the supervisor checks (dispatch block D6b)

Per session: the PR merged with its full-suite line (`N/N checks passed`, the wall and the CPU) in the body; the
marker file on `main`; the reviewer's findings each with what was done; `docs/architecture.md` and `README.md` where
the spec's milestone asks; defaults against the spec said plainly. Then, per milestone, the list in block `## D6b`.
