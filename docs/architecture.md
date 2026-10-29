# agent-harness — architecture (v3.1)

How the harness works, at the level you need to maintain and extend it. The README is the quick start; the
journal (`journal/`) is the history of why. This file is the system as it is.

## 1. What it is, in one paragraph

A run turns a spec into merged, verified code without anyone watching. One **initializer** session (Fable) writes a
feature list. A **driver** (bash, deterministic, $0) then starts one fresh headless Claude session per feature, in
dependency order, and does all the bookkeeping around them: init, suite, sync, guards, metrics. When every feature of
a milestone passes, an independent **verify** session re-runs every step. A verified milestone is tagged and
**merged into `main` through its own PR**. At the end the driver writes a summary, runs a **retro** session that
proposes harness changes, and records the run in the harness's own **ledger**. Runs are queued, and they share one
view of the plan's usage limit. When a queue ends, one read-only **debrief** session writes Michael a triage note.

## 2. Principles (each one is a decision in `journal/decisions.md` or `journal/decisions/`)

| Principle | Consequence in the code |
|---|---|
| **Fresh context per feature; state lives on disk** (D-H1) | Sessions know only the feature list, `progress.md`, `INBOX.md`, git and the prompt. Nothing is carried in memory between sessions |
| **Agents do judgment; the driver does bookkeeping** (D-H5) | Everything that must happen every time is bash: init, suite, sync, repair, un-pass, verify scheduling, tags, merges, metrics, summary |
| **Guard, don't trust** (D-H3, D-H4) | A session may only flip its own `passes`; a red suite un-passes; a separate verifier re-runs steps with evidence |
| **Not the feature's fault → not the feature's attempt** (D-H9, D-H11) | Limits, API errors and $0 sessions are given back and waited out |
| **Milestones are the unit of merge** (D-H6, D-H13, D-H17) | Only verified milestones reach `main`, each once the milestones it depends on have. Unverified work stays on its lane branch |
| **Humans gate policy, not routine** (D-H15, D-H16) | Merges of verified work are automatic. Permissions, policies and project rules change only through Michael |
| **Measure every run; learn from the ledger** (D-H19) | `summary.json`, `retro.md`, `ledger/runs.jsonl`, `harness trends`, calibration fed back to the initializer |
| **Each fact has one home, named in the project's `CLAUDE.md`** (`decisions/2026-10-26-where-things-go`) | The `## Where things go` block (appended to prompts only when `CLAUDE.md` lacks it) routes a session's writes to a store by bucket and scope: see Memory model, §4 |

## 3. Components

```
 you ──► bin/harness ──► queue (state/queue/*.args) ──► lib/queue.sh (tmux h-queue)
          │  start/continue/merge                          │ starts runs: MAX_PARALLEL_RUNS, --until, limit window
          ▼                                                ▼
     tmux h-<run>: driver window ──► lib/driver.sh ──────────────────────────────┐
                   log window (tail run.log)   │ per session:                    │ at the end:
                   supervisor (interactive)    │  claude -p <prompt>             │  summary.mjs build/report
                                               │   initializer | coding |        │  retro session
                                               │   verify | retro                │  ledger (harness repo)
                                               │ libs: config.sh check.sh notify │  notify, queue continuation
                                               │  features.mjs metrics.mjs       │
                                               │  treekey.mjs testcount.mjs      │
                                               ▼                                 ▼
                         git worktree ~/worktrees/<p>/<run> ─── origin (GitHub): harness/<run>,
                         branch harness/<run>                    harness-merge/<run>-<m>, tags run/<run>/<m>,
                                                                 milestone PRs → main
```

