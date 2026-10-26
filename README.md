# agent-harness

A small, reusable harness for **long-running coding agents**, after Anthropic's
["Effective harnesses for long-running agents"](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents).
An initializer session turns a spec into a feature list; then **one fresh Claude Code session per feature** does the
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
harness status                           # every run: running / ended (why), features, last log lines
harness report                           # the writeup: passing, tests, spend total / per feature / by role, causes, memory peaks over 2 GB
```

Queue a night's work at once (runs go one after another by default; `MAX_PARALLEL_RUNS` in your config; the queue
never runs two runs of one project at once, so a second entry for a busy repo waits while later ones go ahead):

```bash
harness queue add ~/projects/pathways --spec OVERNIGHT.md --brief "T5, T7, then T6"
harness queue add ~/projects/hit_list --spec docs/next.md
harness queue add --continue dj-2026-10-17
harness queue start --until 07:30        # tmux h-queue; no run starts after 07:30, and each one stops by then
```

When the runner exits (queue empty, past `--until`, or `harness queue stop`) and it started at least one run, it runs
**`harness debrief`**, detached: one short read-only Sonnet session that reads what happened and overwrites
`ledger/debrief.md`. The notification (ntfy or `NOTIFY_CMD`) carries its three-line headline and the note's path (see [Debrief](#debrief)).

| Command | What |
|---|---|
| `harness start` · `continue` · `merge` · `stop` · `pause` · `resume` · `answer` | one run |
| `harness queue [list]` · `queue add` · `queue start [--until]` · `queue stop` · `rm` · `clear` | the night's queue |
| `harness queue park <n> [<why>]` · `queue unpark <n>` | set an entry aside: `queue list` shows it with its reason, the runner skips it; unpark puts it back at the end |
| `harness sync` | the live harness checkout level with origin (merged PRs in, ledger commits pushed); the queue runner does this itself whenever no run is alive (`LIVE_SYNC=0` turns it off) |
| `harness status` · `report` · `trends [--by version]` · `attach` | look (`status`: under a running run, each of its systemd units with its `MemoryCurrent`; `trends --by version`: runs grouped by harness version, medians of cost, cache hit, orientation) |
| `harness parked [<run>] [--json]` | what each parked feature waits on: the question, since when, the commands to answer (read-only) |
| `harness debrief [--dry-run]` | the triage note for every run since the last one (`--dry-run`: print the gathered context only) |
| `harness eval run` · `compare` · `probes` | replay a fixed task set under a harness version and compare two results (see [Evals](#evals); costs money) |
| `harness init` · `gc [--dry-run]` | set up a project (adds the Vercel/Netlify deploy guard so run branches never deploy), clean up merged runs, stop the systemd units a killed driver left (`harness-<run>-*` of runs with no live driver) and kill the tmux sessions `h-<run>` of its ended runs (never `h-queue`, the desk, a live or paused run's) |

`harness continue` merges `main` into the run branch before any session, so a resumed run never works on a stale base.

## What a project needs

| File | What | Required |
|---|---|---|
| `CLAUDE.md` | durable rules: code rules, how to verify, where decisions live, off-limits; `## Live system` for live projects. Claude Code loads it in every session; the harness prompt names it, it doesn't paste it | yes (template: `harness init`, or `harness init --draft` to have Claude draft it) |
| `.harness/config.sh` | `POLICY=build-only` or `POLICY=live-staged`, plus real overrides only | recommended |
| `.mcp.json` | the MCP servers runs may use. Sessions run with `--strict-mcp-config`, so a committed `.mcp.json` (passed as `--mcp-config <worktree>/.mcp.json`) is what run worktrees load; without one they get none, whatever your user config holds | no |
| `.harness/check.sh` · `init.sh` · `smoke.mjs` | only if the conventions don't fit: a sandboxed suite, a dev server, a browser smoke test | no |
| `.harness/teardown.sh` (executable) | what stopping the run's services scope can't reach, e.g. `npx supabase stop` or `docker compose down` (containers live under `dockerd`): see below | no |

