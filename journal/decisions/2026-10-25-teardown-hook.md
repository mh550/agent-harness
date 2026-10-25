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
