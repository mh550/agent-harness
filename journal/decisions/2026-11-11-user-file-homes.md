# The user file keeps what is Michael's everywhere; how a change lands is the project's, run-time rules are the prompts'

*(2026-11-11, a hand session in agent-harness; analysis `findings-and-research/2026-11-11-user-file-homes.md`; revises
`decisions/2026-10-24-permissions-policy`'s "one home … project files and prompts point here and don't restate it")*

## Finding

- Claude Code loads `~/.claude/CLAUDE.md` into every session of every project, and a longer instruction file is followed
  less (`journal/learning/2026-11-07-memory-curator.md` §6: longer files reduce adherence, contradictions are resolved
  arbitrarily). Of its 48 lines, 17 were not true of every conversation: 3 said how a change lands (merge it yourself),
  which `prompts/coding.md` contradicts inside a run (the harness merges), so every run session carried both; 14
  restated what a project's own `CLAUDE.md`, `prompts/project-catchup.md` or `templates/user/config.merge-policy.sh`
  already says.
- Two denies the settings hold (a Soulseek `fetch --approve`, a write under `/srv/incoming`) were named only inside the
  dj-crate-streaming bullet, not in the deny list.
- No line was a run-time rule the prompts lack: stay in the worktree, the harness merges, no secrets or sudo, the live
  protocol are all in `prompts/coding.md`, `prompts/verify.md` and `prompts/policy/live-staged.md`.

## Choice

- **Three homes, one test each.** The prompts: true only inside a run. `templates/project/CLAUDE.md`: true of every
  project (how a change lands, what is live), reaching existing projects only by a per-project PR. The user file: true of
  Michael's every conversation (the allows and denies and what they protect, how he wants a refusal handled, the pointers
  a session outside a project needs). A line a project's own file says is a duplicate unless a hand session elsewhere
  needs it.
- **The user template** (`templates/user/CLAUDE.md`, 45 → 32 lines, same heading so the installer replaces the section
  in place) keeps: the allows; the denies, now including the two moved ones; the Claude Code `rm` note; one roster bullet
  naming the gated and live projects and their live state, read-only from anywhere else, and `/srv/n8n/data/config` read
  nowhere (no deny covers it and n8n-home's file loads only there); Other projects; Harness commands; A deny is a gate.
- **The project template** gains, under `## Where things go`, "A finished change → `main`, merged by the session that
  made it once the suite is green (…), never left on a branch <or, where `main` deploys: open the PR; Michael merges>. In
  a harness run the harness merges." `prompts/draft-claude-md.md` mirrors it, so a drafted file has the template's shape.
  The per-project PRs that would carry the line to the four existing projects are listed in the findings, not made.
- **Checks** in `tests/checks/memory-prompts.sh`: the template and the drafting prompt carry the line and the user
  template does not; the user template keeps the installer's heading, the denies and no per-project protocol.
- **The denies are not moved.** Adding one (`/srv/n8n/data/config`) is Michael's; the findings list it.

## Rejected

- **The landing line in the user file, with an "outside a harness run" clause.** It would keep the contradiction's fix
  in the one file every run session reads for no reason, and a project that deploys from `main` (portfolio_site) has to
  state its own rule anyway: the project file is where the exception already lives.
- **The landing line in `prompts/parts/where-things-go.md`.** That block reaches run sessions only, and for them the
  harness merges (coding.md already says so).
- **Dropping the `/srv/n8n/data/config` clause with the rest of the n8n-home bullet.** The other n8n lines are covered
  by a project-scoped MCP, a project deny or the policy prompt; nothing covers a `cat` of the key from another
  directory.
- **Making the per-project PRs from this session.** A project changes only from a session in its own directory or
  worktree (the user file's rule), and their CLAUDE.md edits are tier-2 memory under the curator's gate.