Everything else is detected or defaulted: the suite (`npm run check`/`npm test`/pytest/…, run by `lib/check.sh` in
its own scope capped at 3G under a 15m timeout: `CHECK_MEMORY_MAX`, `CHECK_TIMEOUT`), smoke, init (run in the run's
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
| Worktree, branch | `~/worktrees/<project>/<run-id>`, `harness/<run-id>` from `origin/main` |
| Run record (committed) | `.harness/runs/<run-id>/`: `feature_list.json` · `entries.jsonl` (the journal: one entry per session; sessions write `entry.json`, only the driver appends, and a session's edit to it is undone) · `progress.md` (rendered from it for the phone; 15 in full) · `progress-archive.md` (every entry) · `INBOX.md` · `brief.md` · `harness-log.md` · `metrics.jsonl` · `summary.json` · `report.md` · `retro.md` |
| Merges | per verified milestone: tag `run/<run-id>/<m>`, PR from `harness-merge/<run-id>-<m>`, left for you to merge (`MERGE_POLICY=pr`, the default; `auto` lets the driver self-merge — Michael's user config sets it, and a project whose `main` deploys sets `pr` back; `off`) |
| Local state | `~/.local/state/harness/<project>/<run-id>/`: `run.log`, transcripts, attempts, `driver.pid`, `ended` |
| Ledger | `ledger/runs.jsonl` and `ledger/<project>/<run-id>/` in this repo · `harness trends` |
| Memory | each session in the transient user scope `harness-<run-id>-s<n>` (throttled at 5G, killed at 6G, 1G swap: `SESSION_MEMORY_HIGH`, `SESSION_MEMORY_MAX`, `SESSION_SWAP_MAX`), each suite in `harness-<run-id>-check-<pid>`; stopped when they return, so nothing a session started outlives it. Peaks go in `metrics.jsonl` (`mem_peak_mb`) and `report.md` (over 2 GB). No user systemd: uncapped, with a note |

### After the run (box settings, yours)

- With the scopes in, `systemd-oomd` can kill the offending `harness-*` scope instead of the desktop: enabling it with
  `ManagedOOMMemoryPressure=kill` on the user slice is a box setting, your call (`findings-and-research/2026-10-24-system-resource-audit.md` §3C.2).
- `systemctl --user list-units 'harness-*'` shows what each run holds right now (nothing when no run is alive).
- A crashed or stopped run leaves its scratch in `/tmp/harness`. The optional age rule removes it after 3 days
  untouched (never `live.lock`); the user tmpfiles timer it needs is off by default, so the one command enables it:
  `mkdir -p ~/.config/user-tmpfiles.d && cp templates/user/harness-tmpfiles.conf ~/.config/user-tmpfiles.d/harness.conf && systemd-tmpfiles --user --create && systemctl --user enable --now systemd-tmpfiles-clean.timer`

## Steering

- **Phone:** `progress.md` is rendered from the journal (`entries.jsonl`) after every session and is still the phone view; sessions write `entry.json`, the driver appends it. Steer by editing `.harness/runs/<run>/INBOX.md` on the run branch in the GitHub app: first line `status: pause` or
  `status: stop`; answers under `## Answers`. The driver pulls before every session.
- **Box:** `harness pause|resume|stop|answer <run>`, `harness attach <run>` (tmux: driver · log · supervisor). When the driver exits, the
  supervisor window closes, the driver window's scrollback goes to `<state>/tmux-driver.txt` (its last 2000 lines, tmux's `history-limit`;
  `run.log` beside it has everything), and the session `h-<run>`
  closes after `TMUX_KEEP_HOURS` (24; `0` = at once), or sooner: `harness gc <project>` and the queue runner, as it
  exits, kill the sessions of ended runs.
- **What a session reads:** `context.md` first (a bounded pack the driver writes before each coding and verify session: your answers, the feature's earlier dead ends, recent entries); the `--brief` (and `--spec` paths) go into every session's prompt; `CLAUDE.md` is loaded by
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
  Ask a Claude session "answer the harness": it runs `harness parked`, checks what it safely can (variable names, never
  values), proposes, and runs `harness answer` only after your yes. Set `DESK_URL` (above) to get **Answer with Claude**
  on a park's notification; `templates/user/config.sh` documents every user setting.
- **The desk:** with `DESK=1` in `~/.config/harness/config.sh` (off by default) the harness starts the session for you
  whenever a run needs you (a park, a blocked or waiting end, verify or a merge needing you, a debrief with something
  under Needs Michael): a Remote Control `claude` in tmux session `h-desk`, one window per run, on `DESK_MODEL` (opus).
  On the phone you get a second notification, `[<run>] needs you: <why>`; tapping it opens that session in the Claude
  app, already briefed: it has read `harness parked`, the INBOX and the progress log and sends one numbered brief. Answer
  there; it runs `harness answer` and the continue only after your yes. A later event for the same run is typed into the
  same session. By hand: `harness desk <run> [--why "…"]`, `harness desk --debrief`; `harness desk --list` (window, run,
  URL, age), `harness desk --close <run>|--all`; `harness gc <project>` closes desks idle for 24 h (and keeps the
  worktree of a run whose desk is open). A desk showing a dialog gets nothing typed in: answer it first. A desk that can't
  start (no tmux, no URL within a minute) is a line in `harness-log.md` and the plain notification; it never changes
  the run. Turning it on in stages: `docs/plans/2026-10-19-P3-desk.md`, "For Michael: turning it on".
- **After a partial run:** nothing, usually: verified milestones are already merged and a continuation is queued.
  "Blocked" or "needs Michael" runs: answer, then `harness continue <run> [--brief …]`.
- **Waiting on you:** a session that needs something only you can give (a secret, a sudo step) asks in INBOX.md and
  ends `PARKED: …`. The feature waits without spending attempts while independent work goes on; the run ends
  `waiting on Michael: <ids>` when nothing else can run. Any new answer unparks it on `harness continue`.
- **Weekly budget:** past `WEEKLY_STOP_AT` (default 85 %) of the plan's 7-day window, as sessions report it, the queue
  starts no run and a running one stops before its next coding session.

## Debrief

After a queue, `harness debrief` replaces the "morning session". The queue runner starts it, detached, as it exits
(queue empty, past `--until`, or `harness queue stop`), if it started a run; run it by hand any time. It covers every
run whose driver started since the last debrief that produced a note, so a debrief that was refused, failed or killed
is caught up by the next one. Bash gathers the context (status, trends, the queue, the runner's log, and per run: end
reason, summary, report, retro, INBOX.md, open questions, the usage-limit window), then one Sonnet session writes the
note: a headline (what landed on main, what's blocked, spend against the usage window), 3–6 lines per run, **Needs
Michael**, draft answers the project's docs support (it never writes to INBOX.md), and **For the next interactive
session** (merge conflicts, retro proposals seen in two or more retros). It can ask for a continuation of a run that
ran out of time or hit the usage limit (`CONTINUE: <run> :: <brief>`); the harness checks it and queues it with
`--keep-attempts`; nothing starts.

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
cost: `evals/NEXT.md`.

## Tests

```bash
tests/run.sh    # end-to-end with stub claude/gh/curl on a throwaway repo with a bare origin: 168 checks (~4 min)
```
The stubs replay real CLI output where it matters (`tests/fixtures/usage-limit.jsonl`, captured 2026-10-17).
