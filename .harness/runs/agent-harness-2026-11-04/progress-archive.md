<!-- harness: rendered from entries.jsonl after every session; edits here are overwritten -->
# Progress — run `agent-harness-2026-11-04` (agent-harness)

What this file is: the run's journal, newest entry first, rendered by the harness from `entries.jsonl` for Michael's phone. Each entry is one session (init, coding, verify, review, retro) with its outcome, summary and questions.

The run: phase 3 of `docs/plans/2026-11-03-test-suite-redesign.md`, spec `docs/specs/2026-11-03-suite-tiers.md`. T1 (4 features) splits `tests/run.sh` into a fast and a slow tier (`# tier:` on line 2 of every check file, `--tier fast|slow`, `tests/fixtures/check-names-fast.txt`, the 30 s rule in `journal/decisions/2026-11-03-suite-tiers.md`, the six timed runs in `findings-and-research/2026-11-03-suite-tiers.md`). T2 (4 features, after T1) builds the gate: `lib/check.sh --fast` with `CHECK_FAST_CMD` and a `fast-<key>` marker, the driver's `run_init fast` before and `green_fast` after each coding session, `suite_fast` in the metrics and the report, the prompts' two-tier rule, docs. The gate: `passes` stands on a fast-tier green; verify and merge stand on the full suite; a fast-green is never read as a green.

How to read the feature list (`feature_list.json`): array order is priority; `after` names what a feature waits on; `passes` flips when a session's fast tier (T1: the full suite) is green and the verifier agrees per milestone. Steer via `INBOX.md` on this branch: line 1 `status: pause|stop`, answers under `## Answers`.

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
