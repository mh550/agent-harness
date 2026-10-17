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
- **Notifications:** `NOTIFY_CMD` in `~/.config/harness/config.sh` (e.g. a private ntfy.sh topic): start, merges,
  needs-Michael, limits, end.
- **After a partial run:** nothing, usually: verified milestones are already merged and a continuation is queued.
  "Blocked" or "needs Michael" runs: answer, then `harness continue <run> [--brief …]`.

## Tests

```bash
tests/run.sh    # end-to-end with stub claude/gh on a throwaway repo with a bare origin: 47 checks (~3 min)
```
The stubs replay real CLI output where it matters (`tests/fixtures/usage-limit.jsonl`, captured 2026-10-17).
