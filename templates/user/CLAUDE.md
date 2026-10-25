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
  - `git filter-branch` / `filter-repo`, `git reflog expire` / `reflog delete`, `git gc --prune` (they remove the
    reflog, the net that makes `reset --hard`, `branch -D` and bad rebases recoverable);
  - `gh repo delete`; `sudo`;
  - `rm -r` under `/srv`, `docker system prune`, `docker volume rm` / `prune` (live data and rollback images);
  - reading `.env` files or `/etc/restic`.

  Claude Code itself never auto-approves `rm` of `/`, a top-level directory, your home directory, or the working
  directory and its parents, in any mode, so no rule repeats that.
- **Live, production and hardware rules are per project**, in that project's `CLAUDE.md` and
  `.claude/settings.json`. A project settings file holds only its gates and the narrow allows its runs need, nothing
  these user settings or auto mode already give (read-only commands and edits in the working directory need no rule;
  `defaultMode` in a project file is ignored):
  - portfolio_site: Vercel deploys `main`, so no `vercel` and no merging or pushing into `main`. Open the PR with its
    preview URL; Michael merges it.
  - n8n-home: **live**. Agents deploy through the live-staged protocol in its `CLAUDE.md` (`## Live system`):
    snapshots, deploys and rollbacks run under `flock -n /srv/n8n/live.lock`, and live workflows change only through
    `scripts/deploy.sh` from git. Never read `/srv/n8n/data/config` (the encryption key), and never run, call or
    delete anything on the live instance through the n8n MCP.
  - dj-crate-streaming: **live**. Agents deploy and operate it through the live-staged protocol in its `CLAUDE.md`
    (`## Live system`), with its project settings allowing exactly that. Never a Soulseek `fetch --approve`, never
    a write under `/srv/incoming` or to `/srv/docker/compose*` (the first two are user-level denies, so they hold in
    every project).
  - rane-one-mixxx: hardware. No raw MIDI sends (`amidi -s`, `aplaymidi`, `sendmidi`): `tools/midi-send` is the
    only way out, and only Michael creates or removes `~/.rane-armed`.
  - Every other project has no project settings file.
- **A deny is a gate, not an obstacle.** Don't reach the same end through another command, script or tool. Stop
  that step, write down what you need and why, and carry on with whatever doesn't depend on it.
- **Harness runs** merge their verified milestones (`MERGE_POLICY=auto` in `~/.config/harness/config.sh`); the
  production-gated projects (portfolio_site only, for now) set `MERGE_POLICY=pr` in their `.harness/config.sh`.
