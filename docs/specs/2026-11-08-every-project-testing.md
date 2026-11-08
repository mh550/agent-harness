# Every project's testing: what travels from the harness's suite, one runner per language, and each project's first step (2026-11-08)

**Goal.** Phase 5 of `docs/plans/2026-11-03-test-suite-redesign.md` (§4, dispatch piece D7): a design, no code. Phases 1–4
gave this repo a unit tier (`decisions/2026-11-03-unit-tier`), two tiers behind one fast gate (`decisions/2026-11-03-suite-tiers`,
`decisions/2026-11-03-fast-gate`: `CHECK_FAST_CMD`, `check.sh --fast`, `fast-<key>`), a resident helper
(`decisions/2026-11-03-resident-helper`), and a process that keeps the suite slim (`decisions/2026-11-03-trim`,
`decisions/2026-11-05-suite-shape`, `decisions/2026-11-03-check-budget`: the `checks: +a ~b −c` note, `check_budget`). This
spec says which of that reaches pathways, dj-crate-streaming, hit_list and n8n-home, how, and in what order. Every
claim about a project cites the file it was read from; nothing in any project was changed.

**Rules.** The two live projects' `CLAUDE.md` `## Live system` sections bind every step here (`~/projects/dj-crate-streaming/CLAUDE.md`,
`~/projects/n8n-home/CLAUDE.md`): a testing change is build work, never a deploy, a live write or a live read beyond
`Check`. The gate stays deterministic (`decisions/2026-10-26-suite-split` S3). The invariant of
`docs/specs/2026-10-30-suite-time.md` holds in every project: a tree is green only by a green run of every check that
reads what changed in it; a fast-green is never read as a green (`decisions/2026-11-03-fast-gate`).

## 1. The four suites today

| project | runner and shape | size | time | share of lane time | rules that bind a change |
|---|---|---|---|---|---|
| **pathways** | `npm run check` = `tsc --noEmit` then `node --experimental-strip-types --test "tests/**/*.test.ts"` (`package.json` scripts; `.harness/config.sh` detects it); 34 flat `tests/*.test.ts` files, fixtures and a fake Navidrome under `tests/fixtures/`, `tests/helpers/subsonic-fake.ts` | 259 `test(` calls (a grep); 122 → 257 tests in run `threads-2026-10-17` (`.harness/runs/threads-2026-10-17/summary.json`) | **not measured**: one run, before `lib/scope.sh` (2026-10-25) | not measured | `CLAUDE.md` Code rules: zero runtime dependencies, Playwright outside the repo, never in `package.json`; `samples/` read-only (Off-limits) |
| **dj-crate-streaming** | `.harness/check.sh`: pytest `-q -x -p no:cacheprovider`, every path into scratch, live credentials unset (`.harness/check.sh`); 87 `tests/test_*.py`, `tests/conftest.py` (frozen policy, limiter reset), fakes `subsonic/fake_server.py`; no `pytest.ini`/`pyproject.toml`; marks in use: `parametrize` 132, `usefixtures` 33, `skipif` 9, **no `slow`** | 1,849 `def test_` (1,933–2,369 collected per run, parametrized) | **580–930 s**, growing with the count (`findings-and-research/2026-10-30-run-time-budget-dj-hitlist.md`); `CLAUDE.md`: "about 12 minutes" | **59 %** of lane time (62 % every caller); 1.6–1.8 full runs per coding session | **live** (`POLICY=live-staged`, `LIVE_LOCK` in `.harness/config.sh`; `CLAUDE.md` `## Live system`: Check, Snapshots, backup window, Never); the sandbox in `check.sh` is the suite's safety and stays; Gotcha: `-x` hides every failure after the first |
| **hit_list** | `CHECK_CMD="npx expo lint && npx tsc --noEmit && npx jest --silent"` (`.harness/config.sh`), the same three gates as CI (`.github/workflows/ci.yml`, which also runs `--coverage`); jest 29.7 with `jest-expo`, config in `package.json` (`testMatch **/*.test.ts?(x)`, `src/__integration__/` excluded); pgTAP in `supabase/tests/` and the integration suite are separate commands (`CLAUDE.md` Testing) | 107 `src/__tests__` files, 1,931 `it`/`test` calls (a grep); 12 pgTAP, 7 integration | **8–30 s** (median 11 s at 360–656 tests, 19 s at 656–1,937) | **16 %** (17 % every caller); 1.95–2.4 runs per session, most direct `npx jest`/`tsc` calls | build-only; `CLAUDE.md` Testing already says "Fakes mirror the real API" and TDD; Docker: only `supabase_*_hit-list` containers, never `dj-*` or `n8n-*` |
| **n8n-home** | `.harness/check.sh` → `tests/run.sh`: 21 groups in `tests/checks/*.sh`, each with `# check: <name>` and `# needs: none\|rig` (11 none, 10 rig; one `# env:`); the rig is a throwaway `n8n-test-<id>` container against `tests/fakes/server.mjs` (fake Anthropic API and ntfy); `--only`, `--list`, `KEEP=1`; `tests/lib.sh` `check()` prints `PASS`/`FAIL`, the run ends `<n> passed, <m> failed`; a node unit tier `tests/unit/*.test.mjs` via `tests/checks/unit.sh` | about 250 `check` calls (a rough grep), 6 unit files | **about 150 s** (`CLAUDE.md` How to verify); not measured in a run | not measured (one run, before scopes) | **live** (`POLICY=live-staged`; `CLAUDE.md` `## Live system`: `/srv/n8n`, the encryption key never read, deploys only through `scripts/deploy.sh` under `flock`); `deploy/compose.yml` says `name: n8n` (the live project), so every test compose call passes `-p n8n-test-<id>` (Code rules) |

