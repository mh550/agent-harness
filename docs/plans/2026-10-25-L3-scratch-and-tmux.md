Milestone base: the L3-01 commit (`git log --format=%h -1 --grep '^L3-01:'`), the commit before L3-02's first

# L3 · Scratch is cleaned, tmux sessions and supervisors go (plan)

Spec: `docs/specs/2026-10-25-resource-lifecycle.md` §L3 (H1 of `docs/specs/2026-10-22-tmux-and-queue-hygiene.md` as
written there). This plan fixes the interfaces so L3-02 … L3-04 each build one thing and L3-05 reviews from the base
above. Build-only: tmux only on the suite's private server; the two tmux facts below were probed on a throwaway
private server in scratch (tmux 3.4, killed after). Builders: L3-02 = §1, §2, §3 · L3-03 = §4, §6.2 · L3-04 = §5,
§6.3. The checks, by name, in §7. Defaults this plan takes for Michael in §8; what it changes against the feature
list in §9.

## 0. What is there today (087760a)

- `SCRATCH=${HARNESS_SCRATCH_ROOT:-/tmp/harness}/$PROJECT_NAME/$RUN_ID` is built in one place, `prompt_vars`
  (`lib/prompt.sh:11`); the driver `mkdir -p`s it (`lib/driver.sh:43`). Nothing ever deletes it. It holds `init.out`,
  `teardown.out`, `check.out`, one `check-<key>.out` per code tree (`lib/check.sh:59`), `scopes/<unit>.{started,show}`,
  `entry-*`, `context.*`, `retro.md`, a project's dev DB, screenshots, review diffs; the stub's `sessions.log` and
  `count-*` in the suite. The green markers are in `$STATE/green` already (`HARNESS_CHECK_CACHE`, `prompt_env`).
- The project's scratch directory above it (`/tmp/harness/<project>/`) holds `live.lock` (`prompt_env`'s `LIVE_LOCK`
  default), shared with a live project's backup job: it must never go.
- `finish()` (`lib/driver.sh:483`) ends: … `ledger` → the continuation → `commit_all "HARNESS: run end notes"` when
  `$RUN_DIR` is dirty → `log "run kept in …"` → `exit 0`. The EXIT trap then runs; after `finish` it touches no scratch
  (`services_down` returns at once, `SVC_UP=0`; `scope_stop` writes nothing).
- `cmd_start` (`bin/harness:183-192`): `tmux_name` (`:73`, `h-${run//./-}`) → kill a same-name session (a resume) →
  `new-session -n driver "env $env driver.sh; echo; echo '[driver exited — this window stays open]'; exec bash"` →
  `new-window -n log "tail -F run.log"` → unless `--no-supervisor`, `new-window -n supervisor "claude --model … \"$(cat
  supervisor-prompt.md)\"; exec bash"`: bare `claude`, not `$HARNESS_CLAUDE`. Every suite run is `--foreground` today.
