## Outcome
Delivered. All 19 features (M5-01..10, M6-01..09) passed, were verified and merged (PRs #9 and #10). Tests went from 868 to 1262. The run cost $110.95 over 7.8 h and 27 sessions. First-attempt pass rate was 0.89. The one interruption was M5-06, which parked for Michael from 05:37 on 10-24 to 02:50 on 10-26, about 21 h idle. Nothing was lost, but no work continued during that time.

## Non-passing features by cause
Nothing ended non-passing. Two features needed rework:
- **M5-06 (spec or feature-list problem).** The verify re-check failed it at 05:33 and it parked. The final entry says: "Step 4 verified as Michael reworded it… deck 2 bottom pinned as a 0.8–7.3 % sag". The step asserted a bound that the hardware capture did not meet. It cost 3 sessions and $11.05.
- **M5-10 (too big for one session).** The first session ended `passes=false` after 18 min. The retry took 89 min and passed. I did not confirm the cause beyond the duration.

## Harness behaviour
- **Guards:** 1 `verify_failed` (M5-06, correct: the re-check caught a real mismatch). 0 repairs, 0 red_unpass, 0 limit waits.
- **Entry validation:** M6-02's entry.json was rejected for a 401-character summary against a 400 limit, and the driver recorded a minimal entry. The rule worked, but a 1-character overrun discarded the agent's own summary.
- **Cost split:**
  - Check is $45.87 and review is $19.08, together 58% of spend; build is $32.49.
  - Review costs more than half of build and ran on Opus. Review reports exist for M5-04..08 plus the M5 and M6 milestones, so it ran per feature as well as per milestone.
- **Orientation:** 1.26M tokens over 21 turns (219 s) in total. This is modest.
- **Verify:** 3 sessions cost $2.10. I did not compare evidence rows against steps, so I can't say how thoroughly verify re-ran them. M5-06 shows it can catch a real failure.

## Proposed harness changes
1. **Cap or skip review on small milestones, or run it on Sonnet** (driver config and model routing). Evidence: review was $19.08 of $110.95 here, on Opus, and the M6-08 Sonnet build passed in 3 min. Already proposed in `v2-2026-10-18`, `agent-harness-2026-10-19`, `rane-one-mixxx-2026-10-19`, `portfolio_site-2026-10-20` and the voice-concierge retros, so it is a repeat.
2. **Keep working while a feature is parked** (driver). Evidence: M5-06 parked at 05:37 on 10-24 and the run stopped until 10-26 02:50. M6 did not depend on it. Proposed in the voice-concierge-2026-10-20 retro.
3. **Truncate over-limit entry fields instead of discarding the entry** (entry validator). Evidence: M6-02, 401 against 400 characters. Not proposed before, as far as I saw.
