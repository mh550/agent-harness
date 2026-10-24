# System resource audit: a week of harness runs, the boot "hang", and what is still running

Date: 2026-10-24, 12:30 EDT, about 20 minutes after the reboot. Host: pop-os, 15.5 GB RAM, 8 cores, 15.5 GB zram plus
4 GB disk swap.

Sources:
- the journals of the previous boot (Oct 13 to Oct 24) and of both boots today;
- `ps`, PSS from `/proc/*/smaps_rollup`, and cgroup `memory.current`;
- `docker stats` and `docker system df`;
- `~/.claude/daemon.log`;
- `harness status`, `harness trends` and `harness queue`;
- a read-only audit of `lib/`, `bin/` and every project's `.harness/`.

Builds on `2026-10-24-oom-from-unbounded-test-diff.md`. That doc covers the 00:49 OOM; its recommendations still
stand and are folded in below.

## TL;DR

- **The boot didn't hang. It was deleting about 1 million files from `/tmp`.**
  - `/tmp` is on disk and Pop's rule is `D /tmp … 30d`. That rule empties `/tmp` at every boot, but during uptime
    it only removes files older than 30 days.
  - So a week of harness scratch and test temp dirs piled up, and the boot purge took about 60 s.
    `systemd-tmpfiles-setup` ran from 6.6 s to 64.0 s on today's successful boot.
  - The first boot was powered off 60 s into that purge, which is why the second boot shows `recovering journal`.
    Nothing is damaged.
- **The roughly 5 GB you got back was leaked by design gaps, not by a single bug.** The harness never stops what a
  run starts: dev servers, supervisor `claude` processes, tmux sessions and scratch. It also caps no memory. On top of
  that, Claude Code background sessions stay resident and carry over each daily auto-update.
- **Nothing in what is running now comes from the harness.** The queue is empty, no run is active and there is no
  tmux server. The 7.8 GB in use is:
  - the voice-concierge worker (about 1 GB);
  - Claude Code with its MCP children (about 1.7 GB);
  - the COSMIC desktop and Firefox (about 3 GB);
  - docker (about 1 GB);
  - smaller daemons.
- **The biggest fixes:**
  1. Run each session and each init in a **systemd scope with a memory cap**, and stop the scope when the session or
     run ends. That one change gives both garbage collection and OOM isolation.
  2. **Clean scratch at run end.**
  3. **Run `harness gc` automatically.**
  4. **Cut voice-concierge to 1 idle process.**
  5. **Stop loading the n8n MCP servers into every Claude process.**

## 1. What you saw, explained

| Observation | What it actually is | Real cost now |
|---|---|---|
| Boot stuck on the splash screen, with `Job systemd-tmpfiles-setup.service/start running (34s / no limit)` | The boot-time purge of a disk-backed `/tmp`. The root fs held 2,715,855 inodes before the purge and 1,649,372 after, so about **1.07 M files** were deleted. The daily cleaner had run all week but removes only files older than 30 days; it took 8.3 s on its last run, up from 0.04 s on the first day. | 0 now, about 1 min at the next boot if the pile-up repeats |
| "6 python processes at half a GB each" | `voice-concierge.service`, a user unit that starts at login. It is the LiveKit `AgentServer` plus **8 pre-warmed forkserver job processes**. `concierge/worker.py:65` doesn't set `num_idle_processes`, so LiveKit's production default is `ceil(cpu_count)` = 8. Each child preloads the silero, deepgram, openai and anthropic plugins. RSS adds up to about 3.7 GB, but the children share copy-on-write pages. Each idle child also burns about 1% CPU. | **0.93 GB PSS, 1.0 GB cgroup, about 8% CPU at idle** |
| "A bunch of `2.1.310` instances" | Every Claude Code process. The binary *is* `~/.local/share/claude/versions/2.1.310`, so that is its process name. There are 15 now: 2 interactive CLIs (pts/0 and pts/6), 1 transient `claude daemon`, 1 running background job, this audit's job, **3 unclaimed pre-warmed "bg-spare" sessions**, a `bg-pty-host` for each, and **one `n8n-mcp` node child per session**. | **1.38 GB PSS for Claude, plus 0.28 GB for six n8n-mcp** |
| A 1 GB "Claude Code URL Handler" | `~/.local/share/applications/claude-code-url-handler.desktop` runs `claude --handle-uri %u`. That is a **full Claude Code CLI session** opened from a `claude-cli://` link, and the system monitor labels it with the desktop entry's name. It grows like any long session (context and tool output) and lives until its terminal closes. It wasn't running at audit time, so this is inferred from the desktop entry, not measured. | n/a now |

