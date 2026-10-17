# 2026-10-16: Pathways OVERNIGHT-3 — Michael's §11 answers and the orchestration rules

- **Date:** 2026-10-16 (runbook commit `cd3eacb`, 09:44)
- **Project:** pathways
- **Source:** `pathways/OVERNIGHT.md` at `cd3eacb` ("Direction from Michael", "Orchestration"); design amendments in
  `docs/specs/2026-10-14-threads-and-graphs-design.md` §12
- **Iteration:** 2 (orchestrator + subagents), the version written as a runbook
- **Why it matters:** the clearest written form of iteration 2. Michael answers the design questions himself
  (the answers about the product idea are quoted word for word), and asks for implementation, testing and review
  to be delegated. The runbook turns that into roles, models and a "keep your own context small" rule. It was never
  run as a loop: `889f5fe` (21:11 the same day) replaced the loop with the harness.

## Michael's answers (verbatim, as recorded)

> - **2026-10-16 (before the loop), answers to the design doc's §11:**
>   1. "I don't know what the database design should be. The user should be able to have threads,
>      and view pathways / graphs without threads. The thread would be a more saturated/global
>      version of a set of edges in a graph, whose data is persisted across pathways." → D20, D22.
>   2. "A thread is a set at its core, but could carry a canonical walk. There is some ordering
>      inherent in the thread, but it's rather dynamic and flexible." → D21.
>   3. Yes (delete thread = memberships only).
>   4. "The normal eventual flow will not be import-based — I will be creating threads within the
>      app itself. So we don't need to worry about creating threads from the import at all." → T2 dropped.
>   5. "A pathway is just a path through the graph. I don't think we'd be adding new pathways —
>      rather, we'd be adding songs and threads — sometimes converting groups of songs into
>      threads. As I brainstorm I have a natural ordering to the songs that come to mind. So the
>      original creation of the thread has an ordering inspiring it, but its core ideas are
>      unordered." → D21 (songs in brainstorm order), naming collision noted in `docs/naming-options.md`.
>   6. Agreed with the default (context from touching threads only). → D23.
>   7. "I don't really see us exporting a pathway. I see the most common flow of us adding a graph
>      to Navidrome. Or vice versa. Maybe we find a way to sync them." → D24, T6 rewritten.
>   8. "Help me brainstorm different naming options for the terminology across the whole
>      application." → `docs/naming-options.md` (five option sets; recommended: song · link ·
>      thread · map · path/set).
>   Also: T6 drops first; "What Michael will see" after T4 and T5; implementation, testing and
>   review delegated to subagents.

## The orchestration section it produced (runbook text, verbatim)

> ### Orchestration (this session is the orchestrator)
>
> - Keep your own context small. **Implementation** → one Opus subagent per milestone (or per
>   independent task) with a written spec in the scratchpad: goal, files to read first, exact
>   behaviour, tests to write first, what not to touch, a timebox, report ≤ 300 words.
> - **Testing and verification** (headless Chromium passes, replay checks, real-data runs) → a
>   Sonnet subagent told what to test and why, what PASS looks like, the scratch DB
>   (`PATHWAYS_DB=/tmp/pathways-o3/<milestone>.db`) and port (`7791`+, never 7777).
> - **Code review and the four `/simplify` angles** → Opus reviewers that read the diff from a
>   file in the scratchpad (`git diff <milestone-start>..HEAD > scratchpad/t<n>.diff`) and return
>   findings only.
> - Independent agents run in parallel in one message; never two agents on the same files.
>   Do not read large diffs, transcripts or screenshots yourself when an agent can report the
>   conclusion. Verify every claim with one cheap command (`npm run check`, `git status`, a grep)
>   before ticking a box.

## What replaced it the same day (`889f5fe`, for context only; iteration 3 is out of scope)

> **Driver (changed 2026-10-16): the long-running harness in `harness/`**, after Anthropic's
> ["Effective harnesses for long-running agents"](…), replaces the self-paced `/loop`.
