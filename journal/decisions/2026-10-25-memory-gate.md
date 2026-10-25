# A memory gate before each session: wait for free memory, then start anyway

*(2026-10-25, run agent-harness-2026-10-25-lifecycle, feature L1-06; spec `docs/specs/2026-10-25-resource-lifecycle.md`
§L1 item 4, plan `docs/plans/2026-10-25-L1-capped-sessions.md` §1, §7, §8.3; the audit
`findings-and-research/2026-10-24-system-resource-audit.md` §3B.3)*

- **Finding:** the driver started a session whatever the box had left. On 2026-10-24 a session started next to
  leftover servers and Michael's own apps, and when its test grew the kernel picked victims outside the harness. A
  session's 6G scope (L1-03) caps what it can take, but not what it starts with: under memory pressure even a capped
  session pushes the rest of the box into swap.
- **Choice:**
  - **`mem_gate` runs at the top of `session()`** for init, coding and verify (not the retro: the run is ending), before
    the session's clock starts, so a wait is never the session's wall time (nor its timeout's).
  - **The figure is `MemAvailable`** of `${HARNESS_MEMINFO:-/proc/meminfo}`, floored to whole GB (`mem_available_gb`
    in `lib/scope.sh`). A file without the line is no gate.
  - **D *default*: `MEM_MIN_AVAILABLE_GB=5`**, the audit's figure (the box idles at 7.7 GB available), and
    **`MEM_WAIT_MAX=30m`**, polled every 5 minutes (`HARNESS_MEM_POLL`, seconds, is the suite's override). Under the
    minimum: the note `memory: <n> GB available, under MEM_MIN_AVAILABLE_GB=5; waiting up to 30m`, then
    `services_down memory` (a no-op in the driver until L2 stops the run's services there), then a check at once and one
    per poll. Back over it: `memory: <n> GB available after <s> s; starting the session`. Still under at the end:
    `memory still at <n> GB after 30m; starting the session anyway (its cap protects the box)`.
  - **`mem_gate` lives in `lib/scope.sh`** beside `mem_available_gb` and `dur_s`, not in the driver as the plan put it,
    so a check can source it with its own `note` and a `services_down` that frees memory: the "back over it" path is
    tested without timing races. The driver supplies `note` and `services_down`.
  - **The suite's fixture is the real `/proc/meminfo` capture** (`tests/fixtures/meminfo.txt`, 9 GB available); the
    gate's run uses a copy with only its `MemAvailable` line rewritten to 2 GB (the check asserts that one line is the
    only difference).
- **Rejected:**
  - **Refusing to start, or parking the run, until memory is free.** The session's cap now protects the box, and a run
    that never starts helps nobody: Michael would come back to nothing done, for a box that was merely busy.
  - **A gate on the retro.** It runs read-only at the end of a run; waiting 30 minutes to write a retro buys nothing.
  - **Counting the wait in `S_WALL`.** It would read as a slow session in `metrics.jsonl` and the report.

## The gate moves out of `session()`, before the attempt and its prompt (L1-08)

*(2026-10-25, same run, feature L1-08: the L1 review's one Important finding, `docs/plans/2026-10-25-L1-review.md` #1;
spec §L1 item 4)*

- **Finding:** `session()` ran `mem_gate` after everything the driver decides before a session: the deadline and
  `status: stop`/pause checks, the attempt bump and the prompt with its `Clock:` line. A 30-minute wait then started a
  session past the deadline, under a clock 30 minutes stale, and after a stop Michael set during the wait; the suite's
  check (a stop set during the wait) saw the coding session run and its attempt spent.
- **Choice:** the callers gate. The run loop calls `mem_gate` once the feature is picked and before `F bump` and
  `prompt coding`; after a wait (`mem_gate` now exits 1 when it waited, either way) the loop starts over, so the
  deadline, `control` and the pick run again, and the gate is skipped once (`gated`), so a box that stays low still
  starts the session after one `MEM_WAIT_MAX`. `verify()` gates each round before its clock and prompt; the initializer
  before `run_init`. `HARNESS_MEM_POLL=0` is read as 1 (0 never advanced the wait).
- **Rejected:**
  - **Re-rendering the prompt after the gate inside `session()`:** the clock would be right, but the deadline and a stop
    would still be ignored, and the attempt already spent.
  - **Re-gating after the loop starts over:** a box that stays under the bar would wait forever, which the gate's
    first choice (start anyway) rules out.
