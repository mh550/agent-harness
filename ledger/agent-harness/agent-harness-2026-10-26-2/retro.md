## Outcome
Delivered in full. All 12 of 12 features passed and were verified, and both milestones merged to main (F1 as PR #27, F2 as PR #28). The run took 5.05 h wall time and cost $35.45 ($2.95 per feature) across 15 sessions, with no continuations. `first_attempt_pass_rate` was 1, `verify_fail_rate` 0 and `rework` empty. The ledger lists this run's start as 12:30:59 and the log shows 08:51 timestamps, so the log appears to be in a different timezone from the summary.

## Non-passing features by cause
There are none. No feature has cause "not done", and all `cause` fields are null. There were 0 environmental sessions, 0 repairs, 0 red_unpass and 0 limit waits.

## Harness behaviour
- **Guards:** none fired apart from 2 merges (`verify_failed` 0, `verify_escalations` 0). The merges were correct, and each milestone was verified and tagged first.
- **Review cost:** review was $8.76 of $35.45 (25%) and took 0.99 h. F1-06 was a review feature costing $5.05 and 35 min. Both milestones had 6 features and nothing needed rework, so review found nothing that mattered.
- **Orientation:** this cost 1.6M tokens, 22 turns and 584 s. Context packs were 4–8 KB, with 17 and 23 items left out for the two milestones.
- **Build time:** F1-05 took 47 min, but no guard fired.
- **Verify:** it is cheap ($0.39 for 2 sessions, about 585k cache-read tokens) and ran on Sonnet. The F2 verify commit says "33 hold, 0 fail", so it checked 33 items. I did not compare evidence rows with the step count. `summary.json` has no field for that, so I could not confirm that verify really re-ran each step.
- **Timestamps:** the log timestamps disagree with the summary's `started` by about 4 h. They are probably in a different timezone, and the mismatch is confusing when correlating events.

## Proposed harness changes
1. **Skip or cap the per-milestone review when the milestone is clean** (driver config). Skip it when there were no rework or verify fails, or when the milestone has 6 or fewer features. This run: review $8.76 (25% of cost), 0 findings that caused rework. Proposed before in `v2-2026-10-18`, `agent-harness-2026-10-19`, `rane-one-mixxx-2026-10-19`, `portfolio_site-2026-10-20`, `portfolio_site-2026-10-20-2`, `voice-concierge-2026-10-20` and `voice-concierge-2026-10-21`. It is the eighth repeat and still unfixed.
2. **Route review to Sonnet** (driver model routing). Sonnet verify costs $0.39 for 2 sessions, while Opus review costs about $4 each. Proposed in `voice-concierge-2026-10-21`.
3. **Record verify evidence in `summary.json`** (`lib/summary`). Add steps checked versus evidence rows per milestone, and log timestamps in UTC. Without this I could not tell whether verify re-ran every step, and the log and summary times disagree. This is new, and low priority.
