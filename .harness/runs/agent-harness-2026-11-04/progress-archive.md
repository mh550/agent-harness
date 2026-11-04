<!-- harness: rendered from entries.jsonl after every session; edits here are overwritten -->
# Progress — run `agent-harness-2026-11-04` (agent-harness)

What this file is: the run's journal, newest entry first, rendered by the harness from `entries.jsonl` for Michael's phone. Each entry is one session (init, coding, verify, review, retro) with its outcome, summary and questions.

The run: phase 3 of `docs/plans/2026-11-03-test-suite-redesign.md`, spec `docs/specs/2026-11-03-suite-tiers.md`. T1 (4 features) splits `tests/run.sh` into a fast and a slow tier (`# tier:` on line 2 of every check file, `--tier fast|slow`, `tests/fixtures/check-names-fast.txt`, the 30 s rule in `journal/decisions/2026-11-03-suite-tiers.md`, the six timed runs in `findings-and-research/2026-11-03-suite-tiers.md`). T2 (4 features, after T1) builds the gate: `lib/check.sh --fast` with `CHECK_FAST_CMD` and a `fast-<key>` marker, the driver's `run_init fast` before and `green_fast` after each coding session, `suite_fast` in the metrics and the report, the prompts' two-tier rule, docs. The gate: `passes` stands on a fast-tier green; verify and merge stand on the full suite; a fast-green is never read as a green.

How to read the feature list (`feature_list.json`): array order is priority; `after` names what a feature waits on; `passes` flips when a session's fast tier (T1: the full suite) is green and the verifier agrees per milestone. Steer via `INBOX.md` on this branch: line 1 `status: pause|stop`, answers under `## Answers`.

### 2026-11-04 03:52 · T1-04 · passes

Review of T1: 0 Critical, 1 Important, 6 Minor. Fixed: a full run now holds check-names-fast.txt to what the fast files print (both ways); exact line-2 read, non-file *.sh refused quietly, strict option parsing, true fixture paths in hints; one header loop. README, architecture, CLAUDE.md carry --tier.

- **Files:** tests/run.sh, tests/checks/33-suite-runner.sh, tests/fixtures/check-names.txt, journal/decisions/2026-11-03-suite-tiers.md, README.md, docs/architecture.md, CLAUDE.md
- **Verified:** Red→green pairs in 33-suite-runner (bash tests/run.sh 33-suite: 39/44 red before run.sh change, 44/44 after): Important → 'tier conformance: a full run fails on a fast file's name absent from the fast fixture and a fast-fixture name no fast file printed'; Minor 4 → 'a new name's hint names the fixture the run compared' (+ sf-rerun check updated); Minor 5 → 'tiers: --tier after a name, twice, or as --tier=<t> prints the usage'; Minors 2/3 → 'tiers: line 2 is read exactly … directory named *.sh'; Minor 7 → 'tiers: bash -n tests/run.sh passes'. Refusal check extended to 'nothing run or written' (empty TMPDIR), proved by a mutation (mktemp before the refusal) turning it red. Full suite via check.sh: green in 804 s, 1186 tests.
- **Tests:** 1181 → 1186
- **Discovery** (affects T2-01, T2-02, run): tests/run.sh's full run is red when a fast file prints a name absent from check-names-fast.txt, or a fast-fixture name comes only from a slow file: moving a file's tier means moving its names in the same commit
- **Discovery** (affects T2-01, T2-02): run.sh now rejects any --option after a name (usage, exit 2) and a second --tier; T2's check.sh --fast must pass --tier fast before names
- **Proposed change:** README.md's Tests block still says '395 checks (~3 min 30 s)' for a full run; it is 1186 checks and about 13 min 30 s now (left: outside this feature's scope).
- *04-T1-04 · claude-opus-5-5*

### 2026-11-04 03:29 · T1-03 · passes

Timed six solo runs at TEST_JOBS=4: fast 152.8/151.5 s (537 checks), slow 670.7/659.7 s (645), full 809.9/794.1 s (1181); all green. Fast target of 180 s met. Findings in findings-and-research/2026-11-03-suite-tiers.md.

- **Files:** findings-and-research/2026-11-03-suite-tiers.md
- **Verified:** six runs each ended N/M checks passed with 0 FAIL lines; harness status showed only this run before the first run; no code changed, the two full runs are the suite run
- **Tests:** 1181 → 1181
- **Discovery** (affects T1-04, T2-02): Fast tier files over 30 s in both runs: 39-memlint-m4 (41.5/41.2 s, spec exception) and 84-node-memo (31.5/31.5 s): 84 moves to slow at the next re-timing; fast has 537 checks, below the spec's 560-620 estimate
- *03-T1-03 · claude-sonnet-5-5*

