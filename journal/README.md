# Journal — how I learned to drive long-running agents

This journal records the **meta-engineering**: how I went from prompting one model to designing the
system that drives many agent sessions. The app is the case study, mostly *Pathways* (a DJ
companion), plus *dj-crate-streaming* and *hit_list*. The deliverables live in those repos. This
journal holds the thinking: what I tried, why, what broke, and what I changed.

It feeds three things: the **level-up interview** at work, a **portfolio case study**, and short
**write-ups for job applications and connections**.

## Structure

| Path | What it holds | Who writes it |
|---|---|---|
| `iterations/NN-<name>.md` | One file per iteration of *how agents were driven*: context, trigger, design, prompts, evidence, what broke, what it led to | me + Claude, after each change of approach |
| `iterations/NN-*-files/` | Snapshot of an iteration's actual artifacts (runbooks, prompts, scripts) when they no longer exist in the repo | copied at the moment they are replaced |
| `decisions.md` | Decision log: one entry per non-obvious choice (options, choice, why, how to undo) | whenever a design choice is made |
| `evidence/timeline.md` | Dated table of every session or run, with real numbers | refreshed by an agent from git and docs |
| `evidence/prompts/` | The prompts that changed the outcome, verbatim, each with its "why it matters" | added as they happen |
| `sessions/` | Verbatim transcript excerpts of design conversations (my messages, the key answers) | after a design conversation |
| `runs/` | One evaluation per harness run (delivery, failures by cause, guards, cost) plus a cross-run evaluation per night | after each run (the harness writes the metrics) |
| `raw/` | Local, git-ignored raw material (transcript copies, screenshots) | never published as is |

## The iterations so far

| # | Name | Dates | One line |
|---|---|---|---|
| 0 | [Direct implementation](iterations/00-direct-implementation.md) | Sep 2026 | Fable writes and tests the code itself in long sessions; spec files in `ideas/` already guide it |
| 1 | [Spec + overnight loop](iterations/01-spec-and-overnight-loop.md) | 13–15 Oct | One unattended `/loop` session per night, `OVERNIGHT.md` as its memory, superpowers discipline |
| 2 | [Orchestrator + subagents](iterations/02-orchestrator-and-subagents.md) | 15–16 Oct | The main session only orchestrates; Opus implements, Sonnet verifies, Opus reviews; context stays small |
| 3 | [Harness v1](iterations/03-harness-v1.md) | 16 Oct | After Anthropic's "effective harnesses": initializer + one fresh session per feature, inside the app repo |
| 4 | [Harness v2](iterations/04-harness-v2.md) | 16 Oct | A reusable tool: worktrees, a deterministic driver, repair not stop, verify gates, PRs, phone steering, metrics |
| 5 | [Harness v3](iterations/05-harness-v3.md) | 17 Oct | Merges verified milestones itself, waits out limits box-wide, queues nights, measures and retros every run into a ledger |
| 6 | [The harness maintains itself](iterations/06-the-harness-maintains-itself.md) | 23–25 Oct | A week of v3 nights silted up (224 of 520 passing features merged, 10 OOM kills, 404 permission rules): discovery → one root cause → clean up once by hand *and* change the harness so it stays clean |

## How to keep it (the habit)

1. **When the approach changes, write the iteration file before the new approach runs.** The
   trigger and the expectation are only honest before the results exist. Add the results after.
2. **Save the prompt that caused the change, verbatim** (`evidence/prompts/`). Prompts are the
   most persuasive evidence of how I think. Say in two lines why each one mattered.
3. **Log decisions** in `decisions.md` with the rejected options. Judgment shows in what was *not* chosen.
4. **Let the harness measure.** Each run commits `metrics.jsonl` (sessions, cost, duration, turns,
   passes per model). After a run, write a five-line retro in `runs/<run-id>.md`: what got done, what
   broke, what I changed in the harness because of it.
5. **Keep numbers real.** Tests before → after, features passed, sessions, $ per feature, human
   interventions per night. A claim without a number goes in as *(inferred)*.
6. **Keep transcripts.** Claude Code deletes local transcripts after 30 days unless
   `cleanupPeriodDays` is raised in `~/.claude/settings.json`. Copy the ones that matter into `raw/`.

## Turning it into resources

- **Interview (10–15 min):** a story with a clear arc:
  1. The problem: building a real app with agents, and the limits I hit (context, usage, permissions).
  2. The iterations, each with its trigger and a metric. Iteration 6 ends with a ready two-minute version: a
     system that silted up, one root cause, and a cleanup that also fixed the harness.
  3. A live look at a run: `harness status`, the PR, `metrics.jsonl`.
  4. What I'd do next.
  Source: the iteration files' "Trigger" and "Evidence" sections.
- **Portfolio case study:** a page that shows the system and the thinking. It has:
  - a diagram per iteration;
  - before/after numbers;
  - three prompts verbatim, with commentary;
  - the decision log as "judgment calls";
  - a link to the harness repo.
- **Job apps / connections:** one paragraph plus the link to that page.
- **Before publishing:** sanitize. Strip personal paths, hostnames, track libraries if wanted, and
  anything from `raw/`. Keep the repos private until then.
