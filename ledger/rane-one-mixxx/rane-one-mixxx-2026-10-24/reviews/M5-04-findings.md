# M5-04 review findings (Opus, 2026-10-24)

The reviewer re-ran every command in `docs/research/2026-10-24-census-analysis.md` § Platter format against a snapshot
(HEAD + the diff). The pairing counts, histograms, backlogs, net ticks, markers table, band deltas, period figures,
the touch-take listings and the alt-jog counts all matched. Ten findings, all fixed:

1. Important: "saturation confirmed / VERIFIED" overclaimed. The device-time test reaches only −1s with two timed
   neighbours (4 in 07/12/29, 11 in the session). Fixed: the doc, D23, D24 and the core header give the 11 (7 at
   0.97–0.99, 1 at 0.80, 3 at 0.17–0.18) and rest the claim on the near-limit band deltas.
2. Important: "none forward in about 1,830" did not re-run. Fixed: `--markers` now prints `passes through CC 0 with
   timed neighbours`. Over every platter take: 1,306 backward (3 at −1), 5,077 forward (0 at −1).
3. Important: the 1.40× bound behind SHRINK is broken by the census (3.53× in take 29). Fixed: SHRINK = 4, with the
   census figure cited. The 0.17–0.18 exceptions are still flagged.
4. Minor: the hand backlogs are not all markers (07: 13 timed). Fixed with per-take counts.
5. Minor: the touch taps are 6 and 3 one-tick moves, not 5 and 2. Fixed in the doc and spec §2.
6. Minor: the take-events test for take 14 didn't check the channel, and take 10 was unpinned. Fixed: both are checked
   via `--json` (channel, type, alternation).
7. Minor: the decoder pins on 09/13 allowed ±8. Fixed: exact values.
8. Minor: the period tests used a noise-free sine. Fixed: a jitter + ramp test over 8 noise sequences. While fixing it
   I found that one noise sequence gives the same error from any trial, so trial agreement says nothing about
   precision. The doc now gives precision from sub-windows (deck 1 ±0.2, deck 2 ±0.5).
9. Minor: `--period`'s "not found" didn't say why. Fixed: `reason` "short" or "shift", and a separate message for each.
10. Minor: the same-ms count was inconsistent across takes. Fixed.