Current footprint by owner (PSS where readable, otherwise RSS):

| Owner | Memory | Notes |
|---|---|---|
| COSMIC desktop (compositor, panel, launcher, files, monitor, Xwayland) | about 1.3 GB | `cosmic-monitor` alone takes about 17% CPU while it is open |
| Firefox | about 1.5 GB RSS | |
| Claude Code processes (15) plus n8n-mcp (6) | about 1.7 GB | grows by about 0.5 GB for every spare or finished background job kept alive |
| voice-concierge | about 1.0 GB | 8 idle job processes |
| docker: n8n 458 MiB, slskd 143 MiB, other dj-* about 110 MiB, dockerd and containerd about 165 MiB | about 0.9 GB | **no container has a memory limit**; slskd uses 14–18% CPU constantly |
| Page cache | 7.4 GB | reclaimable; `available` is 7.7 GB |

## 2. Root causes from the past week

The previous boot ran from Oct 13 to Oct 24 12:01. In that time the harness did 22 runs, about 155 wall-hours of run time between Oct 17 and Oct 24 (168 hours), so a
run was going almost the whole time. It ran up to 2 runs in parallel, plus interactive and background Claude
sessions. There were 10 OOM kills (Oct 19: 1, Oct 23: 4, Oct 24: 5) and 7 "under memory pressure"
cache flushes.

The causes, ranked by how much memory or how many files they leaked:

1. **Dev servers outlive their runs.**
   - The project init runs as a bare `bash -c "$INIT_CMD"` (`lib/driver.sh:185`).
   - portfolio_site's init does `nohup npx next dev … & echo $! > $SCRATCH/server.pid`.
   - The only kill is the *same run's* next init (`portfolio_site/.harness/init.sh:20`), and it kills the `npx`
     wrapper's pid, not `next-server`.
   - `finish`, `stop`, `pause`, usage-limit waits and a driver crash stop nothing. The EXIT trap in
     `lib/driver.sh:84-86` only writes `ended`.
   - Every run has its own scratch dir, so each portfolio run left a `next dev` behind. Six of them ran for 2–5
     days.
2. **Nothing caps a session's memory.** `session()` is `timeout 100m claude -p …` (`lib/driver.sh:177`): it limits
   wall time only, sends SIGTERM only and has no `-k`. `lib/check.sh:21` runs the suite as a bare `bash -c` with no
   timeout. A single red-phase test grew to 6.5–9.6 GB four times, and the kernel picked victims machine-wide:
   codium, claude-desktop, python.
3. **A session's children outlive it.** When `claude -p` exits normally, nothing signals its process group. Anything
   it backgrounded keeps running: dev servers, Playwright Chromium, watchers, Claude Code background shells and
   subagents.
4. **Claude Code's own processes pile up.** This is Claude Code behaviour, not the harness's.
   - The transient daemon keeps a pool of pre-warmed `bg-spare` sessions, each with its own MCP children.
   - A background job's process stays alive after the job finishes, until the job is deleted.
   - Claude Code auto-updated almost every day (2.1.299 → 2.1.310). Each update restarted the daemon and **adopted**
     the old sessions, up to 9 at once (`adopted=9`, Oct 22).
   - The previous OOM doc counted about 14 `bg-spare` processes, one of them about 5 days old.
   - `daemon.log` for the week: 100 spares spawned, 86 claimed.
