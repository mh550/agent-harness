# `harness eval probes` asks a tool-less session the handoff questions a task's record answers, scored by match

*(2026-10-21, E2-06 of run agent-harness-2026-10-21-measure; plan `docs/plans/2026-10-21-E2-evals.md` §5; builds on
`decisions/2026-10-21-eval-run-isolation`)*

- **Finding:** pass rate and cost say whether a harness version gets work done, not whether its handoff (the prompt,
  progress.md, the record a fresh session starts from) tells the next session what it needs. E3 and E4 change exactly
  that, so it needs a measure of its own that is cheap and deterministic. A probe that sees anything but the handoff
  (tools to read the repo, a prompt rebuilt by hand) measures something else, and a hand copy of the driver's prompt
  assembly would drift from it.
- **Choice:** the driver's prompt assembly moves to `lib/prompt.sh` (`prompt_vars`, `prompt_env`, `prompt_render`,
  sourced by the driver, no prompt byte changed); run as `lib/prompt.sh <state dir> <template> <feature>` it renders a
  run's prompt the way its driver would. `harness eval run` saves, per task, `commits.json` (the run branch's commits
  and files since base, from the clone) and `probe-prompt.md` (the coding prompt of the task's next feature: the first
  not passing, else the last; rendered by the **ref's own** `lib/prompt.sh` with the runs' environment while its
  worktree exists). `harness eval probes <task result dir>` derives questions with the pure `questions()` of
  `lib/eval.mjs`: which files each other feature changed (its `<id>:` commits, `.harness/runs/` left out), what the
  target depends on (`deps`: its `after`, or every feature before it), and what the last attempt at a feature failed
  on (asked when its last coding row that wasn't a limit or an outage didn't pass and didn't park; the key is the
  first sentence of that row's `final`, headings and markdown stripped, split only where a capital follows).
  One `PROBE_MODEL` session (default haiku) gets `# Probe session`, the saved prompt and the numbered questions, with
  `--max-turns 1 --tools "" --allowedTools "" --permission-mode dontAsk --strict-mcp-config --max-budget-usd 0.5`, in
  the run's worktree when it still exists (CLAUDE.md auto-loads, as for the real session), else in an empty temp dir
  (it says so), under `timeout 10m`. A session that exits non-zero, ends on an error result or answers nothing is
  not scored: the command exits 1 and the last probes.json stays. The pure `score()` matches each `Q<n>:` line (the
  last per number): exact (normalized equal; for lists the same items) or contains (every key item is one of the
  answer's items, so `F1` isn't found in `F10`; or the key sentence is in it) score 1, else miss. probes.json gets the questions, answers,
  matches, `score` `<n>/<m>`, model and cost; the command prints one line per question and `score <n>/<m>`.
  *Defaults:* the CLI takes the state dir only (its `meta.env` names the worktree), not the plan's
  `<worktree> <state dir>`; a result from a ref without `lib/prompt.sh` is refused rather than probed with today's
  prompt; probes don't check `EVAL_BUDGET_USD` (one capped turn).
  *Known gaps:* `{{INIT_OUTPUT}}` is the last init's (verify re-runs init after the last coding session), so that
  block can differ from the real handoff; the probe doesn't pass the driver's `--settings` (`AGENT_SETTINGS`), and
  user and project hooks still load. **Expect low scores today:** with no tools, the probe sees the template, the
  brief, CLAUDE.md and the policy, not progress.md, the feature list or git; E3 and E4 (context.md in the prompt)
  are what should raise them, so a near-0 baseline is the measurement, not a bug.
- **Rejected:** an LLM judge for the answers (v1 is deterministic, and a judge's own noise would swamp a 1-of-3
  change); rebuilding the prompt in `lib/eval.sh` (drifts from the driver; the E2-06 check compares it with the prompt
  the driver actually wrote); rendering with the invoking harness's templates (probes must judge the version that
  ran); giving the probe read-only tools (it would answer from the repo, not the handoff); reading the commits from
  the clone at probe time (`/tmp` may have lost it).
