# Debrief · 2026-11-17 18:50

_runs since 2026-11-10 02:54:54: agent-harness-2026-11-10 · claude-sonnet-5-5, $0.1370913 · context: /home/mh550/.local/state/harness/debrief/2026-11-17-184949/context.md_

## Headline
Merged to main for agent-harness: V1 (3/3, PR #178) and V2 (4/4, PR #180), all 7 features passing on the first attempt. Nothing is blocked.
Spend was $35.16, with 7/7 passing and tests 2000 → 2047. The usage window is open, and seven_day is at 19% (resets Sun 17:00).

## Runs
### agent-harness-2026-11-10 (agent-harness) · done
- Features: 7/7 passing, 7 verified, 7 merged. V1 (event kind=memory, memory notification) and V2 (merge/close verbs, n8n-home checklist) each ended with an Opus review.
- Tests went from 2000 to 2047. There were 0 flakes, 0 fix rounds, and first-attempt pass rate was 1.0.
- Cost was $35.16 ($5.02 per feature) over 3.6 h wall. Review took 23.7% of the cost, and one of the 2 reviews found nothing Critical or Important.
- V2 went over its check budget (+28 against 25). The driver recorded why: each refusal and stub-gh behaviour is its own check.
- Memory PR #181 is open and was left for Michael (MEMORY_POLICY=pr). Its review had 1 fact fail (facts/1, q2, touching docs/architecture.md:81, lib/record.sh:499, tests/unit/curator.test.mjs:215 and tests/checks/no-answer.sh:5). The memory-review session was also denied `git push` and `gh`.
- The retro proposed 2 changes (below). Suite re-runs recurred: V2-01 and V2-03 each ran the suite twice at about 270 s.

## Needs Michael
- Memory PR #181 (agent-harness-2026-11-10, memory log): decide whether to merge it. Check its failed fact, facts/1 q2, first.
- The V2-03 checklist, `docs/plans/2026-11-10-review-surface-n8n-home.md`, has a step only you can do: set EVENT_V2 in n8n-home. The doc gives the undo.

## For the next interactive session
- No merge conflicts, and no held or refused merges.
- The branch has 2 commits ahead and 32 behind main, so it is stale. Run `harness gc` on agent-harness if you want it cleared.
- Open `proposed` retro items, most seen first:
  - `suite-time-budget`: cap or warn on repeated session suite runs. Seen 12 times, and re-raised by this run.
  - `verify-question-noise`: classify "Default taken" questions as info versus blocking. Seen 2 times, and re-raised by this run.
  - `memlint-before-session-end`: seen 1 time.
  - `session-entry-write-guard`: seen 1 time.
  - `step-contradiction-lint`: seen 1 time.
  - `record-push-retry-noise`: seen 1 time.
  - Seen 0 times: `no-retry-on-denial`, `base-branch-runs-reverted`, `restrict-merge-tree-base`, `slot-copy-overwritten-on-merge`, `cli-verbiage-and-syntax`, `git-provider-migration`, `rebase-pending-card`.
- Odd log line: "review V2-04: … at or over 0; opus" shows a review threshold of 0. That may be a threshold or logging bug.
- V2-03 logged a project fact of 170 characters, over the 160 limit.
- `harness trends` shows `started` 2026-11-11T00:21 and `ended_at` 05:14 in summary.json, while the run log says it ended 00:14. The timestamps look inconsistent.
