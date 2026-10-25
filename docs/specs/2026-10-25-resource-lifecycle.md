# Resource lifecycle: everything a run starts is capped, and stopped when the run stops (2026-10-25)

**Goal.** Nothing a run starts can take the box down, and nothing it starts outlives it. One systemd user scope per
session, one per suite run and one per run's services, each with a memory cap, each stopped on finish, pause, stop,
a long usage-limit wait or a crash. Then the cleanups that hang off the same stop points: scratch, tmux sessions and
supervisors, and a `harness gc` that runs by itself and finishes. Five milestones, L1–L5.

**Why it goes first.** The previous boot (Oct 13–24) had 10 OOM kills and 7 "under memory pressure" flushes, six
`next dev` servers ran for 2–5 days, and the boot purged about 1 M leaked files from `/tmp`. The policy change of
2026-10-24 lets agents start more services (`docker compose` for test stacks), so the cleanup lands before more work.

**Sources, folded in here.** `findings-and-research/2026-10-24-system-resource-audit.md` §3B (B1–B9; B10 is done:
`lib/sync.sh`), `findings-and-research/2026-10-24-oom-from-unbounded-test-diff.md` (its steps 1–4: the guard first,
the prompt line second), `docs/specs/2026-10-22-tmux-and-queue-hygiene.md` H1/H2 (superseded by this spec), R9 from
`docs/specs/2026-10-21-retro-fixes.md` (moved here: it is the same `cmd_gc` loop), and one finding from the chunk 3
catch-ups (`--all-merged`, §L4). Out of scope: the audit's §3A and §3C (box settings: done in chunk 2 or Michael's),
B6 (per-project fixes: chunk 3 Part 2 did them in the projects), and docker `mem_limit` in project compose files.

**Rules.** `CLAUDE.md` binds: work only in the worktree; never touch real runs or real state; every behaviour visible
in `harness-log.md` (`note`) or `runner.log` and checked in `tests/run.sh`, written first and watched failing;
`bash -n` and `node --check` on every file touched; a decision file per behaviour change; `docs/architecture.md`
(§3 components, §4 state, §10 conventions, the guards) and `README.md` in the same milestone.
- **Fakes mirror the live commands.** `systemd-run` and `systemctl` are called through `HARNESS_SYSTEMD_RUN` and
  `HARNESS_SYSTEMCTL` (like `HARNESS_CLAUDE`/`HARNESS_GH`); the suite's stubs record their argv and print what the
  real commands print. Copy that output into `tests/fixtures/` from real runs on this box (for example
  `systemctl --user show -p MemoryPeak,ControlGroup <unit>` prints `MemoryPeak=4722688` and
  `ControlGroup=/user.slice/…/app.slice/<unit>`), never typed from memory.
- **Real scopes in the suite, only these:** at most one or two checks may start a real transient scope, named
  `harness-test-<pid>-*`, with `MemoryMax` of 64M or less, stopped in the check's own cleanup. They run only when
  `systemd-run --user --scope --quiet true` works, and say so in the check name when they don't. No check stops,
  lists-and-acts-on or otherwise touches a unit the suite didn't create.
- **tmux checks run on the suite's private server** (`tests/run.sh` sets `TMUX_TMPDIR=$T/tmux` and a per-pid
  `HARNESS_DESK_SESSION`), never against Michael's, and never touch `h-queue`, `h-desk`, `overnight` or `rc-host`.
- Proceed on the defaults below and record each in its decision file; never park.

**Probe (2026-10-25, this box).** systemd 255; `systemd-run --user --scope --collect --quiet --unit=… -p MemoryMax=64M`
works, the scope's `memory.max` reads 67108864, `memory.peak` exists, and `systemctl --user show -p MemoryPeak` answers.

---

## L1 · Sessions and suites run capped (B1 sessions, B2, B3, B9; the OOM guard)

