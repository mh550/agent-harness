# agent-harness

A small, reusable harness for **long-running coding agents**, after Anthropic's
["Effective harnesses for long-running agents"](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents).
An initializer session turns a spec into a feature list; then **one fresh Claude Code session per feature** does the
work, test-first. A deterministic bash driver does the bookkeeping around them: it verifies each finished milestone
independently, **merges verified milestones into `main` through their own PRs**, waits out usage limits, and records
every run in a ledger that the next runs learn from.

Zero dependencies beyond `bash`, `git` (≥ 2.38), `node`, `jq`, `tmux`, `flock`, `claude` and `gh`.
**How it works, in depth: [`docs/architecture.md`](docs/architecture.md).** Why it is the way it is: [`journal/`](journal/README.md).

## Quick start

```bash
ln -s ~/projects/agent-harness/bin/harness ~/.local/bin/harness     # once
harness init ~/projects/myapp            # CLAUDE.md template + .harness/config.sh (POLICY=build-only); prints what it detected
# fill in CLAUDE.md, commit to main, then:
harness start ~/projects/myapp --spec docs/todo.md --brief "items 1–3 only"
harness status                           # every run: running / ended (why), features, last log lines
harness report                           # the writeup: passing, tests, spend total / per feature / by role, causes
```

Queue a night's work at once (runs go one after another by default; `MAX_PARALLEL_RUNS` in your config):

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
| `harness status` · `report` · `trends` · `attach` | look |
| `harness parked [<run>] [--json]` | what each parked feature waits on: the question, since when, the commands to answer (read-only) |
| `harness debrief [--dry-run]` | the triage note for every run since the last one (`--dry-run`: print the gathered context only) |
| `harness init` · `gc` | set up a project, clean up merged runs |

## What a project needs

| File | What | Required |
|---|---|---|
| `CLAUDE.md` | durable rules: code rules, how to verify, where decisions live, off-limits; `## Live system` for live projects | yes (template: `harness init`, or `harness init --draft` to have Claude draft it) |
| `.harness/config.sh` | `POLICY=build-only` or `POLICY=live-staged`, plus real overrides only | recommended |
| `.harness/check.sh` · `init.sh` · `smoke.mjs` | only if the conventions don't fit: a sandboxed suite, a dev server, a browser smoke test | no |

Everything else is detected or defaulted: the suite (`npm run check`/`npm test`/pytest/…), smoke, init, port,
models, limits. Run scope is never committed: it's `--spec` and `--brief` on `start`/`continue`.

## What a run is

| | Where |
|---|---|
| Worktree, branch | `~/worktrees/<project>/<run-id>`, `harness/<run-id>` from `origin/main` |
| Run record (committed) | `.harness/runs/<run-id>/`: `feature_list.json` · `progress.md` · `INBOX.md` · `brief.md` · `harness-log.md` · `metrics.jsonl` · `summary.json` · `report.md` · `retro.md` |
| Merges | per verified milestone: tag `run/<run-id>/<m>`, PR from `harness-merge/<run-id>-<m>`, merged by the driver (`MERGE_POLICY=auto`; `pr` leaves it to you; `off`) |
| Local state | `~/.local/state/harness/<project>/<run-id>/`: `run.log`, transcripts, attempts, `driver.pid`, `ended` |
| Ledger | `ledger/runs.jsonl` and `ledger/<project>/<run-id>/` in this repo · `harness trends` |

## Steering

- **Phone:** edit `.harness/runs/<run>/INBOX.md` on the run branch in the GitHub app: first line `status: pause` or
  `status: stop`; answers under `## Answers`. The driver pulls before every session.
- **Box:** `harness pause|resume|stop|answer <run>`, `harness attach <run>` (tmux: driver · log · supervisor).
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
- **Answering from the phone:** install the skill once, `ln -s ~/projects/agent-harness/skills/harness-answer ~/.claude/skills/`.
  Ask a Claude session "answer the harness": it runs `harness parked`, checks what it safely can (variable names, never
  values), proposes, and runs `harness answer` only after your yes. Set `DESK_URL` (above) to get **Answer with Claude**
  on a park's notification; `templates/user/config.sh` documents every user setting.
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

## Tests

```bash
tests/run.sh    # end-to-end with stub claude/gh/curl on a throwaway repo with a bare origin: 125 checks (~3 min)
```
The stubs replay real CLI output where it matters (`tests/fixtures/usage-limit.jsonl`, captured 2026-10-17).
