## Policy: live-staged

This project runs a live system that Michael uses. Its harness policy is **live-staged**: you **may operate it
live**, but only through this protocol. The project-specific commands are in the `## Live system` section of
`CLAUDE.md` (Check, Snapshots, Backups, Deploy and rollback, Staged runbooks, Never). If that section is missing
or doesn't cover what you need, treat the project as build-only for that step.

Build and test first, against fakes and the sandboxed suite. A live stage is the **last step of a feature**,
never a way to debug.

### The backup comes first
If the project's **Backups** section names a backup window (the nightly job's time), make **no live write and no
deploy inside it or while the backup job runs**: a stage that would cross it waits, or the session does build work
instead. The backup takes the same lock you do (below), so a stage holding it delays the backup, never the reverse.

### Before the first live write of a session
1. The full suite (`{{CHECK}}`) is green on the commit you will run, and the tree is clean and pushed.
2. The project's **Check** (from `CLAUDE.md`) passes.
3. Take the **Snapshots** the project lists, named with this run's id (`{{RUN_ID}}`) so the nightly backup or the
   next run can't overwrite your restore point.
4. Read the **Backups** status: the last backup must have succeeded within the age the project states. If it
   didn't, stop: no live writes this session; say so in your journal entry (`entry.json`).
5. Note in your journal entry (`entry.json`'s `verified_how`): the backup status, the running version/image, and the snapshot paths.

### Deploying
- Only as the project's **Deploy and rollback** says, from **this worktree** (`{{WT}}`), on a pushed commit.
  First record what is running now: that is the rollback.
- After a deploy run the project's post-deploy checks. Any failure: roll back, log it, stop.

### Stages (every live write)
dry run → `--limit 5` → `--limit 50` → all. After **each** stage: the tool's exit code and report, then the
project's **Check**. Read every refusal or warning before the next stage. A flow without a dry run, a limit and a
reverse log is **not** run live; write its live steps in your journal entry (`entry.json`) instead.

### On the first problem
Stop. Undo with the flow's reverse log, run the **Check** until it is green, roll back a deploy, and log what
happened in your journal entry (`entry.json`: `dead_ends` for what failed, `verified_how` with the exact commands you
ran). Don't flip `passes`. Don't retry live in
the same session.

### One live writer at a time
Wrap every live write and every deploy in `flock -n {{LIVE_LOCK}} <command>`. If the lock is taken, another run,
Michael or the backup job is working: don't wait. Log it and do only build work this session.

### Always
- Every live command you ran goes into your journal entry's `verified_how`, verbatim, with its result.
- The project's **Never** list holds, and so does this one: no secrets printed or read beyond what a command
  needs, no `sudo`, no backup-tool writes (restore, forget, prune), no rewriting git history, no deploys from
  any checkout but this worktree.
