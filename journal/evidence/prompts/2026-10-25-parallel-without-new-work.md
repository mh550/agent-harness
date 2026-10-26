# 2026-10-25 22:00: "a system that doesn't create more work", with memory by CoALA bucket and scope

- **Date:** 2026-10-25 22:00 and 22:03 EDT, a new session in `~/projects`. The design (PR #22) merged at 22:27.
- **Source:** that session's transcript, my two messages verbatim. The pasted harness status is cut.
- **Iteration:** 7
- **Why it matters:**
  - It turned a speed-up into a design brief with **anti-goals**. A hand-fixed merge conflict, an orphaned worktree,
    branch or piece of data each counts as a failure even if the code works. The design copied them almost word for
    word into its §2, and every mechanism was then checked against them. Slots and lane branches exist only while
    they're needed. Every unit is named so the existing `gc` cleans it up. Merging after `main` moves needs no human.
  - It asked for memory as architecture: in place or ledger, CoALA bucket and scope, "an architecture that will grow
    with me". That produced the bucket × scope table, in which every store has one kind of writer and one mutation rule.
  - The 22:03 follow-up made the plan part of the job: the order of the changes, the runs in flight, and what to
    prepare now. That is why the rollout plan and my decisions came with the design, not after it.

## Verbatim

> Ok, I'd like to make some changes to the harness. L3 of the 'lifecycle' harness self-improvement run is in progress,
> and at 18/25 passing. I'd like to implement your recommendations before the next 2 runs of the agent harness begin.
>
> <harness_status> […] </harness_status>
>
> Let's implement the changes outlined in the previous message-- but I'd like you to also ensure for yourself as you
> decide what changes to make, that the system is in line with my thoughts. I want a more parallelized system, I want
> to remove redundancy, and increase the overall speed & throughput of my agent harness. I want a system that doesn't
> create more work-- so avoids messy manually-fixed merge conflicts, orphaned worktrees and branches, and orphaned
> data. But I want to parallelize what makes sense. Maybe that's just on the milestone level, or maybe we also
> parallelize individual tasks within a milestone as well. Also, consider how we should adjust testing to be more
> targeted. Maybe this can be more asyncronous with the worker agents, or this can be done for sets of tasks like the
> message talks about, or maybe both/something else.
>
> Consider good memory design for Agents-- choosing carefully what should be in-place edits vs a ledger, following
> principles from CoALA-- separating memory into its corresponding bucket (like semantic/episodic/etc), tying it to the
> right scope (user, project, run, session, supervisor, etc) and treating it appropriately. Be thorough and pick
> carefully, as to create an architecture that will grow with me.

> Another note: you should make a plan, consider the ordering of how we should apply the changes and what needs to
> happen to the harness runs to get to that state where we're ready to apply the changes, etc. Also consider the
> context of the agent-harness: the current self-improvement runs in the queue and running, and what's on the roadmap.
>
> Consider if what we can prepare now, to minimize the turnaround and get back to the next-in-queue items in the
> harness with your revisions applied.

## What came back

The design rejected two of the options I had floated, and said why. Features inside a milestone stay serial: the
design names what would make them safe later. The asynchronous post-session suite was rejected because, once a later
session builds on a tree, it's no longer clear which session broke it. Lanes give the same overlap across milestones
without that cost.

> result: Design and rollout plan for parallel milestone lanes, a split parallel suite and a scoped memory model are
> merged to agent-harness main (PR #22), awaiting your approval; tonight park the retro and memory queue entries so
> nothing starts when the lifecycle run ends.