5. **The supervisor and tmux sessions never end.**
   - Every manual `harness start` opens an interactive supervisor `claude` (`bin/harness:166-170`) whose prompt
     ends "Then wait".
   - Every `h-<run>` tmux session stays alive through `; exec bash` and an endless `tail -F` (`bin/harness:164-165`).
   - Both are killed only when the same run id is started again. The reap in spec
     `docs/specs/2026-10-22-tmux-and-queue-hygiene.md` (H1) is not built.
6. **Scratch under `/tmp` is never deleted.** `/tmp/harness/<project>/<run>` (`lib/driver.sh:39`) keeps:
   - `check.out` plus one `check-<tree-hash>.out` copy per code tree (`lib/check.sh:22`);
   - the pytest sandbox tree (dj);
   - `server.log`;
   - full-page smoke screenshots;
   - review diffs;
   - a Playwright `node_modules` reinstalled after every boot.

   Nothing in `lib/`, `bin/` or `harness gc` ever removes these.

   The project test suites also leak temp dirs into `/tmp` on every run. In rane-one-mixxx, 10 of the 21 test files
   that call `mkdtemp`/`tmpdir()` show no cleanup, and pathways and agent-harness have a few more. That count is a
   grep heuristic.

   The suites ran hundreds of times a day: before every session, after every session, at verify and at finish.
   Together these are the most likely source of the roughly 1 M files. It can't be confirmed directly, because the
   boot purge deleted them.
7. **Project services started by sessions aren't torn down by the harness.**
   - hit_list's local **Supabase stack is 13 containers**. It ran for about 15 h during `hit_list-2026-10-22-sharing`
     (Oct 22 21:47 to Oct 23 about 13:00), and `supabase_db` was recreated 149 times by `db reset`.
   - The OOM at Oct 23 01:17 hit while it was up. The process that triggered the OOM killer was `erts_sched`, an
     Erlang scheduler thread, most likely Supabase Realtime.
   - hit_list's CLAUDE.md asks for `db:stop` after use. Only the agent's discipline enforces that; the harness
     doesn't.
8. **Worktrees and their dependencies are never collected.**
   - `~/worktrees` is 7.3 GB, of which 6.6 GB is `node_modules`, `.next` and `.venv`. The portfolio_site worktrees
     alone take about 4.7 GB, and their PRs are all unmerged.
   - `harness gc` is manual only. Nothing calls it, and the debrief denies it (`lib/debrief.sh:205`).
   - It only removes worktrees that are merged, and under `MERGE_POLICY=pr` many never are.
9. **The memory pressure was hidden.** `/etc/default/pop-zram` sets `PORTION=100` with `SWAPPINESS=180`, a 15.5 GB
   zram on a 15.5 GB machine. The box swapped into compressed RAM (14.5 of 15.5 GB at the OOM) instead of showing
   pressure early. `systemd-oomd` is inactive, so the kernel OOM killer was the only backstop.

Also, the live checkout's `main` is **109 commits behind `origin/main`**. The spot-check found the
session, init and check launch paths unchanged there, so the gaps above still apply.

## 3. Recommended next steps

### A. Now (minutes, no code)

1. **voice-concierge:** if you're not demoing it, run `systemctl --user stop voice-concierge` (and `disable` to keep
   it off at login). This frees about 1 GB and about 8% CPU. For the permanent fix, see B6.
2. **Claude Code background sessions:** delete finished jobs from the job list. When no background job is running,
   `claude daemon stop --any` ends the daemon, its spares and every background session, including any that are still
   working. It restarts on demand. I found no setting for the spare-pool size in `claude daemon --help`.
