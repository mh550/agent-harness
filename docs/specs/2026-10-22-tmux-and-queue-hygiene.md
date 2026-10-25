# tmux session hygiene and live-config parallelism (2026-10-22)

**Superseded 2026-10-25** by `docs/specs/2026-10-25-resource-lifecycle.md`: H1 is its §L3 and H2 its §L5. This file
stays for the findings and the detailed checks the new spec cites. Build from the new spec.

**Goal.** Stop ended runs' tmux sessions from piling up, and let `MAX_PARALLEL_RUNS` change without restarting the
queue runner. Two small, independent changes to the CLI (`cmd_start`, `cmd_gc`) and the queue runner (`lib/queue.sh`),
each test-first with a check in `tests/run.sh`, a `D-H<n>` entry, and its `architecture.md`/`README.md` lines.

**Rules.** `CLAUDE.md` binds: work only in the worktree, never touch real runs or real state, every behaviour visible
in `harness-log.md`/the CLI and checked in `tests/run.sh`. **All tmux checks run on the suite's private tmux server**
(`tests/run.sh` already sets `TMUX_TMPDIR=$T/tmux` and a per-pid `HARNESS_DESK_SESSION`; it unsets `TMUX`/`TMUX_PANE`
first). A test **never** calls `tmux` against Michael's server and **never** touches `h-queue`, `h-desk`, `overnight`,
`rc-host` or any session that is not one this suite created. `node --check` every `.mjs`, `bash -n` every shell file
touched. Proceed on the defaults below, record them as `D<n> *default*`-style notes in the decision entries; never park.

**Start from `main` as it stands, and rebase on what is already there.** The queued `agent-harness-2026-10-21-retro`
run's **R9** rewrites `cmd_gc` (worktree removal with `--force` + `rm -rf`, "one failure must not stop the rest of gc")
and its **R6** touches `queue add --continue`/`cmd_continue` in `bin/harness`. If those PRs are still open when this
run starts, keep this diff **small and separable** around `cmd_gc` and `lib/queue.sh`: add the tmux reap as its own
block/helper rather than reflowing R9's loop, and leave R6's continuation code alone. If they have merged, build on
them. Nothing here conflicts with the measure-then-memory (E1–E4) run.

---

## H1 · tmux sessions of ended runs go away by themselves and are reaped (issue A)

**Finding.** Every run gets a tmux session `h-<run>` (`bin/harness` `cmd_start`): a `driver` window, a `log` window
(`tail -F run.log`), and optionally a `supervisor` window. The driver window ends in `exec bash`
(`bin/harness:164`), so the window — and therefore the session — lives forever after the driver exits. `harness
status` currently lists ~10 ended runs whose worktrees are kept; each left a lingering `h-<run>` session until the
box was restarted or they were killed by hand. Everything those sessions show is already on disk (`run.log`,
`logs/*.jsonl`, the committed run record); the **one** thing only the session holds is the driver window's
scrollback. `cmd_start` already kills a same-name session when a run resumes (`bin/harness:163`), so a reaper can
never fight a resume: a resumed run has a fresh `driver.pid` and no `ended`.

**The signal.** A run is finished and reapable when `<state>/ended` exists **and** `<state>/driver.pid` does not name
a live process (`driver.sh:84` writes the pid at start and removes it in the EXIT trap, which also writes `ended` —
`driver.sh:86`). A paused run has a live driver and no `ended`, so it is never reapable; a resuming run has a fresh
live pid.

**The session name.** `tmux_name()` maps `.` → `-` (`bin/harness:54`: `h-${run//./-}`), so a run id and its session
name can differ. Always go **run → session** (compute `tmux_name "$run"` for each run), never session → run. This
also means the reaper only ever targets names it constructs from real run ids, so it cannot name `h-queue`/`h-desk`.

### H1a · The driver window saves its scrollback and self-destructs after a keep window

The authoritative reaper is H1b/H1c (whole-session kill). H1a is the backstop for when neither runs for a long time,
and it preserves the scrollback. Because the `log` and `supervisor` windows otherwise outlive the driver, the driver
window **kills the whole session** on its timer rather than just exiting itself.

