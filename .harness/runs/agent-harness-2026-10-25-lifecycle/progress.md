<!-- harness: rendered from entries.jsonl after every session; edits here are overwritten -->
# Progress — run `agent-harness-2026-10-25-lifecycle` (agent-harness)

What this file is: the run's journal, rendered from `entries.jsonl` after every session, newest entry first (the full record is `progress-archive.md`; the driver's own notes are `harness-log.md`). Each entry says what one session did, what passed, what it found (discoveries) and what it needs from you (questions).

The spec is `docs/specs/2026-10-25-resource-lifecycle.md`: everything a run starts is capped by a systemd user scope and stopped when the run stops. Milestones: L1 capped sessions and suites · L2 run services, teardown hook, stop points · L3 scratch and tmux cleanup · L4 `harness gc` fixes (`--all-merged`, R9, `--deps`, the runner's gc) · L5 `MAX_PARALLEL_RUNS` reload (optional, last). L2 waits for L1; L3, L4 and L5 are independent, so a stuck feature in one never blocks the others. Each verified milestone merges into `main` by itself.

How to read the feature list: `feature_list.json` lists features in priority order; `passes` is the session's claim, the verify entry for a milestone is what counts. Steps are the checks a verifier re-runs. A build feature writes its decision file under `journal/decisions/`, its checks in `tests/run.sh` first, and its `docs/architecture.md` and `README.md` lines.

To steer: edit `INBOX.md` on this branch (GitHub app). Line 1 `status: pause` or `status: stop` takes effect before the next session; answers go under `## Answers`. Sessions never park on this run (the brief): they take the spec's default and record it in the decision file, so the questions below are for after the run.

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

### 2026-10-25 12:23 · L1-01 · passes

Wrote docs/plans/2026-10-25-L1-capped-sessions.md (scope.sh API, unit names, in-scope wrapper and timeout placement, stub contract, config keys, exact notes, 24 named checks) and captured 8 real fixtures (systemctl show/list-units/stop, no-bus, meminfo). Probes found three things the spec missed: an emptied scope vanishes, OOMPolicy=stop kills the wrapper, MemoryHigh near MemoryMax stalls.

- **Files:** docs/plans/2026-10-25-L1-capped-sessions.md, tests/fixtures/systemctl-show-scope.txt, tests/fixtures/systemctl-show-scope-clean.txt, tests/fixtures/systemctl-show-scope-oom.txt, tests/fixtures/systemctl-show-gone.txt, tests/fixtures/systemctl-list-units.txt, tests/fixtures/systemctl-stop-missing.txt, tests/fixtures/systemd-no-bus.txt, tests/fixtures/meminfo.txt
- **Verified:** check.sh full run: 236/236 green in 376 s (tests/run.sh untouched). Real probes on harness-test-<pid>-* scopes (64M), each stopped; `systemctl --user list-units 'harness-*' --plain --no-legend` prints nothing afterwards. claude --help (2.1.310) has both MCP flags.
- **Tests:** 236 → 236
- **Dead end:** a real scope with MemoryHigh=48M MemoryMax=64M MemorySwapMax=0 around a 256 MB node allocation — it stalled for over 2 minutes under memory.high throttling (high events 1821, oom_kill 0) and had to be stopped by hand; MemoryMax alone kills it with 137 in ~80 ms
- **Dead end:** reading MemoryPeak with systemctl show after the command returns — a --collect scope with no processes left is gone at once: show prints MemoryPeak=[not set]; the plan reads it from a wrapper inside the scope
- **Dead end:** the in-scope wrapper with systemd's default OOMPolicy=stop — an OOM kill stops the whole scope, the wrapper dies with 143 and records nothing; -p OOMPolicy=continue keeps it and passes 137 on
- **Discovery** (affects L1-02, L1-03, L1-04): scope_run must pass -p OOMPolicy=continue and run the command under an in-scope wrapper that writes `systemctl --user show -p MemoryPeak,ControlGroup,TasksCurrent` to <scratch>/scopes/<unit>.show before exiting; leftovers = TasksCurrent - 2 (the wrapper's bash and its systemctl). Plan §2.
- **Discovery** (affects L1-02): The L1-02 real-scope check must not set MemoryHigh (it stalls instead of killing) and needs SESSION_SWAP_MAX=0 (with 1G swap a 256 MB allocation survives) and an outer timeout 30s. Plan §10, §13.
- **Discovery** (affects L1-03, L1-05): timeout -k 30s goes inside the scope, around claude or the suite: outside it would signal the wrapper's bash and leave claude alive. GNU timeout exits 137 (not 124) when -k had to KILL, so check.sh calls 137 after >= CHECK_TIMEOUT a timeout, not the cap.
- **Discovery** (affects L1-03): metrics.mjs environmental() treats an exit 137 with no result under 120 s as environmental (attempt given back); L1-03 must return null for 137 like 124 so a cap kill spends the attempt.
- **Discovery** (affects L1-02, L1-06): tests/run.sh must export HARNESS_MEMINFO to the real fixture (9 GB) and HARNESS_MEM_POLL=1 globally, or the box's real memory could gate every suite session for 30 min; and unset HARNESS_SCOPE_PREFIX inherited from the outer session.
- **Discovery** (affects L1-02, L1-03, L2): systemctl --user stop of a unit already gone exits 5 ('Unit … not loaded.'); scope_stop treats 5 as done, and the stub mirrors it (exit 0 only for a live unit).
- **Question for Michael:** D5 default: the deepEqual line goes in prompts/parts/rules.md as the spec says, but that part renders only when a project has CLAUDE.md. Move it to prompts/coding.md §2 next to Test-driven instead?
- **Question for Michael:** D6 default: suites get no MemoryHigh (only CHECK_MEMORY_MAX=3G) so a runaway test dies at once; sessions keep MemoryHigh=5G under MemoryMax=6G, which throttles (can stall up to SESSION_TIMEOUT) before killing. Keep the session gap?
- **Proposed change:** L1-02 step 6: drop MemoryHigh=48M from the real-scope check; run it with SESSION_SWAP_MAX=0 under timeout 30s (plan §10, §13)
- **Proposed change:** L1-02 step 3: -p OOMPolicy=continue and the wrapper (bash -c <wrap> _ <unit> <dir> <systemctl>) sit between -p MemorySwapMax and the command; check parts, not adjacency
- **Proposed change:** L1-03 step 5 needs environmental() in lib/metrics.mjs to return null for exit 137
- **Proposed change:** L1-04 step 3: report() needs metrics.jsonl beside summary.json as its second input
- **Proposed change:** L1-01 step 2 says stub-systemctl exits 0 for stop; the plan's stub exits 5 for a unit already gone, as the real command does
- *01-L1-01 · claude-opus-5-5*

### 2026-10-25 12:05 · init · passes

25 features: L1 8 (plan, scope.sh, scoped sessions, peaks, capped suites, memory gate, strict MCP + prompt line, review), L2 6 (plan, svc scope, teardown + trap, stop points, gc units + status, review), L3 5 (plan, scratch, tmux window, reaper, review), L4 5 (all-merged, removal, --deps, runner gc, review), L5 1 (config reload, optional). L2 after L1; L3, L4, L5 independent.

- **Discovery** (affects run): Real-command shapes to copy into fixtures (captured 2026-10-25 on this box, systemd 255): `systemctl --user show -p MemoryPeak,ControlGroup harness-test-<pid>-probe.scope` printed `ControlGroup=/user.slice/user-1000.slice/user@1000.service/app.slice/harness-test-<pid>-probe.scope` then `MemoryPeak=262144`: systemd prints properties in its own order, not the asked order, so parse by key, never by line number. `systemctl --user list-units 'harness-*' --plain --no-legend` prints nothing when none exist. The probe `systemd-run --user --scope --collect --quiet --unit=harness-test-<pid>-probe -p MemoryMax=64M true` exits 0 here.
- **Discovery** (affects L1-07, L1-01): `claude --help` (installed CLI, 2026-10-25) has both flags: `--mcp-config <configs...> Load MCP servers from JSON files or ...` and `--strict-mcp-config Only use MCP servers from --mcp-config, ...`. Quote the real lines in the L1-07 decision file.
- **Discovery** (affects run): bin/harness passes HARNESS_* overrides to the tmux-started driver window from an explicit list (bin/harness, cmd_start, the `for v in HARNESS_CLAUDE HARNESS_GH ...` loop). Every new override the suite relies on (HARNESS_SYSTEMD_RUN, HARNESS_SYSTEMCTL, HARNESS_MEMINFO, HARNESS_MEM_POLL) must be added there, or a tmux-started run silently uses the real commands.
- **Discovery** (affects L3): The supervisor window runs bare `claude` (bin/harness, cmd_start, `tmux new-window ... -n supervisor`), not $HARNESS_CLAUDE. An L3 check that needs a supervisor window on the private tmux server must put a `claude` shim on PATH pointing at tests/stub-claude.sh (the stub's interactive mode already handles no `-p`). Every existing suite run uses --foreground, so no test starts a tmux session for a run yet.
- **Discovery** (affects L2): lib/driver.sh: the one EXIT trap (near `echo $$ > "$STATE/driver.pid"`) writes `ended` and removes driver.pid; finish() ends with `exit 0`, so the trap runs after finish too: services_down must be idempotent (finish's call and the trap's call must give one `services stopped` note). `note` writes harness-log.md (committed), `log` only run.log.
- **Discovery** (affects L1-05, L3-02): lib/check.sh is called both by the driver (run_init, green) and by sessions ({{CHECK}} in prompts); it reads only HARNESS_* env vars (HARNESS_CHECK_CMD, HARNESS_SCRATCH, HARNESS_CHECK_CACHE) exported by prompt_env in lib/prompt.sh. New inputs for it (scope prefix, cap, timeout) go through prompt_env the same way.
- **Discovery** (affects run): tests/run.sh: `check "<name>" '<bash expr>'` evals its second argument; stubs log calls to $STUB_DIR (= $T) files with `===` separators (see curl_with/curl_last helpers for the parsing pattern); the suite already runs on a private tmux server (TMUX_TMPDIR=$T/tmux, HARNESS_DESK_SESSION=h-desk-test-$$) and kills it in its EXIT trap. 235 checks today; the full suite takes about 6 minutes here. Run a single new check while iterating by copying its lines into a scratch script, not by editing the suite's flow.
- **Discovery** (affects L2-05, L3-04, L4): cmd_gc in bin/harness already has `act` (dry-run prints `would: ...`, else `+ ...` and runs it), `running` (live driver or queued continuation) and `desk_open` helpers: reuse them for the unit stop (L2-05), the tmux reap (L3-04) and --deps (L4-03). The existing gc test (run 1, `harness gc proj` after demo) is the place new gc checks follow.
- **Discovery** (affects run): Config keys: defaults live in harness_config in lib/config.sh (one assignment block), the user's commented copy in templates/user/config.sh, and docs/architecture.md §10 lists every key with its default. Add every new key in all three places in the feature that introduces it.
- **Discovery** (affects L3-04, L4-04, L5-01): lib/queue.sh's exit path (after the while loop: `started=$(grep -lsx -- "$RID" "$STATE_ROOT"/*/*/runners | wc -l)`) is where L3-04's reap and L4-04's gc go, before `setsid -f "$H" debrief`. The runner's whole body is one `{ ... }` block parsed before it runs, because lib/sync.sh may rewrite the file underneath; keep new code inside that block.
- **Discovery** (affects L4-01): git 2.43 here: `git for-each-ref 'refs/heads/*'` lists only branches without a `/`; the trailing-slash prefix `refs/heads/` lists all. The suite's fake origin is $T/origin.git (bare), reached through an insteadOf rewrite of git@github.com:test/proj.git.
- **Discovery** (affects L1-02, L1-06, L2-01): Never start a real scope in the suite other than harness-test-<pid>-* with MemoryMax 64M or less, stopped in the check's own cleanup; the memory-gate fixture is a real /proc/meminfo copy with only its MemAvailable line rewritten for the low case (say so in the decision file).
- **Question for Michael:** L5 (runner config reload) is the last feature and optional per the brief; it is dropped by not being reached. Say in INBOX.md if it should be skipped outright.
- **Question for Michael:** HARNESS_CACHE defaults to ${XDG_CACHE_HOME:-~/.cache}/harness/<project>, kept across runs and boots; the spec's ~/.cache/harness/<project> is the same with XDG_CACHE_HOME unset. Change it in config if another place is wanted.
- **Question for Michael:** The memory-gate fixture is a copy of this box's /proc/meminfo with only MemAvailable edited to 2 GB for the low case (the box can't be made low during the suite); the unedited copy covers the high case. Say if a different fixture is wanted.
- *00-init · claude-fable-5-1*
