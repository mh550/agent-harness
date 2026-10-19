# agent-harness

A harness for long-running coding agents: a deterministic bash driver around headless Claude Code sessions (one
fresh session per feature, independent verify, verified milestones merged through PRs, usage-limit handling, a
queue, per-run retros and a debrief). `docs/architecture.md` is the system as it is; `journal/decisions.md` is why.

## This repo runs Michael's nights: what that means for a session working on it

- **The live harness is `~/projects/agent-harness` on `main`.** It drives real runs on this box right now. Never
  edit, check out, merge or pull in that checkout; work only in your worktree. Your changes reach the live harness
  only when Michael merges your PR and pulls.
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
- Every behaviour the driver or CLI gains is visible in `harness-log.md` (`note`) and gets a check in
  `tests/run.sh`, written first and watched failing.
- **Fakes mirror the live API.** Stub output copies real CLI/HTTP shapes (`tests/fixtures/`); never invent a format.
  The 2026-10-17 usage-limit miss came from a guessed stub line.

## How to verify

- The suite: `bash tests/run.sh` (~3 min, end-to-end with stub `claude`/`gh` on a throwaway repo; prints
  `PASS`/`FAIL` per check and `N/M checks passed`). It must end with every check passing.
- `bash -n` on every shell file you touch; `node --check` on every `.mjs`.

## Where decisions and docs live

- A behaviour change gets a decision entry `D-H<n>` in `journal/decisions.md` (finding · choice · rejected), the
  next free number.
- Update `docs/architecture.md` (components, state, guards, end reasons as they apply) and `README.md` in the same
  milestone as the code.
