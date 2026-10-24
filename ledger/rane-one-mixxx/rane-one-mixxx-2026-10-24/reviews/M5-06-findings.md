# M5-06 review (Opus, 2026-10-24): findings and what was done

The reviewer re-ran the doc numbers: all 22 hold rows, the Range and Play presses, the lag grid and bins, the 12 steep
sections, the takeover counts and the fader statistics reproduced. motorRatioFromFader, faderExpected, deviceRatio's
cursor, valueAt and the platter-run option were checked correct. 1012 tests green before the fixes.

## Important (all fixed)
1. The 25 ms "read the fader late" came from device-time windows; the state machine sees the estimator, which lags
   35 ms (deck 1) / 55 ms (deck 2). 25 ms left 0.72 % of margin on 23 (2.28 % held 10 ms against 3 %); deck 2's count
   depends on the delay (7 at 45–50 ms). Fixed: `fader-sweeps` prints the estimator fit too; new
   `DEFAULTS.FADER_LAG_MS` 35 (23: 0 takeovers, 1.65 %); a sensitivity table (0/25/35/45/50 ms) in the doc; D27
   and the core header rewritten; `RETARGET_MS` stays 0; tests pin 3.79/2.28/1.65 % and the 35 ms counts.
2. The fader position is unknown until it moves (no CC 9/41 on port open in 23/24). Fixed: D27 rule (M6 leaves
   `rate` alone, M7 takes the centre, the failure is platter control at the record's real speed); round 2 item.
3. D27 assumed the mapping owns `rateRange`. Fixed: M6 maps against the live `rateRange`, clamped, logs below 0.5;
   the Mixxx formula marked inferred (checked in M6's run); S4 MK3 prior art cited as the alternative.
4. "No dead band at the centre" was wrong: the One snaps the centre to 8192 and has end zones (1–18 and
   16254–16382 never sent). Fixed in the doc and the plan.

## Minor
- 5 Pairs not always in one µs (9 and 11 with the LSB 20–190 µs later): fixed in the lib header and doc.
- 6 RETARGET_MS header misleading: rewritten.
- 7 The RETARGET_MS 50 column has no CLI option: labelled a one-off `node` read of the functions behind
  `--expected fader`, and pinned in tests/platter-fader.test.mjs.
- 8 Spread 0.03 % → 0.06 % relative (top 0.01 %): fixed. 9 "estimator's 200 ms windows" were the device column: fixed.
- 10 35.28 s is mid-descent, not the slow end: the doc now splits the 4 bottom takeovers from the rest.
- 11 Deck 2's 45 ms is weakly set (40–55 ms within 0.0001): stated.
- 12 The fader's 88–96 ms is by construction; the steep lags carry the 4–6 ms window bias: both stated.
- 13 `lag()` scores windows with Play off too: documented in the lib (fine for 23/24).
- 14 `timed()` keeps zero-tick deltas, unlike platter-format: kept on purpose (their time passed), commented.
- 15 Tests: the vacuous lookahead replaced (the one takeover is before Play); the takeover lookup now takes the
  `scratching` update in that µs; margin and delay-sensitivity pins added.
