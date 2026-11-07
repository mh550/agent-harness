# Decision log — harness design

One entry per non-obvious choice: options considered, the choice, why, and how to undo it.
### D-H1 · Fresh session per feature, not one long session (iteration 3)
- **Options:** one `/loop` session with compaction and handoff files (iterations 1–2) · an
  orchestrator plus subagents in one session (iteration 2) · **a new headless session per feature,
  with state on disk**.
- **Why:** every single-session approach eventually hits the context limit; subagents only delay
  it. Fresh sessions make context a constant, and force the state to be explicit (feature list,
  progress log, git).
