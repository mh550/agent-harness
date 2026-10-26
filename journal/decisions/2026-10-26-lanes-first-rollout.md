# Lanes before the retro and memory runs, built by a harness run, with the suite split as its P0

*(2026-10-26 00:42, Michael, in chat; the design `docs/specs/2026-10-25-throughput-and-memory-design.md`, the rollout
`docs/plans/2026-10-25-throughput-rollout.md` "Decisions that are Michael's" 1, 2 and 4; amended 10-26 13:10 by
the master to-do's update)*

- **Finding:**
  - The 10-25 measurements showed that usage limits weren't the bottleneck. The bottleneck was the serial driver plus
    an 8-minute single-file suite.
  - The two queued runs both had independent milestones that the serial driver would run one at a time: retro (F1–F3)
    and memory (M1, M2, M5, M6).
  - Retro's F3 (R10) would have built a scheduling change that lanes replace.
  - `tests/run.sh` was the most-edited file in the repo, and every run adds checks to it.
- **Choice:**
  - **Order A:** suite split → lanes → retro (F1 ∥ F2) → memory (two lanes). This costs a night of calendar before
    retro and memory start, but both then run on lanes and on the fast suite, and retro shrinks to F1 and F2.
  - **Built by a harness run, not interactively.** The code is concurrency code (locks, child processes, git refs),
    and the harness's independent verify per milestone is the strongest review it can get.
  - **The suite split is P0 of the same run** (decided after the answers), so no human step sits between the
    lifecycle run's end and the lanes run.
  - **rane-one-mixxx-2026-10-24 is answered and continued first,** on the serial driver. Once lanes' P1 merges,
    `harness continue` refuses a run whose branch carries code.
  - **Amended 10-26 13:10:** the memory run waits for the lanes continuation (it was parked). Its M1 edits
    `lib/driver.sh`, which lanes' P1 rewrites, so the other order is a driver-wide merge conflict.
- **Rejected:**
  - **Order B** (retro and memory first on the serial driver, lanes after). It is one night sooner for those two runs,
    but R10 would be built only to be replaced, memory's four independent milestones would run serially, and both runs
    would add checks to the single file the split then has to absorb.
  - **Lanes as two interactive sessions.** Faster if I'm around, but no independent verify.
  - **The suite split as an interactive step the morning after.** It left a human in the loop at 02:00.
  - **Raising `MAX_PARALLEL_RUNS` as the speed-up.** All three runs are one project, and the queue allows one run per
    project (`decisions/2026-10-21-queue-one-run-per-project`).
- **What it cost:** lanes blocked on P0-02. My "about 2.5 minutes" target became a hard 150 s step. With lanes blocked,
  the queue ran retro on the old suite layout, which needed a branch fix (iteration 7, "What broke" 1–2). The order
  stands. The continuation fixes the step and adds the "measured and recorded" rule.
- **Undo:** unpark the memory entry ahead of the lanes continuation (accepting the driver conflict), or drop the
  continuation and run retro and memory on the serial driver. `MAX_LANES=1` is today's behaviour.
