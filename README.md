# agent-harness

A small, reusable harness for **long-running coding agents**, after Anthropic's
["Effective harnesses for long-running agents"](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents).
An initializer session turns a spec into a feature list; then **one fresh Claude Code session per
feature** does the work, test-first, until everything passes or the time is up. A deterministic
bash driver does the bookkeeping around them, so the agents only do the judgment.

Zero dependencies beyond `bash`, `git`, `node`, `tmux`, `claude` and (for PRs) `gh`.
The journal of how it came about is in [`journal/`](journal/README.md).

## Quick start

```bash
ln -s ~/projects/agent-harness/bin/harness ~/.local/bin/harness   # once
harness init ~/projects/myapp          # scaffolds .harness/{config.sh,init.sh,project.md} + .claude/settings.json
# edit them, commit to main, then:
harness start ~/projects/myapp feature-x-2026-10-17
harness status                         # every run: alive, features passing, last log lines
harness attach feature-x-2026-10-17    # tmux: driver · log · supervisor (Ctrl-b n next window, Ctrl-b d detach)
harness gc ~/projects/myapp            # after merging: remove merged worktrees and branches
```

## What a run is

| | Where |
|---|---|
| Worktree (isolated checkout) | `~/worktrees/<project>/<run-id>` |
| Branch | `harness/<run-id>`, from `origin/main` (or `--base <ref>`) |
| Run record (committed, readable on GitHub) | `.harness/runs/<run-id>/feature_list.json` · `progress.md` (sessions, newest first) · `harness-log.md` (driver events) · `INBOX.md` (steering) · `metrics.jsonl` (cost, duration, turns per session) |
| Local state | `~/.local/state/harness/<project>/<run-id>/`: `run.log`, `logs/*.jsonl` (full session transcripts), attempts, port, PAUSE/STOP |
| Scratch (dev DB, server, screenshots) | `/tmp/harness/<project>/<run-id>/` |
| tmux session | `h-<run-id>`, windows `driver`, `log`, `supervisor` |

Several runs (same or different projects) can go at once: each has its own worktree, branch, port
and scratch directory.

## The loop (`lib/driver.sh`)

1. **Initializer** (once, `INIT_MODEL`): reads `SPEC_FILES` and the project rules, then writes the
   feature list (ordered; each feature has verifiable steps, a milestone and a model) and the
   progress log.
2. **Before every session:**
   - move local answers into `INBOX.md`;
   - pull edits made on GitHub (your phone);
   - honour `status: pause|stop` and `harness pause|stop`;
   - run the project's `INIT_CMD` (its output goes into the prompt);
   - choose the next feature that isn't passing.
3. **A coding session** (`claude -p`, the feature's model, auto mode, `--settings`, turn, time and $
   limits). It follows `prompts/coding.md` plus the project's `.harness/project.md`: get bearings,
   smoke test, one feature test-first, verify, flip only its own `passes`, log, commit, push.
4. **After every session:**
   - commit leftovers;
   - **repair** the feature list (only the session's own `passes` may change; anything else is
     reverted, and 3 sessions in a row stop the run);
   - **un-pass** the feature if `CHECK_CMD` is red;
   - record metrics; push.
5. **Milestone complete →** a **verify** session (`VERIFY_MODEL`) re-runs every step cold and may
   only un-pass. A failed feature gets one more attempt; after `MAX_VERIFY_ROUNDS` the milestone is
   marked "needs Michael". When it holds: tag `run/<run-id>/<milestone>` and open or refresh the
   run's **PR into main** with the evidence.
6. **Stop** at `HOURS`, `MAX_SESSIONS`, nothing left to try, or a stop request. Write the summary,
   push, update the PR.

Merging stays a human review (one tap per PR, or enable GitHub auto-merge). `harness gc` cleans up
afterwards. It deletes only what is fully contained in `origin/main`.

## Steering and monitoring

- **From the phone:** the GitHub app.
  - Read `progress.md`, `harness-log.md` and the PR.
  - Edit `INBOX.md` on the run branch: set the first line to `status: pause` or `status: stop`, or
    write answers under `## Answers`.
  - The driver pulls before every session.
- **Live conversation:** the `supervisor` window runs an interactive Claude session in the project.
  With `remoteControlAtStartup` it appears in the Claude app. Ask it for status; it can answer
  questions (`harness answer`), pause, resume, and fix a blocker while paused.
- **Notifications:** set `NOTIFY_CMD` in the project config (e.g. a private ntfy.sh topic) for start,
  milestone, blocked and done.
- **On the box:** `harness status`, `harness attach <run>`, `tail -F ~/.local/state/harness/<p>/<run>/run.log`.

## Permissions

Headless sessions get the project's `.claude/settings.json` through `--settings`. That works in a
fresh, untrusted worktree, where project settings would otherwise be ignored. The template allows
broadly and denies only what destroys git history: force pushes, remote branch deletes,
`branch -D`, tag deletion, filter-branch/filter-repo, reflog expiry, gc prune, stash drops. It also
denies worktree removal by agents, repo or DELETE API calls, `.env` and sudo. Deny rules match
command prefixes, so put the hard guarantees on GitHub: branch protection against force pushes and
deletion.

## Configuration (`.harness/config.sh`)

See [`templates/project/config.sh`](templates/project/config.sh): the spec files, check/init/smoke
commands, base port, models per role, time, session, attempt and budget limits, PR policy and the
notify command.

## Tests

```bash
tests/run.sh    # end-to-end with stub claude/gh on a throwaway project: 20 checks
```
