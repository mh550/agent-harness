# Static template first, a fixed first line, each session's prompt kept (the spec's D-H37)

*(2026-10-21, E3-03 of run agent-harness-2026-10-21-measure; plan `docs/plans/2026-10-21-E3-prompts.md` §1, §3–§5, §11)*

- **Finding:** each template's first line carried the feature id or milestone (`` # Coding session — `<id>` (run
  …) ``), and the run values (run directory, port, scratch, suite) were filled in all through the static text, so two
  sessions of one run shared about 20 bytes of prompt. Only the last prompt of each kind was kept
  (`$STATE/prompt-<kind>.md`), so two sessions' prompts couldn't be compared afterwards.
- **Choice:** every prompt is assembled as: the static template part (a fixed first line, `# Coding session`,
  `# Verify session`, `# Initializer session` or `# Retro`, then the role, ground rules and finish, with no
  placeholders), the policy, *This run* (`prompts/parts/run.md`: run id, worktree, branch, run directory, port,
  scratch, suite, init and smoke commands, spec), the brief, the line naming `CLAUDE.md`, `.harness/project.md`, then
  *This session* (`` Feature: `<id>` `` / `Milestone: <m>`, or `Milestone:` / `Features:` for verify; init output). A
  template line that is exactly `{{SECTIONS}}` marks where `render.mjs` (`assemble`, exported) puts the policy and
  run-level sections; templates without it (debrief, desk, supervisor) are unchanged. The retro, one per run, only
  gets the fixed first line and its run line on line 3. `tests/stub-claude.sh` matches the first lines exactly and
  reads the id and milestone after `# This session`. `session()` copies each prompt beside its transcript
  (`logs/NN-<id>.prompt.md`, `HHMMSS-verify-<m>.prompt.md`, `00-init.prompt.md`, `zz-retro-HHMMSS.prompt.md`), and
  `summary.mjs` now matches `NN-<id>.jsonl` exactly so it can't pick a prompt copy up as a transcript. A check proves
  two coding prompts of run `demo` are byte-identical past the policy.
- **Rejected:** two template files per kind (twice the files for one split point); `--append-system-prompt` for the
  static part (a bigger change; a candidate for a retro to propose once E2's eval has measured this); pasting
  INBOX answers into *This session* (every session reads `INBOX.md` itself).
- **Caveat:** the API caches at content-block boundaries where a breakpoint was written, and `claude -p` sends the
  prompt as one block, so a byte-identical prefix inside it may not be a cache hit by itself. It makes the prompts
  diffable and is the precondition for any split that would hit; E2's eval (first-turn `cache_read` of session 2
  against session 1, from E1's telemetry) says which.
