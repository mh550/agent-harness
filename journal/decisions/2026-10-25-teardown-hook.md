# A run's services stop on finish and in the driver's EXIT trap, through the project's teardown hook

*(2026-10-25, run agent-harness-2026-10-25-lifecycle, feature L2-03; spec `docs/specs/2026-10-25-resource-lifecycle.md`
§L2 items 2–3, plan `docs/plans/2026-10-25-L2-run-services.md` §3, §4, §5.1–5.2, §6.1–6.2, defaults D1–D5 in §10)*

- **Finding:** after L2-02 the init's servers live in `harness-<run>-svc`, but only the next `run_init` stopped it:
  a run that ended, or a driver that was killed, left them up until a run of the same id started again, which for
  most runs is never. And some services aren't the init's processes at all: `npx supabase start` and
  `docker compose up` ask `dockerd` to start containers, which live in `dockerd`'s cgroup, where no stop of a scope of
  ours reaches. Bash also runs the EXIT trap at once on a TERM while a foreground child runs, and the child lives on
  (probed in L2-01): a TERM to the driver mid-session left `claude` working in `harness-<run>-s<n>` with nobody to read
  it, up to `SESSION_TIMEOUT`.
- **Choice:**
  - **`services_down <why>`** in `lib/driver.sh`: the project's `TEARDOWN_CMD` (default `.harness/teardown.sh` when that
    file is executable, else nothing) in the worktree under `timeout -k 10s 2m` (KILL 10 s after the TERM: a hook stuck on `dockerd` that ignores TERM would hang finish), stdin `/dev/null`, with `HARNESS_PORT`,
    `HARNESS_SCRATCH`, `HARNESS_RUN_ID` and `HARNESS_TEARDOWN_WHY=<why>`, output appended to `teardown.out`; then
    `scope_stop harness-<run>-svc`; then one note, `services stopped (<why>)`.
  - **The hook runs before the scope stops** (a `docker compose down` may want the app holding its connection still
    up), **bare** (it is short, and the scope it tears down is about to go), and **its exit never stops the driver**:
    a failure or a timeout is in the note (`teardown exit <rc>, see …/teardown.out`) and the scope stops regardless
    (D4).
  - **Once per started init (D1):** `run_init` sets `SVC_UP=1`; `services_down` returns at once without it and clears
    it after the stop. So `finish`'s call and the EXIT trap's after it give one note, a segment that never ran an init
    is silent (what a SIGKILLed earlier segment left is `run_init`'s stop and `harness gc`'s, L2-05), and a TERM
    during finish's teardown still stops the scope from the trap.
  - **`finish` calls it after the last suite run and before the summary (D3)**: a suite that needs the dev server or a
    local database still has them; the note lands before the end commit.
  - **The EXIT trap stops the running session's scope first, then the services (D2):** `session()` keeps the unit in
    `S_UNIT` while it runs. The teardown may take its two minutes, and `claude` must not edit and push in the worktree
    meanwhile, nor survive a shutdown's SIGKILL during it. The trap first ignores TERM, INT and HUP: it can now take
    minutes, and a second signal (tmux closing sends HUP to the pane's group) would end it with the services up and no
    `ended` written. A bare session (no user systemd) still lives on to its timeout.
  - **`verify()` re-runs the init after a memory wait** (`mem_gate || run_init`, the plan's §1 fix pulled forward from
    L2-04): its gate came after its `run_init`, and a real `services_down` there would start the verify session
    without the services it just started (the review's finding; the `lowmem` run's check saw it).
  - **`templates/project/teardown.sh`**: a commented template with `npx supabase stop` and `docker compose down`;
    the README tells projects to add their own and when it runs.
  - The suite's stub `systemd-run` now runs its command in the background with the pid in `<unit>.cmd`, and the stub
    `systemctl stop` kills that pid's whole tree, as a real stop kills the cgroup; before, a stopped stub scope left
    its command running, so the TERM check could not tell a stopped session from a live one.
- **Rejected:**
  - **Parsing `docker ps`** (or `docker compose ls`) for containers that look like the run's: names are the project's
    choice, a guess could stop another run's or Michael's own containers, and it would tie the harness to docker. The
    project knows what it started; the hook says it.
  - **Running the teardown before every init (D5):** an init brings its services up idempotently, and a
    `supabase stop` before each session would cost minutes each.
  - **The teardown inside the services scope:** the scope is about to be stopped, and a teardown in it would be
    killed with it if it ran long.
  - **A note from every call:** finish followed by the trap would note twice, and a fresh segment's first memory wait
    would note services it never started.

## A TERM mid-init or mid-teardown, and a hook added mid-run (L2-06)

*(2026-10-25, same run, feature L2-06: the L2 review's findings #1–#4, `docs/plans/2026-10-25-L2-review.md`; spec
`docs/specs/2026-10-25-resource-lifecycle.md` §L2 items 2–3)*

- **Finding:** bash runs the EXIT trap at once on a TERM, while its foreground child runs on. A TERM during
  `run_init` ran the hook beside a still-running init (a `supabase start` two minutes in goes on creating containers
  the `supabase stop` beside it has already passed; the scope stop after the hook kills only the CLI). A TERM during
  any teardown (finish, pause, a long limit wait, a memory wait) started a second hook beside the first, orphaned one.
  `TEARDOWN_CMD` was settled at `load_config`, before `sync_main` merges main, so a `.harness/teardown.sh` Michael added
  on main and brought in with `harness continue` (or a session wrote) never ran that segment. And the trap's note
  stayed uncommitted, a dirty worktree `harness gc` then keeps.
- **Choice:**
  - `run_init` sets `SVC_INIT` around the init's `scope_run`; `services_down` with it set stops the svc scope
    (the init) first, then runs the hook, then stops the scope again (exit 5, nothing left, counts as done).
  - The hook runs in the background with its pid in `SVC_TD` and `services_down` waits for it; the trap, finding
    `SVC_TD` set, waits for that one instead of starting another, then stops the scope and notes once (with the
    trap's why, `driver exited`, as that is what ended it).
  - `TEARDOWN_CMD` is only an explicit override (default empty); `services_down` looks for an executable
    `.harness/teardown.sh` each time it runs.
  - The trap commits `harness-log.md` alone (`git commit -- <file>`, not pushed: no network in a dying driver);
    failure is silent.
- **Rejected:**
  - **Stopping the svc scope before the hook always:** L2-03's order (hook, then scope) leaves the hook able to reach
    services that are up; only an init still starting them is stopped first.
  - **A lock file around the hook:** two driver processes never share a run; the race is one shell and its trap.
  - **Re-running `harness_config` before each teardown:** it re-derives every key mid-run; the hook is one file test.
  - **The trap's line as `log`, not `note`:** the phone should see why the services stopped.
