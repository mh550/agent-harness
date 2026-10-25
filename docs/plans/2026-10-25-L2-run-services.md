Milestone base: 36a007ca59aea00290888def523ffcec688c1cb7 (tag `run/agent-harness-2026-10-25-lifecycle/L1`)

# L2 · Run services: a scope, a teardown hook, and every stop point (plan)

Spec: `docs/specs/2026-10-25-resource-lifecycle.md` §L2. This plan fixes the interfaces so L2-02 … L2-05 each build one
thing and L2-06 reviews from the base above. Build-only: `systemd-run`/`systemctl` only through the stubs; the three
fixtures this plan adds were captured from real `harness-test-<pid>-*` scopes (64M, stopped at once, none left: §8).
Builders: L2-02 = §1, §2 (init keys) · L2-03 = §3, §4, §5.1–5.2, §6.1–6.2 · L2-04 = §5.3–5.6, §6.3–6.5 · L2-05 = §7,
§8. Checks in §6 and §7. Defaults this plan takes for Michael in §10; what it changes against the feature list in §11.

## 0. What is there today (after L1, 36a007c)

- `run_init` (`lib/driver.sh:256`) runs `HARNESS_PORT=$PORT HARNESS_SCRATCH=$SCRATCH bash -c "$INIT_CMD" >
  "$SCRATCH/init.out" 2>&1` bare, then the suite. It is called before the initializer (`:571`, after `mem_gate` at
  `:570`), before every coding session (`:631`, after the loop's `mem_gate` at `:628`) and once per `verify()` (`:346`,
  *before* the round loop's `mem_gate` at `:351`). `HARNESS_PORT`, `HARNESS_SCRATCH` and `HARNESS_RUN_ID` are exported
  to everything anyway (`prompt_env`, `lib/prompt.sh:17`).
- The one EXIT trap (`:86`) writes `ended` from `END_REASON` and removes `driver.pid`. `finish()` (`:451`) ends with
  `exit 0`, so the trap runs after it too.
- `services_down` is a no-op placeholder (`:57`: `declare -F services_down > /dev/null || services_down() { :; }`);
  `mem_gate` (`lib/scope.sh:93`) calls `services_down memory` after its first note.
- The pause branch (`:600-606`) logs `paused`, notifies, polls `control()` every `HARNESS_PAUSE_POLL`. `STOP` (or
  `status: stop`) → `finish "stopped by Michael"` (`:608`). `limit_wait` (`:151`) notes `usage-limit window (shared by
  all runs): waiting until HH:MM (<n> min)`, then sleeps `${HARNESS_LIMIT_SLEEP:-$w}`.
- `bin/harness` doesn't source `lib/scope.sh`. `cmd_gc` (`:327`) ends after its branch passes; `cmd_status` (`:220`)
  prints one header line per run and the last `N` lines of `run.log`, indented 4 spaces.
- **Bash runs the EXIT trap at once on SIGTERM**, even while a foreground child runs, and the child lives on
  (probed 2026-10-25: `bash -c 'trap … EXIT; sleep 30'` killed with TERM → trap ran in 13 ms, rc 143, `sleep` still
  running). So a TERM to the driver mid-session leaves `claude` running in `harness-<run>-s<n>` until its timeout: §4.

## 1. The services scope (L2-02)

```bash
run_init() {   # stops what the last init started, then the init in harness-<run>-svc; what it backgrounds stays there
  local unit; unit=$(scope_unit "$RUN_ID" svc)
  scope_stop "$unit"   # exit 5 (gone) is done; a scope of the same name still loaded would make systemd-run refuse
  SVC_UP=1             # before the start: a TERM during the init must still tear down what it began
  scope_run "$unit" "" "$SVC_MEMORY_MAX" timeout -k 10s "$INIT_TIMEOUT" bash -c "$INIT_CMD" > "$SCRATCH/init.out" 2>&1
  local rc=$?; echo "(init exit $rc)" >> "$SCRATCH/init.out"
  [[ -n ${SCOPE_BARE:-} ]] && note "init ran uncapped: $SCOPE_BARE"
  … the rest as today (the log line on rc != 0, the suite, tests-start)
}
```

- Order: `systemctl --user stop harness-<run>-svc.scope`, then `systemd-run --user --scope --collect --quiet
  --unit=harness-<run>-svc --description=harness-<run>-svc -p MemoryMax=3G -p MemorySwapMax=1G -p OOMPolicy=continue
  bash -c <wrap> _ harness-<run>-svc <dir> <systemctl> timeout -k 10s 10m bash -c <INIT_CMD>`. No `MemoryHigh` (empty
  `<high>`, as the suites: a runaway dev server dies at its cap, it doesn't crawl). `timeout` inside the scope, around
  the init's foreground only (L1 plan §3's reasoning): an init that backgrounds `next dev` and exits 0 returns at once;
  the dev server stays in the scope, which the wrapper's `exit` leaves alive (a scope lives while it holds a process).
- **Why the stop first:** real `systemd-run` with a unit name still loaded exits 1 with
  `Failed to start transient scope unit: Unit <u>.scope was already loaded or has a fragment file.`
  (`tests/fixtures/systemd-run-unit-exists.txt`). `scope_run` would then run the init bare (its L1 fallback) and the
  old services would live on. The stop also replaces today's per-project `kill $(cat server.pid)` (which kills the
  `npx` pid, not `next-server`); `templates/project/init.sh` keeps its pid line (harmless, and bare runs need it).
