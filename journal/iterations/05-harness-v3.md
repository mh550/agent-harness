# Iteration 5 — Harness v3: merges itself, waits out limits, queues nights, learns from its runs

**Dates:** 2026-10-17, afternoon (`~/projects/agent-harness`; project migrations pathways#5 and dj-crate-streaming#4).

## Context
The first v2 night ([evaluation](../runs/2026-10-17-evaluation.md)) delivered 26 passing features (18 verified) across two
projects and then lost five hours to one bug: the usage-limit detector didn't recognise the real message.

## Trigger
Michael's review of the evaluation, verbatim in substance:
- partial runs need "a clear, intelligent solution", and **merges should be handled by the harness/agents** so
  mornings and nights aren't config work;
- a fine-grained understanding of the system, for maintaining and extending it;
- the writeup per run (passing, tests, spend total / per feature / by role) as a standard output;
- agreed with the fixes and with Part B; "ensure the results of different harness runs are captured, so we can
  develop a self-improving process"; parallel nights should queue, and queueing a whole night should be easy.

## Design
| Concern | v2 | v3 |
|---|---|---|
| Usage limits | regex on the result text (missed the real message); attempts burned | structured `api_error` fields first, $0 rule, real fixture in tests; wait until the rejected window's `resetsAt`; one `LIMIT_UNTIL` for every run on the box |
| Merging | one whole-run PR for Michael; "final verified" tag on every run | each verified milestone merged through its own PR by the driver, in order; no `final` tag (D-H13, D-H17) |
| Partial runs | merge or rerun by hand | verified milestones already merged; a continuation queued for time/limit ends; "blocked"/"needs Michael" notified |
| Scheduling | first non-passing feature, whatever failed before it | dependency gating with `after` (D-H20) |
| Verify | trusted the session's summary (29–40 s verifies) | one evidence row per step, counted by the driver; thin → one re-run on Opus |
| Suite | run by init.sh, by the session and again by the driver (dj: 7 min × 2 per feature) | one cached command keyed on file contents, shared by all |
| Project config | `.harness/{config.sh,init.sh,project.md}`, ~150 lines | `CLAUDE.md` + `POLICY=` + conventions; run scope via `--spec`/`--brief` (D-H15) |
| Live systems | build-only | `POLICY=live-staged` protocol in the harness, project facts in `CLAUDE.md ## Live system` (D-H16) |
| Metrics | last result event only (time undercounted 2×) | driver wall time, summed turns, roles; `summary.json`, `report.md` |
| Learning | a human evaluation | retro session per run, `ledger/`, `harness trends`, calibration into the initializer (D-H19) |
| Several runs | parallel, racing one limit | a queue, `MAX_PARALLEL_RUNS=1` by default, `--until` (D-H18) |
| Status | "running" while tmux lived | driver pid; `ended: <reason>` |

## Evidence
- **An independent Opus review of v3 before its first use found 2 Critical and 8 Important bugs**, all fixed with a
  test each. The two Critical ones would have merged unverified code: a verify session refused by the usage limit
  counted as "holds" (it reproduced M1 and M2 merging with zero evidence rows), and a session cut off by the limit
  kept its own `passes=true`. Others: verify/retro edits reaching main, a tag carrying another milestone's half-done
  work, a self-paused driver blocking the queue forever, two queued starts sharing one run id, `continue` un-stopping
  a live run, `gc` deleting progress logs the ledger didn't keep. The fix for "what may merge" became one invariant:
  **the tree that lands on main is byte-for-byte a tree that was verified** (`git merge-tree` == the tag's tree).
- `tests/run.sh`: **48/48** checks (v2: 22), including the real 10-17 limit lines, a limit that cuts a session off
  mid-work, a $0 session, a window set by another run, gating, an independent milestone that verifies but doesn't
  merge before an unverified one, thin evidence escalating, a refused merge fixed later with `harness merge`, a
  paused run finished by `harness continue`, the queue, the ledger, `gc` of record-only branches.
- New limit detection on the night's real transcripts: `26-T5-02` and `06-N2-01` → limit with reset 06:10. Two
  mistakes caught by checking against real transcripts, not stubs: the first version picked the 7-day window's
  reset (Sunday 18:00), and the review's "final result only" rule missed `22-T4-09`, whose limit result is followed
  by an empty result from a background task. The rule is now "the last substantive result", and the stub replays
  that shape.
- `harness report` rebuilt both v2 runs' writeups from their records (numbers match the evaluation).

## What worked / what broke
*(after the first v3 night)*

## Led to
*(after the first v3 night)*
