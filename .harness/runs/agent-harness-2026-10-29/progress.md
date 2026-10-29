<!-- harness: rendered from entries.jsonl after every session; edits here are overwritten -->
# Progress — run `agent-harness-2026-10-29` (agent-harness)

What this file is: the run's journal, rendered by the harness, newest entry first. Spec: `docs/specs/2026-10-29-unattended-night.md`. Two milestones in series: **N1** the rerun guard (a red suite is rerun once; a flake is green, named and counted; a real red stays red) and **N2** merge conflicts resolved without you (a sorted merge driver for lists, a resolve session for the rest, the verify gate, then the merge). Feature ids: `N1-01`…`N1-05`, `N2-01`…`N2-06`; `feature_list.json` in this directory holds each one's steps and `passes`. Each entry below says what a session did, what it tried and what it found; a verify entry has one evidence row per step. Steer from your phone: edit `INBOX.md` on this branch (`status: pause` or `status: stop` on line 1; answers under `## Answers`). The harness-log (`harness-log.md`) has the driver's notes: `flaky:` lines and `resolve session` lines are this run's own new behaviour once N1 and N2 land.

### 2026-10-29 01:46 · N1-01 · passes

Wrote docs/plans/2026-10-29-N1-rerun-guard.md: the rerun's place and rules in lib/check.sh (CHECK_RERUN table, never-rerun exits, marker from the first run's total via testcount --total), the HARNESS_FAILED= guard in tests/run.sh, the flakes.jsonl row, flakes_note's sites and lock, summary/report/debrief, every new check name by file, docs.

- **Files:** docs/plans/2026-10-29-N1-rerun-guard.md
- **Verified:** the six headings grep -x present; git diff --stat origin/main...HEAD outside docs/plans and the run dir is empty; check.sh: green (cached, 859 tests)
- **Tests:** 859 → 859
- **Discovery** (affects N1-02): check.sh's find deletes every check-*.out but check-<key>.out after the full run: check-rerun.out must be written after it, and rm'd before the first run
- **Discovery** (affects N1-02): 08-scope-sh's ck() calls check.sh with exit 3 and exit 137 (short of the cap) and greps '— last lines of .../check.out': under auto they rerun; pin HARNESS_CHECK_RERUN=off in ck()
- **Discovery** (affects N1-03): run_init writes tests-start from check.out, which after a rerun-green is the red run (its passes, not the total); take it from the marker first, as tests_end does
- **Discovery** (affects N1-02): a rerun-green with no N/M total leaves an empty marker, and the cached line and tests_end then fall back to check-<key>.out, the red run's count: the plan removes check-<key>.out then
- **Discovery** (affects N1-04): summary.mjs's jsonl() throws on a bad line; flakes.jsonl is appended by lanes at once, so read it tolerantly
- **Proposed change:** N1-03: add a step for run_init's tests-start after a flake (from the marker first) with its check in 74-flakes-run.sh, as the plan's §flakes.jsonl and flakes_note says
- **Proposed change:** N1-02: add 'a kill at the memory cap is never rerun' to step 5 (the plan lists the check) and the 08 ck() pin to HARNESS_CHECK_RERUN=off
- *01-N1-01 · claude-opus-5-5*

### 2026-10-29 01:40 · init · passes

11 features: N1 5 (plan, 3 build, review), N2 6 (plan, 4 build, review); in series, N2 after N1 as the spec asks. First N1-01 (plan), N1-02 (HARNESS_FAILED= and the check.sh rerun), N1-03 (flakes_note and the invariant).

- **Discovery** (affects run): the suite took 604 s at init here (859 checks); each full run inside a feature costs about 10 min, so a build feature runs it twice at most
- **Discovery** (affects run): HARNESS_LANE is not exported anywhere today; N1-02 exports it from lib/lane.sh so flakes.jsonl rows and resolve sessions can name their lane
- **Discovery** (affects run): the stub project's CHECK_CMD (`test ! -f BROKEN`, tests/lib.sh) prints no HARNESS_FAILED= line, so in stub runs CHECK_RERUN=auto reruns the whole suite: the flaky note reads `flaky: whole suite`
- **Discovery** (affects run): scope_run clears <unit>.started and .show before each call, so check.sh can run its rerun through run() with the same unit name
- **Discovery** (affects run): the last run's build features took 25 to 78 min each (the lane-wiring ones the longest); N2-03 and N2-04 are the big ones here and may take two attempts
- *00-init · claude-fable-5-1*
