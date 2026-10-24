# Progress log · run rane-one-mixxx-2026-10-24

What this is: the shared memory of this harness run. Every session appends one entry **at the top** (newest
first) when it finishes: what it built, what it verified (commands and numbers), what it could not do, and
questions for Michael. Sessions start with an empty context; this file, `feature_list.json`, `brief.md`,
`CLAUDE.md`, `docs/spec.md` and `docs/decisions.md` are all they know.

How to read `feature_list.json`: features are in priority order; the harness hands a session the first
feature whose `passes` is false and whose `after` dependencies all pass. A session edits only its own
feature's `passes`. Steps are what the verifier re-runs, so meet them literally (names, numbers, commands).

How Michael steers: edit `INBOX.md` on this branch (`status: pause|stop`; answers under `## Answers`).
Every session reads it at startup. Michael's brief for this run is `brief.md` next to this file; it wins
over the spec on scope: **M5 then M6, nothing else, no M7 platter wiring.**

---

### 2026-10-24 12:40 · M5-06 · not yet (parked)

- Re-attempt after the M5 verify failed step 4. **Step 4 can't hold as written:** deck 2's fader bottom (take 24, value 0) reads 0.464×, 0.496× and 0.493× in the three sweeps. That is one value with three speeds, so no function of the value fits all three within ±0.5 %. Deck 1 and deck 2's top/centre hold within 0.5 %.
- New evidence that it is the motor, not the timer or estimator: net ticks over host time, 250 ms windows (`tools/platter-windows 24-pitch-d2.jsonl --deck 2 --window-ms 250`). Sweep 1 reads 0.460–0.466× for 21.25–22.25 s. Sweeps 2/3 reach 0.500–0.502× at 37.0–37.5 s and 51.5–52.0 s, then fall to 0.488–0.494×. So 0.5× is the target and `motorRatioFromFader` is right; deck 2 sags at torque LOW.
- Changed: `tests/platter-fader.test.mjs` adds 1 test pinning that ("in the ticks themselves"; a mutant with a 0.49× target fails). One sentence in doc § Pitch fader and Range. Tests 1056 → 1057, `check.sh` green. Nothing sent to the One; Mixxx not run. `passes` left false.
- **Question for Michael (in INBOX.md):** (a) reword step 4 so deck 2's bottom is pinned as a sag, which is what the tests do (recommended), or (b) keep it and wait for round 2's torque-HIGH take of deck 2 at the fader's bottom.
- Proposed change: step 4 as in (a). Also: "whether 0 is the top" can't be read from the takes; 16383 is the fast end, and which physical end that is stays UNVERIFIED (round 2).

### 2026-10-24 verify M5

