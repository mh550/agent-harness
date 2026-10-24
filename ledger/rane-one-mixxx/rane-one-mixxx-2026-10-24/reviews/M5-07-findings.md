# M5-07 review (Opus, read-only, 2026-10-24)

Important: none. Suite 1022/1022. Re-derived from the raw JSONL with its own pairing: PAIR_WINDOW_US 279 µs (23),
TIMER_GAP_MAX_US 15,176 µs (18) / 12,038 (32), WRAP_JUMP 1.477× after a ≥ 2.9 ms gap (32), max growth 3.535× (29);
exactly three −1s under 0.25 (08, 15 ×2), next lowest 0.695 (18 at 2.710 s). Decoder/estimator/D24 interplay: no
misfire found. D25 test indices traced by hand: correct.

Minor, and what was done:
1. BACKSPIN_RATIO / HELD_RATIO alone can be reset silently by the pair rule: **fixed** in D25 (M7 settings need max
   under −0.4 / 0.2).
2. Strict pair check vs D25's "above": **flagged** in D25 as a question for Michael.
3. TIMER_HZ +0.0001 % on 15 counts the two lost intervals: **fixed** (header, plan, research doc note; ≈ 2,822,497).
4. 0.70 → 0.69: **fixed** everywhere.
5. AB_ALPHA/AB_BETA lost UNVERIFIED: **fixed** (header, plan).
6. BURST_MS / RPM_45 say "not a round 2 item": **kept** (true); raised under Proposed changes.
7. TAKEOVER_MS evidence (21's sags don't test it) and EURO_BETA/EURO_D_CUTOFF_HZ scratch lag: **fixed** (23 at
   35 ms cited; scratch lag UNVERIFIED).
8. D28 risk sentence understated the hold: **fixed**.