### 2026-11-04 02:34 · T1-02 · passes

tests/run.sh checks a --tier fast run against tests/fixtures/check-names-fast.txt (536 names) and --tier slow against full minus fast; 33-suite-runner gains 6 tier-conformance checks and a 4-check fixture lint. Re-timed solo twice: 33-suite-runner over 30 s both times, so it moved to slow; 39-memlint-m4 stays fast by the spec's exception (*default*).

- **Files:** tests/run.sh, tests/checks/33-suite-runner.sh, tests/fixtures/check-names.txt, tests/fixtures/check-names-fast.txt, journal/decisions/2026-11-03-suite-tiers.md, CLAUDE.md
- **Verified:** Red first: bash tests/run.sh 33-suite gave 32/39 before the runner change (the fast/slow conformance checks and lint red), 39/39 after. Re-timing, both after harness status showed RUNNING 1 (this run), QUEUED 0: TEST_JOBS=4 bash tests/run.sh --tier fast walls 161.9 s and 161.1 s (365.0+219.4 and 363.7+219.5 user+sys). Over 30 s in both: 33-suite-runner 51.7/51.7 (moved to slow), 39-memlint-m4 39.8/39.6 (kept). After the move, on the final tree: --tier fast 537/537 in 151.6 s with PASS conformance: every check of the fast tier ran; --tier slow 645/645 in 684.6 s with the slow tier's PASS line. comm -23 fast full is empty; every name bash tests/run.sh 00-unit prints is in the fast fixture. Full suite: lib/check.sh green in 809 s, 1181 tests.
- **Tests:** 1171 → 1181
- **Dead end:** a first Gotchas edit of 203, then 167 characters — over the 160 cap; memlint doesn't enforce the length, so nothing turns red: count it with ${#l}
- **Discovery** (affects T1-03, T1-04, T2-01): 33-suite-runner is slow now (51.7 s solo, 25.5 in lc-4-solo.out): its TEST_FILE_TIMEOUT fixtures (rt, sa-se, sf) each wait out run.sh's hardcoded 10 s KILL grace; the tier lint runs only in slow and full runs
- **Discovery** (affects T1-03, T1-04): 84-node-memo is at the 30 s line: 29.1 and 28.2 s in the two re-timings, then 31.5, 30.3 and 31.3 s in three later fast runs; the next re-timing will likely move it
- **Discovery** (affects T1-03, T2-02): The fast tier is now 54 files, 536 names + its conformance line (537 checks), about 151 s solo at 4 jobs; the slow tier 34 files, 645 checks, 684.6 s
- **Discovery** (affects T2-01): A --tier names subset checks new and doubled against its tier's list (--tier fast <f>: the fast fixture), so check.sh --fast's rerun (T2-01: --tier fast <files>) is checked against the fast fixture
- **Discovery** (affects T1-04): The tier lint (tierlint in 33-suite-runner.sh) maps a name to files by grep -F on their source: 1,134 of 1,170 names are literal; one built at run time is told only by the fast run's own conformance
- **Question for Michael:** 39-memlint-m4 was over 30 s in both re-timings (39.8 s, 39.6 s). I kept it fast (*default*) because the spec names it fast by exception, not by the 30 s line. Keep it fast, or move it to slow? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-04/slot-0/journal/decisions/2026-11-03-suite-tiers.md
- **Proposed change:** T1-02 step 6 assumes 33-suite-runner stays fast; it moved to slow by step 5, so its names are only in check-names.txt and the lint runs in slow and full runs.
- **Proposed change:** T1-04 or phase 4: a TEST_KILL_GRACE knob (default 10 s) would let 33-suite-runner's timeout fixtures use 1 s and bring it back under 30 s
- *02-T1-02 · claude-opus-5-5*

### 2026-11-04 01:43 · T1-01 · passes

tests/run.sh reads line 2 of every check file (`# tier: fast|slow`), refuses a headerless one (`no tier header: <path>` per file, exit 2, nothing run), and gains `--tier fast|slow` (with names, with --repeat; slowest: line ends `, tier <t>`). 55 files fast, 33 slow by the 30 s rule; table and rule in journal/decisions/2026-11-03-suite-tiers.md.

