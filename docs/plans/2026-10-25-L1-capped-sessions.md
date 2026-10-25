Milestone base: 4bd336fbac6c3c94b3a1b2f23de7e7cd53968f44

# L1 · Sessions and suites run capped (plan)

Spec: `docs/specs/2026-10-25-resource-lifecycle.md` §L1. This plan fixes the interfaces so L1-02 … L1-07 each build one
thing and L1-08 reviews from the base above. Build-only: the suite reaches `systemd-run`/`systemctl` only through the
stubs, except the one real-scope check of §10. Builders: L1-02 = §1, §2, §4, §5, §6 · L1-03 = §3, §7 (session keys),
§8.1, §9.1 · L1-04 = §9.2 · L1-05 = §3, §7 (check keys), §8.2, §9.3 · L1-06 = §1 (`mem_available_gb`, `dur_s`), §7
(memory keys), §8.3, §9.4 · L1-07 = §9.5, §11. Checks in §10. Defaults this plan takes for Michael in §12; what the
probes changed against the feature list in §13.

## 0. What is there today (base 4bd336f)

- `session()` (`lib/driver.sh:172`) runs `timeout "$SESSION_TIMEOUT" "$CLAUDE" -p … > "$3" 2>&1` (`:179`): wall
  time only, SIGTERM only, nothing stops what the session backgrounded. It is called by the initializer (`:548`),
  coding (`:607`), verify (`:334`) and the retro (`:407`).
- `lib/check.sh` runs the subset form bare at `:14` (`bash -c "$cmd \"\$@\"" _ "$@"`) and the full suite at `:21`
  (`bash -c "$cmd" > "$scratch/check.out"`), no memory or time limit. Its RED line is at `:27`.
- `MET append` (`lib/metrics.mjs:125`) takes 11 arguments: `session out run kind feature model passes wall exit env
  role`. `environmental()` (`:109`) returns null for exit 124 only; an exit 137 with no result under 120 s reads as
  `no result after <n> s`, i.e. environmental (the attempt is given back).
- `report(s)` (`lib/summary.mjs:225`) reads `summary.json` only.
- `bin/harness:175` passes HARNESS_* overrides to the tmux-started driver from an explicit list.
- The driver numbers coding sessions with `n` (`:599`), which restarts every segment; logs are `NN-<id>.jsonl`,
  `HHMMSS-verify-<m>.jsonl`, `00-init.jsonl`, `zz-retro-HHMMSS.jsonl`.

## 1. `lib/scope.sh` (sourced; L1-02)

Usage header: `# Usage: source lib/scope.sh; scope_run <unit> <mem-high> <mem-max> <cmd…> · scope_stop <unit> ·
scope_peak <unit> · scope_left <unit> · scope_capped <unit> <mem-max> · scope_unit <run> <role> · mem_available_gb
[<meminfo>] · dur_s <duration>`. Commands: `SYSTEMD_RUN=${HARNESS_SYSTEMD_RUN:-systemd-run}`,
`SYSTEMCTL=${HARNESS_SYSTEMCTL:-systemctl}`, read at call time (the suite swaps them per check).

