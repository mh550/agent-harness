# <project>

<Two lines: what this is, who uses it, what is live.>

## Code rules
- <stack, dependencies policy, the modules to reuse rather than re-implement>

## How to verify
- Suite: `<command>` (<count> tests, <duration>). A subset: `<command> <args>`.
- <dev server, pages and widths to check, fixtures>

## Decisions and plans
- Specs: <files>. Decisions: <file> (settled: D1–Dn). A new default is recorded there as `D<n> *default*`.
- Plans: `docs/plans/<date>-<milestone>-<topic>.md`.

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
