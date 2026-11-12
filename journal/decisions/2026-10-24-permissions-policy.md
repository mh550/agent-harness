# One permissions policy, in ~/.claude: agents merge and clean up, only the irreversible is denied, production is gated per project

*(2026-10-24, chunk 1 of `docs/plans/2026-10-24-handoff.md`, an agent session; the policy itself is the plan's
"Policy" section, agreed with Michael the same day)*

- **Finding:**
  - Every handoff waited on Michael because the user settings denied what finishing takes: `git branch -D`,
    `git push origin --delete`, `git push --delete`.
  - Project files denied more (n8n-home: `git worktree remove/prune`), and the n8n run died at 0/32 on a project-level
    `docker compose` deny.
  - The rules lived in several places that disagreed, and no file every session loads said what an agent may do.
  - The n8n MCP servers sat in user scope, so the live n8n write tools loaded in every project, gated nowhere but
    n8n-home.
- **Choice:**
  - **Files.** `templates/user/` holds the three user files:
    - `settings.permissions.json`: a copy of `~/.claude/settings.json` with the policy's `permissions` block;
    - `CLAUDE.md`: the § "Git, merges and permissions" section;
    - `config.merge-policy.sh`: the harness's merge policy.
  - **`setup/apply-2026-10-24.sh` installs them**, and `--dry-run` shows every diff first. Michael runs it; agents
    don't edit `~/.claude` or `~/.config`. The script takes only `permissions` (and `enabledMcpjsonServers`) from the
    template, over the live file's other keys, so a setting changed after the template was cut survives.
  - **Allowed:** merges, pushes, deleting merged branches and worktrees, `harness gc`, `docker compose`. Each has an
    explicit allow, since auto mode's classifier otherwise blocks merging an unapproved PR and deleting remote
    branches.
  - **Denied:** only what can't be undone. That is force-push and any push that rewrites or deletes `main`,
    `filter-branch`/`filter-repo`, `reflog expire/delete`, `gc --prune`, `gh repo delete`, `sudo`, and reads of `.env`
    and `/etc/restic`.
    - **Two existing denies are kept**, `Bash(*fetch*--approve*)` and `Edit(//srv/incoming/**)`. They gate live
      actions of a project with no settings file of its own, and dropping a gate is Michael's call.
    - **`Bash(scripts/deploy.sh:*)` leaves the user allow list.** A production deploy is gated in its project and
      isn't pre-approved for every project.
  - **The n8n MCP servers move to n8n-home's `.mcp.json`.** n8n drops its static `Authorization` header: the server
    offers OAuth (its `/.well-known/oauth-protected-resource` answers), so the token stays in Claude Code's store and
    out of the repo. `enabledMcpjsonServers` in the user settings approves both names, so headless runs in n8n-home
    worktrees load them without a prompt.
  - **`MERGE_POLICY=auto`, not the plan's `merge`.** `lib/config.sh` and `lib/driver.sh` know `auto`, `pr` and `off`,
    and `merge` would silently behave as `pr`.
- **Rejected:**
  - **Copying the template over `~/.claude/settings.json` whole.** It would revert any setting Michael changed
    between the template and the apply.
  - **Keeping the bearer token in `.mcp.json`, or behind `${VAR}` expansion.** The first commits a secret. The
    second needs the variable in every environment a run starts from.
  - **Keeping `git reset --hard` and `git tag -d` denied.** The policy's deny list is closed, and both are local:
    the reflog gets back the commits a reset moves off. The cost is uncommitted edits a reset discards, a session's
    own and in its own worktree.
- **Revised the same day, after Michael applied it:**
  - **`scripts/deploy.sh` was dj-crate-streaming's production deploy, not n8n-home's.** Dropping the user allow
    stopped pre-approving dj deploys.
  - **dj-crate-streaming goes live again** (`POLICY=live-staged`, `MERGE_POLICY=auto`), at Michael's request. Its
    deploy allow and the rest of the live protocol's commands go in **its own** `.claude/settings.json`, beside the
    denies from its **Never** list. They don't go back into the user file, where `scripts/deploy.sh` would
    pre-approve every repo's script of that name (n8n-home will have one). So the policy's production projects are
    three: portfolio_site and n8n-home (gated), dj-crate-streaming (live).
  - **agent-harness drops its `MERGE_POLICY=pr`.** A project file wins over the user config, so the harness's own runs
    would still have waited for Michael, and chunk 4's three queued runs wouldn't build on each other.
  - **Project-repo changes ride chunk 3, not a separate pass.** n8n-home's `MERGE_POLICY=pr` and `.mcp.json`, and
    dj's live settings, go to each project's catch-up worker, which already edits that project's settings and merges
    there. Only agent-harness's own line changed at once, because chunks 4–5 depend on it.
- **Revised 2026-10-25, after the n8n-home and rane-one-mixxx catch-ups** (both needed a second prompt to trim):
  - **Finding:** the policy was also restated in project prose: `## Off-limits` sections and `.harness/project.md`
    held "never run `harness` commands", "other checkouts are off-limits" and the secrets list. The "other checkouts"
    line is why the rane worker left dj's duplicate rules alone. In every harness run's `permission_denials`, no
    denial fell on a command the project allow lists covered.
  - **Choice:**
    - Catch-up Part 1 step 4 is now "Policy trim: settings and prose". It sets a test for a deny (can't be undone,
      reaches production or a live system, or touches hardware) and for an allow (acts outside the repo or the
      classifier could block it, and a run needed it), and gives the `jq` query over run logs as the evidence.
    - Each project's target is written in its handoff row, so workers check it rather than work it out again.
    - The user `CLAUDE.md` gains two bullets, "Other projects" and "Harness commands", so no project restates
      them.
    - Every secrets read is a user-level deny (`.env.*local`, `~/.config/voice-concierge/**`, `~/.livekit/**`),
      since secrets are box-wide.
    - voice-concierge's live tests, worker and `lk` become one `CLAUDE.md` line (Michael: they spend API credit but
      can be undone).
  - **Rejected:** a separate follow-up session per project. Part 1 already edits the settings, so a complete step 4
    costs nothing extra.