## 2. What travels, and how

- **The gate and its contract travel already.** `lib/check.sh` is the one command in every project; `CHECK_CMD`,
  `CHECK_FAST_CMD`, `CHECK_KEY_IGNORE`, `CHECK_NAMES` and `check_budget` are project settings
  (`templates/project/config.sh`). With `CHECK_FAST_CMD` empty, `--fast` is the whole suite, so **a project adopts tiers
  by setting one line**, no harness change (`decisions/2026-11-03-fast-gate`).
- **The per-run counts travel already.** `lib/testcount.mjs` reads node's `ℹ pass N` (pathways), jest's `Tests: N passed`
  (hit_list), the generic `N passed` (pytest's `-q` summary for dj, n8n-home's `<n> passed, <m> failed`), or a
  `HARNESS_TESTS=<n>` contract line; `tests-start`/`tests-end`, `<id>: suite ran <n>x (<s> s)`, the report's `Suite runs`
  row and the `checks: +<n>` note from counts (`source: "counts"`, `lib/summary.mjs`) need no fixture
  (`decisions/2026-11-03-check-budget`). `CHECK_NAMES` and the `~b −c` detail need a names file: only bash suites get one (below).
- **The rerun guard half-travels.** `check.sh` reruns a red's `HARNESS_FAILED=<files>` when the suite prints the line,
  else the whole suite (`decisions/2026-10-29-rerun-guard`). No project's suite prints it, so a dj red costs a second
  600–900 s run. The line is any runner's to print: dj's `check.sh` can take pytest's `FAILED tests/test_x.py::…` summary
  lines (`-rf`) and print the files; hit_list's and pathways' reds are seconds, not worth it.
- **The bash suite kit** (`templates/project/tests/`: `run.sh`, `lib.sh`, `fixtures/check-names.txt`,
  `fixtures/check-names-fast.txt`), cut from this repo's `tests/run.sh` and `tests/lib.sh`: file selection by name,
  `# tier:` on line 2 with the fail-closed refusal, `--tier fast|slow`, `TEST_JOBS` files at a time under a watchdog and
  `TEST_FILE_TIMEOUT`, the `<file>: <n> checks, <s> s, tier <t>` line, the slowest three, conformance per tier against the
  fixtures, `N/M checks passed`, `HARNESS_FAILED=`. Not in the kit: the throwaway harness state, stubs and `hlog`
  (`tests/lib.sh` `suite_setup` on): those are this repo's. The kit adds two hooks this repo doesn't need,
  `suite_setup`/`suite_teardown`, run once around the files that declare `# needs: rig`, so n8n-home's container boot
  and its `KEEP=1` move there and its 21 groups become kit files. For bash suites only: n8n-home now, a future one by
  `harness init`.
