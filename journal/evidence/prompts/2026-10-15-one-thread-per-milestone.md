# 2026-10-15 ~08:50: "context usage too high" → one thread per milestone

- **Date:** 2026-10-15 ~08:50 EDT
- **Project:** dj-crate-streaming (ON2)
- **Source:** `~/projects/OVERNIGHT-2.md` "Direction from Michael" + "Pacing"; `~/projects/HANDOFF-M4.md`
  (`4802009`), `HANDOFF-M5.md` (`1509b33`), `HANDOFF-M6.md` (`a6a8c91`, refreshed `478480f`, `6ff96e9`)
- **Iteration:** between 1 and 2 (call it 1.5): same loop and runbook, but each milestone runs in a fresh thread
  started from a handoff file
- **Why it matters:** this is the first recorded context-window problem and Michael's first structural answer to
  it. The fix is still one agent doing everything, but its life ends at each milestone, and an agent-written
  handoff carries the "hard-won facts" across.

## Verbatim, as recorded (ON2)

> - **2026-10-15 ~08:50 (Michael, in the session):** context usage too high. **New protocol: one thread per
>   milestone.** Each thread ends its milestone by writing a handoff prompt (`~/projects/HANDOFF-M<next>.md`),
>   committing and pushing it, and stopping the loop. The first one is `HANDOFF-M4.md` (M4 step 1 done; step 2 next).

ON2 Pacing (added the same morning):

> - **One thread per milestone (Michael, 2026-10-15):** after a milestone's review, `/simplify`, milestone
>   push and notification, write `~/projects/HANDOFF-M<next>.md` (start here / where things stand with branch
>   heads and the next unchecked step / hard-won facts / open questions / this protocol), commit + push,
>   stop the loop, and tell Michael which file to paste into a new thread.

## The handoff as a prompt (HANDOFF-M4.md, opening)

> You are a Claude Code session on Michael's Pop!_OS box, continuing an unattended runbook. The previous
> thread ran out of context after completing M0–M3 and the first M4 step. **One thread per milestone** is
> now the protocol (see the end of this file).

and its last "Start here" step:

> 4. Start the loop: `/loop Follow ~/projects/OVERNIGHT-2.md: re-read it, do the next unchecked step, tick it, log it, commit.`

## A rule carried in every handoff (HANDOFF-M4, -M5, -M6 "Hard-won facts")

> - **Reviews:** dispatch the whole-milestone review with `Agent(model="opus")` (Sonnet if Opus is rate
>   limited, and say so); then `/simplify` (4 parallel agents). … Every Opus review so far found real
>   bugs, two of them live damage; don't skip it.