- `cmd_gc` (`bin/harness:337`): `set -euo pipefail` (the file's), a local `act`, the unit step (L2-05), then `git
  fetch` (a failed fetch ends gc), worktrees, branches. `lib/queue.sh` ends: the loop → `rm runner.pid` → `started=`
  → the detached debrief.
- tmux probes (2026-10-25, tmux 3.4, private server): a pane's own `tmux capture-pane -p -S - -t "$TMUX_PANE"` writes
  its scrollback; `tmux kill-window -t =<s>:supervisor` and `kill-session -t =<s>` work from inside that pane;
  `tmux display-message -p -t =<s>: '#{session_created}'` prints epoch seconds (the trailing `:` is needed: without it
  the target is read as a pane and prints nothing).

## 1. Scratch (L3-02)

### 1.1 The guard and the cleanup (`lib/prompt.sh`, beside `prompt_vars`, which builds `SCRATCH`)

```bash
# <dir>: rm -rf it only when it is this run's scratch directory as prompt_vars builds it, never its parent (live.lock)
scratch_rm() {
  local root=${HARNESS_SCRATCH_ROOT:-/tmp/harness}
  [[ $root == /?* && ${PROJECT_NAME:-} =~ ^[A-Za-z0-9._-]+$ && $PROJECT_NAME != . && $PROJECT_NAME != .. \
     && ${RUN_ID:-} =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ && $1 == "$root/$PROJECT_NAME/$RUN_ID" ]] || return 1
  rm -rf -- "$1"
}
```

Pure apart from the `rm`: L3-02's guard check sources `lib/prompt.sh` in a subshell (it runs nothing when sourced:
its command part is under the `BASH_SOURCE` test at the bottom; the builder confirms) and feeds it `/`, `""`,
`$root`, `$root/proj`, `$root/proj/`, `$root/proj/..`, `$root/proj/x/..`, a `RUN_ID=""`/`..` and a
`PROJECT_NAME=""`/`..`: each returns 1 and a marker file under `$T/guard/` is still there; the real one returns 0 and
is gone. L3-05 re-runs this check as its "SCRATCH=/ -shaped values" step.

### 1.2 In `finish`, after `ledger` and before the continuation

```bash
  scratch_done   # the record keeps the last suite and init output; the run's scratch goes (decisions/2026-10-25-scratch-cleanup)
```

```bash
scratch_done() {
  local f; for f in init.out teardown.out; do [[ -f $SCRATCH/$f ]] && cp -f "$SCRATCH/$f" "$STATE/$f"; done
  [[ -f $SCRATCH/check.out ]] && cp -f "$SCRATCH/check.out" "$STATE/check-last.out"
  if [[ $KEEP_SCRATCH == 1 ]]; then note "scratch kept (KEEP_SCRATCH=1): $SCRATCH"
  elif scratch_rm "$SCRATCH"; then note "scratch removed: $SCRATCH (check-last.out and init.out are in the state dir)"
  else note "scratch not removed: $SCRATCH is not this run's scratch directory"; fi
}
```

- Placed before the continuation so the existing "run end notes" commit picks the note up (no new commit).
- Only `finish` deletes. A crash, a SIGKILL or a `harness stop` mid-session leaves scratch for the tmpfiles rule
  (§3) and for Michael to read. A continued run recreates it (`lib/driver.sh:43`), and its first `run_init` rewrites
  `init.out`.
- `KEEP_SCRATCH=0` in `harness_config` (`lib/config.sh`), commented in `templates/user/config.sh`, listed in
  `docs/architecture.md` §10.

### 1.3 `check.sh` keeps one `check-<key>.out`

After `cp "$scratch/check.out" "$scratch/check-$key.out"` (`lib/check.sh:59`):
`find "$scratch" -maxdepth 1 -name 'check-*.out' ! -name "check-$key.out" -delete`. The green markers live in
`$cache` (`$STATE/green`) and are untouched. Two known effects, documented, not fixed: going back to an older green
tree prints `check: green (cached for this code tree)` without its test count (`testcount.mjs` gets a missing file:
the builder checks it prints nothing), and `finish`'s `tests-end` is then empty (`rm -f tests-end`, as today when
the file is missing).

### 1.4 `HARNESS_CACHE`

`prompt_env` exports `HARNESS_CACHE=${XDG_CACHE_HOME:-$HOME/.cache}/harness/$PROJECT_NAME`; the driver's `mkdir -p`
(`lib/driver.sh:43`) adds it. The init (`run_init`), every session and `check.sh` inherit it. No prompt line (the
static prefix stays as it is): projects use it from their init and `CLAUDE.md`, and the README tells them to put
Playwright browsers (`PLAYWRIGHT_BROWSERS_PATH=$HARNESS_CACHE/ms-playwright`) and similar installs there.

## 2. The suite's scratch-dependent checks keep their scratch

26 lines of `tests/run.sh` read `$T/scratch/<project>/<run>/…` after the run ended (the stub's `sessions.log`,
`count-*` across continuations, `teardown-done.marker`, `scopes/`, `server.log` …), three of them on `demo`. So:

- `KEEP_SCRATCH=1` goes into `$T/base-config.sh` (`tests/run.sh:32`) and into each line that writes
  `$T/user-config.sh` without starting from it (`grep -n '> "$T/user-config.sh"' tests/run.sh`: `:780`, `:944`,
  `:964`, `:966`, `:990`, `:992`, `:1075`, `:1146`, `:1159`, `:1349`, `:1357`, `:1359` today). The existing checks
  run as before.
- The scratch checks run with their own `HARNESS_CONFIG` (it is in `cmd_start`'s pass-through list):
  `{ cat "$T/base-config.sh"; echo KEEP_SCRATCH=0; } > "$T/scrub-config.sh"`, on a new foreground run `scrub`, not
  `demo` (§9). A run that ends fast without per-run stub flags: `--until-epoch $(( $(date +%s) - 1 ))` gives the
  initializer, then `deadline reached` → `finish "deadline"` (`lib/driver.sh:629`): init, suite, initializer, retro,
  ledger; nothing merges, so `origin/main` doesn't move under later checks.
- Before `scrub` starts: `mkdir -p "$T/scratch/proj" && echo lock > "$T/scratch/proj/live.lock"` (it may exist from
  earlier runs; the check needs the file).

## 3. The tmpfiles template (L3-02)

`templates/user/harness-tmpfiles.conf`:

```
# Optional (Michael installs it): removes what a crashed run left in its scratch after 3 days untouched. A run that
# finishes deletes its own scratch (finish); live.lock is a live project's flock file and is never aged out.
#   mkdir -p ~/.config/user-tmpfiles.d && cp templates/user/harness-tmpfiles.conf ~/.config/user-tmpfiles.d/harness.conf \
#     && systemd-tmpfiles --user --create
e /tmp/harness - - - 3d
x /tmp/harness/*/live.lock
```

README (box section) gets that one install command and one line: the age rule is applied by the user's
`systemd-tmpfiles-clean.timer` (the builder reads `systemctl --user is-enabled systemd-tmpfiles-clean.timer` on this
box, read-only, and says what it printed). 3 days: longer than a 72 h run, so a running run's quiet files survive.

## 4. H1a: the driver window (L3-03)

`TMUX_KEEP_HOURS=24` in `harness_config` (commented in `templates/user/config.sh`, §10 of the architecture). In
`cmd_start`, after `harness_config`: `[[ $TMUX_KEEP_HOURS =~ ^[0-9]+$ ]] || TMUX_KEEP_HOURS=24` (whole hours; the
value is baked into the window's command at start, so a resume picks up a change). The driver window's command:

```bash
  local s keep out; s=$(tmux_name "$run"); keep=$TMUX_KEEP_HOURS out=$state/tmux-driver.txt
  local after="tmux capture-pane -p -S - -t \"\$TMUX_PANE\" > $(printf %q "$out") 2> /dev/null"
  after+="; tmux kill-window -t $(printf %q "=$s:supervisor") 2> /dev/null; echo"
  after+="; echo $(printf %q "[driver exited — scrollback saved to $out; this session self-destructs in $keep h, or sooner on harness gc]")"
  after+="; sleep $(( keep * 3600 )); tmux kill-session -t $(printf %q "=$s")"
  tmux new-session -d -s "$s" -n driver -c "$wt" "env $env $(printf %q "$HARNESS_HOME/lib/driver.sh"); $after"
```

- Capture first (the pane holds the driver's output; the printed line comes after and isn't in the file), then the
  supervisor window (absent with `--no-supervisor`: ignored), then the line, the sleep, the whole session (the `log`
  window with it). `exec bash` goes; nothing outlives the timer. A resume kills the old session first
  (`bin/harness:184`), the old timer with it.
- `harness attach <run>` still works within the keep window; after it, `tmux-driver.txt` is the scrollback.
- The suite's EXIT trap kills its private server, so a keep-1 timer in a check dies with the suite.

## 5. H1b/H1c: one reaper (L3-04)

### 5.1 `lib/tmux.sh` (new, sourced by `bin/harness` and `lib/queue.sh`)

A sourced function, not an internal `harness _reap-tmux` subcommand: `cmd_gc` needs its `--dry-run` and `queue.sh`
needs each line in `runner.log` through its `log`, both a few lines either way, and a function keeps `tmux_name` in
one place. `tmux_name` moves here from `bin/harness:73`.

```bash
# shellcheck shell=bash
# Run → tmux session, and the reaper of finished runs' sessions (decisions/2026-10-25-tmux-reaper).
#   tmux_name <run>                    → h-<run>, dots as dashes; always run → session, never session → run
#   tmux_reap <dry 0|1> <state dir>…   → kills h-<run> of each run that ended, has no live driver and no PAUSE; a line each
tmux_name() { echo "h-${1//./-}"; }
tmux_live() { local p; p=$(cat "$1/driver.pid" 2> /dev/null) && [[ -n $p ]] && kill -0 "$p" 2> /dev/null; }
tmux_reap() {
  local dry=$1 d r s c; shift
  command -v tmux > /dev/null || return 0
  for d in "$@"; do
    d=${d%/} r=${d##*/}; s=$(tmux_name "$r")
    [[ -f $d/ended && ! -f $d/PAUSE ]] && ! tmux_live "$d" || continue
    c=$(tmux display-message -p -t "=$s:" '#{session_created}' 2> /dev/null) || continue   # no such session
    (( c > $(stat -c %Y "$d/ended" 2> /dev/null || echo 0) )) && continue   # created after the run ended: a resume's, its driver not up yet
    if (( dry )); then echo "would: tmux kill-session -t =$s ($r ended)"; continue; fi
    tmux_live "$d" && continue   # re-checked just before the kill: a resume between the scan and here wins
    if tmux kill-session -t "=$s" 2> /dev/null; then echo "+ reaped tmux session $s ($r ended)"
    else echo "! could not kill tmux session $s ($r ended)"; fi   # never fatal: the next run is still reaped
  done
  return 0
}
```

- Run → session only: the names it can kill are `tmux_name` of a real state dir's run id, so `h-queue` and the desk
  session (`h-desk`, `$HARNESS_DESK_SESSION`) can't be named unless a run is called `queue` or `desk`: `cmd_start`
  already refuses `desk` and `debrief` (`bin/harness:140`); the builder adds `queue` there (`run-id 'queue' is taken
  by the queue runner (tmux h-queue)`), with a check folded into check 10.
- The session-created guard closes the one race the liveness re-check leaves: `harness start`/`continue` creates
  the new session before the new driver writes `driver.pid` and removes `ended`. So a check creates its decoy
  sessions first and writes their `ended` after (same second is fine: the test is `>`), except the one standing for
  a resume.
- `if … then … else` around the kill: `bin/harness` runs under `set -e`.

### 5.2 Callers

- `cmd_gc`, right after the unit step and before `git fetch` (a failed fetch ends gc under `set -e`, and an ended
  run's session has nothing to do with origin): `tmux_reap "$dry" "$STATE_ROOT/$(basename "$p")"/*/`. Its own lines,
  not `act`'s `+ tmux kill-session …`, so the `+`/`would:`/`!` shape matches the unit step's (§9).
- `lib/queue.sh`, after `rm -f "$Q/runner.pid"; trap - EXIT` and before `started=`: `source
  "$HARNESS_HOME/lib/tmux.sh"` at the top beside `lib/config.sh`, then
  `while IFS= read -r l; do log "$l"; done < <(tmux_reap 0 "$STATE_ROOT"/*/*/)`, on every exit, across projects, on
  whatever server the runner's `TMUX_TMPDIR`/`TMUX` names (the suite's private one in tests).

## 6. How the suite drives real tmux runs

### 6.1 At the top of `tests/run.sh`, before anything starts the private server

The private server's global environment is the suite's at the moment the first `tmux new-session` starts it, and
tmux windows get that, not the caller's: so these are exports at the top, next to `TMUX_TMPDIR` (`:8`).

```bash
mkdir -p "$T/bin"; printf '#!/usr/bin/env bash\nexec %q "$@"\n' "$HERE/stub-claude.sh" > "$T/bin/claude"; chmod +x "$T/bin/claude"
export PATH=$T/bin:$PATH XDG_CACHE_HOME=$T/cache   # a supervisor window's bare `claude` is the stub; caches stay in $T
```

- A wrapper, not a symlink: `stub-claude.sh` finds its fixtures through `dirname "$0"`.
- The supervisor window runs `claude --model … "<prompt>"`: no `-p`, no `--remote-control`, so the stub reads its
  prompt from the pane's tty and waits there, a live supervisor until H1a kills its window.
- The driver reaches the stub through `HARNESS_CLAUDE` (already in `cmd_start`'s pass-through list); the rest of the
  `HARNESS_*` overrides travel the same way. `STUB_*` flags set on one command line don't reach a tmux window, so the
  tmux runs use none: they end through the past `--until-epoch` of §2.
- `XDG_CACHE_HOME=$T/cache` keeps every run's `HARNESS_CACHE` in `$T` (`$T/cache/harness/proj`), tmux-started or not.

### 6.2 The H1a runs (L3-03), at the end of the suite (after the weekly block, before the summary)

```bash
{ cat "$T/base-config.sh"; echo TMUX_KEEP_HOURS=0; } > "$T/keep0.sh"; { cat "$T/base-config.sh"; echo TMUX_KEEP_HOURS=1; } > "$T/keep1.sh"
PAST=$(( $(date +%s) - 1 ))
HARNESS_CONFIG=$T/keep0.sh "$H" start "$T/proj" tmux0 --spec SPEC.md --until-epoch "$PAST" --now > "$T/tmux0.out" 2>&1
HARNESS_CONFIG=$T/keep0.sh "$H" start "$T/proj" dot.run --spec SPEC.md --until-epoch "$PAST" --now --no-supervisor > "$T/tmuxdot.out" 2>&1
HARNESS_CONFIG=$T/keep1.sh "$H" start "$T/proj" tmux1 --spec SPEC.md --until-epoch "$PAST" --now > "$T/tmux1.out" 2>&1
```

- `--now`: the suite's `MAX_PARALLEL_RUNS=1` would queue the second; the three run side by side (distinct ports,
  branches and scratch), about one run's time.
- `HARNESS_CONFIG` is passed to the driver window, so driver and `cmd_start` read the same keep value.
- Right after `tmux1`'s start: `tmux list-windows -t =h-tmux1 -F '#W'` lists `supervisor` (the check proves the kill
  has something to kill).
- Waiting: `ended() { local i; for i in $(seq 600); do [[ -f $1/ended && ! -f $1/driver.pid ]] && return 0; sleep 0.1; done; return 1; }`
  (≤ 60 s; `ended` alone isn't it: `finish` writes it before the retro). Then `gone <s>` polls `tmux has-session -t
  "=<s>"` ≤ 10 s (100 × 0.1); for keep 1, poll ≤ 10 s for `-s tmux-driver.txt` and for no `supervisor` in the window
  list, then assert the session is still there and `tmux kill-session -t =h-tmux1` (the check's own cleanup, before
  the gc checks).

### 6.3 The reaper checks (L3-04)

- **gc**, after §6.2: state dirs under `$HARNESS_STATE/proj/` with `: > meta.env`: `gone1` (`ended`, no
  `driver.pid`), `gone2` (`ended`, `driver.pid` of a finished `true &`), `livey` (`ended` and `driver.pid` = `$$`:
  the liveness guard, not a missing `ended`, has to save it), `pausy` (`PAUSE`, no `ended`, as the step says),
  `pausx` (`PAUSE` and `ended`: the `PAUSE` guard itself) and `fresh` (dead driver, `ended` from an hour ago:
  `touch -d '1 hour ago'`, so its session, created now, is a resume's). Order: the sessions first (`tmux new-session
  -d -s <s> sleep 600`: `h-gone1 h-gone2 h-livey h-pausy h-pausx h-fresh h-queue` and `$HARNESS_DESK_SESSION` when it
  doesn't exist; the desk checks may have closed it), then the markers, so every other `ended` is not older than its
  session. `"$H" gc "$T/proj" --dry-run`
  then `"$H" gc "$T/proj"`; afterwards kill the decoy sessions left and `rm -rf` the decoy state dirs (`livey`'s pid
  is the suite's own: `alive_count` would count it).
- **The queue runner**, on the first runner check (`tests/run.sh:861-863`): `D=$(date +%F)` moves above it; before
  the runner, `tmux new-session -d -s "h-proj-$D" sleep 600`, the same for `h-proj-$D-2`, and decoys `h-queue` and
  `$HARNESS_DESK_SESSION` (both killed after the check, so the desk checks start as before). Its runs are
  `--foreground` (`HARNESS_QUEUE_FOREGROUND=1`), so those sessions stand for the windows a tmux start would have
  left; their `ended` is written after they were created, so the resume guard lets them go.

## 7. The checks, by name (written first, watched failing)

L3-02 (`tests/run.sh`, a `scrub` block after the L2 run blocks, and the cache lines in the stub):
1. `finish keeps check-last.out and init.out in the state dir and deletes the run's scratch, not the project's (live.lock stays)`
   — `$HARNESS_STATE/proj/scrub/{check-last.out,init.out}` non-empty, no `$T/scratch/proj/scrub`, `$T/scratch/proj/live.lock`
   there, `hlog scrub` has `scratch removed: $T/scratch/proj/scrub`.
2. `KEEP_SCRATCH=1 keeps the run's scratch; the default is 0` — `demo`'s scratch exists (base config) and `hlog demo`
   has `scratch kept (KEEP_SCRATCH=1)`; `( source lib/config.sh; HARNESS_CONFIG=/dev/null harness_config /nonexistent; [[ $KEEP_SCRATCH == 0 ]] )`.
