# The init runs in the run's services scope, stopped before the next init

*(2026-10-25, run agent-harness-2026-10-25-lifecycle, feature L2-02; spec `docs/specs/2026-10-25-resource-lifecycle.md`
§L2 item 1, plan `docs/plans/2026-10-25-L2-run-services.md` §1, §2, §6.8–6.10)*

- **Finding:** `run_init` ran `bash -c "$INIT_CMD"` bare. portfolio_site's init backgrounds `next dev`, and the only
  kill was the same run's next init, which killed the `npx` pid from `server.pid`, not `next-server` under it: dev
  servers ran for 2–5 days after their runs. Nothing capped what an init started, and nothing bounded an init that
  hung in its foreground.
- **Choice:**
  - **`run_init` first stops `harness-<run>-svc`** (`scope_stop`; exit 5, nothing loaded, is done), **then runs the
    init in that scope** through `scope_run`: `MemoryMax=SVC_MEMORY_MAX` (default `3G`), `MemorySwapMax` 1G,
    `OOMPolicy=continue`, no `MemoryHigh` (a runaway server dies at its cap instead of crawling, as suites do).
    Everything the init backgrounds stays in the scope, so the stop takes `next-server` and its children with it,
    whatever pid file the project kept.
  - **The stop comes first because systemd requires it:** real `systemd-run` with a unit name still loaded exits 1
    (`Failed to start transient scope unit: Unit <u>.scope was already loaded or has a fragment file.`,
    `tests/fixtures/systemd-run-unit-exists.txt`), and `scope_run` would then run the init bare beside the old
    servers. The stub `systemd-run` now refuses a live unit the same way, so a missing stop shows in the suite.
  - **`timeout -k 10s INIT_TIMEOUT` (default `10m`) inside the scope, around the init's foreground only**: an init
    that backgrounds its server and exits 0 returns at once; one that hangs is TERMed, then KILLed 10 s later. The
    servers it started live on in the scope.
  - When systemd refuses the unit after a good probe, the init runs bare and the run notes `init ran uncapped: <why>`;
    without user systemd it runs bare silently (the run's one `no user systemd` note covers it).
  - `SVC_UP=1` is set before the start, for L2-03's `services_down` (a TERM during the init must still stop it).
  - `templates/project/init.sh` keeps its `kill $(cat server.pid)` line: harmless in a scope, needed bare.
- **Rejected:**
  - **Killing the init's pid** (or a pid file it writes): the pid is `npx` or a shell, not the server it forked, and a
    project's own pid bookkeeping is what failed on portfolio_site. The scope's cgroup holds every descendant.
  - **The init inside each session's scope**: the session's scope is stopped after each session, so servers meant to
    serve the next verify or suite would die early, and a dev server would share the session's 6G with `claude`.
  - **Bounding the whole scope with `timeout`** (around `systemd-run`): it would kill the backgrounded servers the
    init exists to start.
