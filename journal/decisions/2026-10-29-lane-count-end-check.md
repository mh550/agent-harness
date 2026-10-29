# The coordinator ends a run only when the lane count its opens used saw no lane

*(2026-10-29, run `agent-harness-2026-10-29-2`, R1-04; spec `docs/specs/2026-10-28-reliability.md` §R1 item 5, plan
`docs/plans/2026-10-29-R1-flakes.md`)*

- **Finding:** the flakes of `44-lanes-record` (`fatal: Not a valid object name harness-lane/rec/M2`) and
  `46-lanes-continue` (the `lc` run) were one race in the coordinator loop (`lib/driver.sh`). It counts the live
  lanes (`alive=$(lanes_open)`), offers opens only while `alive < MAX_LANES`, then ends the run when nothing opened
  and `$(lanes_open) == 0`, a second count. A lane that exits between the two (M1's, right after it merged itself)
  was counted as holding the one slot, so nothing was offered, and then as gone, so the run ended `no feature left to
  try` with M2 ready to open. 46's red copy under `--repeat 10` (9/10 green) logged `M1 merged into main`, `no
  feature left to try: 2/3 passing`, `lane M1 closed (M1 merged)` in that order; 44 forced the same way ends the same
  way and fails its two checks with the same `fatal:` line. U2-06's fix (2026-10-28: a second `reap` and a recount before
  the opens) narrowed the window to these few lines; it did not close it.
- **Choice:** the end check also needs `alive == 0`: the run ends only when the count the opens used saw no lane and
  none is open now. A lane gone since the count is reaped at the next poll (at once: its exit wakes `lane_wait`), and
  what it unblocked opens then. `HARNESS_COUNT_HOLD=1` (tests only, like `HARNESS_RECORD_DELAY`; `bin/harness` passes
  it) holds the coordinator after the count until the counted lanes are gone, so a check lands the exit in the window
  every time: `lanes run: a lane that exits between the coordinator's lane count and its end check doesn't end the
  run (M2 opens, done)` (`tests/checks/45-lanes-run.sh`), red before the fix, green after.
- **Rejected:** one more `reap` just before the end check (the window moves, it doesn't close); a sleep or a retry
  of the end check (a clock assumption in the driver).