| Function | Does | Prints / returns |
|---|---|---|
| `scope_available` | the probe `$SYSTEMD_RUN --user --scope --quiet true` (stdout and stderr to /dev/null), once per process: the answer is cached in `SCOPE_OK` (`1`/`0`); unset `SCOPE_OK` to probe again | 0 when it works, 1 otherwise |
| `scope_unit <run> <role>` | `harness-<run>-<role>` with every character of `<run>` outside `[A-Za-z0-9_-]` replaced by `-` (`a.b/c d` → `harness-a-b-c-d-<role>`). Pure. | the unit name, no `.scope` |
| `scope_run <unit> <high> <max> <cmd…>` | when `scope_available`: `$SYSTEMD_RUN --user --scope --collect --quiet --unit=<unit> [-p MemoryHigh=<high>] -p MemoryMax=<max> -p MemorySwapMax=${SESSION_SWAP_MAX:-1G} -p OOMPolicy=continue bash -c "$SCOPE_WRAP" _ <unit> <dir> "$SYSTEMCTL" <cmd…>`; an empty `<high>` leaves the `MemoryHigh` property out. Otherwise `<cmd…>` bare. stdin/stdout/stderr are the caller's (systemd-run `--scope` execs the command, so `> file` works). | the command's exit code |
| `scope_stop <unit>` | `$SYSTEMCTL --user stop <unit>.scope`; exit 5 (`Unit … not loaded.`, the scope was already gone) counts as done; stderr to /dev/null. No-op (0) when the probe failed. | 0, or systemctl's other exit |
| `scope_peak <unit>` | `MemoryPeak` of `<dir>/<unit>.show` (written by the wrapper, §2), or, when that file is missing, of a live `$SYSTEMCTL --user show -p MemoryPeak <unit>.scope`; parsed **by key**, never by line; bytes → whole MB, rounded (`(b + 524288) / 1048576`). | the MB; nothing and exit 1 when uncapped, gone or `[not set]` |
| `scope_left <unit>` | `TasksCurrent` from the same `.show`, minus 2 (the wrapper's bash and its `systemctl show`), floored at 0 | the count (0 when unknown) |
| `scope_capped <unit> <max>` | `MemoryPeak` in bytes ≥ `$(scope_bytes <max>)` | exit 0 when the cap was reached |
| `scope_bytes <size>` | `6G` → 6442450944; K/M/G/T suffixes (1024-based, as systemd reads them), bare number = bytes. Pure. | bytes |
| `mem_available_gb [<file>]` | `MemAvailable` (kB) of `${1:-${HARNESS_MEMINFO:-/proc/meminfo}}`, floored to whole GB (`kB / 1048576`). Pure on its file. The real fixture (`MemAvailable: 10341868 kB`) prints `9`. | GB; exit 1 when the line is missing |
| `dur_s <d>` | `30m` → 1800, `2s` → 2, `1h` → 3600, `90` → 90 (the suffixes `timeout(1)` takes: s m h d). Pure. | seconds |

`<dir>` is `${HARNESS_SCRATCH:-${TMPDIR:-/tmp}}/scopes` (created by `scope_run`). `.show` and `.started` files
there are per unit; `scope_run` removes stale ones for its unit before it starts. Nothing of a scope persists past
its run (L3 deletes scratch).

**The probe and its note.** The driver probes once at start-up, right after `harness_config` (one driver process =
one segment), and when it fails notes `no user systemd: sessions and suites run uncapped` exactly once. `check.sh` is
its own process and probes for itself (about 20 ms); it prints nothing extra when uncapped.

**systemd-run fails after a good probe** (the bus went away): the wrapper's first act is `touch <dir>/<unit>.started`.
If `scope_run` returns and `.started` is missing, nothing ran: it prints `scope_run: systemd-run failed (exit <rc>);
running bare` on stderr and runs `<cmd…>` bare, returning its exit. The driver's session log shows that line.

### 1a. Unit names

`harness-<run>-<role>[-<n>]`, the run id reduced to `[A-Za-z0-9_-]` by `scope_unit` (systemd unit-name rules; `.` is
legal in unit names but would make `harness-<run>-*` globs ambiguous with dotted run ids, so it goes too):

| Unit | Holds | Started by |
|---|---|---|
| `harness-<run>-s<n>.scope` | one `claude` session; `<n>` from `$STATE/scope-seq` (§3) | `session()` (L1-03) |
| `harness-<run>-check-<pid>.scope` | one `check.sh` run, full or subset; `<pid>` = check.sh's `$$` | `check.sh` (L1-05) |
| `harness-<run>-svc.scope` | the run's services (`INIT_CMD` and what it backgrounds) | `run_init` (L2) |
| `harness-test-<pid>-<name>.scope` | the suite's one real scope (§10), 64M at most, stopped in the check | `tests/run.sh` only |

## 2. The wrapper inside the scope, and why

```bash
SCOPE_WRAP='touch "$2/$1.started"; "${@:4}"; rc=$?; "$3" --user show -p MemoryPeak,ControlGroup,TasksCurrent "$1.scope" > "$2/$1.show" 2> /dev/null; exit $rc'
```

Found by probing the real commands on this box (2026-10-25, systemd 255; §6 has the captures):
- **A scope whose processes have all exited is gone at once** (`--collect`): `show` then prints `ControlGroup=`,
  `MemoryPeak=[not set]`, `TasksCurrent=[not set]` (exit 0). So the peak must be read *from inside*, while the
  wrapper still holds the scope. Read from the wrapper, a scope with nothing left reports `TasksCurrent=2` (the
  wrapper's bash and the `systemctl` it runs); one with a background `sleep` left reports 3. Hence `scope_left` =
  TasksCurrent − 2. TasksCurrent counts tasks (threads too): a leftover `node` counts its threads. The note says
  "process(es)"; the number is systemd's, and what matters is that it is not 0.
- **`OOMPolicy=stop` is the transient scope's default**: on an OOM kill systemd stops the whole scope, the wrapper
  dies with SIGTERM (exit 143) and nothing is recorded. With `-p OOMPolicy=continue` only the kernel's victim dies;
  the wrapper records `MemoryPeak=67108864` (= MemoryMax 64M exactly) and passes the exit on: 137.
- **`MemoryHigh` close under `MemoryMax` stalls instead of killing.** 48M/64M with swap 0 around a 256 MB allocation
  ran over two minutes, throttled (`memory.events high 1821`, `oom_kill 0`, MemoryCurrent 62.8M), until stopped by
  hand. With `MemoryMax=64M` alone it died with 137 in 70–80 ms. Sessions keep the spec's 5G/6G (a 1G gap, and swap
  1G: a session slows before it dies, `SESSION_TIMEOUT` bounds the stall); suites have no `MemoryHigh` (§3); the real
  check uses none (§10, §13).
- `systemctl --user stop` of a unit that isn't loaded prints `Failed to stop <u>.scope: Unit <u>.scope not loaded.`
  and exits 5; the no-bus failure prints `Failed to connect to bus: No medium found` and exits 1 (both commands).

## 3. Where `timeout -k 30s` sits: inside the scope, around the command

```
session: scope_run harness-<run>-s<n> 5G 6G   timeout -k 30s "$SESSION_TIMEOUT"   "$CLAUDE" -p … 
check:   scope_run harness-<run>-check-<pid> "" 3G   timeout -k 30s "$CHECK_TIMEOUT"   bash -c "$cmd" [_ "$@"]
```

So the argv the stub records is `systemd-run --user --scope … -p OOMPolicy=continue bash -c <wrap> _ <unit> <dir>
<systemctl> timeout -k 30s 100m <claude> -p …`. Inside, because `timeout` outside `systemd-run` would signal the
wrapper's bash, not `claude`: bash dies on SIGTERM, `claude` lives on in the scope and nothing is recorded. Inside,
`timeout` signals `claude` directly, the wrapper survives to write `.show`, and exit 124 (and 137 after `-k`) reach the
driver unchanged, so the timeout guard (`environmental()` returns null for 124) holds. Bare (no systemd), the same
`timeout -k 30s …` line runs without the scope.

The **session number** `<n>` is a per-run sequence in `$STATE/scope-seq`, bumped by `session()` for every session of
any kind (init = s1 in a fresh run), so a resumed segment never reuses a unit name a crashed one may have left.

## 4. Config keys (L1-03, L1-05, L1-06)

| Key | Default | Used by | Feature |
|---|---|---|---|
| `SESSION_MEMORY_HIGH` | `5G` | `session()`: `MemoryHigh` (throttles above it) | L1-03 |
| `SESSION_MEMORY_MAX` | `6G` | `session()`: `MemoryMax` (OOM-kill at it) | L1-03 |
| `SESSION_SWAP_MAX` | `1G` | `scope_run`: `MemorySwapMax`, every scope | L1-03 |
| `CHECK_MEMORY_MAX` | `3G` | `check.sh` via `HARNESS_CHECK_MEMORY_MAX` | L1-05 |
| `CHECK_TIMEOUT` | `15m` | `check.sh` via `HARNESS_CHECK_TIMEOUT` | L1-05 |
| `MEM_MIN_AVAILABLE_GB` | `5` | `mem_gate` | L1-06 |
| `MEM_WAIT_MAX` | `30m` | `mem_gate` (`dur_s`) | L1-06 |

Each goes into `harness_config`'s assignment block (`lib/config.sh:13`, beside `SESSION_TIMEOUT`), commented with one
line in `templates/user/config.sh`, and into `docs/architecture.md` §10, in the feature that introduces it.
`SESSION_SWAP_MAX` reaches `check.sh` unset, so suites get `scope_run`'s 1G default.

Exports. `prompt_env` (`lib/prompt.sh:15`) adds `HARNESS_SCOPE_PREFIX=$(scope_unit "$RUN_ID")` (no role: the prefix
`harness-<sanitised run>`; `scope_unit <run> ""` drops the trailing `-`), `HARNESS_CHECK_MEMORY_MAX=$CHECK_MEMORY_MAX`
and `HARNESS_CHECK_TIMEOUT=$CHECK_TIMEOUT` (L1-05). `check.sh` defaults them to empty (bare), 3G and 15m.
Test-only overrides: `HARNESS_SYSTEMD_RUN`, `HARNESS_SYSTEMCTL` (L1-02/03), `HARNESS_MEMINFO`, `HARNESS_MEM_POLL`
(seconds between memory polls, default 300; L1-06). Each one goes into `bin/harness`'s pass-through list (`:175`) in
the feature that first relies on it, or a tmux-started run silently uses the real commands.

## 5. The stub contract (L1-02)

Two stubs, `tests/stub-systemd-run.sh` and `tests/stub-systemctl.sh`, each with a usage header like
`stub-claude.sh`'s. `tests/run.sh` exports `HARNESS_SYSTEMD_RUN=$HERE/stub-systemd-run.sh`,
`HARNESS_SYSTEMCTL=$HERE/stub-systemctl.sh`, `HARNESS_MEMINFO=$HERE/fixtures/meminfo.txt` and `HARNESS_MEM_POLL=1`
beside `HARNESS_CLAUDE` (`:11`), and `unset HARNESS_SCOPE_PREFIX` (a session running the suite inherits its own run's
prefix). The memory exports matter on their own: without them the box's real `/proc/meminfo` could gate every suite
session for 30 minutes.

**The log.** Every call of either stub appends to `$STUB_DIR/systemd.log`: the program name (`systemd-run` or
`systemctl`) on the first line, then each argument on its own line cut to its first line (`${a%%$'\n'*}`, so a
`-p "<prompt>"` shows as `# Coding session`), then `===`. `tests/run.sh` gains helpers in the style of `curl_with`:
`sd_with <text>` (the first call containing it), `sd_count <text>` (how many calls contain it), splitting on `===\n`.
The probe is logged too (`systemd-run`, `--user`, `--scope`, `--quiet`, `true`); a check that wants "no scoped call"
counts calls containing `--unit=`.

**Stub state** (what a real scope would hold), under `$STUB_DIR/scope/`: `<unit>.alive` while it "exists",
`<unit>.max` (MemoryMax in bytes), `<unit>.pids` (pids a stub session left), `<unit>.oom` (the session was "killed at
the cap").

`stub-systemd-run.sh`:
- `STUB_NO_SYSTEMD=1`: prints `fixtures/systemd-no-bus.txt` on stderr, exits 1, for every call (the probe too).
- Exactly `--user --scope --quiet true` (the probe): exit 0.
- Otherwise it reads options up to the first argument that isn't one (`--unit=<u>`; `-p K=V` takes two arguments;
  any other `--…` one), records `MemoryMax` as `<u>.max` (via the same suffix arithmetic as `scope_bytes`), touches
  `<u>.alive`, runs the command after the options with `STUB_SCOPE_UNIT=<u>` exported (so stub claude still runs, and
  knows its unit), removes `<u>.alive` afterwards unless a pid in `<u>.pids` is still alive (as the real scope goes
  when empty), and exits with the command's exit code.

`stub-systemctl.sh`:
- `STUB_NO_SYSTEMD=1`: `fixtures/systemd-no-bus.txt` on stderr, exit 1.
- `--user show -p <K1,K2,…> <u>.scope`: when `<u>.alive`, the lines of `fixtures/systemctl-show-scope.txt` whose key
  was asked, in the fixture's order (systemd's: ControlGroup, MemoryPeak, TasksCurrent; never the asked order), with
  the unit name in `ControlGroup` replaced by `<u>`, `TasksCurrent` set to 2 + the live pids of `<u>.pids`, and
  `MemoryPeak` set to `<u>.max` when `<u>.oom` exists, else `$STUB_MEM_PEAK` when set, else the fixture's
  (2404352 → 2 MB). When not alive: the asked lines of `fixtures/systemctl-show-gone.txt`. Exit 0 either way, as the
  real one.
