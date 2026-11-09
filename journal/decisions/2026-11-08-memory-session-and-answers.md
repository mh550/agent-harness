# The memory session and the answers: a denied curator, an `auto` that keeps its body, answers the next curator reads

*(2026-11-08, run agent-harness-2026-11-08, N2 (the deny-list row by N2-01, the body-refresh row by N2-02); spec
`docs/specs/2026-11-07-memory-followup.md` §N2; journal/learning/2026-11-07-memory-curator.md §11 answer 7 (build the
deny list: `Bash(git push:*)`, `Bash(gh:*)`; `memory_foreign` stays the second layer) and §13 item 3; Claude Code's
https://code.claude.com/docs/en/cli-reference (`--disallowedTools`, "Deny rules", one quoted rule per argument;
`--settings <file|json>`) and https://code.claude.com/docs/en/permissions ("Rules are evaluated in order: deny, then
ask, then allow"; an allow rule can't carve an exception out of a deny rule), both read 2026-11-07;
decisions/2026-11-07-memory-tiers (the known limit this closes).)*

- **Finding:** the curator was read-only by revert alone: `restrict … nothing` undoes what it changes in the run's
  worktree and `memory_foreign` refuses a memory branch tip the driver would not have written, but neither reaches a
  push. A session under `--permission-mode auto` may run `git push` or `gh` against any ref or PR; the tiers decision
  recorded it as a known limit, and Michael said build the deny list (answer 7). `lib/debrief.sh` already runs one
  session under `--disallowedTools "${DENY[@]}"` with rules in the `Bash(git push:*)` form, so the flag and the form
  are in use on this box.
- **Choice (N2-01):**
  - `session()` (lib/record.sh) takes an optional `S_DENY` array, as `S_TURNS`, `S_BUDGET` and `S_TIMEOUT` are per-call
    overrides, and appends `--disallowedTools "${S_DENY[@]}"` last on the one `claude -p` line when it is set and
    non-empty (last: the flag takes every argument after it up to the next option). *Default*: the flag on the command
    line over a `--settings` JSON with `permissions.deny`: the flag's semantics are documented for exactly this, it
    leaves `AGENT_SETTINGS` meaning what it means, and the argv is what the stub records. Deny is evaluated before allow,
    so neither the mode nor a project's `.claude/settings.json` allow admits a denied call.
  - `curator()` (lib/driver.sh) fixes `CURATOR_DENY=("Bash(git push:*)" "Bash(gh:*)")` beside its `MAX_TURNS=40
    SESSION_BUDGET_USD=3` and passes it as `S_DENY`; the curator is the only caller (`grep -n S_DENY lib/*.sh`). The
    coding, verify, retro and every other session get no `--disallowedTools` from `session()` (*default*: the curator
    alone; a retro list is not in this spec). *Default*: not a config knob, since a knob can be set empty and this is a
    floor; a project that needs more adds to the array in a feature. Nothing else in the list: every other write the
    curator could make is reverted by `restrict`, and `memory_foreign` stays the second layer for a push that found
    another form (a Bash rule does not match the same program invoked differently).
  - The colon form, `Bash(git push:*)`, as `lib/debrief.sh` passes it (*default*: one form in the repo). The current
    permissions page writes its examples as `Bash(git push *)` and documents no retirement of the colon form.
    **Falsifier:** a real curator transcript that shows a `git push` or `gh` call run, not refused, under this list, or a
    CLI release note retiring the colon form: then both lists move to the space form in one feature.
  - Visible: the `run.log` line `curator · <model> · deny Bash(git push:*) Bash(gh:*)` and one `harness-log.md` note
    per curator session, `curator: session denied Bash(git push:*), Bash(gh:*)`, given after the restrict (a note before
    it would be reverted). `prompts/curator.md` keeps its "No push, no `gh`" sentence and adds that the driver denies
    both, so such a call is refused.
  - The stub mirrors the CLI: every headless session records its argv in `$STUB_DIR/argv/<n>-<kind>.args` (the desk's
    `<n>-<name>.args` shape, the prompt as `<prompt>`, then `PWD=` and `HARNESS_RUN_ID=`); `STUB_CURATOR_PUSH=1` has the
    stub curator commit a Gotchas line and push it to `harness-memory/<run>` unless its argv carries `--disallowedTools`
    with `Bash(git push:*)`. *Default*: the stub prints no denial event, since none has been captured from the real CLI
    and a guessed line is what `CLAUDE.md` forbids; the check reads the argv and the absence of the push. A captured
    deny event goes into `tests/fixtures/` and the stub replays it, in a later feature.
  - Checks (tests/checks/curator-run.sh, slow): `curator: the curator session alone runs under --disallowedTools, with
    Bash(git push:*) and Bash(gh:*) and nothing else`, `curator: its run.log line names the deny list and harness-log.md
    has one note saying so`, `curator: a curator that would push is denied; harness-memory/<run> holds the driver's one
    commit and its memory PR opens as stub-three-ops predicts` (the `cd` run). Without the push rule all three are red
    (probed 2026-11-08). No unit test: no pure function changed.