- Bare (`STUB_NO_SYSTEMD=1`, no user bus): `scope_run` runs the line bare, `SCOPE_BARE` stays empty, so the L1
  `no user systemd: …` note stays the only one; `scope_stop` is a no-op. The teardown hook (§3) still runs.
- `verify()` (`:346-351`): its `mem_gate` comes after its `run_init`, so a wait would stop the services and the verify
  session would start without them. L2-04 makes it `mem_gate || run_init` (exit 1 = it waited, so services_down ran).
  The coding loop and the initializer gate before their `run_init` and need nothing.
- The stub needs nothing new for the init: `stub-systemd-run.sh` runs the command with `STUB_SCOPE_UNIT` set, so a test
  `INIT_CMD` that backgrounds `sleep 300 & echo $! >> "$STUB_DIR/scope/$STUB_SCOPE_UNIT.pids"` keeps the stub unit
  alive as a real one is, and the next stop kills it.

## 2. Config keys

| Key | Default | Used by | Feature |
|---|---|---|---|
| `INIT_TIMEOUT` | `10m` | `run_init`: `timeout -k 10s` around the init's foreground | L2-02 |
| `SVC_MEMORY_MAX` | `3G` | `run_init`: the svc scope's `MemoryMax` | L2-02 |
| `TEARDOWN_CMD` | `.harness/teardown.sh` when that file is executable in the worktree, else empty | `services_down` | L2-03 |
| `SVC_IDLE_STOP_MIN` | `10` | `limit_wait`: stop services before a wait of more than this many minutes | L2-04 |

Each in `lib/config.sh` (the defaults block; `TEARDOWN_CMD=""` there and the executable-file default beside
`INIT_CMD`'s at `:38`, written so it always succeeds: `[[ -n $TEARDOWN_CMD || ! -x $wt/.harness/teardown.sh ]] || TEARDOWN_CMD=.harness/teardown.sh`.
The `[[ … ]] || { [[ -x … ]] && … }` form returns 1 without the file, and as `harness_config`'s last line that is its
exit: `bin/harness` runs under `set -euo pipefail` (`:54`) and would die silently at `harness_config` for every project
without a hook),
`templates/user/config.sh` (commented) and `docs/architecture.md` §10, in the feature that introduces it. The
teardown's own `timeout 2m` is fixed, not a key (the spec's figure; a teardown that needs longer is a bug to see).
No new `HARNESS_*` override: `bin/harness`'s env list needs nothing.

## 3. `services_down <why>` (L2-03)

Defined in `lib/driver.sh` in place of the `:57` placeholder (after `note`, before the trap; `mem_gate` finds it with
`declare -F`, so the `declare -F … ||` guard goes):