- `--user list-units '<glob>' --plain --no-legend`: for each `<u>.alive` matching the glob, the fixture line of
  `fixtures/systemctl-list-units.txt` with its unit name replaced by `<u>`; nothing when none (the real empty answer).
  L2 builds on this.
- `--user stop <u>.scope`: when alive, `kill` the live pids of `<u>.pids`, remove the unit's state, exit 0; when not,
  `fixtures/systemctl-stop-missing.txt` (name replaced) on stderr, exit 5.

`stub-claude.sh` gains, for coding sessions:
- `STUB_LEAVE_PROCESS=1`: before exiting, `sleep 300 > /dev/null 2>&1 &` and append its pid to
  `$STUB_DIR/scope/$STUB_SCOPE_UNIT.pids` (when `STUB_SCOPE_UNIT` is set). The stub `stop` kills it; the suite's EXIT
  trap also kills every pid left in `$T/scope/*.pids`, so a failing check never leaks a sleep.
- `STUB_OOM=<id>`: that feature's first session touches `$STUB_DIR/scope/$STUB_SCOPE_UNIT.oom`, prints the
  `usage-tokens.jsonl` events without the `result` line (a killed CLI's stream is cut off) and exits 137.

## 6. The fixtures (captured 2026-10-25 on this box, systemd 255.4; real output, never typed)

All captures used units `harness-test-<pid>-*` with `MemoryMax=64M`; every one was stopped, and `systemctl --user
list-units 'harness-test-*' --plain --no-legend` printed nothing afterwards. `$W` is the §2 wrapper with
`systemctl` in place of `"$3"` and an output file in place of `"$2/$1.show"`.

| File | Captured with |
|---|---|
| `tests/fixtures/systemctl-show-scope.txt` | `systemd-run --user --scope --collect --quiet --unit=harness-test-1320299-left -p MemoryMax=64M -p MemorySwapMax=0 bash -c "$W" _ … bash -c 'sleep 300 > /dev/null 2>&1 & exit 0'`, i.e. `systemctl --user show -p MemoryPeak,ControlGroup,TasksCurrent harness-test-1320299-left.scope` from inside the live scope holding the background sleep: `ControlGroup=/user.slice/user-1000.slice/user@1000.service/app.slice/harness-test-1320299-left.scope`, `MemoryPeak=2404352`, `TasksCurrent=3` (systemd's order, not the asked order) |
| `tests/fixtures/systemctl-show-scope-clean.txt` | the same with `true` as the command: `TasksCurrent=2` (the wrapper and its systemctl), `MemoryPeak=1728512` |
| `tests/fixtures/systemctl-show-scope-oom.txt` | the same with `-p OOMPolicy=continue` around `timeout -k 30s 100m node -e '<256 × Buffer.alloc(1 MB)>'`: exit 137, `MemoryPeak=67108864`, `TasksCurrent=2` |
| `tests/fixtures/systemctl-show-gone.txt` | `systemctl --user show -p MemoryPeak,ControlGroup,TasksCurrent harness-test-1320299-left.scope` after `systemctl --user stop` of it: `ControlGroup=`, `MemoryPeak=[not set]`, `TasksCurrent=[not set]` |
| `tests/fixtures/systemctl-list-units.txt` | `systemctl --user list-units 'harness-*' --plain --no-legend` with the `-left` scope alive: one line, `harness-test-1320299-left.scope loaded active running /usr/bin/bash -c …` |
| `tests/fixtures/systemctl-stop-missing.txt` | `systemctl --user stop harness-test-1320842-none.scope` (never started): stderr, exit 5 |
| `tests/fixtures/systemd-no-bus.txt` | `env -u DBUS_SESSION_BUS_ADDRESS -u XDG_RUNTIME_DIR systemd-run --user --scope --quiet true` (and the same `systemctl --user stop x.scope`): stderr, exit 1 |
| `tests/fixtures/meminfo.txt` | `cat /proc/meminfo` (`MemAvailable: 10341868 kB` → 9 GB) |

## 7. Note texts, exactly (L1-03 … L1-06)

`<who>` is the feature id for a coding session, `verify <m>`, `initializer` or `retro`. `session()` gains it as a 4th
argument.

| Feature | Where | Text |
|---|---|---|
| L1-03 | start-up, once per segment, when `scope_available` fails | `no user systemd: sessions and suites run uncapped` |
| L1-03 | after a session whose `scope_left` > 0 | `<kind> session left <n> process(es) running; stopped with its scope` (`<kind>` = `coding`, `verify`, `init`, `retro`) |
| L1-03 | exit 137 and `scope_capped <unit> "$SESSION_MEMORY_MAX"` | `<who>: the session hit its memory cap (<SESSION_MEMORY_MAX as configured, e.g. 6G>)` |
| L1-04 | none (`metrics.jsonl` and `report.md` carry it) | — |
| L1-05 | `check.sh` output (the session and `init.out` read it), not a note | exit 124, or 137 after ≥ `CHECK_TIMEOUT`: `check: RED (timed out after <CHECK_TIMEOUT>, exit <rc> after <n> s) — last lines of <file>:` · exit 137 otherwise, scoped: `check: RED (killed at its <CHECK_MEMORY_MAX> memory cap, exit 137 after <n> s) — last lines of <file>:` · anything else, as today: `check: RED (exit <rc> after <n> s) — last lines of <file>:` |
| L1-06 | `mem_gate`, under the threshold | `memory: <n> GB available, under MEM_MIN_AVAILABLE_GB=<min>; waiting up to <MEM_WAIT_MAX>` |
| L1-06 | `mem_gate`, back over it while waiting | `memory: <n> GB available after <s> s; starting the session` |
| L1-06 | `mem_gate`, still under after `MEM_WAIT_MAX` | `memory still at <n> GB after <MEM_WAIT_MAX>; starting the session anyway (its cap protects the box)` |

The timed-out rule needs the elapsed time because GNU `timeout -k` exits 137, not 124, when the command ignored the
TERM: a hung suite killed after 15m30s must not read as the memory cap.

## 8. The builders' hooks

### 8.1 `session()` (L1-03)

```bash
session() {   # kind model log who → claude headless in its own capped scope; sets S_EXIT, S_WALL, S_PEAK
  … (as today, up to the settings array)
  local seq unit; seq=$(( $(cat "$STATE/scope-seq" 2> /dev/null || echo 0) + 1 )); echo "$seq" > "$STATE/scope-seq"
  unit=$(scope_unit "$RUN_ID" "s$seq")
  scope_run "$unit" "$SESSION_MEMORY_HIGH" "$SESSION_MEMORY_MAX" timeout -k 30s "$SESSION_TIMEOUT" "$CLAUDE" -p … > "$3" 2>&1
  S_EXIT=$? S_WALL=…; S_PEAK=$(scope_peak "$unit"); local left; left=$(scope_left "$unit"); scope_stop "$unit"
  (( left > 0 )) && note "$1 session left $left process(es) running; stopped with its scope"
  (( S_EXIT == 137 )) && scope_capped "$unit" "$SESSION_MEMORY_MAX" && note "$4: the session hit its memory cap ($SESSION_MEMORY_MAX)"
  … (usage, the log line unchanged: `  <kind> exit <rc> · <commit>`)
}
```

`environmental()` returns null for exit 137 as for 124 (`lib/metrics.mjs:111`): a session killed at its cap is the
feature's attempt, not the environment's. `lib/driver.sh` sources `lib/scope.sh` beside `lib/prompt.sh`.

### 8.2 `check.sh` (L1-05)

Sources `$here/scope.sh`. One function runs the command, for both forms:
`u=${HARNESS_SCOPE_PREFIX:+$HARNESS_SCOPE_PREFIX-check-$$}`; with `u`: `scope_run "$u" "" "$max" timeout -k 30s
"$to" bash -c …; rc=$?; scope_stop "$u"`; without: the same `timeout … bash -c …` bare. The subset form stays
uncached; the full form keeps its cache. The RED line of §7 replaces `:27`'s.

### 8.3 `mem_gate <who>` (L1-06)

In `lib/driver.sh`, called right before `session` for init, coding and verify (not the retro: the run is ending).
`gb=$(mem_available_gb)` (missing line → no gate); under `MEM_MIN_AVAILABLE_GB`: the first note, `services_down
memory` (a no-op `services_down() { :; }` defined in L1-06 unless one exists; L2 replaces it), then poll every
`${HARNESS_MEM_POLL:-300}` s until `dur_s "$MEM_WAIT_MAX"` has passed, with the second or third note.

## 9. What each feature records

1. **L1-03**: `bin/harness:175` gains `HARNESS_SYSTEMD_RUN HARNESS_SYSTEMCTL`; `docs/architecture.md` §7 gains the
   session-scope guard row (`SESSION_MEMORY_MAX` reached → exit 137, the note, an attempt spent; leftovers stopped).
2. **L1-04**: `MET append` takes a 12th argument `<mem_peak_mb>` (`""` or `null` → `null`, else `Number`) and
   writes `mem_peak_mb` on every line; every `MET append` call (init `:555`, coding `:617`, `:638`, verify `:341`,
   `:348`, retro `:412`) passes `"$S_PEAK"`. `report(s, metrics = [])` stays pure and gains the section
   `## Memory peaks over 2 GB` with one line per session over 2048 MB, `- <feature> · <model> · <peak> MB`
   (`<feature>` = `role` for init/retro lines with a null feature), omitted when none; the CLI's `report` reads
   `metrics.jsonl` from each `summary.json`'s directory when it exists. `summary.json` gains no field.
3. **L1-05**: `docs/architecture.md` §3 (`lib/check.sh`) and §7 (the check scope and its two RED lines); README's
   check line names 3G/15m.
4. **L1-06**: `bin/harness:175` gains `HARNESS_MEMINFO HARNESS_MEM_POLL`; §7 gains the memory gate.
5. **L1-07**: `session()` passes `--strict-mcp-config` always and `--mcp-config "$WT/.mcp.json"` when that file
   exists (after `--permission-mode auto`, before the settings); `prompts/parts/rules.md` gains the deepEqual line
   (§11 below for the help text). Caveat: `rules.md` is rendered only when the project has a `CLAUDE.md`
   (`lib/prompt.sh:26`); every harness project has one today (§12, D5).

## 10. Checks (written first), with their names in `tests/run.sh`

Runs named here are new `"$H" start "$T/proj" <run> …` lines unless they say `demo` (`:438`). Config keys a run needs
go into `$T/user-config.sh` for that run and back to `$T/base-config.sh` after, as the suite does today.

| Feature | Check name | Driven by |
|---|---|---|
| L1-02 | `scope.sh: scope_run wraps the command in systemd-run with the caps and returns its exit` | stubs; `scope_run harness-x-s1 5G 6G bash -c 'exit 3'` → 3; `sd_with --unit=harness-x-s1` has `--user --scope --collect --quiet`, `-p MemoryHigh=5G`, `-p MemoryMax=6G`, `-p MemorySwapMax=1G`, `-p OOMPolicy=continue`, then the command |
| L1-02 | `scope.sh: scope_stop stops <unit>.scope; scope_peak and scope_left read the fixture` | stubs; `stop harness-x-s1.scope` in the log; peak `2`; left `0`, and `1` after a `STUB_LEAVE_PROCESS`-style pid |
| L1-02 | `scope.sh: a run id becomes a unit name of [A-Za-z0-9_-]` | pure: `scope_unit 'a.b/c d' s1` = `harness-a-b-c-d-s1` |
| L1-02 | `scope.sh: without user systemd scope_run runs bare (STUB_NO_SYSTEMD=1)` | `STUB_NO_SYSTEMD=1`; `scope_available` → 1, the command still runs, `sd_count --unit=` = 0 |
| L1-02 | `scope.sh: a real 64M scope kills a 256 MB allocation with exit 137 and leaves no unit` (name ends ` (skipped: no user systemd)` and the check passes trivially when the real probe fails) | the real commands (`HARNESS_SYSTEMD_RUN=systemd-run HARNESS_SYSTEMCTL=systemctl`, `SCOPE_OK` unset) in a child shell (`timeout` can't run a function): `SESSION_SWAP_MAX=0 timeout 30s bash -c 'source lib/scope.sh; scope_run harness-test-<suite pid>-oom "" 64M node -e "<256 × Buffer.alloc(1 MB)>"'` → 137, `scope_peak` = 64, then `scope_stop` and `systemctl --user list-units 'harness-test-$$-*' --plain --no-legend` empty |
| L1-03 | `sessions run in harness-<run>-s<n> with the three caps and timeout -k 30s` | demo: `--unit=harness-demo-s1`, `-p MemoryHigh=5G`, `-p MemoryMax=6G`, `-p MemorySwapMax=1G`, `timeout`, `-k`, `30s`, `100m` and the stub claude's path in one call |
| L1-03 | `each session's scope is stopped after it returns` | demo: the set of `--unit=harness-demo-s<n>` equals the set of `stop harness-demo-s<n>.scope`; run.log still has `exit <rc>` per session |
| L1-03 | `a session that leaves a process gets the left-1-process note (STUB_LEAVE_PROCESS=1)` | run `leftover`, `STUB_LEAVE_PROCESS=1`: `coding session left 1 process(es) running; stopped with its scope` in its harness-log.md, none in demo's; the sleep pids are dead after the run |
| L1-03 | `a session killed at its memory cap is noted and spends the attempt (STUB_OOM=A)` | run `leftover` too, `STUB_OOM=A`: `A: the session hit its memory cap (6G)`, and A's attempts in `attempts.json` count it |
| L1-03 | `no user systemd: the run goes bare with one uncapped note (STUB_NO_SYSTEMD=1)` | run `bare`, `STUB_NO_SYSTEMD=1`: `sd_count --unit=harness-bare` = 0, the list passes as demo's, exactly one `no user systemd: sessions and suites run uncapped` |
| L1-04 | `metrics.mjs: append writes mem_peak_mb as a number or null` | pure, `node --input-type=module` |
| L1-04 | `metrics.jsonl: every session line has mem_peak_mb from its scope` | demo: every line's `mem_peak_mb` = 2 (the fixture's 2404352 B) |
| L1-04 | `metrics.jsonl: mem_peak_mb is null when uncapped` | run `bare` |
| L1-04 | `summary.mjs: report lists only the sessions over 2 GB` | pure: peaks 1500 and 2500 → only 2500; none → no section |
| L1-05 | `check.sh runs the suite in harness-<run>-check-<pid> at 3G under timeout -k 30s` | demo: a call with `--unit=harness-demo-check-`, `-p MemoryMax=3G`, no `MemoryHigh`, `timeout -k 30s 15m` and the project's `CHECK_CMD` |
| L1-05 | `check.sh: exit 137 prints the memory-cap RED line` | `check.sh` called directly with `HARNESS_SCOPE_PREFIX=harness-ck`, `HARNESS_CHECK_CMD='exit 137'` |
| L1-05 | `check.sh: exit 124 prints the timed-out RED line` | the same with `exit 124`; and `exit 3` keeps `check: RED (exit 3 after` |
| L1-05 | `check.sh: a subset call is scoped too and never cached` | `check.sh -k foo` twice: two `--unit=harness-ck-check-` calls, no `cached` |
| L1-06 | `scope.sh: mem_available_gb reads the real meminfo fixture` | pure: `9` |
| L1-06 | `memory gate: under 5 GB the driver waits, then starts the session anyway (HARNESS_MEMINFO, HARNESS_MEM_POLL)` | run `lowmem`: `HARNESS_MEMINFO=$T/meminfo-2g.txt` (the fixture with only the MemAvailable line rewritten to `2097152 kB`), `MEM_WAIT_MAX=2s` in the user config, `HARNESS_MEM_POLL=1`: both notes; the list passes as demo's |
| L1-06 | `memory gate: the real fixture's 9 GB passes without a note` | demo: neither note |
| L1-07 | `session argv has --strict-mcp-config, and no --mcp-config without .mcp.json` | demo: stub claude's argv (the `sd_with --unit=harness-demo-s2` call) |
| L1-07 | `session argv has --mcp-config <wt>/.mcp.json when the worktree has one` | run `mcp` on a project copy with a committed `.mcp.json` |
| L1-07 | `the coding prompt has the deepEqual line` | `lib/prompt.sh` render for a demo feature, `grep -q deepEqual` |

`STUB_LEAVE_PROCESS=1` and `STUB_OOM=A` share the run `leftover` to keep the suite's time down (each new run costs
about 10 s); the memory gate gets its own run because it changes the user config.

## 11. `claude --help` (installed CLI 2.1.310, 2026-10-25), the lines L1-07 relies on

```
  --mcp-config <configs...>             Load MCP servers from JSON files or
                                        strings (space-separated)
  --strict-mcp-config                   Only use MCP servers from --mcp-config,
                                        ignoring all other MCP configurations
```

Both exist; the L1-07 decision file quotes these lines.

## 12. Defaults this plan takes (each recorded in its feature's decision file; questions for Michael)

- **D1 *default*: the peak is read from inside the scope** by a wrapper bash (§2), because an emptied scope is gone
  at once. Rejected: reading `memory.peak` from `/sys/fs/cgroup` (not stubbable), and a `RemainAfterExit` service
  instead of a scope (stdin/stdout and the exit code would go through the journal). → `2026-10-25-scoped-sessions`.
- **D2 *default*: `OOMPolicy=continue`** on every harness scope, so a cap kill takes only its victim and the record
  survives. → `2026-10-25-scoped-sessions`.
- **D3 *default*: `timeout -k 30s` inside the scope** (§3). → `2026-10-25-scoped-sessions`.
- **D4 *default*: exit 137 counts as the feature's attempt**, like 124. → `2026-10-25-scoped-sessions`.
- **D5 *default*: the deepEqual line goes in `prompts/parts/rules.md`** as the spec says, though that part renders
  only with a `CLAUDE.md`. The alternative is `prompts/coding.md` §2, beside "Test-driven". →
  `2026-10-25-strict-mcp-and-deepequal-rule`.
- **D6 *default*: suites get no `MemoryHigh`**, only `CHECK_MEMORY_MAX`, so a runaway test dies in milliseconds
  instead of stalling under throttling. → `2026-10-25-capped-suites`.

## 13. What the probes change against the feature list (proposed changes)

- **L1-02 step 6**: the real-scope check cannot use `MemoryHigh=48M MemoryMax=64M`: the probe stalled over two minutes
  under throttling without an OOM kill. It runs with no `MemoryHigh`, `SESSION_SWAP_MAX=0` (with 1G of swap a 256 MB
  allocation fits) and an outer `timeout 30s`, as §10 says.
- **L1-02 step 3**: between `-p MemorySwapMax=…` and the command come `-p OOMPolicy=continue` and the wrapper
  (`bash -c <wrap> _ <unit> <dir> <systemctl>`); the check looks for each part in the call, not for adjacency.
- **L1-03 step 5**: "the attempt counts as the feature's" needs `environmental()` to return null for 137 (§8.1); today
  a 137 with no result under 120 s gives the attempt back.
- **L1-04 step 3**: `report()` reads `metrics.jsonl` beside `summary.json` (it has no other source of per-session
  peaks once `summary.json` gains no field).
