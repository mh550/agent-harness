# Admission by headroom: a second lane (and later a second run) opens when the box and the plan have room for it

*(2026-10-27, run agent-harness-2026-10-26, feature P2-02; spec `docs/specs/2026-10-26-lanes.md` P2 item 1, plan
`docs/plans/2026-10-26-P2-two-lanes.md` §2. Supersedes D-H18's reason for serial runs, in `journal/decisions.md`.)*

- **Finding:** D-H18 made runs serial on 2026-10-17, when two parallel runs spent the five-hour window in 2 h 49 min.
  2026-10-25's figures (`docs/specs/2026-10-25-throughput-and-memory-design.md`) show several times that headroom: the
  five-hour window at 12 % and the seven-day window 82 → 83 % in 4.5 h of runs. Usage is no longer what limits a
  night; memory and a fixed one-lane rule are. A fixed count can't tell a quiet window from a busy one either way.
- **Choice:** admission is by headroom, checked before each open and retried every poll:
  - lanes alive `< MAX_LANES` (the configuration: no note when it is the reason);
  - `MemAvailable ≥ MEM_MIN_AVAILABLE_GB + LANE_RESERVE_GB × lanes alive` (`scope.sh`'s reader; unreadable → not
    tested, as `mem_gate`);
  - when the newest session reported a five-hour window (`USAGE_5H`, `<utilization 0..1> <reset epoch>`, written
    beside `USAGE_7D` by `metrics.mjs usage <log> five_hour`) that hasn't reset, its utilization under
    `LANE_OPEN_BELOW_5H` (70 %).
  - A refusal is `lane <m> waiting: <reason>` once per kind (memory, five-hour), e.g. `lane M2 waiting: 7 GB available,
    under 9 GB (MEM_MIN_AVAILABLE_GB 5 + LANE_RESERVE_GB 4 x 1 open)` or `lane M2 waiting: 5-hour window at 80%, opens
    under 70% (resets 14:05)`. The first lane always opens (`admit` with 0 open): its own `mem_gate` and `limit_wait`
    handle a short box, and a refusal there could stall the run for good.
  - `MAX_LANES` stays 1 in code; Michael's config sets 2. `MAX_PARALLEL_RUNS=2` waits for a night at two lanes that
    shows the headroom (two runs × two lanes is four sessions' memory).
- **Defaults taken** (Michael's to change): `LANE_RESERVE_GB=4` (a session's `SESSION_MEMORY_HIGH` plus a suite) and
  `LANE_OPEN_BELOW_5H=70` (a second lane at 70 % would spend the rest of the window in well under its 5 h).
- **Rejected:**
  - Keeping serial (D-H18 as it was): the 2026-10-25 figures show the window unused most nights.
  - A fixed `MAX_LANES` with no test: one busy window (a debrief, Michael's own sessions) and two lanes hit the limit
    together; one lean box and two suites hit the memory cap.
  - Refusing the first lane too: the run would wait with nothing open and no session to report a fresh window.
  - The seven-day window as an admission test: it moves about 1 % in 4.5 h; the weekly gate (`WEEKLY_STOP_AT`)
    already stops runs near its end.
