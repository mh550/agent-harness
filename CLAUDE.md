# agent-harness

A harness for long-running coding agents: a deterministic bash driver around headless Claude Code sessions (one
fresh session per feature, independent verify, verified milestones merged through PRs, usage-limit handling, a
queue, per-run retros and a debrief). `docs/architecture.md` is the system as it is; `journal/decisions.md` (D-H1 to D-H34) and `journal/decisions/` are why.

## This repo runs Michael's nights: what that means for a session working on it

- **The live harness is `~/projects/agent-harness` on `main`.** It drives real runs on this box right now. Never
  edit or check out anything in that checkout; work only in your worktree. **Finish what you start:** when the suite
  is green, push your branch, open a PR and merge it yourself (`gh pr merge --merge`; never force-push or rewrite
  `main`). A finding or spec is finished the same way, not left on a branch. The queue runner levels the live checkout
  with origin whenever no run is alive (`lib/sync.sh`); `harness sync` does it by hand, and only when no run is alive.
- **Never touch real runs or real state.** No `harness start/continue/queue/stop/pause/answer/merge/gc/debrief`
  except inside `tests/run.sh`'s throwaway environment. Never read or write `~/.local/state/harness`,
  `~/worktrees/*` (other than your own), `~/.config/harness`, or `ledger/` and `journal/raw/` in this repo.
- **Never send a real notification.** Nothing may post to ntfy.sh or any other URL. Notifications are tested with a
  stub (the way `tests/stub-claude.sh` and `tests/stub-gh.sh` stand in for `claude` and `gh`).
- **No `~/.claude` edits.** Skills, settings and hooks there are Michael's; ship files in this repo and tell him
  the one command to install them.

## Code rules

- bash (`set -uo pipefail`), node ≥ 20 standard library only, `jq`, `git`, `gh`, `tmux`, `flock`. No npm packages.
- Match the surrounding style: short comments that say why, one-line usage headers on every lib file, pure
  functions in the `.mjs` files where they can be (exported, unit-checkable with `node --input-type=module -e`).
- Every behaviour the driver or CLI gains is visible in `harness-log.md` (`note`) and gets a check in a
  `tests/checks/` file, written first and watched failing.
- **Fakes mirror the live API.** Stub output copies real CLI/HTTP shapes (`tests/fixtures/`); never invent a format.
  The 2026-10-17 usage-limit miss came from a guessed stub line.

## How to verify

- The suite: `bash tests/run.sh` (~3 min 30 s on this box: 208 s measured with `TEST_JOBS=4`, the default here; end-to-end
  with stub `claude`/`gh` on a throwaway repo; prints `PASS`/`FAIL` per check, a `<file>: <n> checks, <s> s` line per
  file, the slowest three with the wall time, and `N/M checks passed`). It must end with every check passing. It runs
  the files in `tests/checks/` (one per topic, each from a fresh throwaway state built by `tests/lib.sh`), `TEST_JOBS`
  at a time (default half the cores, 1 to 4; `TEST_JOBS=1` runs one after another); while iterating, run a subset by
  file name: `bash tests/run.sh gc` runs every file whose name contains `gc`. A new
  check goes in a `tests/checks/` file by topic, and its name gets one line in `tests/fixtures/check-names.txt` (the
  full run's conformance check fails on a name it doesn't list).
- `bash -n` on every shell file you touch; `node --check` on every `.mjs`.

## Where decisions and docs live

- A behaviour change gets a decision file `journal/decisions/<YYYY-MM-DD>-<slug>.md` (title, provenance, then
  finding · choice · rejected), cited as `decisions/<date>-<slug>`. Never number it and never append to
  `journal/decisions.md` (D-H1 to D-H34, closed): see `decisions/2026-10-21-one-file-per-decision`. Where a spec asks
  for "a `D-H<n>` entry", this file is what it means.
- Update `docs/architecture.md` (components, state, guards, end reasons as they apply) and `README.md` in the same
  milestone as the code.

## Where things go

- What happened, what you tried, what failed → your `entry.json` (the harness keeps the journal), never here.
- A decision → one file in `journal/decisions/` (`decisions/2026-10-21-one-file-per-decision`), never numbered.
  Overturned → edit it in place in its own file, plus one `Updated in place <date>: …` line; never a new file
  beside a dead one.
- A fact a fresh session would otherwise rediscover → one line under `## Gotchas`, edited in place.
- Tonight's scope (what to build, drop or do first) → the run's brief, never this file.
- How to work here (rules, conventions, workflow) → Michael's: say it in your entry's `proposed_changes`.
- Anything the code, git or the suite can tell (test counts, file lists, constants) → nowhere.

## Gotchas
<!-- At most 15 lines, one fact each, edited in place: replace a wrong or least useful line, never rewrite the section. -->
- tests/lib.sh runs under `pipefail`: never pipe a multi-write producer (sed/awk/git show, a log over 4 KiB) into `grep -q`, `grep -m` or `head` in a check; the early exit SIGPIPEs the producer now and then (141). Use `grep X > /dev/null`.
- check() evals its command in the check file's shell: an `exit` in it ends the whole file; fail with `false` or a flag (agent-harness-2026-10-28 2026-10-28)
- the end-reasons check greps literal finish/END_REASON/lane_exit 13 reasons in lib/driver.sh and lib/lane.sh: a new one needs a line in end-reasons.txt
- status_stubs' HARNESS_NOW stays in the past: a file touched to a future time is -newer than any stamp (agent-harness-2026-10-28 2026-10-28)
- a check's regex on a glyph run is locale-bound: write `(─)+`, `(●|✓) `, never `─+` or `[●✓]` (bytes under LC_ALL=C) (agent-harness-2026-10-28 2026-10-28)
- a card or view cuts every line at the width (100 off a TTY): a check comparing whole run.log lines sets COLUMNS=200 (agent-harness-2026-10-28 2026-10-28)
- status.mjs: a session runs from its `session <n> · <id>` log line to its `passes=` or limit note; stub logs need both (agent-harness-2026-10-28 2026-10-28)
- tests/fixtures/check-names.txt is LC_ALL=C sorted (run.sh comms it): re-sort it after adding names (agent-harness-2026-10-28 2026-10-28)
- INBOX.md: cut at lib/inbox.mjs answersLine (the `## Answers` outside the steering comment), never `/^## Answers/` (agent-harness-2026-10-28 2026-10-28)
- a check name for check-names.txt: copy it from a PASS line of `bash tests/run.sh <file>`, never a greedy sed over `check "…" '…"…'` lines (agent-harness-2026-10-28 2026-10-28)