Change the driver window's trailing command (`bin/harness:164`) from `…driver.sh; echo; echo '[driver exited …]';
exec bash` to, after the driver exits:

1. capture its own scrollback once to `<state>/tmux-driver.txt` (`tmux capture-pane -p -S - > "$state/tmux-driver.txt"
   2>/dev/null` — the pane still exists; `-S -` is from the top of history);
2. print `[driver exited — scrollback saved to <state>/tmux-driver.txt; this session self-destructs in
   <TMUX_KEEP_HOURS> h, or sooner on `harness gc`]`;
3. `sleep` for `TMUX_KEEP_HOURS` hours (new config, **default 24**; `0` = destroy at once, no keep window) and then
   `tmux kill-session -t "=<s>"` (exact target), which takes the `log` and `supervisor` windows with it.

`TMUX_KEEP_HOURS` is added to `lib/config.sh` defaults and to `templates/user/config.sh` (commented). A resume kills
the old same-name session first (`bin/harness:163`), so the old timer dies with it — no double-destruct.

**Checks (written first, watched failing):**
- With `TMUX_KEEP_HOURS=0` and a stubbed/short-circuited driver (the suite's foreground/driver stub), starting a run
  on the private server leaves **no** `h-<run>` session once the driver has exited, and `<state>/tmux-driver.txt`
  exists and is non-empty.
- With a normal keep window the session is still present right after the driver exits, and `tmux-driver.txt` is
  written (assert the file, not a 24 h wait).
- A run id containing a `.` produces session `h-<run-with-dots-as-dashes>` and the above still holds (exercise
  `tmux_name`'s substitution).

### H1b · `harness gc` reaps ended runs' sessions

In `cmd_gc`, after the existing worktree/branch/desk housekeeping (and after R9's worktree-removal block if it is
present), add a self-contained reap step: for every run state dir of this project (`$STATE_ROOT/<project>/*`), if
`<state>/ended` exists, `<state>/driver.pid` is not alive, and `<state>/PAUSE` is absent, compute `s=$(tmux_name
"$run")` and `tmux has-session -t "=$s"` → `tmux kill-session -t "=$s"` (exact `=` target), logging `+ reaped tmux
session <s> (<run> ended)`. `--dry-run` prints `would: kill-session …` (reuse the existing `act`). **Never** kill a
session whose name is not `h-<run>` for an ended, dead-driver run — in particular never `h-queue`, the desk session
(`${HARNESS_DESK_SESSION:-h-desk}`), or a session with a live driver or a `PAUSE` marker. Re-check `driver.pid`
liveness immediately before the kill (a resume between the scan and the kill must win).

**Checks (written first):**
- On the private server, create `h-<run>` for an ended run (write `<state>/ended`, no live `driver.pid`) plus a decoy
  `h-queue`, a decoy desk session, and an `h-<run2>` for a run with a **live** `driver.pid`. `harness gc <project>`
  kills only the ended run's session; `h-queue`, the desk session and the live run's session survive.
- A run with `<state>/PAUSE` and no `ended` is not reaped.
- `harness gc <project> --dry-run` prints the `would:`/`would kill` line and kills nothing.
- `harness gc` still processes later runs after reaping one (one reap must not short-circuit the rest; mirrors R9's
  "one failure must not stop the rest").

### H1c · The queue runner reaps on exit

At the end of `lib/queue.sh` (the exit path, around the `started`/debrief block, lines 58–63), before launching the
debrief, run the **same reap** across all projects' ended, dead-driver runs on whatever tmux server the runner is on
(the runner inherits `TMUX_TMPDIR` in tests). Factor the reap into one helper both `cmd_gc` and `queue.sh` call so the
two never drift — e.g. a `harness` subcommand `harness _reap-tmux [<project>]` (underscore = internal, not in help) or
a tiny sourced function; whichever keeps the queue-runner diff a few lines. The runner must **never** kill its own
`h-queue` session or the desk session, or any live-driver session; the H1b guards apply unchanged.

**Checks (written first):**
- The queue-runner test (the suite already drives `queue.sh` in foreground) leaves no `h-<run>` session for a run it
  started that has ended, and leaves `h-queue`/the desk session untouched while it is still running the next entry.

**Decision (next free `D-H<n>`).** *Finding:* driver windows `exec bash`, so `h-<run>` outlives the run; ~10 ended
runs' sessions accumulated on the box with nothing to reap them; all their content is on disk except the driver
scrollback. *Choice:* the driver window saves its scrollback to `<state>/tmux-driver.txt` and self-destructs the whole
session after `TMUX_KEEP_HOURS` (default 24); `harness gc` and the queue runner reap `h-<run>` sessions of runs with an
`ended` marker and no live driver, by `tmux_name`, skipping `h-queue`, the desk session, live-driver and paused runs.
*Rejected:* only the driver window self-exiting (the `log`/`supervisor` windows keep the session alive); reversing
session→run by name (`tmux_name`'s `.`→`-` makes it lossy); a `TMUX_KEEP_HOURS` of 0 as the default (Michael may want
to read a just-finished run's scrollback).

---

## H2 · `MAX_PARALLEL_RUNS` applies without restarting the runner (issue B — optional; Michael may drop this)

**Finding.** `lib/queue.sh` sources the config **once** at startup (`queue.sh:17`, `harness_config /nonexistent`) and
reads `MAX_PARALLEL_RUNS` and `WEEKLY_STOP_AT` from that snapshot for the whole run of the loop (used at
`queue.sh:42` and via `weekly_over` at `:48`). Changing `~/.config/harness/config.sh` has no effect until the runner
is restarted, and a clean `harness queue stop` triggers a debrief — so there is no quiet way to widen or narrow live
parallelism. `harness_config` is idempotent (it resets every variable to a default, then re-sources the layers), so
re-running it per iteration is safe; the loop consumes only `MAX_PARALLEL_RUNS` and `weekly_over`.

**Change.** At the top of the `while` loop in `lib/queue.sh`, re-run `harness_config /nonexistent` (same call as line
17), capturing the old `MAX_PARALLEL_RUNS` first. When it changes, `log "MAX_PARALLEL_RUNS <old> → <new> (config
reloaded)"`. Lowering it never stops a running run — the loop only gates *starting* new runs (`:42`), so runs already
alive keep going until they finish; raising it lets the next poll start more. `POLL` stays as set at startup (it is an
env var, `queue.sh:15`, not config). No other loop behaviour changes.

**Checks (written first):**
- A queue-runner test with `MAX_PARALLEL_RUNS=1`, two startable entries for **different** projects queued, and a
  config edit to `2` mid-run: within one poll the runner starts the second run and logs the `1 → 2` change. (Use the
  suite's private config file / `HARNESS_CONFIG`; drive the loop with the existing short `HARNESS_QUEUE_POLL`.)
- Lowering `2 → 1` while two runs are alive stops no running run and logs the change; the next startable entry waits.

**Decision (next free `D-H<n>`).** *Finding:* `MAX_PARALLEL_RUNS` is read once at runner startup, so an edit needs a
restart, and a clean stop debriefs. *Choice:* the runner re-runs `harness_config` each loop iteration and logs a
change to `MAX_PARALLEL_RUNS`; lowering never stops running runs. *Rejected:* a signal/`SIGHUP` handler (more moving
parts than a per-poll re-source for a 30 s loop); re-reading inside `harness start` only (the runner is the live
gate).

> **Optional.** If Michael drops H2, delete this section and its milestone row; H1 stands alone and is the reason the
> run is queued now.

---

## Docs

- `architecture.md` §3 (`lib/queue.sh` row), §4 (add `tmux-driver.txt` to the per-run state list and note the
  reap), §10 (new `TMUX_KEEP_HOURS` convention), §12 (queue: live re-read of `MAX_PARALLEL_RUNS`), §13 "Extending it"
  if a row fits, and §17 is untouched (the desk owns `h-desk`; the reaper never touches it).
- `README.md`: the steering/queue sections — a line that ended runs' tmux sessions self-clear (`TMUX_KEEP_HOURS`,
  `harness gc`) and that `MAX_PARALLEL_RUNS` now applies to a live runner.
- `templates/user/config.sh`: `TMUX_KEEP_HOURS` (and nothing else — H2 reads existing `MAX_PARALLEL_RUNS`).

## Milestones

| M | Contents | After |
|---|---|---|
| H1 | §H1 (H1a driver self-destruct + scrollback, H1b gc reap, H1c queue-runner reap) | — |
| H2 | §H2 (live `MAX_PARALLEL_RUNS`) — **optional, droppable** | [] (independent of H1) |

Each milestone gets its `D-H<n>` entries (the next free numbers at build time — the measure and retro runs will have
consumed some; do not hardcode), the `architecture.md`/`README.md`/`templates` lines in the same milestone, and its
checks in `tests/run.sh` written first and watched failing. The suite must end green (`N/M checks passed`, every
check passing). `MERGE_POLICY=pr`: open the milestone PRs, never merge them.
