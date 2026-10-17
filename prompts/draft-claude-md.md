Draft this repository's `CLAUDE.md`: the durable rules and facts every Claude session (interactive or run by the
agent harness) needs here. Read the README, docs/ (specs, decisions, runbooks, architecture), the build/test setup
and a sample of the code. Then write `CLAUDE.md` at the repository root, 25–60 lines, with these sections in order:
`# <project>` (two lines: what it is, who uses it, whether anything is live) · `## Code rules` · `## How to verify`
(exact suite command, test count, duration, how to run a subset, dev server, UI widths) · `## Decisions and plans`
(where decisions live, how a new default is recorded) · `## Off-limits` (read-only inputs, secrets).
If the repo operates a live system and documents how (runbooks, deploy scripts, backups), add `## Live system` with
`### Check`, `### Snapshots`, `### Backups`, `### Deploy and rollback`, `### Staged runbooks`, `### Never`, using only
commands you found in the repo. Mark anything you inferred "(unverified)". Nothing about a particular night's
scope. Don't commit, don't touch any other file, and never write settings or permission files.
