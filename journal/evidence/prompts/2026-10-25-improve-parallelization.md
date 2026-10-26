# 2026-10-25 16:25: "Is there any way we can improve the parallelization of the tasks"

- **Date:** 2026-10-25 16:25 EDT. It was my third message in a session in `~` that had begun as a status check
  (14:23); the answer came at 16:32.
- **Source:** that session's transcript, my message verbatim.
- **Iteration:** 7
- **Why it matters:**
  - I asked for speed, but with two conditions: principles "that scale and would work into the future", and no
    "duplicate/cleanup work". Those conditions came straight out of iteration 6, where quick fixes had left branches,
    worktrees and processes behind.
  - The question was open, so the answer could start with measurement. I expected the answer to be "run more runs in
    parallel". The session timed the suite and checked the usage windows instead, and found that the bottleneck was
    the harness's own 8-minute test suite and its serial driver. Raising the parallel-run setting would have changed
    nothing.

## Verbatim

> Is there any way we can improve the parallelization of the tasks, in order to speed up the next 3 projects? Be
> thorough-- considering good design principles that scale and would work into the future on future harness runs, and
> avoid creating duplicate/cleanup work.

## What came back

> Yes, but changing the queue or the parallel-run setting won't help. The real gain is inside each run, and the safe
> order matters more than any single change. Nothing was changed: I only read files.

It ended with a recommended order (split the suite, run lanes inside a run, two runs at once after L5) and a question
back to me: lanes before the memory run, or after it?

> result: Inside each run the driver and the 8-minute single-threaded suite are the bottleneck, not usage limits;
> recommended order is lifecycle → suite-split run → retro → memory, with parallel milestone lanes as the scalable
> follow-up.