3. **Move the n8n MCP servers out of user scope.** `n8n` (http) and `n8n-docs` (a stdio node process, about 110 MB
   each time) are in `~/.claude.json`'s top-level `mcpServers`. So *every* Claude process loads them: interactive
   CLIs, spares, background jobs, and every harness `claude -p` coding, verify and retro session. Re-add them with
   `-s project` in `~/projects/n8n-home` only. That saves about 110 MB per Claude process, plus startup time.
4. **Disk:** this is low priority, since the root fs is only 16% full. Still:
   - `harness gc <project> --dry-run`, then `gc`, for each project.
   - Decide on the six unmerged portfolio_site worktrees (about 4.7 GB).
   - `docker image prune` for the old `dj-crates:<sha>` tags (9 tags of about 840 MB, with shared layers).
   - `docker builder prune` (1.7 GB).
   - Remove the `public.ecr.aws/supabase/*` images (about 8.5 GB) if hit_list will use a hosted Supabase.
5. Close `cosmic-monitor` when you're not using it (about 17% CPU).
6. Next time the splash screen sits on `tmpfiles-setup`, **wait**. Cutting power mid-purge only adds a journal
   recovery to the next boot.

### B. Harness changes (in priority order)

Each change needs the repo's usual process: a decision file, a check in `tests/run.sh` written first, then updates
to `docs/architecture.md` and `README.md`.

1. **One cgroup per session, and one per run for services.** This is garbage collection and OOM isolation in one
   change.
   - Launch each session as
     `systemd-run --user --scope --unit=harness-<run>-s<n> -p MemoryHigh=5G -p MemoryMax=6G -p MemorySwapMax=1G timeout -k 30s …`.
   - When `claude` returns, run `systemctl --user stop harness-<run>-s<n>.scope`. That kills every child the session
     left behind, without needing pid files.
   - Run `INIT_CMD` inside a per-run service scope, `harness-<run>-svc` (dev servers, Supabase CLI). Stop it in
     `finish`, in the EXIT trap, on `pause` and `stop`, and before any usage-limit wait longer than about 10 minutes.
     The next session's init starts it again.
   - With these scopes in place, `systemctl --user list-units 'harness-*'` becomes a ready-made dashboard of what
     each run holds.
2. **Cap and time-limit the suite and init.**
   - Run `check.sh`'s `bash -c "$cmd"` in its own scope (`MemoryMax` about 2–3 G) under `timeout -k 30s 15m`.
   - Give `INIT_CMD` a timeout too.
   - A runaway test then fails by itself, with exit 137 recorded, instead of the kernel picking a victim.
3. **Check free memory before each session.** Like `LIMIT_WAITS`: if `MemAvailable` is under about 5 GB, log it and
   wait (or park the run). Record each scope's `memory.peak` per session in `metrics.jsonl`, so `harness report`
   shows which features are memory-hungry.
4. **Add a project teardown hook.** Add an optional `.harness/teardown.sh` (`TEARDOWN_CMD`) that runs at the same
   points as the scope stop in B1.
   - For hit_list it would be `npx supabase stop`.
   - For portfolio_site it would kill the `next-server` *process group*, not the `npx` pid. Easier: start it with
     `setsid` and kill `-pgid`.
   - The cgroup in B1 already covers processes. This hook covers state the cgroup can't see, such as docker
     containers, which run under `dockerd`.
5. **Clean scratch.**
   - In `finish`, copy what the record needs (the last `check.out`, `retro.md`) into `$STATE`, then delete `$SCRATCH`.
   - Keep only the newest `check-<key>.out`; the green marker in `$STATE/green` is the cache.
   - Move the Playwright install to `~/.cache/harness/pw`, so it isn't reinstalled after every boot.
   - Optionally set `HARNESS_SCRATCH_ROOT=~/.cache/harness/scratch` with a user tmpfiles age rule
     (`~/.config/user-tmpfiles.d/harness.conf`: `e %h/.cache/harness/scratch - - - 3d`), so even a crashed run's
     scratch ages out within days, not at the next boot.
