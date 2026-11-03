# Tiers: a fast tier gates a feature's `passes`, the full suite gates verify and merge (2026-11-03)

**Goal.** Phase 3 of `docs/plans/2026-11-03-test-suite-redesign.md`. The suite is 805 s solo and a coding session runs
it 1.3–1.7 times (58 % of lane time). Split it into a **fast tier** (the unit tier, the short scenario files, every
check that has caught a real regression: about 150 s solo at 4 jobs) and a **slow tier** (the long stub runs). A coding
session iterates on the fast tier and ends on a fast-tier green; **a feature's `passes` stands on that fast-green**;
the full suite runs once per milestone at verify (as today: `run_init fresh`) and before a merge, so the slow tier runs
5–7× less often. Michael chose this gate on 2026-11-03 over keeping the full suite behind `passes` (the plan's question 2).
Two milestones in series: **T1** the runner and the assignment (`tests/` only), **T2** the gate (`check.sh`, the driver,
the prompt).

**Source.** `docs/specs/2026-11-03-test-suite-redesign.md` (Phase 3); `findings-and-research/2026-11-03-redesign-baseline.md`
§1 (per-file slot times: 52 files under 30 s add up to 580 slot-s, 34 files of 33 s or more to 2,604);
`findings-and-research/2026-10-29-run-time-budget.md` §2 (the sessions' suite 58 % of lane time), §4 (1.5–2.1 full runs
per session; the post-session run a cache hit 50 of 54 times), §6 (the guards behind every full run), §7 (85 reds: 35
in the session's own check file, 38 selected by name, 4 missed: `39-memlint-m4` twice); `docs/specs/2026-10-30-suite-time.md`
(the markers `green-<key>`, `red-<key>`, `part-<key>`; the invariant); `decisions/2026-10-26-verify-runs-the-suite`;
`decisions/2026-10-29-rerun-guard`; `lib/check.sh`, `lib/record.sh` (`run_init` line 443, `green` 79, `tests_end` 500),
`lib/lane.sh` (72, 78, 109, 190–192, 319, 364), `lib/driver.sh` (319, 482), `lib/prompt.sh` (`suite_length`),
`prompts/coding.md` (*The suite*, §3), `prompts/parts/run.md`.

**Rules.** `CLAUDE.md` binds: worktree only; never touch real runs or real state; fakes mirror the live API (the stub
suites print `tests/run.sh`'s lines); every behaviour visible in `harness-log.md`, `run.log` or the init output and
checked test-first in `tests/checks/`, names in the fixtures; `bash -n`, `node --check`; one decision file per
behaviour; `docs/architecture.md` and `README.md` in the same milestone. **Proceed on the defaults written here; record
them marked *default*; never park.** The gate stays deterministic: no LLM chooses a tier or a verdict. **The invariant,
restated for two tiers:** a tree is marked **green** (`green-<key>`) only by a green full run of every check that reads
what changed in it; a tree is marked **fast-green** (`fast-<key>`) only by a green run of the whole fast tier on it;
`passes` stands on fast-green; a tag, a verify and a merge stand on green. A fast-green is never read as a green.

## Depends on

- `main` at or after the merge of phase 1 (`docs/specs/2026-11-03-unit-tier.md`: `00-unit-tier.sh` is the fast tier's
  first file) and of run `agent-harness-2026-11-03` (C1: `check-runs.log` rows and `suite_runs` in the metrics row).
- T2 after T1 (the driver calls what T1 built). T1's first feature `after: []`, T2's `["T1"]`.

---

## T1 · The tier of every check file, in the runner

**Choice.**

1. **The header.** Line 2 of every `tests/checks/*.sh` (after the shebang) is `# tier: fast` or `# tier: slow`. The
   runner reads it with `sed -n 2p`. A check file without one is refused: `tests/run.sh` prints `no tier header: <file>`
   and exits 2 before running anything (fail-closed: a file in no tier would be in no gate). `TEST_CHECKS` directories
   (the runner's own stub suites) follow the same rule.
2. **`tests/run.sh --tier fast|slow`** (before any names): only the files of that tier; with names, the files of that
   tier whose names match; without `--tier`, every file as today. `--repeat` combines with it. The `slowest:` line ends
   `, tier <fast|slow|all>`.
3. **Conformance per tier.** `tests/fixtures/check-names.txt` stays the full list. New: `tests/fixtures/check-names-fast.txt`,
   C-sorted, the fast tier's names (a name the unit tier prints is fast). A `--tier fast` run checks **missing, new and
   doubled** against the fast fixture (a deleted fast check must turn the fast run red, since `passes` stands on it); a
   `--tier slow` run against the difference (`comm -23` full fast); a run without `--tier` against the full list as
   today; a subset (names) run new and doubled only, as today. The line: `conformance: every check of the <tier> tier
   ran, none new or doubled` (the existing line for a full run). A fast name absent from the full fixture, or a fast
   fixture name whose file is slow, is a lint failure in the runner's own check (item 5). `HARNESS_FAILED=` is unchanged.
4. **The assignment** (`journal/decisions/2026-11-03-suite-tiers.md`, a table of every file with its tier, its solo slot
   time and the reason). The rule: **fast** = `00-unit-tier` + every file whose solo slot time at 4 jobs was **≤ 30 s** in
   `findings-and-research/2026-10-30-suite-load-curve/lc-4-solo.out` (52 files; the line falls between `81-partial-key`
   29.1 s and `70-overlap` 33.8 s) + every file that caught a real regression outside its own feature in the budget's
   escapes data: `39-memlint-m4` (42 s; the Gotchas cap, twice). **Slow** = the rest (33 files, `15`, `13`, `08`, `76`,
   `46`, `77`, …). The session re-times the fast set solo (`TEST_JOBS=4 bash tests/run.sh --tier fast`, twice) and
   moves out any file over 30 s in both runs, noting it. **Target: the fast tier ≤ 180 s solo at 4 jobs** (predicted
   ~150 s: 580 slot-s over 4 jobs, longest file 42 s).
5. **Who may move a file** (the decision file's rule): a session moves fast → slow when the file's time was over 30 s in
   two solo runs, with the two times in one `Updated in place <date>: …` line of the table; slow → fast only Michael, or
   a session whose spec says so, with a time under 30 s and the file absent from the flaker rows of the last three runs
   (`flakes.jsonl`). A new check file declares its tier by the same 30 s rule; a session that adds a stub run to a fast
   file re-times it. The runner's own check lints the fixtures' consistency (item 3) on every full run.
6. **Measure (T1's last build feature).** `findings-and-research/2026-11-03-suite-tiers.md`: solo wall and user+sys of
   `--tier fast`, `--tier slow` and the full run, each twice, no other suite alive (`harness status`), with the check
   count per tier.

**Checks (written first)**, in `tests/checks/33-suite-runner.sh` with a `TEST_CHECKS` directory of three tiny files
(two `fast`, one `slow`) and its own `check-names.txt` and `check-names-fast.txt`: `--tier fast` runs the two and not
the third (their `tmp:` lines); `--tier slow` the third; `--tier fast <name>` one; a file without a header → exit 2
naming it, nothing run; a fast name missing from the fast run → `FAIL conformance` naming it and no `HARNESS_FAILED=`;
a slow run checks against the difference (a slow name missing → red; a fast name absent from the slow run → not
missing); the lint: a fast fixture name whose file says slow → red naming it; on the real tree: every file has a
header, every fast fixture name is in the full fixture, the fast fixture equals the names the fast files print
(`bash tests/run.sh --tier fast` conformance green); `bash -n tests/run.sh`.

### T1-review

Sized to the milestone: a reader of the runner diff; hardest: the three conformance branches (fast, slow, full) and
that a refused header leaves the runner's exit and output deterministic.

---

## T2 · The gate: `check.sh --fast`, the driver's calls, the prompt

**Choice.**

1. **Config.** `lib/config.sh`: `CHECK_FAST_CMD=""` in the project layer (`templates/project/config.sh` commented: "the
   fast tier; empty: the whole suite is the fast tier"); `prompt_env` exports `HARNESS_CHECK_FAST_CMD`. This repo's
   `.harness/config.sh`: `CHECK_FAST_CMD="bash tests/run.sh --tier fast"`. No other project sets it: **for them nothing
   changes** (below).
2. **`lib/check.sh --fast`.** With `HARNESS_CHECK_FAST_CMD` empty, `--fast` is the full form, byte for byte (the same
   markers, lines and rows): a one-tier project's `passes` still stands on its whole suite. With it set, in order:
   `green-<key>` present → the cached green line as today (a full green satisfies the fast gate); `red-<key>` present →
   the cached RED as today (a full red stands); `fast-<key>` present → `check: fast green (cached for this code tree,
   N tests)`, row `cached`, exit 0; else the fast run: `run()` of `CHECK_FAST_CMD` (the same scope, cap and
   `HARNESS_CHECK_TIMEOUT`) to `check-fast.out`, the rerun guard as for a full run (`HARNESS_FAILED=` names, else the
   fast tier again; a flake row gains `"tier": "fast"`), then green → `fast-<key>` two lines (`<n> tests` of the fast
   run, `wall <s>`), `check: fast green in <s> s, N tests` (after a rerun: `check: fast green after a rerun (flaky:
   <names>), N tests`), row `fast`, exit 0; red → `check: RED (fast: exit <rc> after <s> s[; red again on a rerun of …])
   — last lines of check-fast.out:` and the tail, **no marker** (*default:* a fast red is 150 s; the red marker is for a
   900 s run), row `fast`, exit as the run did. A timeout or cap kill: as the full form says it, no rerun, no marker.
   The partial path (`CHECK_KEY_MAP`, `part-<key>`) belongs to the full form only; `--fast` never reads the map. The
   subset form is unchanged. `check.out` and `check-<key>.out` stay the last **full** run's (every count the driver
   reads from them is a full run's).
3. **The driver.** `run_init` (`lib/record.sh`) takes a mode: `run_init fast` calls `check.sh --fast`; bare `run_init`
   and `run_init fresh` call the full form as today. The run's first init (`lib/driver.sh` line 482: `tests-start`, the
   baseline) stays full. **A coding session's pre-session init (`lib/lane.sh` 319) becomes `run_init fast`**, and the
   post-session gate (`lib/lane.sh` 364) becomes `green_fast` (`"$CHECK" --fast`): the note on a red is
   `<id> un-passed: fast tier red after the session`. The verify's `run_init fresh` (72) and `green` after a hold (109),
   the re-base's `run_init fresh` + `green` (190–192) and the driver's final `green` (319) stay full. `run_init fresh`
   removes `fast-<key>` with the other three markers. `tests_end` and `run_init`'s `tests-start` read **full** markers
   only (never `fast-<key>`): the counts in the record are the whole suite's. `tests-start` is set by the first full run
   as today.
4. **The prompt.** `prompts/parts/run.md`'s Suite line: `Suite: \`{{CHECK}}\` (full: runs \`{{CHECK_CMD}}\`; fast tier:
   \`{{CHECK}} --fast\` runs \`{{CHECK_FAST_CMD}}\`; cached per code tree; last full run {{SUITE_LENGTH}}; last fast run
   {{SUITE_FAST_LENGTH}})` where `suite_length` (`lib/prompt.sh`) also reads the newest `fast-<key>`'s wall (`<s> s`, or
   `not measured yet`); a project without a fast command renders the line as today. `prompts/coding.md`, *The suite*:
   "The suite has two tiers. While iterating, run the fast tier (`<suite> --fast`) or a subset (`<suite> <args>`). Before
   you flip `passes`, run the fast tier once, last, after your final edit of any file: your feature passes on that
   green. The full suite runs at verify on the milestone's tree; **if your change touches the driver's scenario paths
   (`lib/driver.sh`, `lib/lane.sh`, `lib/record.sh`, `bin/harness`) or a slow-tier check file, also run that file
   (`<suite> <file>`) before you end**: a slow red at verify costs the milestone a fix session." The timeout rule stays
   (the fast tier's twice-the-wall is a foreground call). §3's order (Gotchas line before the suite) stays. The
   initializer's and verify's prompts say which tier the harness ran for them (`parts/run.md` carries the line; the
   init output shows `fast green` or `green`).
5. **Visible.** `init.out` carries the fast line (the prompt's *Init output*); `run.log` and `harness-log.md`: the
   un-pass note above; `<id>: suite ran <n>x (<s> s) in the session` counts fast rows as runs (the row kind is in
   `check-runs.log`); `metrics.jsonl`'s `suite_full` counts full rows only (unchanged), and a new `suite_fast` beside it;
   `summary.mjs suiteRuns` adds `fast` and the report's `Suite runs` row reads `0.2 full and 1.6 fast per coding
   session (…)`. The verify's `red on the verified tree` line is unchanged and is the measure of the gate's cost.
6. **Decision and docs.** `journal/decisions/2026-11-03-fast-gate.md` (finding · choice with every default · rejected:
   the full suite behind `passes` (Michael's question 2, option a: safer, 0.3–0.7 full runs per session saved only); an
   LLM-chosen tier or subset; a per-feature file subset (budget §7: 73 % of the files); a fast red marker; `--fast` as
   the bare default (every existing caller and check reads the bare form as full)). `docs/architecture.md` §3 (`check.sh`
   `--fast`, `run_init fast`, `green_fast`), §4 (*Suite cache*: `fast-<key>`, `check-fast.out`), §7 (the guard table:
   the two gates, one row each), §10 (`CHECK_FAST_CMD`); `README.md` (the tier rule, `CHECK_FAST_CMD`, the report row);
   `templates/project/config.sh`; `CLAUDE.md` *How to verify*: the two commands a session runs and when (the mechanism
   changed; the sentence is the mechanism's).

**Checks (written first)**, in a new `tests/checks/NN-fast-gate.sh` with the stub suite of `73-check-rerun.sh` (a
counter, a mode and the arguments logged) and a throwaway repo: `check.sh --fast` with no fast command → the stub called
with no arguments, `green-<key>` written, the cached line next call (byte for byte the full form); with
`HARNESS_CHECK_FAST_CMD=<stub> --tier fast`: the stub called with `--tier fast`, `fast-<key>` two lines, `check: fast
green in <s> s, N tests`, row `fast`; the next call `cached` without a run; a planted `green-<key>` → the full cached
line and no run; a planted `red-<key>` → the cached RED, exit 1, no run; a fast red twice (`HARNESS_FAILED=a`) → one
rerun of `a`, `check: RED (fast: …; red again on a rerun of a)`, exit 1, no marker of any kind; red then green → a
flake row with `"tier":"fast"` and the fast green line; a timeout (`HARNESS_CHECK_TIMEOUT=2s`) → no rerun, no marker;
`--fast` never reads `part-<key>` (a planted sidecar and a mapped-path diff → the fast tier runs, not the partial); a
subset call unchanged. **The stub run** (`STUB_*` modes as `34-check-key.sh`'s): the coding session's `init.out` has
`fast green`, the stub suite's argument log shows `--tier fast` before and after the session and no bare call between;
the session's prompt carries the tier rule and both lengths; with the stub's slow tier red (a mode: the bare call red,
`--tier fast` green) the feature **passes** after the session (`passes=true` note, no un-pass), and the verify's
`run_init fresh` runs the full suite, goes red, and today's `red on the verified tree` path fires (the note, the needs
record); `tests-end` is the full count; `run_init fresh` removed a planted `fast-<key>`; a fast red after the session
→ `un-passed: fast tier red after the session`; `metrics.jsonl`'s coding row has `suite_fast`; `harness report --md`
prints the new `Suite runs` row; `prompts/coding.md` has `run the fast tier once, last`; `bash -n` on every `lib/*.sh`
touched, `node --check` on `summary.mjs`, `metrics.mjs`.

### T2-review

Sized to the milestone: an Opus reader of the diff; hardest: every branch of `check.sh --fast` falling through to the
right marker (a fast-green must never be written as, or read as, a green), the three `run_init` modes at their call
sites, `tests_end` reading full markers only, and the stub run's verify path on a slow red.

---

## Milestones

| M | Contents | After |
|---|---|---|
| T1 | the tier header and its refusal; `--tier`; the fast fixture and per-tier conformance; the lint; the assignment table and the 30 s rule; the tier timings; `2026-11-03-suite-tiers`; T1-review | `[]` |
| T2 | `CHECK_FAST_CMD`; `check.sh --fast` and `fast-<key>`; `run_init fast`, `green_fast`, the lane's two calls; `tests_end` full only; the prompt and `parts/run.md`; `suite_fast` and the report row; docs; `2026-11-03-fast-gate`; T2-review | `["T1"]` |

Plan each as three to five features, the last the review feature. The suite ends green at every milestone.

## Predictions (for the retro and the supervisor; against `findings-and-research/2026-11-03-redesign-baseline.md` and budget §11)

| Measure | now | after T1 + T2 (the next real run on this repo) |
|---|---|---|
| fast tier solo wall at 4 jobs | – | **≤ 180 s** (predicted ~150 s), 560–620 checks |
| full suite solo wall | 804 s | unchanged (the tiers reorder nothing) |
| time-to-signal for a coding session's last run | 805 s (a full run) | **≤ 180 s** |
| full runs per coding session (`Suite runs`) | 1.3 (10-30) | **≤ 0.2** (a session that follows the driver-path rule) |
| fast runs per coding session | – | 1.5–2.5 |
| sessions' suite share of lane time | 58 % (budget §11) | **20–30 %** |
| suite wall per 20 coding sessions, every caller | 29,511 lane-s | **12,000–16,000** |
| `red on the verified tree` per milestone | 0 (four runs) | **≤ 1** |
| un-passes `fast tier red after the session` per 20 sessions | – | 0–2 |
| main green after milestone merges | 100 % | 100 % |

Falsifiers: a feature merged with a check that reads its change never run (the invariant: a fast-green read as a
green); a verify red more than once per milestone (the fast tier is too small: move the catching file in); a fast tier
over 180 s (a file grew: the 30 s rule); sessions still running the full suite (a prompt problem: the rule's wording).

## Not in this run

The resident helper (phase 2); trimming or moving checks between files (phase 4); `TEST_JOBS`; any `lib/lane.sh` verify
path change beyond `run_init fast` at the pre-session init and `green_fast` after the session; the partial map's
semantics; dj, hit_list, pathways, n8n-home (they get `--fast` = full behaviour, nothing to configure).

## After the run (Michael)

- Nothing to configure for other projects; this repo's `CHECK_FAST_CMD` is in the run. A project with a slow suite can
  set `CHECK_FAST_CMD` to a marker-selected subset (`pytest -m "not slow"`, `jest --selectProjects fast`) when it has one.
- The morning after the next real run on this repo: `harness report <run>` (the `Suite runs` row), `grep -c 'red on
  the verified tree' <run dir>/harness-log.md`, and `budget.mjs` over the run for the share, against the table.
