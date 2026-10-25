# 2026-10-24 (late morning): "consider the meta issues that caused this, and how to address them"

- **Date:** 2026-10-24, 12:55 EDT, in an interactive session in `~/projects`. It came an hour after "What is the
  state of the harness-improvement-related harness runs…? What's blocked? What's not?" (11:52), and after the
  resource audit (12:30) and the memory-model spec (12:39) had been started in other sessions.
- **Source:** the saved terminal transcript `~/projects/2026-10-24-233454-what-is-the-state-of-the-harness-improvement-rela.txt`
  (lines 77–118; the terminal's line wrapping is joined here, words unchanged)
- **Iteration:** 6 (the harness maintains itself). This is the prompt that turned a status check into a redesign.
- **Why it matters:**
  - I didn't ask for four fixes. I named four symptoms from my own use (retros in the wrong place, worktrees blocking
    writes, permission sprawl, memory), pointed at the evidence (the resource audit, the memory-model spec), and
    asked for the cause behind them and "a clear, actionable path forward… one at a time".
  - The answer, "almost nothing reaches main, or the running harness, unless you carry it there by hand", reframed
    all four as one problem. Step 1 of its plan (save stranded work, sync the live harness) came before any fix, so
    every fix built on current code.

## Verbatim

> Ok, I'd like you to consider the meta issues that caused this, and how to address them. Here's some thoughts to
> start:
> 1. The 'retro' notes are helpful, but I feel like they live in the wrong place, potentially-- as they live with the
>    run itself, instead of writing to shared memory location that relates to the harness itself.
> 2. I'm not sure if the worktrees directive is helpful. It constantly denies my agent writing into the harness
>    folder-- for example, I had an agent do a system usage audit, and it wasn't able to write to
>    harness/findings-and-research, and instead had to write to a worktree. See
>    ~/projects/agent-harness/.claude/worktrees/resource-audit/findings-and-research/2026-10-24-system-resource-audit.md
>    for the full audit results. This is also important to the rest of the task, as the audit brings up memory usage,
>    test cleanup, and other key concepts.
> 3. I'm not sure that the permissions model setup is helpful-- with one .claude per project folder, in addition to
>    the user folder-- and there's a ton of commands in each project's allowlist and denylist. A single deny to a key
>    setup step has stopped runs, like the n8n run recently. I want the permissions model to be much more permissive--
>    even for 'production'-facing repos, since I'm the only user for most of them. The only projects that are truly
>    'production' are need a human verification gate before deployment are my portfolio site and the n8n site. But
>    even then, I think I want to allow my agent to handle merges & git as a whole, as long as the action it's making
>    is not deleting history that can't be recovered-- and thus truly destructive. But I want branch cleanup,
>    automated merges (with or without PRs), and other steps to be handled easily, without running into permissions
>    bottlenecks.
> 4. This relates to the other points, as well. But I want to look into the helpfulness of the current memory model,
>    and improving it going forward. Check the writeup that is linked in this message, and factor memory into your
>    analysis of what's failing, and how we should proceed. <message>The spec is at
>    docs/specs/2026-10-24-memory-model.md on branch worktree-memory-model-spec (pushed; it's the only change, no PR
>    opened). To read it: git show origin/worktree-memory-model-spec:docs/specs/2026-10-24-memory-model.md.
>
>    result: Memory-model spec (K1–K4: one routing block, gotchas kept in place, a memory lint, a one-time project
>    tidy) written and pushed on branch worktree-memory-model-spec; waiting on approval and on whether K1–K3 join the
>    retro follow-ups run.</message>
>
> Consider how this relates to the in-queue harness improvement runs, the most recently completed harness improvement
> run, and recent run failures & limitations. Then, give me a clear, actionable path forward to address my most
> pressing issues, one at a time.

## What came back (the session's result line)

> result: Most of the harness work never reaches main or the running harness, because every handoff waits on you
> (retros, findings, specs, parked queue entries, merges, pulls) and a deny anywhere blocks everything (n8n died on a
> project-level docker compose deny). The live harness is 109 commits behind origin/main, and the retro-fixes, hygiene
> and n8n-events runs sit unseen in queue/held/. Proposed six steps: save the stranded work and sync, one permissions
> policy, close the merge loop, resource cgroups, the retro-fixes run, then one consolidated memory spec.
