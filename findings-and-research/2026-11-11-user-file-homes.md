# Where each line of `~/.claude/CLAUDE.md` belongs (2026-11-11)

**TL;DR.** The user file (48 lines on 2026-11-11: the 45-line installed section plus Michael's own `## Gotchas`) loads into
every Claude Code conversation on this box. Of its 48 lines, 31 are true of every conversation and stay (the allows, the
denies and why, the per-project pointer, other projects, harness commands, a deny is a gate, Michael's own section);
3 say how a change lands and move to `templates/project/CLAUDE.md`; 0 move to the prompts, because every run-time rule
the file carries is already in `prompts/coding.md`, `prompts/verify.md` or `prompts/policy/live-staged.md`; 14 are
dropped as duplicates of a project's own `CLAUDE.md`, of `prompts/project-catchup.md`, or of a file that states the fact
(`templates/user/config.merge-policy.sh`). Two denies the settings hold (a Soulseek `fetch --approve`, a write under
`/srv/incoming`) were named only inside the dj-crate-streaming bullet; they move into the deny list. One clause no deny
covers (`/srv/n8n/data/config`, n8n's encryption key) stays as a pointer, since n8n-home's file loads only there.
Decision: `decisions/2026-11-11-user-file-homes`.

## The test for each line

| Home | The test | Reaches |
|---|---|---|
| (1) the prompts | true only inside a harness run: how a coding or verify session works, what the harness does with an entry, run-time rules | every run of every project at once; never a hand session |
| (2) `templates/project/CLAUDE.md` | true of every project under the harness: how a change lands, what is live | new projects at init; existing ones only by a per-project PR (listed below, not made) |
| (3) the user file | true of Michael's every Claude Code conversation: the denies and what they protect, how he wants to be talked to | every conversation, every project |
| dropped | a project's own `CLAUDE.md`, a prompt, or a config file already says it, and no hand session outside that project needs it | — |

The denies are not moved: the user file's lines about them stay with the deny.

## Every line, its home, the reason

Line numbers are `~/.claude/CLAUDE.md`'s on 2026-11-11 (identical to `templates/user/CLAUDE.md` through line 45; lines
46–48 are Michael's own section, which the installer keeps because it replaces only the section under its heading).

| # | Line as it is | Home | Why |
|---|---|---|---|
| 1 | `## Git, merges and permissions` | stays | the heading `setup/apply-2026-10-24.sh` replaces the section by |
| 2 | (blank) | stays | layout |
| 3 | The one home of this policy: project files and prompts point here and don't restate it. Source: | stays, reworded | the pointer every conversation needs; the claim that project files don't restate it stops holding, since a project file now says how a change lands |
| 4 | `~/projects/agent-harness/templates/user/CLAUDE.md` (`decisions/2026-10-24-permissions-policy`). | stays | the source and its decision, now with `decisions/2026-11-11-user-file-homes` |
| 5 | (blank) | stays | layout |
| 6 | - **Finish in your worktree, then merge to `main` yourself.** Worktrees stay (Claude Code uses them for isolated | project template | how a change lands; inside a run `prompts/coding.md` says the opposite (the harness merges), so one file loaded by both contradicted the other, and contradictions are resolved arbitrarily (memory-curator §6) |
| 7 | sessions). When the checks are green, push the branch and merge its PR (`gh pr merge --merge`), or merge locally | project template | the same line |
| 8 | and push. Then delete the merged branch, local and remote, and remove the worktree. Don't leave work on a branch. | project template | the same line |
| 9 | - **Allowed without asking:** merges, with or without a PR; pushes; deleting merged branches and worktrees; | stays | describes the settings' allow list, which every conversation runs under |
| 10 | `harness gc`; `docker compose` for test stacks. Stop the stacks you started before you finish. | stays | the same, and the stop rule holds in every conversation |
| 11 | - **Denied in `~/.claude/settings.json`, because they can't be undone:** | stays | the denies |
| 12 | - force-push, and any push that rewrites or deletes `main`; | stays | a deny in `settings.permissions.json` |
| 13 | - `git filter-branch` / `filter-repo`, `git reflog expire` / `reflog delete`, `git gc --prune` (they remove the | stays | a deny |
| 14 | reflog, the net that makes `reset --hard`, `branch -D` and bad rebases recoverable); | stays | what the deny protects |
| 15 | - `gh repo delete`; `sudo`; | stays | denies |
| 16 | - `rm -r` under `/srv`, `docker system prune`, `docker volume rm` / `prune` (live data and rollback images); | stays | denies, and what they protect |
| 17 | - reading secrets: `.env` and `.env.*local` files, `/etc/restic`, `~/.config/voice-concierge`, `~/.livekit`. | stays | the `Read` denies |
| 18 | (blank) | stays | layout |
| 19 | Claude Code itself never auto-approves `rm` of `/`, a top-level directory, your home directory, or the working | stays | why the deny list has no `rm` rule: about Claude Code, true in every conversation |
| 20 | directory and its parents, in any mode, so no rule repeats that. | stays | the same |
| 21 | - **Live, production and hardware rules are per project**, in that project's `CLAUDE.md` and | stays, reworded | the pointer; it now carries the roster of gated and live projects and their live state, so a session elsewhere leaves that state alone |
| 22 | `.claude/settings.json`. A project settings file holds only its gates and the narrow allows its runs need, nothing | dropped | duplicate of `prompts/project-catchup.md` Part 1 step 4 (the deny test, the allow test, how the rules combine) and of the 2026-10-24 decision: a rule for whoever writes a project settings file, which is a catch-up session or Michael |
| 23 | these user settings or auto mode already give (read-only commands and edits in the working directory need no rule; | dropped | the same (project-catchup.md: "Auto mode approves edits in the working directory and read-only commands with no rule") |
| 24 | `defaultMode` in a project file is ignored): | dropped | the same ("ignores `defaultMode` in a project file") |
| 25 | - portfolio_site: Vercel deploys `main`, so no `vercel` and no merging or pushing into `main`. Open the PR with its | dropped | duplicate of portfolio_site's `CLAUDE.md` § Off-limits ("Never deploy: no `vercel` CLI, never push or merge to `main` … Michael merges"); the roster keeps the name and "Michael merges" |
| 26 | preview URL; Michael merges it. | dropped | the same |
| 27 | - n8n-home: **live**. Agents deploy through the live-staged protocol in its `CLAUDE.md` (`## Live system`): | dropped | duplicate of n8n-home's `CLAUDE.md` § Live system and of `prompts/policy/live-staged.md`, which every run session of a live project gets |
| 28 | snapshots, deploys and rollbacks run under `flock -n /srv/n8n/live.lock`, and live workflows change only through | dropped | duplicate of its § Backups (Lock) and § Deploy and rollback |
| 29 | `scripts/deploy.sh` from git. Never read `/srv/n8n/data/config` (the encryption key), and never run, call or | stays, as one clause | the key read is in its § Never, but that file loads only in n8n-home and no deny covers the path: a hand session elsewhere needs the clause (a `Read` deny would be its right home; Michael's call) |
| 30 | delete anything on the live instance through the n8n MCP. | dropped | the n8n MCP servers are project-scoped since the 2026-10-24 apply (n8n-home's `.mcp.json`), so they load nowhere else; there, § Never says "no live MCP write tools" (the broader "no calls" wording is for its own PR, below) |
| 31 | - dj-crate-streaming: **live**. Agents deploy and operate it through the live-staged protocol in its `CLAUDE.md` | dropped | duplicate of dj-crate-streaming's `CLAUDE.md` § Live system and the policy prompt |
| 32 | (`## Live system`), with its project settings allowing exactly that. Never a Soulseek `fetch --approve`, never | stays, moved | the Soulseek deny is a user-level deny the deny bullet did not list: it moves up into that list |
| 33 | a write under `/srv/incoming` or to `/srv/docker/compose*` (the first two are user-level denies, so they hold in | stays, moved | the `/srv/incoming` deny likewise; `/srv/docker/compose*` is dj's project deny (its § Never), and the roster names `/srv/docker` as live state |
| 34 | every project). | stays, moved | the same |
| 35 | - rane-one-mixxx: hardware. No raw MIDI sends (`amidi -s`, `aplaymidi`, `sendmidi`): `tools/midi-send` is the | dropped | duplicate of rane-one-mixxx's `CLAUDE.md` § Hardware and Mixxx rules (every outbound MIDI through `tools/midi-send`, no amidi/aplaymidi writes) |
| 36 | only way out, and only Michael creates or removes `~/.rane-armed`. | dropped | duplicate of its § Off-limits; the roster names the Rane One and `~/.rane-armed` |
| 37 | - Every other project has no project settings file. | dropped | `ls ~/projects/*/.claude/settings.json` tells it: anything the files can tell goes nowhere |
| 38 | - **Other projects:** read any of them. Change one only from a session in that project's directory or one of its | stays | protects other sessions' checkouts; true in every conversation (a run has its own form in coding.md's Ground rules, which is the narrower rule, not a contradiction) |
| 39 | worktrees, since another session may own its checkout. | stays | the same |
| 40 | - **Harness commands:** any session may run `harness status`, `report`, `parked` and `sync`, and `harness gc` on its | stays | the harness CLI is on the box in every conversation; it is also the only place a run session is told not to steer runs |
| 41 | own project. Starting, continuing, queueing, answering or merging runs is for Michael, the queue or a desk. | stays | the same |
| 42 | - **A deny is a gate, not an obstacle.** Don't reach the same end through another command, script or tool. Stop | stays | how Michael wants a refusal handled, everywhere |
| 43 | that step, write down what you need and why, and carry on with whatever doesn't depend on it. | stays | the same |
| 44 | - **Harness runs** merge their verified milestones (`MERGE_POLICY=auto` in `~/.config/harness/config.sh`); the | dropped | `templates/user/config.merge-policy.sh` and `docs/architecture.md` § Permissions say it; a run session is told the harness merges (coding.md Ground rules); no conversation acts on the setting |
| 45 | production-gated projects (portfolio_site only, for now) set `MERGE_POLICY=pr` in their `.harness/config.sh`. | dropped | the same; portfolio_site's `.harness/config.sh` is the fact's home |
| 46 | (blank) | stays (Michael's) | outside the installed section |
| 47 | `## Gotchas` | stays (Michael's) | his own section; the installer stops at the next heading |
| 48 | - node 24's `node --test <dir>` loads the directory as a module, not a folder to scan: give it an index file that imports the tests, or a glob | stays (Michael's) | his line (this repo's `CLAUDE.md` also says it, under its own Gotchas) |

**Counts:** stay 31 · to the project template 3 · to the prompts 0 · dropped as a duplicate 14.

## What moves where

- **`templates/user/CLAUDE.md`** (45 → 32 lines): the heading, a reworded pointer paragraph, the allows, the denies (now
  with the Soulseek and `/srv/incoming` ones), the Claude Code `rm` note, one per-project bullet (the roster: portfolio_site
  gated, n8n-home and dj-crate-streaming live with their `/srv` paths, rane-one-mixxx hardware; that state read-only from
  anywhere else; `/srv/n8n/data/config` read nowhere), Other projects, Harness commands, A deny is a gate. The installer
  (`bash setup/apply-2026-10-24.sh --dry-run`, then without) replaces the section under its heading, so
  `~/.claude/CLAUDE.md` goes 48 → 35 lines and Michael's `## Gotchas` stays (checked by running the installer's awk on a
  copy).
- **`templates/project/CLAUDE.md`**, under `## Where things go`: "A finished change → `main`, merged by the session that
  made it once the suite is green (push, `gh pr merge --merge` or merge locally, delete the branch, remove the worktree),
  never left on a branch <or, where `main` deploys: open the PR; Michael merges>. In a harness run the harness merges."
  45 lines, `harness memlint` clean on a copy (its one finding, no decisions store, is the copy's missing
  `.harness/config.sh`). `prompts/draft-claude-md.md`, which drafts a project's `CLAUDE.md` to the template's shape,
  mirrors the line (its block is "about 8 lines" now).
- **The prompts:** nothing of the user file. Its run-time rules are already there: stay in the worktree and never touch
  another checkout (coding.md Ground rules), the harness merges and cleans up (the same), no secrets and no sudo (the same;
  policy/live-staged.md Always), the live protocol (policy/live-staged.md and the project's `## Live system`).
- **Checks** (`tests/checks/memory-prompts.sh`, slow tier, +2): the template and the drafting prompt carry the landing
  line and the user template no longer does; the user template keeps the installer's heading on line 1, names the
  settings denies (the two moved ones too), `/srv/n8n/data/config`, and no per-project live protocol or `MERGE_POLICY`,
  within 40 lines. Both seen red against the unchanged files first.

## Per-project PRs (listed, not made: a project changes only from a session in its directory)

| Project | Lines | Why |
|---|---|---|
| agent-harness | `CLAUDE.md` § Where things go: the landing line (its § This repo already says push, open a PR, merge it yourself; the line adds delete the branch, remove the worktree) | so the repo's block matches the template's |
| n8n-home | `CLAUDE.md` § Where things go: the landing line. Optional, Michael's call: § Never line "Change live workflows any way but `scripts/deploy.sh` from git: no live MCP write tools, no editor clicks" may take the user file's broader "never run, call or delete anything on the live instance through the n8n MCP" | the user file no longer says how a change lands; the MCP wording was broader in the user file than in the project |
| dj-crate-streaming | `CLAUDE.md` § Where things go: the landing line | the same; its § Off-limits already names the two denies as user-level |
| rane-one-mixxx | `CLAUDE.md` § Where things go: the landing line | the same |
| portfolio_site | nothing required: § Off-limits already says never push or merge to `main`, Michael merges. Optional: the template's variant ("open the PR; Michael merges") under § Where things go | its landing rule is already its own |

**For Michael, not a PR:** `/srv/n8n/data/config` is a secret no deny covers. A `Read(//srv/n8n/data/config)` deny in
`templates/user/settings.permissions.json` would be its right home; then the user file's clause moves into the deny list
with it. Adding a deny is a policy change, so it is listed here and not made.
