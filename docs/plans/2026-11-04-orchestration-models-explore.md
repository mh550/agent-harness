You are a research session for agent-harness, Michael's harness for long-running coding agents. He starts you from
~/projects/agent-harness with `claude --model claude-fable-5-1 "$(cat docs/plans/2026-11-04-orchestration-models-explore.md)"`.

CLAUDE.md binds (the user's and this repo's): enter a worktree before writing anything (the live checkout is off
limits); never touch real runs or real state; never send a notification; no `harness` command but `status`, `report`,
`parked`, `sync`. Never read ~/.local/state/harness, ~/worktrees/*, ~/.config/harness, ledger/ or journal/raw/.
Committed run records under `.harness/runs/*/` (summary.json, metrics.jsonl, harness-log.md, retro.md) are yours to read.

## The question

Michael is moving toward "loop engineering": the whole build process agentic from end to end, reached in measured
steps. Today's design is a **deterministic bash driver around stateless headless sessions**:
- one fresh `claude -p` session per feature, with its state in files (feature_list.json, entries.jsonl, progress.md,
  context.md);
- an independent verify session per milestone, verified milestones merged through PRs, lanes for parallel milestones;
- a supervisor that is a human-started session, keeps its state in a Status table and hands Michael commands to paste.

He is weighing an alternative: **multi-turn agents that spawn subagents**. A long-lived supervisor gets an update as
each coding instance resolves, and coding instances spawn their own subagents (through bash) for triage,
implementation and verification. Answer, with evidence:

1. Speed: where does wall time actually go in this harness (sessions, the suite, usage-limit waits, merges), and which
   of it would each design change?
2. Accuracy: first-attempt pass rate, verify failures, rework. What does each design do to context rot, compounding
   errors, self-verification bias and conflicting decisions between agents?
3. Tokens and cost: re-orientation per fresh session vs context growth in a long-lived agent, prompt-cache effects,
   and subagent fan-out multiples. Use real numbers.
4. Reliability and operability: crash, limit and compaction recovery; reproducibility; whether it can be tested with
   stubs the way `tests/` tests the driver; human gates on irreversible actions; visibility (`harness status`, cards).
5. What top teams currently consider best practice, and why: Anthropic, OpenAI, Cognition, LangChain, Google and
   others; papers if any measure this.
6. "Stateful single-turn" (each LLM call stateless, the state in files, the loop in code) vs a multi-turn stateful
   agent: compare them on 1–4.
7. Subagents spawned through bash (`claude -p` from inside a session) vs Claude Code's built-in subagents vs sessions
   the driver spawns: what each sees, what the harness can account for and guard (cost rows, usage-limit waits, memory
   scopes, `restrict`, `lane_guard`), and what it costs.

## Read first

- `docs/architecture.md` (the system as it is) and `README.md`.
- `journal/iterations/02-orchestrator-and-subagents.md` (Michael already ran a multi-turn orchestrator with subagents,
  15–16 Oct: what worked and what broke), `03-harness-v1.md`, `04-harness-v2.md`, and the newest iteration file.
- `journal/sessions/2026-11-04-loop-engineering-design.md` (the conversation this question came from, its concepts
  list, and the planned steps F1–F3: fix loop, triage, memory curator).
- `docs/plans/2026-11-03-test-suite-redesign-supervisor.md` and the Status table in
  `docs/plans/2026-11-03-test-suite-redesign-dispatch.md` (how the supervisor works today).
- `findings-and-research/` for earlier research on supervision layers and memory (`Coding agent supervision layers.md`,
  `Agent Memory Field Guide.md`); don't repeat them, build on them.
- This repo's numbers: `.harness/runs/*/summary.json` (cost by role, tokens, cache hit rate, orientation, rework,
  first-attempt pass rate) and the suite-time findings (`findings-and-research/2026-11-03-redesign-baseline.md`,
  `2026-11-03-suite-tiers.md`).

## Research

Search the web, starting with "standard" searches and using "extended" for the newest material. Prefer primary
sources: engineering posts and papers, not summaries. Starting points, which you must check are current and not
rely on from memory: Anthropic's "Building effective agents", "How we built our multi-agent research system",
"Effective harnesses for long-running agents" and its context-engineering post; Cognition's "Don't build
multi-agents"; OpenAI's agent-building guide; and any 2026 work on long-horizon coding agents, agent orchestration or
self-improving harnesses. For every claim, give the source URL and its date. Mark anything you infer *(inferred)*.

## Deliverable

`findings-and-research/2026-11-<dd>-orchestration-models.md` (today's date), under 400 lines, merged by PR titled
"findings: orchestration models for loop engineering" (`gh pr merge --merge`), then delete the branch and remove your
worktree. It contains:
1. A comparison table of the designs against questions 1–4 and 6 (this harness today; a long-lived multi-turn
   supervisor; coding sessions with bash-spawned subagents; coding sessions with built-in subagents; a hybrid), each
   cell with a number or a source.
2. What best practice says and where the sources disagree.
3. A recommendation for this harness's next steps toward loop engineering, ordered and each small enough for one
   harness run, saying which F1–F3 steps it changes. Include whether the supervisor should become event-driven (the
   harness invoking a short stateless supervisor session on each milestone event) and which of its actions stay
   Michael's.
4. One experiment that would measure the difference on this repo, with its predictions, in the shape of the
   Predictions tables in `docs/specs/2026-11-03-*.md`.

Rules: research and write only. Change nothing under lib/, bin/, tests/, prompts/ or templates/. Report at the end:
the file's path, the PR number and your recommendation in five lines.