| Component | Lines | Responsibility |
|---|---|---|
| `bin/harness` | ~350 | CLI: start/continue/merge/queue/status/parked/report/trends/attach/pause/resume/stop/answer/init/gc/memlint/debrief. Creates worktrees, ports, state dirs, tmux sessions. A tmux start's driver window, when the driver exits, saves its scrollback to `<state>/tmux-driver.txt` (`capture-pane -pJ -S -`), kills the `supervisor` window, prints where the scrollback went, sleeps `TMUX_KEEP_HOURS` (24; 0 = at once) and kills its session `h-<run>` (exact `=` target), the `log` window with it (a Ctrl-C in the window never skips this: `trap : INT`); a resume kills the old session, timer and all, first (decisions/2026-10-25-tmux-driver-window), and a start refuses a run id whose `h-<run>` another run that hasn't ended holds (`a.b` and `a-b`, one id in two projects) rather than kill it; `attach` and the queue runner's `h-queue` are exact `=` targets (decisions/2026-10-25-tmux-reaper, L3-05). `harness gc <project>` first stops the units of this project's runs with no live driver and no live lane process (what a SIGKILLed driver left: `+ stopped <unit> (<run> ended)` or `(<run>: driver gone)`; `--dry-run` prints `would: systemctl --user stop …`; a unit only another project's runs own, live or ended, is skipped silently (that project's gc's); one no run on this box owns is listed `? <unit>: no run on this box owns it (systemctl --user stop <unit> by hand)`, never stopped; decisions/2026-10-25-gc-orphan-units, decisions/2026-10-27-gc-foreign-units), then kills the tmux session `h-<run>` of each of this project's runs that has `ended`, no live driver and no `PAUSE` (`tmux_reap`, `lib/tmux.sh`: `+ reaped tmux session <s> (<run> ended)`, `would: tmux kill-session -t =<s> …` on `--dry-run`, a failed kill is `! could not kill …` and gc goes on), then, in this order: (1) `git fetch --prune`; (2) closes idle desks; (3) **removes worktrees**: a run's (branch `harness/<run>`, under `$WT_ROOT`, never the checkout; one on any other branch, a session's of Michael's, prints `keeps <wt>: not a run worktree (branch <b>)`) that is merged (or holds only run-record commits past main), clean (`status --porcelain --untracked-files=normal` empty, whatever the config; a failing status is not clean), not running, with no queued continuation and no open desk; the **removal fallback** is `git worktree remove --force` (ignored files are build output, never work), `git worktree prune`, then `rm -rf` only once git no longer lists the worktree (a refusal, a locked one, is never bypassed); one that stays prints `! could not remove <wt>: <why>`, the failing command's first stderr line, and gc goes on; a listed worktree whose directory is gone is skipped (decisions/2026-10-25-gc-removal-finishes, decisions/2026-10-26-gc-unattended-guards); a lane's **slot** (`$WT_ROOT/<project>/lanes/<run>/slot-<k>`, known by its path, since a closed lane's slot is detached) goes the same way once its run has no live driver, no live lane process (`keeps <slot>: lane <m>'s process <pid> is alive`), no queued continuation and no open desk, and it is clean (`keeps <slot>: uncommitted work`), whatever its branch's merge state (the branch keeps the work; `harness continue` makes the slot again); then `lanes/<run>` and `lanes/` when empty (decisions/2026-10-27-lane-branches-and-slots); (4) **`--deps`** deletes the `DEPS_DIRS` (`node_modules .next .next-check .venv`) in the worktrees of ended runs, merged or not (a worktree of the project under `$WT_ROOT/<project>/` whose run's `meta.env` names it, with `ended`, no live `driver.pid`, no queued continuation, no open desk; or a slot gc kept, of an ended run with no live lane process; never the project's checkout; only directories, not symlinks, inside the tree and holding nothing git tracks: `+ freed <n> MB in <wt>: <dirs>`, `would: freed …` on `--dry-run`, `! could not free <wt>: <why>` and gc goes on; an unreadable directory gives a partial count; decisions/2026-10-25-gc-deps); (5) deletes the record-only tails (a `harness/` branch whose only commits past its merge-base touch `.harness/runs/`, `branch -D`, not checked out, not running); (6) **the branch passes**: one per prefix, `harness/`, `harness-merge/` and `harness-lane/`, or under **`--all-merged`** the bare prefix, every branch (`refs/heads/`, `refs/remotes/origin/`), prefixes never a `*` (it doesn't cross a `/`); merged = an ancestor of `origin/main`; never `main`, the origin's default branch (`refs/remotes/origin/HEAD`) or a running run's branch (a lane's `harness-lane/<run>/<m>` included; running = a live driver or lane process, or a queued continuation); local deletes are `branch -d`, skipping a branch checked out in a worktree (a lane branch, which has no upstream, `branch -D` after the same ancestry test); a failed step prints `! failed: <argv>` and gc goes on (decisions/2026-10-25-gc-all-merged). `--dry-run` for a person (`tty_out`: `HARNESS_TTY=1`, else a terminal) re-runs gc with `--sections`, which prints a `\x1e<STEP>` marker before each step's lines (`UNITS TMUX DESKS WORKTREES DEPS BRANCHES`) and `\x1eEND` at its end, into `view.mjs gcView` (sections, `~`, `would remove <w> worktrees, <b> branches; keeps <k>`; no `END`: `gc stopped before <step> (see the error above)`); off a TTY and for a real gc no markers, the lines as before. `harness report` and `harness trends` render `summary.mjs reportView`/`trendsView` on a TTY (`--md`, and off a TTY: the markdown; `finish` writes `report.md` with `--md`; decisions/2026-10-27-read-views). `harness status`, `harness status <run>` and `harness queue list|show` collect what only bash knows (live pids, a running run's units with `MemoryCurrent` under `-v`/`--json`) in `run_rows` and render through `lib/status.mjs` |
| `lib/driver.sh` | ~420 | The run's coordinator (§5, lanes P1-04): start-up, the initializer, then every `HARNESS_LANE_POLL` seconds (10; the suite sets 1; at once when a lane exits) it reaps lanes whose process is gone (`lane <m> closed (<reason>)`), checks the run's ends (session cap, deadline and its verify-only lanes, stop, pause logged once, the usage-limit window and the weekly budget while no lane is open), and opens what `F lanes` offers while `lanes alive < MAX_LANES` and `admit` lets it (P2-02, decisions/2026-10-26-parallel-runs-headroom: with a lane open, `MemAvailable` must cover `MEM_MIN_AVAILABLE_GB + LANE_RESERVE_GB × lanes alive` and the newest five-hour window, `USAGE_5H`, while not reset, must be under `LANE_OPEN_BELOW_5H` %; the first lane always opens; a refusal is `lane <m> waiting: <reason>` once per kind, memory or five-hour, retried every poll) (`lane <m> opened (slot <k>, port <n>, from <sha>)`: the lowest free slot, the services that slot's last lane left up stopped silently, its port (slot 0 the run's; slot 1 and up the first free from `BASE_PORT`, `port_alloc_` under the record lock and the box-wide `state/port.lock`, `port_taken` in `lib/config.sh`), `slot_open` (`--no-track`: no lane writes `.git/config`, which git locks without waiting), then `lib/lane.sh <m> &` with its pid in `state/lanes/<m>/pid`). A lane ending the run (a session cap, a usage limit, the weekly budget, list edits) writes `state/lanes-end`; every other lane exits 16 before its next session, and `limit_wait`/`mem_gate` sleep in slices of at most 60 s that end early on it or a stop. Merges run under `state/merge.lock` (lanes and coordinator alike; network commands close its fd). With no lane open and none to open, the end reason as before lanes. `finish` waits for every lane, tears down the services the last lanes left up (one `services stopped (<reason>)`), removes every slot, the merged lane branches left (most went at their merge) and the never-pushed ones that carry nothing beyond main. A lane closing `<m> merged` gets its local branch deleted at its reap (`lane_branch_gone`). Its EXIT trap sends every lane a TERM (`lane <m>: stopped (the driver is exiting)`) and waits up to 150 s for it first; a segment's start TERMs a lane an earlier driver left (`lanes_orphans`: its pid's command line is `lib/lane.sh` and its environment's `STATE` this run's). The session command line (`session()`, in `lib/record.sh`): `claude -p <prompt> --model <m> --permission-mode auto [--settings <wt>/.claude/settings.json] --strict-mcp-config [--mcp-config <wt>/.mcp.json] --max-turns … --max-budget-usd … --output-format stream-json --verbose`, under `timeout -k 30s SESSION_TIMEOUT` in its scope. `--strict-mcp-config` always, `--mcp-config` only when the worktree has a `.mcp.json`: a session loads its project's committed MCP servers and no others (run.log's `MCP servers:` line at the run start; decisions/2026-10-25-strict-mcp-and-deepequal-rule) |
| `lib/queue.sh` | ~50 | Starts queued runs within the parallel limit (one per project), the `--until` time and the usage-limit window; skips parked entries; syncs the live checkout when no run is alive; as it exits, runs `harness gc <project> --all-merged --deps` for each project it started a run in (no git prompt, killed at `HARNESS_GC_TIMEOUT`, 10m), then starts `harness debrief`, detached (§12, §16) |
| `lib/sync.sh` | ~40 | The live checkout level with origin: merged PRs in, the driver's ledger commits out, only when safe (§12) |
| `lib/debrief.sh` | ~280 | `harness debrief`: gathers the context in bash (per run: its card, then a `#### needs` block from `COLUMNS=80 harness needs <run>`), waits out the limit window, one read-only session, the note, checked continuations, the notification (§16) |
| `lib/config.sh` | ~60 | Config layers and conventions (§10) |
| `lib/notify.sh` | ~50 | `notify "<message>" [title= body= click= actions= priority= tags=]` for the driver and the debrief: posts to `NTFY_URL` through `${HARNESS_CURL:-curl}` (bearer `NTFY_TOKEN`), else runs `NOTIFY_CMD` with `$1` + `HARNESS_NOTIFY_*`; always returns 0, a failed post is a note. `gh_url <path> [blob\|edit]`: that file on the run branch on GitHub, or nothing |
| `lib/notify.mjs` | ~85 | Pure helpers for it: `githubUrls` (GitHub origins only), `compareUrl` (`urls compare <origin> <base> <branch>`: a conflict card's link), `trimBody` (3500 bytes, `…`), `actionsHeader` (ntfy `view, <label>, <url>; …`), `inboxQuestion` (the lines a session added above `## Answers`) |
| `lib/parked.mjs` | ~110 | `harness parked --json` (§17): pure `questionFor`, `commandsFor`, `runState` (the parked card's `run` words), `entriesFor`, `parkedReport`, and a `report` CLI over the state dirs bash names on stdin. Never writes |
| `lib/needs.mjs` | ~230 | What waits on Michael, one record per item (decisions/2026-10-27-needs-record): `<state dir>/needs/<seq>.json`, its first 13 keys the n8n event v1's, then `ref` (`<run>/<seq>`), `key` (`<reason>:<subject>`, one open per key), `reason` (15, `REASONS`: kind, severity, priority), `seen`, `card`, `resolved_*`. Pure `record`, `refresh`, `sweep` (each reason's rule; `run removed` when worktree and record branch are gone), `synthesize` (a SIGKILLed driver, a `parked.json` entry without a record and with its worktree: listed, never stored), `order`; the cards (U2-04): `TEMPLATES`, one per reason as data (`headline`, `cost`, `why` naming the mechanism and its file, `where` rows `{path, line, label, url}`, `options` with one recommended, `commands`), `card(reason, facts)` (plus `blocked` from `waitsOn`, the features whose deps reach the subject; `question` for a park: inbox.mjs's section, its line and `?plain=1#L<n>` URL; `where` from its `Files:` line, else from `session_files=` the lane passes, `files_from: "session"`; decisions/2026-10-27-question-locations), `mergedBy` (main's merge subjects as runs and milestones, the run's own left out), `renderCard`, `renderList`; CLI `open` (0 new, 3 refreshed), `sweep`, `done`, `list` (read-only; a parked card's commands and `run` recomputed from the driver, the queue runner and a queued continuation), `card <reason> <facts.json>`, `md <state dir>` (`markdown`: the run record's `needs.md`, which `open` and a sweep that changes it rewrite; the notifications' click), `fields <state dir> <ref>`. A record's `body` is `bodyOf`: the card at 60 columns, plain (a park's: `PARKED: <why>`, the question, the card's blocked, where and do, the answer line). `lib/needs.sh`: `needs_open` calls `open` under the record lock, `needs_notify <ref>` sends the record's title, body, click, priority and actions, `needs_sweep` sweeps and notes each resolved item. Openers: the lane loop (`parked`, `given_up`), `finish` (`feature_list_edits`, `initializer_failed`, `usage_limit`, `weekly_budget`), the driver's EXIT trap (`driver_crash`, default `END_REASON`), `reap` (`driver_crash` for a lane gone without a reason), `sync_main` (`main_conflict`, notified once per `origin/main` commit: `main-conflict-<subject>`), `merge_one` (`merge_conflict`, `merge_refused`), `verify` and `rebase_fail` (`verify_thin`, `verify_red`, `verify_recheck`, a re-base's `merge_conflict`), `slot_open`/`slot_fail` (`base_conflict`); `needs_you` sends the record. Sweeps: `sync_main` when main merges cleanly or is already in, the lane loop and the coordinator after their unpark, `finish`, `harness continue`, `harness gc` (runs whose worktree is gone) |
| `lib/inbox.mjs` | ~150 | INBOX.md read one way (decisions/2026-10-27-question-locations): pure `answersLine` (the `## Answers` outside an HTML comment; an unclosed one runs to the end), `question`/`questionLine` (parked.mjs's `questionFor`), `added` (notify.mjs's `inboxQuestion`), `answers` (what `answers_hash` hashes), `insert`, `files`, `repair` (a session's text inside the steering comment moved above `## Answers`, the comment as it was); CLI `repair`, `answers`, `insert`, `question` |
| `lib/view.mjs` | ~250 | The read views' one formatter (decisions/2026-10-27-read-views): `context` (width from `COLUMNS` ≥ 40, else the TTY, else 100; narrow under 72; colour only on a TTY, `NO_COLOR`, `TERM=dumb`, `HARNESS_COLOR`, `HARNESS_TTY`; unicode or ASCII glyphs by locale, `HARNESS_GLYPHS`; `HARNESS_NOW`), `glyph` (`● ✓ ✗ ■ ‖ ⚠ ○ · ─ …`, ASCII `* + x # = ! o - - ...`), `paint`, `displayWidth` (ANSI ignored, wide characters 2), `cut`, `pad`, `table` (ids never cut, the flex column cut or moved to a second line, no line over the width), `section`, `rule`, `card` (labels, hanging indent, URLs whole; `rule: false` for cards of one section), `cutFront` (`…/dir/file:line`: a path keeps its end), `ago`, `when`, `home`, `duration`, `endClass` (`done` · `stopped` · `waiting` · `failed`). Pure; unit checks in `tests/checks/51-view-pure.sh` |
| `lib/status.mjs` | ~470 | `harness status` and `harness queue list|show`: reads one row per run on stdin (`run_rows` in bin/harness: `<run> <project> <state dir> <worktree> <record dir> <alive>`, plus units under `-v`/`--json`) and the files itself (`ended`, `PAUSE`, `LIMIT_UNTIL`, `run.log`, `metrics.jsonl`, `feature_list.json`, `summary.json` from the record, the state dir or the ledger copy, the queue's `.args`; the needs items through `needs.mjs list`, the records and the synthesized ones, so NEEDS YOU, `--json`'s `needs` and the card's `needs you` (the count and the open items' headlines) are `harness needs`'s), builds the run, needs and queue objects in one process and prints the v1 `--json` document (key paths: `tests/fixtures/status-json-keys.txt`), the one-screen view (NEEDS YOU, RUNNING, QUEUED, FINISHED in the `STATUS_SINCE` window, footer), a run's card, the queue list and an entry's card, all through `view.mjs`. Never writes |
| `lib/overlap.mjs` | ~70 | The tracked paths a spec or brief names, and where two lists meet (decisions/2026-10-27-same-project-starts). `busyRun(state)`: the first other live run of the state dir's project (`liveRun`: driver or a lane), `""` when none. Pure `named(text, tracked)`: backticked spans and path-shaped words (one `/` at least; trailing `.,:;)` and `:<line>` stripped) equal to a tracked path; a word ending in `/` or holding a glob (`*`, `<`, `>`) names its directory before the first glob segment as `dir/` when it has two or more segments and holds a tracked file; a word without `/` only a top-level tracked file, in backticks; never `.harness/runs/`; HTML tags blanked, trailing `*`s dropped when that leaves a tracked file (Markdown emphasis). `overlap(a, b)`: the sorted intersection, a `dir/` meeting the files under it. CLI: `named <tracked file> < text`, `overlap <file a> <file b>` |
| `lib/show.mjs` | ~260 | `harness show <run> [<feature>] [--files] [--json]` (decisions/2026-10-28-show): where a run's work is, read-only from local refs of the run's `PROJECT_DIR` (no fetch, no lock; the branches live there, so a removed worktree changes nothing). The run card's header (`status.mjs cardHeader`), then `worktree` (clean or `<n> changed files`, or `removed`), `branch` (`harness/<run> @ <head> · <a> ahead, <b> behind`), `record`, `state`, `lanes` (`<m> · harness-lane/<run>/<m> · slot <k> · open|closed`), one `merged`/`proposed` line per milestone from `harness-log.md`'s notes (tag, `PR #<n>` or the URL), the compare URL of every run branch with changes (GitHub-shaped origin only); `CHANGES vs origin/main` over the run's branches (`harness/<run>` and every `harness-lane/<run>/*`, an origin copy without a local branch too): `git diff --no-renames --numstat` and `--name-status` from each branch's merge-base, joined by path, `.harness/runs/` left out, a path with the same blob on two branches counted once (stacked or fanned-out lanes), different results summed; `✗ conflicts` on the paths `git merge-tree --write-tree --name-only` lists (into a scratch object store); `origin/<MAIN_BRANCH>` (the project's config, read in a subshell), and `unknown` when that ref is missing; the 12 largest (`--files`: all); `CONFLICTS with origin/main`; `NEEDS YOU`. A feature: its milestone, passes, attempts, steps, sessions (`metrics.jsonl`), entry files (absolute), commits (subjects matching `^(WIP: )?<id>` on the run branches and `run/<run>/*` tags since the run started) and its open needs card; the feature list, log, metrics and entries from the ledger copy once gc removed the worktree. `--json`: v1, key paths in `tests/fixtures/show-json-keys.txt`. Pure `joinDiff`, `mergeTreePaths`, `combine`, `milestonesOf`, `renderShow`, `renderFeature` |
| `lib/check.sh` + `treekey.mjs` + `testcount.mjs` | ~80 | The suite, cached per content of the code tree. One command for the driver and every session. Full and subset runs alike go under `timeout -k 30s $CHECK_TIMEOUT` (15m) in the scope `harness-<run>-check-<pid>` (`MemoryMax=CHECK_MEMORY_MAX`, 3G, no `MemoryHigh`; the prefix, cap and timeout come from `prompt_env`, so a session's call caps like the driver's), stopped after; bare without a prefix or user systemd. A TERM to `check.sh` stops the scope with it. It keeps only the newest code tree's `check-<key>.out`; a green tree's marker (`green-<key>`, in the state dir) holds its test count, so a cached green and `finish`'s `tests-end` keep it after scratch is gone. A kill gets its own RED line: `check: RED (killed at its 3G memory cap, exit 137 after <n> s)` or `check: RED (timed out after 15m, exit <rc> after <n> s)` (decisions/2026-10-25-capped-suites). A red full run is rerun once by `CHECK_RERUN` (§10; read as `HARNESS_CHECK_RERUN`): `auto` reruns the files of the output's `HARNESS_FAILED=<names>` line as arguments, else the whole suite; never after a timeout or a cap kill, and the subset form never reruns. `check.out` keeps the first run, `check-rerun.out` the rerun's; a green rerun prints `check: green after a rerun (flaky: <names | whole suite>), <n> tests`, exits 0, writes the marker with the full run's count (`testcount.mjs --total`: the first run's `M` of its last `N/M … passed`, never the rerun's subset) and appends a `green/flakes.jsonl` row (§4); a red rerun says `red again on a rerun of …` with the rerun's tail (§7 Rerun guard; decisions/2026-10-29-rerun-guard). `testcount.mjs` takes the last `HARNESS_TESTS=<n>` line a project's check prints (the contract; decisions/2026-10-26-test-count-contract), else reads the passed count from the output for node:test, cargo (the sum of its `test result:` lines), jest (the `Tests:` line; vitest's, with no colon, by the last rule), `go test -v` (`--- PASS` lines) and pytest and the like (the last `N passed`), one fixture each in `tests/fixtures/check-*.txt`; `--source` names the rule (`contract`, `node`, `cargo`, `jest`, `go`, `generic`, `none`). The first suite `run_init` ran is noted once per run with its source (`testcount-source`): `test count: HARNESS_TESTS contract`, `test count: parsed (<runner>)`, or `test count: no match in the suite's output (tests start/end stay unknown)` (decisions/2026-10-26-real-test-counts) |
| `lib/tmux.sh` | ~25 | Run → tmux session (decisions/2026-10-25-tmux-reaper): `tmux_name <run>` (`h-<run>`, dots as dashes) and `tmux_reap <dry> <state dir>…`, which kills `h-<run>` of each given run that has `meta.env` and `ended`, no live `driver.pid` (re-checked just before the kill) and no `PAUSE`, and spares a session created after its run's `ended` (a resume's, its driver not up yet). Names come only from state dirs, never from `tmux list-sessions`, so `h-queue` and `h-desk` are never candidates (`harness start` refuses run ids `queue`, `desk`, `debrief`). The kill goes by session id, read with the creation time, so a resume's new `h-<run>` is never the one killed. `tmux_shared` (another run of the same session name that isn't done, any project; `TMUX_OTHER` names it) spares a shared session and makes `harness start` refuse such a run id. Sourced by `bin/harness` (gc) and `lib/queue.sh` (as the runner exits) |
| `lib/lane.sh` | ~240 | One milestone as its own process (lanes P1-04), started by the coordinator with `LANE LANE_SLOT LANE_PORT`: in its slot, with its own units (`harness-<run>-<m>-s<n>`, `-check-<pid>` through `HARNESS_SCOPE_PREFIX`, `-svc`), scratch (`<scratch>/lanes/<m>`) and the slot's config, `--settings` and `.mcp.json`, it loops as the driver did (cap, deadline, answers, pause: its services down and wait; stop, the limit window, the weekly gate, `F next … <m>`, init, context, materialize, the review gate (`review_diff` on the lane's branch, the model by `REVIEW_OPUS_LINES`, an escalation round pending in `state/lanes/<m>/review-escalate`), session, take-back, `gotchas`, the limit branch, repair, red-suite un-pass, `tests_end`, the flip, metrics with `lane`, park), verifies when `F milestone-done` holds and merges through `merge_milestones <m>`. Exit codes, the reason also in `state/lanes/<m>/exit`: 0 merged, proposed or its PR waiting · 10 given up · 11 parked · 12 needs Michael (verify, merge, feature-list edits) · 13 session cap, usage limit or weekly budget · 14 stopped · 15 deadline · 16 the run is ending (another lane ended it, `state/lanes-end`). The session counter is taken atomically (`rec_count` prints from inside the lock; over the cap it is given back and the lane exits 13). `LANE_ONCE=1`: the deadline's one verify. `rebase <m>` (main moved under its tag, `state/rebase-<m>`): main merged into the verified commit, the suite on it (disjoint files) or `verify <m> rebase` (overlapping, or `LANE_REBASE=verify`), the tag forced to the merged commit, then `merge_milestones <m>` again (`merge_own`); `LANE_MERGE=1`: a merge lane, opened on the tag by the coordinator's `rebase_due` or `harness merge`, runs only that. Its EXIT trap stops a running session's scope and, when it dies without a reason (the coordinator's TERM), its services |
| `lib/record.sh` | ~510 | Everything the coordinator and the lanes share (`run_paths`, `note`, `session`, `journal`, `gotchas`, `context [<cap>]` (verify passes `CONTEXT_PACK_BYTES_VERIFY`), `run_init` (the once-per-run `testcount-source` note), `tests_end`, `services_down`, `limit_wait`, `merge_one`, `merge_milestones` …), the record on its own branch and the lane slot (lanes P1-03, docs/plans/2026-10-26-P1-lanes-serial.md): `record <cmd…>` (one `flock` on `state/record.lock` around every record write; nested calls reuse it; `HARNESS_RECORD_DELAY` holds it in tests only), `commit_all`, `rec_commit`, `rec_count` (`sessions`, `limits`), `sync_record` (fetch, merge and push `harness/<run>`), `sync_lane`, `slot_open <m> [<k>]` (slot-k on `harness-lane/<run>/<m>`, the dependencies' tags merged in, the per-worktree excludes), `materialize`/`unmaterialize` (the record's copy in the slot), `take_question`, `lane_guard`, `lane_branch_gone <m>` (a merged milestone's lane branch: on the origin at once, here once no live lane has it checked out, a closed lane's slot detached first; only a tip its tag or `origin/main` holds, the origin's under `--force-with-lease`, never from a checkout outside this run's slots; `lane <m>: branch harness-lane/<run>/<m> deleted (merged)`; from `merge_one`, the merged-by-its-PR path, `reap` and `slot_close`), `slot_close` (at `finish`: every slot, merged lanes' branches, and never-pushed lane branches with nothing beyond main) |
| `lib/scope.sh` | ~70 | Capped transient systemd user scopes (decisions/2026-10-25-scoped-sessions): `scope_run <unit> <high> <max> <cmd…>` (`systemd-run --user --scope --collect`, `MemoryHigh`/`MemoryMax`/`MemorySwapMax`, `OOMPolicy=continue`, a wrapper inside the scope that records `MemoryPeak` and `TasksCurrent` before it exits), `scope_stop`, `scope_peak` (MB), `scope_left`, `scope_capped`, `scope_unit` (`harness-<run>-<role>`, the run id reduced to `[A-Za-z0-9_-]`), `scope_owns <run> <unit>.scope` (the unit is `scope_unit <run>` plus `-s<n>`, `-check-<pid>` or `-svc`: gc's and status's match, rebuilt from the id, so run `demo` never claims `demo-x`'s), `dur_s` (`15m` → 900), `mem_available_gb` (`MemAvailable` of `${HARNESS_MEMINFO:-/proc/meminfo}`, whole GB) and `mem_gate` (§7). Bare when the probe `systemd-run --user --scope --quiet true` fails |
| `lib/review.sh` | ~15 | `review_diff` (§7, the review gate): fetches `MAIN_BRANCH`, then `git diff --shortstat origin/<main>...HEAD -- . ':!.harness/runs'` → `<files> <changed lines>`; exit 1 with why (`no origin/<main>`) |
| `lib/resolve.sh` | ~145 | Layer 2 of conflict resolution (decisions/2026-10-29-conflict-resolution), sourced by `lib/lane.sh`: `resolve_ok <m>` (`CONFLICTS=resolve`, not `HARNESS_MERGE_ONLY`, in a lane, a merge in progress, no session yet for this main (`resolve-<m>-<main>`), `resolves-<m>` under `MAX_RESOLVES`, `RESOLVE_TIMEOUT` left before the deadline; else the reason); `resolve <m> <what>` with a merge left in conflict in the slot (called through `merge_main <m> resolve`, `lib/record.sh`: the one conflict path of `sync_main` and `rebase`): the session cap, the weekly gate and the memory gate as a coding session's, a NUL-separated `ls-files -s` snapshot of stage 0 and the untracked files, one `resolve` session on `RESOLVE_MODEL`/`_MAX_TURNS`/`_BUDGET_USD`/`_TIMEOUT` (`prompts/resolve.md`; journaled, a metrics row of kind `resolve`), then the driver's checks in order (it committed or aborted the merge itself, an `UNRESOLVED:` line, an unmerged path, more marker lines than either side had); passed, any other path it touched is put back as git merged it (`resolve_restore`, `checkout-index`, noted) and the merge is committed (`resolved-<m>` names the files): 0; failed: `resolve_undo` (the slot back at the lane's commit, files it created removed), `RESOLVE_TRIED` kept in the marker: 1; refused by a limit, or the cap or weekly gate: the merge aborted, 2 (`RESOLVE_END` set when the lane must end 13). `resolved_note <m> <what follows>`: the note a resolution gets, never a question |
| `lib/merge-sorted.sh` | ~15 | Layer 1: the `sorted-union` git merge driver (`%O %A %B`) for a `LC_ALL=C` sorted one-item-per-line file a project opts in with `.gitattributes` `merge=sorted-union`: both sides' lines once each, minus every base line either side removed; a side out of order gets git's own text merge (`git merge-file`: clean 0, else 1 with its markers in `%A`, which git keeps as the result whatever the exit; then layer 2). `merge_drivers <worktree>` (`lib/record.sh`) sets it as worktree config (§8) |
| `lib/entries.mjs` | ~390 | The journal (decisions/2026-10-22-journal-single-writer, -rendered-progress, -context-pack): pure `journalEntry`, `stamp`, `render`, `pack`; verbs `ingest` (validate `entry.json`, stamp, append to `entries.jsonl`; a question without a `Files:` line gets ` Files (harness, from the session): …` appended by `fillQuestions` from `sessionFiles`, the entry's `files` then the session's diff, absolute, at most 8, noted `<id>: <n> question(s) had no Files: line; filled from the session's diff`; decisions/2026-10-27-question-locations), `session-files` (that list for a park's card), `render` (progress.md, progress-archive.md) and `pack` (context.md within `CONTEXT_PACK_BYTES`, or `CONTEXT_PACK_BYTES_VERIFY` for a verify; the worktree's `## Gotchas` and decisions store read from the worktree given after the cap (`context` passes its cwd: a lane's slot, whose `CLAUDE.md` the session edits; decisions/2026-10-27-p1-main-merge), else only from a run dir at `<worktree>/.harness/runs/<run>`, an unreadable one skipped) |
| `lib/features.mjs` | ~300 | The feature-list contract: scheduling, gating, repair, kinds, evidence counting, the step lint |
| `lib/metrics.mjs` | ~100 | Per-session metrics; the "environmental?" decision (limits, API errors, $0) |
| `lib/summary.mjs` | ~230 | Run summary, writeup, ledger rows, trends, calibration |
| `lib/prompt.sh` | ~50 | The driver's prompt assembly (`prompt_vars`, `prompt_env`, `prompt_render`), sourced by the driver; run as `prompt.sh <state dir> <template> <feature>` it renders a run's prompt the way its driver would (eval probes use it) |
| `lib/eval.sh` | ~260 | `harness eval run\|compare\|probes` (§11): replays `evals/` tasks with a ref's own driver on throwaway clones in `/tmp/harness-eval/<stamp>/`, under `EVAL_BUDGET_USD` and the 7-day window; compare; probes |
| `lib/eval.mjs` | ~335 | Pure helpers: task validation, `spent`, `loadResult`, `METRICS`, `compare`/`compareText` (verdicts with the repeat spread as noise), probe `questions`/`score` |
| `lib/memlint.mjs` | ~140 | The project's memory, read deterministically (decisions/2026-10-26-where-things-go): `decisionsStore(worktree)` (`DECISIONS=` from `.harness/config.sh`, else `docs/decisions.md` if it exists, else null; `{ path, kind: dir\|file, exists }`), `storeLine` (the routing block's `{{DECISIONS}}`), `gotchasLines`/`gotchasDiff` (the `## Gotchas` section's lines, a wrapped bullet as one, and their multiset diff; decisions/2026-10-26-gotchas-in-place), `currentRules`/`readRules` (the store's decision lines newest first, for the pack's `Current rules`; decisions/2026-10-26-pack-current-rules); CLI `store <worktree>` (the path or nothing), `store-line <worktree>`, `gotchas <before> <after>` (`+<a> ~<e> -<d>`, nothing when equal); `lint`, CLI `<worktree>`: the memory lint, `<file>:<line> <check>: <text>` per finding (`size`, `gotchas`, `derivable-count`, `night-scope`, `decisions`), exit 0 with or without findings, 2 with no worktree (decisions/2026-10-26-memlint) |
| `lib/render.mjs` | ~35 | Prompt templating (`{{X}}` ← `HARNESS_X`), titled sections placed at a `{{SECTIONS}}` line (`assemble`) |
| `lib/page.mjs` | ~130 | The debrief page: a card per run from summary.json, then the note (escaped), one self-contained HTML file |
| `lib/desk.sh` | ~240 | `harness desk <run> [--why …]` \| `--debrief` (§17): a Remote Control `claude` in tmux session `h-desk`, window `<run>`, in the project directory; the pane's session URL is the notification's click; one desk per run (a later event is typed into the open one); a desk that can't start is a note and the plain notification, exit 0. `--list`, `--close <run>\|--all`, `--gc` (from `harness gc`: idle for 24 h) |
| `prompts/desk.md` | ~80 | The desk's instructions (a run block and a debrief block): read `COLUMNS=60 harness needs`/status/INBOX/progress, check safely, one numbered brief, `harness answer` and the continue only after Michael's yes, the never-list |
| `skills/harness-answer/SKILL.md` | ~45 | The answer desk's instructions for an interactive session Michael opens (§17); installed by a symlink into `~/.claude/skills/` |
| `templates/user/config.sh` | ~15 | The documented `~/.config/harness/config.sh` (every line commented) |
| `templates/user/{settings.permissions.json,CLAUDE.md,config.merge-policy.sh}` | | The permissions policy (`decisions/2026-10-24-permissions-policy`): the user settings, the `~/.claude/CLAUDE.md` section that is its one home, and `MERGE_POLICY=auto` |
| `setup/apply-2026-10-24.sh` | ~110 | Installs those three (`--dry-run` shows every diff; backs up to `~/projects/backups/`) and moves the n8n MCP servers to n8n-home's `.mcp.json`; Michael runs it, the harness never does |
| `prompts/resolve.md` | ~55 | The resolve session's instructions: keep both sides' intent, edit and `git add` only the conflicted files, no marker left, only the suite's subset for those files, never commit; end `RESOLVED: <file>: <how>` per file or `UNRESOLVED: <why>`. *This session* names the milestone, its features, what merged in, the conflicted files and each side's commits touching them |
| `prompts/*.md` | | initializer, coding, verify, retro, debrief, supervisor, draft-claude-md, desk, resolve; `policy/{build-only,live-staged}.md`; `parts/run.md` (*This run*), `parts/rules.md` (the line naming `CLAUDE.md`) and `parts/where-things-go{,-readonly}.md` (the routing block) |
| `tests/run.sh` + `tests/lib.sh` + `tests/checks/` + stubs | | End-to-end with stub `claude`, `gh` and `curl` on a throwaway repo with a bare origin, desks on a private tmux server: 539 checks, 354 s with `TEST_JOBS=4` (measured at the P1/main merge). `run.sh` is the runner (all files, or those whose names contain an argument; `TEST_JOBS` at a time, default half the cores, 1 to 4, largest first, as background jobs in the one check scope, never a scope of their own; each file's output whole when it ends, a timing line per file, the slowest three and the wall time, one total, in which a file that exited non-zero with no `FAIL` line is one failed check; on a TERM/INT/HUP, each unfinished file's output so far and its name; on a full run the conformance check against `tests/fixtures/check-names.txt`); each `checks/NN-<slug>.sh` starts from `lib.sh`'s `suite_setup` and ends with `suite_end`; `tests/split.sh` cut them from the single file by its section markers, grouping a section with the one whose state it reads or replaying that one first, uncounted (`REPLAY=1`) (decisions/2026-10-26-suite-split) |

## 4. Where state lives

The run record (`<wt>/.harness/runs/<run>/`, every "yes, record branch" or plain "yes" row of the run directory below) is committed only on the record
branch `harness/<run>`, in the run's worktree (`RWT`); code is committed only on lane branches
`harness-lane/<run>/<m>`, worked in a slot worktree `<worktrees>/<project>/lanes/<run>/slot-<k>` (lanes P1-03,
`lib/record.sh`). A lane opens in the lowest slot no live lane holds (`k < MAX_LANES`, so `slot-0` alone at the
default 1): the worktree is created the first time and checked out on the lane's branch after that, so ignored build
and install directories carry over from one milestone to the next; `finish` removes every slot. Before each coding and verify session the record is copied into the slot (invisible to the slot's
git through a per-worktree `core.excludesFile`, `state/lanes/<m>/exclude`, holding `.harness/runs/`; skip-worktree
when the slot's base tracks it); after it the driver takes back `entry.json`, the lines the session added above
`## Answers` and its `passes` flip (`F pass` on the record's list), and removes the copy. Every write to the record
goes through `record` (one `flock` on `state/record.lock`); sessions, inits and suites never run under it. A record
commit (`rec_commit`) stages `.harness/runs/<run>/` only, so what a suite or an init leaves in the record worktree
never lands on `harness/<run>`.

| What | Path | Written by | Read by | Committed? |
|---|---|---|---|---|
| Feature list | `<wt>/.harness/runs/<run>/feature_list.json` | initializer; driver only after that: a session's own `passes` flip (from its copy, after repair and the red-suite check) and a verify's un-passes are applied with `F pass`/`F unpass` | everyone | yes, record branch |
| Session entry | `…/entry.json` (the run directory, transient; its `resolved` names the questions found answered and the `Promote to Gotchas` facts dropped, so later packs leave them out, and progress.md shows them as `Resolved:`) | each session, once, at the end | driver (`entries.mjs ingest`), which validates, stamps `at`/`session`/`model`, appends to `entries.jsonl` and deletes it; a missing or invalid one becomes a minimal entry built from git, with a note | no (removed on ingest) |
| Journal | `…/entries.jsonl` (one line per session: feature, outcome, what changed, evidence, dead ends, discoveries) | driver only (`ingest`) | `render`, `pack`, retro, evals | yes |
| Context pack | `…/context.md` (at most `CONTEXT_PACK_BYTES` for a coding session, `CONTEXT_PACK_BYTES_VERIFY` for a verify; seven parts in priority order: this feature's earlier attempts, dead ends, failed verify rows and questions (less any a later entry lists in `resolved`; a milestone pack lists the failed rows first); Michael's answers; discoveries that name it, its milestone or the run; `Promote to Gotchas` (coding packs only, at most cap/8 bytes: discoveries affecting `"project"` until a `## Gotchas` line of the worktree's `CLAUDE.md` holds their first 40 characters (case, backticks, emphasis and spacing aside) or a later entry lists them in `resolved`; decisions/2026-10-26-resolved-and-project-facts); the latest entry of each feature in its `after`; the last 3 entries; each item ends `→ entries.jsonl:<line>`; last, `Current rules`: the decisions store's lines newest first (`memlint.mjs readRules`), at most cap/4 bytes, each `→ <store ref>`, the rest one `_<k> older rules: <path>._` line, none when the pack already stopped or the room left can't hold the heading and that line; decisions/2026-10-26-pack-current-rules); a copy in `logs/*.context.md` | driver (`entries.mjs pack`) before every coding and verify session, committed `HARNESS: context pack for <id>` | the session, first (prompts say `Read context.md first`); `eval probes` | yes |
| Progress log | `…/progress.md` (newest first: 15 in full, then one line each) and `…/progress-archive.md` (every entry in full; a continued legacy run's old progress.md at its end) | driver (`entries.mjs render` after every journal append, decisions/2026-10-22-rendered-progress); a legacy run's sessions until it is continued | sessions, Michael (phone), retro, PR bodies (the archive), verify's `F evidence` | yes |
| Steering | `…/INBOX.md` (`status: run/pause/stop [<why>]`, the steering comment, `## Answers`: the one outside the comment, `lib/inbox.mjs`) | Michael (GitHub app), `harness answer` via the driver; after a session (the slot's copy) and the initializer, `inbox_repair` moves a question written inside the comment above `## Answers` and notes it | driver, sessions | yes |
| Brief | `…/brief.md` | driver, from `--brief` at start/continue | every prompt | yes |
| Driver events | `…/harness-log.md` | driver (`note`) | Michael, summary, retro | yes |
| Metrics | `…/metrics.jsonl` (one row per session: kind, role, model, cost, wall/api seconds, turns, `tokens_in cache_read cache_write tokens_out cache_hit_rate context_peak`, `orient_tokens orient_turns orient_s`, exit, result, `mem_peak_mb`) | driver (`metrics.mjs append`) | summary, report (memory peaks) | yes |
| Summary / writeup / retro | `…/summary.json`, `report.md`, `retro.md` | driver at the end, `summary.json`, `report.md` and `metrics.jsonl` copied into the state dir too; `harness report` rebuilds `summary.json` into the state dir (with `metrics.jsonl` beside it) while the worktree exists, else reports the state's copy, else the ledger's `<project>/<run>/` (copied into the state on that read), else `## <run>: no record (worktree removed; nothing in <state> or <ledger>/<project>/<run>)` (decisions/2026-10-27-record-after-gc) | Michael, ledger | yes |
| Scopes | transient systemd user units, not files: `harness-<run>-s<n>.scope` per session, `harness-<run>-check-<pid>.scope` per suite, `harness-<run>-svc.scope` for what the init starts (§7; `systemctl --user list-units 'harness-*'`). **Nothing of a scope persists**: `--collect` unloads it once empty, and the driver and `check.sh` stop it when their command returns (the svc scope lives on while the init's servers do, until a stop point (`services_down`) or the next `run_init` stops it). What stays is the record: `state/scope-seq` (the last `<n>`, so a resumed segment never reuses a name), the wrapper's `<scratch>/scopes/<unit>.{started,show}` (`MemoryPeak`, `TasksCurrent` at exit; scratch), `mem_peak_mb` in `metrics.jsonl` and the cap/leftover notes in `harness-log.md`. A SIGKILLed driver runs no trap and leaves its units loaded: `harness gc` stops every unit `scope_owns` gives to a run of the project with no live `driver.pid` (`ended` or not: the driver removes `ended` at start) and none of another run sharing its prefix | `systemd-run` via `scope_run`; driver, `check.sh` | driver (`scope_peak`, `scope_left`, `scope_capped`), `harness status` (`MemoryCurrent`), `harness gc` (`list-units`, then stop) | no |
| Driver log | `~/.local/state/harness/<p>/<run>/run.log` | driver (`log`) | status, summary (wall times) | no |
| Transcripts | `…/logs/NN-<id>.jsonl`, `HHMMSS-verify-<m>.jsonl`, `00-init.jsonl`, `zz-retro-*.jsonl`, each with its prompt beside it (`*.prompt.md`) | `claude --output-format stream-json`; the driver copies the prompt | metrics, retro, you (`jq`) | no |
| Harness version | `~/.local/state/harness/<p>/<run>/{harness-version,harness-dirty}` (last harness commit outside `ledger/`, and whether the tree has changes outside it; `lib/version.sh`; rewritten each segment, shown on the `run <id> on` line, copied into `summary.json` and the ledger row) | driver | summary, `harness trends --by version` | no |
| Attempts | `…/attempts.json` | driver (bump, unbump, grant, reset) | scheduler | no |
| Needs records | `…/needs/<seq>.json` (open), `…/needs/done/<seq>.json` (resolved: `resolved_at`, `resolved_by` `sweep` or `michael`, `resolved_why`); written to `.tmp` and renamed (`lib/needs.mjs`) | `needs.mjs open` (`needs_open`), `sweep`, `harness needs done` | `harness needs` | no |
| `needs.md` | `.harness/runs/<run>/needs.md`: the open items as markdown (`## ⚠ <headline>`, the card's fields, links, the commands in an `sh` block), or `Nothing needs Michael in <run>.` | `needs.mjs open` and `sweep` | Michael (the notifications' click) | yes (the record branch) |
| Parked features | `…/parked.json` (`id → {answers, why, at}`; `answers` = hash of INBOX.md from its `## Answers` heading on, `inbox.mjs answers`) | driver (park after a `PARKED:` session; unpark when the hash changes) | scheduler, summary, `harness parked` | no |
| Markers | `…/{driver.pid, ended, PAUSE, STOP (empty, or the reason of `harness stop --why`, one line), verified-<m>, merged-<m>, proposed-<m>, nomerge-<m>, needs-<m>, conflict-<m>, moved-<m> (main moved since the verify: the main commit, once per main commit), resolves-<m> (resolve sessions run for it), resolve-<m>-<main> (one per main commit: empty when it resolved, else its `tried` text), resolved-<m> (the files a resolve session settled, for the PR body), rebase-<m> (that main, for its lane or a merge lane to re-base), rebase-rounds-<m> (re-base verify rounds used), record-pr (the record PR's URL, for `gc`), waits-<m> (its PR waits for a dependency, noted once), verify-rounds-<m>, tests-start (the baseline: the first `run_init` with a count writes it, nothing rewrites it), tests-end (the latest green tree's count, from its marker or, an older empty marker, its `check-<key>.out`; a red tree has none: `tests_end` after every coding session, of its lane's slot, and at `finish` (of the last lane's slot, with that lane's `check-<key>.out` copied in first), which clears it when there is none), testcount-source (older runs: testcount-nomatch), review-escalated-<id> (the review gate's once-marker), waited-<t>, port, meta.env, run.env (`SPEC_FILES`, `DEADLINE_AT`, `BASE_REF` from `--base`), brief.md, inbox.md, inbox-unstopped (the `status: stop` line `harness continue` reset, for the driver's note)}` | driver, CLI | driver, CLI, summary | no |
| Record lock and counters | `…/record.lock` (the `record` helper's flock; desk.sh's note takes it too), `…/sessions` (coding sessions started this segment, less those a limit gave back; `MAX_SESSIONS` is checked against it), `…/limits` (refused sessions in a row); both written 0 at each segment's start | driver (`lib/record.sh`) | driver | no |
| Lane state | `…/lanes/<m>/{pid, port, opening, waiting, slot, now, exit, closed, need, svc-up, exclude}`, `…/lanes-end`, `…/merge.lock` (`opening`: its port allocated, the pid not written yet; `waiting`: the kind of the last refusal noted; `lanes-end`: why the run is ending, for the other lanes; the lane's process, written by the coordinator as it starts it, removed when it is reaped, so a pid file is an open lane and its slot taken; its port; the slot's path, so `lib/prompt.sh` renders a lane's prompt as the driver did; its latest session (`<feature> · session <n>` or its verify round), for `harness status`; `<code> <reason>` as it exits, renamed `closed` once reaped; why it needs Michael; the services unit it left up; the slot's excludes file), `…/question` (what the last session added above `## Answers`, for the park's notification), `…/lanes/<m>/review-escalate` (the review gate's pending escalation round, kept across a usage-limit wait and a continue) | coordinator (`lane_open`, `reap`), `slot_open`, the lane (`lane_exit`), `take_question` | the coordinator (`lanes_open`, `reap`, `lane_open`'s free slot), git in the slot, `lib/prompt.sh`, `notify_park`, `harness status` | no |
| Driver scrollback | `…/tmux-driver.txt`: a tmux-started run's driver window, captured when the driver exits (its last `history-limit` lines, tmux's default 2000; the whole record is `run.log`) | the driver window (`bin/harness`) | you, after `h-<run>` closes | no |
| Last outputs | `…/{check-last.out, init.out, teardown.out}`: the last full suite's, the init's and the teardown's output, copied from scratch by `finish` before it deletes scratch (`check-last.out` is the final tree's `check-<key>.out` when scratch has it, else the last `check.out`; a failed copy keeps scratch; the note lists what was kept) | driver (`scratch_done`, `lib/prompt.sh`) | you, after the run | no |
| Suite cache | `…/green/green-<key>`: one marker per code tree that went green, holding its test count; outlives scratch; `verify()` removes the verified tree's (as its init left it) before each verify's suite run (`run_init fresh`). The key (`treekey.mjs`) hashes every tracked and untracked file except `.harness/runs` and the prefixes in `CHECK_KEY_IGNORE` (default `.harness/runs docs/plans`; read as `HARNESS_CHECK_KEY_IGNORE`, exported by `prompt_env`), so a plan alone leaves the tree cached green; a cached line names a non-default list (`check: green (cached for this code tree, N tests; key ignores: docs/plans …)`) (decisions/2026-10-26-suite-split) | `lib/check.sh` | `check.sh` (a cached green), `finish` (`tests-end`) | no |
| Flakes | `…/green/flakes.jsonl`: one JSON row per rerun that went green (`at`, `key`, `names` (the first run's `HARNESS_FAILED=` files, `[]` without the line: noted and counted as `whole suite`), `rerun` (`failed` or `suite`), `first` (the first run's RED reason), `load` (`/proc/loadavg`'s first three), `lane` (`HARNESS_LANE`, empty outside a lane)), appended by every lane's and session's `check.sh`; `…/flakes-noted`: the byte offset `flakes_note` noted up to (whole lines only, under `flakes-noted.lock`), so each row is one `flaky: …` note in `harness-log.md` (decisions/2026-10-29-rerun-guard) | `lib/check.sh`; `flakes_note` (`lib/record.sh`) | `flakes_note`, `summary.mjs` (`flakes`) | no |
| Set-aside entries | `…/entry-stale-<epoch>.json` (an earlier session's `entry.json` no ingest took), `…/entry-failed-<session>.json` (one whose journal append failed): in the state dir, so they outlive scratch | driver (`session`) | you | no |
| Shared limit window | `~/.local/state/harness/LIMIT_UNTIL` (epoch) | any driver hitting a limit | every driver, the queue runner, status | no |
| 7-day window | `~/.local/state/harness/USAGE_7D` (`<utilization 0..1> <reset epoch>`, from the newest session's rate-limit event) | every session (driver) | every driver, the queue runner (`weekly_over`) | no |
| 5-hour window | `~/.local/state/harness/USAGE_5H` (the same shape, `metrics.mjs usage <log> five_hour`; each file through a temporary file named for its process) | every session | the coordinator's `admit` | no |
| Port lock | `~/.local/state/harness/port.lock` | `cmd_start`, `port_alloc_` (flock) | the same | no |
| Queue | `~/.local/state/harness/queue/NNNN-<verb>-<name>.args` (one argument per line; a newline inside one, a multi-line brief, written as `\x1f` and read back by the runner, `entry_overlaps` and `status.mjs`), `held/` (parked entries and their `.why`), `done/`, `runner.log`, `runner.pid`, `STOP`, `last-debrief` (when the last note was produced, and the "since" of the next), `debrief.out` | CLI, driver (continuations), debrief | runner, debrief | no |
| Debrief workspace | `~/.local/state/harness/debrief/<stamp>/{context.md,prompt.md,session.jsonl,final.md,body.md}`, `debrief.lock` | `harness debrief` | you (`--dry-run` prints `context.md`) | no |
| Debrief note and page | `<harness>/ledger/debrief.md` and `debrief.html`, overwritten each time (history: `git log -p`) · `<state>/runners` marks the runs a queue runner started | `harness debrief` (flock, `git commit -- <note>` when `LEDGER_COMMIT=1`) · `harness start` | Michael, the next interactive session | yes, harness repo |
| Desk | `~/.local/state/harness/<p>/<run>/desk/{<stamp>.md,url,last-event}` (the prompt per event, the session URL while the desk is open, the epoch of its last event) · the debrief's in `queue/desk/` · `desk.lock` (one desk start at a time) · tmux session `h-desk`, a window per run and `debrief` | `harness desk` (the driver, the debrief, you) | `harness desk` (reuse, `--list`), `harness gc` (24 h idle) | no |
| Eval results | `<harness>/evals/results/<stamp>-<sha>-<label>/<task>[/r<N>]/{summary.json,commits.json,probe-prompt.md,probes.json,…}` (git-ignored) | `harness eval run`, `eval probes` | `eval compare`, Michael | no |
| Eval workspace | `/tmp/harness-eval/<stamp>/{harness,<task clones>}` (the ref's worktree, a clone per task sealed at `base`: only `main`, no source tag or later object; a private state dir) | `harness eval run` (`harness` removed at the end and by an EXIT trap; the clones and run worktrees stay for `eval probes`) | `harness eval run`, `eval probes`, Michael (`rm -rf`) | no |
| Scratch | `/tmp/harness/<p>/<run>/` (`HARNESS_SCRATCH`: `init.out`, `teardown.out`, `check.out` (the last full suite), `check-rerun.out` (its rerun, when it was red: decisions/2026-10-29-rerun-guard), `check-<key>.out` (the newest code tree's only; its `green-<key>` marker, holding the tree's test count, is in the state dir's `green/`), `scopes/<unit>.{started,show}`, `entry-*`, `context.*`, `retro.md`, `retro-proposals.json` (the retro's, past `restrict`, until the ledger merges it), a project's dev DB, screenshots, review diffs). **`finish` deletes it** (`scratch_done`, after the ledger): `init.out`, `teardown.out` and `check.out` (as `check-last.out`) are copied into the state dir first, and `scratch_rm` removes only this run's directory as `prompt_vars` builds it, and only when its real path is that too (no symlinked project or run dir; `rm -rf --one-file-system`), never `/tmp/harness/<p>/` (it holds `live.lock`). `KEEP_SCRATCH=1` keeps it. A crash, a SIGKILL or a stop mid-session leaves it, for you to read and for the optional age rule (`templates/user/harness-tmpfiles.conf`: 3 days untouched) | driver, init, check, sessions | sessions, driver | no |
| Cache | `${XDG_CACHE_HOME:-~/.cache}/harness/<p>/` (`HARNESS_CACHE`, created by the driver): what a project installs once and keeps across runs and boots, Playwright browsers (`PLAYWRIGHT_BROWSERS_PATH=$HARNESS_CACHE/ms-playwright`) and the like; never deleted by the harness | the project's init and sessions | the same | no |
| Live-write lock | `LIVE_LOCK` (default `/tmp/harness/<p>/live.lock`; dj: `/srv/docker/crates/live.lock`, shared with the backup job) | sessions under `live-staged` (`flock -n`), the backup script (`flock -w`) | both | no |
| Ledger | `<harness>/ledger/runs.jsonl`, `ledger/<p>/<run>/{summary.json,retro.md,…}` | driver at the end (flock, `git commit -- <paths>`; the retro's proposals merged into `retro-backlog.jsonl` in the same lock and commit) | `harness trends`, retro, calibration | yes, harness repo |
| Retro backlog | `<harness>/ledger/retro-backlog.jsonl` (one row per retro proposal id across runs: `id`, `title`, `first_seen`, `runs_seen`, `status` proposed · specced · queued · merged · dropped, `spec`, `pr`, `note`; decisions/2026-10-26-retro-backlog) | the driver's `finish()` (`ledger()`, merging the retro's `retro-proposals.json` under the ledger flock) and `harness backlog` (set, import), never a session | the retro prompt (`{{BACKLOG}}`, the text list), the debrief (its gathered context, the rows as JSONL) | yes, harness repo |

### Memory model

Four buckets (CoALA), each store tied to a scope, with one writer kind and one mutation rule
(`docs/specs/2026-10-25-throughput-and-memory-design.md` §6). The paths are the ones in the table above.

| Scope | Working (what this actor sees now) | Episodic (what happened; append-only) | Semantic (what is true now; in place) | Procedural (how to work; in place, reviewed) |
|---|---|---|---|---|
| **Session** | the prompt; `context.md`; the auto-loaded `CLAUDE.md` (derived by the driver, never hand-edited) | its transcript (`logs/*.jsonl`, state); its `metrics.jsonl` row; its `entry.json` → one line of `entries.jsonl` | none: it proposes (entry `discoveries`, `questions`, `proposed_changes`) | none |
| **Lane** | none | the lane column in `metrics.jsonl`; the `lane …` notes in `harness-log.md` | none (port, pid, scratch: deleted with the lane) | none |
| **Run** | `context.md` per session (cap per kind) | `entries.jsonl`, `harness-log.md`, `progress.md` and `progress-archive.md` (rendered), `brief.md`, `INBOX.md` questions, `retro.md`, `summary.json` | `INBOX.md` `status:` and `## Answers`; `feature_list.json` `passes`; discoveries with `affects: ["run"]` | the run's `brief.md` |
| **Project** | none | `.harness/runs/<run>/` on its record branch; `docs/plans/`; `docs/specs/` | the decisions store (`DECISIONS=`: `journal/decisions/` or `docs/decisions.md`, an overturned rule rewritten in place with one `Updated in place <date>` line); `## Gotchas` in `CLAUDE.md` (15 lines, in place) | `CLAUDE.md` (all but Gotchas), `.harness/config.sh`, `.harness/{check,init,teardown}.sh`, `.claude/settings.json` |
| **Harness** | the initializer's calibration line (derived each time); the debrief's context | `ledger/runs.jsonl`, `ledger/<p>/<run>/`, `queue/runner.log`, `journal/` | `ledger/retro-backlog.jsonl` (keyed by id, status moved in place by the CLI); `ledger/debrief.md` (a view, overwritten) | `lib/`, `prompts/`, `policy/`, `templates/`, `journal/decisions/`, `docs/architecture.md` |
| **User** | none | none | Michael's own notes | `~/.claude/CLAUDE.md`, `~/.claude/settings.json`, `~/.config/harness/config.sh` |

Rules that follow, each enforced where the driver can:

1. **Append or in place is decided by bucket, not by file type.** Episodic stores only grow: a mistake there is a new
   entry (`dead_ends`), never an edit. Semantic stores are rewritten in place with one dated line; a dead rule beside
   a new one is a memlint finding. Procedural stores change through review. Working stores are derived and may be
   regenerated at any time.
2. **One writer kind per store.** The driver writes the run's episodic stores and the ledger; sessions write their
   `entry.json`, their `passes`, project semantic files and code; Michael writes `INBOX.md` answers, user and policy
   files; the CLI moves backlog status.
3. **Scope is declared, not inferred.** An entry's `discoveries[].affects` carries the scope (a feature, a
   milestone, `"run"`, and `"project"` for a fact that outlives the run).
4. **Derive, don't store.** Test counts, file lists, calibration, "needs Michael" lists and the debrief are computed
   from the ledger or the tree; memlint flags stored copies.
5. **Working memory has a budget per role.** `CONTEXT_PACK_BYTES` bounds the coding pack; verify gets a larger
   `CONTEXT_PACK_BYTES_VERIFY`, failed evidence rows first.
6. **Lanes add no store.** A lane's state is operational and dies with it; its facts go through the same entry.

A new store must name its bucket, scope, writer and mutation rule before it exists; this section is the registry.
The routing block (`decisions/2026-10-26-where-things-go`) tells sessions which row to use.

## 5. The life of a run

```
harness start ─► worktree + branch ─► driver (the coordinator):
  [resume?] merge main in before any session, the initializer included (and reload the config if it changed) · merge verified (v3) milestones
  [no list] init + suite ─► INITIALIZER (runs the lint, fixes it) ─► feature_list.json, entry.json ─► entries.jsonl ─► progress.md (rendered)
            ─► lint note ("lint: <n> findings (…); the list is not edited — first: …" or "lint: clean"; the list stays as written)
  coordinator, every HARNESS_LANE_POLL s (a lane's exit wakes it at once):
    reap: a lane whose process is gone → "lane <m> closed (<reason>)"; 13 (cap, limit, weekly) or feature-list edits
      end the run once every lane has exited; merge_milestones (a merge may free a waiting PR)
    end if: session cap · deadline (lanes stop between sessions, then the deadline's verifies, each in a lane) ·
      STOP/"status: stop" (wait for the lanes) · pause: logged once, nothing opens (the lanes pause themselves)
    no lane open: wait out LIMIT_UNTIL · the weekly budget
    open while lanes alive < MAX_LANES (1) and admit (memory reserve, five-hour window) lets it: each lane F lanes
      offers, in list order → "lane <m> opened (slot <k>, …)", or "lane <m> waiting: <reason>" once per reason
      (F lanes: a feature to try, every feature passing (to verify), or a review's escalation round pending in it)
    nothing open, nothing to open, and the count the opens used saw no lane either → the end reason (below); a lane
      gone since that count is reaped at the next poll first (decisions/2026-10-29-lane-count-end-check)
  each lane (lib/lane.sh <m>, in its slot, until it exits with its reason):
    stop if: session cap · deadline · STOP/"status: stop [<why>]" → "stopped by Michael[: <why>]"
      deadline (paused or not): first one verify per complete, unverified milestone ("deadline reached: <m> complete
      but unverified; one verify before the end"; no escalation, no attempt granted), merged if it holds; none when
      a stop came first ("…; stopped by Michael, so no verify before the end") or a usage-limit window holds
      ("…; the usage limit holds until HH:MM, so no verify before the end")
    pause while: PAUSE/"status: pause" (services down first, the note committed and pushed)
    unpark every feature parked under different INBOX answers
    wait while: LIMIT_UNTIL is in the future (any run set it); services down first when the wait is over SVC_IDLE_STOP_MIN
    verify every complete, unverified milestone (in order) ─► see below; a refused verify waits for the window
    stop if: the 7-day window (USAGE_7D) is past WEEKLY_STOP_AT → "weekly budget (…)"
    next = first feature of the lane: not passing, not parked, attempts < MAX_ATTEMPTS, every dependency passing
      none → "done" (all pass) | "blocked on X" (a given-up feature) and/or "waiting on Michael: Y" (parked)
             | "no feature left to try"
    init + suite (cached) ─► context.md (pack for this feature) ─► CODING SESSION (one feature) ─► commit leftovers
      ingest entry.json ─► entries.jsonl ─► render progress.md + progress-archive.md (after every session, verify included)
      environmental? (limit, API error, $0 one-turn) → keep its commits, revert its claims (the list, "passes"
        included), give the attempt back, set LIMIT_UNTIL; MAX_LIMIT_HITS in a row → end "usage limit"
      repair the list (only its own passes may change) · un-pass if the suite is red · tests-end · metrics · push
      not passing and the final message says "PARKED: <why>" → attempt given back, parked until the answers change
  VERIFY m: merge main in → context.md → session (its code edits are reverted) → refused? deferred, no verdict
      → a new entry with one evidence row per step? no → one re-run on the stronger model → still no → not verified
      → suite green on that tree? → tag run/<run>/<m> (v3) → merge_milestones (PR per milestone, in order)
      a step fails → one more attempt for the feature, then "needs Michael"
  CONFLICT with main (decisions/2026-10-29-conflict-resolution; an opted-in sorted list merges by itself first, merge-sorted.sh):
      VERIFY's sync_main, in a lane, CONFLICTS=resolve → resolve: resolved → "<m>: main merged in by a resolve session
        (…); the verify goes on with main merged" · refused by a limit → verify returns 2 (no round), the lane waits for
        the window and verifies again · not resolved → main_conflict (with tried), the verify goes on without main (nomerge-<m>)
      merge_one: the tag doesn't merge as it is and conflicts → return 3 (moved-<m>), no record: the lane re-bases
      rebase: main merged into the verified commit conflicts, a re-base round left → resolve: resolved → one verify round
        on the merged commit (never the disjoint suite-only path), then tag and merge · refused → rebase-<m> back, after
        the window · not resolved, or no round left → merge_conflict (with tried) and conflict-<m>: needs Michael
      Michael's, as before: the record branch's sync_main (a resumed start) · slot_open's base and diverged-branch merges
        (the coordinator: a session there would hold every lane) · harness merge · merge_one at the run's end (ended) ·
        CONFLICTS=michael
  finish: every lane exited · merge what's verified · the last lane's init/check output into the run's scratch · tests-end · services down (the run's, then those the last lanes
          left up) · every slot removed, merged lanes' branches deleted · summary.json · report.md, pushed · notify · RETRO ·
          report.md again · ledger · scratch: init.out, teardown.out, check-last.out into state, rm the run's scratch
          (KEEP_SCRATCH=1 keeps it) · queue a continuation (a feature left to try or a pending review round) · the record PR
          (`<run>: run record`: merged under auto, left under pr, none with RECORD_PR=off; nothing deleted)
  EXIT trap (every exit, a TERM included): TERM every lane and wait for it (each stops its session's scope and its
          services) · stop the running session's scope · services down · write ended · rm driver.pid
  services down <why>: .harness/teardown.sh (TEARDOWN_CMD) · stop harness-<run>-svc · note "services stopped (<why>)";
          once per started init, silent when this segment ran none. Its stop points: finish (<end reason>, so STOP
          gives "stopped by Michael") · the EXIT trap (driver exited) · pause (paused) · a usage-limit wait over
          SVC_IDLE_STOP_MIN minutes (usage-limit wait) · the memory gate's wait (memory wait). The next init (a coding
          session's or a verify's) starts them again
```

**End reasons** (written to `state/ended`, shown by `harness status`, recorded in the summary):

| Reason | Meaning | What happens next |
|---|---|---|
| `done` | every feature passes | nothing; `harness gc` cleans up once milestones are merged |
| `blocked on X` | X was given up and the rest depend on it (directly, or through a milestone that can't verify without X: `laneBlocked`) | needs Michael: read X's progress entries, answer in INBOX.md, `harness continue` |
| `waiting on Michael: Y` | Y is parked (its session said `PARKED:`) and what's left depends on it (may follow `blocked on X; `) | answer in INBOX.md (phone or `harness answer`), then `harness continue`: changed answers unpark it |
| `no feature left to try` | everything left is given up (no dependency chain) | needs Michael |
| `weekly budget (…)` | the plan's 7-day window passed `WEEKLY_STOP_AT` | nothing automatic; the queue won't start runs either until the window resets |
| `session cap (N)` | the session budget is spent | a continuation is queued when a feature is left to try or a review's escalation round is pending (`AUTO_CONTINUE=1`, at most `AUTO_CONTINUE_MAX`=3, within the run's `--until`, given-up features stay given up) |
| `deadline`, `deadline (paused)` | the run's time (`HOURS` or `--until`) is up; a milestone complete but unverified got one verify first, and merged if it held | nothing automatic: time is your budget. `harness continue` or queue it for another night |
| `usage limit (N sessions refused in a row)` | the plan refused `MAX_LIMIT_HITS` sessions in a row | the run ends so the queue isn't blocked; `harness continue` later |
| `stopped by Michael`, `stopped by Michael: <why>` | STOP or `status: stop`; the reason is `STOP`'s line (`harness stop --why`), else the text after `status: stop`, cut at 200 characters (`stop_why`, decisions/2026-10-26-stop-reason); summary.mjs never reads its words as a cause. The retro prompt says it (`{{END_REASON}}`) | `harness continue` when you want |
| `feature-list edits` | MAX_REPAIRS sessions in a row edited the list | a prompt/model problem: look before continuing |
| `initializer failed` / `usage limit before the feature list` | no valid list | fix and `harness continue` (it re-runs the initializer) |
| `driver exited unexpectedly` | the trap fired without a reason (crash, kill) | the trap stopped the session's scope and the services first (`services stopped (driver exited)` in `run.log`; not after a SIGKILL); `harness continue` resumes safely: everything is on disk |

## 6. The feature-list contract

```json
{ "id": "T1-03", "milestone": "T1", "kind": "build", "model": "opus",
  "description": "observable behaviour", "steps": ["verifiable check", "…", "the suite is green"],
  "after": ["T1-02"], "passes": false }
```

- **Order** is priority. **Dependencies**: `after` if present, else *every earlier feature*. So by default one failure
  blocks everything behind it (safe), and the initializer opts independent work out with `after`. `after` may name
  feature ids or milestone ids (every feature of that milestone before this one). The initializer must give the
  first feature of every milestone an `after` (`[]` if independent), and any feature that doesn't need its predecessor
  in the same milestone; the driver notes once per run which milestones after the first lack one (D-H25).
- **Step lint** (`features.mjs lint <list>`, decisions/2026-10-26-step-lint): pure, reported, never applied. One
  `<id>\tstep <n>\t<rule>\t<text>` line per finding, exit 1 with findings. Rules: `no-anchor` (a step with no digit,
  quote, backtick span, path or file name; `the suite is green` is exempt), `outside-repo` (`~`, `$HOME`, `../`, or an
  absolute path under `/home /root /srv /etc /var /opt /usr /mnt /media`; `/tmp`, `/dev/null` and other routes pass; a route or a live path under one of those roots, `GET /media/x` or `/srv/n8n/live.lock`, trips too),
  `self-match` (a grep command over a step-quoting run-record file, not `harness-log.md`, whose pattern matches the step's
  own text), `undeclared` (the milestones above, one finding on each first feature, `step -`), and the review sizing
  (decisions/2026-10-26-reviews-sized-to-milestone; kinds as `kindOf` gives them, `step -`): `review-small` (a review
  feature in a milestone of one or two build features, whose last build feature's steps should carry the review) and
  `review-missing` (three or more build features and no review feature, on the milestone's last). The initializer runs
  it before its commit (`{{LINT}}`, the live harness's `features.mjs lint`) and fixes what it prints; the driver runs
  it once after the initializer and notes what is left (`lint: …`), never editing the list.
- **Parked** (D-H26): a session that can't go on without Michael ends with `PARKED: <why>`. The feature is skipped
  like a given-up one (only its dependants wait) without spending an attempt, until INBOX.md's answers change.
- **kind** ∈ plan · build · review · check · docs. It drives cost-by-role and nothing else (inferred for v2 lists).
- **model**: alias (`fable`, `opus`, `sonnet`, `haiku`) or a full `claude-…` id.
- **Write rules**, enforced by `features.mjs repair` after every session: a coding session may change only its own
  feature's `passes`; a verify session may only turn its milestone's `passes` true → false. Anything else (text, steps,
  order, additions, removals) is reverted from the pre-session snapshot and logged; 3 sessions in a row → stop.
- There is deliberately **no way for an agent to add features mid-run**. New work comes from Michael: a brief on
  `continue` (the next initializer-less sessions read it), or a new run.

## 7. Guards

| Guard | Trigger | Action | Where |
|---|---|---|---|
| Edit repair | list differs from the snapshot beyond the allowed flip | revert, log; stop after `MAX_REPAIRS` in a row | `features.mjs repair`, driver loop |
| Red suite | a session flips `passes` but `check.sh` fails | un-pass, log | driver loop |
| Attempts | `MAX_ATTEMPTS` real sessions without passing | given up → dependants blocked | `features.mjs schedule` |
| Environmental session | the session's **final** result has `api_error` / `api_error_status ≥ 429` / `terminal_reason: api_error`; regex fallback; `$0` and ≤ 1 turn; no result within 120 s | commits kept, claims reverted (list back to the snapshot), attempt given back; `LIMIT_UNTIL` = rejected window's `resetsAt` + 2 min (else 15/30/60 min); the run ends after `MAX_LIMIT_HITS` in a row | `metrics.mjs environmental`, driver |
| Timeout | `SESSION_TIMEOUT` (exit 124; 137 when `timeout -k 30s` had to KILL) | counts as a real attempt (the feature is too big) | `metrics.mjs` |
| Session scope | every session (init, coding, verify, retro) runs as `timeout -k 30s $SESSION_TIMEOUT claude …` inside the transient user scope `harness-<run>-s<n>` (`<n>` from `state/scope-seq`, never reused in a run) with `MemoryHigh=SESSION_MEMORY_HIGH` (5G), `MemoryMax=SESSION_MEMORY_MAX` (6G), `MemorySwapMax=SESSION_SWAP_MAX` (1G), `OOMPolicy=continue` | the scope is stopped when claude returns (what it backgrounded goes with it: note `<kind> session left <n> process(es) running; stopped with its scope`); the cap reached → the kernel kills at it, exit 137, note `<who>: the session hit its memory cap (6G)`, the attempt is the feature's; no user systemd → one note per segment, `no user systemd: sessions and suites run uncapped`, and sessions run bare; systemd refusing one scope after the probe passed (a `MemoryMax` it can't parse, the bus gone) → that session runs bare, note `<kind> session ran uncapped: systemd-run failed (exit <rc>)` (`SCOPE_BARE`; systemd's error is in the transcript) | `session()`, `lib/scope.sh`, `metrics.mjs environmental` |
| Suite scope | every `check.sh` run (the driver's and a session's, full or subset) runs as `timeout -k 30s $CHECK_TIMEOUT bash -c <CHECK_CMD>` inside the transient user scope `harness-<run>-check-<pid>` with `MemoryMax=CHECK_MEMORY_MAX` (3G), `MemorySwapMax` 1G, `OOMPolicy=continue`, no `MemoryHigh` | the scope is stopped after the suite returns; exit 124, or 137 after the whole `CHECK_TIMEOUT` (timeout had to KILL) → `check: RED (timed out after 15m, exit <rc> after <n> s)`; a 137 whose scope peaked at the cap (`scope_capped`) → `check: RED (killed at its 3G memory cap, exit 137 after <n> s)`; both are red like any failure (a subset prints only these lines after its own output); a TERM, INT or HUP to `check.sh` (the calling session's scope stopped, a Ctrl-C) stops the check scope too (the suite runs in the background of a trapped `wait`); no prefix or no user systemd → bare, under the same timeout | `lib/check.sh`, `lib/scope.sh` |
| Rerun guard | a full `check.sh` run is red, not by a timeout (124, or a 137 that took the whole `CHECK_TIMEOUT`) or a kill at the memory cap | rerun once by `CHECK_RERUN` (`auto`: the `HARNESS_FAILED=` files, else the whole suite · `failed` · `suite` · `off`); green → `check: green after a rerun (flaky: …)`, exit 0, a `green/flakes.jsonl` row, then one `flaky: <names> (red, then green on a rerun; load <1-min>)` note (`flakes_note`, after each coding session's un-pass check, verify, disjoint re-base and in `finish`), counted in `summary.json` `flakes` and `report.md`'s `Flakes` row; red again → red as before (un-pass, `verify_red`, re-base fail). Never quarantined (decisions/2026-10-29-rerun-guard) | `lib/check.sh`, `lib/record.sh` |
| Services scope | every `run_init` (before the initializer, each coding session and each verify) first stops `harness-<run>-svc` (systemd refuses a unit name still loaded), then runs `timeout -k 10s $INIT_TIMEOUT bash -c <INIT_CMD>` (10m) inside it with `MemoryMax=SVC_MEMORY_MAX` (3G), `MemorySwapMax` 1G, `OOMPolicy=continue`, no `MemoryHigh` | the init's stdin is `/dev/null`; once the init returns, what it backgrounded (a dev server) stays in the scope, capped, until a stop point (Services teardown, below) or the next `run_init` stops it; an init that times out takes its whole process group with it (servers it had started included); `(init exit <rc>)` in `init.out` as before; systemd refusing the unit after a good probe → bare, with the note `init ran uncapped: <why>`; no user systemd → bare and silent (the run's one `no user systemd` note) (decisions/2026-10-25-services-scope) | `run_init` in `lib/driver.sh`, `lib/scope.sh` |
| Services teardown | when this segment ran an init (`SVC_UP`), at every stop point: `finish` (after the last suite run, before the summary: `services stopped (<reason>)`, so a STOP gives `(stopped by Michael)`); the driver's EXIT trap (`services stopped (driver exited)`); a pause, before its poll (`(paused)`, then committed and pushed: nothing else commits during a pause); a usage-limit wait of more than `SVC_IDLE_STOP_MIN` minutes (10), before its `usage-limit window` note (`(usage-limit wait)`; a shorter one keeps them); the memory gate's wait (`(memory wait)`). The next `run_init` (a coding session's or a verify's) starts them again (decisions/2026-10-25-services-stop-points) | `services_down <why>`: the project's `TEARDOWN_CMD` (default `.harness/teardown.sh` when executable at that moment) in the worktree under `timeout -k 10s 2m`, stdin `/dev/null`, with `HARNESS_PORT`, `HARNESS_SCRATCH`, `HARNESS_RUN_ID`, `HARNESS_TEARDOWN_WHY=<why>`, output appended to `teardown.out` in scratch; then `scope_stop harness-<run>-svc`; one note per started init (finish's call clears `SVC_UP`, so the trap after it is silent); a failing hook is in the note (`teardown exit <rc>, see …`), never fatal. A TERM during an init (`SVC_INIT`) stops the svc scope before the hook, so the init can't start what the hook just stopped; the hook runs in the background (`SVC_TD`), so a TERM during a teardown makes the trap wait for it rather than start a second; the trap commits `harness-log.md` alone (not pushed) (L2-06). The trap ignores further TERM/INT/HUP, then first stops the running session's scope (`S_UNIT`): bash runs it at once on a TERM while `claude` would live on (a bare session, without user systemd, does live on to its timeout). The memory gate stops the services too, so `verify()` re-runs the init after a wait (`mem_gate || run_init`) (decisions/2026-10-25-teardown-hook) | `services_down`, the trap and `session()` in `lib/driver.sh` |
| Memory gate | before every init, coding and verify session (not the retro), `MemAvailable` (`${HARNESS_MEMINFO:-/proc/meminfo}`) under `MEM_MIN_AVAILABLE_GB` (5) | note `memory: <n> GB available, under MEM_MIN_AVAILABLE_GB=5; waiting up to 30m`, `services_down "memory wait"`, then poll every 5 minutes (`HARNESS_MEM_POLL` s) up to `MEM_WAIT_MAX` (30m): back over it → `memory: <n> GB available after <s> s; starting the session`; still under → `memory still at <n> GB after 30m; starting the session anyway (its cap protects the box)`. The wait is not the session's wall time; an unreadable meminfo is no gate. The gate runs where the session is decided, not in `session()`: for a coding session after the feature is picked and before its attempt is bumped and its prompt (with the clock) rendered, and after a wait the loop starts over (deadline, `status: stop`/pause, the pick) with the gate skipped once; for a verify round before its prompt; for the initializer before `init` (decisions/2026-10-25-memory-gate) | `mem_gate` in `lib/scope.sh` (exit 1 after a wait), the driver loop, `verify()` |
| Verify | milestone complete | independent session; must write a **new** entry with ≥ one row per step, else one re-run on `VERIFY_ESCALATE_MODEL`, else not verified ("needs Michael"); refused by a limit → deferred, never "holds"; the tree's cached green is removed after its init, before the suite (`verify <m>: suite cache cleared; the suite runs in full on the verified tree`), so its init and the verifier run the suite in full (decisions/2026-10-26-verify-runs-the-suite); suite must be green on the verified tree; a step fails → one more attempt, then "needs Michael" (`MAX_VERIFY_ROUNDS`). At the deadline (`deadline`, `deadline (paused)`) each complete, unverified milestone gets exactly one verify session (`verify <m> once`: no escalation, this round is the last, so a failed step is `failed the re-check in round <r> of <r>` and thin evidence `after one verify at the deadline`), merged if it holds, before `finish`; skipped with a note when a stop came first or the usage-limit window holds (`deadline_verify`, decisions/2026-10-26-verify-before-deadline) | `verify()`, `verify_ready()` |
| Review gate | a `review` feature picked (its kind, `F kind`) | the lane's diff is measured in its slot (`review_diff`: main fetched first, then `git diff --shortstat origin/<main>...HEAD -- . ':!.harness/runs'`, insertions plus deletions; three dots from the fresh ref, so a milestone merged meanwhile drops out, while one still waiting in a PR under `MERGE_POLICY=pr` counts) and the session runs on Sonnet under `REVIEW_OPUS_LINES` (400) changed lines, on Opus at or over (the feature's own model is overridden), note `review <id>: <n> changed lines, under 400; sonnet` (or `at or over 400; opus`); a failed measure → Opus, `review <id>: diff not measured (no origin/<main>); opus`; a review whose round already ran (the once-marker is there: the round parked or didn't pass) runs every later attempt on `REVIEW_ESCALATE_MODEL`, `review <id>: <n> changed lines, escalated earlier in this run; opus`. The prompt's `Review diff:` line (`{{REVIEW_DIFF}}`, empty for other kinds) gives the counts, ending `; escalated to opus` in the round, and its `Review findings:` line asks for the entry summary's `<n> Critical, <n> Important, <n> Minor`. A Sonnet review whose last entry summary (else its final message) gives `<n> Critical` or `<n> Important` above 0 (`reviewFindings`: the pair first, count before or after the capitalised word, never the tail of an id such as `M3-06 Critical`) is un-passed (verify waits for the round) and gets one round on `REVIEW_ESCALATE_MODEL` before the next pick, once per feature per run, costing no attempt: note `review <id>: sonnet found <c> Critical, <i> Important; one round on opus`, clock `Review round 2 of 2 (escalated: sonnet found <c> Critical, <i> Important)`; the pending round is `lanes/<m>/review-escalate` in the state dir, the lane's own (kept across a usage-limit wait and a continue; `F lanes` opens a lane with one pending, the review at `MAX_ATTEMPTS` too, and `finish` counts it as work left for the automatic continuation; decisions/2026-10-27-p1-main-merge), the once-marker `review-escalated-<id>`. `0 Critical, 0 Important` → no round; neither count → none, note `review <id>: no "<n> Critical, <n> Important" in its summary or final message; not escalated`; a review on Opus never escalates (decisions/2026-10-27-review-gate) | the lane loop (`lib/lane.sh`), `review_diff()`, `entries.mjs findings` (`reviewFindings`) |
| Read-only sessions | a verify session changes code, a retro changes anything | reverted by a new commit (`restrict`), logged; the retro's `retro-proposals.json` is copied to scratch first, left out of the note and put back in the run record (decisions/2026-10-26-retro-backlog) | `restrict()` |
| memlint | every segment start (a continue too), beside the deploy check, before the initializer or the first session, on the record worktree (main's tree at the last `sync_main`, plus the record): a lane's edit to `CLAUDE.md` or the decisions store is linted once it reaches main, not from its slot (decisions/2026-10-27-p1-main-merge) | one note `memlint: <finding>` per finding (`<file>:<line> <check>: <text>`), none when clean; findings are its stdout; a lint that exits non-zero (an unreadable file: `cannot read <file>: <code>`) or runs past 60 s (124) is one note `memlint: failed (exit <n>): <its first stderr line>`; notes only, never stops the run (decisions/2026-10-26-memlint); `harness memlint <project>` prints the same | `memlint_check()` in `lib/driver.sh`, `lint` in `lib/memlint.mjs` |
| Gotchas | the `## Gotchas` lines of `CLAUDE.md` differ between a coding session's start commit and HEAD (after its WIP commit, so a limited session counts too); the prompt's Finish step asks for one line (≤ 160 characters, ending `(<run> <date>)`, 15 at most, edited in place, never a rewrite) | note `<feature>: gotchas +<added> ~<edited> -<deleted>` (a multiset diff: reordering is no change, a line out and a line in are one edit, a wrapped bullet is one line, the section ends at the next `# ` or `## ` heading); a session that leaves the section alone gets none; never blocks (decisions/2026-10-26-gotchas-in-place) | `gotchas()` in `lib/record.sh` (called by `lib/lane.sh`), `gotchasDiff` in `lib/memlint.mjs` |
| Journal writer | a session edits `entries.jsonl` or `progress-archive.md` | the initializer's: restored from its start commit; a lane session's copy is compared with the record (`cmp`) and discarded; either way the note `<id>: <file> edited by the session; restored`; readers skip any line that isn't a valid entry and keep line numbers | `journal()`, `entries.mjs readEntries` |
| Record writes | anything that writes the record or shared run state (note, journal, context, take-back, the flip, counters, record commits and sync) | one at a time under `flock` on `state/record.lock` (`record`; nested calls reuse the held lock; network commands run with `9>&-`) | `lib/record.sh` |
| Lane commit | a lane commit touches `.harness/runs/` (a session `git add -f`'d its copy) | reverted by a new commit (`restrict … runs`), note `<id>: a lane commit touched the run record; reverted`; the record takes nothing from it | `lane_guard` |
| Initializer edits | the initializer changes anything outside the run record | reverted (`restrict … record initializer`), noted: the record branch holds the record only (D3, decisions/2026-10-26-lanes) | driver |
| Lane base | a dependency's tag (`F deps`) not on main conflicts with the lane's base | `<m>: its base conflicts (<dep> vs main); needs Michael`, `needs-<m>`; the lane doesn't open | `slot_open` |
| Lane slot | the slot's `git worktree add` or `checkout -B` of the lane's branch fails | `<m>: its slot failed (<what>; see run.log); needs Michael`, `needs-<m>` (the loop never picks the lane again); a reopened lane always checks its branch out again | `slot_open` |
| Merge dependencies | a verified milestone depends on one that hasn't merged (refused, `pr`, needs Michael) | its PR is opened and waits, `<m> verified; its PR waits for <dep> to merge` once, under `pr` too (it is not `proposed`; once a `proposed` dependency's tag is on main, merged by Michael, it is noted `<dep> merged into main (by its PR)` and the waiting one is proposed); merged by the next `merge_milestones` once every dependency has (after each verify, at the end, `harness merge`) | `merge_milestones` |
| Verified tree | the merge of the tag into `main` wouldn't produce exactly the tag's tree (main moved since the verify) | not merged as it is: re-based (`rebase-<m>`, once per main commit), main merged into the verified commit in a slot; files disjoint from the milestone's: the suite in full, green → `<m> re-based on main <sha>: <n> files, disjoint, suite green; re-tagged` (the tag forced to the merged commit) and merged; overlapping, or `LANE_REBASE=verify`: one verify round (`MAX_REBASE_ROUNDS`), then tag and merge; a conflict → a resolve session (below), then the verify round; red, an unresolved conflict, rounds used or 3 re-bases in one lane → needs Michael (decisions/2026-10-26-lane-rebase-disjoint) | `merge_one` (returns 3 in a lane: no record), `rebase` (lib/lane.sh) |
| Resolved merge | a lane's merge with main conflicts (`rebase`, or the verify's `sync_main`) and `CONFLICTS=resolve`, a session left (`resolve_ok`: `MAX_RESOLVES`, one per main commit, `RESOLVE_TIMEOUT` before the deadline) | a resolution lands only through a verify round on that tree: the resolve session's merge commit is the tree the re-base's verify round (never the disjoint suite-only path) or the verify it ran in checks, the tag moves there, and `merge_one` merges only a tree equal to it. Before the commit the driver checks: the session didn't commit or abort the merge, no `UNRESOLVED:` line, no unmerged path, no more marker lines than either side had; paths outside the conflict are put back as git merged them (`<m>: the resolve session edited <paths> outside the conflict; restored`). Any check failing → `resolve_undo`, the merge aborted, today's record with `tried`; a refused session → deferred like a refused verify, no record | `resolve` (lib/resolve.sh), `rebase`, `sync_main` |
| v2 tags | a tag verified by harness v2 (no "(v3)" in its message) | never merged automatically; `harness merge <run>` merges it (and closes the v2 whole-run PR) | `merge_milestones` |
| Main drift | `main` moved during the run | merged into the lane branch before its verify (a conflict in a lane under `CONFLICTS=resolve` → a resolve session first, below; unresolved → that milestone isn't merged; a `main_conflict` needs record naming the files and the PRs that brought them, notified once per `origin/main` commit, resolved by a later clean merge), and into the record branch when a run resumes | `sync_main` |
| Session budget | `--max-budget-usd`, `--max-turns` per session | the CLI stops the session | `session()` |
| Weekly budget | the newest session reported the 7-day window ≥ `WEEKLY_STOP_AT` (default 85 %, 0 = off) | the run ends before its next coding session; the queue starts no run | `weekly_over` (config.sh), driver loop, queue.sh |
| INBOX repair | a session (a lane's or the initializer) wrote its question inside the steering comment (GitHub hides it, and a `## Answers` there was read as the heading) | the comment goes back as it was before the session, the question below it and above the real `## Answers`; note `INBOX.md: <who>'s question was inside the steering comment (hidden on GitHub); moved below it` (decisions/2026-10-27-question-locations) | `inbox_repair` (lib/record.sh) on `inbox.mjs repair`, after each lane session and the initializer |
| Parking | a not-passing session's final message has a `PARKED:` line | attempt given back; skipped until the INBOX answers change | driver loop, `features.mjs park/unpark` |
| Desk | `DESK=1` and a park, a blocked or waiting run end, verify or a merge needing Michael | a desk failing to start never stops or fails the run: `desk()` drops the output, notes a non-zero exit and returns 0; `desk.sh` itself exits 0 with a note and the plain notification when there is no tmux, no URL in time, or the lock is held | `desk()` (driver), `plain()` (desk.sh) |

## 8. Branches, tags and PRs — and what `run/*/final` was

| Ref | Created by | Lifetime | Meaning |
|---|---|---|---|
| `harness/<run>` | `harness start` (from `--base`, else `origin/main`) | until `harness gc` (record-only, so done once nothing else runs; the queue runner's end-of-queue `gc --all-merged --deps` deletes it here and on origin with its worktree, the ledger keeping the record, except while its record PR is open: `state/record-pr` names it and `gh pr view` says `OPEN`, or gh can't answer); never deleted by `finish`, so a same-night `harness continue` finds it | the run record only (`.harness/runs/<run>/`): only its own record PR carries it |
| PR "`<run>: run record`" | driver, `record_pr`, the last step of `finish` (`RECORD_PR=end`, the default; the open one reused) | merged by the driver under `auto` (`record PR merged into main · <url>`), left for you under `pr` (`record PR opened; left for Michael (MERGE_POLICY=pr) · <url>`); none under `RECORD_PR=off` or `MERGE_POLICY=off`, or when the branch has changes outside its record that main lacks (a `--base` run, a phone edit outside `.harness/runs/`) (`record PR: none (…)`) | the record onto `main`: its diff is `.harness/runs/<run>/` only, so it can't conflict; `harness merge`'s v2 closer leaves it open |
| `harness-lane/<run>/<m>` | driver (`slot_open`): from `--base` or `origin/main`, plus the tags of dependencies main doesn't have; resumed from itself (`harness continue`, a segment that ended mid-milestone): the origin's when it is ahead of the box's or the box has none (a fix pushed by hand), the box's when it has commits the origin lacks (a failed push), the box's with the origin's merged in when they diverged (`<m>: harness-lane/<run>/<m> here and on origin had diverged; merged origin's into it`; a conflict: needs Michael) | deleted when its PR merges: on the origin at once, here when its lane closes (`lane <m>: branch harness-lane/<run>/<m> deleted (merged)`); under `pr` kept until the driver or `harness gc` sees it merged; kept unverified or unmerged (decisions/2026-10-27-lane-branches-and-slots) | milestone `<m>`'s code, worked in the slot |
| `run/<run>/<m>` (annotated tag) | driver, after verify holds, at the lane tip | permanent | "this commit is milestone `<m>` verified": the exact merge point |
| `harness-merge/<run>-<m>` | driver, `merge_one` | deleted after the merge | a branch at the tag commit, so the PR contains exactly that prefix of the run |
| PR "`<run>: <m> (verified)`" | driver | merged by the driver (`auto`) or left for you (`pr`, the default) | the audit record: features, verify evidence table, cost so far |

**The merge driver in worktree config.** A sorted one-item-per-line file a project opts in with `.gitattributes`
(`<path> merge=sorted-union`; this repo: `tests/fixtures/check-names.txt`) merges by `lib/merge-sorted.sh`.
`merge_drivers <worktree>` (`lib/record.sh`) turns `extensions.worktreeConfig` on and sets `merge.sorted-union.driver`
with `git config --worktree`: in the record worktree every segment (right after the first `sync_record`, before a
resumed start's `sync_main`) and in each slot at `slot_open`. So the driver runs in the harness's checkouts only;
Michael's checkout, with no such config, merges the file as text, as git always did. Attributes are read from the
merging tree, so a `.gitattributes` only main has applies once the lane's tree has it; `git merge-tree --write-tree`
(`merge_one`'s check, in a harness worktree) runs the driver too; `harness show`, in the project's own checkout, doesn't.

**Why a lane per milestone.** Before lanes a run branch was linear (T0's commits, then T1's, T3's, T4's), a tag was
a point on that line, and merging a later tag carried every earlier commit, verified or not: hence the ordering rule
("stop at the first unverified milestone") and held "tainted" tags. A lane tip holds main, its dependencies' verified
tags and its own commits only, so each verified milestone merges on its own once its dependencies have; the record
travels on `harness/<run>` and reaches `main` only through its own record PR at `finish` (decisions/2026-10-26-lanes, P2-05).

**`run/<run>/final`.** In v2, the end of every run called `propose final`, which **tagged the branch head as
`run/<run>/final` with the message "final verified"**, whatever had been verified, and refreshed the whole-run PR.
On 10-17 that labelled 16 unverified Pathways features and 14 unbuilt dj features as "final verified". The two tags
(`run/threads-2026-10-17/final`, `run/dj-2026-10-17/final`) point at bookkeeping commits and nothing uses them.
v3 has no `final` tag: the end of a run is a summary, not a verification. Delete them when convenient (agents may not
delete tags):
`git push origin :refs/tags/run/threads-2026-10-17/final && git tag -d run/threads-2026-10-17/final` (same for dj).

**v2 whole-run PRs** (pathways#4, dj-crate-streaming#3) are closed with an explanatory comment by `harness merge
<run>`, which is also the only way their v2-verified milestones reach `main` (an explicit decision, because v2's
verify was weaker). A plain resume leaves both alone.

**The merge invariant.** A merge happens only when `git merge-tree origin/main <tag>` produces *exactly the tag's
tree*: what lands on main is byte-for-byte what was verified. Merging an earlier milestone through a PR adds a merge
commit to main but no content, so the next tag still satisfies it. When main moved with content (another lane merged),
the lane re-bases: main merged into the verified commit, the suite in full on it when the files are disjoint (a verify
round when they overlap, or with `LANE_REBASE=verify`), the tag moved there (its only forced push), then the merge, so
the invariant holds for the merged tree (decisions/2026-10-26-lane-rebase-disjoint). A lane that closed before its
re-base gets a merge lane (`LANE_MERGE=1`: the slot at the tag, the re-base and merge only); `harness merge <run>` opens
one for each the same way. A milestone that conflicts with main goes to its lane's re-base and a resolve session first (`CONFLICTS=resolve`;
the resolved merge then takes a verify round, so the invariant holds for it too); one still conflicting (an open
`merge_conflict` record) is Michael's to merge by hand. The card's commands do it in a worktree of their own (`<HARNESS_SCRATCH_ROOT>/<project>/fix-<run>-<m>`, never
the slot or the record worktree) and push the lane branch. `harness merge <run>` then takes that branch's tip as the
milestone's when it holds the verified commit: the tag moves there (noted), and the merge goes on from it. A conflict
at the same main is said again on every `harness merge`, never skipped silently (U2 review).

## 9. Partial runs: the pattern

A run ends partial for one of three reasons, and each has one answer:

| Why it's partial | What's already done | What the harness does | What you do |
|---|---|---|---|
| Out of sessions | verified milestones are already **in main** | queues an automatic continuation (same branch, main merged in first; given-up features stay given up) | nothing, if a queue runner is going; else `harness queue start` |
| Out of time, or the plan refused 6 sessions in a row | same | nothing automatic | `harness continue <run>` or `harness queue add --continue <run>` (a request: it starts even after a stop) |
| Blocked: a feature was given up | same | ends with "blocked on X" and notifies; nothing is queued | read X's last progress entry; answer in INBOX.md or give a `--brief`; `harness continue <run>` |
| Verify failed twice, or a merge was refused/conflicted | verified milestones before it are in main | "needs Michael" note + notification; later milestones wait | fix or answer; `harness continue` (or `harness merge` once a refused merge is fixed) |

So "merge as-is" and "run again" stop being choices: **verified milestones are merged as they happen; everything
else continues.** Unverified work is never merged and never thrown away.

## 10. Configuration

Layers, later wins (`lib/config.sh`): harness defaults → `~/.config/harness/config.sh` (yours: models, limits,
`MERGE_POLICY`, `CONTEXT_PACK_BYTES`, `CONTEXT_PACK_BYTES_VERIFY`, `MAX_PARALLEL_RUNS`, `NOTIFY_CMD`, `NTFY_URL`, `NTFY_TOKEN`, `DESK_URL`, `DESK`, `DESK_MODEL`, `STATUS_SINCE`) → `<project>/.harness/config.sh` (`POLICY=` and real overrides) →
the run's options (`--spec`, `--until`; in `state/run.env`) → **conventions** for what's still unset:

| Setting | Convention |
|---|---|
| `MERGE_POLICY` | `pr` (default): a verified milestone opens its PR and waits for you. `auto`: the driver also merges each one (`gh pr merge --match-head-commit`, so the verified tree lands); Michael's user config sets it (`decisions/2026-10-24-permissions-policy`), and a project whose `main` reaches production without a gate sets `pr` in `<project>/.harness/config.sh` (portfolio_site, n8n-home). `off`: no PR. `harness merge <run>` lands verified milestones under `auto` or `pr`, and does nothing under `off` |
| `RECORD_PR` | `end`: `finish`'s last step opens `<run>: run record` from `harness/<run>` against main (the open one reused), merged under `MERGE_POLICY=auto`, left for you under `pr`; `off`: none, the record stays on `harness/<run>` and in the ledger (§8). The suite's base config sets `off` |
| `NTFY_URL` / `NTFY_TOKEN` | empty: notifications go to `NOTIFY_CMD` (or nowhere). Set: the harness posts to that ntfy topic itself, the token as `Authorization: Bearer` (never logged), and `NOTIFY_CMD` is not called |
| `DESK_URL` | empty: no **Answer with Claude** action on a park's notification |
| `DESK` / `DESK_MODEL` | `0` / `opus`: no desk starts by itself (`harness desk` by hand still works). `DESK=1`: the driver and the debrief start one whenever a run needs Michael (§17), on `DESK_MODEL` |
| `SESSION_MEMORY_HIGH` / `SESSION_MEMORY_MAX` / `SESSION_SWAP_MAX` | `5G` / `6G` / `1G`: each session's scope (§7): throttled above the first, killed at the second, at most the third in swap |
| `CHECK_KEY_IGNORE` | `.harness/runs docs/plans`: path prefixes (space-separated) left out of the suite cache key (§4), paths the suite never reads; `.harness/runs` is left out whatever the list says. This repo's `.harness/config.sh` adds `docs/specs journal findings-and-research ledger` |
| `CHECK_MEMORY_MAX` / `CHECK_TIMEOUT` | `3G` / `15m`: each `check.sh` run's scope (§7): killed at the first, TERM after the second and KILL 30 s later; `check.sh` reads them as `HARNESS_CHECK_MEMORY_MAX` / `HARNESS_CHECK_TIMEOUT` |
| `CHECK_RERUN` | `auto`: a red full `check.sh` run is rerun once, the files its `HARNESS_FAILED=` line names, else the whole suite; `failed`: only the named files (no line, no rerun); `suite`: always the whole suite; `off`: never (§7 Rerun guard); `check.sh` reads it as `HARNESS_CHECK_RERUN` |
| `INIT_TIMEOUT` / `SVC_MEMORY_MAX` | `10m` / `3G`: `run_init`'s `timeout -k 10s` around the init's foreground, and the `MemoryMax` of the services scope `harness-<run>-svc` its servers stay in (§7) |
| `TEARDOWN_CMD` | `.harness/teardown.sh` when that file is executable in the worktree, else empty: looked up by `services_down` each time it runs (a hook merged or written mid-run counts), run under `timeout -k 10s 2m` before the services scope stops (§7; template `templates/project/teardown.sh`) |
| `TMUX_KEEP_HOURS` | `24`: whole hours a tmux-started run's session `h-<run>` stays after its driver exits (its `supervisor` window goes at once, the scrollback is in `<state>/tmux-driver.txt`); `0` closes it at once; anything else is 24. Read at `harness start`/`continue` (decisions/2026-10-25-tmux-driver-window). `harness gc` and the queue runner's exit close an ended run's session sooner (decisions/2026-10-25-tmux-reaper) |
| `DEPS_DIRS` | `node_modules .next .next-check .venv`: what `harness gc <project> --deps` deletes (paths relative to the worktree) in the worktrees of ended runs, merged or not; never in the project's checkout or a live, queued or desk-open run's (decisions/2026-10-25-gc-deps) |
| `HARNESS_PROJECTS` | `~/projects` (environment only): where a bare project name (`harness gc myapp`) is looked for when no run of that name has a `PROJECT_DIR` that is still a repository; a path that is a repository resolves to its top level first (`project_dir` in `bin/harness`, for `start`, `init`, `queue add`, `gc`, `memlint` and `status --project`; decisions/2026-10-27-project-names) |
| `HARNESS_GC_TIMEOUT` | `10m` (environment only): how long the queue runner's `harness gc <project> --all-merged --deps` may take before `timeout` kills it and its git children (`gc <p> failed (exit 124)`; the debrief starts anyway; decisions/2026-10-26-gc-unattended-guards) |
| `KEEP_SCRATCH` | `0`: `finish` deletes the run's scratch directory after copying `init.out`, `teardown.out` and `check-last.out` into the state dir (§4); `1` keeps it, for debugging. `HARNESS_CACHE` (not a setting: `${XDG_CACHE_HOME:-~/.cache}/harness/<project>`, exported by `prompt_env`, created by the driver) is where installs that should outlive a run go |
| `SVC_IDLE_STOP_MIN` | `10`: `limit_wait` stops the run's services (`services_down "usage-limit wait"`) before a usage-limit wait of more than this many minutes; the next init starts them again (§7) |
| `REVIEW_OPUS_LINES` / `REVIEW_ESCALATE_MODEL` | `400` / `opus`: the review gate (§7): a `review` feature runs on Sonnet under this many changed lines of the milestone diff and on Opus at or over; a Sonnet review reporting a Critical or Important finding gets one round on the second |
| `CONFLICTS` | `resolve`: a lane's conflict with main (its re-base's merge, its verify's `sync_main`) goes to a resolve session, then a verify round on the merged tree (§7 Resolved merge); `michael`: every conflict needs Michael, as before. The record branch's, a lane base's (`slot_open`), `harness merge`'s and the run's end's conflicts are Michael's either way (decisions/2026-10-29-conflict-resolution) |
| `RESOLVE_MODEL` / `RESOLVE_MAX_TURNS` / `RESOLVE_BUDGET_USD` / `RESOLVE_TIMEOUT` | `opus` / `60` / `5` / `30m`: the resolve session's model (a feature's `model` doesn't apply), turns, spend cap and wall time; none starts with less than `RESOLVE_TIMEOUT` before the run's deadline |
| `MAX_RESOLVES` | `3`: resolve sessions per milestone per run (and one per main commit); past them a conflict needs Michael, its card's `tried` saying so. `harness continue` (fresh attempts) starts the count over |
| `MEM_MIN_AVAILABLE_GB` / `MEM_WAIT_MAX` | `5` / `30m`: the memory gate before each session (§7): under the first (whole GB of `MemAvailable`) the driver waits up to the second, then starts the session anyway |
| `CONTEXT_PACK_BYTES` | `8192`: the cap on a coding session's `context.md`; lower-priority items are cut whole, counted in `_<k> items left out_`. The CLI refuses a value that isn't a whole number ≥ 1024, and the driver then points the session at the full record |
| `CONTEXT_PACK_BYTES_VERIFY` | `16384`: the cap on a verify session's `context.md` (its failed evidence rows first); not raised by `CONTEXT_PACK_BYTES` |
| `STATUS_SINCE` | `24h` (user config): `harness status`'s FINISHED window (`30m`, `6h`, `2d`, `1w` or a date), never fewer than the 3 newest ended runs, never more than 10; `--since` and `--all` override. Colour follows `NO_COLOR` (any non-empty value turns it off) |
| `CHECK_CMD` | `.harness/check.sh` · `npm run check` · `npm test` · `python3 -m pytest -q` · `cargo test` · `go test ./...` · `make test` |
| `SMOKE_CMD` | `node .harness/smoke.mjs` · `bash .harness/smoke.sh` · `true` |
| `INIT_CMD` | `.harness/init.sh` · `true` (the driver runs the suite itself, so init only starts servers) |
| port | first free from `BASE_PORT` (7800), under `port.lock`; a lane in slot 1 and up gets its own the same way |
| run id | `<project>-<date>[-n]` |

**What a project provides**: `CLAUDE.md` (durable rules; read by interactive sessions too, and loaded by Claude Code
in every session, which runs in the worktree; the prompt names it once), one `POLICY=` line, and only the scripts that
are truly its own (a sandboxed `check.sh`, a dev-server `init.sh`, a `smoke.mjs`).
A project deployed by a Git-connected host that builds every branch (Vercel, Netlify)
disables run-branch deploys on `main`: `harness init` writes the guard (`vercel.json` `git.deploymentEnabled`
`"harness/**": false`; a `netlify.toml` `[build] ignore` that exits 0 for `harness/*`), and a run start without it on
`origin/main` notes it and notifies once (`lib/deploy.sh`; milestone PR heads `harness-merge/*` still get a preview).
**What a run provides**: `--spec` files and a `--brief` (scope for this run only).

**Prompt assembly** (`prompt()` → `prompt_render` → `render.mjs`, decisions/2026-10-21-static-first-prompts), in
this order: (1) the static part of `prompts/<kind>.md`: a fixed first line (`# Coding session`, `# Verify session` or
`# Initializer session`), then the role, rules and finish, with no placeholders; (2) at its `{{SECTIONS}}` line the
policy (`prompts/policy/<POLICY>.md`); (3) the run-level parts: *This run* (`prompts/parts/run.md`: run id,
worktree, branch, run directory, port, scratch, suite, init, smoke, spec), "Brief for this run" (pasted as written,
so a `{{X}}` in it stays text), `prompts/parts/rules.md` (one line naming `CLAUDE.md`, which Claude Code loads
itself, when the worktree has one; decisions/2026-10-21-no-double-claude-md), the `## Where things go` block
(`prompts/parts/where-things-go.md`, or `-readonly.md` for verify and the retro; under `# Project rules (this project
has no CLAUDE.md)` when there is none) unless `CLAUDE.md` has a `## Where things go` line, its `{{DECISIONS}}` from
`memlint.mjs store-line` (decisions/2026-10-26-where-things-go), and legacy `.harness/project.md` if
present; (4) the template's *This session* part: `` Feature: `<id>` `` / `Milestone: <m>` (coding), `Milestone:` /
`Features:` (verify) or `Earlier runs' feature sizes:` (initializer), the clock line, the init output. Sections are
one blank line apart. Two sessions of a run share every byte up to *This session*. The clock line (`{{CLOCK}}`,
driver `clock`, coding and verify only; decisions/2026-10-21-clock-and-bounded-init-output) is `Clock: <now> · run
<elapsed> of <total>, ends <HH:MM> · this session: $<budget> budget, <turns> turns, <timeout> timeout · attempt N of
MAX_ATTEMPTS` (or `verify round N of MAX_VERIFY_ROUNDS`, or `Review round 2 of 2 (escalated: …)` for a review's escalation round, §7); the run is this driver's segment, `T0` to `DEADLINE`. A
probe rendered by `lib/prompt.sh` says it is outside a run. The retro (`# Retro`, its run on line 3) gets the
template, the rules line and the read-only block; its `{{BACKLOG}}` is `backlog.mjs list` of the ledger's backlog (≤ 6000 bytes, past which every
row keeps at least `<id> · <status>`; `(empty)` without one, and a store that won't parse is a `backlog: the retro
prompt has no backlog: <why>` note), so it reuses an id, cites a specced/queued/merged item's status and coins a slug only for a new
proposal. `{{INIT_OUTPUT}}` is the last 40 lines of `$SCRATCH/init.out` (init and suite output)
and then `full output: <path>`. The coding and verify templates open their bearings with `Read context.md first` (the pack in the run directory, written by the driver just before the session, §4), so it is not pasted into the prompt. Each session's prompt is kept beside its transcript (`logs/*.prompt.md`).

**Policies**: `build-only` (default: never operate anything live; write live steps down) and `live-staged` (operate
live through the protocol: preflight, stages, stop-and-revert, one writer via `flock`, deploy only from the run's
worktree; the project's `## Live system` section supplies the commands). A policy is text the agent follows **and**
what the permission rules allow; the harness owns the first, Michael the second.

**Permissions.** Headless sessions run in auto mode under your user settings (`~/.claude/settings.json`, where the
history-destroying denies live). A project may add `.claude/settings.json` (passed with `--settings`, because a fresh
worktree is untrusted). The harness never writes either, and agents can't (the auto-mode classifier blocks
"Self-Modification"). The driver logs which applied at start. What agents may do (merge, push, delete merged branches
and worktrees, `docker compose`) and the closed deny list live in `~/.claude/CLAUDE.md` § "Git, merges and
permissions" and the user settings, installed from `templates/user/` by `setup/apply-2026-10-24.sh`. A project file
holds only its own gates and the narrow allows its runs need (portfolio_site's deploy gate, n8n-home's and
dj-crate-streaming's live protocols, rane-one-mixxx's hardware); the others have none.

## 11. Measurement and the improvement loop

1. **Per session**: `metrics.jsonl` row: kind, role, model, cost (max of cumulative results), wall time (driver),
   API time and turns (summed over result events), **tokens** (in, out, cache read/write; `cache_hit_rate`),
   `context_peak`, **orientation** (`orient_tokens/turns/s`: requests up to and including the first edit), exit, `env`, final text,
   and **`mem_peak_mb`**: the session scope's `MemoryPeak` in MB, null when it ran uncapped
   (`decisions/2026-10-25-session-memory-peaks`).
2. **Per run**: `summary.json` (features, milestones verified/merged, tests start→end, cost by role and model, time
   by role, **tokens**, cost and tokens per verified feature, median orientation, first-attempt pass rate, rework (a review gate's Opus round is not a second try), verify-fail rate, **`lanes`** (`max_open`: the most lanes open at once; `lane_hours`: the sum of each lane's open-to-close time, from run.log's `lane <m> opened`/`closed` notes, a lane still open at a segment's end closing there; `wall_hours`: the run's wall time; a `Lanes` row in `report.md` once a lane opened; `harness trends` unchanged), **`review`** (`cost_pct`: the review role's share of the run's cost in % with one decimal, null without a review session; `found_nothing`: review features whose every entry giving counts (one at least) reports `0 Critical, 0 Important`, so an escalated review never counts, of `reviews` that have an entry; a `Review share` row in `report.md`, `review_cost_pct` in the ledger row; decisions/2026-10-27-review-gate), **`flakes`** (`count`: the rows of the state dir's `green/flakes.jsonl`, check.sh's rerun-greens, a line that isn't JSON passed over; `names`: rows per check-file name, a whole-suite rerun as `whole suite`; `{count: 0, names: {}}` without the file; a `Flakes` row in `report.md` right after `Tests`, `3 · <name> ×2, <name>` by count, `0` for none, no row for an older summary; decisions/2026-10-29-rerun-guard), **`conflicts`** (`{resolved, escalated, sessions}`: the `main merged in by a resolve session` notes, the distinct milestones whose conflict with main went to Michael, the metrics rows of kind `resolve`) and beside it **`resolutions`** (`[{milestone, files}]`, from the same notes), a `Conflicts` row in `report.md` after `Flakes` (`<n> resolved by sessions (<m>: <files>; …), <k> to Michael`, no row for an older summary; decisions/2026-10-29-conflict-resolution), `harness` version and dirty flag, sessions real/refused, guard counts, every non-passing feature with an automatic cause), `report.md`
   (the writeup: `harness report <run>`; its `Memory peaks over 2 GB` section lists `<feature> · <model> · <peak> MB`
   per session over 2048 MB, read from the `metrics.jsonl` beside `summary.json`, which carries no peak), and `retro.md` (a Sonnet session classifies "not done" features into
   spec / size / dependency / permission / environment / model / harness causes and proposes ≤ 3 harness changes,
   each with its backlog id, reusing the id of an item already in the backlog it is shown), with the same proposals as data in `retro-proposals.json`
   (`[{id, title, evidence}]`), which the driver merges into `ledger/retro-backlog.jsonl` in `ledger()`: a new id is a
   `proposed` row (its title folded to one line of ≤ 200 characters), a known one gains the run in `runs_seen`, a
   malformed file is one note and skipped; a symlink or a file over 64 KB is not taken.
3. **Across runs**: `ledger/runs.jsonl` + `harness trends` ($ per feature, causes, end reasons over time);
   `harness trends --by version` groups runs by the harness version that ran them, to compare a change before and after.
4. **Back into runs**: the initializer gets a calibration line from the ledger (median and p90 minutes per passing
   feature, this project and all) to size features against reality.
5. **Into the harness**: you read the retros/trends (or ask a session to), turn a repeated proposal into a decision
   (a file in `journal/decisions/`), implement it test-first, and **turn the failing transcript into a stub fixture** (as
   `tests/fixtures/usage-limit.jsonl` was), so the fake never drifts from the real API again.
6. **Replay evals**: `evals/tasks/*` are real past features with their `base` commit; `harness eval run` replays a set
   with a chosen harness ref's own driver, on clones with no real remote, config, state or notification, sealed at `base`
   (`decisions/2026-10-21-eval-run-isolation`, `decisions/2026-10-21-eval-clone-sealed-at-base`), capped by
   `EVAL_BUDGET_USD` and the 7-day window (`decisions/2026-10-21-eval-budget-window-repeat`). `harness eval compare` sets
   two results side by side; a verdict is "within noise" inside the spread of `--repeat` runs, "one sample" without
   (`decisions/2026-10-21-eval-compare-verdicts`); per verified feature is pooled over every repeat
   (`decisions/2026-10-21-eval-per-verified-pooled`). `harness eval probes` asks one tool-less Haiku turn what a task's
   handoff should answer, scored by match (`decisions/2026-10-21-eval-probes`). Evals cost money and are Michael's to run
   (`evals/NEXT.md`); D-H35.

## 12. Queue and parallelism

`MAX_PARALLEL_RUNS` (user config, default 1) bounds live drivers. `harness start` beyond it **queues** the run (its
id is chosen when it starts) and ensures the runner (tmux `h-queue`); `--now` bypasses. A queued continuation is
**requested** or **automatic**: `harness queue add --continue <run>` (Michael, the desk) writes `--queued --requested`,
and starts even a run Michael stopped; the driver's after a session cap and the debrief's pass `--automatic` and write
`--queued` alone, which `harness continue` skips for a run whose `ended` starts with `stopped by Michael` (`skipping
queued continuation of <run>: Michael stopped it` in `runner.log`). `harness queue list` marks each continuation
`(requested)` or `(automatic)` beside its run id, parked ones too. A request for a run whose continuation is queued becomes that
entry, its options included (`already queued: continue <run> (now requested, with this request's options)`); a stop the
driver honours turns its run's queued requests that are no newer than the stop (`STOP`, else INBOX.md) automatic and
notes it:
`stop: the queued continuation <entry> is automatic now (the stop came after the request)`
(the later word wins). `harness continue` of a run a phone stop ended sets INBOX.md's `status: stop …` back to
`status: run`, or the continuation would stop at once; the driver notes
``INBOX.md: `status: stop <why>` set back to `status: run` (that stop ended the last segment; harness continue started this one)``
(decisions/2026-10-26-requested-continuations). `harness continue` refuses a run whose driver is alive. `harness queue add …` queues without starting;
`harness queue start --until 07:30` runs the queue and gives every run it starts that deadline. The runner never
starts a run while `LIMIT_UNTIL` is in the future, and starts **one run per project at a time**: an entry whose
project has a live driver is held in its place (logged once, `holding <entry> (<project>)`) and the next entry for a
free project starts instead (`decisions/2026-10-21-queue-one-run-per-project`); `harness start --now` still bypasses. A
plain `harness start` or `harness continue` (no `--now`, not `--foreground`) of a project with a live run (`project_busy`:
another run's driver `alive`, or a `lane_live` lane) is queued the same way, whatever `MAX_PARALLEL_RUNS` allows:
`<R> is running on <project>: queued (the runner starts it when that run ends; --now starts it anyway)`, a `queued
behind <R>: <entry>` line in `runner.log`, the runner ensured; a continue is queued (`continue <run> --queued
--requested …`, as `queue add --continue` writes it, `--until` as `--until-epoch`) before it changes any of the run's
state, so its `ended` stays. The runner holds an entry for a project with a live lane too, and waits for it rather than
ending `queue empty` (decisions/2026-10-27-same-project-starts). **Overlaps** warn and record, never hold: before a start (by hand or by the runner; `overlap_start`) and at `queue add`, `lib/overlap.mjs runs` compares the paths the new run's spec and briefs name (`named`) with each other run R of the project that is alive or has changes `origin/main` lacks (R's branch changes, `.harness/runs/` left out, plus what R's spec and briefs name); a meeting prints `warning: overlaps <R> on <paths>` and the start goes on (`--now` or not); a start opens an `overlap` record (needs_michael, warn) on both runs, naming the paths and that the new run merges second (`run.log`, `harness-log.md`; on an R that has ended, its state dir only: no `needs.md` or log line in a worktree no commit follows, which gc could then never remove), `queue list` shows `⚠ overlaps <R> on <paths>` under a waiting entry and `status --json`'s queue entry `overlap` `[{run, files}]`; the sweep resolves a record once the other run is gone or merged, or this run merged (`harness needs done <ref>` by hand). With 1, nights are serial: each run gets the whole plan window.

**The queue view** (`status.mjs`, decisions/2026-10-27-read-views): `harness queue list` is `QUEUE <n> · runner ● going|off ·
MAX_PARALLEL_RUNS=<k>`, one row per entry (number, verb, run id or `<project> (new run)`, the mark, the spec basenames
and the brief's first 30 characters with `(+<k> chars)`, its age), a `held: <project> busy (<run>)` line under an entry
the one-run-per-project rule holds, `PARKED <n>` with each entry's `why:`, `RUNNING`, `RECENT` (the runner log's last
5 lines) and the hint `one entry in full: harness queue show <n>`. `harness queue show <n> [--parked]` is the entry's
card: verb, project, run, specs, the whole brief, `--until` as a time, marks, held, other options, why, added and the
`.args` path. The numbering is the one `rm`, `park` and `unpark` take.
The runner **re-reads the config at the top of every poll** (`harness_config /nonexistent`: the defaults, then the
user's file), so a `MAX_PARALLEL_RUNS` edit applies without a restart: it logs `MAX_PARALLEL_RUNS <old> → <new>
(config reloaded)` and the next poll starts more, or fewer. Lowering it only gates the next start; it never stops a
running run, so an entry waits until fewer than the new value are alive. A value that is no plain whole number (`2x`,
or `08`, octal to bash) keeps the old one, logged once (`… is not a whole number: keeping <n>`); a file read half
written falls back to the default for one poll (both changes logged). `HARNESS_QUEUE_POLL` is an
env var, read once at start-up (decisions/2026-10-25-runner-config-reload).
The runner exits when the queue is empty and nothing it started runs, when it is past `--until` with nothing running,
or on `harness queue stop`; whichever, if it started at least one run (marked in `<state>/runners`), it then starts
`harness debrief` once, detached with `setsid`, so a new runner replacing tmux `h-queue` can't kill it (§16). Before that, on every exit it lives through (a runner killed with its `h-queue` session doesn't), it reaps the tmux sessions of every project's ended runs (`tmux_reap`, the same helper as `harness gc`; a `+ reaped tmux session <s> (<run> ended)` line each in `runner.log`); `h-queue` and the desk are no run's session, so they stay (decisions/2026-10-25-tmux-reaper). Then, if it started a run, it **collects as it drains**: `harness gc <project> --all-merged --deps` once for each distinct project (`PROJECT_DIR` in `meta.env`) of the runs it started, logged as `gc <name>: harness gc <dir> --all-merged --deps` and each output line as `gc <name>: <line>` in `runner.log`; a gc that exits non-zero logs `gc <name> failed (exit <n>)` and the debrief starts anyway. Nobody watches it, so it runs with `GIT_TERMINAL_PROMPT=0` under `timeout -k 10s ${HARNESS_GC_TIMEOUT:-10m}` (a hang is `failed (exit 124)`; decisions/2026-10-26-gc-unattended-guards). The gc runs first so the debrief sees what is left; a removed worktree's run record is read from the ledger's copy, and the debrief itself stays read-only (decisions/2026-10-25-runner-gc).

**Lanes beside `MAX_PARALLEL_RUNS`.** `MAX_PARALLEL_RUNS` bounds drivers (runs) on the box; `MAX_LANES` (default 1)
bounds the lanes inside one run: each open milestone is a `lib/lane.sh` process in its own slot, with its own port,
scratch and units (`harness-<run>-<m>-…`), so two runs at two lanes each are up to four sessions and four suites at
once; a second lane opens only with headroom (`admit`, `lib/scope.sh`: `MemAvailable` at least
`MEM_MIN_AVAILABLE_GB + LANE_RESERVE_GB × lanes open`, and a five-hour window not reset yet under `LANE_OPEN_BELOW_5H`;
the first lane always opens; decisions/2026-10-26-parallel-runs-headroom). The queue counts
drivers only and still starts one run per project; a run's lanes share its record (one lock),
its session cap and the plan's usage windows (decisions/2026-10-26-lanes). Two lanes that touch the same lines no
longer stop on the overlap: the second to merge re-bases, a resolve session settles the conflict in its slot
(`CONFLICTS=resolve`), and a verify round on the merged tree comes before its merge; two lanes adding to an opted-in
sorted list (`check-names.txt` here) merge without a session at all (§8, decisions/2026-10-29-conflict-resolution).

**Parked entries** (`harness queue park <n> [<why>]`) move to `queue/held/` with a `.why` file: the runner skips them
and says how many at start-up, `harness queue list` shows each with its reason, and `unpark <n>` puts one back at the
end of the queue, renumbered. New entries are numbered past the parked ones too, and a park whose name is already in
`held/` is refused (`harness: <name> already parked (…)`, exit 1; both files stay) rather than overwrite it
(decisions/2026-10-26-queue-numbering-and-park).

**Live sync** (`lib/sync.sh`, `LIVE_SYNC=1`): before each start with **no driver alive**, the runner levels the
checkout that holds the ledger (the live harness) with origin: it fetches, rebases the driver's unpushed ledger
commits onto `origin/main` and pushes them (never forced), or fast-forwards. It acts only on `MAIN_BRANCH` with no
rebase/merge going, no modified tracked file, and no local commit outside `ledger/`; otherwise it logs why and changes
nothing. Only with nothing alive, because a driver reads its scripts as it runs; the runner's own body is one `{ … }`
block, parsed before it runs, for the same reason. `harness sync` does the same by hand
(`decisions/2026-10-24-close-the-loop`).

## 13. Extending it

| You want to… | Change | Test |
|---|---|---|
| a new policy | `prompts/policy/<name>.md`; projects opt in with `POLICY=<name>` | a run with `POLICY=<name>` checks the prompt contains it |
| a new guard | the driver loop after `repair`/`green`; log with `note` (phone-visible); count it in `summary.mjs` guards | a stub misbehaviour flag + a check in a `tests/checks/` file by topic |
| a new end reason | `finish "<reason>"`; teach `summary.mjs` cause/auto-continue if it should continue | a run that ends that way |
| a new session kind | a template in `prompts/`, a `session <kind>` call, a `MET append … <role>`; extend `parseRunLog` for `"<kind> · model"` lines | stub branch on the prompt's exact first line |
| scheduling rules | `features.mjs schedule()` (pure; unit-testable with node) | a feature list in the stub initializer |
| a new stack | `detect_check` / `detect_smoke` in `config.sh` | `harness init` on a sample repo prints the detection |
| notifications | a call site: `notify "<msg>" title=… priority=high click="$(gh_url …)"` in the driver (the plan's call-site table in `docs/plans/2026-10-19-P1-notifications.md`); a delivery path: `lib/notify.sh` (`NTFY_URL` built in; `NOTIFY_CMD` gets `$1` + `HARNESS_NOTIFY_*`) | `tests/stub-curl.sh` records each call as a block in `$STUB_DIR/curl.log` (`STUB_CURL_FAIL=1` → exit 22); the request shape is `tests/fixtures/ntfy-publish.txt` (from docs.ntfy.sh); `curl_with`/`curl_body` in `tests/lib.sh` |
| memory and process limits | `lib/scope.sh` (`scope_run` around the command, `scope_stop` after it) | `tests/stub-systemd-run.sh` / `tests/stub-systemctl.sh` (through `HARNESS_SYSTEMD_RUN` / `HARNESS_SYSTEMCTL`) log each call as a block in `$STUB_DIR/systemd.log` and keep unit state in `$STUB_DIR/scope/`; their shapes are the real captures `tests/fixtures/systemctl-*.txt`, `systemd-no-bus.txt` (`STUB_NO_SYSTEMD=1`); `sd_with`/`sd_count` in `tests/checks/08-scope-sh-…` (the only file that reads `systemd.log`). Free memory reads `HARNESS_MEMINFO` (the suite's default: the real capture `tests/fixtures/meminfo.txt`, 9 GB; the gate's run uses a copy with only `MemAvailable` rewritten to 2 GB) and polls every `HARNESS_MEM_POLL` s (1 in the suite). The suite's one real scope is `harness-test-<pid>-*` at 64M, stopped in its check |
| a new failure signal from the CLI | `metrics.mjs environmental()`; capture the real transcript lines as a fixture | stub replays the fixture |

Rules of thumb: keep the driver the only writer of refs and merges; keep agents' write surface to code, the run
record and their own `passes`; make every new behaviour visible in `harness-log.md`; add a stub check before trusting it.

## 14. Recovery runbook

| Situation | Do |
|---|---|
| Where is a run's work (branches, unmerged files, conflicts with main, PRs)? | `harness show <run>` (`--files` for every changed file); `harness show <run> <feature>` for one feature's commits, files and sessions. Local refs only: `git fetch` in the project first for an up-to-date ahead/behind and conflict marks |
| What is waiting on me? | `harness needs` (every run) or `harness needs <run>` (`harness parked`, its alias): a card per item, its question or why, where, options and the commands that answer it |
| Driver died (machine reboot, kill) | `harness continue <run>`: worktree, list, attempts and markers are on disk |
| Units left after a SIGKILL (`systemctl --user list-units 'harness-<run>-*'`) | `harness gc <project> --dry-run`, then `harness gc <project>`; by hand: `systemctl --user list-units 'harness-<run>-*' --plain --no-legend` lists them (`-svc` the init's servers, `-s<n>` a session, `-check-<pid>` a suite), `HARNESS_RUN_ID=<run> .harness/teardown.sh` in the worktree first (containers), then `systemctl --user stop <unit>` for each |
| Paused after limit hits | `harness status` shows the window; `harness resume <run>` after it, or let the queue continuation run |
| Merge refused (branch protection) or conflicted | fix on GitHub or in the worktree; `harness merge <run>` |
| `harness continue` says `continue refused: harness/<run> has code main does not have` (a run from before lanes; exit 1, in `run.log` and a high-priority notification, nothing changed) | one of the three it prints: `harness merge <run>` for its verified milestones; a new run, `harness start <project> --brief "finish <what is left>; harness/<run> is the source"`; or finish it by hand on `harness/<run>` and merge it yourself. A record-only branch (its record on main too, like n8n-home-2026-10-22) is never refused |
| A feature keeps failing | read its progress entries; answer in INBOX.md; `harness continue <run> --brief "<guidance>"` |
| The list itself is wrong | stop the run; edit `feature_list.json` yourself (only agents are guarded) and commit; continue |
| Where did a tmux run's screen go? | `~/.local/state/harness/<p>/<run>/tmux-driver.txt`: the driver window's scrollback, saved when the driver exited. it holds the window's last `history-limit` lines (tmux's default 2000); `run.log` beside it is the whole record. `harness attach <run>` still works until `h-<run>` closes (`TMUX_KEEP_HOURS`, 24; `harness gc <project>` or the queue runner's exit closes an ended run's session sooner); the `supervisor` window is gone at once |
| Where did the run's scratch go? | a finished run's is deleted (`KEEP_SCRATCH=1` keeps it); the last full suite's output is `<state>/check-last.out`, beside `init.out` and `teardown.out`. A crashed, SIGKILLed or stopped run's scratch is still at `/tmp/harness/<p>/<run>/` until the optional 3-day age rule (§4's Scratch row; README has its install command) |
| Need to see a session | `jq -r 'select(.type=="assistant")…' ~/.local/state/harness/<p>/<run>/logs/NN-<id>.jsonl` |

## 15. Known limits (candidates for v4)

- Verify evidence is counted, not judged: a verifier can write plausible rows. The real quality gate is still the
  milestone's review (its review feature, or the last build feature's review steps in a milestone of one or two); an occasional Opus audit of verify entries would measure this.
- Inside a run, milestones are the unit of parallelism (lanes, §5, `MAX_LANES`); a milestone's features run one after
  another in its lane. Feature-level lanes (a feature whose `after` lies outside its milestone opening as a lane of
  one) are not built: a milestone's features edit the same modules (decisions/2026-10-26-lanes).
- Admission reads the five-hour window from the newest session's `USAGE_5H`: two lanes that open on a quiet reading
  both spend until their next sessions report, so a second lane can still meet a limit the first would have missed.
- The weekly gate reacts to the last session's figure; it doesn't forecast a night's spend (a run that starts at
  80 % can still use most of the rest before the next reading).
- `harness gc` deletes a run branch whose unmerged commits only touch `.harness/runs/` (the ledger keeps the whole
  run record) unless its driver is alive or a continuation is queued.
- The suite cache (`state/green/green-<key>`) is a file a determined session could create; the key ignores
  gitignored files and the `CHECK_KEY_IGNORE` prefixes, so a suite that does read a file there must not list it. Verify
  removes the verified tree's marker and runs the suite in full; review is the other backstop.
- A milestone whose re-base needs Michael (a red suite on the merged tree, its rounds used, a conflict) waits for
  you: fix it on its lane branch, then `harness continue` (fresh rounds) or `harness merge` (one more re-base).
- A run without user systemd, or whose dev server escaped the svc scope with no teardown hook, can leave that server
  running after `finish`; its `$SCRATCH/server.pid` (the project init's handle on it) went with scratch, so a
  continuation's init can't stop it. `systemctl --user list-units 'harness-*'` and `ss -ltnp` find it.
- `harness gc` reaps the tmux session of a run that has `ended` only: a SIGKILLed driver (no `ended`) or a run that
  ended paused keeps `h-<run>` until its driver window's own timer (`TMUX_KEEP_HOURS`) closes it.

## 16. Debrief

After a queue, one short session reviews what happened and tells Michael, so nobody opens a session to triage.
It replaces a fixed-time morning session: the queue's end triggers it; `harness debrief` by hand is the fallback.

```
queue runner exits (empty · past --until · queue stop), having started ≥ 1 run (<state>/runners)
  ─► setsid -f harness debrief  (output: queue/debrief.out)
harness debrief [--dry-run]:
  preflight: node, jq, git, flock, claude (sources nvm.sh, adds ~/.local/bin; else logs "missing: …" and exits 1)
  flock debrief.lock (a second debrief says it waits, waits, then covers only what is left)
  since = queue/last-debrief (the first time: the newest "runner up"); the next "since" is taken now, before
    runs = every driver started since (run.log): a run starting during the wait or the session is covered next time
    none → nothing to do, no session
  LIMIT_UNTIL in the future: wait (≤ 5 h; HARNESS_LIMIT_SLEEP in tests), else exit (the next debrief covers it)
  context.md (bash, $0, each part capped): status · trends · queue · runner.log since · per run: ended · summary.json
     · report.md · flakes (`summary.mjs flakers`: the names in two or more of the project's last five ledgered
       summaries, newest by ended_at, `<name> ×<runs>`, or `(none)`) · retro.md · INBOX.md · progress.md questions · needs-Michael lines · limit window · rate-limit info
     · the retro backlog (ledger/retro-backlog.jsonl as JSONL rows, proposed first, ≤ 6000 bytes, a cut list
       ending {"more": n})
     · the whole capped at 150 KB; pasted into the prompt with render.mjs --raw ({{X}} in it stays literal)
     (--dry-run: print it and stop)
  DEBRIEF SESSION (DEBRIEF_MODEL=sonnet, 40 turns, $3, SESSION_TIMEOUT; prompt on stdin; --permission-mode dontAsk,
     --allowedTools ALLOW, --disallowedTools DENY; --add-dir ledger, queue/, each run's state dir, worktree and project)
  refused by a usage limit → LIMIT_UNTIL updated; died at startup, not "success", no text → failed (no window):
     exit 1, one notification line, last-debrief untouched: the next one covers these runs
  git status + refs of the ledger, worktrees and projects: before vs after → a warning section in the note
  "CONTINUE: <run> :: <brief>" lines → checked → harness queue add --continue <run> --automatic --keep-attempts --brief "Suggested by
     the debrief …" (or "Not queued: why")
  ─► ledger/debrief.md (overwritten) · last-debrief · ledger/debrief.html (lib/page.mjs: a card per run from its
     summary.json and how it stands now, then the note, escaped; committed with the note) · notify (title `harness debrief`, high when Needs Michael has anything): 3 lines + the
     note's path · DEBRIEF_PAGE_CMD "$page" (optional: copy it somewhere a phone can open it)
  commit (LEDGER_COMMIT=1) only if the harness checkout is on MAIN_BRANCH with no rebase/merge/cherry-pick going, only
     that file; a failed commit is unstaged again ("written but not committed" in runner.log)
```

**Since the last success.** `queue/last-debrief` holds the time the last successful debrief gathered its context (or
the start of a run that was still going then, so its end is seen next time). It is written only after a note is
produced, so a refused, failed or killed debrief changes nothing and the next one covers its runs too.

**The note**: Headline (≤ 3 lines; the notification): what landed on main, what is blocked and why, spend against
the usage window. **Runs**: 3–6 lines each. **Needs Michael**: policy, permission and product questions, sudo steps,
inbox questions the docs can't answer. **Draft answers**: only where the project's docs answer, quoting the doc path;
Michael pastes them into INBOX.md himself. **For the next interactive session**: merge conflicts on run branches,
held or refused merges, the retro backlog's open `proposed` items, most seen first (candidate harness PRs), and items a
run of this debrief re-raised though already `specced` or `queued`; the debrief reads the backlog, not earlier
`retro.md` files. v1 lists; it resolves
nothing and opens no PR. One file, overwritten; `git log -p ledger/debrief.md` is the archive.

**Continuations.** The session may only *ask*; bash queues, and only a run of this debrief that ended on its
deadline or a usage limit, isn't running, has work left (`summary.json`) and isn't already queued. It is queued with
`--keep-attempts` (given-up features stay given up; verify holds stay) and a brief labelled as the debrief's
suggestion. Nothing starts: it waits for the next `harness queue start`.

**Read-only, and the never-list.** The debrief never edits files (in particular INBOX.md, policies, CLAUDE.md,
settings), answers for Michael, starts/continues/merges/stops runs or starts the queue, merges or edits PRs, pushes,
commits, or runs anything live. Enforced in layers:

| | How |
|---|---|
| `--permission-mode dontAsk` + `--allowedTools ALLOW` | only these run: Read, Grep, Glob; `cd ls cat head tail wc grep jq date`; `git log/show/diff/status/rev-parse/rev-list/merge-base/for-each-ref/ls-files`, `git branch --list/-a/-v/-vv/-av/--show-current`; `gh pr view/list/checks`; `harness status/trends/queue list`. Left out on purpose: `rg` and `git grep` (`--pre`, `-O` run programs), plain `git branch`, `harness report` (rewrites summary.json). **The scope lives in one commented array (`ALLOW`) in `lib/debrief.sh`**: widen it there. Checked against the real CLI (haiku, 2026-10-17, $0.004): a read in an added state dir works; Write, a shell redirect and `git … --output=` are denied |
| `--disallowedTools DENY` (wins over ALLOW) | `Edit`, `Write`, `NotebookEdit`; `git diff/log/show --output`; every state-changing `harness` command and `harness report` (bare and by full path); `git push/commit/merge/rebase/reset/checkout/switch/restore/stash/tag/worktree`, `git branch -d/-D/-f/-m`; `gh pr merge/create/close/edit/review/comment/ready`, `gh api/repo/release/workflow`; `sudo ssh scp rsync docker systemctl kubectl tmux kill pkill rm mv cp curl wget npm npx` |
| After the session | compared with before: the ledger directory's files; the worktrees of runs that have ended and the projects: files, HEAD, local branches and tags (not remote refs, not the harness repo's commits, not a still-running run's worktree). Any change is logged and flagged in the note |
| The prompt | the same list in words, including what prefix rules can't express (`git -C …`, shell redirection, a project's `## Live system` commands) |
| Bash | continuations are queued only by bash, after the checks above |

**Cost.** One Sonnet session per queue that started a run, at most 40 turns and $3 (the retro's caps); the context is
capped at a few tens of KB, so expect well under $1. With nothing to cover there is no session. The note's second line
records the model and the session's cost.

## 17. Answer desk

A parked feature waits on a question only Michael can answer, usually while he is away from the box. The answer desk
is the path from the notification to an answer the driver takes, without a branch switch in the GitHub app.

```
session ends "PARKED: <why>", question above ## Answers in INBOX.md
  ─► driver: parked.json[id] = {answers: hash, why, at}; the park notification (§10 NTFY_URL): question, the
     harness answer command, Edit INBOX / Progress, and Answer with Claude when DESK_URL is set
  ─► Answer with Claude opens DESK_URL (Michael's Remote Control environment) → an interactive session on the box
  ─► the harness-answer skill (Michael: "answer the harness" / "what does <project> need?"):
       harness needs (harness parked, its alias) · harness status <run> · the run's INBOX.md and newest progress.md entries
       checks what is safe (files, git, a variable's name with grep -c, never a value, no .env, no sudo)
       proposes the answer in one or two sentences; nothing is done before Michael's yes
  ─► harness answer <run> "<text>"  (state/inbox.md; the driver appends it under ## Answers before the next session)
  ─► the run takes it: still going → its next loop unparks (the answers hash changed), nothing else to run
     ended (or ending, once it has) → harness queue add --continue <run> when a queue runner is going, else
     harness continue <run>; with another run R of the project alive, Michael picks: the queue add (waits for R,
     R merges first) or harness continue <run> --now (beside R); then harness status <run> says it started or is held
```

**`harness needs [<run>] [--all] [--json]`** (`cmd_needs` names the state dirs, `lib/needs.mjs list` renders): `NEEDS
YOU <n> · <runs> runs`, then a card per open item (block before warn, oldest first): `<glyph> <run> · <headline> ·
since <HH:MM> (<ago>) · <ref>` (narrow, or too long: `… · <ago>` and a `ref` field), `blocked` (the subject, what
waits on it with counts, and what waiting costs), `question` (a park: its INBOX section) or `why`, `where` (home as
`~`; narrow: cut at the front, `…/dir/file:line`), each URL whole on its own line, `options` (one recommended, with
why), `do` (the commands; `--json` has their full text), `run` (a park: `runState`); a rule and `done by hand: harness
needs done <ref> · resolved too: harness needs --all`. Nothing open: `NEEDS YOU 0` and `nothing needs you` (`… in
<run>`). A park's commands are `commandsFor`'s as of now: the run's driver alive, a queue runner up, a queued
continuation, and another live run of the project (`overlap.mjs busyRun`, `project_busy`'s rule): then the continue
is two, `harness queue add --continue <run> # waits for <R> to end; <R> merges first` and `harness continue <run> --now
# runs beside <R>; this run merges first if it finishes first`, and `run` ends `; <R> is running on this project: pick
one continue`, since the per-project hold would queue a plain one behind R unsaid
(decisions/2026-10-29-continue-advice-busy-project). **`harness parked [<run>]`** is `harness needs` for text; **`harness parked --json`**
(`cmd_parked` gathers, `lib/parked.mjs` reports, `jq` joins): one element per parked feature that isn't passing
(`parked.json` minus passing ids), oldest first: `{run, project, feature, since, why, question,
running, ending, queued, commands[], ref, card}` (`ref` and `card` from its needs item, stored or synthesized); the question is `questionFor`'s (the newest `### <id>` section of INBOX.md above `## Answers`), running `yes` while `driver.pid` is alive and `ended` isn't written, `ending` when both are, a run whose worktree is gone is skipped. It never writes: no `harness_config`, no
`mkdir`; a broken `meta.env` skips that run only.

**The skill only asks.** It runs commands that already exist, Michael's words passed through a quoted heredoc so
nothing in them is run or expanded; its never-list (never edit INBOX.md, feature lists,
policies or CLAUDE.md directly; never answer without Michael's yes; never run a project's live commands) is text
the session follows, and Michael's yes is the gate. The harness ships the file; Michael installs it once
(`ln -s ~/projects/agent-harness/skills/harness-answer ~/.claude/skills/`).

**The desk starts itself** (`lib/desk.sh`, D-H31). With `DESK=1` the driver calls `harness desk <run> --why …` when a
feature parks (`<id> parked: <why>`), verify or a merge needs Michael (`<m> needs Michael: …`, `<m>: merge refused`)
and the run ends blocked or waiting (`ended: …`); the debrief calls `harness desk --debrief` when its note's
`## Needs Michael` isn't empty. Michael can run either by hand at any time.

```
harness desk <run> --why "<one line>"            (desk.lock: one start at a time, ≤ HARNESS_DESK_WAIT + 10 s)
  ─► <state>/desk/<stamp>.md from prompts/desk.md (run id, why, INBOX and progress paths; no config value)
  ─► window <run> in tmux h-desk open, its claude alive, desk/url kept?
       yes → its screen shows a dialog (the CLI's words: "Esc to cancel", "Enter to select", …) or can't be read?
             type nothing, note it, notify "answer its dialog first" · else type "New since your last brief: <why>.
             Re-read <prompt>." · notify, click = the same URL · done
  ─► tmux new-window|new-session -c ~/projects/<project> (trusted) -- env -u NTFY_TOKEN … claude --remote-control
       "desk · <run> · <why>" --model <DESK_MODEL id> --add-dir <worktree>
  ─► capture-pane until https://claude.ai/code/session_… (≤ HARNESS_DESK_WAIT, 60 s)
       none / claude exited → kill the window · note "desk: …; plain notification" · the plain notification · exit 0
  ─► desk/url · type "Read <prompt> and follow it." · note "desk started: <url> (<why>)" · notify
     "[<run>] needs you: <why>", priority high, click = the session URL · print the URL
```

Every tmux target is exact (`=h-desk`, window ids `@N`): a name would match by prefix. tmux runs `claude` as separate
arguments with no shell, so the `why` (session-written text) is never run; typed lines go in with `send-keys -l`
(literal, never a key name) and Enter half a second later. The desk's note goes to `harness-log.md` through the run
record: the driver commits it at once (`HARNESS: desk`; the retro's revert would drop it otherwise), `desk.sh` commits
it itself when the run's driver is gone. `--debrief` uses window `debrief`, `queue/desk/`, `queue/runner.log` and the
harness checkout as its directory. A refused merge is noted, notified and sent to the desk once per tag commit while the run goes;
`harness merge` says it every time and starts no desk (Michael is at the terminal). Every tmux call runs under `timeout 10`: a wedged server can't hold the driver.
Housekeeping: `harness desk --list` (window, run, URL, age), `--close <run>|--all`, and `harness gc <project>` closes
the project's desks (and the debrief's) idle for 24 h first, then keeps the worktree of a run whose desk is still open. With `DESK=1` Michael gets two
notifications per event: the driver's own (unchanged; it needs no desk) and the desk's.