- **The tier convention for native runners**: no runner of ours is replaced; each gets its own subset as `CHECK_FAST_CMD`,
  chosen by the same 30 s rule (`decisions/2026-11-03-suite-tiers`: a file over 30 s solo in two runs is slow), with the
  full command unchanged:
  - **dj**: `CHECK_FAST_CMD=".harness/check.sh -m 'not slow'"` (`check.sh` passes its arguments to pytest), a
    `pytest.ini` registering `slow` with `--strict-markers` (an unregistered mark is a warning, not an error), and
    `@pytest.mark.slow` on the files the profile names (§5). A `pytest.ini` is the first config file dj's tests get.
  - **hit_list**: nothing now (§5). When it is due: `projects` in the `package.json` jest block, two entries sharing the
    preset (`displayName` `fast`: `src/utils`, `src/stores`, `src/db`, `src/sync`; `slow`: the screen and component files),
    and `CHECK_FAST_CMD="npx tsc --noEmit && npx jest --silent --selectProjects fast"`. `tsc` stays in the fast tier: a type
    error is what `passes` must not stand on; `expo lint` runs at verify.
  - **pathways**: stay on `node --test`; bun is a second runtime and Vitest is 13 packages plus Vite
    (`findings-and-research/2026-11-03-test-runner-survey.md`), against its zero-dependency rule. The tier is a directory,
    since `node:test` has no marker and no list mode: the files over 30 s move to `tests/slow/`, `npm test` stays the full
    glob `tests/**/*.test.ts`, and `CHECK_FAST_CMD="npm run typecheck && node --experimental-strip-types --no-warnings --test 'tests/*.test.ts'"`
    (one level, no recursion). If the profile finds no file over 30 s, no tier: the suite is its own fast tier.
  - **n8n-home**: the kit's `--tier fast` (today's `needs: none` groups) as `CHECK_FAST_CMD=".harness/check.sh --tier fast"`;
    the rig groups are the slow tier and run at verify. Until the kit lands, `--only <the 11 none groups>` is the same
    tier, hand-listed and fragile.
- **"Fakes mirror the live API" as one `CLAUDE.md` line** in every project's Code rules or Testing section, Michael's to
  paste: *Fakes mirror the live API: a stub's output copies a real response or CLI line captured into `tests/fixtures/`,
  never a format typed from memory.* Three of four already have a form of it (hit_list Testing; n8n-home Code rules,
  "fixtures are copied from real harness files"; pathways "Navidrome is tested on the fake only"); dj has "follow those
  fakes" in How to verify. One wording, and the `templates/project/CLAUDE.md` Code rules gain it.

## 3. One shared runner, or one per language

**One per language: the native runner, under one shared contract.** The contract is what the harness reads and sets:
`CHECK_CMD`, `CHECK_FAST_CMD`, the count line, `HARNESS_FAILED=`, the markers. The reason is in the numbers and the rules.
The cost phases 1–2 removed was process starts, not run time (learning entry 12; `decisions/2026-11-03-resident-helper`):
pytest and jest are already one warm process or pool, and `node --test` one per file or one in all, so a bash runner
around them would add starts and a second place to filter, and would re-implement what `-m`, `--selectProjects` and a glob
do in one flag. The native runners' output is already parsed (`lib/testcount.mjs`), their fakes and fixtures are their
own, and each project's `CLAUDE.md` names its runner as the thing a session runs. A shared runner is right only where the
tests are shell checks with no runner of their own: this repo and n8n-home, whose `tests/run.sh` is already this repo's
shape (`tests/lib.sh` `check()`, `PASS`/`FAIL` lines, groups by file). That is the kit, and it is a template, not a
shared library: a project copies it and owns it (as `templates/project/*.sh` are copied today), so a harness change never
breaks a project's suite and a project's fix never waits on a harness run.

## 4. The rules that keep each suite growing well

Proposed for every project's `CLAUDE.md` How to verify (Michael's to paste; the harness side exists):

1. **Tiers from day one.** `CHECK_FAST_CMD` set when the first file passes 30 s solo, by the native runner's filter;
   the full suite at verify and before a merge. A new file declares its tier (mark, project or directory) when it is
   written. `templates/project/CLAUDE.md` How to verify gains the line `Fast tier: <command> (what passes stands on)`.
2. **A count in every run's log.** The suite's last line is one `lib/testcount.mjs` reads, or `HARNESS_TESTS=<n>`; the
   harness then notes `tests-start`/`tests-end`, `suite ran <n>x (<s> s)` and `checks: +<n>` without a fixture. A suite
   whose count the harness cannot read is a bug in the suite's output, fixed first.
