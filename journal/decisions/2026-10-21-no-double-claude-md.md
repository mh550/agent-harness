# Worktree sessions get one line naming CLAUDE.md, not the file pasted in (the spec's D-H36)

*(2026-10-21, E3-02 of run agent-harness-2026-10-21-measure; plan `docs/plans/2026-10-21-E3-prompts.md` §2, §11)*

- **Finding:** every session runs in the worktree (`cd "$WT"`), so `claude -p` loads `CLAUDE.md` itself, and
  `prompt_render` pasted it again under "Project rules (CLAUDE.md)": twice per session (2682 B for agent-harness,
  against a 4968 B coding template), and two copies that drift when the file changes mid-run. The debrief runs in
  `$STATE_ROOT/debrief/<stamp>/`, where nothing is auto-loaded (`--add-dir` doesn't load CLAUDE.md unless
  `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1`, which the harness never sets), and it pastes none either.
- **Choice:** for initializer, coding, verify and retro, `prompt_render` passes `prompts/parts/rules.md` when the
  worktree has a `CLAUDE.md`: `# Project rules` and one line saying the rules are in `CLAUDE.md`, which Claude Code
  loads. `.harness/project.md` (harness-only, not auto-loaded) is still pasted. The retro, which got the template
  only, now gets the rules line too. The debrief is unchanged. The coding and initializer templates point at the
  loaded file instead of "the rules at the end". `harness eval probes` renders through the same `lib/prompt.sh`, so a
  probe in the run's worktree sees what the session saw; one whose worktree is gone (the empty-temp-dir fallback,
  which says so) now sees no rules at all, where a baseline probe saw them pasted.
- **Rejected:** keeping the paste "to be safe" (tokens every session, and the copies drift); `--setting-sources` to
  stop the auto-load (interactive sessions read the same file, so it should be the one copy).