**Finding.** `session()` is `timeout "$SESSION_TIMEOUT" "$CLAUDE" -p …` (`lib/driver.sh:179`): wall time only,
SIGTERM only, and nothing stops what the session backgrounded. `lib/check.sh:21` runs the suite as a bare
`bash -c "$cmd"`, with no memory or time limit (and `:14`, the subset form, the same). On 2026-10-24 one red-phase
`deepEqual` diff grew to 6.5–9.6 GB four times and the kernel killed codium, claude-desktop and python instead.

1. **One helper.** `lib/scope.sh` (sourced; usage header): `scope_run <unit> <mem-high> <mem-max> <cmd…>` runs
   `systemd-run --user --scope --collect --quiet --unit=<unit> -p MemoryHigh=… -p MemoryMax=… -p MemorySwapMax=…`
   around the command and returns its exit; `scope_stop <unit>` stops it (killing whatever is left);
   `scope_peak <unit>` prints the peak in MB. Unit names are `harness-<run>-<role>[-<n>]`, with the run id reduced
   to `[A-Za-z0-9_-]` (systemd unit-name rules). If the probe `systemd-run --user --scope --quiet true` fails (no
   user bus), everything runs bare as today and the driver logs `note "no user systemd: sessions and suites run
   uncapped"` once per segment.
2. **Sessions.** `session()` runs `claude` in `harness-<run>-s<n>` under `timeout -k 30s "$SESSION_TIMEOUT"`, with
   `SESSION_MEMORY_HIGH=5G`, `SESSION_MEMORY_MAX=6G`, `SESSION_SWAP_MAX=1G` (`lib/config.sh` defaults,
   `templates/user/config.sh` commented). When `claude` returns, the driver reads the peak, then stops the scope, so
   dev servers, browsers, watchers and background shells the session left go with it. It logs
   `note "<kind> session left <n> process(es) running; stopped with its scope"` when there were any, and
   `note "<feature>: the session hit its memory cap (<max>)"` when the exit is 137 with the cap reached.
