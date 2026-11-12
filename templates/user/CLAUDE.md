## Git, merges and permissions

What every conversation on this box may do and may not, whatever the project: the allows and denies of
`~/.claude/settings.json` and the rules beside them. How a change lands in a project is in that project's `CLAUDE.md`
(`## Where things go`); what a harness session does is in its prompt. Source:
`~/projects/agent-harness/templates/user/CLAUDE.md` (`decisions/2026-10-24-permissions-policy`,
`decisions/2026-11-11-user-file-homes`).

- **Allowed without asking:** merges, with or without a PR; pushes; deleting merged branches and worktrees;
  `harness gc`; `docker compose` for test stacks. Stop the stacks you started before you finish.
- **Denied in `~/.claude/settings.json`, because they can't be undone:**
  - force-push, and any push that rewrites or deletes `main`;
  - `git filter-branch` / `filter-repo`, `git reflog expire` / `reflog delete`, `git gc --prune` (they remove the
    reflog, the net that makes `reset --hard`, `branch -D` and bad rebases recoverable);
  - `gh repo delete`; `sudo`;
  - `rm -r` under `/srv`, `docker system prune`, `docker volume rm` / `prune` (live data and rollback images);
  - reading `/srv/n8n/data/config` (n8n's encryption key: credentials are unrecoverable without it);
  - a Soulseek `fetch --approve` and any write under `/srv/incoming` (dj-crate-streaming's live intake);
  - reading secrets: `.env` and `.env.*local` files, `/etc/restic`, `~/.config/voice-concierge`, `~/.livekit`.

  Claude Code itself never auto-approves `rm` of `/`, a top-level directory, your home directory, or the working
  directory and its parents, in any mode, so no rule repeats that.
- **Live, production and hardware rules are per project**, in that project's `CLAUDE.md` and
  `.claude/settings.json`: portfolio_site (Vercel deploys `main`; Michael merges), n8n-home (live: `/srv/n8n`),
  dj-crate-streaming (live: `/srv/docker`, `/srv/music`, `/srv/incoming`), rane-one-mixxx (hardware: the Rane One,
  `~/.rane-armed`). From any other directory that state is read-only.
- **Other projects:** read any of them. Change one only from a session in that project's directory or one of its
  worktrees, since another session may own its checkout.
- **Harness commands:** any session may run `harness status`, `report`, `parked` and `sync`, and `harness gc` on its
  own project. Starting, continuing, queueing, answering or merging runs is for Michael, the queue or a desk.
- **A deny is a gate, not an obstacle.** Don't reach the same end through another command, script or tool. Stop
  that step, write down what you need and why, and carry on with whatever doesn't depend on it.
