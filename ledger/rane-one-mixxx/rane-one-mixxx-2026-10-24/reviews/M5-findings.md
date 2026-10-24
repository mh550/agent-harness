# M5 review findings (M5-10, 2026-10-24)

Input: `reviews/M5.diff` (6398 lines), `git diff fad1f45..91452cf` with the harness files left out (`cmp` against a
fresh diff: identical). fad1f45 is "HARNESS: start run rane-one-mixxx-2026-10-24", 91452cf the M5-09 commit. The
reviewer also read the 248-line diff of the interrupted first M5-10 session (6b0db24: header round 2 step numbers,
three header tests, Play no longer "assumed" in the platter tools' help, backlog sizes, spec §5 M5 marked done).

Reviewer: one Opus subagent. It read the diff from a copy in `/tmp/harness/rane-one-mixxx/rane-one-mixxx-2026-10-24/review-m5/`
and had read-only access to the repo. Experiments ran in a `git archive` copy there. No MIDI was sent and no Mixxx
was run. The per-feature reviews (M5-04..M5-08) had fixed their own findings, so this pass looked across M5. It was
asked to wrap up after about an hour, so some mutations were left unchecked (listed below).

I re-ran each Important reproduction before fixing it. "Failing test first" means the test was added and run red
before the fix; the red output is quoted. Test and fix are in the same commit, **7dcf65b**.

## Critical

None.

## Important

| # | Finding | Outcome |
|---|---------|---------|
| I1 | **Spec answer 6 said "held through Play (17, 31)" occurs, but no census take goes `stopped → held` (T5a) and T6 never fires.** In 17 and 31 the motor is already at speed when the hand grabs (T7 → `scratching`, then T10 → `held`). Summed transitions over every `platter-run-all` take: 0 `stopped>held`, 14 `motor_at_speed>scratching`, 5 `scratching>held`. The only `untrusted` samples (15, 21) follow the start backlog with the deck stopped, so D24 is never armed either. `HELD_START_MS`'s "24–49 ms" only shows a free platter isn't read as held. | **Fixed** in 7dcf65b. The header's `HELD_START_MS` entry, the analysis doc (§ Spin-up, M5-07 list), the plan row and spec answer 6 mark T5a/T6 UNVERIFIED (round 2 step 2) and D24 UNVERIFIED (M7). `HARDWARE-TESTS.md` round 2 step 2 now holds the record through a Play press on each deck (36 s takes; round 14.3 → 14.5 min). Test written first: "I1: no census take goes stopped -> held, …" in `tests/m5-review.test.mjs`. Red: `The input did not match /T5a[^.]*UNVERIFIED[^.]*round 2 step \d/` on the header entry (the capture assertions held). |
| I2 | **`HANDBACK_TOL`'s citation measured against the wrong reference.** "21: 20 of deck 2's 1,180 leave 1 %" is against the take's mean (0.99820). The state machine compares `r/e − 1` with e = 1 (D27, no trim): against 1.0 it is **45** windows, all slow. | **Fixed** in 7dcf65b: the header, the plan row and the analysis doc's M5-07 list give 45 off 1.0 (20 off the mean). Take 15 against 1.0 is −0.30/+0.26 %. The verdict stands (31 and 32 hand back). Test written first: "I2: take 21 has 45 of 1,180 50 ms windows more than 1 % off 1.0, …". Red: header did not match `/45 of deck 2's 1,180[^.]*1 % (off\|from) 1\.0/` (the 1,180 and 45 counts held). |
| I3 | **Spec A3 stated the Shift+Slip motor-off toggle as a fact.** Take 25 toggled it with both motors stopped and never pressed Play in the mode; the analysis doc already says it rests on Michael's account. | **Fixed** in 7dcf65b: A3 says "per Michael … UNVERIFIED by capture" and why (round 2 optional 11 stays). Test written first: "I3: spec answer A3 marks what Shift+Slip's mode does UNVERIFIED by capture". Red: `/motor-off mode[^.]*UNVERIFIED/` did not match. |

## Minor

| # | Finding | Outcome |
|---|---------|---------|
| M1 | Spec A1 credited both timer rates to take 21 (deck 1's is 15) and gave deck 1's period range for both decks. | **Fixed** in 7dcf65b (deck 2 3598.6–3600.1, analysis doc § Platter format). |
| M2 | D25 said `HELD_EXIT_RATIO` is not in the tunable set; it is (`TUNABLE`). | **Fixed** in 7dcf65b: M7 must check `HELD_RATIO` against `HELD_EXIT_RATIO`; only `BACKSPIN_EXIT_RATIO` is outside the set. |
| M3 | D27 called `FADER_LAG_MS` "a D25-style user setting"; it isn't in `TUNABLE`. | **Fixed** in 7dcf65b: "a DEFAULTS key the glue reads; M7 may expose it". Adding it to `TUNABLE` is M7's call. |
| M4 | `MOVE_RATIO`'s header said 23–26's stray pairs are all start backlogs; 26's lone pair is at 17.257 s. | **Fixed** in 7dcf65b. |
| M5 | Stale UNVERIFIED notes M5 had verified: core (saturation comment in the estimator), `tools/lib/platter-run.mjs` (Play), `tools/lib/platter-analysis.mjs` (saturation; "−1 only after gaps ≥ 5 ms", contradicted by D28), `tools/lib/synth-platter.mjs` (3600 vs 3584). | **Fixed** in 7dcf65b. The header test still scans only the header (a whole-file scan would hit the many legitimate UNVERIFIEDs in code). |
| M6 | Spin-up 0.1 crossings truncated (21: 23.595 ms printed as 23) while 0.5 is rounded. | **Fixed** in 7dcf65b: 24 ms, "24–49 ms" in the header, plan and analysis doc. |
| M7 | Take 24's takeover count mixed entries to `scratching` (5–7, "6 at 35 ms") with hand-overs to the platter (5, `platter-run-all`). | **Fixed** in 7dcf65b: the header and D27 name both metrics. |
| M8 | D1 had no `To undo` line after its in-place update. CLAUDE.md lists settled decisions as D1–D8, D13 though D25 is Michael's too. | **Fixed** (D1 To undo) in 7dcf65b. CLAUDE.md left alone: **proposed change** in the progress entry. |
| M9 | The reverse control's identity conflicts: Michael's note on 18 says a deck pad, the analysis proposes note 16 (a deck button), round 2 step 4 points at `off ch5 10`. | **Fixed** in 7dcf65b: the analysis doc's B5 paragraph states the conflict; round 2 step 4 settles it. |
| M10 | D28's disclosed risk holds with margin: the only real markers passing the 2.9 ms test are in 07's backlog at fractions 0.932 and 0.957 (≫ 0.25). A real fast-then-stop inside a host burst would be bounded wrongly; no capture can show it. | **No change**; for M7: log `glitchMarkers` in telemetry. |

## Ten sampled numbers (`docs/research/2026-10-24-census-analysis.md`)

All ten MATCH, re-derived with the commands the document states (`C=captures/2026-10-23-census`):

| # | Group | Claim | Command | Result |
|---|---|---|---|---|
| 1 | hand | 09 net +36,008, +35,994 after the backlog | `tools/analyze-platter $C/09-hand-d1-ten.jsonl [--phases 0.001-31]` | MATCH |
| 2 | hand | 13 net +35,987 | `… $C/13-hand-d2-ten.jsonl --deck 2` | MATCH |
| 3 | hand | backlogs 07 138 messages −4, 29 74 +10 | analyze-platter on 07, 29 `--deck 2` | MATCH |
| 4 | motor | period 3600.0 (21 shift 0.1 corr 0.88; 15 0.3, 0.99) | `--phases 4-63 --period 3600` on 21 and 15 | MATCH |
| 5 | motor | 15 −117,950 ticks, 2,822,403/s; 21 +117,792, 2,822,501/s | `--phases 4-63` | MATCH |
| 6 | motor | 21 spin-up 23/125/216/272 ms | `tools/platter-windows $C/21… --deck 2 --from 2.103 --to 3.603 --window-ms 100 --cross 0.1,0.5,0.9,0.99` | MATCH (23.595: rounding, M6, now 24) |
| 7 | motor | backspin lows 18 −2.154/−2.156, 32 −2.346/−2.349 | `platter-windows --json` | MATCH |
| 8 | motor | hold 16.4/s ≤ 0.0175 (17); 10.2/s ≤ 0.0125 (31) | `analyze-platter --phases 3-7.5`; `platter-windows --window-ms 200` | MATCH |
| 9 | pitch | 23 top 1.49929; 24 bottom 0.46379; lag 25/35 and 45/55 ms | `tools/fader-sweeps $C/23…`; `… $C/24… --deck 2` | MATCH |
| 10 | census | 134 rows; Shift 41/78/15; diff 125/12/75; confidence 57/72/12 | `tools/census` (7 takes, `--shift 16:50`), `--diff`, `grep -c` | MATCH (regenerated map identical to the reference) |

Also matched: 01's 193 messages / 110 rows; `platter-run-all` (24 takes, 0 flips under 20 ms; 24 → 5 hand-overs);
CC 0 passes; D28's 0.695 at 18's 2.710 s; `PAIR_WINDOW_US` 279 µs; `TIMER_GAP_MAX_US` 15.2/12.0 ms; `TAKEOVER_TOL`
floor on 21 (0.025 → 0 takeovers, 0.024 → 1, which I re-ran); Mixxx 2.5.6 `common-controller-scripts.js` rate inversion (D27).

## Checks

- (a) Header: all 36 DEFAULTS keys cited to a take or decision, or UNVERIFIED with a round 2 step or a reason
  (`RPM_45` D26, `BURST_MS`/host stall M7, a real `WRAP_JUMP` wrap M7, `AB_*` unused). After the fixes, the first
  session's header tests stay green, and they fail on the M5-09 header (10 UNVERIFIED sentences with no step, 6 bare
  "round 2").
- (b) `To undo`: D23–D29 had one; D1 was missing it (M8, fixed). D25's undo names the M7 `<settings>` block that
  doesn't exist yet. That is accurate as a plan, and dropping the overrides also drops the pair fallback.
- (c) Spec §5 M5: every answer and open question has a take or UNVERIFIED with a reason, after I1, I3 and M1.

## Mutations

The reviewer mutated the core in its scratch copy and ran the platter tests. All 12 mutations it finished were
killed: D29 position/advance/absorb/peak without the direction, D25 pair fallback and `<=`, fader `/8192`, D28
ignoring ticks, `maxGapShrink` not gated, T3 exit not mirrored, eRose and `low` only for e > 0. Not checked (time):
`TUNABLE` without `SPINUP_MS`, backspin validated with `isNumber`, `d = 1` in `next()`, clock direction from `lastE`
(left unpinned on purpose, D29), the glitch host-gap check removed, `FADER_DIRECTION` ignored, six tool mutations.

## Simplifications

Applied in e2c7eea. `tools/platter-run-all --json`, `tools/platter-windows 21 --deck 2
--window-ms 50 --json` and `tools/fader-sweeps 24 --deck 2 --json` are byte-identical before and after:

1. `NOMINAL` (ticks/s at ratio 1) is defined once, in `tools/lib/platter-format.mjs`, and imported by
   `platter-windows.mjs` and `fader-sweeps.mjs`; it was hard-coded in both.
2. `timedDelta` in `platter-windows.mjs` lost its `markerMin` parameter, which was always `MINUS_2`.
3. The decoder's wrap check computes `shrink` once instead of testing `perTick !== null && lastPerTick !== null`
   twice (`mapping/rane-one-platter.js`).

Deferred to M9's cleanup, with the CLI scaffolding (M4-findings #11): the three "timed delta" predicates
(platter-format, fader-sweeps, platter-windows), `deviceRatio()` vs `summarize`'s sums, `isPlatter` copied into
fader-sweeps, `tickDelta` vs `wrap`, three copies of Play-press detection, `lag()`'s grid fit, `CLOCK_STATES` in the
core and `platter-run-all.mjs` (the core is plain script and doesn't export it), and `pair()`'s array return. Each one
touches pinned tool output. None changes a number.