Re-ran every step; `npm test` 1056/1056 pass (exit 0). Nothing sent to the One, no Mixxx run.

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| M5-01 | 1 | `grep '^## '` of docs/plans/2026-10-24-M5-truth.md | Sections Questions, Tool changes, Constants to re-check, Hardware round 2 candidates, Done when all present; Questions is a table with take, command, destination columns | yes |
| M5-01 | 2 | Read the Questions table | Rows A1–A6, 1–7, B1–B10 with takes 09/13, 12/13/21, 17/31, 07/12/29, 10/14, 15/17 vs 18/21, 23/24, 25, 26, 01; 16 and 22 marked `not data` with Michael's no-hardware-33/45 reason | yes |
| M5-01 | 3 | Compared the table's keys to `DEFAULTS` (mapping/rane-one-platter.js:131) | Every key listed, each with a take or `no take`/UNVERIFIED | yes |
| M5-01 | 4 | Read docs/decisions.md D1, D25, D26 | D1 has no `*default*` and carries the `(Updated in place 2026-10-24: Michael settled hybrid)` line; D25 names the 11 keys; D26 *default* says 33⅓ only, RPM_45 unused, nothing sent; D27 is the next free number in the plan | yes |
| M5-01 | 5 | Read spec §5 M7, §7 and line 3; `flatpak info`, grep `<settings>` | M7 bullet exists with the Spectra file, which exists in the Flatpak; 13 shipped mappings contain `<settings>`; §7 no longer asks about D1 or Serato; status line names the run | yes |
| M5-01 | 6 | Read the plan's Tool changes | `--deck 1\|2` (ch 1/2, note 0) named; analysis doc named docs/research/2026-10-24-census-analysis.md | yes |
| M5-01 | 7 | `npm test` | 1056 pass, 0 fail | yes |
| M5-02 | 1 | Read tests/analyze-platter.test.mjs:232–284 and tests/platter-run.test.mjs:304–378; ran the three files | Twin tests assert deck 2 on channel 2 equals deck 1 on channel 1; `--deck 3` exits 2; all pass | yes |
| M5-02 | 2 | `tools/analyze-platter 12-hand-d2-slow.jsonl --deck 2`, and without `--deck` | Deck 2: CC 6 deltas −1 ×2870, +1 ×3198 (of 6631), net −4; without it: 0 CC 6 messages ("other deck (ch 2): 6631 CC 6 … not analysed"); help says default 1 | yes |
| M5-02 | 3 | `tools/platter-run 21-motor-d2-33.jsonl --deck 2` | Runs to the end; "0 timer unwrap errors"; "control flips under 20 ms: 0" | yes |
| M5-02 | 4 | Both tools `--help`, `node --test tests/tools-usage.test.mjs` | Both document `--deck`, channel and Play note per deck, cite takes 12 and 21; usage test passes | yes |
| M5-02 | 5 | `npm test` | green | yes |
| M5-03 | 1 | Re-ran the map command from the CSV's first line into /tmp, and the `--diff` command; read commit b5c2b5f | `diff` of the map and the MK2 diff against the committed files: no differences; tool says 134 rows; commit message states 134 rows; diff has its command in a comment line | yes |
| M5-03 | 2 | Checked reference/rane-one-mk1-controls.csv with a node script | Header `status,channel,number,name,evidence,confidence`; every one of the 134 map rows has exactly one controls row (141 rows total); confidence capture 57 / mk2 72 / unknown 12; Play, Range 43, fader CC 9, strip CCs, Slip note 10 ch 5/6 are `capture` with take times | yes |
| M5-03 | 3 | Read controls rows for Shift and pads (`awk`, `grep`) | `90,16,50,Shift` capture (03@9.59–131.45); pad-mode notes 0, 7, 11, 12, 13 with MK2 mode names, marked `mk2`; shift layers listed | yes |
| M5-03 | 4 | Read analysis doc § Census and § Power-on dump; `tools/take-events 01-power-on.jsonl --json` | Per-channel table, notes with no release, 14-bit pairs CC 9/41, FX rows matched to take 02's note; I counted 193 messages in take 01 with channels 1, 2, 5, 6, 9, 10, 15, 16 as the doc says; CLAUDE.md note comparison present | yes |
| M5-03 | 5 | Ran the map reproduction myself (step 1); read tests/census-map.test.mjs header | Byte-for-byte reproduction holds; the test asserts it and the one-row-per-control check | yes |
| M5-03 | 6 | `npm test` | green | yes |
| M5-04 | 1 | `tools/analyze-platter 09-hand-d1-ten.jsonl`; `13-hand-d2-ten.jsonl --deck 2`; doc lines 187–220 | Net +36008 and +35987 as briefed; doc gives 3599.4/3600.8 and 3598.7 per turn, excludes 3584, discusses 3598 via the revolution period, mark error from Michael's note | yes |
| M5-04 | 2 | Doc lines 222–262 (saturation) and D23/D24 text in decisions.md | Counts per take given (band 16,304–16,381: 5, not the plan's 0; −1 under 5.8 ms: 2 host gaps, 0 by device time) with explanation; states "saturation confirmed, with one exception"; D23 amendment recorded. Plan's "expected 0" was not met but is reported and amended | yes |
| M5-04 | 3 | `tools/take-events 10-hand-d1-touch.jsonl` and `14-…` | 12 and 6 messages, all CC 6 + pitch bend pairs on ch 1/2; no touch message; spec §2 line 34 marked VERIFIED for vinyl-top taps, with motor-on/edge UNVERIFIED | yes |
| M5-04 | 4 | Doc line 315 and grep | Takes 11 and 30: hand turns with Shift held, nothing new, with counts | yes |
| M5-04 | 5 | Read tests/platter-decoder.test.mjs:438–460 | 09 → 0 unwrap errors, ticks 36008; 13 under ch 2 → +35,987, 0 errors, deck 1 sees none; 12 → 0 unwrap errors; all pass | yes |
| M5-04 | 6 | Read header of mapping/rane-one-platter.js lines 9–26 | TICKS_PER_REV, TICK_MOD, TIMER_MOD, TIMER_MARKER_MIN and deck 2 channel cite census takes | yes |
| M5-04 | 7 | `npm test` | green | yes |
| M5-05 | 1 | `tools/analyze-platter` 15 (`--phases 4-63`) and 21 (`--deck 2`); doc lines 359–406 | 15 net −126082, timer 2,822,403/s; 21 net +125540, 2,822,501/s (0.0036 % off 2,822,400, within 0.01 %); doc gives rpm 33.318 / 33.273, per-message ranges | yes |
| M5-05 | 2 | Doc lines 434–458 (hold) | 17 and 31: msgs/s 16.4 and 10.2, CC 6 ±1 histogram, 100 % markers, HELD_RATIO window reading 0.0175 / 0.0125 vs quick capture's 16/s | yes |
| M5-05 | 3 | Doc line 460+ (stopped); `platter-run-all` ends for 19/20/33/34 | Max ratio over 200 ms windows and roll-back stated (≤ 0.015), STOPPED_RATIO margin stated; all four end `stopped` | yes |
| M5-05 | 4 | `tools/platter-windows` 19 and 20 with `--cross`; doc lines 482–527 | My crossings (19: 0.99 at 38 ms, 0.1 at 386 ms; 20: 0.99 at 128 ms, 0.1 at 6.28 s) match the doc's tables; spin-up 261–272 ms, SPINUP_MS/HELD_START_MS/T8 get numbers | yes |
| M5-05 | 5 | `tools/platter-windows 32-… --cross -0.5,-0.4`; doc lines 529–552 | Backspin 32: −0.5 crossed at 1.845 s, −0.4 at 1.807 s as in the doc; min ratios −2.154 / −2.346, times under −0.5/−0.4 and re-acceleration tabulated, BACKSPIN constants judged | yes |
| M5-05 | 6 | `tools/take-events 25-motor-toggle.jsonl --no-platter`; doc § Shift+Slip and lines 419–432 | Sequence matches doc (Shift 16:50, note 10 ch 5/6, `cc ch15 96` 127/0 at 34.571/37.606 s); doc says nothing sent and that motor-off mode rests on Michael's account; reverse pad marked UNVERIFIED, round 2 step 4 | yes |
| M5-05 | 7 | `take-events` times in take 25; doc table lines 337–351; controls CSV | Note-on times (15: 1.774, 21: 2.103, 23: 3.368, 24: 1.979) match; CSV "Deck N Play" confidence `capture` | yes |
| M5-05 | 8 | Read tests/platter-speed.test.mjs:418–440 | Asserts 21 at +1.00 ± 0.01 and 15 at −1.00 ± 0.01 in every 1 s window, span ratios +0.99820 / −0.99954 | yes |
| M5-05 | 9 | `npm test` | green | yes |
| M5-06 | 1 | `tools/fader-sweeps 23-pitch-d1.jsonl`, `24-pitch-d2.jsonl --deck 2`; doc § Pitch fader and Range | Per sweep: values 16383/8192/0, ratios, Range presses (note 43 at 46.363 / 65.640 s on 23; 26.690 / 42.336 on 24); range ±50 % stated | yes |
| M5-06 | 2 | Doc lines 700+ | States Range sends only note 43 and the motor mapping did not change between sweeps | yes |
| M5-06 | 3 | `fader-sweeps` lag section; doc | Lag fit 25 ms (device) / 35 ms (estimator), steep sections 8–46 ms; RETARGET_MS recommendation (keep 0, read the fader late via FADER_LAG_MS) | yes |
| M5-06 | 4 | `fader-sweeps 24-pitch-d2.jsonl --deck 2`; tests/platter-fader.test.mjs:83–100 | `motorRatioFromFader` exists and deck 1 holds are all within 0.5 %, but deck 2's bottom (0) holds read 0.46379, 0.49588, 0.49346 against 0.5 (−7.24 %, −0.82 %, −1.31 %); the test asserts that sag instead of ±0.5 %. Step says the top, centre and bottom of 23 **and 24** are within ±0.5 % | **no** |
| M5-06 | 5 | decisions.md D27 | D27 *default* names rateRange 0.5, raw fader via `motorRatioFromFader` read FADER_LAG_MS late, alternative and `To undo` | yes |
| M5-06 | 6 | `npm test` | green | yes |
| M5-07 | 1 | `git log` M5-07 commit 8c51051; read tests | No existing value changed; one new key MARKER_GLITCH_FRACTION none → 0.25 with take citations, D28; message says tests failed first (I did not re-run the red state); constants no take covers say round 2/M7 | yes |
| M5-07 | 2 | Read tests/platter-state.test.mjs:859–912; ran it | D25 test with TAKEOVER_TOL 0.06, HANDBACK_TOL 0.02, TAKEOVER_MS 40, SETTLE_MS 400 against defaults on one step script; invalid overrides fall back without throwing; pair-breaking falls back; 85 pass | yes |
| M5-07 | 3 | Header lines 8–60; `node --test tests/platter-pure.test.mjs` | Header names TUNABLE and each D25 key with takes; pure test passes | yes |
| M5-07 | 4 | Read plan `Constants to re-check` | Every DEFAULTS key has an Outcome (confirmed / changed old → new / UNVERIFIED round 2) | yes |
| M5-07 | 5 | `npm test` | green | yes |
| M5-08 | 1 | `tools/platter-run-all`; doc § Platter runs table | 24 takes 07–15, 17–21, 23–26, 29–34, each with command, states and glitch count; the script is re-runnable | yes |
| M5-08 | 2 | Same run output | "glitches 0" on every take; "24 takes: 0 control flips under 20 ms" | yes |
| M5-08 | 3 | Run output and tests/platter-run.test.mjs:403–455 | 18 and 32 reach `backspin`; 17 and 31 reach `held`; 19/20/33/34 end `stopped`; 15 and 21 `motor_at_speed` to the end (test line 438 with −1 for 15); 25 ends `stopped` 43.180; tests pin each | yes |
| M5-08 | 4 | Doc lines 892–905 and run output | WRAP_JUMP check: largest shrink 08 1.40×, 29 2.63× (1.34× after a gap), 0 unwrap errors, 1.8 stands | yes |
| M5-08 | 5 | `npm test` | green | yes |
| M5-09 | 1 | Read HARDWARE-TESTS.md `## Round 2` | 9 steps, 14.5 min total; includes FX with Shift, Play hold 1 s per deck, contour knob and both reverse switches, reverse pad per deck, torque HIGH take, five vinyl taps and five platter-edge taps with times, step 9 prints the `unknown`/`mk2` rows (12 + 72, matching my count), INBOX instructions | yes |
| M5-09 | 2 | `tools/capture-session --help` / `--list`; section text | Tool has no option for another list (48 lines in `--list`); the section says why steps are by hand and writes out `rec` helper with `tools/capture --port 'Rane ONE MIDI 1' --seconds N --out` | yes |
| M5-09 | 3 | Read spec §5 M5 Answers and §2 | A1–A6, torque, items 1–7 each with takes or UNVERIFIED plus round 2 step; D26 named; §2 covers deck 2, 45 rpm, torque LOW, touch | yes |
| M5-09 | 4 | Read progress M5-09 entry | "Question for Michael: can you do Round 2 (about 14 min …)?" | yes |
| M5-09 | 5 | `npm test` | green | yes |
| M5-10 | 1 | `ls reviews/`, read M5-findings.md | M5.diff (6398 lines) and M5-findings.md exist; 0 Critical, 3 Important each with a failing test in tests/m5-review.test.mjs and fixing commit 7dcf65b; simplifications listed | yes |
| M5-10 | 2 | Re-derived 10 numbers myself | 09 +36008, 13 +35987, 15 −126082, 21 +125540, 15/21 timer rates, 19/20 spin-down crossings, 32 backspin crossings, 23 and 24 fader holds, 25 events, 01 count 193: all match the doc | yes |
| M5-10 | 3 | Header vs DEFAULTS keys; `node --check`; platter-pure test | Every key appears in the header with a take or UNVERIFIED/round 2; check and test pass | yes |
| M5-10 | 4 | Spec §5 M5, decisions.md | M5 marked "Done 2026-10-24" with links to plan, analysis, M5-findings; D25–D29 each have a `To undo` | yes |
| M5-10 | 5 | `npm test` | green | yes |

**Result: 9 features hold, 1 fails (M5-06 step 4, deck 2's bottom-end holds are 0.8–7.3 % under the function, not within ±0.5 %; the doc and test record the sag honestly, but the step as written does not hold). `passes` set to false for M5-06 only.**


### 2026-10-24 05:11 · M5-10 · passes

- `reviews/M5-findings.md` written. `reviews/M5.diff` is the run's start (fad1f45) to M5-09 (91452cf), harness files left out, `cmp`-identical. One Opus reviewer: **0 Critical, 3 Important, 10 minor**. All fixed in **7dcf65b**; the Important ones went test-first (`tests/m5-review.test.mjs`, 3 tests, each red on the doc assertion). **I1**: no census take goes `stopped → held`, so T5a/T6 (held through Play) and D24 are UNVERIFIED. Round 2 step 2 now covers it (round 14.3 → 14.5 min). **I2**: `HANDBACK_TOL` against 1.0 is 45 of 21's 1,180 windows, not 20 (20 is off the mean). **I3**: spec A3's motor-off mode is UNVERIFIED by capture.
- Minors fixed: A1 deck/period, D25/D27 wording, D1 `To undo`, stale UNVERIFIEDs in 4 files, 23 → 24 ms, take 24 metrics, reverse-control conflict. Simplifications in e2c7eea (`NOMINAL` once, `timedDelta`, the decoder's `shrink`); `platter-run-all`/`platter-windows`/`fader-sweeps` JSON is byte-identical. The rest is deferred to M9.
- Verified: ten doc numbers (hand 09/13/07/29, motor 15/21/17/31/18/32, pitch 23/24, census map) re-derived, all MATCH. `node --check` and `tests/platter-pure.test.mjs` pass; the header tests fail on the M5-09 header. `check.sh` green, tests 1053 → 1056. Nothing sent to the One; Mixxx not run.
- Next: M6. Next free decision **D30**. For M7: log `glitchMarkers` (D28); `FADER_LAG_MS` is not in `TUNABLE`.
- Question for Michael: round 2 step 2 now asks you to hold the record still while pressing Play (+6 s per deck). OK?
- Proposed change: CLAUDE.md says "settled: D1–D8, D13", but D25 is yours and settled too. Add D25?

### 2026-10-24 10:05 · M5-09 · passes

- `HARDWARE-TESTS.md` gains **`## Round 2`**: 9 steps, **14.3 min** (13.3 plus 1 min setup), by-hand `tools/capture --port 'Rane ONE MIDI 1' --seconds N` commands (a `rec` helper), because `tools/capture-session`'s list is fixed at 34 recordings. Covers FX with Shift, Play/Shift+Play per deck, the deck contour section, the reverse pad per deck, 5 taps on the vinyl top and 5 on the platter edge per deck at timed seconds, torque HIGH takes (both decks, with the record and the platter edge held, deck 2 at the fader's bottom), the fader's fast end and a fast slam, and the 84 `unknown`/`mk2` rows of the controls CSV by name. 3 optional extras (replug, motor-off mode with Play, deck 2 sag) are not counted. The section ends with what to write in INBOX.md.
- `docs/spec.md` §5 M5 has an **Answers** list (A1–A6, torque, items 1–7, each with takes or UNVERIFIED and its round 2 step); §2 is updated for deck 2, 45 rpm, torque LOW and the touch finding. Tests 1050 → 1050 (docs only); `check.sh` green.
- Nothing sent to the One; Mixxx not run. Next free decision: **D30**.
- **Question for Michael: can you do Round 2 (about 14 min at the One, plus 3 optional minutes)?** Steps are in `HARDWARE-TESTS.md`; answers go in INBOX.md under `## Answers`.
- Proposed change: none.

### 2026-10-24 09:20 · M5-08 · passes

- New **`tools/platter-run-all`** (lib `tools/lib/platter-run-all.mjs`, shared arg parsing `tools/lib/platter-run-cli.mjs`): the 24 platter takes (07–15, 17–21, 23–26, 29–34) with each one's `--deck`/`--expected`, one line each. **Glitches 0 on every take.** Doc § Platter runs has the table (what Michael did, the arguments, the states in words, glitches) and a WRAP_JUMP table. Tests 1022 → 1050 (`tests/platter-run-all.test.mjs`, step 3 pins in `tests/platter-run.test.mjs`, D29 mirror tests, WRAP_JUMP pins, pipe tests).
- **D29 *default* (new):** a negative expectedRatio means the motor is reversed, and the state machine mirrors its rules for it. Before, it was malformed input, and take 15 (reverse pad on) read as 62 s of `backspin` under the platter. Now 15 holds `motor_at_speed` from 2.415 s to 65 s, and 17 goes at speed → held → at speed. Forward runs give byte-identical output on all 22 forward takes (checked by the reviewer). `--expected` takes signed ratios.
- **WRAP_JUMP 1.8 stands.** New decoder stats `maxShrink`/`maxGapShrink`: 08 1.29×, 29 1.34× after a ≥ 2.9 ms gap, 1.48× at most anywhere (32), 0 unwrap errors. The 21.44× in 17 (and 18/19/31/32's) is inside the start backlog. Fixed bug: `platter-run`, `take-events`, `analyze-platter` and `census` cut piped output at 64 KiB (they wrote, then called process.exit).
- Verified: `check.sh` green, 1050 tests; mutations caught (15 at +1; dropping `d *` in T1, in `peak` and in the untrusted-sample absorb). Opus review: 1 Important (that absorb branch untested in reverse), 4 minor, all fixed (`reviews/M5-08-findings.md`). Nothing sent to the One; Mixxx not run.
- Next free decision: **D30**. For M7: a stop press hands the deck to the platter for the spin-down (T8, 0.7–7.1 s). 24 hands deck 2 to the platter 5 times at the fader's slow end (D27).
- Questions for Michael: (D29) should the One's reverse pad make Mixxx play backwards with the motor (Mixxx `reverse`), or should the mapping treat it as something else?
- Proposed change: none. The `--help` texts of platter-run/deck.mjs still call Play "assumed (UNVERIFIED)", although M5-05 verified it; M5-10 could update them.

### 2026-10-24 07:55 · M5-07 · passes

- Every DEFAULTS key checked against the census and cited in the `mapping/rane-one-platter.js` header; **no existing value changed**. New key **`MARKER_GLITCH_FRACTION` none → 0.25** (D28 *default*, takes 08/15): a −1 under 2.9 ms after a timed delta whose ticks would take < 0.25 of the limit is a mis-timed message → `untrusted` sample, stat `glitchMarkers`, `platter-run` prints "N mis-timed markers". It catches exactly 08 4.284 s and 15 5.207/37.989 s (next lowest 0.69); take 15's 1 ms `backspin→scratching→backspin` flips are gone. Core also enforces D25's hysteresis pairs (both defaults if out of order) and exports `RaneOnePlatter.TUNABLE` (the 11 D25 keys). Plan § Constants to re-check filled. Tests 1013 → 1022.
- New measurements (scan of all 23 platter takes, own deck, backlog out): CC→pb pairing ≤ 279 µs (PAIR_WINDOW_US 2000 ok), host gap before a valid delta ≤ 15.2 ms (TIMER_GAP_MAX_US 20000 ok), wrap check fired 0 times, shrink ≤ 1.48× after ≥ 2.9 ms gaps (WRAP_JUMP 1.8 ok).
- Verified: red first (`tests/platter-decoder.test.mjs` M5-07 ×4, take 15 estimator pin in `tests/platter-speed.test.mjs`, D25 pair/TUNABLE tests), then `check.sh` green, 1022 tests. Opus review: 0 Important, 8 minor; 7 fixed, 1 raised below (`reviews/M5-07-findings.md`). Nothing sent to the One; Mixxx not run.
- Next free decision: **D29**. For M5-08: `platter-run` lines now carry the mis-timed count; 15 shows 2.
- Questions for Michael: (D28) OK to treat those three −1s as glitches (only seen in reverse play)? (D25) the core rejects equal hysteresis pairs too (HANDBACK_TOL = TAKEOVER_TOL), stricter than D25's "above": OK?
- Proposed change: step 1 wants every uncovered constant marked "round 2", but RPM_45 (needs Serato traffic, D26) and BURST_MS (Mixxx delivery, M7) can't be settled by any hardware round; the header says so instead.

### 2026-10-24 06:40 · M5-06 · passes

- Doc § Pitch fader and Range filled (`docs/research/2026-10-24-census-analysis.md`). Core: `RaneOnePlatter.motorRatioFromFader(value14, config)` plus DEFAULTS `MOTOR_RANGE` 0.5, `FADER_DIRECTION` +1 (16383 = fast) and `FADER_LAG_MS` 35 (for the M7 glue). New `tools/fader-sweeps` (lib `tools/lib/fader-sweeps.mjs`) and `tools/platter-run --expected fader[:<ms>]`. **D27 *default*** (Mixxx `rateRange` 0.5, set against the live range; no soft takeover on the pitch fader; expectedRatio from the raw fader read 35 ms late, not `rate_ratio`). Next free decision: **D28**. Tests 974 → 1013 (`tests/platter-fader.test.mjs`, `tests/fader-sweeps.test.mjs`, usage cases).
- **The fader is ±50 % on both decks, in every sweep:** 0 → 0.5×, 8192 → 1×, 16383 → 1.5×. Deck 1's 12 holds are within 0.21 %. **Range sends only note 43 and changes nothing on the motor** (end speeds match across all 3 sweeps). The One snaps the centre to 8192, and 1–18 and 16254–16382 are never sent. **Deck 2 sags at the slow end:** 0.464/0.496/0.493 at 0, and it runs 2.8–3.1 % slow in the bottom quarter, so it hands over to the platter 5–7 times per take whatever the delay. The fader position is unknown until it first moves (D27 has the rule).
- **Lag:** the motor runs 25 ms (deck 1) / 45 ms (deck 2) behind the fader by device time and 35 / 55 ms by the estimator. On deck 1 the steepest sections lag 8–46 ms, on deck 2 up to 136 ms below the centre. `RETARGET_MS` stays 0: with a fader moving every 6–8 ms it removes a takeover at one delay only. Reading the fader 35 ms late leaves take 23 with 0 takeovers and a 1.65 % peak deviation held for 10 ms (3.79 % when read with no delay).
- Verified: `check.sh` green, 1013 tests. The Opus review re-ran the hold table, lag, takeovers and statistics, all of which reproduced. It found 4 Important issues, all fixed: the lag was fitted on the wrong signal, the fader position is unknown at start, D27 assumed it owns `rateRange`, and the centre-dead-band claim was wrong. It also found 11 minor ones, all handled (`reviews/M5-06-findings.md`). Nothing sent to the One; Mixxx not run.
- **Proposed changes:** (a) step 4's "±0.5 % at the bottom" can't hold for deck 2: three sweeps at value 0 read 0.464, 0.496 and 0.493, and no function of the value fits all three. The test pins the sag (0.8–7.3 % under, never over) and the pre-sag 200 ms window instead. (b) Step 4's "whether 0 is the top" can't be read from the takes: the prompt said "one end". The takes show 16383 is the fast end; the physical end is UNVERIFIED. Round 2 item 14 (plan) asks for it, plus a fast fader slam, deck 2 at the bottom with torque HIGH, and a replug to see whether the fader gets reported.
- Question for Michael (D27): OK to fix Mixxx's range at ±50 % so Mixxx's tempo always matches the platter? The Range button then does nothing in Mixxx.

### 2026-10-24 05:10 · M5-05 · passes

- Doc §§ Motor, Shift+Slip and Stop Time, Other deck's stray pairs and Not data filled (`docs/research/2026-10-24-census-analysis.md`). New `tools/platter-windows` (lib `tools/lib/platter-windows.mjs`): the core over fixed host-time windows (host, device and estimator ratios, markers, state) plus `--cross` threshold times. Play rows in `reference/rane-one-mk1-controls.csv` cite every start/stop press (15, 19, 20, 23, 25; 21, 24, 33, 34). Pins: `tests/platter-speed.test.mjs` (21 deck 2 +0.99820, 15 deck 1 −0.99954, both ±0.01 in every 1 s window), `tests/census-map.test.mjs` (Play citations), `tests/platter-windows.test.mjs`. Tests 938 → 974.
- **Speed at pitch centre:** deck 1 33.31–33.32 rpm (0.9994–0.9996 over 5 takes), deck 2 33.24–33.28 (0.9971–0.9983 over 4). TIMER_HZ holds within 0.0036 %. **Deck 2's motor sags** 0.2–0.4 s at a time, down to 0.9755 (21; 24, 33, 34 dip to ~0.98); deck 1 at most 0.64 %. `TAKEOVER_TOL` 0.03 clears it by 0.55 %: a D25 user setting under ~0.025 would hand deck 2 to the platter in its sags.
- Spin-up 261–272 ms to 0.99 forward (7 starts), 491 ms in reverse; 0.1 within 23–49 ms (`HELD_START_MS` 150 ok). Spin-down to 0.1: 0.2–0.4 s at Stop Time min, 2.7 s at 12 o'clock, 6.2–6.3 s at max (straight ramp 0.145/s). Stop Time = CC 72, 0/60/127. Hold: ±1 ticks, 100 % markers, 16.4/s (deck 1) and 10.2/s (deck 2), ≤ 0.0175 over 200 ms. Stopped: a 0–13 tick roll-back after each stop, then silence: motion, ≤ 0.015×. Backspins reach −2.15/−2.35; both caught and ended cleanly.
- **Shift+Slip sends only note 10 on ch 5/6** (same note for on and off, no state message; both motors were stopped, so note 10 as the toggle rests on Michael's account); `cc ch15 96` is the torque switch (speed unchanged by it). Take 25 toggled the mode with both motors stopped, so what Play does in motor-off mode is UNVERIFIED. Reverse is probably note 16 (press counts in 03/05 fit Michael's story) but UNVERIFIED. The other deck's "stray pairs" in 23–25 are start backlogs, not creep.
- Verified: `check.sh` green, 974 tests; every doc number re-run from the command it names. The Opus review re-ran ~40 numbers and found 4 Important (piped `--json` cut at 64 KiB, a creep claim on 17, an incomplete sag list, "deck 1 doesn't sag" from one reverse take) and 15 minor; all fixed but one cosmetic (`reviews/M5-05-findings.md`). Nothing sent to the One, no Mixxx run.
- For M5-06/M7: the motors don't run at exactly 1.0 (deck 2 0.3 % slow); consider a per-deck trim of expectedRatio. For M7: ignore the start backlog after the port opens. For M5-08: 17, 18, 19, 32, 33 need `--expected` (motor already running, no press); 15/17 need −1 (`parseExpected` refuses negatives today).
- Round 2 additions (plan items 12, 13): deck 2 untouched 60 s (the sag); motor-off mode with Play pressed.

### 2026-10-24 03:40 · M5-04 · passes

- Doc § Platter format filled (`docs/research/2026-10-24-census-analysis.md`). New `tools/take-events`. `tools/analyze-platter` gains `--markers`, `--period <ticks>` and a `start backlog:` line (lib `tools/lib/platter-format.mjs`). Decoder pins on takes 09/13/12. The core header now cites the census for TICKS_PER_REV, TICK_MOD, TIMER_MOD, TIMER_MARKER_MIN and deck 2's channel (no value changed). D23/D24 VERIFIED + amended; spec §2 touch line VERIFIED for motor-off taps. Tests 892 → 938.
- **Ticks/rev 3600, VERIFIED.** Ten turns: 09 +36,008 (tool; +35,994 without its +14-tick start backlog), 13 +35,987. That excludes 3584 but not 3598. A new no-mark check settles it: the once-per-revolution pattern of the per-tick interval in motor takes 15/21 repeats every 3600.0 ticks (deck 1 ±0.2, deck 2 ±0.5 from sub-windows).
- **Saturation confirmed.** Five near-limit deltas (16,338–16,373) sit beside −1s, and the 11 −1s device time can test read 0.80–0.99 of the limit. **Except 3 spurious −1s on backward passes through CC 0** (08 4.284 s; 15 5.207, 37.989 s): 3 of 1,306 backward passes, 0 of 5,077 forward. platter-run on 15 shows a 1 ms `backspin→scratching→backspin` at each. **M5-07:** treat a −1 whose timed neighbours read < 1/4 of the limit as a lost pitch bend; pin take 15.
- Touch: 10/14 hold only CC 6 + pitch bend (6 and 3 one-tick moves over 5 taps each): no touch message. Alt jog 11/30: Shift held ~10 s, same platter messages, nothing new.
- **For M5-05/M5-08:** takes open with a **start backlog** of 24–256 messages in the first ms, sent before the port opened (21: 256 msgs, +162 ticks: the M5-02 `scratching` before Play). 128/256 may be a buffer cap. `--phases 0.001-…` skips it.
- Verified: `check.sh` green, 938 tests. Mutation-checked 5 lib mutations (all caught). The Opus review found 10 issues (3 Important: overclaimed saturation, an unreproducible forward count, the 1.4× bound broken by the census's 3.53×), all fixed (`reviews/M5-04-findings.md`). Nothing sent to the One, no Mixxx run.
- Proposed change: M5-04 step 2 expects 0 deltas in 16,304–16,381. Under saturation they are expected (intervals just under 5.8 ms), and there are 5. The step should read "each beside a −1".

### 2026-10-24 02:10 · M5-03 · passes

- `reference/rane-one-mk1-midi-map.csv` regenerated over the seven census takes with `--shift 16:50`: **134 rows** (19,265 messages, 0 SysEx). New `reference/rane-one-mk1-vs-mk2.csv` (both 125, only-mk1 12, only-mk2 75): `tools/census --diff` now writes `--out [--force]` with its command in a first comment line. New hand-written `reference/rane-one-mk1-controls.csv`: 141 rows (the 134 plus Play, platter CC 6/pb per deck, torque CC 96 ch15), 57 `capture`, 72 `mk2`, 12 `unknown`. New `docs/research/2026-10-24-census-analysis.md`: § Census, § Power-on dump and § Strip search are filled, and the other sections are stubs naming their feature. Tests 886 → 892 (new `tests/census-map.test.mjs`: byte-for-byte reproduction except the date, one controls row per map row, every evidence range holds a message of that control in the take).
- Findings: Shift (note 50 ch16) makes most buttons send **another note** (Cue 1→5, Sync 2→3, pads 20–27→28–35 …), and a Shift-layer release goes out on the unshifted note if Shift is let go first. That explains all six "no release" rows. Pad notes don't change with the mode: modes 0/13/7/11/12 are host state. Strip = 14-bit CC 43/75. **CC 96 ch15 = rear torque switch** (0 = LOW). FX1–6 sent no press message: only all-zero state notes on each paddle change. Power-on = a 193-message state dump that contains CLAUDE.md's burst.
- Verified: `check.sh` green, 892 tests. An Opus review found 9 issues (overclaimed confidence on the EQ, cue and Tap rows; the deck 2 Shift layers; the strip 0s; a stale plan line); all were fixed. I mutation-checked the evidence test. Nothing sent to the One, no Mixxx run.
- For M6: treat the release of either layer as the button's release; map note 27 (headphone cue) as a latched state; the strip has no release message.
- Round 2 additions (M5-09): the printed pad-mode names, the FX buttons alone and with Shift, which knob CC 35/36 on ch15 is, the trim/EQ order of CC 22–25, deck 1's encoder with Shift, deck 2's mode 11 and Stop Time with Shift, strip touch-and-lift timing, and the meaning of the power-on state CCs.
- Proposed change: `tools/census` pairs only CC 0–31 with CC n+32 (the MIDI convention), so the strip's 43/75 shows as two rows. Widen the rule if M6 wants it as one.

### 2026-10-24 01:00 · M5-02 · passes

- `--deck 1|2` on `tools/analyze-platter` and `tools/platter-run` (default 1, anything else exits 2 with usage). New `tools/lib/deck.mjs` (deck N = CC 6, pitch bend, note 0 on channel N; cites takes 12 and 21; `deckHelp(col)` for both `--help`s). `runCore(P, recs, { deck })` sets the decoder's `ccStatus`/`pbStatus` and the press channel; presses carry `ch`. Tests 868 → 886 (4 analyze-platter, 6 platter-run, 8 tools-usage).
- Also: analyze-platter now counts the other deck's CC 6/pitch bends on one `other deck (ch N): … not analysed (--deck N)` line instead of listing ~13,000 lines (one older test updated for it); platter-run's text ends with `decoder: N samples, N timer unwrap errors, N untrusted, N markers, N orphan pitch bends`.
- Verified: `analyze-platter 12-hand-d2-slow.jsonl --deck 2` → 6,631 CC 6, deltas −2 ×364, −1 ×2870, +1 ×3198, +2 ×198, net −4 ticks; without `--deck` → 0 CC 6. `platter-run 21-motor-d2-33.jsonl --deck 2` → 62,850 samples, 0 timer unwrap errors, 1 untrusted, 2 markers, press note 0 ch 2 at 2.103 s, motor_at_speed at 2.526 s, 0 control flips under 20 ms. `check.sh` green, 886 tests. Nothing sent to the One, no Mixxx run.
- For M5-05/M5-08: take 21 is `scratching` at +0.861 for 0.02–0.32 s, before Play. The platter was still moving when the take started (coasting, or the One's state dump?). Look at it with `platter-windows`.
- Test note: compare big arrays as JSON text (`same()` in `tests/platter-run.test.mjs`). A failing `deepEqual` on thousands of updates made node's diff use up memory and get killed.

### 2026-10-24 00:45 · M5-01 · passes

- New `docs/plans/2026-10-24-M5-truth.md`: a `Questions` table (spec §5 M5 A1–A6 and 1–7, brief items B1–B10, each → takes → command → doc section/decision/constant → feature), `Tool changes` (`--deck 1|2`; new `tools/take-events`, `tools/platter-windows`, `tools/platter-run-all`; `RaneOnePlatter.motorRatioFromFader` with `MOTOR_RANGE`/`FADER_DIRECTION` in M5-06), `Constants to re-check` (every DEFAULTS key), `Hardware round 2 candidates` (11), `Done when`. Tests 868 → 868 (docs only).
- `docs/decisions.md`: D1 settled in place; **D25** configurable switch-over (11 keys, hysteresis pairs fall back to defaults, M7 `<settings>`); **D26 *default*** 33⅓ only, RPM_45 unused, nothing sent. Next free: **D27**.
- `docs/spec.md`: header names this run, §2 title, §5 M7 `<settings>` bullet (13 Flatpak 2.5.6 mappings use it, types boolean/enum/integer/real; checked with grep), §7 now D26 + round 2.
- Plan-time peek (hints for M5-03..05, in the plan's First look): **Stop Time knob sends CC 72** on the deck channel (19/20/33/34); touch takes 10/14 hold only CC 6/pb pairs (no touch message); Shift+Slip in 25 = Shift + note 10 on ch 5/6 plus `cc ch15 96`; stray other-deck pairs in 23 (128), 24 (128), 25 (64): check as creep; Range (note 43) is the only non-fader message between sweeps in 23.
- Verified: `check.sh` green, 868 tests. Nothing sent to the One, no Mixxx run.
- Question for Michael: D26, 33⅓ only OK, or schedule the D8 Serato USB capture?

### 2026-10-24 · initializer

**Feature counts:** M5 Truth 10 (M5-01 plan · M5-02 build · M5-03..M5-06 check · M5-07 build · M5-08 check ·
M5-09 docs · M5-10 review) · M6 Non-platter mapping 9 (M6-01 plan · M6-02..M6-06 build · M6-07 check ·
M6-08 docs · M6-09 review). 19 in all. M6-01 waits only on M5-03 (the named control map) and M5-06 (the
pitch-fader answer), so M6 can start while M5's later features run. Sizing: last run's features cost
$1.7–9.6 each and 15–80 min; the two heaviest here are M5-05 (motor takes) and M6-06 (FX plus "nothing
unhandled"); split them in your own session if they run long, by recording the half you did and leaving
`passes` false.

**Base:** this branch starts from `origin/harness/rane-one-mixxx-2026-10-19` (M1–M4 verified and merged,
868 tests green in 22 s) plus commit `daf519e`, Michael's 34-take session `captures/2026-10-23-census/`
(README.md there has his per-take notes; read it first). `main` does not have the captures.

**Where things live**
- `mapping/rane-one-platter.js` (860 lines): the pure core. `RaneOnePlatter.DEFAULTS` (frozen) and the three
  factories `createDecoder`, `createSpeedEstimator`, `createStateMachine`; its 60-line header lists every
  constant with its citation or `UNVERIFIED`. Loaded in Node by `tests/helpers/load-platter.mjs` (vm, no
  globals); `tests/platter-pure.test.mjs` fails on any `engine`/`midi`/`print`/`require`.
- `mapping/Rane-One-scripts.js` (36 lines): glue skeleton, `RaneOne.guard(name, fn)` wraps init/shutdown. No
  controls mapped yet; `mapping/Rane-One.midi.xml` has an empty `<controls/>`, controller id `Rane ONE`.
- `tools/`: `analyze-platter`, `platter-run`, `census`, `replay`, `capture`, `synth-platter`, `install-mapping`,
  `mixxx-dev` (bash), `null-sink`, `midi-send` (the safety gate). All print usage on `--help`; the Node ones
  share `tools/lib/*.mjs` (`platter-analysis.mjs`, `platter-run.mjs`, `census.mjs`, `jsonl.mjs`, `midi-parse.mjs`).
  **analyze-platter and platter-run are hard-wired to channel 1** (deck 1); M5-02 adds `--deck`.
- `tests/*.test.mjs` (30 files, 868 tests), helpers in `tests/helpers/` (`synth.mjs`, `run-core.mjs`,
  `filter-bench.mjs`), fixtures in `tests/fixtures/` (`census-small.jsonl`, `motion/`).
- Capture format (M2): one JSON per line, `{"t_us":5831515,"bytes":"90017F","type":"on","ch":1,"d1":1,
  "d2":127,"value":127}`; `bytes` is a hex **string**, `ch` is 1-based, pitch bend has `value` 0–16383.
- Plans go in `docs/plans/2026-10-24-M5-truth.md` and `docs/plans/2026-10-24-M6-mapping.md`; the analysis
  document for this run is `docs/research/2026-10-24-census-analysis.md` (model it on
  `docs/research/2026-10-19-quick-capture-analysis.md`). Reviews go in `.harness/runs/<run>/reviews/`
  (see last run's `M4-findings.md` for the format).
- Next free decision number is **D25**. D1 is to be settled in place (M5-01). Existing *default* decisions
  D9–D12, D14–D18, D20–D24 stand.

**What a first look at the census shows (2026-10-24, `tools/census` over takes 02–06, 27, 28: 19,265 messages,
134 rows, 0 SysEx). Hints only: every one must be re-derived and cited by the feature that uses it.**
- Deck 1 is MIDI channel 1, deck 2 is channel 2: notes 1–3, 5–8, 11–13, 16–18, 27, 43; CC 0 (63/65: an
  endless encoder), CC 9+41 (a 14-bit pair, 0–16383: the pitch fader, it moves in takes 23/24), CC 22–26, 28,
  43, 72, 75. Note 0 on the deck's channel is in the motor takes (Play, UNVERIFIED which). The platter is
  CC 6 + pitch bend on the deck's channel (take 12 shows `cc ch2 6` and `pb ch2`).
- Pads: channel 5 (deck 1) and 6 (deck 2): notes 0, 7, 9–13 (mode buttons?), 20–35 (pads, two banks?),
  40–43, 52–55, 63, 65. Mode/pad numbers match the MK2 djay map (`reference/rane-one-mk2-djay-midi-map.csv`,
  channels there are 0-based: its ch 4 is our ch 5).
- **Shift is note 50 on channel 16**, in every deck and pad take; the same as the MK2 map (`--shift 16:50`).
- Mixer/FX: channels 9 and 10 notes 0–2 / 3–5 (the census shows no velocity range: look at them raw) and
  note 16; channel 15 CC 35/36 and, in take 25 only, **CC 96 on channel 15** (sent around Shift+Slip: a
  "motor off" state message?); channel 16 CC 3 (63/65 encoder), CC 4, CC 8, note 4.
- Take 26 (strip search) has CC 43 and CC 75 on channels 1 and 2 swept 0–127. Take 23 shows note 43 ch 1
  between the sweeps (Range) and CC 9/41 moving.
- Take 25 (Shift+Slip): notes ch5 10 / ch6 10 with Shift, plus the platter pairs, plus `cc ch15 96`.
- The MK2 djay map matches many MK1 numbers (pitch CC 9, cue 1, sync 2/3, load 6, pitch bend 11/12, key 13,
  reverse 16, Shift 16:50, pad modes 0/7/11/12/13, pads 20–35). Use it to **name** controls, flagged `mk2`,
  never as proof.

**Gotchas**
- `tools/census` reads a 14-bit pair heuristically ("CC 9/41 taken as a 14-bit pair"): check the message
  order in take 23 before deciding which byte is the MSB.
- Michael's deck 1 reverse pad was ON through takes 07–17 (his note on take 18): deck 1's motor takes before
  18 run backwards (take 15 net about −126,082 ticks). Deck 2 (21) runs forward. Hand takes are unaffected
  by direction of the motor but say so when you cite them.
- Takes 16 and 22 are **not data** (no 33/45 switch on the MK1). The One ran at torque LOW and Stop Time at
  12 o'clock the whole session; torque HIGH was never captured.
- The brief forbids sending anything to the One to probe the motor (45 rpm, SysEx, firmware-shaped). Nothing
  in M5 or M6 needs to send to the One at all: replays go to `Midi Through` only, and `tools/replay` refuses
  any port that reaches a Rane client. `~/.rane-armed` exists but leave it alone.
- Mixxx resources for 2.5.6 are at `$(flatpak info --show-location org.mixxx.Mixxx)/files/share/mixxx/controllers/`
  (315 files: `midi-components-0.0.js`, `common-controller-scripts.js`, `lodash.mixxx.js`; 13 mappings use
  `<settings>`, so 2.5.6 supports it). `Numark V7` and `Numark-Scratch` mappings there are platter prior art.
- The dev Mixxx (`tools/mixxx-dev start`) needs `WAYLAND_DISPLAY`; it was set (`wayland-1`) when this
  initializer ran. If it is empty in your session, say so in progress and skip the Mixxx step (M6-07 says how).
  `tools/mixxx-dev` seeds the dev profile and binds the mapping to `Midi_Through_Port-0` (tools/lib/dev-seed.mjs);
  always `tools/mixxx-dev stop` before you finish.
- `node --test` runs every `tests/**/*.test.mjs`; the 8 `tools/midi-send` safety tests come first and must
  stay green. Keep zero npm dependencies (D5): no ESLint install here; M9 does lint.
- The platter takes are big (take 23 is 164,656 messages); `tools/platter-run` on one is a few seconds. A
  test that runs all 30 takes should keep its total under a minute or be split.

**Questions for Michael (defaults taken; none blocks the run)**
1. Round 2 at the hardware (M5-09 writes it into `HARDWARE-TESTS.md`, under 15 min): FX with Shift, Play in a
   census take, the deck contour section, the reverse pad, one motor take at torque HIGH, timed taps. Could you
   run it when convenient and answer in `INBOX.md`? Default: M5 marks those items UNVERIFIED and carries on.
2. 45 rpm: no capture can show a host motor command and nothing is sent to probe it, so the mapping targets
   33⅓ only (M5-01 records it as a *default* decision). OK, or do you want a Serato USB capture phase (D8)
   scheduled?
3. The switch-over tuning set (D25): the plan names TAKEOVER_TOL, HANDBACK_TOL, TAKEOVER_MS, SETTLE_MS,
   HELD_RATIO, HELD_EXIT_RATIO, STALL_MS, STOP_MS, SPINUP_MS, HELD_START_MS, BACKSPIN_RATIO as user-tunable.
   Anything to add or drop?
4. Pad modes, Shift+Play/Cue, FX paddles, browse/load: M6-01 takes the MK2 djay layout as the default for each
   (recorded as *default* decisions). Tell us any you want different.
