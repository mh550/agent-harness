## Outcome
35 of 37 features passed (tests 122 → 256, $84.47, 5.9 h wall). Milestones T0, T1, T3, T4, T5, T7 and T6 were each verified and merged, as PRs #6–#12. S-01 passed but wasn't verified or merged. S-02 stayed `passes=false`, so the run ended "blocked on S-02" with S-03 never tried. The cause was a contradiction in the S-02 feature list, not the code.

## Non-passing features by cause
- **S-02 (not done): spec or feature-list problem.** Its final detail reads: "The command is built and works, but two of its steps contradict each other. Step 1 orders songs by start time, so Leroy's Latin Lament (started 19:55Z) comes first. Step 2's example…" Step 1 says `started_at` order; step 2's test expects Rico Suave Bossa Nova before Leroy's Latin Lament.
- **S-03 (not reached): depends on a failed feature.** The log says "blocked: the remaining features wait on S-02". But S-03's `depends_on` is `null`, and it is a docs-only task with no code. The driver blocked it on its own, with no dependency in the feature list. That is a harness bug, not a real dependency.

## Harness behaviour
- **Guards.**
  - The T4 verify guard worked as designed. At 13:42 it flagged "evidence short of the steps" and re-ran on opus. At 13:49 T4-08 failed the re-check, and a retry then passed.
  - The usage-limit wait (46 min at 15:15) was correct.
  - Repairs and red-unpass guards never fired.
- **Waste.**
  - S-02 got a second session (1 min, $2.23 across both) that only re-confirmed the contradiction. Writing the test to the step-2 order and noting the conflict would have been cheaper.
  - S-03 was skipped for about $1 of work. There was no reason to stop the run there.
  - The 20 "environmental" sessions out of 68 (29%) look like retries and limit stalls.
  - Driver time was 0.98 h (17% of wall).
- **Verify.**
  - I did not check evidence rows against steps in `progress.md`. The T4 guard fired once. Verify entries exist for every milestone, with some timestamps out of order (e.g. 20:30 for T5 against a run that ended at 16:16).
  - `metrics.jsonl` verify rows have `cost: null` and `minutes: null`, so per-verify cost and time can't be audited.
  - There was no verify for the stretch milestone, which is why S-01 stayed unmerged.

## Proposed harness changes
1. **Block only on declared dependencies** (driver blocking logic). The "remaining features wait on S-02" rule held back S-03, which had `depends_on: null`. Skip the failed feature and continue with independent ones. I found no earlier retro proposing this. The only prior pathways retro is a one-line stub (see 3).
2. **Handle spec contradictions in a session** (builder prompt and driver). When a build session reports contradictory steps, the driver should do one of three things:
   - run a cheap, bounded "reconcile" step that picks the simplest reading, records it as `D<n> *default*` and amends the step;
   - or park the feature straight away, with no second identical retry;
   - or have `plan` or the init session lint feature steps for contradictions before the run, since this one is statically detectable.
   
   Evidence: S-02's two sessions, $2.23. The project's own CLAUDE.md already says to take the simplest reversible default. Not proposed before.
3. **Make metrics complete and run a real retro session** (`metrics.jsonl` writer and driver). Verify rows have null cost and minutes, and the previous pathways run's retro was "written by hand: v2 had no retro session". Also run verify for the stretch milestone so S-01 isn't left unmerged. Not proposed before.
