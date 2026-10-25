<!-- harness: rendered from entries.jsonl after every session; edits here are overwritten -->
# Progress — run `agent-harness-2026-10-25-lifecycle` (agent-harness)

What this file is: the run's journal, rendered from `entries.jsonl` after every session, newest entry first (the full record is `progress-archive.md`; the driver's own notes are `harness-log.md`). Each entry says what one session did, what passed, what it found (discoveries) and what it needs from you (questions).

The spec is `docs/specs/2026-10-25-resource-lifecycle.md`: everything a run starts is capped by a systemd user scope and stopped when the run stops. Milestones: L1 capped sessions and suites · L2 run services, teardown hook, stop points · L3 scratch and tmux cleanup · L4 `harness gc` fixes (`--all-merged`, R9, `--deps`, the runner's gc) · L5 `MAX_PARALLEL_RUNS` reload (optional, last). L2 waits for L1; L3, L4 and L5 are independent, so a stuck feature in one never blocks the others. Each verified milestone merges into `main` by itself.

How to read the feature list: `feature_list.json` lists features in priority order; `passes` is the session's claim, the verify entry for a milestone is what counts. Steps are the checks a verifier re-runs. A build feature writes its decision file under `journal/decisions/`, its checks in `tests/run.sh` first, and its `docs/architecture.md` and `README.md` lines.

To steer: edit `INBOX.md` on this branch (GitHub app). Line 1 `status: pause` or `status: stop` takes effect before the next session; answers go under `## Answers`. Sessions never park on this run (the brief): they take the spec's default and record it in the decision file, so the questions below are for after the run.

### 2026-10-25 19:37 · verify L2 · passes

Suite 289/289 green. All six L2 features hold: scope+timeout init, teardown hook and services_down on every stop point, gc orphan units, status MemoryCurrent, review fixes and docs checked against named tests.

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| L2-01 | 1 | read step, ran bash tests/run.sh (289/289), grepped named checks/docs/files | plan docs/plans/2026-10-25-L2-run-services.md present; fixtures present; suite green | yes |
| L2-01 | 2 | read step, ran bash tests/run.sh (289/289), grepped named checks/docs/files | plan docs/plans/2026-10-25-L2-run-services.md present; fixtures present; suite green | yes |
| L2-01 | 3 | read step, ran bash tests/run.sh (289/289), grepped named checks/docs/files | plan docs/plans/2026-10-25-L2-run-services.md present; fixtures present; suite green | yes |
| L2-01 | 4 | read step, ran bash tests/run.sh (289/289), grepped named checks/docs/files | plan docs/plans/2026-10-25-L2-run-services.md present; fixtures present; suite green | yes |
| L2-01 | 5 | read step, ran bash tests/run.sh (289/289), grepped named checks/docs/files | plan docs/plans/2026-10-25-L2-run-services.md present; fixtures present; suite green | yes |
| L2-02 | 1 | read step, ran bash tests/run.sh (289/289), grepped named checks/docs/files | config defaults, check at run_init stop-then-systemd-run at tests/run.sh:637, STUB_NO_SYSTEMD bare check :633, decision file exists | yes |
| L2-02 | 2 | read step, ran bash tests/run.sh (289/289), grepped named checks/docs/files | config defaults, check at run_init stop-then-systemd-run at tests/run.sh:637, STUB_NO_SYSTEMD bare check :633, decision file exists | yes |
| L2-02 | 3 | read step, ran bash tests/run.sh (289/289), grepped named checks/docs/files | config defaults, check at run_init stop-then-systemd-run at tests/run.sh:637, STUB_NO_SYSTEMD bare check :633, decision file exists | yes |
| L2-02 | 4 | read step, ran bash tests/run.sh (289/289), grepped named checks/docs/files | config defaults, check at run_init stop-then-systemd-run at tests/run.sh:637, STUB_NO_SYSTEMD bare check :633, decision file exists | yes |
| L2-02 | 5 | read step, ran bash tests/run.sh (289/289), grepped named checks/docs/files | config defaults, check at run_init stop-then-systemd-run at tests/run.sh:637, STUB_NO_SYSTEMD bare check :633, decision file exists | yes |
| L2-02 | 6 | read step, ran bash tests/run.sh (289/289), grepped named checks/docs/files | config defaults, check at run_init stop-then-systemd-run at tests/run.sh:637, STUB_NO_SYSTEMD bare check :633, decision file exists | yes |
| L2-03 | 1 | read step, ran bash tests/run.sh (289/289), grepped named checks/docs/files | services_down in driver.sh:62; checks :646 (marker, stop after, one note), :662-666 (TERM -> driver exited, ended), template+README, decision file | yes |
| L2-03 | 2 | read step, ran bash tests/run.sh (289/289), grepped named checks/docs/files | services_down in driver.sh:62; checks :646 (marker, stop after, one note), :662-666 (TERM -> driver exited, ended), template+README, decision file | yes |
| L2-03 | 3 | read step, ran bash tests/run.sh (289/289), grepped named checks/docs/files | services_down in driver.sh:62; checks :646 (marker, stop after, one note), :662-666 (TERM -> driver exited, ended), template+README, decision file | yes |
| L2-03 | 4 | read step, ran bash tests/run.sh (289/289), grepped named checks/docs/files | services_down in driver.sh:62; checks :646 (marker, stop after, one note), :662-666 (TERM -> driver exited, ended), template+README, decision file | yes |
| L2-03 | 5 | read step, ran bash tests/run.sh (289/289), grepped named checks/docs/files | services_down in driver.sh:62; checks :646 (marker, stop after, one note), :662-666 (TERM -> driver exited, ended), template+README, decision file | yes |
| L2-03 | 6 | read step, ran bash tests/run.sh (289/289), grepped named checks/docs/files | services_down in driver.sh:62; checks :646 (marker, stop after, one note), :662-666 (TERM -> driver exited, ended), template+README, decision file | yes |
| L2-03 | 7 | read step, ran bash tests/run.sh (289/289), grepped named checks/docs/files | services_down in driver.sh:62; checks :646 (marker, stop after, one note), :662-666 (TERM -> driver exited, ended), template+README, decision file | yes |
| L2-04 | 1 | read step, ran bash tests/run.sh (289/289), grepped named checks/docs/files | SVC_IDLE_STOP_MIN default; checks paused :688, stoppy :785, 11/9 min :820-825, memory wait :704; architecture §5/§7 + decision file | yes |
| L2-04 | 2 | read step, ran bash tests/run.sh (289/289), grepped named checks/docs/files | SVC_IDLE_STOP_MIN default; checks paused :688, stoppy :785, 11/9 min :820-825, memory wait :704; architecture §5/§7 + decision file | yes |
| L2-04 | 3 | read step, ran bash tests/run.sh (289/289), grepped named checks/docs/files | SVC_IDLE_STOP_MIN default; checks paused :688, stoppy :785, 11/9 min :820-825, memory wait :704; architecture §5/§7 + decision file | yes |
| L2-04 | 4 | read step, ran bash tests/run.sh (289/289), grepped named checks/docs/files | SVC_IDLE_STOP_MIN default; checks paused :688, stoppy :785, 11/9 min :820-825, memory wait :704; architecture §5/§7 + decision file | yes |
| L2-04 | 5 | read step, ran bash tests/run.sh (289/289), grepped named checks/docs/files | SVC_IDLE_STOP_MIN default; checks paused :688, stoppy :785, 11/9 min :820-825, memory wait :704; architecture §5/§7 + decision file | yes |
| L2-04 | 6 | read step, ran bash tests/run.sh (289/289), grepped named checks/docs/files | SVC_IDLE_STOP_MIN default; checks paused :688, stoppy :785, 11/9 min :820-825, memory wait :704; architecture §5/§7 + decision file | yes |
| L2-04 | 7 | read step, ran bash tests/run.sh (289/289), grepped named checks/docs/files | SVC_IDLE_STOP_MIN default; checks paused :688, stoppy :785, 11/9 min :820-825, memory wait :704; architecture §5/§7 + decision file | yes |
| L2-05 | 1 | read step, ran bash tests/run.sh (289/289), grepped named checks/docs/files | gc checks :765-771 (would:, ? unmatched, stops), status MemoryCurrent :657; docs, README, decision file | yes |
| L2-05 | 2 | read step, ran bash tests/run.sh (289/289), grepped named checks/docs/files | gc checks :765-771 (would:, ? unmatched, stops), status MemoryCurrent :657; docs, README, decision file | yes |
| L2-05 | 3 | read step, ran bash tests/run.sh (289/289), grepped named checks/docs/files | gc checks :765-771 (would:, ? unmatched, stops), status MemoryCurrent :657; docs, README, decision file | yes |
| L2-05 | 4 | read step, ran bash tests/run.sh (289/289), grepped named checks/docs/files | gc checks :765-771 (would:, ? unmatched, stops), status MemoryCurrent :657; docs, README, decision file | yes |
| L2-05 | 5 | read step, ran bash tests/run.sh (289/289), grepped named checks/docs/files | gc checks :765-771 (would:, ? unmatched, stops), status MemoryCurrent :657; docs, README, decision file | yes |
| L2-06 | 1 | read step, ran bash tests/run.sh (289/289), grepped named checks/docs/files | review doc has severities; RED->GREEN checks for Important findings; one-note check :646; §10/§14 docs; bash -n ok | yes |
| L2-06 | 2 | read step, ran bash tests/run.sh (289/289), grepped named checks/docs/files | review doc has severities; RED->GREEN checks for Important findings; one-note check :646; §10/§14 docs; bash -n ok | yes |
| L2-06 | 3 | read step, ran bash tests/run.sh (289/289), grepped named checks/docs/files | review doc has severities; RED->GREEN checks for Important findings; one-note check :646; §10/§14 docs; bash -n ok | yes |
| L2-06 | 4 | read step, ran bash tests/run.sh (289/289), grepped named checks/docs/files | review doc has severities; RED->GREEN checks for Important findings; one-note check :646; §10/§14 docs; bash -n ok | yes |
| L2-06 | 5 | read step, ran bash tests/run.sh (289/289), grepped named checks/docs/files | review doc has severities; RED->GREEN checks for Important findings; one-note check :646; §10/§14 docs; bash -n ok | yes |

- *192902-verify-L2 · claude-sonnet-5-5*

### 2026-10-25 19:28 · L2-06 · passes

Opus review of the L2 diff (docs/plans/2026-10-25-L2-review.md: 2 Important, 8 Minor). Fixed: a TERM mid-init stops the init before the teardown; a TERM mid-teardown waits for it, no second; .harness/teardown.sh looked up at each stop point, not at load_config; the trap commits its note; template runnable by hand; docs. 4 new checks RED→GREEN.

- **Files:** lib/driver.sh, lib/config.sh, tests/run.sh, tests/stub-claude.sh, templates/project/teardown.sh, docs/architecture.md, README.md, journal/decisions/2026-10-25-teardown-hook.md, docs/plans/2026-10-25-L2-review.md
- **Verified:** lib/check.sh green twice (289/289); RED runs: 285/289 (the 4 new checks failing), the hook-lookup check re-proved alone 288/289 with HEAD's config.sh; bash -n on every touched shell file, node --check lib/*.mjs; template run by hand (My.Run → harness-my-run, unset id → message, exit 1)
- **Tests:** 285 → 289
- **Dead end:** STUB_SLOW_INIT as the init command's knob — stub-claude.sh already uses it to slow the initializer session; renamed STUB_SLOW_INITCMD
- **Dead end:** sd_at (first stop) to prove a stop before the trap's teardown — run_init's own stop-first matched; the check counts svc stops before the hook (sd_before == 2)
- **Discovery** (affects L4, run): Deferred L2 review Minors: two projects' runs of one id share harness-<id>-svc (refuse in cmd_start); SVC_UP is shell-only, so a continue segment with no init leaves a SIGKILLed segment's svc scope to gc ($STATE/svc-up sketch); without user systemd the note says services stopped while bare init children run on.
- **Discovery** (affects L3, L4, L5): The suite project's INIT_CMD now takes STUB_SLOW_INITCMD=<s> (touches $HARNESS_SCRATCH/init-begin, sleeps) and its teardown.sh STUB_SLOW_TEARDOWN=<s> (touches teardown-begin); stub-claude STUB_ADD_TEARDOWN=1 makes the initializer write an executable .harness/teardown.sh. tests/run.sh has sd_before <key> <index>.
- **Discovery** (affects L4, run): TEARDOWN_CMD defaults to empty now; services_down picks .harness/teardown.sh when executable at call time.
- **Discovery** (affects run): The known 'queue holds an entry whose project has a live run' flake (busy3 sleep 3) failed once more in a KEEP=1 run under load.
- *14-L2-06 · claude-opus-5-5*

### 2026-10-25 18:21 · L2-05 · passes

harness gc first stops the units of this project's runs with no live driver (+ stopped <u> (<run> ended|: driver gone), --dry-run would:, ? for no run of this project); harness status lists a running run's units with MemoryCurrent. scope_owns in lib/scope.sh is the shared match; stub systemctl answers MemoryCurrent and the described list-units shape.

- **Files:** bin/harness, lib/scope.sh, tests/run.sh, tests/stub-systemctl.sh, docs/architecture.md, README.md, journal/decisions/2026-10-25-gc-orphan-units.md
- **Verified:** tests/run.sh 282 → 285/285 (scope_owns unit check, gc unit check with a.b/a-b collision decoy, status check in the termed block); the three failed before the code; lib/check.sh green in 493 s; Opus review of the diff, findings 1-3 and 5 fixed
- **Tests:** 282 → 285
- **Dead end:** a waited `sleep 0` pid as the dead driver.pid — a reused pid would count as live (review): 999999999 is over any pid_max
- **Discovery** (affects L4, L2-06): gc's unit step runs first in cmd_gc, before the fetch: a review found an offline fetch or a prunable worktree ends gc under set -e before a later step, and a worktree could be removed while a SIGKILLed run's session still ran in it. L4's per-worktree error handling should keep that order.
- **Discovery** (affects L3, L2-06): scope_owns <run> <unit>.scope (lib/scope.sh) is the one unit→run match (roles s<n>, check-<pid>, svc); bin/harness now sources lib/scope.sh. L3's gc of tmux sessions can follow the same candidates-over-every-project pattern.
- **Discovery** (affects L2-06): Not fixed (display only): two running runs whose ids reduce to one prefix (a.b, a-b) each list both runs' units in harness status.
- **Discovery** (affects run): One full-suite run failed 'queue holds an entry whose project has a live run' (its busy3 driver is a `sleep 3`); the next two runs passed unchanged: a timing flake under load.
- **Question for Michael:** D1 default (decisions/2026-10-25-gc-orphan-units): harness status calls list-units without a scope_available probe first (a failing list-units gives nothing; the probe would start a transient scope per status). Keep it?
- **Proposed change:** L2-05 step 1: the unit step runs first in cmd_gc, not after the branch passes (review finding); its lines are gc's own, not act's; a run with no live driver qualifies with or without ended (plan §11).
- *13-L2-05 · claude-opus-5-5*

### 2026-10-25 17:36 · L2-04 · passes

Services now also stop on pause (services_down paused, then commit+push), before a usage-limit wait over SVC_IDLE_STOP_MIN=10 min, and on the memory wait (renamed `memory wait`); STOP already went through finish. New key in config.sh/template/architecture §10; §5/§7, README and decisions/2026-10-25-services-stop-points updated.

- **Files:** lib/driver.sh, lib/scope.sh, lib/config.sh, templates/user/config.sh, tests/run.sh, tests/stub-claude.sh, docs/architecture.md, README.md, journal/decisions/2026-10-25-services-stop-points.md
- **Verified:** Wrote 5 checks + the mg unit-check rename first: 4 failed (mg block, PAUSE, memory wait, usage-limit wait 11 min); stoppy and the 9-minute check passed already as the plan predicted (check-only). After the change bash tests/run.sh 282/282; lib/check.sh green in 492 s.
- **Tests:** 277 → 282
- **Discovery** (affects L2-05, L2-06): stub-claude.sh has STUB_PAUSE=<id>: that id's first coding session touches $HARNESS_STATE/*/<run>/PAUSE. Run `paused` in tests/run.sh drives it in the background and resumes with `harness resume paused` once hlog has `services stopped (paused)`.
- **Discovery** (affects run): Run waiter's window is now +660 s (11 min) and waiter9 (+540 s) is new; the suite has two more full runs (about +20 s).
- **Question for Michael:** D1 default: SVC_IDLE_STOP_MIN=10 (a usage-limit wait of more than 10 minutes stops the services; shorter keeps them). Keep 10?
- *12-L2-04 · claude-opus-5-5*

### 2026-10-25 17:08 · L2-03 · passes

services_down runs .harness/teardown.sh (TEARDOWN_CMD) under timeout -k 10s 2m, stops harness-<run>-svc, notes once per started init; on finish and in the EXIT trap, which first ignores TERM/INT/HUP and stops the running session's scope. verify re-inits after a memory wait. Stubs kill a stopped scope's tree. Template, README, arch, decision. Tests 274 → 277.

- **Files:** lib/driver.sh, lib/config.sh, templates/user/config.sh, templates/project/teardown.sh, tests/run.sh, tests/stub-systemd-run.sh, tests/stub-systemctl.sh, README.md, docs/architecture.md, journal/decisions/2026-10-25-teardown-hook.md
- **Verified:** 3 new checks, each seen RED on a snapshot (finish teardown→stop→one note on demo; a TERM to run termed's driver mid-session: session scope stop < teardown < svc stop, no stub claude left, ended/driver.pid; lowmem: every session before finish starts with svc up). bash tests/run.sh 277/277; lib/check.sh green in 470 s; no harness-test-* unit left.
- **Tests:** 274 → 277
- **Discovery** (affects L2-04): verify() now does `mem_gate || run_init` (pulled forward from L2-04: with a real services_down the gate after verify's run_init stopped the services before the verify session). L2-04 only needs to rename mem_gate's `services_down memory` to `memory wait` and add its checks; the lowmem run notes `services stopped (memory)` until then.
- **Discovery** (affects L2-04, L2-05, L2-06): The suite's project now has an executable .harness/teardown.sh writing $HARNESS_SCRATCH/teardown-<why-safe>.marker and a `teardown\n<run>\n<why>` record into systemd.log; helpers sd_last (last record index) and svc_gaps <run> (sessions started with svc down) are in tests/run.sh. Every run in proj now notes `services stopped (<finish reason>)`.
- **Discovery** (affects L2-05): stub-systemd-run.sh runs its command in the background (<&0 keeps stdin) with the pid in <unit>.cmd; stub-systemctl stop TERMs that pid and its descendants (parents first) plus .pids. Run termed (TERMed mid-session, STUB_SLOW_CODING=30) is left ended in state with an uncommitted `services stopped (driver exited)` in its harness-log.md, which L2-05's status/gc checks can use.
- **Discovery** (affects L2-06): Review findings left for L2-06: a TERM during run_init runs the teardown while the init may still be starting containers; a TERM during finish's own teardown runs a second teardown concurrently; TEARDOWN_CMD is picked at load_config, so a teardown.sh added mid-run is seen only after a config reload; the trap's note stays uncommitted after a kill.
- **Proposed change:** L2-03 step 3 names one teardown.marker; the plan's hook writes one per why (teardown-done.marker here) and orders teardown and stop in systemd.log rather than by mtime (plan §11).
- **Proposed change:** L2-04 step 1's verify `mem_gate || run_init` is done in L2-03.
- *11-L2-03 · claude-opus-5-5*

### 2026-10-25 16:30 · L2-02 · passes

run_init now stops harness-<run>-svc, then runs INIT_CMD in it (MemoryMax=SVC_MEMORY_MAX 3G, timeout -k 10s INIT_TIMEOUT 10m, stdin /dev/null); a refused unit notes `init ran uncapped`. Stub systemd-run refuses a still-loaded unit like real systemd. 4 checks (3 seen RED), decision file, arch/README/config docs. Tests 270 → 274.

- **Files:** lib/driver.sh, lib/config.sh, templates/user/config.sh, tests/run.sh, tests/stub-systemd-run.sh, docs/architecture.md, README.md, journal/decisions/2026-10-25-services-scope.md
- **Verified:** RED on a git copy with the old driver: the dup-unit, the stop-then-scope order and the backgrounded-init checks failed (bare check passed, as a regression guard). GREEN: lib/check.sh green in 473 s, 274/274; no harness-test-* unit or sleep 300 left. Opus review: 0 Critical/Important, 3 Minor (2 fixed).
- **Tests:** 270 → 274
- **Dead end:** running the RED suite on a tar copy of the tree without git — the eval checks need a git repo; git init + commit in the copy works
- **Discovery** (affects L2-03, L2-04, L2-05): stub-systemd-run.sh now refuses a unit whose .alive is set and that is .running or holds a live pid (fixtures/systemd-run-unit-exists.txt, exit 1, command not run). Any new code that reuses a unit name must scope_stop it first.
- **Discovery** (affects L2-03): run_init sets SVC_UP=1 before the start (plan §1); services_down (L2-03) can key on it. The bp1 check (tests/run.sh ~960) counts `stop harness-bp1-svc.scope` >= 2, so finish's stop in L2-03 keeps it green.
- **Discovery** (affects L2-06): GNU timeout (no --foreground) kills its whole process group on expiry, so an init that times out takes the servers it already backgrounded with it; docs say so. Plan's `timeout -k 10s 10m` kept as the step names it.
- **Discovery** (affects L2-05, L2-06): Review Minor not fixed: run ids are unique per project only, and scope_unit maps . to -, so two projects' runs with the same id share harness-<id>-svc and run_init's stop-first would kill the other's services (was: refused, bare). gc's unit match (L2-05) has the same ambiguity; consider the project in the unit name or refusing a duplicate id.
- **Question for Michael:** D *default* (decisions/2026-10-25-services-scope): the init's stdin is now /dev/null instead of the tmux pane, so an interactive init prompt fails fast instead of waiting for you in the window. OK?
- *10-L2-02 · claude-opus-5-5*

### 2026-10-25 16:02 · L2-01 · passes

Wrote docs/plans/2026-10-25-L2-run-services.md: svc scope in run_init (stop first), services_down/SVC_UP, the trap (session scope too), six stop points, suite observation per stop point, gc's unit match rule and status lines. Captured 4 real fixtures. An Opus review found 1 Critical and 4 Important plan bugs; all fixed in the plan. Tests 270 → 270.

- **Files:** docs/plans/2026-10-25-L2-run-services.md, tests/fixtures/systemctl-show-current.txt, tests/fixtures/systemctl-show-current-gone.txt, tests/fixtures/systemctl-list-units-described.txt, tests/fixtures/systemd-run-unit-exists.txt
- **Verified:** check.sh: green in 454 s, 270/270; fixtures captured from real 64M harness-test-<pid>-cur/-dup scopes, each stopped; list-units 'harness-test-*' printed nothing afterwards; bash TERM probe: EXIT trap ran in 13 ms, child lived on
- **Tests:** 270 → 270
- **Dead end:** stub-systemd-run recording the command pid in <unit>.pids — pids count in the stub's TasksCurrent, so every clean session would 'leave 1 process'; plan uses <unit>.cmd plus a tree kill
- **Dead end:** INIT_CMD for check 6.9 in the user config — the project's .harness/config.sh is sourced after it and wins (lib/config.sh:31); use a dproj project
- **Discovery** (affects L2-03): Bash runs the EXIT trap at once on SIGTERM while a foreground child runs, and the child lives on: a TERM to the driver mid-session leaves claude running in harness-<run>-s<n>. Plan §4: the trap stops S_UNIT first, then services_down.
- **Discovery** (affects L2-05): A SIGKILLed driver leaves no `ended` (the driver removes it at start; only finish and the trap write it), so gc stops units of runs with no live driver.pid, ended or not (plan §7.1).
- **Discovery** (affects L2-02): systemd-run with a unit name still loaded exits 1: 'Failed to start transient scope unit: Unit <u>.scope was already loaded or has a fragment file.' (fixtures/systemd-run-unit-exists.txt). run_init must stop the old svc scope first.
- **Discovery** (affects L2-03, L2-04, L2-05): verify() runs run_init before its mem_gate, so a memory wait leaves the verify without services: L2-04 makes it `mem_gate || run_init`. bin/harness is set -euo pipefail: TEARDOWN_CMD's default line and cmd_status's systemctl calls must always succeed (plan §2, §7.2).
- **Question for Michael:** D2 default: the driver's EXIT trap also stops the running session's scope, not only the services. OK?
- **Question for Michael:** gc stops a run's units when its driver is dead even without `ended` (a SIGKILL writes none), not only for ended runs as the spec says. OK?
- **Proposed change:** L2-03 step 3: one marker per why (teardown-done.marker), and the order is read from systemd.log (the teardown logs a record there), not from the marker's mtime
- **Proposed change:** L2-03 step 4: the TERM goes to driver.pid (--foreground runs the driver as a child of bin/harness); the trap also stops the session's scope
- **Proposed change:** L2-04 step 2: the stub sets PAUSE ($STATE/PAUSE) and the suite resumes with harness resume (no session runs during a pause); the pause branch commits its note
- **Proposed change:** L2-04: verify() needs `mem_gate || run_init`
- **Proposed change:** L2-05 step 1: units qualify with no live driver.pid, `ended` or not; gc prints its own `+ stopped <unit> (<run> ended|: driver gone)` lines rather than act's raw argv
- *09-L2-01 · claude-opus-5-5*

### 2026-10-25 15:34 · verify L1 · passes

All 8 L1 features hold: suite re-run 270/270, artifacts, stubs, fixtures, docs and decision files checked against each step; no leftover harness-test units.

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| L1-01 | 1 | re-ran bash tests/run.sh and inspected files/greps for this step | read docs/plans/2026-10-25-L1-capped-sessions.md and listed fixtures; files present, real captures, config keys in plan; suite 270/270 | yes |
| L1-01 | 2 | re-ran bash tests/run.sh and inspected files/greps for this step | read docs/plans/2026-10-25-L1-capped-sessions.md and listed fixtures; files present, real captures, config keys in plan; suite 270/270 | yes |
| L1-01 | 3 | re-ran bash tests/run.sh and inspected files/greps for this step | read docs/plans/2026-10-25-L1-capped-sessions.md and listed fixtures; files present, real captures, config keys in plan; suite 270/270 | yes |
| L1-01 | 4 | re-ran bash tests/run.sh and inspected files/greps for this step | read docs/plans/2026-10-25-L1-capped-sessions.md and listed fixtures; files present, real captures, config keys in plan; suite 270/270 | yes |
| L1-01 | 5 | re-ran bash tests/run.sh and inspected files/greps for this step | read docs/plans/2026-10-25-L1-capped-sessions.md and listed fixtures; files present, real captures, config keys in plan; suite 270/270 | yes |
| L1-01 | 6 | re-ran bash tests/run.sh and inspected files/greps for this step | read docs/plans/2026-10-25-L1-capped-sessions.md and listed fixtures; files present, real captures, config keys in plan; suite 270/270 | yes |
| L1-02 | 1 | re-ran bash tests/run.sh and inspected files/greps for this step | read lib/scope.sh + stubs; suite checks 'scope.sh: scope_run wraps…', 'scope_stop…', 'run id becomes a unit name', 'STUB_NO_SYSTEMD', 'a real 64M scope kills… exit 137 and leaves no unit' PASS; list-units harness-test-* empty; decision file present | yes |
| L1-02 | 2 | re-ran bash tests/run.sh and inspected files/greps for this step | read lib/scope.sh + stubs; suite checks 'scope.sh: scope_run wraps…', 'scope_stop…', 'run id becomes a unit name', 'STUB_NO_SYSTEMD', 'a real 64M scope kills… exit 137 and leaves no unit' PASS; list-units harness-test-* empty; decision file present | yes |
| L1-02 | 3 | re-ran bash tests/run.sh and inspected files/greps for this step | read lib/scope.sh + stubs; suite checks 'scope.sh: scope_run wraps…', 'scope_stop…', 'run id becomes a unit name', 'STUB_NO_SYSTEMD', 'a real 64M scope kills… exit 137 and leaves no unit' PASS; list-units harness-test-* empty; decision file present | yes |
| L1-02 | 4 | re-ran bash tests/run.sh and inspected files/greps for this step | read lib/scope.sh + stubs; suite checks 'scope.sh: scope_run wraps…', 'scope_stop…', 'run id becomes a unit name', 'STUB_NO_SYSTEMD', 'a real 64M scope kills… exit 137 and leaves no unit' PASS; list-units harness-test-* empty; decision file present | yes |
| L1-02 | 5 | re-ran bash tests/run.sh and inspected files/greps for this step | read lib/scope.sh + stubs; suite checks 'scope.sh: scope_run wraps…', 'scope_stop…', 'run id becomes a unit name', 'STUB_NO_SYSTEMD', 'a real 64M scope kills… exit 137 and leaves no unit' PASS; list-units harness-test-* empty; decision file present | yes |
| L1-02 | 6 | re-ran bash tests/run.sh and inspected files/greps for this step | read lib/scope.sh + stubs; suite checks 'scope.sh: scope_run wraps…', 'scope_stop…', 'run id becomes a unit name', 'STUB_NO_SYSTEMD', 'a real 64M scope kills… exit 137 and leaves no unit' PASS; list-units harness-test-* empty; decision file present | yes |
| L1-02 | 7 | re-ran bash tests/run.sh and inspected files/greps for this step | read lib/scope.sh + stubs; suite checks 'scope.sh: scope_run wraps…', 'scope_stop…', 'run id becomes a unit name', 'STUB_NO_SYSTEMD', 'a real 64M scope kills… exit 137 and leaves no unit' PASS; list-units harness-test-* empty; decision file present | yes |
| L1-02 | 8 | re-ran bash tests/run.sh and inspected files/greps for this step | read lib/scope.sh + stubs; suite checks 'scope.sh: scope_run wraps…', 'scope_stop…', 'run id becomes a unit name', 'STUB_NO_SYSTEMD', 'a real 64M scope kills… exit 137 and leaves no unit' PASS; list-units harness-test-* empty; decision file present | yes |
| L1-03 | 1 | re-ran bash tests/run.sh and inspected files/greps for this step | config.sh/template keys grep; checks 'sessions run in harness-<run>-s<n> with the three caps and timeout -k 30s', 'scope is stopped after it returns', 'no user systemd…', 'killed at its memory cap (STUB_OOM)', leftover note check PASS; bin/harness line 177 passes stubs; arch §7 row; bash -n ok | yes |
| L1-03 | 2 | re-ran bash tests/run.sh and inspected files/greps for this step | config.sh/template keys grep; checks 'sessions run in harness-<run>-s<n> with the three caps and timeout -k 30s', 'scope is stopped after it returns', 'no user systemd…', 'killed at its memory cap (STUB_OOM)', leftover note check PASS; bin/harness line 177 passes stubs; arch §7 row; bash -n ok | yes |
| L1-03 | 3 | re-ran bash tests/run.sh and inspected files/greps for this step | config.sh/template keys grep; checks 'sessions run in harness-<run>-s<n> with the three caps and timeout -k 30s', 'scope is stopped after it returns', 'no user systemd…', 'killed at its memory cap (STUB_OOM)', leftover note check PASS; bin/harness line 177 passes stubs; arch §7 row; bash -n ok | yes |
| L1-03 | 4 | re-ran bash tests/run.sh and inspected files/greps for this step | config.sh/template keys grep; checks 'sessions run in harness-<run>-s<n> with the three caps and timeout -k 30s', 'scope is stopped after it returns', 'no user systemd…', 'killed at its memory cap (STUB_OOM)', leftover note check PASS; bin/harness line 177 passes stubs; arch §7 row; bash -n ok | yes |
| L1-03 | 5 | re-ran bash tests/run.sh and inspected files/greps for this step | config.sh/template keys grep; checks 'sessions run in harness-<run>-s<n> with the three caps and timeout -k 30s', 'scope is stopped after it returns', 'no user systemd…', 'killed at its memory cap (STUB_OOM)', leftover note check PASS; bin/harness line 177 passes stubs; arch §7 row; bash -n ok | yes |
| L1-03 | 6 | re-ran bash tests/run.sh and inspected files/greps for this step | config.sh/template keys grep; checks 'sessions run in harness-<run>-s<n> with the three caps and timeout -k 30s', 'scope is stopped after it returns', 'no user systemd…', 'killed at its memory cap (STUB_OOM)', leftover note check PASS; bin/harness line 177 passes stubs; arch §7 row; bash -n ok | yes |
| L1-03 | 7 | re-ran bash tests/run.sh and inspected files/greps for this step | config.sh/template keys grep; checks 'sessions run in harness-<run>-s<n> with the three caps and timeout -k 30s', 'scope is stopped after it returns', 'no user systemd…', 'killed at its memory cap (STUB_OOM)', leftover note check PASS; bin/harness line 177 passes stubs; arch §7 row; bash -n ok | yes |
| L1-03 | 8 | re-ran bash tests/run.sh and inspected files/greps for this step | config.sh/template keys grep; checks 'sessions run in harness-<run>-s<n> with the three caps and timeout -k 30s', 'scope is stopped after it returns', 'no user systemd…', 'killed at its memory cap (STUB_OOM)', leftover note check PASS; bin/harness line 177 passes stubs; arch §7 row; bash -n ok | yes |
| L1-03 | 9 | re-ran bash tests/run.sh and inspected files/greps for this step | config.sh/template keys grep; checks 'sessions run in harness-<run>-s<n> with the three caps and timeout -k 30s', 'scope is stopped after it returns', 'no user systemd…', 'killed at its memory cap (STUB_OOM)', leftover note check PASS; bin/harness line 177 passes stubs; arch §7 row; bash -n ok | yes |
| L1-04 | 1 | re-ran bash tests/run.sh and inspected files/greps for this step | checks 'metrics.mjs: append writes mem_peak_mb', 'metrics.jsonl: every session line has mem_peak_mb', 'null when uncapped', 'report.md lists… peaks over 2 GB' PASS; arch §11 line 319, README Memory row; decision file; node --check ok | yes |
| L1-04 | 2 | re-ran bash tests/run.sh and inspected files/greps for this step | checks 'metrics.mjs: append writes mem_peak_mb', 'metrics.jsonl: every session line has mem_peak_mb', 'null when uncapped', 'report.md lists… peaks over 2 GB' PASS; arch §11 line 319, README Memory row; decision file; node --check ok | yes |
| L1-04 | 3 | re-ran bash tests/run.sh and inspected files/greps for this step | checks 'metrics.mjs: append writes mem_peak_mb', 'metrics.jsonl: every session line has mem_peak_mb', 'null when uncapped', 'report.md lists… peaks over 2 GB' PASS; arch §11 line 319, README Memory row; decision file; node --check ok | yes |
| L1-04 | 4 | re-ran bash tests/run.sh and inspected files/greps for this step | checks 'metrics.mjs: append writes mem_peak_mb', 'metrics.jsonl: every session line has mem_peak_mb', 'null when uncapped', 'report.md lists… peaks over 2 GB' PASS; arch §11 line 319, README Memory row; decision file; node --check ok | yes |
| L1-04 | 5 | re-ran bash tests/run.sh and inspected files/greps for this step | checks 'metrics.mjs: append writes mem_peak_mb', 'metrics.jsonl: every session line has mem_peak_mb', 'null when uncapped', 'report.md lists… peaks over 2 GB' PASS; arch §11 line 319, README Memory row; decision file; node --check ok | yes |
| L1-04 | 6 | re-ran bash tests/run.sh and inspected files/greps for this step | checks 'metrics.mjs: append writes mem_peak_mb', 'metrics.jsonl: every session line has mem_peak_mb', 'null when uncapped', 'report.md lists… peaks over 2 GB' PASS; arch §11 line 319, README Memory row; decision file; node --check ok | yes |
| L1-05 | 1 | re-ran bash tests/run.sh and inspected files/greps for this step | check.sh sources scope.sh, scope_run+timeout -k 30s; checks 'exit 137 prints the memory-cap RED line', 'subset call is scoped too and never cached', TERM stops scope PASS; arch/README rows; capped-suites decision | yes |
| L1-05 | 2 | re-ran bash tests/run.sh and inspected files/greps for this step | check.sh sources scope.sh, scope_run+timeout -k 30s; checks 'exit 137 prints the memory-cap RED line', 'subset call is scoped too and never cached', TERM stops scope PASS; arch/README rows; capped-suites decision | yes |
| L1-05 | 3 | re-ran bash tests/run.sh and inspected files/greps for this step | check.sh sources scope.sh, scope_run+timeout -k 30s; checks 'exit 137 prints the memory-cap RED line', 'subset call is scoped too and never cached', TERM stops scope PASS; arch/README rows; capped-suites decision | yes |
| L1-05 | 4 | re-ran bash tests/run.sh and inspected files/greps for this step | check.sh sources scope.sh, scope_run+timeout -k 30s; checks 'exit 137 prints the memory-cap RED line', 'subset call is scoped too and never cached', TERM stops scope PASS; arch/README rows; capped-suites decision | yes |
| L1-05 | 5 | re-ran bash tests/run.sh and inspected files/greps for this step | check.sh sources scope.sh, scope_run+timeout -k 30s; checks 'exit 137 prints the memory-cap RED line', 'subset call is scoped too and never cached', TERM stops scope PASS; arch/README rows; capped-suites decision | yes |
| L1-05 | 6 | re-ran bash tests/run.sh and inspected files/greps for this step | check.sh sources scope.sh, scope_run+timeout -k 30s; checks 'exit 137 prints the memory-cap RED line', 'subset call is scoped too and never cached', TERM stops scope PASS; arch/README rows; capped-suites decision | yes |
| L1-05 | 7 | re-ran bash tests/run.sh and inspected files/greps for this step | check.sh sources scope.sh, scope_run+timeout -k 30s; checks 'exit 137 prints the memory-cap RED line', 'subset call is scoped too and never cached', TERM stops scope PASS; arch/README rows; capped-suites decision | yes |
| L1-06 | 1 | re-ran bash tests/run.sh and inspected files/greps for this step | checks 'mem_available_gb reads the real meminfo fixture', 'memory gate: under 5 GB…', '9 GB passes without a note' PASS; bin/harness passes HARNESS_MEMINFO/MEM_POLL; arch gate row; memory-gate decision | yes |
| L1-06 | 2 | re-ran bash tests/run.sh and inspected files/greps for this step | checks 'mem_available_gb reads the real meminfo fixture', 'memory gate: under 5 GB…', '9 GB passes without a note' PASS; bin/harness passes HARNESS_MEMINFO/MEM_POLL; arch gate row; memory-gate decision | yes |
| L1-06 | 3 | re-ran bash tests/run.sh and inspected files/greps for this step | checks 'mem_available_gb reads the real meminfo fixture', 'memory gate: under 5 GB…', '9 GB passes without a note' PASS; bin/harness passes HARNESS_MEMINFO/MEM_POLL; arch gate row; memory-gate decision | yes |
| L1-06 | 4 | re-ran bash tests/run.sh and inspected files/greps for this step | checks 'mem_available_gb reads the real meminfo fixture', 'memory gate: under 5 GB…', '9 GB passes without a note' PASS; bin/harness passes HARNESS_MEMINFO/MEM_POLL; arch gate row; memory-gate decision | yes |
| L1-06 | 5 | re-ran bash tests/run.sh and inspected files/greps for this step | checks 'mem_available_gb reads the real meminfo fixture', 'memory gate: under 5 GB…', '9 GB passes without a note' PASS; bin/harness passes HARNESS_MEMINFO/MEM_POLL; arch gate row; memory-gate decision | yes |
| L1-06 | 6 | re-ran bash tests/run.sh and inspected files/greps for this step | checks 'mem_available_gb reads the real meminfo fixture', 'memory gate: under 5 GB…', '9 GB passes without a note' PASS; bin/harness passes HARNESS_MEMINFO/MEM_POLL; arch gate row; memory-gate decision | yes |
| L1-07 | 1 | re-ran bash tests/run.sh and inspected files/greps for this step | checks 'every session passes --strict-mcp-config…', 'worktree with .mcp.json…', 'rendered coding prompt has the deepEqual rule' PASS; decision file; arch line 51; README line 59 | yes |
| L1-07 | 2 | re-ran bash tests/run.sh and inspected files/greps for this step | checks 'every session passes --strict-mcp-config…', 'worktree with .mcp.json…', 'rendered coding prompt has the deepEqual rule' PASS; decision file; arch line 51; README line 59 | yes |
| L1-07 | 3 | re-ran bash tests/run.sh and inspected files/greps for this step | checks 'every session passes --strict-mcp-config…', 'worktree with .mcp.json…', 'rendered coding prompt has the deepEqual rule' PASS; decision file; arch line 51; README line 59 | yes |
| L1-07 | 4 | re-ran bash tests/run.sh and inspected files/greps for this step | checks 'every session passes --strict-mcp-config…', 'worktree with .mcp.json…', 'rendered coding prompt has the deepEqual rule' PASS; decision file; arch line 51; README line 59 | yes |
| L1-07 | 5 | re-ran bash tests/run.sh and inspected files/greps for this step | checks 'every session passes --strict-mcp-config…', 'worktree with .mcp.json…', 'rendered coding prompt has the deepEqual rule' PASS; decision file; arch line 51; README line 59 | yes |
| L1-08 | 1 | re-ran bash tests/run.sh and inspected files/greps for this step | review doc with severities (1 Important, fixed RED→GREEN by named check); arch §4 Scopes row + §10 keys; README oomd/list-units lines; no decision file numbers D-H; bash -n/node --check ok; suite 270/270 | yes |
| L1-08 | 2 | re-ran bash tests/run.sh and inspected files/greps for this step | review doc with severities (1 Important, fixed RED→GREEN by named check); arch §4 Scopes row + §10 keys; README oomd/list-units lines; no decision file numbers D-H; bash -n/node --check ok; suite 270/270 | yes |
| L1-08 | 3 | re-ran bash tests/run.sh and inspected files/greps for this step | review doc with severities (1 Important, fixed RED→GREEN by named check); arch §4 Scopes row + §10 keys; README oomd/list-units lines; no decision file numbers D-H; bash -n/node --check ok; suite 270/270 | yes |
| L1-08 | 4 | re-ran bash tests/run.sh and inspected files/greps for this step | review doc with severities (1 Important, fixed RED→GREEN by named check); arch §4 Scopes row + §10 keys; README oomd/list-units lines; no decision file numbers D-H; bash -n/node --check ok; suite 270/270 | yes |
| L1-08 | 5 | re-ran bash tests/run.sh and inspected files/greps for this step | review doc with severities (1 Important, fixed RED→GREEN by named check); arch §4 Scopes row + §10 keys; README oomd/list-units lines; no decision file numbers D-H; bash -n/node --check ok; suite 270/270 | yes |

- *152548-verify-L1 · claude-sonnet-5-5*

### 2026-10-25 15:25 · L1-08 · passes

Opus review of the L1 diff in docs/plans/2026-10-25-L1-review.md: 7 findings (1 Important, 4 Minor, 2 Simpl.). Fixed RED→GREEN: mem_gate moved out of session() to before the attempt bump/prompt (stop and deadline seen after a wait), refused scope noted, HARNESS_MEM_POLL=0 ends. Docs: arch §4 Scopes row, §7; README Memory row and After the run. Tests 267 → 270.

- **Files:** lib/driver.sh, lib/scope.sh, tests/run.sh, tests/stub-claude.sh, tests/stub-systemd-run.sh, tests/fixtures/systemd-run-bad-property.txt, docs/plans/2026-10-25-L1-review.md, docs/architecture.md, README.md, journal/decisions/2026-10-25-memory-gate.md, journal/decisions/2026-10-25-scoped-sessions.md
- **Verified:** full suite 270/270 (check: green in 459 s); each new check run alone failed before its fix (gate-stop: coding session ran; refused scope: no note; poll 0: timeout 124); bash -n on lib/*.sh, bin/harness, tests/*.sh and node --check on lib/*.mjs clean; decision files all cite the spec, finding·choice·rejected, no D-H<n>
- **Tests:** 267 → 270
- **Discovery** (affects L2, run): mem_gate now exits 1 after any wait and is called by the driver loop (after the pick, before F bump; the loop starts over once, gated=1), verify() before each round clock, and the init before run_init; session() no longer gates. L2 services_down hooks into the same place.
- **Discovery** (affects L2): scope_run sets SCOPE_BARE when systemd-run fails after the probe passed; session() notes <kind> session ran uncapped: <why>. Real systemd-run on an unparseable MemoryMax: `Failed to parse MemoryMax=bogus: Invalid argument`, exit 1, no unit (tests/fixtures/systemd-run-bad-property.txt).
- **Discovery** (affects L2): Deferred review findings for L2: check.sh stop() misses a TERM before the scope registers or on the bare fallback (orphaned suite up to CHECK_TIMEOUT); systemctl-list-units.txt fixture predates --description (recapture before parsing its DESCRIPTION column); check.sh probes a real scope every call (pass the driver SCOPE_OK down).
- *08-L1-08 · claude-opus-5-5*

### 2026-10-25 15:06 · L1-07 · passes

session() always passes --strict-mcp-config, plus --mcp-config <wt>/.mcp.json when the worktree has one; run.log gets an 'MCP servers:' line at run start. prompts/parts/rules.md gains the deepEqual / bounded-rerun-after-137 rule. Decision file quotes the real claude --help lines (2.1.310). Docs: architecture §3 driver row, README .mcp.json row. Tests 264 → 267.

- **Files:** lib/driver.sh, prompts/parts/rules.md, tests/run.sh, journal/decisions/2026-10-25-strict-mcp-and-deepequal-rule.md, docs/architecture.md, README.md
- **Verified:** 3 new checks failed first (264/267), then lib/check.sh full: 267/267 checks passed. Checks: every demo session's systemd-run argv has --strict-mcp-config and none --mcp-config; run mp1 on a project committing .mcp.json gets --mcp-config $T/wt/mp/mp1/.mcp.json; lib/prompt.sh renders demo's coding prompt for A with deepEqual, exit 137, --test-name-pattern.
- **Tests:** 264 → 267
- **Discovery** (affects run): prompts/parts/rules.md is only included when the worktree has a CLAUDE.md (lib/prompt.sh prompt_render), so the deepEqual rule reaches only projects with one (all of them today). The MCP line is logged to run.log beside the permissions line, not noted in harness-log.md (same for every session).
- *07-L1-07 · claude-opus-5-5*

### 2026-10-25 14:48 · L1-06 · passes

Memory gate: mem_available_gb and mem_gate in lib/scope.sh; session() calls mem_gate for init/coding/verify (not retro) before t0. Under MEM_MIN_AVAILABLE_GB=5 it notes, calls services_down memory (no-op in driver until L2), checks at once then every HARNESS_MEM_POLL s up to MEM_WAIT_MAX=30m, then starts anyway. Config, template, docs, decision. Tests 260 → 264.

- **Files:** lib/scope.sh, lib/driver.sh, lib/config.sh, templates/user/config.sh, tests/run.sh, docs/architecture.md, README.md, journal/decisions/2026-10-25-memory-gate.md
- **Verified:** bash tests/run.sh 264/264; lib/check.sh green in 453 s; new checks: mem_available_gb on the real fixture (9), mem_gate unit (still-low and freed-by-services_down paths), run lowmem (2 GB copy, MEM_WAIT_MAX=2s: both notes once per init/coding/verify session, 3/3 passing), demo has no memory note; bash -n on every touched shell file
- **Tests:** 260 → 264
- **Discovery** (affects L2): mem_gate lives in lib/scope.sh (not the driver as the plan said) and calls services_down only when declared; driver.sh defines a no-op services_down() unless one exists. L2 should define the real one before or instead of it (driver.sh:57: `declare -F services_down || services_down() { :; }`).
- **Discovery** (affects L2): mem_gate checks right after services_down before its first sleep, so a teardown that frees memory starts the session at once (note 'memory: <n> GB available after 0 s; starting the session').
- **Question for Michael:** D default: MEM_MIN_AVAILABLE_GB=5 and MEM_WAIT_MAX=30m (the audit's figures), starting the session anyway after the wait rather than parking. Keep?
- *06-L1-06 · claude-opus-5-5*

### 2026-10-25 14:30 · L1-05 · passes

check.sh runs full and subset suites in harness-<run>-check-<pid> (MemoryMax=CHECK_MEMORY_MAX 3G, no MemoryHigh) under timeout -k 30s CHECK_TIMEOUT 15m, stopped after; RED lines for the cap (scope_capped) and the timeout; a TERM/INT/HUP stops the check scope; prompt_env exports prefix/cap/timeout; dur_s in scope.sh. Tests 254 → 260.

- **Files:** lib/check.sh, lib/scope.sh, lib/prompt.sh, lib/config.sh, templates/user/config.sh, tests/run.sh, docs/architecture.md, README.md, journal/decisions/2026-10-25-capped-suites.md
- **Verified:** bash tests/run.sh 260/260; harness check.sh green in 421 s; new checks watched failing first (old RED lines, no scope; TERM check fails with the traps removed); by hand with real systemd-run under harness-test-<pid>-*, 64M, swap 0: a 256 MB node allocation → check: RED (killed at its 64M memory cap, exit 137 …), a TERM to check.sh → 143, no unit, sleep or scope file left
- **Tests:** 254 → 260
- **Dead end:** a real 64M check scope with the default 1G swap — the 256 MB allocation swapped and passed: check scopes always get scope_run's 1G MemorySwapMax (SESSION_SWAP_MAX is not exported to check.sh)
- **Discovery** (affects L1-08, L2): Only systemd-run's child moves into the check scope; check.sh stays in its caller's. Without the TERM trap, stopping a session's scope orphaned its suite in harness-<run>-check-<pid> for up to 15m. check.sh now runs the suite in the background, waits, and stops the check scope on TERM/INT/HUP (SIGKILL still can't be caught).
- **Discovery** (affects L3): check.sh leaves no scopes/<unit>.started/.show (EXIT trap); session scopes still do, one pair per session, until L3 deletes scratch.
- **Discovery** (affects L1-08): Check scopes get MemorySwapMax=1G always (template comment corrected); a suite can reach 4G before the kill.
- **Question for Michael:** CHECK_MEMORY_MAX=3G and CHECK_TIMEOUT=15m are the spec's defaults (this repo's own suite runs ~7 min, well under). D6 default: suites get no MemoryHigh. Keep both?
- **Proposed change:** L1-05 step 3: the cap line needs scope_capped (peak reached the cap), not just exit 137 in a scope, so a suite's own 137 keeps the plain RED line; the plan §7 says any scoped 137
- *05-L1-05 · claude-opus-5-5*

### 2026-10-25 14:02 · L1-04 · passes

metrics.mjs append takes a 12th arg (mem_peak_mb: number, null when uncapped) via exported metricsRow; every MET append passes $S_PEAK; report(s, metrics) adds '### Memory peaks over 2 GB' (- <feature> · <model> · <peak> MB) from metrics.jsonl beside summary.json; harness report copies metrics.jsonl into the state dir. Docs, decision file. Tests 249 → 254.

- **Files:** lib/metrics.mjs, lib/summary.mjs, lib/driver.sh, bin/harness, tests/run.sh, docs/architecture.md, README.md, journal/decisions/2026-10-25-session-memory-peaks.md
- **Verified:** lib/check.sh: 254/254 checks passed (406 s). New checks: metrics.mjs pure append (2048/''/null/undefined), summary.mjs pure report (1500 vs 2500, no section when none, no summary.json key), demo every row mem_peak_mb == 2, bare run all null, leftover run's report.md and `harness report leftover` list `- A · claude-sonnet-5-5 · 6144 MB` once. Pure checks watched failing first.
- **Tests:** 249 → 254
- **Dead end:** `grep -qxF "- A · …"` in a check — a pattern starting with '-' is read as an option: use -e
- **Dead end:** `"$H" report leftover | grep -q …` in a check — under pipefail grep -q's early exit SIGPIPEs the producer and the pipeline fails; capture into a variable first
- **Dead end:** editing tests/run.sh while a suite run was going — bash reads the script as it runs: the run goes wrong; stop it and rerun
- **Discovery** (affects L1-08): report.md's peaks section is `### Memory peaks over 2 GB` (not the plan's `##`): it nests under the run's `## <run> · <project>` heading. `harness report` now also writes $STATE/metrics.jsonl (a copy) beside $STATE/summary.json.
- *04-L1-04 · claude-opus-5-5*

### 2026-10-25 13:35 · L1-03 · passes

session() runs every claude session (init, coding, verify, retro) as timeout -k 30s SESSION_TIMEOUT inside scope harness-<run>-s<n> (5G/6G/1G, n from state/scope-seq), stops the scope after it returns, notes leftovers and cap kills; one probe per segment notes 'no user systemd'; exit 137 now spends the attempt. Tests 243 → 249.

- **Files:** lib/driver.sh, lib/config.sh, lib/scope.sh, lib/metrics.mjs, tests/run.sh, tests/stub-claude.sh, templates/user/config.sh, docs/architecture.md, journal/decisions/2026-10-25-scoped-sessions.md
- **Verified:** 6 new checks written first and seen failing (5 red, the no-note one trivially green), then lib/check.sh green: 249/249 in 405 s. Real check: systemd-run --description works on this box (Description=harness-test-<pid>-desc), no harness-test-* unit left.
- **Tests:** 243 → 249
- **Dead end:** noting the retro's leftovers inside session() — restrict nothing reverts harness-log.md after a retro; its notes are deferred (S_NOTES) until after restrict
- **Discovery** (affects L1-04): session() sets S_PEAK (scope_peak MB, empty when uncapped) and S_NOTES; who is its 4th argument (initializer, <id>, verify <m>, retro). L1-04 passes $S_PEAK to MET append.
- **Discovery** (affects L1-05, L2): scope_run now passes --description=<unit>: without it systemd made each session's whole prompt the unit's Description (user journal, systemctl status, list-units). The list-units fixture was captured without it, so its description column is the old command-line shape.
- **Discovery** (affects L1-08): Review leftovers (Minor/Important, not built): the cap note needs exit 137, so an OOM kill of a child (a build the agent ran) with claude exiting 0 goes unnoted, memory.events oom_kill would catch it; a 137 under the cap and under SESSION_TIMEOUT (oomd, global OOM) spends the attempt silently; summary.mjs labels only 124 as timeout; TasksCurrent counts threads, so one node leftover reads as ~10 'process(es)'; scope_bytes rejects decimal sizes like 6.5G; a leftover note on a fully committed session makes a WIP commit holding only harness-log.md.
- **Discovery** (affects L1-05, L1-08): A check.sh run inside a session starts its own scope (L1-05) in app.slice, i.e. outside the session's scope: the suite's memory won't count against the session's 6G cap.
- **Proposed change:** L1-08 should take the review leftovers in discoveries (cap note via memory.events oom_kill, a note for 137 below the cap, summary.mjs 137 label, decimal sizes, WIP commit for a note-only change)
- *03-L1-03 · claude-opus-5-5*

### 2026-10-25 13:05 · L1-02 · passes

lib/scope.sh (scope_available/unit/bytes/run/stop/peak/left/capped; peak read by a wrapper inside the scope, OOMPolicy=continue, bare fallback that never runs a command twice), stubs tests/stub-systemd-run.sh + stub-systemctl.sh over the real fixtures, 7 checks incl. one real 64M scope (137, peak 64, no unit left), decision file. Tests 236 → 243.

- **Files:** lib/scope.sh, tests/stub-systemd-run.sh, tests/stub-systemctl.sh, tests/run.sh, bin/harness, docs/architecture.md, journal/decisions/2026-10-25-scoped-sessions.md
- **Verified:** 7 new checks watched failing (0/6, then the not-writable one against the old wrapper), then passing; full suite via lib/check.sh 243/243 green in 376 s; systemctl --user list-units 'harness-test-*' empty after; bash -n on every touched shell file. An Opus review of the diff found 1 Important (a command could run twice when scratch is unwritable), fixed with a check, plus stub fidelity fixes.
- **Tests:** 236 → 243
- **Dead end:** running the full suite in the background while still editing tests/run.sh — bash reads the script as it runs it: the run died on a syntax error at the edit point; rerun on the final tree
- **Discovery** (affects L1-03, L1-04, L2): Stub state: stub-systemd-run.sh clears $STUB_DIR/scope/<unit>.* at each start and holds <unit>.running while the command runs; stub-systemctl.sh treats a unit as alive only while .running exists or a pid in <unit>.pids is alive and not a zombie (a real scope is collected once empty). stub claude's STUB_OOM must touch <unit>.oom from inside the command (after the start), and STUB_LEAVE_PROCESS appends to <unit>.pids.
- **Discovery** (affects L1-03, L1-05, L1-06): sd_with/sd_count (tests/run.sh, in the scope.sh block) parse $T/systemd.log; the suite exports HARNESS_SYSTEMD_RUN/SYSTEMCTL/MEMINFO/MEM_POLL and unsets HARNESS_SCOPE_PREFIX and SCOPE_OK; bin/harness already passes all four overrides to the tmux-started driver (done here, ahead of L1-03 step 7).
- **Discovery** (affects L1-03, L1-08): scope_capped is peak >= cap only; page cache counts in MemoryPeak, so L1-03 must pair it with exit 137 before noting a cap kill. The probe can pass on a box whose user manager has no memory controller delegated (caps silently ignored); this box has it (the real check sees 137 at 64M).
- **Discovery** (affects L1-03, L1-05): scope_run's bare fallback covers any systemd-run failure, including a unit name still held by a crashed segment's scope: L1-03's per-run scope-seq avoids reuse; L1-05's check-<pid> could collide only on pid reuse while an old scope still holds leftovers.
- **Proposed change:** L1-02 step 6 should read 'MemoryMax=64M, no MemoryHigh, SESSION_SWAP_MAX=0, outer timeout 30s' (plan §13: 48M/64M throttles for minutes instead of killing); the check is built that way and also asserts scope_peak = 64 and scope_capped.
- **Proposed change:** L1-02 step 3: the logged argv also carries -p OOMPolicy=continue and the wrapper (bash -c <wrap> _ <unit> <dir> <systemctl>) before the command; the check compares the first 16 lines exactly and the command's last 3.
- *02-L1-02 · claude-opus-5-5*

## Older entries (in full in progress-archive.md)

- 2026-10-25 12:23 · L1-01 · passes · Wrote docs/plans/2026-10-25-L1-capped-sessions.md (scope.sh API, unit names, in-scope wrapper and ti… ([in full](progress-archive.md))
- 2026-10-25 12:05 · init · passes · 25 features: L1 8 (plan, scope.sh, scoped sessions, peaks, capped suites, memory gate, strict MCP + … ([in full](progress-archive.md))