6. **Bound the per-project memory hogs.**
   - voice-concierge: `AgentServer(num_idle_processes=1, …)` in `concierge/worker.py:65`. Prewarm happens per
     process, so 1 is enough for a portfolio demo. This saves about 0.7 GB and 7% CPU.
   - Fix the rane-one-mixxx and pathways tests that `mkdtemp` without `t.after(() => rm(…))`.
   - Add try/finally around `browser.close()` in the `smoke.mjs` scripts.
7. **Reap tmux sessions and supervisors.**
   - Build spec H1 (`TMUX_KEEP_HOURS`).
   - Have `finish` kill its own supervisor window (or tell the supervisor prompt to exit on `ended`).
   - Count supervisors and desks against `MAX_PARALLEL_RUNS`.
8. **Run gc automatically.**
   - The queue runner runs `harness gc --all-merged` when it drains.
   - Add a `--deps` mode that deletes `node_modules`, `.next`, `.next-check` and `.venv` in the worktrees of ended
     runs, even unmerged ones. They're cheap to rebuild, and they're 90% of worktree disk.
9. **Limit headless sessions' MCP servers.** Pass `--strict-mcp-config` (plus a project MCP config only where a
   project needs one) in `session()`, so harness sessions never inherit user-scope MCP servers.
10. **Pull `origin/main`** into the live checkout before building any of this. It is 109 commits behind.

### C. Box hygiene (one-time settings)

1. **zram:** set `PORTION=50` in `/etc/default/pop-zram` (an 8 GB zram), and consider `SWAPPINESS=100`. Memory pressure
   then shows up before RAM is mostly compressed swap.
2. **systemd-oomd:** once the scopes in B1 exist, enable it with `ManagedOOMMemoryPressure=kill` on the user slice.
   Under sustained pressure it then kills the offending harness scope instead of your editor or desktop.
3. **Docker memory limits:** add `mem_limit` in the compose files (n8n about 1 G, slskd about 512 M, the others about
   256 M). Look into slskd's constant 15–18% CPU, which is probably share scanning or searches.
4. **A watchdog timer:** a 15-minute user timer that appends one line to `~/.local/state/harness/box.log`, with:
   - `MemAvailable` and zram used;
   - the counts of `next-server`, `bg-spare`, `h-*` tmux sessions and `harness-*` scopes;
   - the file count under `/tmp/harness`.

   The debrief can then flag leaks in its headline before they cost a reboot.

## 4. Evidence

- Boot timing: `journalctl -b 0` shows `Starting systemd-tmpfiles-setup` at 6.59 s and `Finished` at 63.99 s. In
  boot −1, it started at 4.08 s and had not finished when the journal ended 60 s later. The previous boot shut down
  cleanly at 12:01:12, so the slow purge came from the files, not from an unclean shutdown.
- Inodes: 2,715,855 in the fsck line of the boot photo, and 1,649,372 from `df -i /` after boot.
- Tmpfiles rules (`/usr/lib/tmpfiles.d/tmp.conf`): `D /tmp 1777 root root 30d`. `/tmp` is on `/dev/nvme0n1p3`, not
  tmpfs.
- OOM kills, from `journalctl -b -2 -k | grep 'Out of memory'`: node `MainThread` at 9.6 GB (Oct 19), and 6.5, 7.3,
  7.5 and 7.6 GB (Oct 24). claude-desktop ×2, python ×2 and codium were collateral.
- Daemon: in `~/.claude/daemon.log`, 27 daemon starts across 11 versions, 100 spare spawns, 86 claims, and
  `adopted=` up to 9.
- Supabase: `journalctl -b -2 -u docker` shows 149 `sbJoin … supabase_db_hit-list` lines, from Oct 22 21:47 to
  Oct 23 12:54.
- Harness: `harness queue` is empty, there is no runner, and `tmux ls` finds no server. `harness trends` shows 22 runs,
  520 features and $1,941.70.