3. **A trim pass per iteration.** A run whose `Checks` row shows `+n ~0 −0` for three milestones in a row gets a trim
   feature in its next spec, with the evidence the runner gives: jest `--coverage` (already in hit_list's CI),
   `node --experimental-test-coverage` (pathways, the unit tier), `pytest --cov` (dj: one more `pipx` package, Michael's),
   and the kit's `TEST_XTRACE_DIR` (n8n-home). A removed check is named in the decision store with the check that covers
   it now (`decisions/2026-11-03-trim`).
4. **A budget per milestone.** The spec sets `check_budget` where it knows the shape; the verify note says
   `over budget: <reason>` when a milestone passes it (`decisions/2026-11-03-check-budget`); a note, never a gate.
5. **A pure function gets a unit test, never a scenario.** Per language: a `src/utils`/`src/stores` test, not a screen
   render (hit_list); a `tests/test_<module>.py` on the function, not a run of the fake server (dj); a `tests/*.test.ts`
   on the module, not `*-server.test.ts` (pathways); `tests/unit/*.test.mjs`, not a rig group (n8n-home). A scenario is
   added only for a behaviour no unit test can see, in the file named for its unit (`decisions/2026-11-05-suite-shape`).

## 5. Per project: the first step, its cost, and what Michael decides before it is queued

| project | first step | cost | Michael decides first |
|---|---|---|---|
| **dj-crate-streaming** | **Any dj night begins with a read-only profile**: `.harness/check.sh --durations=25 -p no:cacheprovider` on the run's worktree, in the sandbox `check.sh` builds (no live path, no credential: `.harness/check.sh`), its 25 slowest tests and the per-file sum into `findings-and-research/` of that run. Then, in the same run's first milestone: `pytest.ini` (`slow` registered, `--strict-markers`), `@pytest.mark.slow` on the files the profile puts over 30 s, `CHECK_FAST_CMD` in `.harness/config.sh`, and `HARNESS_FAILED=` from `-rf` in `check.sh`. Predicted: the sessions' suite share 59 % → 20–30 % (this repo's phase 3 table), the full suite unchanged. | one full suite (10–15 min) for the profile; one milestone of three or four features | (a) whether `-x` leaves `check.sh` for the full run (today one red hides the rest; the rerun guard then reruns a file that may hold more); (b) the `slow` line: 30 s per file as here, or a per-test bound (`--durations` reports tests, not files); (c) that a dj run is build-only this night: no deploy, no live write, so `## Live system`'s Check and Snapshots are not entered |
| **hit_list** | **Nothing** until the whole suite is over 60 s by `check.sh`'s own clock (`green-<key>` line 2, the prompt's `Suite:` line). At 8–30 s and 17 % of lane time, a fast tier would save under 20 s a session and cost a `projects` split that every new test file must then be filed into. When it crosses the line: time the three gates separately (`time npx expo lint`, `time npx tsc --noEmit`, `time npx jest --silent`), then §2's `projects` split. | nothing now; later one feature | the trigger (60 s, or a lane-time share) and that `expo lint` may leave the fast tier |
| **pathways** | **Measure once**: `time npm run check` and `time npm test` on a quiet box (free: no run record holds a suite time; `summary.json` of `threads-2026-10-17` has counts only), with `node --test`'s per-file durations (`--test-reporter=spec` prints them). Under 60 s in all: no tier, `CHECK_FAST_CMD` stays empty, and the rules of §4 are the whole step. Over it: `tests/slow/` for the files over 30 s and §2's command. | ten minutes by hand or one feature; the rules are text | whether `tsc` sits in the fast tier (the recommendation: yes) and the `tests/slow/` name |
| **n8n-home** | **The kit**: build `templates/project/tests/` in this repo first (one agent-harness milestone, test-first against a throwaway suite as `33-suite-runner.sh`'s `TEST_CHECKS` does), then one n8n-home milestone: copy the kit, its rig boot and teardown into `suite_setup`/`suite_teardown`, `# tier: fast` on the 11 `needs: none` groups and `slow` on the 10 rig groups, the names fixture from one green run, `CHECK_FAST_CMD` and `CHECK_NAMES` in `.harness/config.sh`, `CLAUDE.md` How to verify's `--only` sentence rewritten for `--tier`. The rig stays `n8n-test-<id>` with `-p` (Code rules); nothing touches `/srv/n8n` or `scripts/deploy.sh`. Predicted: a session's gate about 150 s → the none groups' seconds; the rig runs at verify. | one harness milestone (the kit, ~250 lines moved, not written) and one n8n-home milestone | (a) kit or conventions only (the kit replaces `tests/run.sh`'s group loop; the smaller change adds `--tier` and conformance to the runner it has); (b) a names fixture at all: every new check then adds a line, which is the conformance's price; (c) that the n8n-home run is build-only (no deploy), so its live protocol is not entered |

**Order.** pathways' measurement and hit_list's nothing cost no run; the kit is this repo's and can go in the next
agent-harness run; dj and n8n-home are live-staged runs Michael queues with a brief that says *build-only, no deploy*.
Each run's retro reads its `Suite runs` and `Checks` rows against the predictions above.

## Not in this design

A shared test library across languages; Vitest, bun or bats anywhere (`docs/plans/2026-11-03-test-suite-redesign.md` §7);
the resident helper outside this repo (no other project spawns node per question); LLM-chosen tiers or verdicts;
any change to a live system or to another project's files by this session.

## After this spec (Michael)

Read §5's last column and answer each line; paste §2's fakes line and §4's rules into the `CLAUDE.md` files you keep;
queue the kit as an agent-harness run; then dj's night with its profile as the first feature.
