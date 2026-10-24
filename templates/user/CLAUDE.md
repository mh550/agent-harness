## Git, merges and permissions

The one home of this policy: project files and prompts point here and don't restate it. Source:
`~/projects/agent-harness/templates/user/CLAUDE.md` (`decisions/2026-10-24-permissions-policy`).

- **Finish in your worktree, then merge to `main` yourself.** Worktrees stay (Claude Code uses them for isolated
  sessions). When the checks are green, push the branch and merge its PR (`gh pr merge --merge`), or merge locally
  and push. Then delete the merged branch, local and remote, and remove the worktree. Don't leave work on a branch.
- **Allowed without asking:** merges, with or without a PR; pushes; deleting merged branches and worktrees;
  `harness gc`; `docker compose` for test stacks. Stop the stacks you started before you finish.
- **Denied in `~/.claude/settings.json`, because they can't be undone:**
  - force-push, and any push that rewrites or deletes `main`;
  - `git filter-branch` / `filter-repo`, `git reflog expire` / `reflog delete`, `git gc --prune`;
  - `gh repo delete`; `sudo`;
  - reading `.env` files or `/etc/restic`.
- **Production is gated per project**, in that project's `.claude/settings.json`, and nowhere else:
  - portfolio_site: Vercel deploys `main`, so no `vercel` and no merging or pushing into `main`. Open the PR with its
    preview URL; Michael merges it.
  - n8n-home: no `scripts/deploy.sh`, no writes under `/srv`, nothing against the live `n8n-n8n-1` container, no
    live n8n MCP writes. `docker compose` for `n8n-test-*` stacks is fine.
  - dj-crate-streaming: **live**. Agents deploy and operate it through the live-staged protocol in its `CLAUDE.md`
    (`## Live system`), with its project settings allowing exactly that. Never a Soulseek `fetch --approve`, never
    a write under `/srv/incoming` or to `/srv/docker/compose*`.
  - Every other project has no project settings file.
- **A deny is a gate, not an obstacle.** Don't reach the same end through another command, script or tool. Stop
  that step, write down what you need and why, and carry on with whatever doesn't depend on it.
- **Harness runs** merge their verified milestones (`MERGE_POLICY=auto` in `~/.config/harness/config.sh`); the
  production-gated projects (portfolio_site, n8n-home) set `MERGE_POLICY=pr` in their `.harness/config.sh`.
