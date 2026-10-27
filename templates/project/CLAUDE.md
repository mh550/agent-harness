# <project>

<Two lines: what this is, who uses it, what is live.>

## Code rules
- <stack, dependencies policy, the modules to reuse rather than re-implement>

## How to verify
- Suite: `<command>`. A subset: `<command> <args>`.
- <dev server, pages and widths to check, fixtures>

## Decisions and plans
- Specs: <files>. Decisions: <file, or a directory of one file per decision; the same as DECISIONS= in
  .harness/config.sh>. A new default is recorded there marked *default* (in a file: the next free `D<n>`).
- Plans: `docs/plans/<date>-<milestone>-<topic>.md`.

## Where things go
- What happened, what was tried, what failed → the session's entry (the harness keeps the journal), never here.
- A decision → the decisions store above. Overturned → rewrite it in place, plus one `Updated in place <date>: …`
  line; never a new entry beside a dead one.
- A fact a fresh session would otherwise rediscover → one line under `## Gotchas`, edited in place.
- Tonight's scope (what to build, drop or do first) → the run's brief, never this file.
- How to work here (rules, conventions, workflow) → Michael's: propose it, don't write it.
- Anything the code, git or the suite can tell (test counts, file lists, constants) → nowhere.

## Gotchas
<!-- At most 15 lines, one fact each, edited in place: replace a wrong or least useful line, never rewrite the section. -->

## Off-limits
- <only this project's own gates: read-only inputs, hardware, production deploys. Secrets, other projects, git safety
  and harness commands are in `~/.claude/CLAUDE.md`; don't restate them.>

<!-- For POLICY=live-staged, add:
## Live system
### Check        (the command that proves the live system is consistent; its pass condition)
### Snapshots    (what to snapshot before a live write, and how)
### Backups      (how to read the last backup's status; how old is too old)
### Deploy and rollback
### Staged runbooks   (where each flow's dry run → --limit 5 → --limit 50 → all procedure and reverse log are)
### Never
-->