- **Rejected (N2-01):** a `--settings` JSON carrying `permissions.deny` (two meanings for one flag, and a file the stub
  would have to parse); a `CURATOR_DENY` config knob (a floor that can be emptied is not one); `--permission-mode
  dontAsk` with an allowlist, as the debrief runs (the curator reads with `jq` and arbitrary commands; an allowlist is a
  larger change than answer 7 asked for); the deny list on every session (the coding and verify sessions push their
  own branches by design).
- **Finding (N2-02):** under `MEMORY_POLICY=auto` `memory_pr` merged the facts PR whenever its segment pushed a tier-1
  commit, whether or not `memory_edit`'s `gh pr edit` had put this segment's body on a reused PR: the merge went into
  `main` with an older body, which is the audit trail of what was merged (Michael's flip of M3-02's question,
  decisions/2026-11-07-memory-policy).
- **Choice (N2-02):**
  - `memory_edit` returns `gh pr edit`'s status; `memory_pass` returns 1 when it pushed a commit to a reused PR whose
    edit failed. `memory_pr` merges the facts PR only when that status is 0: a fresh PR (`pr create --body-file`)
    carries its body and merges as before; a reused PR whose edit failed gets one note in place of the two
    (`its body was not updated …` and `merged into main`): `memory PR: its body was not updated (see run.log); not
    merged (MEMORY_POLICY=auto), left open · <url>`. The edit's own failure note is held back for this one case (its
    `quiet` argument), so the segment says it once.
  - *Default*: no retry of the edit inside the segment (one `gh` call per step is the harness's origin rule); the
    branch is pushed and the PR open, so the next segment reuses both, refreshes the body and merges then at the head
    it pushed.
  - *Default*: the second facts edit, the one that names a rules PR opened after the facts body was written, does not
    decide the merge: a failed first edit stays unmerged even when the second succeeds (one rule, and the first
    failure keeps its note), and a failed second edit after a good first one still merges, since this segment's body is
    on the PR and only the other PR's URL is missing, which its own note says.
  - Under `pr` nothing changes (no merge either way, the edit's failure note as before); the rules PR is never merged
    (invariant 3), so this concerns the facts PR alone.
  - Checks (tests/checks/memory-branch.sh, slow): `memory PR: under MEMORY_POLICY=auto a reused PR whose body refresh
    failed gets its commit but no merge, with one note` and `memory PR: the next segment refreshes the reused PR's body
    and merges it at the commit it pushed`, on two continues of the `mw` run (`STUB_GH_DOWN=1 STUB_GH_DOWN_ONLY=edit`,
    then gh up), each adding one fact (`tests/fixtures/memory/stub-fact-b.json`, `stub-fact-c.json`). Both red before
    the change (the first continue merged). No unit test: no pure function changed.
- **Rejected (N2-02):** a retry of the edit inside the segment (a second `gh` call for one step, and the next segment
  retries anyway); merging a reused PR that is already pushed on a bare body refresh with no new tier-1 commit (a new
  behaviour the spec does not ask for: only a new tier-1 commit merges, as before); clearing `PASS_HEAD` on a failed
  edit to stop the merge (it would hide the pushed commit from the decision that reads it).
