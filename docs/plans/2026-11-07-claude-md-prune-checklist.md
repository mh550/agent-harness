# Pruning a project's `CLAUDE.md` under the memory cap, by hand (checklist, 2026-11-07)

*(For a `claude` session opened in a project's own directory: hit_list (181 lines, 15 Gotchas), n8n-home (134),
portfolio_site (127, 15 Gotchas) first; any project later. Row F3c of
`docs/plans/2026-11-03-test-suite-redesign-dispatch.md`, Decision 22 (a). Why by hand: the curator trades line for
line inside an over-cap file and never shrinks it (`capCheck`, `decisions/2026-11-07-memory-tiers`), and a longer
instruction file is followed less (`journal/learning/2026-11-07-memory-curator.md` §6). The cap: 120 lines, 15 lines
under `## Gotchas` (`lib/memlint.mjs`).)*

## Before you cut

1. **The project's own `CLAUDE.md` binds**, on how a change lands and what is live. portfolio_site: a PR with its
   preview URL, Michael merges (Vercel deploys `main`). n8n-home: live; this is a docs-only change, nothing is deployed,
   and `/srv/n8n/data/config` is never read. hit_list: its `## Git` section. Change nothing but `CLAUDE.md`.
2. **Not during a harness run of this project**: `harness status` shows none RUNNING for it (a run's coding sessions
   would see two versions of the file, and its curator would anchor on lines you are removing).
3. **Measure first**, and keep the numbers for the PR body:
   ```bash
   harness memlint .          # every finding: size, gotchas, derivable-count, run-scope, decisions
   wc -l CLAUDE.md
   sed -n '/^## Gotchas/,/^## /p' CLAUDE.md | grep -c '^- '
   ```
4. **Aim under the cap with headroom**: at most 110 lines and 12 Gotchas. At exactly 120 or 15 the curator can only
   evict, so its first new fact costs an old one.

## What leaves (in this order; each line goes to one of four places, written down)

1. **Stale Gotchas**: the path, tool or command the line names is gone (`git log -S '<the name>' --oneline | head`,
   `grep -rn '<the name>'`), or the incident cannot recur (the behaviour was fixed; a decision file or test holds it).
   → *dropped as stale*, with the one-line reason.
2. **General facts that belong in `~/.claude/CLAUDE.md`**: true in several projects, about bash, jq, git, Claude Code or
   the box, not about this project (a `set -u` idiom, a `pipefail` trap, a Claude Code behaviour). → *proposed for
   `~/.claude/CLAUDE.md`*: listed in the PR body with the exact line; **never edit `~/.claude/CLAUDE.md` yourself**
   (Michael's file, no run and no session touches it).
3. **Duplicates**: a Gotcha that restates a rule in `## Code rules`, `## How to verify` or `## Where things go` (keep the
   rule, drop the Gotcha); two Gotchas that say one thing (keep the sharper, drop the other); a fact the decisions store
   already holds (keep the pointer, not the prose). → *merged into <line or file>*.
4. **What memlint names**: a stored count (`~1,870 tests`: the suite says it), a run-scoped word (`tonight`, `this run`,
   `as of <date>`). → *dropped* or reworded to the durable fact.
5. **A fact that is a decision or a doc**, not an instruction: a why, a history, a plan. → *moved to* the decisions store
   (one file per decision where the project uses that shape) or the doc it belongs to, with the file named.

## What never moves

- `## Live system`, `## Off-limits`, `## On-limits`, `## Hardware facts…`, `## Hardware and Mixxx rules…`, this repo's
  `## This repo runs Michael's harness runs…`, and every permission or deny rule wherever it sits: **not a line of these is
  cut, moved or reworded** by the prune. A line there you believe stale is a question for Michael in the PR body, not an
  edit.
- The `## Where things go` block (the harness's routing; it is appended to prompts only when the file lacks it).
- The wording of a kept rule. A reworded rule is a rule change, which is Michael's: join duplicates, do not rephrase.

## After you cut

1. `harness memlint .` prints nothing (or only the `decisions` finding the project already carries, which this prune
   does not touch); `wc -l CLAUDE.md` at or under 110; the Gotchas count at or under 12.
2. **Open the PR** by the project's rule (its `CLAUDE.md`; a worktree, a branch, a PR; `gh pr merge --merge` where that
   project allows a session to merge, else leave it for Michael). Title: `CLAUDE.md: under the memory cap (<before> →
   <after> lines, <g0> → <g1> Gotchas)`.
3. **The PR body is the account.** One table, every removed or merged line, nothing summarized:

   | line (as it was) | went to |
   |---|---|
   | `- the suite: ~1,870 tests` | dropped: a derivable count |
   | `- X needs HARNESS_HOME before sourcing lib/*.sh (…)` | proposed for `~/.claude/CLAUDE.md` (true of every project here) |
   | `- never pipe git show into grep -q (…)` | merged into `## Code rules`, the `pipefail` line |
   | `- deploy only through scripts/deploy.sh` | **kept** (`## Live system`; a question for Michael: the script moved to `bin/`) |

   Then the memlint output before and after, and the two counts.
4. **Report** (to Michael, or the supervisor's Status table): the line counts and Gotchas before and after, the PR
   number, the lines proposed for `~/.claude/CLAUDE.md`, and any question raised on a protected section.

## Don'ts, in one place

No file but `CLAUDE.md`. No `~/.claude` edit. No rewording of a kept line. No edit to a protected section or a
permission rule. No prune while a harness run of the project is alive. No `harness` command but `status`, `memlint`,
`report`.
