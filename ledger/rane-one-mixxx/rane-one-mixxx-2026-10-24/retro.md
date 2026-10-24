## Outcome
Partly delivered. 9 of 19 features passed (M5-01..M5-10 except M5-06), tests went from 868 to 1057, and cost was $72.37 over 5.16 h and 14 sessions. M5-06 failed the verify re-check and was parked "waiting on Michael". The 9 M6 features are blocked behind it, and nothing is verified or merged. The main reason is a spec problem in M5-06 step 4: it demands a result the hardware can't produce.

## Non-passing features by cause
- **M5-06** (2 sessions, 38 min, $10.15): spec or feature-list problem. From the INBOX question: "deck 2 at 0 ran 0.464×, 0.496× and 0.493× in the three sweeps… One value, three speeds: no function fits."
- **M6-01..M6-09** (9 features): depend on a failed feature. M6-01's detail reads "waits on M5-06, which is waiting on Michael". M6-01 waits only on M5-03 and M5-06, so a single parked check froze the whole milestone.

## Harness behaviour
- **Guards:** only `verify_failed` fired, once (M5-06). That was correct: the first build session had marked it passing on a step it couldn't meet. There were 0 repairs, 0 `red_unpass` and 0 limit waits. The retry was a 4-minute session that confirmed the impossibility and parked it, which was sensible.
- **Verify:** the single M5 verify session was Sonnet, 46 turns, 297 s and $1.15. It named the failing step with specifics, so it did real work. `summary.json` has no per-step evidence counts, so I can't confirm every step of the other 9 features was re-run.
- **Cost:** check sessions were $41.52 (57%) and review $13.70 (19%). M5-10 review ran 108 min across 2 sessions, the first of which failed, for $13.70. The M5-06 build-time review found 4 Important issues, so some of it was useful.
- **No gain:** the run stopped at 05:37 with 4 h of driver time unused while M6 sat blocked. Verify ran on M5 after the whole milestone, so M5-06's unreachable step surfaced only after M5-07..M5-10 were built on it.

## Proposed harness changes
1. **Run a mid-milestone verify or step dry-run for check features (driver and plan prompt).** Evidence: the M5-06 step 4 impossibility sat unflagged through 4 more features. This repeats the "dry-run steps at plan time" proposal from `rane-one-mixxx-2026-10-19`, `voice-concierge-2026-10-20` and `hit_list-2026-10-20`.
2. **Let a parked feature block only its true dependents (driver).** M6-01 declares dependence on M5-06, but later M6 features such as the docs and review ones, and any that don't touch the parked work, could proceed. Evidence: 9 M6 features idle for the rest of the run. Proposed in `voice-concierge-2026-10-20` and `rane-one-mixxx-2026-10-19`.
3. **Route per-milestone review to Sonnet or cap its length (driver config).** Evidence: review was $13.70 and 1.81 h of this run. Proposed in 8 earlier retros and still unfixed.
