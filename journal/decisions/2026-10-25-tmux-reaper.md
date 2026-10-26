# harness gc and the queue runner reap the tmux sessions of ended runs, run → session

*(2026-10-25, run agent-harness-2026-10-25-lifecycle, feature L3-04; spec `docs/specs/2026-10-25-resource-lifecycle.md`
§L3 (H1b/H1c of `docs/specs/2026-10-22-tmux-and-queue-hygiene.md`), plan
`docs/plans/2026-10-25-L3-scratch-and-tmux.md` §5, §6.3, §8)*

- **Finding:** the driver window now closes `h-<run>` after `TMUX_KEEP_HOURS` (decisions/2026-10-25-tmux-driver-window),
  but nothing closed it sooner, and a session whose driver window was killed by hand, or started before that change,
  had no timer at all. The window's own line promises "or sooner on harness gc". A runner night leaves one such session
  per run until the timers fire, and the debrief that follows reads a box still full of them.
- **Choice:**
  - **One helper, `tmux_reap <dry> <state dir>…` in a new `lib/tmux.sh`** (with `tmux_name`, moved there from
    `bin/harness`), sourced by `bin/harness` and `lib/queue.sh`. For each state dir it kills `h-<run>` only when the
    dir has `meta.env` (a run's, not `queue/done`) and `ended`, its `driver.pid` is not alive (checked again just
    before the kill: a resume between scan and kill wins) and there is no `PAUSE`. Lines: `+ reaped tmux session <s>
    (<run> ended)`, `would: tmux kill-session -t =<s> (<run> ended)` on a dry run, `! could not kill …` on a failed
    kill, which never stops the rest (`if/else`: `bin/harness` runs under `set -e`). Exact `=<s>` targets.
  - **Run → session, never session → run.** The only names it can kill are `tmux_name` of a real state dir's run id,
    so `h-queue`, `h-desk` (`$HARNESS_DESK_SESSION`) and Michael's own sessions are never candidates. ***default*:
    `harness start` refuses run id `queue`** (beside `desk` and `debrief`), the one id whose session would be
    `h-queue`.
  - **A session name another run shares is kept while that run isn't done** (found building it: `tmux_name` is lossy,
    `a.b` and `a-b` of any two projects are both `h-a-b`): every state dir of the same root is checked, and one that
    is live, paused or not ended keeps the session.
  - ***default*: a session created after its run's `ended` is spared** (`#{session_created}` > the mtime of `ended`):
    `harness start`/`continue` creates the new session before the new driver writes `driver.pid` and removes `ended`,
    the one window the liveness re-check can't see.
  - **`harness gc <project>`** reaps its project's runs (`<state>/<project>/*/`), right after the unit step and before
    `git fetch` (a failed fetch ends gc; a session has nothing to do with origin). ***default*:** its lines are the
    helper's, the unit step's `+`/`would:`/`!` shape, not `act`'s bare `+ tmux kill-session …`, which couldn't name the
    run (the feature step said "through act").
  - **The queue runner** reaps every project's runs as it exits, whichever way, after `runner.pid` goes and before
    the debrief line, each line logged to `runner.log`.
- **Rejected:**
  - **Parsing `tmux list-sessions`** for `h-*` names and mapping them back to runs: `tmux_name` is lossy (`a.b` and
    `a-b` are both `h-a-b`), and every session that merely looks like a run's (`h-queue`, `h-desk`, a hand-made one)
    would be a candidate guarded only by a deny-list.
  - An internal `harness _reap-tmux` subcommand for the runner: gc needs its `--dry-run` and the runner each line
    through its `log`; a sourced function keeps `tmux_name` in one place for both.
  - Reaping in `finish`: the driver window already closes its session after the keep window, and Michael may want
    that window; gc and the runner's exit are the moments nobody is reading it.

## L3-05: the L3 review's tmux fixes

*(2026-10-25, run agent-harness-2026-10-25-lifecycle, feature L3-05; review `docs/plans/2026-10-25-L3-review.md` #1, #2, #9)*

- **Finding:** `cmd_start` killed any existing `h-<run>` before creating its own, checking only that this project's
  run wasn't alive. A start of `fix` in project B killed project A's live `fix` (or `a-b` killed `a.b`'s), and its
  driver died on the SIGHUP. `queue_ensure_runner` targeted `h-queue` by prefix, so with no exact `h-queue` it killed
  a run's `h-queue-x` or `h-queuefix`, and `harness attach` landed in `h-<run>-2`. The reaper killed by name, so a
  resume between its scan and its kill could lose the new session.
- **Choice:**
  - **`harness start` refuses a run id whose `h-<run>` another run that isn't done holds** (`tmux_shared`, any
    project, the reaper's own test; `TMUX_OTHER` names it in the message), in every mode, before any worktree or
    state is made. It closes the L2 review's deferred #5 too: those two runs would also share `harness-<id>-*` units.
  - **Exact targets** for `h-queue` (has-session and kill-session) and `attach`.
  - **The reaper kills by session id** (`#{session_id}`, read in the same `display-message` as the creation time).
- **Rejected:**
  - Refusing only in tmux mode: a foreground run of a shared id still shares its systemd unit names.
  - Refusing only a *live* other run: a paused or crashed one comes back with `harness continue` into the same names;
    the message says which run to end or continue.
  - Sparing sessions with a client attached in the queue runner's reap (review #11): left. The runner exits after
    its runs ended and gc is Michael's own command; `tmux_reap` would need an attached-check per caller.