- **Files:** tests/run.sh, tests/checks/33-suite-runner.sh, tests/checks/75-suite-tools.sh, tests/checks/*.sh (line 2 header), tests/fixtures/check-names.txt, journal/decisions/2026-11-03-suite-tiers.md
- **Verified:** 33-suite-runner red before the runner change (8 FAIL: 6 new tiers checks + the two slowest-line regexes now ending `, tier all`), 28/28 + conformance after; 75-suite 82-key 84-node 85-suite 53/53; full suite via check.sh: check: green in 805 s, 1171 tests (1171/1171, wall 805.2 s). Untimed files timed alone at TEST_JOBS=4 after harness status showed only this run: 83-spec-must-exist 18.3 s, 84-node-memo 27.6 s, 85-suite-runs 13.2 s, all fast.
- **Tests:** 1165 → 1171
- **Dead end:** a Gotchas line for the tier header — the section already held 15 lines: 39-memlint-m4 went red (gotchas: 16 lines, over 15); dropped it, since the runner's own refusal message names the fix
- **Discovery** (affects T1-02): Until T1-02 a --tier run's conformance is a subset's (none new or doubled): `(( $# )) || [[ -n $tier ]]` in tests/run.sh; T1-02 replaces that branch with the per-tier fixture checks.
- **Discovery** (affects T1-02, T1-04, T2-01, T2-02): The refusal looks at every *.sh in the directory, not only the selected files: a subset or --tier run is refused too. 33-suite-runner.sh's tiny fixture files use `tiny <file> <line>…` (TIER=slow for slow), which writes the shebang and header.
- **Discovery** (affects T1-02, T1-03): 84-node-memo timed 27.6 s alone, the closest fast file to the 30 s line: T1-02's solo re-timings should watch it, and 39-memlint-m4 (fast by the spec at 42.1 s) took 35.7 s in check.sh's rerun.
- **Discovery** (affects run): CLAUDE.md's ## Gotchas is at its 15-line cap: 39-memlint-m4 fails a 16th line; a session adding one must replace one.
- **Proposed change:** T1-04 step 4's CLAUDE.md How to verify sentence is where the line-2 header rule belongs (the Gotchas section is full).
- *01-T1-01 · claude-opus-5-5*

### 2026-11-04 01:06 · init · passes

8 features: T1 4 (runner header and --tier, fast fixture and per-tier conformance with the solo re-timing, the six timed runs, review), T2 4 (check.sh --fast and CHECK_FAST_CMD, the driver's run_init fast and green_fast with the stub run, metrics/report/prompt, review). T2-01 after T1. Spec defaults taken; nothing parked.

- **Files:** .harness/runs/agent-harness-2026-11-04/feature_list.json
- **Verified:** node lib/features.mjs lint on the list prints nothing; node lib/entries.mjs validate on this entry prints nothing; the harness's own full run before init was green (787 s).
- **Discovery** (affects run): tests/checks/ holds four files findings-and-research/2026-10-30-suite-load-curve/lc-4-solo.out never timed: 00-unit-tier (fast by the spec's rule), 83-spec-must-exist, 84-node-memo, 85-suite-runs (T1-01 times each once and places it by the 30 s line); that output's 01-scheduler-pure and 02-notifications-pure rows now live inside 00-unit-tier (phase 1).
- **Discovery** (affects run): The stub project's suite is `CHECK_CMD="test ! -f BROKEN"` (tests/lib.sh suite_setup): T2-02's stub run writes its own argument-logging suite script and CHECK_FAST_CMD into $T/proj/.harness/config.sh, as 34-check-key.sh writes its config. TEST_CHECKS directories exist only in 33-suite-runner.sh and 75-suite-tools.sh: those tiny files need tier headers too.
- **Discovery** (affects run): 86 and 87 are the next free check-file numbers. The spec's one NN-fast-gate.sh is planned as two files: 86-fast-gate.sh (fast tier: the check.sh --fast cases with 73-check-rerun's stub suite) and 87-fast-gate-run.sh (the stub harness run; its tier by the 30 s rule, likely slow), so the check.sh cases stay in the fast tier.
- **Discovery** (affects run): This run's init.out (/tmp/harness/agent-harness/agent-harness-2026-11-04/init.out) has every check file's time from the harness's full 4-job run: a first look at the tier line, not a solo time; the solo times are lc-4-solo.out's and T1-02's two re-timings.
- **Discovery** (affects run): harness status at init: RUNNING 1 (this run), QUEUED 0; T1-02's re-timing and T1-03's six runs re-check it first (the brief: no other suite alive).
- **Question for Michael:** The spec names one check file `NN-fast-gate.sh` for T2; the list plans two (86-fast-gate.sh, fast tier, the check.sh cases; 87-fast-gate-run.sh, the stub run, tier by the 30 s rule) so the check.sh cases run in the fast tier. Default taken: two files. Say so in INBOX.md if you want one. Files: /home/mh550/worktrees/agent-harness/agent-harness-2026-11-04/docs/specs/2026-11-03-suite-tiers.md:170, /home/mh550/worktrees/agent-harness/agent-harness-2026-11-04/.harness/runs/agent-harness-2026-11-04/feature_list.json
- *00-init · claude-fable-5-1*
