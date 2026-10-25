# 2026-10-24 (afternoon): "a sensible context window for each set of steps" and "a worker per project"

- **Date:** 2026-10-24, in the same session as [the four meta issues](2026-10-24-four-meta-issues.md). The go-ahead
  came at 13:04, after the six-step plan. The other two (13:24 and 13:26) were typed while the session was still
  working, queued mid-turn. Step 1 merged at 13:12 (PR #11) and step 3 at 13:39 (PR #12).
- **Source:** the saved terminal transcript `~/projects/2026-10-24-233454-what-is-the-state-of-the-harness-improvement-rela.txt`
  (lines 296–298, 378–390; wrapping joined, words unchanged)
- **Iteration:** 6
- **Why it matters:**
  - These prompts set the *shape* of the work, not its content. I stopped one long session at a natural point and
    asked for work cut to fit a context window, with a limit per chunk. The result was
    `docs/plans/2026-10-24-handoff.md`: five chunks, each one fresh session or one sitting of mine, ticked on `main`.
  - The second prompt asked how to bring seven projects up to the new model and left the method open (subagents,
    me pasting a command, or the harness). The answer was one worker per project, launched by me, with one shared
    prompt (`prompts/project-catchup.md`). Subagents can't ask me anything, and a harness run costs $10+ before any
    merge.

## Verbatim

The go-ahead, after the six-step plan:

> Go ahead with step 1, and the proceed with the rest of the steps-- delegating steps to me that I need to do, and
> doing the steps yourself that you're able to do.

Mid-way through step 3:

> Come to a natural stopping point, to handoff to the next agent to continue implementation. Maybe even set a limit
> for the next agent, in a sensible chunk. I want to have a sensible context window for each set of steps the agent
> is instructed to do.

> Part of the work should also be to get the projects up to speed with our new model-- so maybe we have a worker per
> project to go through, handle the merges & ensure each project is up to speed before we go through implementation
> again. Consider the best way to accomplish this-- delegating to subagents, or me pasting a command into each
> channel. I feel like the harness is off limits for this until we get it fully back up to speed, but that's also on
> the table potentially.

## What came back (the session's result line)

> result: The harness is caught up and the rest of the work is handed off in five chunks: stranded work merged (PR
> #11), auto-sync and visible parking live (PR #12, suite 236/236), and the plan plus a per-project catch-up prompt in
> docs/plans/2026-10-24-handoff.md, starting with Chunk 1 (the permissions policy files).
