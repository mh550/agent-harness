# 2026-10-26 12:55: "sensible defaults around time limits, that won't stop future runs"

- **Date:** 2026-10-26 12:55 EDT, in the design session. The answer came at 12:59, and the master to-do gained its
  "UPDATE 13:10" section.
- **Source:** that session's transcript, my message verbatim. The pasted 10:15 status is cut; its gist is in
  [the session record](../../sessions/2026-10-25-throughput-design.md) §4.
- **Iteration:** 7
- **Why it matters:**
  - The lanes run had blocked at 2/17 on one acceptance number, and I asked for two things: unblock this run, and
    find a rule so no run blocks this way again. The rule: **a performance number in a step is "measured and
    recorded", never a gate, unless it protects the box.** Hard limits that protect the box (session time, suite
    time, attempts) stay. Soft targets become measurements.
  - I asked about the knock-on effect, not just the block. The retro run had started on the old suite layout. The
    answer found a four-file conflict that would have ended the lanes verify "needs Michael", and a queue order
    (memory next) that would have collided with lanes' rewrite of the driver. Both were fixed before they happened.

## Verbatim

> A status update from the harness this morning, that I ran about 3 hours ago, showed this. <status> […] </status>
>
> How should I proceed? The retro run has probably made more progress. I want to ensure the rest of the lanes run gets
> unblocked and we have sensible defaults around time limits, that won't stop future runs but also help ensure our
> agent's testing framework is not running for an absurd amount of time. What's the best way to accomplish this? How
> should we handle the running retro run, which relied on changes that should've been completed by the lanes run? How
> do we rectify this?

## What came back

> The hard guards already exist and stayed out of the way: 100 minutes per session, 15 minutes per suite run, two
> attempts per feature. The problem was a soft target written as a gate.

The three changes go into the continuation's brief, so no new run is needed:
- the initializer rule above;
- `TEST_FILE_TIMEOUT=10m` per test file, so a hung file is one FAIL line rather than a 15-minute suite;
- a driver note of how many times, and for how long, the suite ran in each session.

> result: Lanes blocked only on a soft 150 s target written as a gate; park memory now, then after retro ends a
> 30-minute branch fix resolves the four-file conflict and rewords P0-02, and the continuation plus memory run
> unattended; commands are in the todo's new top section.
