# agent-harness

A small, reusable harness for **long-running coding agents**, after Anthropic's
["Effective harnesses for long-running agents"](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents).
An initializer session turns a spec into a feature list (and runs the step lint over it: steps with nothing to check,
paths outside the repo, greps that match their own words, reviews out of size with their milestone; the driver notes what is left); then **one fresh Claude Code session per feature** does the
work, test-first. A deterministic bash driver does the bookkeeping around them: it verifies each finished milestone
independently, **opens a PR into `main` for each verified milestone, and merges it itself only in projects that
opt in with `MERGE_POLICY=auto`**, waits out usage limits, and records every run in a ledger that the next runs
learn from.

Zero dependencies beyond `bash`, `git` (≥ 2.38), `node`, `jq`, `tmux`, `flock`, `claude` and `gh`.
**How it works, in depth: [`docs/architecture.md`](docs/architecture.md).** Why it is the way it is: [`journal/`](journal/README.md).

## Quick start

```bash
ln -s ~/projects/agent-harness/bin/harness ~/.local/bin/harness     # once
harness init ~/projects/myapp            # CLAUDE.md template + .harness/config.sh (POLICY=build-only); prints what it detected
# fill in CLAUDE.md, commit to main, then:
harness start ~/projects/myapp --spec docs/todo.md --brief "items 1–3 only"
harness status                           # one screen: what needs you, what runs, what's queued, what finished (24h)
harness report                           # the writeup: passing, tests, spend total / per feature / by role, causes, memory peaks over 2 GB
                                         # (tests: counted for node:test, pytest, jest/vitest, cargo and go test -v; a suite with no count is said once in harness-log.md)
```

Queue a night's work at once (runs go one after another by default; `MAX_PARALLEL_RUNS` in your config, which the
runner re-reads every poll, so an edit applies without a restart and lowering it stops no running run; the queue
never runs two runs of one project at once, so a second entry for a busy repo waits while later ones go ahead):

```bash
harness queue add ~/projects/pathways --spec OVERNIGHT.md --brief "T5, T7, then T6"
harness queue add ~/projects/hit_list --spec docs/next.md
harness queue add --continue dj-2026-10-17   # a request: it starts even if you stopped the run (a stop after it wins; it replaces a queued one)
harness queue start --until 07:30        # tmux h-queue; no run starts after 07:30, and each one stops by then
```

When the runner exits (queue empty, past `--until`, or `harness queue stop`) and it started at least one run, it
collects as it drains: `harness gc <project> --all-merged --deps` for each project it started a run in (its lines
in `queue/runner.log`, prefixed `gc <project>:`; no git prompt, killed after `HARNESS_GC_TIMEOUT` (10m); a failed gc is logged and never stops what follows). Then it runs
**`harness debrief`**, detached: one short read-only Sonnet session that reads what happened and overwrites
`ledger/debrief.md`. The notification (ntfy or `NOTIFY_CMD`) carries its three-line headline and the note's path (see [Debrief](#debrief)).