```bash
# <why>: the project's teardown, then the svc scope, then one note. Only after an init started something (SVC_UP):
# finish's call and the EXIT trap's after it give one note, and a segment that never ran an init is silent.
services_down() {
  (( ${SVC_UP:-0} )) || return 0
  local rc=0
  if [[ -n $TEARDOWN_CMD ]]; then
    HARNESS_TEARDOWN_WHY=$1 timeout 2m bash -c "$TEARDOWN_CMD" >> "$SCRATCH/teardown.out" 2>&1; rc=$?
  fi
  scope_stop "$(scope_unit "$RUN_ID" svc)"; SVC_UP=0
  if (( rc )); then note "services stopped ($1; teardown exit $rc, see $SCRATCH/teardown.out)"
  else note "services stopped ($1)"; fi
}
```

- **Contract of the hook:** runs in the worktree (the driver's cwd), with `HARNESS_PORT`, `HARNESS_SCRATCH`,
  `HARNESS_RUN_ID` (already exported) and `HARNESS_TEARDOWN_WHY=<why>`; under `timeout 2m`; bare, not in a scope (it
  is short, and the scope it tears down is about to stop); before the scope stops (a `docker compose down` may want the
  app that holds the connection still up, and `npx supabase stop` lives under `dockerd`, where no cgroup of ours
  reaches). Output appended to `$SCRATCH/teardown.out`. Its exit never stops the driver.
- `SVC_UP=0` is set **after** `scope_stop`, so a TERM during finish's teardown runs the trap's `services_down` again
  (teardown twice is harmless; leaving the services up is not), while the interrupted first call never reaches its note:
  still exactly one note.
- "Idempotent per why" in the feature list means: one call per started init notes; any further call before the next
  `run_init` is silent whatever its `<why>`.

## 4. The EXIT trap (L2-03)

```bash
trap '[[ -n ${S_UNIT:-} ]] && scope_stop "$S_UNIT"; services_down "driver exited"; echo "$END_REASON · $(date "+%F %T")" > "$STATE/ended"; rm -f "$STATE/driver.pid"' EXIT
```

- `session()` sets `S_UNIT=$unit` before `scope_run` and clears it after its own `scope_stop` (one line each). Then a
  TERM mid-session stops the session's scope too, so `claude` doesn't run on for up to `SESSION_TIMEOUT` with nobody to
  read it (§0's probe). It goes first: the teardown may take its 2 minutes, and `claude` must not edit and push in
  the worktree meanwhile (nor survive a shutdown's SIGKILL during it). Not in the feature list's steps; see §11.
- The trap must not fail when nothing started: `services_down` returns 0 at once with `SVC_UP` unset, `S_UNIT` unset
  skips the stop, and `ended`/`driver.pid` are written/removed exactly as today. `finish` → `exit 0` → trap: finish's
  `services_down` already cleared `SVC_UP`, so the trap adds no note.
- SIGKILL runs no trap: what it leaves, `harness gc` stops (§7.1).

## 5. Every stop point

| # | Where | Call | Note | Feature |
|---|---|---|---|---|
| 5.1 | `finish()`, after `green`/`tests-end` and before `SUM build` (the summary): services the suite may need stay up through finish's suite run | `services_down "$1"` | `services stopped (<finish reason>)`, e.g. `(done)` | L2-03 |
| 5.2 | the EXIT trap (§4) | `services_down "driver exited"` | `services stopped (driver exited)` | L2-03 |
| 5.3 | the pause branch, after `log "paused …"` and `notify "paused"`, before its `while` poll | `services_down paused`, then `commit_all "HARNESS: paused"; sync` (nothing else commits during a pause, so the note would stay off the phone until the next session's commit) | `services stopped (paused)` | L2-04 |
| 5.4 | `STOP` / `status: stop`: `finish "stopped by Michael"` (`:608`) reaches 5.1, nothing new | — | `services stopped (stopped by Michael)` | L2-04 (check only) |
| 5.5 | `limit_wait`, after `w` is final (capped at the deadline) and before its note: `(( w > SVC_IDLE_STOP_MIN * 60 )) && services_down "usage-limit wait"` | as said | `services stopped (usage-limit wait)`, then the `usage-limit window` note | L2-04 |
| 5.6 | `mem_gate` (`lib/scope.sh`): `services_down memory` → `services_down "memory wait"`; and `verify()`'s `mem_gate || run_init` (§1) | as said | `services stopped (memory wait)` | L2-04 |

After 5.3, 5.5 and 5.6 the next `run_init` (the next coding session's, or verify's) starts the services again: a
resumed run needs nothing new. A wait of exactly `SVC_IDLE_STOP_MIN` minutes keeps them (strictly over). The
`HARNESS_LIMIT_SLEEP=0` the suite sets doesn't change `w`, so the comparison is the real one while the sleep is instant.

## 6. How the suite observes each stop point

**The test project's hook** (added once to `$T/proj` before run 1, in the same commit as its `.harness/config.sh`, so
every run's worktree has it and every run's scratch gets its own markers):

```bash
#!/usr/bin/env bash
# .harness/teardown.sh of the suite's project: one marker per why, and the call in the stubs' own timeline
w=$(printf %s "$HARNESS_TEARDOWN_WHY" | tr -cs 'A-Za-z0-9' -)
touch "$HARNESS_SCRATCH/teardown-$w.marker"
printf 'teardown\n%s\n%s\n===\n' "$HARNESS_RUN_ID" "$HARNESS_TEARDOWN_WHY" >> "$STUB_DIR/systemd.log"
```

`<why-safe>`: `done`, `driver-exited`, `paused`, `stopped-by-Michael`, `usage-limit-wait`, `memory-wait`. The record in
`systemd.log` puts the teardown in the same `===`-separated timeline as the stub `systemctl stop` calls, so "teardown,
then the stop" is one ordered read (`awk 'BEGIN{RS="===\n"}'` over the file, as the `sd_*` helpers do), not an mtime
comparison. Every run in the suite then also logs `services stopped (<reason>)` on finish; checks that count
`harness-log.md` lines exactly must be re-read when L2-03 lands (none counts all notes today).

| Check | Run | Drive | PASS |
|---|---|---|---|
| 6.1 finish (L2-03) | `demo` (run 1) | none | `$T/scratch/proj/demo/teardown-done.marker` exists; in `systemd.log` the `teardown demo done` record comes before the last `stop harness-demo-svc.scope`; `hlog demo` has `· services stopped (done)` exactly once |
| 6.2 SIGTERM (L2-03) | new `termed`, `--foreground` in the background with `STUB_SLOW_CODING=30` | `rm -f $T/slow-coding`; wait (≤ 30 s) for `$T/slow-coding`; `kill -TERM $(cat $HARNESS_STATE/proj/termed/driver.pid)`; `wait` | `teardown-driver-exited.marker`; `stop harness-termed-svc.scope` and `stop harness-termed-s<n>.scope` in `systemd.log` after the teardown record; `services stopped (driver exited)` in `run.log`; `ended` starts `driver exited unexpectedly`; no `driver.pid`. L2-05 reads `harness status termed` here, before the kill (§7.2) |
| 6.3 PAUSE (L2-04) | new `paused`, background, `STUB_PAUSE=A` | the stub's coding session for A, attempt 1, touches `$(compgen -G "$HARNESS_STATE/*/$HARNESS_RUN_ID")/PAUSE` (as `harness pause` does mid-session); the suite waits for `services stopped (paused)` in `hlog`, then `"$H" resume paused`; `wait` | `services stopped (paused)` once; `teardown-paused.marker`; after the pause's `stop harness-paused-svc.scope` a later `systemd-run … --unit=harness-paused-svc` (the next init); the run ends `3/3 passing` |
| 6.4 STOP (L2-04) | `stoppy` (run 2, `STUB_PHONE_STOP`) | none (its initializer sets `status: stop`) | `services stopped (stopped by Michael)`; `teardown-stopped-by-Michael.marker` |
| 6.5 usage-limit (L2-04) | `waiter` (run 7) with its window cut from 3600 s to `+660` (11 min), and new `waiter9` at `+540` (9 min) | `LIMIT_UNTIL` as run 7 writes it; `HARNESS_LIMIT_SLEEP=0` | `waiter`: `services stopped (usage-limit wait)` on the line before `usage-limit window (shared by all runs): waiting`; `waiter9`: the window note and no `(usage-limit wait)` (its `(done)` note is finish's) |
| 6.6 memory (L2-04) | `lowmem` (the L1-06 run) | as today | at least one `services stopped (memory wait)` (the gates after the first `run_init`; the initializer's gate comes before any init and is silent) |
| 6.7 the unit check (L2-04) | `lib/scope.sh` `mg` block (`tests/run.sh:141-152`) | as today | its expected `down: memory` lines become `down: memory wait` |
| 6.8 init scope (L2-02) | `demo` | none | in `systemd.log`, `stop harness-demo-svc.scope` then a `systemd-run` with `--unit=harness-demo-svc`, `MemoryMax=3G`, no `MemoryHigh`, and `timeout -k 10s 10m bash -c echo init ok` (joined as the L1-05 check does with `grep -A… -x timeout`) |
| 6.9 backgrounded init (L2-02) | `run_init` isn't callable alone, so a run on a project of its own made with `dproj` (as run `ip` is, `tests/run.sh:931`): the project's `.harness/config.sh` wins over the user config (`lib/config.sh:31` sources it after), so `INIT_CMD` goes there: `INIT_CMD='date +%s%N > "$STUB_DIR/svcbg.t0"; sleep 300 & echo $! >> "$STUB_DIR/scope/$STUB_SCOPE_UNIT.pids"; echo $! > "$STUB_DIR/svcbg.pid"; exit 0'` | `--foreground` | its `init.out` has `(init exit 0)`; `init.out`'s mtime is within 2 s of `svcbg.t0` (the init's own stamps, not run.log's 1-second lines with git, the probe and the suite between) and the run ends far under 300 s; the sleep is gone after the run (only a stop of the scope that held it kills it: a `sleep 300` the init had lost would still run). That last part is the one that fails before L2-02: a bare init also returns at once; the cleanup kills `$(cat $T/svcbg.pid)` if not |
| 6.10 bare (L2-02) | `bare` (the L1 run, `STUB_NO_SYSTEMD=1`) | as today | `(init exit 0)` in its init.out, `no user systemd` once, no `init ran uncapped` note |

**Stub changes, all in the builders' features:**
- `stub-claude.sh`: `STUB_PAUSE=<id>` (above). `STUB_SLOW_CODING` already exists (it touches `$STUB_DIR/slow-coding`).
- `stub-systemd-run.sh` (L2-03): run the command in the background and `wait`, writing its pid to `<unit>.cmd`, and
  `stub-systemctl.sh`'s `stop` kills that pid's whole tree (descendants collected with `ps -o pid= --ppid` first, then
  TERM to all), as a real scope stop kills everything in its cgroup; `<unit>.cmd` is removed right after the `wait` (the unit may
  live on through `.pids`, and a stale pid could name an unrelated process by then). Not `<unit>.pids`: those count in `TasksCurrent`
  (`2 + live pids`), and the command's own pid there would make every clean session "leave 1 process". Not a process
  group: `timeout` makes its own, so a group kill misses `claude`. Today the stub forks in the foreground and records
  nothing of the command: after 6.2's TERM, `stop harness-termed-s<n>.scope` would leave the slow stub session
  running, and it would go on to commit in the dead run's worktree. `alive()` stays as is.
- Time: 6.2, 6.3 and 6.5's `waiter9` are three more runs (about 15 s each here); 6.9 one more small one.

## 7. gc of orphaned units, and `harness status` (L2-05)

`bin/harness` sources `lib/scope.sh` (for `scope_unit`, `scope_stop`) at the top, beside its other sources.

### 7.1 `cmd_gc`'s unit step, after the branch passes and before `return 0`

```bash
# A SIGKILLed driver ran no trap: stop the units of this project's runs that have no live driver. Unit → run
# by rebuilding each run's prefix (never by parsing the unit name): harness-<sanitised id>-<role>.scope
local u r d role cands mine busy why
while read -r u _; do
  [[ $u == harness-*.scope ]] || continue
  cands=() mine=0 busy=0
  for d in "$STATE_ROOT"/*/*/; do   # every project's runs: two ids may reduce to one prefix (a.b, a-b)
    r=$(basename "$d"); role=${u#"$(scope_unit "$r")-"}
    [[ $role != "$u" && $role =~ ^(s[0-9]+|check-[0-9]+|svc)\.scope$ ]] || continue
    cands+=("$r"); [[ $d == "$STATE_ROOT/$(basename "$p")/"* ]] && mine=1
    alive "$d" && busy=1   # a SIGKILLed driver wrote no `ended`: a dead driver.pid is enough
  done
  (( mine )) || { echo "? $u (no run of this project)"; continue; }
  (( busy )) && continue   # a live run's, or one sharing its prefix
  why="${cands[0]} ended"; compgen -G "$STATE_ROOT/*/${cands[0]}/ended" > /dev/null || why="${cands[0]}: driver gone"
  if (( dry )); then echo "would: systemctl --user stop $u ($why)"
  elif scope_stop "${u%.scope}"; then echo "+ stopped $u ($why)"
  else echo "! could not stop $u"; fi
done < <("${HARNESS_SYSTEMCTL:-systemctl}" --user list-units 'harness-*' --plain --no-legend 2> /dev/null)
```

- **Match rule:** a unit belongs to run `R` when it equals `$(scope_unit R)-<role>.scope` with `<role>` one of
  `s<n>`, `check-<n>`, `svc`. The role pattern is what keeps run `demo` from claiming `harness-demo-x-svc.scope` (run
  `demo-x`'s). A unit is stopped only when no run it could belong to has a live `driver.pid`, and at least one is
  this project's. **Not "has `ended`"** (the spec's words): the driver removes `ended` at start (`lib/driver.sh:84`) and
  only `finish` and the EXIT trap write it, so a SIGKILLed driver, the very case this step is for, leaves a dead
  `driver.pid` and no `ended`. The note says `(<run> ended)` when `ended` exists, else `(<run>: driver gone)`. Units of no run of this project print `? <unit> (no run of this project)` and are never
  stopped (another project's gc owns them; `harness-test-*` units are the suite's).
- Column 1 only, so the description column (now the unit name: L1-03's `--description`) never matters. Real output:
  `harness-test-329212-cur.scope loaded active running harness-test-329212-cur`
  (`tests/fixtures/systemctl-list-units-described.txt`); nothing at all when none exist (init capture).
- `--dry-run`: `would: systemctl --user stop <unit> (<run> ended)`, and no stop call reaches `systemctl`.
- No user bus: `list-units` fails, its stderr dropped, the loop sees nothing.

### 7.2 `cmd_status`: a running run's units

Under the header line of a run that is `running`, before the `run.log` tail, one line per unit:

```
    harness-<run>-s7 · MemoryCurrent 50 MB
```

from `"${HARNESS_SYSTEMCTL:-systemctl}" --user list-units "$(scope_unit "$RUN_ID")-*" --plain --no-legend`, filtered by the same role pattern
(so `demo`'s status doesn't list `demo-x`'s units), then `"$SYSTEMCTL" --user show -p MemoryCurrent <unit>` parsed by
key, bytes → MB rounded as `scope_peak` does (`(b + 524288) / 1048576`). Not a number (`[not set]`: the unit went
between the two calls) → the line is skipped. The unit is shown without `.scope`. An ended run prints no unit lines and
calls no `systemctl`. `bin/harness` runs under `set -euo pipefail` and each run's lines come from a `( … )`
subshell: no bare `$SYSTEMCTL` (unbound there), `scope_available` first, and every call read through
`< <(… 2> /dev/null)` or ending `|| true`, so a missing bus or a unit gone between the two calls never cuts the listing off.

Real output (2026-10-25, a 64M `harness-test-329212-cur` scope holding `sleep 60`, then stopped):
`MemoryCurrent=253952` (`tests/fixtures/systemctl-show-current.txt`); once gone: `MemoryCurrent=[not set]`, exit 0
(`tests/fixtures/systemctl-show-current-gone.txt`).

### 7.3 Stub and checks

- `stub-systemctl.sh`: `show` adds `MemoryCurrent=` to the stream it filters: for a live unit
  `${STUB_MEM_CURRENT:-<the fixture's value>}`, for a gone one the `-gone` fixture's line. `list-units` switches to
  `systemctl-list-units-described.txt`, replacing its unit name (`harness-test-329212-cur`, which is also its
  description) with the live unit's (the old fixture stays for any check that reads it; none parses it beyond column 1).
- **gc check:** next to run 15's gc (`tests/run.sh:1195`), fake stub units: `touch $T/scope/<u>.{alive,running}` for
  `harness-demo-svc`, `harness-demo-s99` (run `demo`: `ended`, no driver), `harness-gclive-svc` and
  `harness-demo-x-svc`, plus `harness-killed-svc` for a fake run `killed` with a dead-pid `driver.pid` and **no**
  `ended` (a SIGKILLed driver: it must be stopped, `(killed: driver gone)`) (state dirs `$HARNESS_STATE/proj/gclive` and `proj/demo-x`, each with `meta.env` copied from
  demo's and a `driver.pid` of a background `sleep 60`), and `harness-nosuch-svc`. `harness gc "$T/proj" --dry-run`
  prints `would: systemctl --user stop harness-demo-svc.scope (demo ended)` and the `s99` line, `? harness-nosuch-svc.scope
  (no run of this project)`, and no `stop` reaches `systemd.log`; then the real gc prints `+ stopped …` for demo's two
  and killed's one only, `systemd.log` has exactly those three stops, and the three others are still listed by the stub. Cleanup at once:
  kill the sleeps, remove the three fake state dirs and the fake unit files (a live fake `driver.pid` would count
  against `MAX_PARALLEL_RUNS` in every later run).
- **status check:** inside 6.2, while `termed`'s slow session runs: `STUB_MEM_CURRENT=52428800 "$H" status termed` has
  `    harness-termed-s<n> · MemoryCurrent 50 MB`. After the kill, touch a fake live `harness-termed-s99` stub unit:
  `"$H" status termed` (ended) has no `MemoryCurrent` line and adds no `list-units` record to `systemd.log`; then remove
  the fake unit. Without the fake unit the trap has stopped everything and the check could not fail.

## 8. Fixtures captured for L2 (2026-10-25, this box, systemd 255)

| File | Command | Shape |
|---|---|---|
| `systemctl-show-current.txt` | `systemctl --user show -p MemoryCurrent harness-test-329212-cur.scope` (alive, `sleep 60`, `-p MemoryMax=64M`) | `MemoryCurrent=253952` |
| `systemctl-show-current-gone.txt` | the same after `systemctl --user stop` | `MemoryCurrent=[not set]` (exit 0) |
| `systemctl-list-units-described.txt` | `systemctl --user list-units 'harness-test-<pid>-*' --plain --no-legend`, the scope started with `--description=<unit>` | `harness-test-329212-cur.scope loaded active running harness-test-329212-cur` |
| `systemd-run-unit-exists.txt` | `systemd-run --user --scope … --unit=harness-test-331922-dup … true` while a scope of that name holds a `sleep` | stderr `Failed to start transient scope unit: Unit harness-test-331922-dup.scope was already loaded or has a fragment file.`, exit 1 |

Both scopes were stopped in the same command (`systemctl --user list-units 'harness-test-*'` printed nothing after).
The stub `systemd-run` may use the last one when asked to start a unit it already holds alive (L2-02's choice; no
check needs it unless `run_init`'s stop is removed).

## 9. Templates, README, docs

- `templates/project/teardown.sh` (L2-03), executable, everything below the header commented:

  ```bash
  #!/usr/bin/env bash
  # .harness/teardown.sh (optional) — run by the harness whenever it stops a run's services: on finish, a pause, a stop,
  # a usage-limit wait over SVC_IDLE_STOP_MIN, a memory wait and the driver's exit, then the services scope is stopped.
  # For what a cgroup can't hold: containers live under dockerd. HARNESS_PORT, HARNESS_SCRATCH, HARNESS_RUN_ID and
  # HARNESS_TEARDOWN_WHY are set; it has 2 minutes. Idempotent: it may run when nothing is up.
  set -uo pipefail
  cd "$(dirname "$0")/.."
  # npx supabase stop                                   # hit_list's local stack (13 containers)
  # docker compose -f docker-compose.test.yml down      # a test stack the init started
  ```
  `harness init` doesn't copy it (projects opt in), as with `init.sh`.
- README (L2-03): the `.harness/` table's `init.sh` row gains `teardown.sh` ("stops what a cgroup can't: docker,
  supabase"), and one paragraph: the init's services run in `harness-<run>-svc` (3G), stopped with the hook first at
  every stop point; a project that starts containers adds its own `.harness/teardown.sh` from the template. L2-05: the gc
  row names the orphan-unit step; the status row the unit lines.
- `docs/architecture.md`: §3 (`run_init`, `services_down`, `harness gc`, `harness status`), §4 (the svc unit, `SVC_UP`
  is memory only, `teardown.out` in scratch), §5 (each stop point in the life of a run), §7 (guards: the stop points,
  gc's match rule), §10 (the four keys), §14 (by hand: `systemctl --user list-units 'harness-<run>-*'`, then
  `systemctl --user stop <unit>`; run the project's `.harness/teardown.sh` first). L2-06 checks they are complete.
- Decision files: `2026-10-25-services-scope` (L2-02), `2026-10-25-teardown-hook` (L2-03), `2026-10-25-services-stop-points`
  (L2-04), `2026-10-25-gc-orphan-units` (L2-05), each finding · choice · rejected, citing the spec and this plan.

### Carried over from L1's review (entries.jsonl:9), assigned

- The list-units fixture predated `--description`: recaptured here (§8); the stub switches in L2-05.
- `check.sh` `stop()` misses a TERM that lands before the scope registers, or on the bare fallback (the suite runs on up
  to `CHECK_TIMEOUT`): L2-06 (a review fix with its own RED→GREEN check).
- `check.sh` probes a real scope on every call (about 20 ms): L2-06 may pass the driver's `SCOPE_OK` down
  (`HARNESS_SCOPE_OK`); a simplification, not a bug.

## 10. Defaults this plan takes for Michael

- **D1 *default*:** `services_down` is silent unless this segment's driver ran an init (`SVC_UP`), so a fresh segment's
  first memory wait or a crash before the init notes nothing. What an earlier, SIGKILLed segment left is `run_init`'s
  stop and `harness gc`'s to clear.
- **D2 *default*:** the EXIT trap also stops the running session's scope (`S_UNIT`), not only the services: a killed
  driver otherwise leaves `claude` working unread until `SESSION_TIMEOUT`.
- **D3 *default*:** in `finish`, the services stop after the final suite run (`green`) and before the summary, so a
  suite that needs them (a dev server, a local database) still has them.
- **D4 *default*:** a teardown that fails or times out is in the note (`teardown exit <rc>`) and never stops the driver;
  the scope stops regardless.
- **D5 *default*:** the teardown runs bare, not in the svc scope, and doesn't run before each init (an init brings its
  own services up idempotently; a `supabase stop` before every session would cost minutes each).

## 11. Against the feature list (for `proposed_changes`)

- L2-03 step 3 names one `teardown.marker`; the plan's hook writes one per why (`teardown-done.marker` there), so the
  same hook serves L2-04's checks.
- L2-03 step 4: "a foreground driver started in the background": the TERM goes to the driver's own pid
  (`driver.pid`), since `--foreground` runs the driver as a child of `bin/harness` (`eval env … driver.sh`), not
  `exec`. The trap also stops the session's scope (D2), which the step doesn't list.
- L2-04 step 2 says "paused through INBOX.md … resumed by the stub": no session runs during a pause, so the stub can
  only set it; the suite resumes with `harness resume`. The pause goes through `$STATE/PAUSE` (what `harness pause`
  does), which `control()` reads exactly as `status: pause`.
- L2-04 needs `verify()`'s `mem_gate || run_init` (§1), or a memory wait before a verify leaves it without services.
- L2-03 step 3's "stop after the marker's mtime": the plan orders the teardown and the stop in one log (`systemd.log`,
  §6), which a 1-second mtime can't.
- L2-05 step 1, "stopped through act" and "a run with `ended`": the unit lines are gc's own (`+ stopped <unit> (<run>
  ended)`, `would: systemctl --user stop …`), since `act` would print the raw systemctl argv; and a run with no live
  driver qualifies with or without `ended` (§7.1: a SIGKILLed driver writes none).
- L2-04 step 1's pause branch also commits (§5.3).
