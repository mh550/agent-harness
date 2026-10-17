# Iteration 4 — Harness v2: a reusable tool with a deterministic driver

**Dates:** 2026-10-16, night (`~/projects/agent-harness`; Pathways config in commit `7d0c1eb`, PR #3).

## Context
The same Pathways slice, about to run for the first time. This time the harness itself is the
thing being engineered: a tool that should work for any of my projects, several runs at once.

## Trigger
Reviewing v1 ([iteration 3](03-harness-v1.md)) raised six problems:
- the edit guard kills a night;
- merges and cleanup were blocked or manual;
- runs collide in one checkout;
- there is no remote control;
- nothing is reusable;
- I wanted the thinking tracked for my portfolio.
([my questions, verbatim](../sessions/2026-10-16-harness-design.md#3-review))

## Design
**Principle: agents do judgment; the driver does bookkeeping.** Everything that must happen every
time is in a deterministic bash driver, not in a prompt:
- running init, syncing git, guarding the list, gating on the suite;
- verifying milestones, tagging, opening PRs, logging metrics.

| Concern | v1 | v2 |
|---|---|---|
| Where it lives | inside the app repo | its own repo; projects keep only `.harness/{config.sh,init.sh,project.md}` |
| Isolation | runs in my checkout | **a git worktree per run** (`~/worktrees/<project>/<run-id>`, branch `harness/<run-id>`, its own port and scratch) |
| Run record | `harness/progress.md` | committed per run: `.harness/runs/<run-id>/{feature_list.json,progress.md,INBOX.md,harness-log.md,metrics.jsonl}`; logs and transcripts in `~/.local/state/harness/…` |
| Init | the agent runs `init.sh` | the **driver** runs it before every session and pastes the output into the prompt |
| Feature-list edits | stop the night | **repair and continue**: revert everything but the session's own `passes`; stop only after 3 in a row |
| False passes | trust the session | a **red suite un-passes**; each finished milestone gets an independent **verify session** (Sonnet), capped at 2 rounds |
| Merging | blocked / manual | per verified milestone: **tag `run/<id>/<m>` and open or refresh a PR** with the evidence; I merge (one tap) |
| Cleanup | manual commands | `harness gc`: removes merged worktrees and branches, locally and on GitHub; unmerged work is never touched |
| Steering | `tmux attach` | phone: edit `INBOX.md` on GitHub (`status: pause/stop`, answers). Box: `harness pause/resume/stop/answer`. Live: a **supervisor** Claude session in the tmux session, reachable through Remote Control |
| Permissions | allowlist ignored in untrusted folders | permissive settings passed with **`--settings`** (works in fresh worktrees); deny only history-destroying commands |
| Cost control | turns only | `--max-budget-usd` per session; per-session cost, duration and turns in `metrics.jsonl` |

## How it was prompted
See [the review questions](../sessions/2026-10-16-harness-design.md#3-review). Decisions with their
rejected options are in [`decisions.md`](../decisions.md) (D-H1 to D-H8).

## Evidence
- **End-to-end test with stub `claude` and `gh`** (`tests/run.sh`), on a throwaway project and a
  local bare origin. 20/20 checks pass. The stub sessions misbehave on purpose:
  - one tampers with another feature;
  - one leaves the suite red;
  - a verifier catches a false pass;
  - a phone edit stops a run;
  - a strict verifier rejects forever.
  The checks also cover two runs in parallel and `gc` after a merge.
- **The test found real problems before any real run:**
  - a verifier that keeps rejecting made the coder and verifier ping-pong until the session cap.
    It is now capped at 2 rounds and the milestone is marked "needs Michael";
  - metrics mixed model aliases and IDs;
  - "features passed" counted sessions, not features.
- **Untrusted-worktree permissions:** a real headless call in a fresh worktree with `--settings`
  ran an allow-listed command with no warning, so no trust dialog is needed per worktree.
- **The classifier again:** it blocked building an automatic fast-forward push to `main` ("Merge
  Without Review"). The design changed to tag + PR, keeping a human review on every merge into
  `main`. I can still turn on GitHub auto-merge myself.

## What worked / what broke
- *(to fill in after the first real run: features passed, sessions, $ per feature, interventions,
  which guards fired, what I changed)*

## Led to
*(after the first run)*