3. `check.sh keeps one check-<key>.out; the green markers stay` — in a throwaway repo, `check.sh` on two trees (two
   commits) with `HARNESS_CHECK_CACHE=$T/ckc`: one `check-*.out` (the second tree's), both `green-*` in `$T/ckc`.
4. `the init and the sessions see HARNESS_CACHE (XDG_CACHE_HOME/harness/<project>), created` — the suite project's
   `INIT_CMD` (`tests/run.sh:40`) gains `echo "cache: $HARNESS_CACHE"`, so `$HARNESS_STATE/proj/scrub/init.out` has
   `cache: $T/cache/harness/proj`; stub-claude appends `$HARNESS_RUN_ID ${HARNESS_CACHE:-unset}` to
   `$STUB_DIR/cache.log` (not scratch: scrub's goes), which has `scrub $T/cache/harness/proj`; `-d $T/cache/harness/proj`.
5. `scratch_rm refuses anything but the run's own scratch directory` — §1.1's values.
6. `the tmpfiles template holds the 3-day age rule; README has its install command` — `grep -qx 'e /tmp/harness - - - 3d'`,
   the `x … live.lock` line, README greps `user-tmpfiles.d` and `HARNESS_CACHE`.

L3-03 (the §6.2 block):
7. `tmux: TMUX_KEEP_HOURS=0: the driver window saves its scrollback and kills h-<run> when the driver exits` (`tmux0`, with a supervisor)
8. `tmux: a keep window keeps h-<run>, its supervisor window gone, the scrollback saved` (`tmux1`; also `TMUX_KEEP_HOURS` defaults to 24)
9. `tmux: run id dot.run gets session h-dot-run, gone at keep 0` (`h-dot-run` listed right after its start)

L3-04 (§6.3):
10. `harness gc reaps only the ended runs' tmux sessions (h-queue, the desk, a live driver, a paused run, a resume's session survive)`
    — exactly `+ reaped tmux session h-gone1 (gone1 ended)` and `… h-gone2 (gone2 ended)` in the output, and the
    other six sessions exist.
11. `harness gc --dry-run kills no tmux session` — `would: tmux kill-session -t =h-gone1 (gone1 ended)` printed and
    every decoy session still exists.
12. `the queue runner reaps its ended runs' tmux sessions before the debrief; h-queue and the desk untouched` —
    no `h-proj-$D` or `h-proj-$D-2`, `h-queue` and the desk session exist, and in `runner.log` the `reaped tmux
    session h-proj-$D` line comes before `harness debrief (detached`.

L3-05 adds its review's checks; check 5 is its guard check.

## 8. Defaults taken (each recorded in its decision file as `*default*`)

- `KEEP_SCRATCH=0`; only `finish` deletes; `teardown.out` is kept beside `init.out` and `check-last.out` (a failed
  teardown's note points there). → `decisions/2026-10-25-scratch-cleanup`
- The tmpfiles template also excludes `live.lock` (`x`): aging out a held flock file would let a second writer in.
  → same file
- No prompt line for `HARNESS_CACHE` (static prefix unchanged). → same file
- `TMUX_KEEP_HOURS` in whole hours; anything else is 24. → `decisions/2026-10-25-tmux-driver-window`
- The reaper is a sourced `lib/tmux.sh`, with a session-created guard beyond the spec's, and `queue` joins `desk` as
  a refused run id. → `decisions/2026-10-25-tmux-reaper`

## 9. Against the feature list (for `proposed_changes`)

- L3-02 step 1 names run `demo`: the check runs on a new run `scrub` with `KEEP_SCRATCH=0`, since `demo`'s three
  checks read its scratch after the run (§2); `demo` instead shows `KEEP_SCRATCH=1` (check 2).
- L3-04 step 1 says gc calls the reaper "through act": gc's reap lines are `+ reaped …`/`would: tmux kill-session …`
  from the helper, the unit step's shape; `act` would print the bare command and couldn't carry the run.
- L3-04 step 2's paused decoy has no `ended`, so it can't exercise the `PAUSE` guard; the plan adds `pausx`.
