Draft this repository's `CLAUDE.md`: the durable rules and facts every Claude session (interactive or run by the
agent harness) needs here. Read the README, docs/ (specs, decisions, runbooks, architecture), the build/test setup
and a sample of the code. Then write `CLAUDE.md` at the repository root, 30–70 lines, with these sections in order:
`# <project>` (two lines: what it is, who uses it, whether anything is live) · `## Code rules` · `## How to verify`
(exact suite command, how to run a subset, dev server, UI widths; no test counts or durations) · `## Decisions and plans`
(where decisions live, how a new default is recorded) · `## Where things go` (about 7 lines: what happened → the
session's entry · a decision → the store, overturned → rewritten in place plus one `Updated in place <date>: …` line ·
a fact a fresh session would rediscover → one `## Gotchas` line, edited in place · tonight's scope → the run's brief ·
how to work here → Michael's · anything the code, git or the suite can tell → nowhere) · `## Gotchas` (at most 15
one-line facts a fresh session would otherwise rediscover, from the docs and history; empty if none) · `## Off-limits` (this project's own gates only, such as read-only inputs and hardware: secrets, other projects
and git safety are in `~/.claude/CLAUDE.md`).
If the repo operates a live system and documents how (runbooks, deploy scripts, backups), add `## Live system` with
`### Check`, `### Snapshots`, `### Backups`, `### Deploy and rollback`, `### Staged runbooks`, `### Never`, using only
commands you found in the repo. Mark anything you inferred "(unverified)". Nothing about a particular night's
scope. Don't commit, don't touch any other file, and never write settings or permission files.