| Command | What |
|---|---|
| `harness start` · `continue` · `merge` · `stop` · `pause` · `resume` · `answer` | one run |
| `harness queue [list]` · `queue show <n> [--parked]` · `queue add` · `queue start [--until]` · `queue stop` · `rm` · `clear` | the night's queue (`list` marks each continuation `(requested)`, yours, or `(automatic)`, the driver's or the debrief's: an automatic one is skipped for a run you stopped; a brief shows its first 30 characters, `show` prints the entry whole) |
| `harness queue park <n> [<why>]` · `queue unpark <n>` | set an entry aside: `queue list` shows it with its reason, the runner skips it; unpark puts it back at the end; new entries are numbered past parked ones, and a park never overwrites one of the same name |
| `harness sync` | the live harness checkout level with origin (merged PRs in, ledger commits pushed); the queue runner does this itself whenever no run is alive (`LIVE_SYNC=0` turns it off) |
| `harness backlog [list]` · `backlog set <id> <status> [--spec] [--pr] [--note]` · `backlog import <file.jsonl>` | the retro backlog, `ledger/retro-backlog.jsonl`: one row per retro proposal across runs, `proposed` first, most seen first; `set` moves one (`proposed` · `specced` · `queued` · `merged` · `dropped`), `import` merges rows by id; writes hold the ledger lock and are a ledger commit (`LEDGER_COMMIT`) (see [Retro backlog](#retro-backlog)) |
| `harness status [--all] [--since <d>] [--project <p>] [-v] [--json]` · `status <run> [-v] [--json]` | look: one screen, NEEDS YOU, RUNNING, QUEUED and FINISHED (runs ended in the last `STATUS_SINCE`, default `24h`, never fewer than the 3 newest, never more than 10), then how many are hidden; `--all` lists every run, `--since 3d` widens the window, `--project` keeps one project's; `-v` (or `N=<lines>`) adds a running run's units with `MemoryCurrent`, one line per open lane (`lane <m> · <feature> · session <n> · port <p> · slot <k> · MemoryCurrent <unit> <MB> MB, …`) and the last `N` `run.log` lines; `<run>` prints that run's card (state, now or ended, milestones, lanes, spend, branch, worktree, needs you, next); `--json` the v1 document (`tests/fixtures/status-json-keys.txt`). It fits the terminal (`COLUMNS`, else 100 off a TTY), colours only on a TTY (`NO_COLOR=1` turns it off) and falls back to ASCII glyphs outside a UTF-8 locale |
| `harness report` · `trends [--by version]` · `attach` | look (`report`'s `Lanes` row: the most lanes open at once and lane hours against wall hours; `trends --by version`: runs grouped by harness version, medians of cost, cache hit, orientation) |
| `harness needs [<run>] [--all] [--json]` · `needs done <run>/<n> [--why "<text>"]` | every open item that waits on Michael (a park, a give-up, a failed verify or merge, a run that stopped on its own) as a card: what waits on it, the question or why (the mechanism and its file), where (files with lines, GitHub links), options with one recommended, the commands; block before warn, oldest first; `COLUMNS=60` for the phone; `--all` adds those resolved in the last 7 days; `done` resolves one by hand (read-only but for `done`); each item is a JSON file, `<STATE_ROOT>/<project>/<run>/needs/*.json` (resolved ones in `needs/done/`), what n8n reads |
| `harness parked [<run>] [--json]` | `harness needs` for text; `--json`: each parked feature (run, project, feature, since, why, question, running, ending, queued, commands) with its needs item's `ref` and `card` (read-only) |
| `harness debrief [--dry-run]` | the triage note for every run since the last one (`--dry-run`: print the gathered context only) |
| `harness eval run` · `compare` · `probes` | replay a fixed task set under a harness version and compare two results (see [Evals](#evals); costs money) |
| `harness init` · `gc [--all-merged] [--deps] [--dry-run]` | set up a project (adds the Vercel/Netlify deploy guard so run branches never deploy), clean up merged runs (their clean worktrees, run worktrees only (`harness/<run>`: a worktree on any other branch is a `keeps` line), clean counting untracked files whatever the config, ignored build output and all: `worktree remove --force`, then `rm -rf` only once git has let go of it (a locked one stays), a failure a `! could not remove <wt>: <why>` line and gc goes on; and the merged `harness/` and `harness-merge/` branches, local and on origin; `--all-merged`: every branch merged into `origin/main`, whatever its name, except `main`, the origin's default branch and a running run's; local deletes are `branch -d`, a refused one is a `! failed:` line and gc goes on; `--deps`: the `DEPS_DIRS`, default `node_modules .next .next-check .venv`, in the worktrees of ended runs, merged or not, never the project's checkout or a live or queued run's, each a `+ freed <n> MB in <wt>: <dirs>` line), stop the systemd units a killed driver left (`harness-<run>-*` of runs with no live driver) and kill the tmux sessions `h-<run>` of its ended runs (never `h-queue`, the desk, a live or paused run's) |

`harness continue` merges `main` into the run branch (the record) before any session, so a resumed run never works on
a stale base, and reopens each unfinished milestone on its lane branch `harness-lane/<run>/<m>`: the origin's when it
is ahead (a fix you pushed there by hand), both merged when the box's and the origin's diverged. A run from before
lanes, whose `harness/<run>` carries code `main` doesn't have, is refused (exit 1, plus a high-priority notification)
with three ways forward: `harness merge <run>` for its verified milestones; a new run with `--brief "finish <what is
left>; harness/<run> is the source"`; or finishing it by hand on that branch. A branch that holds only the record
continues as a lanes run. Under `MERGE_POLICY=pr`, a verified milestone whose dependency's PR still waits for you opens
its own PR from the dependency's tag and waits (`<m> verified; its PR waits for <dep> to merge`); `harness merge <run>`
then lands every proposed milestone, dependencies first, re-basing in a slot each whose `main` moved since its verify
(the same rule as in a run).

## What a project needs

| File | What | Required |
|---|---|---|
| `CLAUDE.md` | durable rules: code rules, how to verify, off-limits; a `## Where things go` block (what goes in which store: your entry, a decision file, a plan, `CLAUDE.md`) and `## Gotchas` (15 lines, edited in place, facts a fresh session would rediscover: a coding session adds or edits one line as it finishes, and `harness-log.md` notes `<feature>: gotchas +<a> ~<e> -<d>`); the harness appends its own routing block to the prompts only when `CLAUDE.md` lacks the `## Where things go` heading; `## Live system` for live projects. Claude Code loads it in every session; the harness prompt names it, it doesn't paste it | yes (template: `harness init`, or `harness init --draft` to have Claude draft it) |
| `.harness/config.sh` | `POLICY=build-only` or `POLICY=live-staged`, plus real overrides only; `DECISIONS=<path>` names the decisions store (a directory of one file each, or one file) when it isn't `docs/decisions.md` | recommended |
| `.mcp.json` | the MCP servers runs may use. Sessions run with `--strict-mcp-config`, so a committed `.mcp.json` (passed as `--mcp-config <worktree>/.mcp.json`) is what run worktrees load; without one they get none, whatever your user config holds | no |
| `.harness/check.sh` · `init.sh` · `smoke.mjs` | only if the conventions don't fit: a sandboxed suite, a dev server, a browser smoke test | no |
| `.harness/teardown.sh` (executable) | what stopping the run's services scope can't reach, e.g. `npx supabase stop` or `docker compose down` (containers live under `dockerd`): see below | no |

**Test counts.** A suite may print a line `HARNESS_TESTS=<n>` (a whole line from column 0, no colour or prefix; the
last one wins): the harness takes it over scraping
the runner's summary (node:test, cargo, jest, `go test -v`, then the last `N passed`), and `harness-log.md` says once
per run which it used: `test count: HARNESS_TESTS contract`, `parsed (<runner>)` or `no match`. The run's first count
is its baseline (`tests-start`); the latest tree's (`tests-end`) is refreshed after every session, so `harness status`,
`harness report` and each session's line in `harness-log.md` show it mid-run, and report.md's Tests cell reads
`<start> → <end> (baseline at run start → end)`.

**Memory lint.** `harness memlint <project>` prints what `lib/memlint.mjs` finds in a project's memory files, one
`<file>:<line> <check>: <text>` per line: `size` (`CLAUDE.md` over `MEMLINT_LINES`, 120), `gotchas` (over 15 lines),
`derivable-count` (a stored `<n> tests`), `night-scope` (`tonight`, `this run`, `as of <date>`) and `decisions` (no
store, no current-rule-set header, a superseded entry without an `Updated in place` line). Every run segment starts
with the same lint as `memlint: …` notes in `harness-log.md`; they never stop the run. Run `harness memlint
<project>` for each project to confirm chunk 3 Part 2's tidy held: on 2026-10-26 the projects with a `CLAUDE.md`
give two `size` findings (hit_list's, 181 lines; portfolio_site's, 127) and nothing else, agent-harness once the memory
run's tidy of its own `CLAUDE.md` and `DECISIONS=` is on main; a directory without a decisions store gives `decisions:
no store`.

Everything else is detected or defaulted: the suite (`npm run check`/`npm test`/pytest/…, run by `lib/check.sh` in
its own scope capped at 3G under a 15m timeout: `CHECK_MEMORY_MAX`, `CHECK_TIMEOUT`; cached per code tree, whose key
leaves out `CHECK_KEY_IGNORE`, default `.harness/runs docs/plans`, so a plan alone doesn't rerun it, and each verify
clears its tree's cached green so the suite runs in full on what it judges), smoke, init (run in the run's
services scope `harness-<run>-svc`, capped at 3G, under a 10m timeout; what it leaves running when it returns stays in the
scope until the run's services stop (below) or the next init stops it: `SVC_MEMORY_MAX`, `INIT_TIMEOUT`), port, models, limits
(a session waits up to 30m while the box has under 5 GB available, then starts anyway: `MEM_MIN_AVAILABLE_GB`,
`MEM_WAIT_MAX`). Run scope is never committed: it's `--spec` and `--brief` on `start`/`continue`.

**Scratch and cache.** Each run gets `HARNESS_SCRATCH` (`/tmp/harness/<project>/<run>`) for its outputs, sandboxes,
logs and screenshots; a run that finishes deletes it (`KEEP_SCRATCH=1` keeps it), after copying `init.out`,
`teardown.out` and the last suite output (`check-last.out`) into its state dir. Installs that should outlive a run
and a reboot go under `HARNESS_CACHE` (`~/.cache/harness/<project>`, never deleted): put Playwright browsers there
(`PLAYWRIGHT_BROWSERS_PATH=$HARNESS_CACHE/ms-playwright` in the init) and anything similar, not in scratch.

**Teardown.** When a run ends (a `status: stop` included), when its driver is killed (a TERM, or an error that ends
it), when it pauses, before a usage-limit wait of more than `SVC_IDLE_STOP_MIN` minutes (10) and before a memory wait,
the harness stops the run's services (the next session's init starts them again): it runs the project's `.harness/teardown.sh` if that file is executable then (or `TEARDOWN_CMD`), in the
worktree under `timeout 2m` (KILL 10 s later) with `HARNESS_PORT`, `HARNESS_SCRATCH`, `HARNESS_RUN_ID` and `HARNESS_TEARDOWN_WHY` set,
then stops `harness-<run>-svc`, and notes `services stopped (<why>)` in `harness-log.md`. The scope stop alone takes
everything the init started itself; a project whose init starts containers (Supabase, `docker compose`) adds its own
hook to stop them (template: `templates/project/teardown.sh`). It runs only when the segment ran an init, its output
goes to `teardown.out` in the scratch directory, and a failing hook is noted, never fatal. A TERM during an init stops
the init first; a TERM during a teardown waits for it rather than starting a second. A SIGKILLed driver runs no
hook: `harness gc <project>` stops the units it left (run the teardown by hand for its containers:
`HARNESS_RUN_ID=<run> .harness/teardown.sh` in the worktree).

## What a run is

| | Where |
|---|---|
| Worktree, branch | `~/worktrees/<project>/<run-id>` on `harness/<run-id>` (from `origin/main`): the run record only, written by the driver alone. Code goes on a lane branch per milestone, `harness-lane/<run-id>/<m>` |
| Lanes | each milestone runs as a lane: its own process (`lib/lane.sh`), its features in order, then its verify and merge, in a slot worktree `~/worktrees/<project>/lanes/<run-id>/slot-<k>` with its own port and scratch. `MAX_LANES` (default 1: one milestone after another) caps the lanes open at once; a second lane opens only with headroom: `MemAvailable` at least `MEM_MIN_AVAILABLE_GB` + `LANE_RESERVE_GB` (4) per open lane, and the newest session's five-hour window (`USAGE_5H`) under `LANE_OPEN_BELOW_5H` (70 %) until it resets, else `lane <m> waiting: <reason>` once per reason and a retry every poll (decisions/2026-10-26-parallel-runs-headroom). Slot 0's lane uses the run's port, a lane in slot 1 and up the first free one from `BASE_PORT`; a slot is reused by the next lane (`checkout -B`), so its ignored install and build directories carry over, and `finish` removes every slot. A merged milestone's lane branch is deleted when its PR merges (under `pr`, once `harness gc` sees it merged); an unverified one stays. `harness gc <project>` removes the slots a killed driver left once no lane process of the run lives, and stops their lane units. When another lane's merge moved `main` under a verified milestone, its lane re-bases
it: `main` merged into the verified commit; files disjoint from the milestone's (`LANE_REBASE=suite`, the default)
run the suite in full on the merged tree and, green, move the tag there (`<m> re-based on main <sha>: <n> files,
disjoint, suite green; re-tagged`); overlapping files, or `LANE_REBASE=verify`, get one verify round
(`MAX_REBASE_ROUNDS`, 1) first; a red suite, a conflict or the rounds used need you
(decisions/2026-10-26-lane-rebase-disjoint). `harness-log.md` says `lane <m> opened (slot <k>, port <n>, from <sha>)` and `lane <m> closed (<reason>)`, the reason by the lane's exit code: 0 `<m> merged` · `proposed` · `verified; its PR waits` · `verified; its re-base waits` (done) · 10 `given up <ids>` · 11 `parked <ids>` · 12 `<m> needs Michael: <why>` (verify, merge, a conflict, its slot, or `lane exited unexpectedly`) · 13 `session cap`, `usage limit`, `weekly budget` (ends the run) · 14 `stopped` · 15 `deadline` · 16 `the run is ending (<why>)` (another lane ended it) |
| Run record (committed) | `.harness/runs/<run-id>/`: `feature_list.json` · `entries.jsonl` (the journal: one entry per session; sessions write `entry.json`, only the driver appends, and a session's edit to it is undone) · `progress.md` (rendered from it for the phone; 15 in full) · `progress-archive.md` (every entry) · `INBOX.md` · `brief.md` · `harness-log.md` · `metrics.jsonl` · `summary.json` · `report.md` · `retro.md` · `retro-proposals.json` |
| Reviews | sized to the milestone: one or two build features fold the review into the last one's steps (an Opus subagent reads the diff); three or more keep one review feature, which the driver runs on Sonnet under `REVIEW_OPUS_LINES` (400) changed lines of what the lane's branch has and main doesn't (main fetched first) and on Opus at or over; a Sonnet review whose entry summary reports `<n> Critical, <n> Important` above 0 gets one more round on Opus, at no attempt, and any later attempt stays on Opus (decisions/2026-10-27-review-gate). The lint flags `review-small` and `review-missing` |
| Merges | per verified milestone: tag `run/<run-id>/<m>`, PR from `harness-merge/<run-id>-<m>`, left for you to merge (`MERGE_POLICY=pr`, the default; `auto` lets the driver self-merge — Michael's user config sets it, and a project whose `main` deploys sets `pr` back; `off`) When the run ends, its record (`.harness/runs/<run-id>/`) reaches main through one PR of its own, `<run-id>: run record` from `harness/<run-id>`: merged under `auto`, left for you under `pr`, none with `RECORD_PR=off`; `finish` deletes nothing, and the queue's end-of-queue `harness gc` deletes the record branch and its worktree once its record PR is no longer open (the ledger keeps the record) |
| Local state | `~/.local/state/harness/<project>/<run-id>/`: `run.log`, transcripts, attempts, `driver.pid`, `ended` |
| Ledger | `ledger/runs.jsonl` and `ledger/<project>/<run-id>/` in this repo · `harness trends` |
| Memory | each session in the transient user scope `harness-<run-id>-s<n>` (throttled at 5G, killed at 6G, 1G swap: `SESSION_MEMORY_HIGH`, `SESSION_MEMORY_MAX`, `SESSION_SWAP_MAX`), each suite in `harness-<run-id>-check-<pid>`; stopped when they return, so nothing a session started outlives it. Peaks go in `metrics.jsonl` (`mem_peak_mb`) and `report.md` (over 2 GB). No user systemd: uncapped, with a note |

### After the run (box settings, yours)

- With the scopes in, `systemd-oomd` can kill the offending `harness-*` scope instead of the desktop: enabling it with
  `ManagedOOMMemoryPressure=kill` on the user slice is a box setting, your call (`findings-and-research/2026-10-24-system-resource-audit.md` §3C.2).
- `systemctl --user list-units 'harness-*'` shows what each run holds right now (nothing when no run is alive).
- **Two lanes:** set `MAX_LANES=2` in `~/.config/harness/config.sh` before the next run starts (the code's default
  stays 1; the driver reads the config at run start). The morning after: `grep -c "lane .* waiting"
  <run dir>/harness-log.md` (how often admission held a lane back), `jq .lanes <run dir>/summary.json` (`max_open`,
  `lane_hours`, `wall_hours`), `mem_peak_mb` in `metrics.jsonl`, no OOM lines in `journalctl --user -b`, and
  `systemctl --user list-units 'harness-*'` empty. Under `MERGE_POLICY=pr` the record PR (`<run>: run record`) is
  yours to merge too. `MAX_PARALLEL_RUNS=2` only after a night at two lanes shows the headroom
  (decisions/2026-10-26-parallel-runs-headroom).
- A crashed or stopped run leaves its scratch in `/tmp/harness`. The optional age rule removes it after 3 days
  untouched (never `live.lock`); the user tmpfiles timer it needs is off by default, so the one command enables it:
  `mkdir -p ~/.config/user-tmpfiles.d && cp templates/user/harness-tmpfiles.conf ~/.config/user-tmpfiles.d/harness.conf && systemd-tmpfiles --user --create && systemctl --user enable --now systemd-tmpfiles-clean.timer`

## Steering

- **Phone:** `progress.md` is rendered from the journal (`entries.jsonl`) after every session and is still the phone view; sessions write `entry.json`, the driver appends it. Steer by editing `.harness/runs/<run>/INBOX.md` on the run branch in the GitHub app: first line `status: pause` or
  `status: stop`, optionally with why (`status: stop the spec changed`); answers under `## Answers`. The driver pulls before every session.
- **Why a stop:** either reason ends up in harness-log.md, `ended`, summary.json's `end_reason` and the retro prompt as
  `stopped by Michael: <why>` (the `--why` one wins when both are set); without one, `stopped by Michael` as before.
  `harness continue` (or a queued request) of a run stopped from the phone sets its `status: stop` line back to
  `status: run`, so the continuation doesn't stop again at once.
- **Box:** `harness pause|resume|stop|answer <run>` (`harness stop <run> --why "<text>"` records why), `harness attach <run>` (tmux: driver · log · supervisor). When the driver exits, the
  supervisor window closes, the driver window's scrollback goes to `<state>/tmux-driver.txt` (its last 2000 lines, tmux's `history-limit`;
  `run.log` beside it has everything), and the session `h-<run>`
  closes after `TMUX_KEEP_HOURS` (24; `0` = at once), or sooner: `harness gc <project>` and the queue runner, as it
  exits, kill the sessions of ended runs.
- **What a session reads:** `context.md` first (a bounded pack the driver writes before each coding and verify session: your answers, the feature's earlier dead ends and open questions (a later entry's `resolved` drops one), facts to promote into `## Gotchas` (until a line there or a later `resolved` carries them), recent entries, and last the decisions store's current rules, newest first; a verify's pack is larger, `CONTEXT_PACK_BYTES_VERIFY`, its failed rows first); the `--brief` (and `--spec` paths) go into every session's prompt; `CLAUDE.md` is loaded by
  Claude Code itself (the prompt names it in one line, it doesn't paste it), so a rule edited on the run branch reaches
  the next session. Each session's prompt is kept beside its transcript (`logs/*.prompt.md`).
- **Notifications:** start, merges, needs-Michael, parks, limits, end. In `~/.config/harness/config.sh` either
  - `NTFY_URL` (an ntfy topic URL, e.g. a private ntfy.sh topic) and optionally `NTFY_TOKEN` (sent as
    `Authorization: Bearer`, never logged): the harness posts itself, with a title, priority high where you must
    act, a click URL (INBOX.md, progress.md, report.md on the run branch on GitHub, or the PR) and view actions.
    **`NTFY_URL` wins: `NOTIFY_CMD` is then not called.**
  - or `NOTIFY_CMD`: it gets the one-line message as `$1` as always, plus `HARNESS_NOTIFY_TITLE`,
    `HARNESS_NOTIFY_BODY`, `HARNESS_NOTIFY_CLICK`, `HARNESS_NOTIFY_ACTIONS` (ntfy's `view, <label>, <url>; …`) and
    `HARNESS_NOTIFY_PRIORITY` (`high` or empty) in its environment.

  A park's notification carries the question the session wrote in INBOX.md (body capped at 3500 bytes), the
  `harness answer` command, and Edit INBOX / Progress actions; `DESK_URL` (e.g. a Claude Code environment URL; no `,` or
  `;` in it, they split ntfy's Actions header) adds **Answer with Claude**. A non-GitHub origin sends the same without URLs.
- **Permissions:** the policy (agents merge, push and clean up; only the irreversible is denied; production is gated
  per project) lives in `~/.claude/CLAUDE.md` § "Git, merges and permissions" and the user settings. Install or
  refresh both from `templates/user/` with `bash setup/apply-2026-10-24.sh --dry-run`, then without `--dry-run`.
- **Answering from the phone:** install the skill once, `ln -s ~/projects/agent-harness/skills/harness-answer ~/.claude/skills/`.
  Ask a Claude session "answer the harness": it runs `harness needs`, checks what it safely can (variable names, never
  values), proposes, and runs `harness answer` only after your yes. Set `DESK_URL` (above) to get **Answer with Claude**
  on a park's notification; `templates/user/config.sh` documents every user setting.
- **The desk:** with `DESK=1` in `~/.config/harness/config.sh` (off by default) the harness starts the session for you
  whenever a run needs you (a park, a blocked or waiting end, verify or a merge needing you, a debrief with something
  under Needs Michael): a Remote Control `claude` in tmux session `h-desk`, one window per run, on `DESK_MODEL` (opus).
  On the phone you get a second notification, `[<run>] needs you: <why>`; tapping it opens that session in the Claude
  app, already briefed: it has read `harness needs`, the INBOX and the progress log and sends one numbered brief. Answer
  there; it runs `harness answer` and the continue only after your yes. A later event for the same run is typed into the
  same session. By hand: `harness desk <run> [--why "…"]`, `harness desk --debrief`; `harness desk --list` (window, run,
  URL, age), `harness desk --close <run>|--all`; `harness gc <project>` closes desks idle for 24 h (and keeps the
  worktree of a run whose desk is open). A desk showing a dialog gets nothing typed in: answer it first. A desk that can't
  start (no tmux, no URL within a minute) is a line in `harness-log.md` and the plain notification; it never changes
  the run. Turning it on in stages: `docs/plans/2026-10-19-P3-desk.md`, "For Michael: turning it on".
- **After a partial run:** nothing, usually: verified milestones are already merged and a continuation is queued.
  A run that hits its deadline first gives each complete, unverified milestone one verify session, so finished work
  merges that night (not when you stopped it or a usage-limit window holds: the continuation verifies it); one that
  fails it needs Michael.
  "Blocked" or "needs Michael" runs: answer, then `harness continue <run> [--brief …]`.
- **Waiting on you:** a session that needs something only you can give (a secret, a sudo step) asks in INBOX.md and
  ends `PARKED: …`. A question written inside the steering comment (GitHub hides it) is moved below it, with a note. Every question
  (in INBOX.md or an entry's `questions`) names the files to open on a `Files:` line; one without it gets the files the
  session changed, filled in by the harness (`Files (harness, from the session): …`, noted). The feature waits without spending attempts while independent work goes on; the run ends
  `waiting on Michael: <ids>` when nothing else can run. Any new answer unparks it on `harness continue`. The park's
  notification carries the question, what waits on it, where and the commands; tapping it opens `needs.md` in the
  run record, every open item there as a card. A milestone that needs you (thin, red or failed verify, a conflict with
  main, a refused merge, a lane base that won't merge) notifies the same way, its card as the body; main conflicting
  with a lane is said once per main commit, and resolves itself once main merges cleanly. A card's commands fix a
  branch in a worktree of their own (never the run's slot or record worktree) and push it. After a merge conflict,
  `harness merge <run>` takes the branch with main merged in as the milestone's tip. `harness needs done` refuses a
  park: it resolves when you answer and continue.
- **Weekly budget:** past `WEEKLY_STOP_AT` (default 85 %) of the plan's 7-day window, as sessions report it, the queue
  starts no run and a running one stops before its next coding session.

## Retro backlog

Every retro proposal across runs, deduplicated by id, with a status: `ledger/retro-backlog.jsonl`, one JSON row each
(`id`, `title`, `first_seen`, `runs_seen`, `status`, `spec`, `pr`, `note`). Only the harness writes it: the driver and
`harness backlog`, never a session. Each retro writes its proposals (at most three, `{id, title, evidence}`) to the
run's `retro-proposals.json`; at the run's end the driver merges them in, under the ledger lock and in the ledger
commit: a new id is a `proposed` row, a known id gains the run in `runs_seen`, and a malformed file is noted in
harness-log.md (`backlog: retro-proposals.json invalid: …`) and skipped whole. Mark what became work with `harness backlog set <id> specced --spec <path>` (or
`queued`, `merged --pr <url>`, `dropped --note "<why>"`); `harness backlog` lists it, open proposals first. Each retro
is shown that list, so it reuses an id and cites a specced or queued item's status instead of re-arguing it; the
debrief reads it to rank the open proposals.

**Seed it once, by hand, on the live checkout** (the build that added the backlog never ran this; it writes the real
ledger): `harness backlog import docs/specs/2026-10-25-memory.backlog-seed.jsonl`. It prints `backlog: imported 8
rows (8 new, 0 updated)`, makes one `ledger: backlog import …` commit, and is idempotent by id: a second import never moves a row back to an
earlier status nor clears a link `set` gave it. To look first:
`node lib/backlog.mjs list docs/specs/2026-10-25-memory.backlog-seed.jsonl` (writes nothing); to undo, `git revert`
that commit.

## Debrief

After a queue, `harness debrief` replaces the "morning session". The queue runner starts it, detached, as it exits
(queue empty, past `--until`, or `harness queue stop`), if it started a run; run it by hand any time. It covers every
run whose driver started since the last debrief that produced a note, so a debrief that was refused, failed or killed
is caught up by the next one. Bash gathers the context (status, trends, the queue, the runner's log, and per run: end
reason, summary, report, retro, INBOX.md, open questions, the usage-limit window; and the retro backlog), then one Sonnet session writes the
note: a headline (what landed on main, what's blocked, spend against the usage window), 3–6 lines per run, **Needs
Michael**, draft answers the project's docs support (it never writes to INBOX.md), and **For the next interactive
session** (merge conflicts, the retro backlog's open `proposed` items most seen first, and items re-raised though
already `specced` or `queued`). It can ask for a continuation of a run that
ran out of time or hit the usage limit (`CONTINUE: <run> :: <brief>`); the harness checks it and queues it with
`--automatic --keep-attempts` (an automatic continuation: skipped if you stop the run first); nothing starts.

- **The page**: `ledger/debrief.html` beside the note: a card per run (passing, verified, merged, milestones,
  spend, tests, what isn't done and why), built by `lib/page.mjs` from each run's `summary.json`, not by the model,
  then the note. `DEBRIEF_PAGE_CMD` (user config) gets its path, e.g. to copy it where your phone can open it.
- **The note** is one file, `ledger/debrief.md`, overwritten each time and committed with the ledger (`LEDGER_COMMIT`),
  only while the harness checkout is on `main` with no rebase or merge going: the archive is
  `git log -p ledger/debrief.md`. The notification (title `harness debrief`; high when the note's Needs Michael
  isn't empty) carries its three-line headline and the path, or one line if it failed.
- **Read-only**: the session runs in `dontAsk` mode with an allowlist of read-only tools (one commented array in
  `lib/debrief.sh`, where the scope can be widened) plus the never-list as `--disallowedTools`; anything that still
  changes in the ledger, run worktrees or projects while it runs is flagged in the note. See `docs/architecture.md` §16.
- **Cost.** One Sonnet session per queue (`DEBRIEF_MODEL`), at most 40 turns and $3 like the retro; the context is
  capped at a few tens of KB, so a typical debrief is well under $1. Nothing to cover: no session, $0. A closed
  usage-limit window is waited out up to 5 h; past that, the next debrief (or yours, by hand) covers these runs.
- `harness debrief --dry-run` prints the gathered context and launches nothing.

## Evals

A **task** is 1–3 features copied from a real past run, with the commit they started from (`evals/tasks/<id>/task.json`);
`evals/sets/default.txt` lists the ones `--set default` runs (5 tasks, all agent-harness so far; the categories
still to add are in `evals/README.md`). Two harness versions run the same tasks and are compared.

```bash
harness eval run [--set default] [--harness <ref>] [--label <L>] [--repeat <N>]   # replay on throwaway clones; nothing posted or merged
harness eval compare <A> <B>       # pass rate, $ and tokens per verified feature, cache, orientation, context peak, wall time, rework; B's verdict against A
harness eval probes <task result>  # one tool-less Haiku turn answers the handoff questions; prints score <n>/<m>
```

Results go to `evals/results/<stamp>-<sha>-<label>/` (git-ignored). The ref's worktree lives in
`/tmp/harness-eval/<stamp>/harness` and is removed at the end. The throwaway clones (each sealed at its base: no tag
or later commit of the source) and the runs' worktrees stay beside it for `eval probes`; `rm -rf
/tmp/harness-eval/<stamp>` once you're done with them. **Evals are real sessions and cost money** (about $28 per
eval of the default set); they are Michael's to run, the overnight run never does. The commands, in order, with the
cost: `evals/NEXT.md`; its `## 5. M6: the review gate` compares the harness before the review gate (tag `…/M5`) with M6
(`summary.json`'s `review.cost_pct` and `review.found_nothing` say what the reviews cost and how many found nothing
Critical or Important in any round).

## Tests

```bash
tests/run.sh          # end-to-end with stub claude/gh/curl on a throwaway repo with a bare origin: 395 checks (~3 min 30 s)
tests/run.sh gc       # only the tests/checks/ files whose names contain "gc"
TEST_JOBS=1 tests/run.sh   # one file at a time (default: half the cores, 1 to 4)
```
Each `tests/checks/*.sh` sources `tests/lib.sh` (a fresh `$T`, private tmux server, stub environment and throwaway
project) and runs alone; `tests/fixtures/check-names.txt` lists every check name and a full run fails on one missing,
new or doubled. The runner starts the files `TEST_JOBS` at a time, largest first, as plain background jobs inside the
caller's check scope, prints each file's output whole when it finishes with a `<file>: <n> checks, <s> s` line, and
ends with the slowest three, the wall time and the total. A file that exits non-zero with no `FAIL` line counts as one
failed check; stopped by a signal (check.sh's timeout), the runner prints each unfinished file's output so far and names it.
A file still running after `TEST_FILE_TIMEOUT` (10m) is stopped, its process group with it, and counted as one
`FAIL <file>: still running after TEST_FILE_TIMEOUT=<t>; stopped`.
The stubs replay real CLI output where it matters (`tests/fixtures/usage-limit.jsonl`, captured 2026-10-17).