3. **Suites.** `check.sh` (full and subset) runs the command in its own scope, `harness-<run>-check-<pid>`, with
   `CHECK_MEMORY_MAX=3G` and `timeout -k 30s "$CHECK_TIMEOUT"` (default `15m`). The driver exports the unit prefix,
   since a session calls `check.sh` too. A kill shows in check's own RED line: `check: RED (killed at its 3G memory
   cap, exit 137 …)` or `check: RED (timed out after 15m …)`, so the session reads the reason, not a hang.
4. **Free memory before a session** (B3, the OOM finding's step 3). If `MemAvailable` (read from `HARNESS_MEMINFO`,
   default `/proc/meminfo`) is under `MEM_MIN_AVAILABLE_GB=5`, the driver logs it, stops the run's services (L2 when
   built), and polls every 5 minutes up to `MEM_WAIT_MAX=30m`; then it starts the session anyway with a note, since
   the cap now protects the box and a run that never starts helps nobody. *Default:* 5 (the audit's figure; the box
   idled at 7.7 GB available).
5. **Peaks are recorded.** Each session's `metrics.jsonl` line gains `mem_peak_mb` (from `scope_peak`, null when
   uncapped); `report.md` lists features whose sessions peaked over 2 GB. No `summary.json` field.
6. **Headless sessions load only their project's MCP servers** (B9). `session()` passes `--strict-mcp-config`, plus
   `--mcp-config "$WT/.mcp.json"` when the worktree has one (n8n-home commits its `.mcp.json` so run worktrees get
   the n8n servers). Check against the real `claude --help` text for both flags before relying on them, and record it.
7. **The prompt line** (the OOM finding's step 4, second to the guard): `prompts/parts/rules.md` gains one line: a
   red-phase test never compares large values with `deepEqual` (compare a length, a hash or the first mismatch), and
   after an exit 137 or a hang, don't rerun the same command: bound it (a `check.sh` subset, `--test-name-pattern`).

**Checks (written first):** a stub session's argv runs inside `systemd-run … --unit=harness-<run>-s<n>` with the three
memory properties and `timeout -k 30s`; after it returns, the stub `systemctl` saw `stop harness-<run>-s<n>.scope`
and `metrics.jsonl` has `mem_peak_mb` from the fixture; a stub session that leaves a background `sleep` gets the
"left 1 process" note; with the probe failing, the same run goes bare and logs the uncapped note once; `check.sh`
wraps its command the same way and turns exit 137 and 124 into the two RED lines; a `HARNESS_MEMINFO` fixture under
5 GB logs the wait and, with `MEM_WAIT_MAX` short, starts the session with its note; the session argv has
`--strict-mcp-config`, and `--mcp-config <wt>/.mcp.json` only when that file exists; the rendered coding prompt has
the deepEqual line. Real scope (when available): a 64M-capped `scope_run` of a process that allocates 256M exits 137
inside its scope, and the suite's own shell survives.

## L2 · Run services: a scope, a teardown hook, and every stop point (B1 services, B4)

**Finding.** `run_init` runs `bash -c "$INIT_CMD"` bare (`lib/driver.sh:237`). portfolio_site's init backgrounds
`next dev` and the only kill is the same run's next init, which kills the `npx` pid, not `next-server`. `finish`,
`harness stop`, `pause`, usage-limit waits and a driver crash stop nothing: the EXIT trap (`lib/driver.sh:83`) only
writes `ended`. hit_list's Supabase stack (13 containers) ran for 15 h, and docker containers live under `dockerd`,
where no cgroup of ours can see them.

1. **The services scope.** `run_init` first stops `harness-<run>-svc` if it exists (an init is what starts a
   session's services), then runs `INIT_CMD` in that scope under `timeout -k 10s "$INIT_TIMEOUT"` (default `10m`; it
   bounds the init's foreground, and what the init backgrounds stays in the scope), with `SVC_MEMORY_MAX=3G`.
2. **The teardown hook** (B4). `TEARDOWN_CMD`, defaulting to `.harness/teardown.sh` when that file is executable, runs
   with `HARNESS_PORT` and `HARNESS_SCRATCH` under `timeout 2m`, before the scope stops. It is for state a cgroup can't
   hold: hit_list's `npx supabase stop`, any project's `docker compose down` of a test stack. `templates/project/`
   gains a commented example; the projects' own files are theirs to add (README says how).
3. **`services_down <why>`** = teardown, then `scope_stop`, then `note "services stopped (<why>)"`. It runs:
   - in `finish`, whatever the reason;
   - in the EXIT trap, so a crash or a `kill` of the driver still stops them (the trap gains the call; it must not
     fail when nothing was started);
   - when the driver sees `PAUSE` (before its pause poll) and `STOP`;
   - before a usage-limit wait longer than `SVC_IDLE_STOP_MIN=10` minutes (`limit_wait`), and before L1's memory wait.
   The next `run_init` starts them again, so a resumed run needs nothing new.
4. **A killed driver** (SIGKILL: no trap) leaves units behind: `harness gc` stops every `harness-<run>-*` unit whose
   run has `ended` and no live `driver.pid` (`systemctl --user list-units 'harness-*' --plain --no-legend`, matched
   back to run ids it constructs, never parsed loosely), logging `+ stopped <unit> (<run> ended)`; `--dry-run` prints
   `would:`.
5. **What a run holds is visible.** `harness status` prints, under a live run, its units and their `MemoryCurrent`.

**Checks (written first):** the stub `systemd-run` sees `INIT_CMD` under `--unit=harness-<run>-svc` and `timeout -k
10s`, after a stop of the old one; a test project with an executable `.harness/teardown.sh` that touches a marker gets
it run, then the scope stopped, with the note, on each of: `finish`, a driver killed with SIGTERM (the trap), `PAUSE`,
`STOP`, and a stubbed usage-limit wait over 10 minutes (and not on one under it); `harness gc` stops the units of an
ended, dead-driver run and leaves a live run's alone (stub `list-units` output from a real fixture); `harness status`
shows the units.

## L3 · Scratch is cleaned, tmux sessions and supervisors go (B5, B7, H1)

**Finding.** `/tmp/harness/<project>/<run>` is never deleted: `check.out` plus a `check-<key>.out` per code tree
(`lib/check.sh:22`), sandboxes, `server.log`, screenshots, review diffs. Every `h-<run>` tmux session lives forever
through the driver window's `exec bash` and the `log` window's `tail -F` (`bin/harness:182-183`), and a manual start's
supervisor `claude` waits forever (`bin/harness:184-189`). All of it is on disk except the driver window's scrollback.

1. **Scratch** (B5). In `finish`, after the retro and the ledger, copy what the record needs into `$STATE`
   (`check-last.out` and `init.out`), then delete `$SCRATCH`: that run's directory only, never the project's
   directory above it (it holds `live.lock`). `KEEP_SCRATCH=1` keeps it, for debugging. `check.sh` keeps only the
   newest `check-<key>.out` (the green markers already live in `$STATE`). The driver exports `HARNESS_CACHE`
   (`~/.cache/harness/<project>`, kept across runs and boots) for installs a project shouldn't redo after every
   boot, such as Playwright browsers; the README tells projects to move those installs there.
   `templates/user/harness-tmpfiles.conf` holds the optional age rule for a crashed run's scratch
   (`e /tmp/harness - - - 3d`), with the one install command in README; Michael installs it.
2. **tmux** (B7, H1). H1 of the superseded spec holds as written, with today's line numbers:
   - **H1a.** When the driver exits, its window saves its scrollback to `<state>/tmux-driver.txt`
     (`tmux capture-pane -p -S -`), kills the `supervisor` window at once (there is nothing left to supervise), prints
     where the scrollback went, sleeps `TMUX_KEEP_HOURS` (default 24; 0 = at once), then kills its whole session
     (exact `=` target), which takes the `log` window too. A resume already kills the old session first
     (`bin/harness:181`), so no timer outlives a resume.
   - **H1b.** `harness gc` kills `h-<run>` for runs of that project with `ended`, no live `driver.pid` and no `PAUSE`,
     going run → session through `tmux_name` (never session → run: `.` becomes `-`), re-checking the driver just
     before the kill. Never `h-queue`, the desk session or a live run's.
   - **H1c.** The queue runner does the same reap across projects as it exits, before the debrief. One helper serves
     both.
   - Rejected again: counting supervisors and desks against `MAX_PARALLEL_RUNS`. Queue starts have no supervisor
     (`--no-supervisor`), H1a ends a manual start's supervisor with its driver, and a desk is Michael's conversation,
     which `harness gc` already closes when idle.

**Checks (written first):** `finish` leaves `$STATE/check-last.out` and no `$SCRATCH`, but keeps the project's
scratch directory and a `live.lock` in it; `KEEP_SCRATCH=1` keeps scratch; a second code tree's check leaves one
`check-*.out`; the init and sessions see `HARNESS_CACHE`; and H1's checks as listed in the superseded spec: with
`TMUX_KEEP_HOURS=0` no `h-<run>` is left after the driver exits and `tmux-driver.txt` is non-empty; with a keep window
the session stays but its `supervisor` window is gone; a run id with a `.`; gc reaps only the ended run among decoys
(`h-queue`, the desk session, a live-driver run, a paused run), `--dry-run` kills nothing, and one reap doesn't stop
the rest; the queue runner leaves no ended run's session behind and doesn't touch `h-queue`.

## L4 · gc runs by itself, and finishes (B8, R9, the `--all-merged` finding)

**Findings.**
- **`--all-merged` matches no branch with a slash in its name** (found in a chunk 3 catch-up, 2026-10-25). With
  `--all-merged`, `cmd_gc` swaps its pattern for `*` and lists `refs/heads/*` and `refs/remotes/origin/*`, but a `*`
  in a `git for-each-ref` pattern doesn't cross a `/`: on git 2.43, `refs/heads/*` lists `flat` and `main` and
  misses `harness/a` and `spec/b` (the trailing-slash prefix `refs/heads/` lists all four). Then `(( all )) && break`
  ends the loop after that one pass, so the `harness/*` and `harness-merge/*` passes never run either. So
  `--all-merged` collects *less* than plain gc: none of this repo's `spec/…`, `docs/…` or `harness/…` branches.
- **R9: gc stops at the first worktree with build output** (2026-10-21). portfolio_site's tree was clean, but
  gitignored `.next/` made `git worktree remove` refuse; the loop died there and nothing after it ran.
- **B8: gc is manual only**, the debrief may not run it (`lib/debrief.sh:205`, and it stays read-only), and it removes
  only merged worktrees, while `node_modules`, `.next` and `.venv` are 90% of the 7.3 GB under `~/worktrees`.

1. **`--all-merged` covers every branch.** List with prefixes (`refs/heads/`, `refs/remotes/origin/`), never a `*`
   glob, and run every pass rather than break. The plain passes use prefixes too (`refs/heads/harness/`,
   `refs/heads/harness-merge/`). Merged still means "an ancestor of `origin/main`" and local deletes stay `-d`.
2. **Removal finishes** (R9). A clean tree is removed with `git worktree remove --force` (ignored files are build
   output, never work), then `rm -rf` if the directory is still there; a failure is logged (`! could not remove
   <wt>: <why>`) and gc goes on to the next one.
3. **`--deps`.** In the worktrees of ended runs (ended, no live driver, no queued continuation, no open desk), even
   unmerged ones, delete the directories named by `DEPS_DIRS` (default `node_modules .next .next-check .venv`) and log
   the space freed. Never in a project's own checkout or a live run's worktree. They are cheap to rebuild; the run
   branch keeps every line of work.
4. **The queue runner collects as it drains.** Before the debrief, for each project it started a run in:
   `harness gc <project> --all-merged --deps`, its output into `runner.log`. A gc failure is logged and never stops
   the debrief.

**Checks (written first):** in the suite's throwaway repo and fake origin, `--all-merged` deletes merged `spec/x`,
`docs/y`, `harness/z`, `harness-merge/w` and `flat`, locally and on the origin, and keeps an unmerged `spec/u`; plain
gc deletes only the merged `harness/` and `harness-merge/` ones; a clean worktree holding an ignored `.next/` is
removed and the worktree after it is still processed; `--deps` empties an ended unmerged run's `node_modules` and
leaves a live run's and the main checkout's alone, `--dry-run` deleting nothing; the queue-runner test logs the gc
line before the debrief line.

## L5 · `MAX_PARALLEL_RUNS` applies without a runner restart (H2; optional, droppable)

H2 of the superseded spec as written: the runner re-runs `harness_config /nonexistent` at the top of each loop and logs
`MAX_PARALLEL_RUNS <old> → <new> (config reloaded)`; lowering it never stops a running run. Its two checks as written
there. If time is short, this milestone goes first: drop it and say so in the decision file.

---

## Milestones

| M | Contents | After |
|---|---|---|
| L1 | §L1: `lib/scope.sh`, capped sessions and suites, the memory gate, peaks, strict MCP, the prompt line | — |
| L2 | §L2: the services scope, teardown hook, stop points, gc of orphaned units, status | L1 |
| L3 | §L3: scratch, `HARNESS_CACHE`, the tmpfiles template, H1 | [] (independent) |
| L4 | §L4: `--all-merged` fix, R9, `--deps`, the runner's gc | [] (independent) |
| L5 | §L5: H2 | [] (independent; optional) |

Mark the independent milestones' first features with `"after": []` so a given-up feature in one doesn't stop the
others. Each milestone gets its decision file (`journal/decisions/<date>-<slug>.md`), its `architecture.md`,
`README.md` and `templates/` lines, and its checks in `tests/run.sh` written first and watched failing. The suite
must end green.

## After the run (Michael, README lines)

- With the scopes in, `systemd-oomd` can kill the offending `harness-*` scope instead of the desktop: enabling it
  with `ManagedOOMMemoryPressure=kill` on the user slice is a box setting (audit §3C.2), his call.
- `systemctl --user list-units 'harness-*'` shows what each run holds.
