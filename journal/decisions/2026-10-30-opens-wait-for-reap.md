# The coordinator opens no lane while a lane that exited is not reaped yet

*(2026-10-30, run `agent-harness-2026-10-30`, F1-03; plan `docs/plans/2026-10-30-F1-flakes.md`, the `47-lanes-two`
row; builds on `decisions/2026-10-29-lane-count-end-check`)*

- **Finding:** `47-lanes-two`'s `lanes admission: with the five-hour window at 80 % …` went red under `--repeat 10`
  (copy 9 of 10). Its `u5` log read `lane M2 opened (slot 0, …, slot reused)` at 17:58:03, then C's session, then
  `lane M1 closed (M1 merged)` at 17:58:04. The opens in the coordinator loop (`lib/driver.sh`) count lanes by their
  live pid (`a=$(lanes_open)`, and `lane_open`'s slot choice). A lane that exits after the poll's `reap` (M1's, just
  after it merged itself) frees its slot and its admit count before `reap` has noted it: M2 is admitted as `0 open`
  (which skips the five-hour and memory gates) into M1's slot, and M1's close, its end reason (`lanes-end`: a session
  cap, a usage limit, feature-list edits) and the merges it unblocked are seen only after M2's lane has started a
  session. R1-07's skip covered the exited lane's own milestone, not another one taking its place.
- **Choice:** an open stops for the poll when a lane exited since the reap: the opens go on only while every lane
  with a pid file is alive (`lanes_held`, the pid files, equals `lanes_open`). The next poll (at once: the exit wakes
  `lane_wait`) reaps it, notes its close and its end, and opens then. The run's end check counts held lanes, not live
  ones, so an open stopped this way never ends the run (the R1-04 race). Checked forced: a run of its own, `uh` (`u5`'s
  five-hour window), starts with `HARNESS_COUNT_HOLD=1`, which holds the coordinator after its count until M1 has
  exited, so the exit lands before the opens every time: `lanes admission: a lane that exits after the coordinator's
  reap is noted closed (its slot free) before another lane opens; M2's session after it` (47), red before (`lane M2
  opened` above `lane M1 closed`), green after. `u5` stays unheld, so its `noted once` still spans four polls.
- **Rejected:** a `reap` inside the opens loop (it runs `merge_milestones` mid-loop, under the list `F lanes` already
  gave, and the window moves to after it); counting held lanes in `admit` and `lane_open` but going on with the opens
  (a lane would open beside an exited one whose end, a usage limit say, isn't noted yet); a check that compares M2's
  open with M1's merge instead of its close (loosens the check: the order it asserts is the one the driver got wrong).
