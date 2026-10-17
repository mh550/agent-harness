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
First real run: two projects in parallel, 2026-10-17 02:24 → 05:23 EDT
([Pathways](../runs/threads-2026-10-17.md), [dj](../runs/dj-2026-10-17.md),
[evaluation](../runs/2026-10-17-evaluation.md)).

- ✅ **The loop held for 2 h 49 min.** 27 real coding sessions, each one feature, test-first, inbox read, progress
  logged, committed and pushed. **0** feature-list repairs, **0** red-suite un-passes, **0** permission denials,
  **0** human interventions, and no live-system command in the dj run.
- ✅ **Delivered:** Pathways 21/37 features, tests **122 → 211**, T0/T1/T3 verified and tagged; dj 5/19, the
  duplicate cleanup (plan → repoint → trash) with a staged runbook, N1 verified. **$2.23** and **$4.51** per
  passing feature; ~7 and ~20 min of session time per feature.
- ✅ **Fable initializer:** two lists with zero repairs, executable steps and real handover notes, for 18 % of the
  night's cost.
- ✅ **Tag + PR per verified milestone** gave Michael something precise to merge (`run/threads-2026-10-17/T3`).
- ❌ **The usage-limit backoff never fired.** Both runs hit the plan's five-hour limit at 05:13. The real message
  ("You've hit your session limit", `api_error: usage_limit_reached`) didn't match the regex, which had been tested
  only against a message I invented for the stub. 45 sessions were counted as failed attempts in 6 minutes;
  Pathways stopped at `MAX_SESSIONS=40`, dj ran out of features, both with 5 h of budget left.
- ❌ **Two parallel runs share one plan limit** and spent it in under 3 h.
- ❌ **Verify sessions were too thin** (29–40 s on Pathways). The defects that matter were found by an Opus review
  the next morning: a half-built `/live?graph=`, a README promising it, unrecorded decisions, and four Important
  gaps in dj's trash step.
- ❌ **Mislabels:** every run ends "final verified and tagged"; `harness status` says "running" for finished runs;
  metrics reported 1.2 h of session time for 2.54 h of real sessions.
- ❌ **Per-project configuration is heavy and fragile:** ~150 lines per project, of which ~15 are durable facts
  only the project knows. dj's policy was edited 46 s before the run and came out contradictory ("never operate"
  heading, "you can test live" bullets, "code only" scope).

## Led to
Harness v3, not built yet. The ranked list is in [the evaluation](../runs/2026-10-17-evaluation.md#ranked-changes-for-harness-v3);
proposed decisions D-H11 to D-H16. The first three changes go in before the next unattended night:
1. limit detection on the structured error, plus a fake that replays the real message;
2. a shared limit marker across parallel runs;
3. an honest end of run (no "final verified" unless it is).
Per-project configuration moves to conventions, one `POLICY=` line, `CLAUDE.md` and a run brief (D-H15).
