# Progress log · run rane-one-mixxx-2026-10-19

What this is: the shared memory of this harness run. Every session appends one entry **at the top** (newest
first) when it finishes: what it built, what it verified (commands and numbers), what it could not do, and
questions for Michael. Sessions start with an empty context; this file, `feature_list.json`, `CLAUDE.md`,
`docs/spec.md` and `docs/decisions.md` are all they know.

How to read `feature_list.json`: features are in priority order; the harness hands a session the first
feature whose `passes` is false and whose `after` dependencies all pass. A session edits only its own
feature's `passes`. Steps are what the verifier re-runs, so meet them literally.

How Michael steers: edit `INBOX.md` on this branch (`status: pause|stop`; answers under `## Answers`).
Every session reads it at startup.

---

### 2026-10-21 15:10 · verify M4

All 8 features hold; `passes` left true everywhere. Three literal mismatches, all recorded decision renumberings or capture-over-hypothesis corrections (D6/CLAUDE.md "capture wins"): decision numbers D12/D13 in the steps are D19/D22 in `docs/decisions.md`; the preview's "29116 of 29325 pairs" is 29,248 of 29,323 in the tool; `MIN_TIMED_SPEED_RATIO` is struck from the plan (D20, D23).

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| M4-01 | 1 | `tools/analyze-platter captures/2026-10-19-quick/platter.jsonl --phases 2-8,9-15,20-36,38-41,41-44,45-49`; `tests/analyze-platter.test.mjs` | Per phase: msgs/s, CC-6 histogram, timestamp histogram, net ticks, ticks/rev all printed; 15/15 tests pass, 200-line fixture test first | yes |
| M4-01 | 2 | Read `docs/research/2026-10-19-quick-capture-analysis.md` vs tool output | 20-36 s: 998.3/s (998-999), CC +2 ×15679, ts 2819-2826, 3598.2 ticks/rev, by hand ±1, note 0 at 19.236 s/95 ms and 44.670 s/110 ms all present. Pair count is 29,248 of 29,323 (the doc explains it replaces the preview's 29116/29325) | yes |
| M4-01 | 3 | Read "The hold phase anomaly" | 38-41 s: 16.7 msgs/s, CC ±1 (-1 ×24, +1 ×26), ts -1 ×49; "What M5 must check" lists 5 items | yes |
| M4-01 | 4 | Read `docs/decisions.md` D19, prior-art.md lines 43 and 108 | D19 (the step's "D12", renumbered because D12 was taken; D19 says so) states 7-bit counter, 2,822,400 Hz, 3600 within 0.1 %, note 0 UNVERIFIED button, no touch; prior-art links to the analysis | yes |
| M4-01 | 5 | `npm test` | 868 tests, 868 pass, 0 fail | yes |
| M4-02 | 1 | `grep '^##'` on `docs/plans/2026-10-19-M4-platter-core.md` | Loading, Constants, Decoder, Speed estimator, State machine, Switch-over, synth-platter, Real-capture check all present; Loading shows `var RaneOnePlatter` and `vm.runInNewContext` | yes |
| M4-02 | 2 | Read Constants table | TICKS_PER_REV 3600, TIMER_HZ 2822400, TICK_MOD 128, TIMER_MOD 16384, RPM_33 100/3, RPM_45 45 each with capture citation or UNVERIFIED. MIN_TIMED_SPEED_RATIO is struck through ("removed in M4-05, D23; was 0.1, step says 0.05") | yes (deviation documented) |
| M4-02 | 3 | Read plan lines 104, 179, 306-309 | `createDecoder`/`feed` (+flush, now), `createSpeedEstimator`/`push`→`{ratio,timed}`, `createStateMachine`/`update`→`{state,control,position}` (a superset, the plan notes the added fields) | yes |
| M4-02 | 4 | Read State machine table T1-T14 and Switch-over | Every transition has a condition with tolerances, hysteresis (3 %/1 %) and ms timers; handback invariant stated (position = integrated platter position ±1 tick) | yes |
| M4-02 | 5 | Read Filter choice (D22) | Candidates 1-Euro and α-β, synthetic data and acceptance named (33⅓ ±0.002 after 50 ms, step settles) | yes |
| M4-02 | 6 | `npm test` | 868/868 pass | yes |
| M4-03 | 1 | `node --test tests/platter-pure.test.mjs`; read `tests/helpers/load-platter.mjs` | 18/18 pass; refuses engine/midi/print/require/import/export/module; loads in empty vm context | yes |
| M4-03 | 2 | `node --test tests/platter-decoder.test.mjs` | 29/29 pass, incl. "CC 6 unwraps mod 128: 127→0 +1, 0→127 -1, 126→1 +3, 1→126 -3", timestamp 16383→0 +1, 0→16383 -1, unpaired pitch bend dropped, two CCs → timer null | yes |
| M4-03 | 3 | same file, "the quick capture decodes to 29323 samples…" | Passes: 29323 samples, net ticks, zero timer unwrap errors | yes |
| M4-03 | 4 | same file, "malformed input returns null without throwing" | Passes | yes |
| M4-03 | 5 | `npm test` | 868/868 pass | yes |
| M4-04 | 1 | `ls tests/fixtures/motion`; `node --test tests/synth-platter.test.mjs` | Scripts for constant/scratch/backspin/slow/drop/stall-burst exist; 21/21 pass incl. "every generated file is M2 JSONL of CC 6 + pitch bend pairs" | yes |
| M4-04 | 2 | same test run | "constant33, 10 s: 20000 ± 20 ticks, 998-1000 msgs/s, CC advancing 2"; slow: every ts delta is marker 16383 (>8192); drop loses 10 % ± 1 % | yes |
| M4-04 | 3 | `ls tests/fixtures/motion` | 7 scripts (constant33, constant45, scratch, backspin, slow, drop-and-burst, step); test "holds the seven scripts and no generated JSONL" passes | yes |
| M4-04 | 4 | same test run | "the M4-03 decoder on each fixture gives the scripted net ticks" passes | yes |
| M4-04 | 5 | `npm test` | 868/868 pass | yes |
| M4-05 | 1 | `node --test tests/platter-speed.test.mjs` | 43/43 pass; per filter: constant33 1.000±0.002 after 50 ms, constant45 with RPM_45, step to 0.5±0.02 in 100 ms, slow untimed ±20 %, backspin negative | yes |
| M4-05 | 2 | Read plan "Filter choice (M4-05, D22)" and D22 | Table of settle time and jitter for 1-Euro vs α-β on same scripts, 1-Euro chosen; recorded as D22 (step's "D13", taken, as D22 states) | yes |
| M4-05 | 3 | same test run | "dropped messages and the 40 ms stall change the ratio by less than 0.01" passes for all three filters | yes |
| M4-05 | 4 | same test run | "createSpeedEstimator never throws on a null timer, junk or a throwing sample" and "repeated sample is a no-op" pass | yes |
| M4-05 | 5 | `npm test` | 868/868 pass | yes |
| M4-06 | 1 | `node --test tests/platter-state.test.mjs` | 53/53 pass; one test per T1-T14 (T4 stopped→at speed, T7 →held, T9 held→scratching, T11 scratching→settling, T13 settling→at speed, T1 →backspin, T2 backspin→stopped) and "motor_at_speed stays put under ±1 tick jitter" | yes |
| M4-06 | 2 | same run | "hysteresis: ratio oscillating at ±2 % never flips control", "control leaves beyond ±3 % and returns only within ±1 %", "whole session… control rule holding on every update" pass | yes |
| M4-06 | 3 | same run | "handback invariant: position is integrated platter position (±1 tick)" and "a rate_ratio change in clock mode changes expectedRatio without a transition" pass | yes |
| M4-06 | 4 | same run | "update never throws and returns the previous result on malformed input" passes | yes |
| M4-06 | 5 | `npm test` | 868/868 pass | yes |
| M4-07 | 1 | `tools/platter-run captures/2026-10-19-quick/platter.jsonl` and `--json` | Timeline of state changes with seconds and ratio; --json prints one object per change | yes |
| M4-07 | 2 | `node --test tests/platter-run.test.mjs` | 23/23 pass: scratching + positive 3-7 s, negative 10-14 s, motor_at_speed ≤21 s to 36 s ratio 1.00±0.01 no flip, held/stopped 38.5-40.5, at speed by 42.5, stopped after 46 | yes |
| M4-07 | 3 | Read analysis "What the core sees" | Timeline pasted, both note-0 presses marked `<== note 0 press` | yes |
| M4-07 | 4 | Same section and tool output | "control flips under 20 ms: 0" stated, count given | yes |
| M4-07 | 5 | `npm test` | 868/868 pass | yes |
| M4-08 | 1 | `ls reviews/`; read `M4-findings.md`; `git cat-file -t` on 7 named commits | M4.diff (321 KB) and M4-findings.md exist; 3 Important each with failing test quoted and commit named; all 7 commits exist | yes |
| M4-08 | 2 | Read header of `mapping/rane-one-platter.js`; `node --check`; platter-pure tests | Header lists constants with capture citation/UNVERIFIED (test "header lists every DEFAULTS constant" passes); `node --check` OK; 18/18 purity tests pass | yes |
| M4-08 | 3 | Read `docs/spec.md` §2 and §5 M4 | §5 M4 "Done 2026-10-21", cites analysis, D19 (the "D12") and D22 (the "D13"); M5 open-questions list of 7 items from the analysis | yes |
| M4-08 | 4 | `npm test` | 868 tests, 868 pass, 0 fail | yes |


### 2026-10-21 14:46 · M4-08 · passes

- **What changed:**
  - `reviews/M4.diff` (`f837cbf..4fb6aca`) and `reviews/M4-findings.md`.
  - The core's header lists every constant with its capture citation or UNVERIFIED. The purity test now fails on a missing or uncited key, and on syntax QJSEngine may not take.
  - Spec §2 cites the analysis doc and D19/D22 (the feature list's D12/D13). §5 M4 is marked done 2026-10-21, and M5 has a 7-item open-question list.
  - Tests 853 → 868. `check.sh` is green.
- **Opus review: 0 Critical, 3 Important, all fixed test-first** (red quoted in the findings):
  - **#1** (d15b323): a timestamp wrap behind 5–19 lost pairs read 2.8–29.8× for one sample. New decoder rule `WRAP_JUMP` 1.8. The capture's interval never jumps more than 1.40×, so its timeline is unchanged.
  - **#2** (6f4811e): new `decoder.now()` gives the absorbed clock (D21) for heartbeats. Before, a 1 s wall-clock step back held a dead stop at 0.5 for 1 s.
  - **#3** (92e0ecb): D24's burst window is now its own `BURST_MS` 20 (was 2 ms). A backlog spread at 50 µs per message skipped 100 ticks; now 0.
- **Minors:**
  - Fixed: `analyze-platter` now counts −2 as a marker, and the analysis Output is regenerated. Also D20, the plan API and test-helper duplication.
  - Documented: the creep dead band, and that the glue must pass the same config to all three factories.
  - Deferred to M9: a shared CLI library.
- **Next (M5/M7):** `WRAP_JUMP` and `BURST_MS` are UNVERIFIED. M7 should build a `createDeck`-style wrapper so the glue hands one config to all three factories.
- **Questions for Michael:** none new. D24 is still open; it is amended with `BURST_MS`. **Sent:** nothing to MIDI, and no Mixxx was run.

### 2026-10-21 13:34 · M4-07 · passes

- **Changed:**
  - New `tools/platter-run` (decoder → estimator → state machine, a heartbeat every 20 ms; text timeline, `--json` one object per change, `--expected <s>:<ratio>,…`). The loop is `tools/lib/platter-run.mjs`.
  - `tests/helpers/run-core.mjs` now wraps that loop. The loader moved to `tools/lib/load-platter.mjs`, and the test helper re-exports it.
  - New `tests/platter-run.test.mjs` (written first, red seen), plus 12 usage cases.
  - Docs: the analysis doc gains "What the core sees", and the plan and README are updated. Tests 819 → 853.
- **Verified on the real capture, every update checked:**
  - 3–7 s: `scratching`, ratio +0.242…+0.537.
  - 10–14 s: `scratching`, ratio −0.451…−0.232.
  - `motor_at_speed` from 19.642 s through 36 s, ratio 0.9964–1.0040, control always `clock`.
  - 38.5–40.5 s: `held`.
  - `motor_at_speed` again at 42.004 s.
  - `stopped` from 45.671 s.
  - **Glitches (control flips under 20 ms): 0.** The 8 flips are at least 681 ms apart, none moves `position` beyond that update's own clock advance or tick change, and the count stays 0 with nearby tuning.
- **Review (Opus):** 0 Critical/Important, 7 Minor.
  - Fixed test-first: same-µs ordering around a press, heartbeat timing for presses and `--expected` alike.
  - Fixed in the docs: Play now marked UNVERIFIED, heartbeat wording, a note on the markers added to the pasted output.
  - Not changed: no glitch list in `--json`; the `runEstimator` field copy.
- **Next (M4-08):**
  - The capture never fires T1–T3, T5a or T6, and has no untrusted sample, so D24 is untested on real data.
  - T8 and the Play button are still UNVERIFIED.
- **Questions for Michael:** none new (D24 from M4-06 still open). **Sent:** nothing to MIDI, and no Mixxx was run.

### 2026-10-21 17:30 · M4-06 · passes

- **Changed:**
  - `mapping/rane-one-platter.js` gains `createStateMachine`: T1–T14 + T5a in the plan's order, condition timers clamped to state entry, ±3 %/±1 % hysteresis, `RETARGET_MS`, and a `position` keyed to control changes.
  - New `tests/platter-state.test.mjs` (written first, red seen). `run-core.mjs` now reports the decoder's `untrusted` flag.
  - Plan (as-built, invariant), D24, README. Tests 767 → 819.
- **D24 *default* (a deviation from the plan, please check):**
  - A probe found that a host stall of 60–80 ms at speed takes over (M4-05's stall-made `held`), and the burst's ticks then moved the track a second time. The track ended **116–162 ticks (58–81 ms) ahead**, an audible skip.
  - Now a silent takeover from `motor_at_speed` is armed. It is confirmed only if the first tick after it is decoder-`untrusted`, and then it absorbs only the burst (2 ms window).
  - Dead hand stops release with a marker, so they absorb 0. The 40–150 ms stall sweep ends within 3 ticks of the clock.
- **Verified:**
  - Every transition named in step 1 has its own test.
  - The control rule is asserted on every scripted update. The ±2 % wobble never flips control.
  - Handback lands within 1 tick of the integrated position, scripted and on the synth scratch.
  - A +8 % fader step through the real estimator causes no transition. 22 malformed inputs return the previous result.
  - Mutation checks: 14 mutants, all killed.
  - `check.sh` green, 819.
- **Review (Opus, 2 rounds):**
  - Round 1: 2 Important, 5 Minor. The worst: the first D24 version absorbed about 160 ticks on a dead stop, a 126 ms dead zone. Fixed by the untrusted confirmation.
  - Round 2: 3 Minor, all fixed or documented. The burst cap is built. D24's dependence on M5 check 2's saturation reading and on Mixxx's backlog timestamps is written into D24.
- **Next (M4-07):**
  - Pass `untrusted` from `runEstimator` output into `update`.
  - M7 must feed the decoder's monotonic clock. A forward `hostTimeUs` outlier freezes the machine (deferred review Minor).
  - T5a: the clock plays `HELD_START_MS` while a record is held through Play.
- **Questions for Michael:** D24: keep it, or take the plan's rule with its up-to-81 ms skip per host stall? **Sent:** nothing to MIDI; no Mixxx was run.

### 2026-10-21 15:10 · M4-05 · passes

- **Changed:**
  - `mapping/rane-one-platter.js` gains `createSpeedEstimator` with two filters, 1-Euro (default, **D22 *default***) and α-β.
  - The decoder now flags `untrusted: true` on samples with no device time.
  - New: `tests/platter-speed.test.mjs` (written first, 31/31 red seen), `tests/helpers/run-core.mjs` (decoder → estimator with 20 ms heartbeats, for M4-07) and `tests/helpers/filter-bench.mjs` (grid search + measurements).
  - Plan: Filter choice section; README updated. Tests 724 → 767.
- **D23 *default* (a deviation from the plan, please check):** the speed gate is dropped. Valid timer deltas are timed at any speed, and a marker clamps the host-time ratio to what the device clock allows.
  - With the plan's 0.1/0.125 gate, every scratch reversal read the 200 ms window: about 0.9 at the turn, with peak errors of 1.02–1.22. A −0.9 there would fire T1 (backspin).
  - Now: scratch peak error 0.095 and no false backspin.
  - `MIN_TIMED_SPEED_RATIO` is gone from `DEFAULTS`.
- **Verified:**
  - Both filters pass every acceptance: constant33/45 peak ≤ 0.00074, step settle ≤ 14 ms, slow untimed within ±20 %, backspin to < −2.5, drop vs twin ≤ 0.00088.
  - 1-Euro wins on scratch lag, 2 ms vs 5.5 ms.
  - Real capture 20–36 s: 0.9964–1.0027. The other phases match the plan's timeline (3–7 s +0.24…+0.54 timed, hold ≤ 0.022).
  - `node --check` OK, `check.sh` green, 767.
- **Review (Opus):** 1 Critical, 2 Important, 4 Minor. All fixed test-first and re-verified by the reviewer, except Minor #4.
  - Critical: a marker after a 20 ms gap froze the ratio at its last timed value (the capture's hold sends markers 20–90 ms apart). Fixed with the decoder flag.
  - Important: unclamped heartbeats read −0.99 after a back-cue and a dead stop. Now capped at 1 tick in the silence.
  - Important: the host-time ring grew 70 MB per hour. Now trimmed on every push.
- **Next session (M4-06):**
  - Heartbeats must be on the decoder's clock (M7; the open Minor #4: a wall-clock step back holds the ratio for the step's length).
  - A host stall over 50 ms now drops the ratio to about 0, so expect a stall-made `held`.
  - T14 acts on a single outlier sample.
- **Questions for Michael:**
  - D22: 1-Euro, or α-β (Mixxx-familiar, 3.5 ms more lag)?
  - D23: OK to drop the speed gate? This makes D20's 0.1 question moot.
- **Proposed change:** M4-05 step 2 should say D22, not D13. **Sent:** nothing to MIDI; no Mixxx was run.

### 2026-10-21 12:40 · M4-04 · passes

- **Changed:** new `tools/synth-platter` (CLI) + `tools/lib/synth-platter.mjs`: device model, `parseScript`, `createMotion` (true `posAt`/`ratioAt` labels for M4-05/06) and `synthesize`, using seeded mulberry32. Also new: 7 scripts in `tests/fixtures/motion/` (constant33, constant45, step, scratch, backspin, slow, drop-and-burst), `tests/helpers/synth.mjs` (generates them into a temp dir; nothing generated is committed), `tests/synth-platter.test.mjs` (written first, red seen), tools-usage cases, README, fixtures README and the plan's synth-platter "As built" notes. Tests 689 → 724.
- **Verified:**
  - constant33 decodes to exactly 20000 ticks at 1000.0 msg/s, with most messages advancing 2.
  - A 2-tick timer delta has mean 2822.4 and sd 4.5.
  - slow: every delta is the unsigned marker 16383.
  - The drop share is 10 % ± 1 %.
  - The M4-03 decoder gives each fixture's net ticks, computed by the test from the script.
  - `analyze-platter` reads constant33 back as 1411.2 counts per tick and 3600.0 ticks/rev.
- **Review (Opus):** 0 Critical, 0 Important, 9 Minor findings, all fixed test-first: ticks-per-message bound, aliasing drops refused, temp-file cleanup, host t_us that no longer swings with the seed, the 1 kHz cap at the ends, whole-ms startUs, `Object.hasOwn`, and two plan notes.
- **Capture facts found (in the plan):**
  - After a marker, the pitch bend counts on from the marker message (4 of 4 transitions): it works as an accumulator.
  - The 4.5-count timer sd is mostly slow motor wow (50-message means 2814–2831, lag-1 autocorrelation +0.93); the synth noise is white.
- **Next session (M4-05):**
  - Synth fast noise is about 4.8× the real fast part, and the synth has no wow.
  - drop-and-burst's 40 ms stall exceeds `TIMER_GAP_MAX_US`, so its first burst sample is untimed.
  - Use `synthDir()` + `createMotion` for labels.
- **Proposed change:** M4-04 step 2's "|delta| > 8192" is only possible as an unsigned delta (a signed 14-bit delta never exceeds 8192); suggest "unsigned delta 16383".
- **Sent:** nothing to MIDI. No Mixxx was run.

### 2026-10-21 11:58 · M4-03 · passes

- **Changed:** `mapping/rane-one-platter.js` is now `var RaneOnePlatter = (function() {…})()` with frozen `DEFAULTS` (every plan constant) and `createDecoder()` (`feed`/`flush`/`pending`/`stats`). New `tests/helpers/load-platter.mjs` (`vm.runInNewContext`, empty context), `tests/platter-pure.test.mjs` (greps the raw source, comments included, for engine/midi/print/require/import/export/module; the mutation `// print me` turns it red), `tests/platter-decoder.test.mjs` (written first, red seen). Plan Decoder section and README updated. **D21 *default*** recorded. Tests 654 → 689.
- **Verified:** on the real capture the decoder gives 29,323 samples, net ticks 43,547 (= the sum of the signed CC deltas, computed separately in the test), 281 markers, 0 timer errors, 0 orphans and 4 malformed (the note-0 on/off). Undefined, NaN and wrong-status input return null. `node --check` OK. `check.sh` green, 689.
- **Review (Opus):** 0 Critical, 2 Important and 6 Minor findings; fixed test-first:
  - A marker or untrusted delta on a dropped pitch bend now makes the next sample untimed.
  - A host clock stepping back is absorbed and counted in `clockSteps` (D21), instead of every message being rejected.
  - A `u = 0` after a gap counts as untrusted, not as an error.
  - A config that throws falls back to the defaults.
  - Tighter tests.
  - More than 63 lost ticks wrapping is documented as accepted and UNVERIFIED.
- **Deviation from the plan, recorded in it:** a dropped pitch bend still advances the cumulative timer. Ticks are a running counter, so this keeps ticks and timer over the same span.
- **Next session (M4-04/05):** the estimator must take its tick and timer deltas from the last *timed* sample: after a late pitch bend, a null-timer sample's ticks fall inside the next timed span. **M4-05's filter decision is now D22** (D21 is the clock-step rule).
- **Question for Michael:** D21: OK to absorb backward steps of `Date.now()` in the decoder?
- **Proposed changes:** M4-05 step 2 should say D22, not D13.
- **Sent:** nothing to MIDI. No Mixxx was run.

### 2026-10-21 14:20 · M4-02 · passes

- **Changed:** new `docs/plans/2026-10-19-M4-platter-core.md`, with the sections Loading, Constants, Decoder, Speed estimator, State machine (T1–T14 + T5a, each with its condition, tolerance and ms), Switch-over, synth-platter and Real-capture check. Also **D20 *default*** in `docs/decisions.md`. No code. Tests 654 → 654.
- **Built from the capture, not the hypothesis:**
  - The timestamp is read unsigned, and deltas of 16382/16383 are saturation markers adding −1/−2 (so M4-03's 0 → 16383 = −1 still holds).
  - Multi-tick messages carry their last tick's time (1/2/3/4-tick median deltas 1413/2823/4234/5661).
  - The real 20–36 s per-message ratio runs 0.9945–1.0041. The decoder targets are 29,323 samples, net +43,547 and 281 markers.
- **Verified:** I grepped every step-1–5 item in the plan and checked each number with Node one-liners over `captures/2026-10-19-quick/platter.jsonl`. An Opus review found 1 Critical and 5 Important problems, all fixed in the plan:
  - The hand turn back reaches −0.6 at 9.4–9.8 s, so `backspin` now needs the motor on.
  - T2 couldn't fire.
  - The switch-over is now keyed to the change in `control`.
  - The new `STALL_MS` keeps a host MIDI stall from taking control.
  - A heartbeat can no longer get between a CC and its pitch bend.
  - synth-platter gets `timerJitterCounts` 4.5, fitted to the capture.
  - A record held through Play is caught by T5a.
  `check.sh` green, 654.
- **Next session (M4-03):** the extras beyond step 3 are `flush`/`pending` on the decoder, `ticks`/`playRatio` in and `position` out of `update`, and stats on every object. M4-05's filter decision is **D21** (its step names D13, which is taken).
- **Question for Michael:** D20 sets `MIN_TIMED_SPEED_RATIO` to **0.1**, not the 0.05 in M4-02 step 2. The capture's timer can't time anything below 0.086, and at 0.05 the 1.25× re-entry point sits under that floor. OK to keep 0.1?
- **Proposed changes:**
  - M4-02 step 2: MIN_TIMED_SPEED_RATIO 0.1.
  - M4-02 step 3: add `ticks` (and `playRatio`) to `update` and `position` to its result, as M4-06 step 3 needs.
  - M4-04 step 2: "|delta| > 8192" should say unsigned delta, because the slow script gives 16383 markers.
  - M4-05 step 2: D21, not D13.
  - M4-07 step 2: "stopped after 46 s" has a narrow margin (the plan expects stopped at about 45.9 s).
- **Sent:** nothing to MIDI. No Mixxx was run.

### 2026-10-21 13:05 · M4-01 · passes

- **Changed:** new `tools/analyze-platter` + `tools/lib/platter-analysis.mjs` (per phase: CC-6 rate and per-second counts, signed CC-6 and timestamp delta histograms, net ticks, unsigned net timer with −1s counted apart, ticks/rev at `--rpm`; phases clipped to the data; `--json`, `--top`). `tests/analyze-platter.test.mjs` (200-line synthetic fixture plus edge cases), 16 bad-argument cases in `tests/tools-usage.test.mjs`. New `docs/research/2026-10-19-quick-capture-analysis.md`, decision **D19** (capture wins), prior-art §2 and §5 link to it, README "Platter core (M4)". `parseRpm` moved to `tools/lib/numbers.mjs` (drift.mjs re-exports it). Tests 624 → 654.
- **Measured (real capture, 20–36 s):** 998–999 CC-6/s, +2 per message (15,679 of 15,972), timestamp 2819–2826 per message, 1411.9 per tick, **2,822,469 counts per host second**, 31,984 ticks in 16 s = **3598.2 ticks/rev at an exact 33⅓**. By hand ±1 per message. Note 0 ch 1 at 19.236 s (95 ms) and 44.670 s (110 ms), each just before the motor starts or stops. No touch message. Hold 38–41 s: 16.7/s, CC ±1, timestamp −1 ×49.
- **New finding for M4-02/03/05:** the timestamp never shows a delta over 16,304 (5.777 ms). Every longer gap reads −1 (274×) or −2 (7×), so the counter seems to **saturate rather than wrap** (UNVERIFIED). Decode it unsigned, and read −1 as "≥ 5.8 ms". The timed-speed floor is therefore **0.086×** at 33⅓, not the 0.05 in M4-02's MIN_TIMED_SPEED_RATIO.
- **Review (Opus):** 0 Critical, 2 Important, 6 Minor; all fixed test-first (red seen). Important: my first draft said hand-phase wraps were lost. That came from summing signed deltas; unsigned, the timer accounts for the data span. The draft also leaned on host gaps, which jitter by several ms (an 11 ms host gap held a 4.28 ms device interval).
- **Sent:** nothing to any MIDI port. No Mixxx was run. `check.sh`: green, 654.
- **Proposed changes:** M4-01 step 4 says `D12`, which is taken (wow & flutter), so the decision is **D19** and its text says so. Step 2's "29116 of 29325 pairs" is the initializer's preview; the capture gives **29,248 of 29,323** (29,323 CC 6 and 29,323 PB, all adjacent, CC first). The doc cites that and notes the preview. M4-05 step 2 names `D13 *default*`, also taken: the next free number is D20. M4-02 step 2: MIN_TIMED_SPEED_RATIO should default to ≥ 0.086, or be justified against the analysis.
- **Questions for Michael:** none new.

### 2026-10-21 12:10 · verify M3

Re-ran every step; scratch files under /tmp/harness/rane-one-mixxx/rane-one-mixxx-2026-10-19. All 6 features hold; no `passes` edited. Live step: null-sink up → record-output → wow-flutter → down, default sink/source diffed unchanged (Default Sink is the Rane One's ALSA sink, untouched; nothing sent to MIDI).

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| M3-01 | 1 | `grep '^## ' docs/plans/2026-10-19-M3-measurement.md` | has WAV library, make-test-audio, wow-flutter algorithm, Telemetry format, drift, record-output (+ Evidence) | yes |
| M3-01 | 2 | read plan lines 99-130 | names zero-crossing + linear interpolation, per-cycle frequency, 0.5 Hz high-pass, peak/RMS %; ±15 % tolerance named | yes |
| M3-01 | 3 | read plan 188-232; `grep D11 docs/decisions.md` | one JSON object/line, keys t_us, ticks, timer, playposition, rate_ratio, mode (clock/platter), dev-profile/telemetry.jsonl; line 58 `D11 *default*` | yes |
| M3-01 | 4 | `grep 'pw-record --target' plan` | line 301 gives the exact command; target confirmation described via null-sink/pactl path check | yes |
| M3-01 | 5 | `npm test` | 624 tests, 624 pass, 0 fail | yes |
| M3-02 | 1 | `node --test tests/wav.test.mjs` (with the other M3 tests: 143 tests, 0 fail) | round-trip tests pass | yes |
| M3-02 | 2 | `tools/make-test-audio tone --seconds 5`, `clicks --bpm 120 --seconds 5`, `tone --fm-depth 0.1 --fm-rate 4`; readWav | 240000 frames, 48000 Hz, pcm32, 2 ch; peak -6.000 dBFS; 10 clicks; FM file measures peak 0.1009 % | yes |
| M3-02 | 3 | `tests/make-test-audio.test.mjs` run | passes; plus my own counts above agree with 240000 / -6 dBFS / 10 clicks | yes |
| M3-02 | 4 | `git check-ignore -v x.wav`; no stray wav in tree | `.gitignore:4:*.wav` | yes |
| M3-02 | 5 | `npm test` | 624 pass | yes |
| M3-03 | 1 | `node --test tests/wow-flutter.test.mjs`; CLI on 12 s tones | tests pass; CLI: clean tone 1000.000 Hz peak 0.0000 %, 0.1 %@4 Hz reads 0.1005 % | yes |
| M3-03 | 2 | `tools/wow-flutter tone.wav` and `--json` | prints mean Hz, peak %, rms %, worst 1 s window; JSON has same fields as one object | yes |
| M3-03 | 3 | zeroed 48 samples (1 ms) of a 12 s tone, ran wow-flutter | `peak 0.0000 % dropouts 1` with stderr warning | yes |
| M3-03 | 4 | `npm test` | 624 pass | yes |
| M3-04 | 1 | `tests/drift.test.mjs` pass; my own 5 min logs via `tools/drift` | zero: max 0.000 ms; 10 ms linear: final 9.974 ms, slope 2.000 ms/min; 50 ms jump: reported "jump @ 120.05 s" (injected at 120) | yes |
| M3-04 | 2 | `tools/drift d10.jsonl --track-seconds 300 --ticks-per-rev 3600 --rpm 33.333 [--csv]` | prints max, final, slope; `--csv` writes `t_us,drift_ms` rows to stdout (flag, no file arg) | yes |
| M3-04 | 3 | log with line 2 lacking `ticks` | `drift: bad.jsonl:2: missing "ticks"`, exit 1 | yes |
| M3-04 | 4 | `npm test` | 624 pass | yes |
| M3-05 | 1 | read tests/record-output.test.mjs lines 91-160 | asserts argv contains `--target mixxx-dev.monitor --rate 48000 --format s32 --channels 2`; `--target other.monitor` override; Rane targets refused exit 3; stubbed pw-record, all pass | yes |
| M3-05 | 2 | live: `null-sink up`, `record-output --seconds 2 /tmp/silence.wav`, `wow-flutter /tmp/silence.wav`, `null-sink down`, diff `pactl info` defaults | 96000 frames 48 kHz WAV; `no signal` exit 1 (no crash); defaults unchanged; sink absent after, no pw-record left | yes |
| M3-05 | 3 | `git show --numstat` of M3 README commits; read README "Measurement (M3)" | section is heading + 4 tool bullets (7 lines added in 9921a22; later commits 1/1 modifications) ≤ 8 | yes |
| M3-05 | 4 | `npm test` | 624 pass | yes |
| M3-06 | 1 | read reviews/M3-findings.md; `git cat-file -t 0d6f840` | M3.diff (3311 lines) and findings exist; Critical #1 and Important #2 name fixing commit 0d6f840 and quote the red test first | yes |
| M3-06 | 2 | wow-flutter tests (all pass, run above); spec.md lines 32-35, 86-89 | tolerance tests green; spec §3 rows name `tools/wow-flutter`, `tools/drift`, `tools/record-output`, `tools/make-test-audio` | yes |
| M3-06 | 3 | `grep M3 docs/spec.md` | line 83: "**Done 2026-10-21**" | yes |
| M3-06 | 4 | `npm test` | 624 pass | yes |


### 2026-10-21 11:40 · M3-05 · passes

- **Changed (fixes the verify-M3 failure on step 1):** pw-record now really gets `--target mixxx-dev.monitor --rate 48000 --format s32 --channels 2` (plus `-P stream.capture.sink=true`, dont-fallback, dont-move). It resolves because `tools/null-sink up` now loads the sink with `sink_properties="device.description=mixxx-dev object.path=mixxx-dev.monitor"`, and WirePlumber matches a target by `node.name` or `object.path`. Before running pw-record, `tools/record-output` checks that the sink's `object.path` is the target (if not: exit 1, "re-create it"), and that no other sink and no recording stream (`pactl -f json list source-outputs`, read-only) answers to it (exit 3). D18 is amended in place, along with the M3 plan (As built, Evidence), an M1 plan pointer and the README bullet. Tests 617 → 624.
- **Verified live (capture only, nothing to speakers or the One):** first a probe sink `hprobe` with that `object.path`; then the real tools. `null-sink up` → `record-output --seconds 2 /tmp/silence.wav`: 96000 frames, 48000 Hz, 2 ch, pcm32. `pw-link -l` showed only `mixxx-dev:monitor_FL/FR -> pw-record`, with no `alsa_input`. `wow-flutter` printed `no signal` (exit 1). A 1 kHz tone played into `mixxx-dev` only, recorded for 4 s: `mean 1000.000 Hz peak 0.0000 % dropouts 0`, -6.00 dBFS. Default Sink and Source were unchanged (diffed before and after). The sink was brought down again (`absent`), and no pw-record was left. I re-ran step 2 on the final code. README's M3 section adds 5 lines. `check.sh`: green, 624.
- **Review (Opus):** 0 Critical, 0 Important, 6 Minor. Fixed test-first, red seen first: capture streams can also match the target; the "re-create" hint was wrong for non-mixxx-dev sinks; stale docs; the null-sink test stub's module line. Not fixed: the race between pactl's check and WirePlumber's link (documented in a code comment and D18).
- **Next session:** a `mixxx-dev` sink loaded before this commit has no `object.path`. Run `tools/null-sink down && tools/null-sink up` once. The tool tells you so if you forget.
- **Sent:** nothing to any MIDI port. No Mixxx was run.
- **Questions for Michael:** none new. The earlier D18 question is replaced: step 1 now holds literally, so no step change is needed.

### 2026-10-21 11:10 · verify M3

Check ran green (617 tests). Live null-sink step run and torn down; no Mixxx, no MIDI sent. M3-05 set to false: step 1 literal text (`--target mixxx-dev.monitor`) contradicts the test and tool (D18); fix is amending the step with Michael or changing the tool.

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| M3-01 | 1 | grep '^##' on the plan | sections WAV library, make-test-audio, wow-flutter algorithm, Telemetry format, drift, record-output all present | yes |
| M3-01 | 2 | read plan L99-143 | names zero-crossing + linear interpolation, 0.5 Hz high-pass, peak/RMS %; tolerance ±15 % for 0.1 % FM at 4 Hz | yes |
| M3-01 | 3 | read plan L188-210, D11 in decisions.md | one JSON/line, keys t_us, ticks, timer, playposition, rate_ratio, mode clock|platter, dev-profile/telemetry.jsonl; `D11 *default*` present | yes |
| M3-01 | 4 | read plan L294-335 | gives the pw-record command with `--target mixxx-dev.monitor` as the form, plus the read-only confirmation procedure; notes the native target is expected to need translation (later D18) | yes |
| M3-01 | 5 | `/…/check.sh`, node --test of M3 tests | suite green (617 tests, fail 0) | yes |
| M3-02 | 1 | node --test tests/wav.test.mjs; read round-trip test | 136/136 pass across the 5 M3 test files; round-trips per format/mono/stereo at 48000, byte rate and block align asserted | yes |
| M3-02 | 2 | ran `make-test-audio tone`, `clicks --bpm 120`, `tone --fm-depth 0.1 --fm-rate 4` | each wrote 240000 frames, 48000 Hz, pcm32, 2 ch; wow-flutter on the FM file read peak 0.1009 %, mean 1000 Hz | yes |
| M3-02 | 3 | read tests/make-test-audio.test.mjs L41-105 | asserts 240000 frames, peak within 1 % of -6 dBFS, 10 clicks, zero-crossing diff < 0.002; passes | yes |
| M3-02 | 4 | .gitignore, test code | `*.wav` at .gitignore:4; tests use temp dirs (setup/join(r.dir)) | yes |
| M3-02 | 5 | check.sh | green | yes |
| M3-03 | 1 | read tests/wow-flutter.test.mjs L53-88 | clean tone <0.01 %; 0.1 %@4 Hz peak 0.085-0.115; 0.5 %@0.5 Hz peak 0.42-0.58; 1010 Hz <0.01 %, mean ±0.5; all pass | yes |
| M3-03 | 2 | ran `tools/wow-flutter tone.wav` and `fm.wav --json` | text prints mean, peak, rms, worst 1 s window, dropouts, cycles; --json one object with same numbers | yes |
| M3-03 | 3 | read test L124 (1 ms zeros at 2.5 s -> dropouts 1) and CLI test L279 | dropout reported as `dropouts`, not flutter; passes | yes |
| M3-03 | 4 | check.sh | green | yes |
| M3-04 | 1 | read tests/drift.test.mjs L73-98 | zero drift <0.1 ms; 10 ms/5 min final 10±0.5, slope 2±0.1; 50 ms jump within 1 s; all pass | yes |
| M3-04 | 2 | ran `tools/drift t.jsonl --track-seconds 600 --ticks-per-rev 3600 --rpm 33.333` and `--csv` | prints max/final/slope/noise/jumps; --csv gives `t_us,drift_ms` header and rows (my log used 33.333 vs 100/3 so it showed 3 ms, as D-documented) | yes |
| M3-04 | 3 | ran drift on a log whose line 12 lacks `ticks` | `drift: …bad.jsonl:12: missing "ticks"`, exit 1 | yes |
| M3-04 | 4 | check.sh | green | yes |
| M3-05 | 1 | read tests/record-output.test.mjs L86-170 | test asserts argv has `--target mixxx-dev -P stream.capture.sink=true` and that NO arg ends in `monitor` (L99); the step says pw-record is called with `--target mixxx-dev.monitor`. Plan anticipated this as a step change for Michael (D18), but the step text was never amended. Other halves hold: --target override, `Rane` refused exit 3 | NO |
| M3-05 | 2 | `tools/null-sink up`; `record-output --seconds 2 /tmp/silence.wav`; `wow-flutter`; `pactl info`; `null-sink down` | 96000 frames 48 kHz WAV; wow-flutter printed `no signal` (exit 1, no crash); Default Sink unchanged (Rane alsa_output) ; sink brought down again | yes |
| M3-05 | 3 | git diff of README.md vs merge-base | M3 section adds 6 lines (heading, blank, 4 tool bullets), ≤ 8 | yes |
| M3-05 | 4 | check.sh | green | yes |
| M3-06 | 1 | read reviews/M3-findings.md; git cat-file for 0d6f840, 3b04e6b, 7a4f64c | M3.diff (3311 lines) and findings exist; Critical #1 and Important #2 fixed in 0d6f840 which adds tests (tests/wow-flutter.test.mjs) in the same commit; test-first claim rests on the notes, commits are one fix+test each | yes |
| M3-06 | 2 | wow-flutter tests; spec §3 table | tolerance tests pass (136/136); §3 names tools/wow-flutter, tools/record-output, tools/drift, make-test-audio | yes |
| M3-06 | 3 | grep M3 docs/spec.md | `M3 · Measurement tools. Done 2026-10-21` | yes |
| M3-06 | 4 | check.sh | green | yes |


### 2026-10-21 16:30 · M3-06 · passes

- **Changed:** `reviews/M3.diff` (3311 lines: the M3-01 plan commit plus `cadb770..2b59a39`) and `reviews/M3-findings.md`. One Opus review found 1 Critical, 1 Important, 4 Minor, 4 duplication, 3 simplification and 4 docs issues. **Critical #1:** wow-flutter counted a full-level speed step over 5 % as a "dropout" and cut it out, so 8 % for 50 ms read `peak 0.0000 %`, exit 0. Now a run of ≥ 3 full-level cycles off the same way is flutter (7.8065 %), and the tool warns when `dropouts > 0`. **Important #2:** the 1 s filter edge read 0.1 % of 0.5 Hz wow as 0.1055 %; the edge is now 2 s, down to 1 s for short tones. Both fixes are in 0d6f840. Minors in 3b04e6b: drift checks each deck's clock separately; `--rpm 33.0` means 100/3; `RECORD_OUTPUT_GRACE_MS` must be 0..600000. Dedupe in 7a4f64c: `tools/lib/atomic-write.mjs` and `tools/lib/numbers.mjs` (median, DECIMAL). Docs in 2136806: spec §3 names the tools, spec §5 M3 is done 2026-10-21, D12 is amended, the plan has inline "superseded" marks. Tests 611 → 617.
- **Verified:** I ran each fix's test red first (red output quoted in the findings), then green. I reproduced the Critical myself before fixing it (8 %/50 ms and 20 %/100 ms: `peak 0.0000 %  dropouts 1`, exit 0). A dropped or repeated 256-sample block is still `dropouts 1`. `make-test-audio tone --seconds 5` still measures (edge 1.9 s). All M3-03 tolerance tests pass unchanged. `check.sh`: green, 617 tests.
- **Deferred:** #6, noise above 200 Hz counts as flutter (unweighted to 500 Hz). It is harmless on the digital null-sink path, but an analog loopback in M8 would need a low-pass. #9, a shared `tools/lib/cli.mjs` for 6 tools (for M9).
- **Sent:** nothing to any MIDI port. No Mixxx was run, and no audio was played or recorded.
- **Next session (M4):** `median` and `DECIMAL` are in `tools/lib/numbers.mjs`, and `writeFileAtomic` is in `tools/lib/atomic-write.mjs`.
- **Questions for Michael:** D12 amended: is "a §3 wow & flutter measurement needs `dropouts 0`" the rule you want? Spec §3 now says "≤ 0.1 % peak" and "max |drift| < 10 ms" explicitly.

### 2026-10-21 15:40 · M3-05 · passes

- **Changed:** new `tools/record-output` (records a null sink's monitor into a temp WAV next to `<out.wav>`, renamed into place only if it is exactly `seconds·48000` frames at 48000 Hz, 2 ch, pcm32). New `tests/record-output.test.mjs` (39, with stubbed `pw-record` and `pactl`) and 18 bad-argument cases. `D18 *default*`, the plan's "As built" and Evidence, and a 7-line README "Measurement (M3)" listing the four tools. Tests 554 → 611.
- **Live (capture only, no audio to speakers or the One):** raw `pw-record --target mixxx-dev.monitor` printed "defined target not found" and left a 44-byte WAV, as the plan predicted. So the tool sends `--target mixxx-dev -P stream.capture.sink=true --rate 48000 --format s32 --channels 2 --sample-count N -P node.dont-fallback=true -P node.dont-move=true` (D18). `pw-link -l` showed `mixxx-dev:monitor_FL/FR -> pw-record` and no `alsa_input` link. `--seconds 2` gave 96000 frames, all zero, and `tools/wow-flutter` printed `no signal` (exit 1). Default Sink and Source were unchanged, and no sink-input was added. A 1 kHz tone played into `mixxx-dev` only (`pw-play --target mixxx-dev -P node.dont-fallback=true`) recorded at 1000.000 Hz, peak 0.0000 %, -6.00 dBFS. The null sink was brought up and down again.
- **Review (Opus), 0 Critical, 2 Important, 3 Minor, all fixed test-first with red seen.** Important 1: the blocklist let `auto.monitor` (pw-record reads it as the default sink, which is the One), numeric serials and object paths (`alsa:acp:ONE:…`) through. It is now an allowlist plus a read-only `pactl -f json list sinks` check that the sink is `support.null-audio-sink`. Important 2: D18 and README overstated the safety. A second review pass found that a sink with no `factory.name` (a filter or loopback) passed the check; that is fixed test-first too. Also fixed: the temp file leaked on errors, signals didn't escalate to SIGKILL (6 mutants, all caught), there was no check for a directory or unwritable output, and the cap is now 600 s (memory).
- **Next session (M3-06):** pw-record 1.6.8 exits 1 even after a complete recording; the tool judges the WAV instead. M3 commits are `9451137` (M3-01, the plan, made before M2) and everything after `cadb770` (M2 verified).
- **Sent:** nothing to any MIDI port. No Mixxx was run.
- **Question for Michael:** D18: is it OK that `--target mixxx-dev.monitor` stays the user-facing name but reaches pw-record as `--target mixxx-dev -P stream.capture.sink=true`?
- **Proposed change:** M3-05 step 1 should read "calls pw-record with `--target mixxx-dev -P stream.capture.sink=true --rate 48000 --format s32 --channels 2` (D18)". The literal `.monitor` argv records nothing on this machine. I flipped `passes` because the step's intent (that monitor, 48000, s32, 2 ch) holds, the brief says never park, and D18 records the default.

### 2026-10-21 14:30 · M3-04 · passes

- **Changed:** new `tools/lib/drift.mjs` (`parseTelemetry`, `parseRpm`, `analyzeDrift`, sorted sliding-window medians) and `tools/drift` (`--track-seconds`, `--ticks-per-rev`, `--rpm`, `--deck`, `--jump-ms`, `--smooth-ms`, `--csv | --json`); new `tests/drift.test.mjs` (32) and 22 bad-argument cases in `tests/tools-usage.test.mjs`. The plan's drift section has an "As built" list. Tests 500 → 554.
- **Verified:** CLI on a 5-minute 20 Hz scratch log with 10 ms of linear drift, `--ticks-per-rev 3600 --rpm 33.333`: `max 9.976 ms  final 9.976 ms  slope 2.000 ms/min`; `--csv` header `t_us,drift_ms` + 6001 rows; a line without `ticks` → `…bad.jsonl:5: missing "ticks"`, exit 1 (same for `playposition`, line 7). Tests: zero drift max < 0.1 ms, 50 ms step → one jump within 1 s (5 seeds with a 0–21 ms lag too), `--rpm 33.333` is exactly 100/3. A 1 kHz 5-minute log takes 0.9 s. `check.sh` green, 554 tests.
- **Review (Opus):** 0 Critical, 1 Important, 4 Minor. Fixed test-first, with the failures seen first: **Important:** a stale first or last line read as a jump, because the window at the ends held one sample. Jumps now need smooth-ms/2 of log on each side, and removing that fix makes its test fail. Also fixed: a real NTP step back gave one warning per line and shifted later jump times (the step is now carried forward: 1 warning, `t_backsteps: 1`); `--rpm 33.30` was taken literally; a BOM or a whitespace-only line said "not JSON". Added a brute-force median check on uneven spacing.
- **Plan deviations (in the plan's "As built"):** a jump's time is the midpoint of its run (a clean step gives a flat plateau, and the plan's "largest change" read 0.5 s early); `noise_ms` is measured around the smoothed curve, without the baseline offset.
- **Limits, documented:** an excursion shorter than smooth-ms/2 (+60 ms for 0.4 s) shows in neither `max` nor `jumps` at the 1 s default; `--smooth-ms 200` shows it (max 60.000, 2 jumps). With a 0–43 ms lag, the 1 s window gives false 20 ms jumps mid-log, so M7 should keep the playposition lag near one 21 ms buffer.
- **Sent:** nothing to any MIDI port. No Mixxx was run, and no audio was played or recorded.
- **Next session (M3-05):** README's four-tool list should include `tools/drift`. For M7: D11 requires `timer` to be an integer, but M4-03 plans `timer: null` samples, so if M7 logs those, D11 and `parseTelemetry` change together.
- **Questions for Michael:** none.

### 2026-10-21 13:20 · M3-03 · passes

- **Changed:** new `tools/lib/wow-flutter.mjs` (`analyze`, `highPass`) and `tools/wow-flutter` (`--channel`, `--json`, `--expect-hz`; prints `no signal` and exits 1 on silence); new `tests/wow-flutter.test.mjs` (28) and 14 bad-argument cases in `tests/tools-usage.test.mjs`. The plan's wow-flutter section has an "As built" list. Tests 458 → 500.
- **Verified:** CLI on `make-test-audio` files: clean 1 kHz peak 0.0000 %; 0.1 % @ 4 Hz peak 0.1021 %, RMS 0.0707 %; 0.5 % @ 0.5 Hz (10 s) peak 0.5279 %; 1010 Hz peak 0.0012 %, mean 1010.000 Hz; 1 ms of zeros → `dropouts 1`, < 0.01 %; -80 dBFS → `no signal`, exit 1. A 5-minute stereo file takes 0.56 s and 302 MB. `check.sh` green, 500 tests.
- **Review (Opus):** 1 Critical, 2 Important, 4 Minor (3 fixed, 1 documented). Each fix had its test fail first. **Critical:** the plan's odd-reflection pad made the result depend on the FM phase at t = 0. A 0.1 % tone starting at maximum deviation read 0.1180 %, outside the 0.085–0.115 % window, and the steps' tests missed it because `tone()` always starts at zero deviation. Mirror padding fixes it: 0.1015–0.1021 % across phases. **Important:** a noise floor before the tone gave `no signal`, because it out-votes the tone in the medians. Silence around the tone put the filter edge inside the statistics. The tone is now found by level and trimmed, and the edges count from the tone.
- **Deviation from the plan:** step 8's padding is now even reflection, not scipy-style odd. The plan's "As built" says why. D12 itself is unchanged.
- **Sent:** nothing to any MIDI port. No Mixxx was run, and no audio was played or recorded.
- **Next session (M3-04 drift):** no dependency on this work. For M3-05: `tools/wow-flutter` on an all-zero WAV prints `no signal` and exits 1 (tested).
- **Questions for Michael:** none.

### 2026-10-21 12:10 · M3-02 · passes

- **Changed:** new `tools/lib/wav.mjs` (encode/decode/read/write: pcm16/24/32 and float32, extensible headers, LIST/PEAK skipped with pad bytes, streamed headers read to EOF, `{ channel }`), `tools/lib/test-audio.mjs` (`tone` with integrated-phase FM, `clicks`), `tools/make-test-audio`. New `tests/wav.test.mjs` (20) and `tests/make-test-audio.test.mjs` (11), 35 bad-argument cases. Plan § make-test-audio got an "As built" list. Tests 392 → 458.
- **Verified:** CLI run as the steps say: tone.wav and fm.wav are 240000 frames, 48000 Hz, pcm32, 2 ch, peak -6.0000 dBFS, 4999 rising crossings each; FM per-cycle frequency +0.1002 % / -0.1002 %, peaking every 0.25 s; clicks.wav has 10 clicks of 48 samples. Header bytes: byte rate 384000, block align 8. `git check-ignore` matches `*.wav`; tests write and remove their own temp dirs. Mutation checks: 13 of 13 sabotages caught. `check.sh` green, 458 tests.
- **Review (Opus):** 0 Critical, 0 Important, 7 Minor, all fixed test-first (red seen): an empty data chunk read as streamed (and a chunk after it decoded as audio), a round-trip bound loose enough to pass truncation, float32 ±Inf from out-of-range values, a RangeError for huge rates, EPIPE on `--out -` crashing after claiming "wrote", no `--fm-rate` cap (now ≤ 200), and `tests/tools-usage.test.mjs` leaking a temp dir per case (now removed; ~2770 old `/tmp/tools-usage-*` dirs from earlier runs are left alone).
- **Sent:** nothing to any MIDI port. No Mixxx, no audio played or recorded.
- **Next session (M3-03):** build test tones with `tone()` from `tools/lib/test-audio.mjs`; `readWav(path, { channel })` returns Float64Array channels and `sizeFromEof`.
- **Questions for Michael:** none new.

### 2026-10-21 10:05 · verify M2

All 8 features hold (39 steps). Check.sh green, 392 tests. Step 3 of M2-04 was run live: null sink up, `tools/mixxx-dev start` (id 1908187295), replay, `tools/mixxx-dev stop`, null sink down; nothing was sent to the One (replay went to `Midi Through` 14:0 via `tools/midi-send play`). A probe `tools/capture-session --label vtest --device /dev/null` made `captures/2026-10-21-vtest/`; I deleted it again.
Note on M2-01 step 3: the plan's capture-backend decision is recorded as **D14** (D10 was already taken, which D14's text says); the content the step asks for is there.

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| M2-01 | 1 | `grep -n '^##'` on docs/plans/2026-10-19-M2-capture-replay.md | sections JSONL format, SMF library, Capture backend, Replay, Census, Capture session, HARDWARE-TESTS outline all present | yes |
| M2-01 | 2 | read plan § JSONL format; `head -3 captures/2026-10-19-quick/platter.jsonl` | seven keys in order, three example lines; the real file's first 3 lines are identical to them | yes |
| M2-01 | 3 | read docs/decisions.md D14 (and D10) | D14 *default* holds: amidi -l name resolution, `fs.openSync(path,"r")`, process.hrtime, `--device`, arecordmidi + capture-convert fallback. Number is D14 not D10 (D10 taken; D14 says so) | yes |
| M2-01 | 4 | read plan § Replay | JSONL -> SMF format 0, division 1000, tempo 1000000, 1 tick = 1 ms -> `tools/midi-send play`; never aplaymidi | yes |
| M2-01 | 5 | read plan § Census | header row control,status,channel,number,min,max,sends_on_release,pair_14bit_msb,pair_14bit_lsb,shift,source_file | yes |
| M2-01 | 6 | read plan § Capture session tables vs `tools/capture-session --list` | each §6 step has prompt, nn-file name and expected minutes; --list matches the files | yes |
| M2-01 | 7 | `/home/mh550/projects/agent-harness/lib/check.sh` | green, 392 tests | yes |
| M2-02 | 1 | `node --test tests/smf.test.mjs` | 15/15 pass in that file's 28 with capture-convert; round-trip, VLQ 1/2/3 bytes read+write, "division 1000 + tempo 1000000 gives 1000 µs per tick" | yes |
| M2-02 | 2 | `tools/capture-convert captures/2026-10-19-quick/platter.mid`; `wc -l`, `tail -1`, grep | "already up to date: 58650 messages"; 58650 lines; last t_us 48390000; 29323 lines of cc d1 6; `git ls-files` lists platter.jsonl | yes |
| M2-02 | 3 | `node --test tests/capture-convert.test.mjs` | pass; asserts 58650 lines, last t_us 48.38–48.40 s, 29323 CC 6, non-decreasing t_us | yes |
| M2-02 | 4 | `grep -n jsonl captures/2026-10-19-quick/README.md` | line 2 names platter.jsonl and the conversion command | yes |
| M2-02 | 5 | check.sh | green | yes |
| M2-03 | 1 | `node --test tests/capture.test.mjs` | 15/15; "three chunks from a FIFO (a split pitch bend, a SysEx, running status)" and "--seconds 1 ends the capture by itself ... exit 0" pass | yes |
| M2-03 | 2 | same test file; `tools/capture --port 'Nope X' --out ...` | "--port resolves the name exactly through amidi -l to <snd dir>/midiC<card>D<dev>" (stubbed amidi) passes; real run with absent name prints the listed ports, exit 4 | yes |
| M2-03 | 3 | `grep -n openSync tools/capture`; test "the source opens only the device, read-only" | single `fs.openSync(path, "r")` (line 55); only `amidi -l` is called; test passes | yes |
| M2-03 | 4 | `tools/capture --help` | documents --port, --device, --out, --seconds, --wait and the Ctrl-C stop | yes |
| M2-03 | 5 | check.sh | green | yes |
| M2-04 | 1 | `node --test tests/replay.test.mjs` | 22/22; dry-run SMF within 1 ms, `--speed 2` halves gaps, `--from 20 --to 37` keeps range | yes |
| M2-04 | 2 | tests "--to-port 'Midi Through' resolves the client by name and runs tools/midi-send play 14:0" and "never names the player itself (source grep)" | both pass; asserts only `aplaymidi -p 14:0 -- <file>` comes from the stub via midi-send | yes |
| M2-04 | 3 | null-sink up, `tools/mixxx-dev start`, `tools/replay --to-port 'Midi Through' --from 19 --to 21 captures/2026-10-19-quick/platter.jsonl`, grep of new mixxx.log lines, `tools/mixxx-dev stop`, null-sink down | 3396 events sent to 14:0; log got 1697 lines `status 0xB0 ... ctrl 0x06`; 0 lines matching warn/error/critical; Mixxx stopped, status `stopped` | yes |
| M2-04 | 4 | check.sh | green | yes |
| M2-05 | 1 | `ls tests/fixtures`; read tests/fixtures/README.md | census-small.jsonl documented as synthetic; 140 lines: note pair, unreleased note, swept CC 7, CC 9/41 pair, pitch bend, two channels | yes |
| M2-05 | 2 | `node --test tests/census.test.mjs`; `tools/census tests/fixtures/census-small.jsonl` | 21/21; header as planned; sends_on_release true only for the on/off note; pair on one row (9,41); CC 7 min 0 max 127; sorted by channel then number | yes |
| M2-05 | 3 | `tools/census --diff reference/rane-one-mk2-djay-midi-map.csv`; test "--diff prints rows only in the MK1 capture, only in the MK2 map, and in both" | output has only-mk1, only-mk2 and both rows; test covers one of each | yes |
| M2-05 | 4 | `tools/census captures/2026-10-19-quick/platter.jsonl`; `cat reference/rane-one-mk1-midi-map.csv` | exactly 3 rows (cc ch1 6, pb ch1, note ch1 0); saved CSV has a `# partial: ...` header comment (differs from a fresh run only in the first comment line's --out text) | yes |
| M2-05 | 5 | check.sh | green | yes |
| M2-06 | 1 | `node --test tests/capture-session.test.mjs` | 25/25; "a full scripted session: one file per step, r re-records and overwrites, s skips, one README line per step" passes | yes |
| M2-06 | 2 | `tools/capture-session --list` | 7 groups, 26 recordings, total 24.75 min (< 25), then 8 extras | yes |
| M2-06 | 3 | read tools/lib/capture-session.mjs lines 26–28, 69; test "platter prompts say to align the tape marks and count ten turns mark to mark; power-on is off, Enter, on" | prompts say align tape mark, "counting each one mark to mark"; power-on says OFF, press Enter, then ON; test passes | yes |
| M2-06 | 4 | tests "--label names the session dir <YYYY-MM-DD>-<label>" and "an existing session is refused without --resume" | both pass; real probe made `captures/2026-10-21-vtest/` (date-label form), since removed | yes |
| M2-06 | 5 | check.sh | green | yes |
| M2-07 | 1 | read HARDWARE-TESTS.md | has Before you start, Run (capture-session + tools/capture + arecordmidi fallback), Time needed (per group, 24.75 min), Commit (git add + message), Report back (INBOX.md) | yes |
| M2-07 | 2 | ran `tools/capture-session --list`, `--help`, `tools/capture --help`, `tools/capture-convert --help`, `arecordmidi -l` | all exist and exit 0 | yes |
| M2-07 | 3 | read file head | "Nothing is sent to the controller during the session ... `~/.rane-armed` is not needed" | yes |
| M2-07 | 4 | check.sh | green | yes |
| M2-08 | 1 | `ls .harness/runs/.../reviews`; read M2-findings.md; `git cat-file -t` on 5b4809d 1169eb9 68ad766; `git show --stat` | M2.diff (283 KB) and M2-findings.md exist; 0 Critical, 2 Important; each has a named fixing commit that adds a test (jsonl.test.mjs, capture-session.test.mjs); red-first results are quoted, not re-provable now | yes |
| M2-08 | 2 | grep JSON.parse/stringify/t_us in tools/capture, replay, census, capture-session, lib/census.mjs | only jsonl.mjs builds/parses lines; the other hits are IPC in capture and census's CSV errors; capture/replay/census import midi-parse/jsonl | yes |
| M2-08 | 3 | `git diff ea48c15 HEAD --numstat -- README.md`; grep HARDWARE-TESTS README.md; spec §5 | +10 lines, link on line 30; spec M2 "Done 2026-10-21" | yes |
| M2-08 | 4 | check.sh | green | yes |


### 2026-10-21 11:05 · M2-08 · passes

- **Changed:** `reviews/M2.diff` (from ea48c15, "M1 verified": 5154 lines) and `reviews/M2-findings.md`. One Opus review found 0 Critical, 2 Important, 2 Minor, 4 duplication and 3 simplification issues. Fixed: #1 a short or failed write in the JSONL writer is cut back to whole lines (5b4809d). #2 capture-session reads takes with `readJsonl`; a damaged take goes to `.part.damaged` instead of crashing `--resume` or being kept (1169eb9). #3 SIGTERM/SIGHUP stop the session's capture, exit 143/129 (1169eb9). #4 census breaks a tie in pair order by time gap (68ad766). Shared now: `hexBytes`, `CHANNEL_LEN` and the type tables in midi-parse.mjs, `formatMessages` in jsonl.mjs, and the new `tools/lib/local-date.mjs`. README +10 lines (M2 tools, links HARDWARE-TESTS.md); spec §5 M2 is marked done 2026-10-21. Tests 387 → 392.
- **Verified:** each fix's test was run red first (red results quoted in the findings), then green. `check.sh`: green, 392 tests. A grep finds no JSONL line built or read outside `tools/lib/jsonl.mjs`.
- **Deferred:** #8, replay's `aconnect -o` lookup next to midi-send's (both refuse, neither mis-routes); it goes with M1 #8/#19. #10 is unchanged.
- **Sent:** nothing to any MIDI port. No Mixxx was started. I killed one orphaned test `capture-stub` (from the review's repro of #3) by its pid.
- **Next session (M3):** a capture's `.part.damaged` files are evidence; `git add captures/<session>` commits them too.
- **Questions for Michael:** none new (D17 is still open from M2-06).

### 2026-10-21 10:20 · M2-07 · passes

- **Changed:** new `HARDWARE-TESTS.md` at the repo root with Before you start, Run, Time needed, Commit and Report back. It follows the plan's outline and D17. No code changed; tests stay at 387.
- **Verified:** every command was run with `--help` or `--list`: `tools/capture-session --help` and `--list`, `tools/capture --help`, `tools/capture-convert --help`, `arecordmidi --help` and `-l`, `tools/census --help`. The times are copied from `--list` (24.75 min, extras 4.40 min, about 5 min of setup). The file says nothing is sent and `~/.rane-armed` is not needed.
- **Sent:** nothing. No Mixxx started.
- **Next session:** M3 needs Michael's capture. Until it lands in `captures/`, anything about the real protocol stays UNVERIFIED.
- **Questions for Michael:** D17: OK to keep the 8 extras optional, or raise the cap to 30 min and fold them in?

### 2026-10-21 09:55 · M2-06 · passes

- **Changed:** new `tools/capture-session`, plus `tools/lib/capture-session.mjs` (pure: the 34 steps, prompts, durations and README rules). New `tools/lib/amidi.mjs`; `tools/capture` now uses it, so there is one `amidi -l` parser. New `tests/capture-session.test.mjs` (22), `tests/amidi.test.mjs` (3) and 13 usage cases. Also **D17 *default*** and an "As built" list in the plan's Capture session section. Tests 349 → 387; `check.sh` green.
- **Verified:** a full scripted session with a `--capture-cmd` stub gives 33 files plus 1 skipped, 34 README lines in order, and `r` replacing the take. Also covered: `--resume` (including after midnight), refusing an existing session, Ctrl-C (to the session, and to the whole process group with the real `tools/capture` on a FIFO) keeping the take as `.part` for review, exits 4/5, `k` keeping a partial take, an empty take needing `k`, and the standby power-on path. `--list`: 7 groups, **24.75 min**, then 4.40 min of extras. Sabotages: 11 of 11 caught. Session tests stable 3× in parallel.
- **D17 *default* (step 2):** honest times total 28.15 min (D15). So 8 recordings became optional extras at the end, nothing dropped: Shift pads in modes 2–8, and deck 2's fast/alt turns, hold, backspin and both stops. **Question:** OK, or raise the cap to 30 and fold them back (`extra: false`)?
- **Review:** an Opus reviewer found 1 Critical, 8 Important and 9 Minor issues. All are fixed test-first except two Minors: skipped steps can't be redone on resume, and a stub slower than 2 s to start under load. Critical: the standby branch recorded with the port present, so a power-cycle killed the take. Takes now go to `.part`, renamed when kept. A prompt bug is also fixed: "align the marks" now comes before Enter, so the ten-turn take holds no alignment motion.
- **Sent:** nothing to any MIDI port. No Mixxx started. Nothing live (build-only); Michael's staged run is in the plan's "Live use" list.
- **Next session (M2-07):** copy times from `tools/capture-session --list` (24.75 + 4.40 extras). Takes are `.jsonl.part` until kept.

### 2026-10-21 09:20 · M2-05 · passes

- **Changed:** new `tools/census` (CLI) and `tools/lib/census.mjs` (pure rules: rows, CSV read/write, MK2 reader, diff). New synthetic `tests/fixtures/census-small.jsonl` (140 lines) and `tests/fixtures/README.md`. New `reference/rane-one-mk1-midi-map.csv` (3 rows, marked partial). New `tests/census.test.mjs` (20) and 13 usage cases. The plan's Census section gained an "As built" list. Tests 315 → 349; `check.sh` green.
- **Verified:** the platter census gives `pb ch1` 0..16383, `note ch1 0` vel 127 with a release, and `cc ch1 6` 0..127. A separate node one-liner over the JSONL gave the same numbers (29323 pb, 29323 CC 6, notes `90007F 800000` ×2). `tools/census --diff reference/rane-one-mk2-djay-midi-map.csv` (step 3 as written; with no capture it reads the MK1 CSV) gives both 2, only-mk1 1, only-mk2 193. awk counts 195 distinct MK2 channel/data/type groups. Mutation checks: 7 of 7 sabotages caught.
- **Finding:** at MK2 channel 0, data 0 is a CC (`libraryRotary`) and data 6 a note (`loadTrack`). The MK1 sent **note 0 and CC 6** there, so the MK2 map is wrong about the MK1's channel 1 kinds (D6 holds: it's a hint).
- **Review:** an Opus reviewer found 2 Important and 5 Minor issues, all fixed test-first. Important: 14-bit values were mis-paired when a capture opens mid-pair or the LSB updates alone. Values now follow the stream's MSB/LSB order with the last other half. Pair decisions go to stderr, since an n+32 button during a sweep could pass the plan's 90 % rule. Minor: adjacency is now on the whole channel stream, a line break in `--comment` and duplicate inputs are refused, `Object.hasOwn` replaces `in` for the MK2 msgType, and CC alternation is judged per file.
- **Sent:** nothing to any MIDI port. No Mixxx was started.
- **Next session (M2-06):** after a capture session, run `tools/census captures/<session>/*.jsonl --shift 16:50 --out reference/rane-one-mk1-midi-map.csv --force` (Shift 16:50 is the MK2's, UNVERIFIED). Read the stderr pair lines.
- **Questions for Michael:** none new. D9–D12 and D14–D16 are still open.

### 2026-10-20 09:40 · M2-04 · passes

- **Changed:** new `tools/replay` (JSONL → SMF at 1 tick = 1 ms → `tools/midi-send play <client>:0`; never starts a player itself). It drops non-channel messages and counts them, has `--from/--to/--speed`, `--dry-run [--out [--force]] [--to-port]`, and exits 4 when two clients have the same name. The gate's route walk moved byte-identical into `tools/lib/rane-route.awk`; replay runs it armed or not. New `tests/replay.test.mjs` (22), 2 midi-send tests and 17 usage cases. Tests 274 → 315; `check.sh` green.
- **Verified:** the tests check SMF bytes and ticks within 0.5 ms of the scaled `t_us`, `--speed 2`, `--from 20 --to 37` and the quick capture's 3396/1697. The stub call log shows exactly one `aplaymidi -p 14:0 -- <tmp>` (from midi-send), the source grep finds no `aplaymidi`, and Rane names and routes exit 3. Mutation checks: 9 of 10 sabotages caught. **Live twice** (dev Mixxx, null sink): `--from 19 --to 21` gave 3396 log lines, **1697 CC 6** (the plan's predicted count; the step's "about 2000"), 0 `[Controller]` warnings and 0 mapping errors. Mixxx was stopped by its id, the default sink was unchanged and the temp SMF was removed.
- **Sent:** twice, `tools/midi-send play 14:0 /tmp/replay-{tka3Fk,h1YK8v}/replay.mid` (3396 channel messages each, Midi Through → Mixxx only; the route walk passed). Nothing went to the Rane One.
- **Review:** an Opus reviewer found 0 Critical, 1 Important and 7 Minor issues. The Important one: `--dry-run --out` could overwrite the input capture. It is now refused unless `--force`. Also fixed test-first: early signal handlers with temp cleanup, exit 128+n, midi-send codes other than 3/4 → 1, and midi-send's `here` via `readlink -f` with `CDPATH` cleared. Left as documented: port 0 only, and the route is checked once, before sending.
- **Next session:** `tools/replay` is ready for M3 replays. Run the dry run first, and use a fresh `--out` (it now refuses to overwrite).
- **Questions for Michael:** none new. D9–D12 and D14–D16 are still open.
- **Proposed change:** M2-04 step 3: "about 2000" → "1697" (or use `--from 20 --to 22` for 1996), as M2-01 proposed.

### 2026-10-20 09:20 · M2-03 · passes

- **Changed:** new `tools/capture`, the read-only rawmidi capture to M2 JSONL. A `--reader` child does the only open, `fs.openSync(path, "r")`, and sends hrtime-stamped frames; the parent writes JSONL through `jsonl.mjs`. New `tests/capture.test.mjs` (15 tests) and 13 capture cases in `tools-usage`. The plan's Capture backend section now matches the build: 4 frame kinds, `CAPTURE_SND_DIR` for tests, exit-4 text, `--force` and stop semantics. Tests 246 → 274; `check.sh` green.
- **Verified:** the FIFO tests cover 3 chunks (a split pitch bend, a SysEx, running status) with strict `readJsonl`, `--seconds 1`, SIGINT/SIGTERM/SIGHUP, and Ctrl-C to the process group. They also cover the stubbed `amidi -l` (exact name, input-only, subdevice ≠ 0 refused), `--wait`, exit 4, and ENOSPC on /dev/full ending the reader. Stable: 5 runs in a row, then 3 in parallel. The step-3 grep shows one open line (54). **Live, read-only:** `--port 'Rane ONE MIDI 1'` gave hw:2,0,0 → `/dev/snd/midiC2D0`, 0 messages in 2.0 s, exit 0. With my own aseqdump holding the port: exit 5 in 2.14 s, no file. aseqdump was killed by pid.
- **Review:** an Opus reviewer found 1 Important issue: a parent dying outside `finish` (an output write error, SIGHUP) left the reader blocked, holding the device. I reproduced it as a hanging test and fixed it test-first (try/catch, an exit handler, SIGHUP). I also fixed 5 Minors (busy/opened race, subdevice, a lost partial frame reported, `--force` not deleting, wider test timing). Two stay documented, not fixed: a stop before the open exits 1, and the microsecond loss window at a stop.
- **Sent:** nothing to any MIDI port. No Mixxx was started.
- **Next session (M2-04+):** a capture of the One needs Mixxx closed (the port is exclusive; exit 5 otherwise). The busy path is not in the suite (a FIFO can't be busy), only live-checked.
- **Questions for Michael:** none new. D9–D12 and D14–D16 are still open.

### 2026-10-20 09:45 · M2-02 · passes

- **Changed:** new `tools/lib/smf.mjs` (SMF read/write, tempo map → µs), `tools/lib/jsonl.mjs` (the only implementation of the M2 line format), `tools/capture-convert`, and the parser's new `flush()` in `midi-parse.mjs`. Committed `captures/2026-10-19-quick/platter.jsonl` (58650 lines, 4.8 MB) and a README line. New tests: `smf` 14, `jsonl` 7, `capture-convert` 14, plus usage cases. Tests 202 → 246; `check.sh` green.
- **Verified:** `tools/capture-convert captures/2026-10-19-quick/platter.mid` on a fresh tree wrote 58650 lines (cc 29323, all `d1` 6; pb 29323; on 2; off 2). The last `t_us` is 48390000 and nothing was dropped. A second conversion was byte-identical to the committed file. Its type/d1/value sequence also matches aseqdump's `platter.txt` line for line (`cmp`: all 58650 messages identical). The plan's 3 example lines are the file's first 3 (asserted).
- **Review:** an Opus reviewer found 10 issues (1 Important, 9 Minor), and I fixed all of them test-first. The Important one: SysEx divided across an F0 packet and F7 continuations was rejected. That fix is recorded as **D16 *default*** and in the plan. The other fixes: an open SysEx at EOF is now written truncated, dropped bytes fail unless `--allow-dropped`, F7 events are flagged `escape`, `parseLine` accepts only the canonical form, `--out` parsing is stricter, `--force` goes through a temp file and rename, `.midi` is accepted, and there are rounding and SysEx running-status tests.
- **Step 2 re-runs:** without `--force`, converting onto an identical existing file is a no-op (exit 0, "already up to date"), so the verifier can run step 2 literally on the committed file. A file that differs is still refused.
- **Sent:** nothing to any MIDI port. No Mixxx was started.
- **Next session (M2-03+):** use `createJsonlWriter`, `readJsonl` and `parser.flush()` (at the end of a capture) from `tools/lib`, and `writeSmf` for replay (it rejects F7 escapes, real-time, system common and truncated SysEx).
- **Questions for Michael:** D16: is it OK that capture-convert refuses dropped bytes by default (`--allow-dropped` overrides)? D9–D12, D14 and D15 are still open.

### 2026-10-20 08:50 · M2-01 · passes

- **Changed:** new `docs/plans/2026-10-19-M2-capture-replay.md` with the sections JSONL format, SMF library, Capture backend, Replay, Census, Capture session, HARDWARE-TESTS outline and Evidence. New `D14 *default*` (capture backend) and `D15 *default*` (session timing) in `docs/decisions.md`. Tests 202 → 202; `check.sh` green.
- **Verified:** I checked each step against the plan with grep. The 3 example JSONL lines are decoded from `platter.mid`'s hex (CC 6 = 92 at 2651 ms, pitch bend 7829 = aseqdump's −363). Read-only probes of `/dev/snd/midiC2D0`: an `O_RDONLY` open takes 42 µs. A blocking open waits indefinitely while aseqdump holds the port (so capture times out after 2 s and exits 5). `process.exit()` hangs while a worker is blocked in `readSync`, so the reader runs in a child process; I prototyped that on a FIFO. When motor-on, the One sends ≈ 1998 messages/s. An Opus review returned 15 findings (8 Important), and I applied all of them.
- **Sent:** nothing to any MIDI port. All my probe processes were stopped.
- **Next session (M2-02+):** build from the plan. M2-04 step 3's `--from 19 --to 21` gives **1697** CC 6, not 2000 (the motor starts at 19.236 s). Replay drops non-channel messages and runs midi-send's route walk via a new `tools/lib/rane-route.awk`. Close Mixxx before any capture (the port is exclusive).
- **Questions for Michael:** (1) D15: honest estimates put the §6 session at ≈ 28 min of steps plus 5 min setup, over the 25 min in M2-06/M2-07. Raise the cap to 30, or cut (pads with Shift in one mode only, the 45 step at 30 s)? (2) D14: is reading the rawmidi device OK as the backend (arecordmidi as fallback)? D9–D12 are still open.
- **Proposed changes:** M2-01 step 3 says `D10 *default*`, but D10 was already the launcher check, so the backend is **D14**; amend the step to D14. M2-06 step 2 and M2-07 step 1: "under 25 minutes" → "under 30 minutes" (D15). M2-04 step 3: "about 2000" → "about 1700", or use `--from 20 --to 22` (1996).

### 2026-10-20 08:30 · verify M1

All 6 features hold; I changed no `passes`. Live run: WAYLAND_DISPLAY=wayland-1, own Mixxx instance 4244755264 started and stopped, null sink up/down, default sink unchanged throughout. `npm test` 202/202. Note: `reviews/M1.diff` no longer equals a fresh `git diff main...HEAD` (779 differing lines, later commits); the file exists, which is all the step needs.

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| M1-01 | 1 | `grep '^## ' docs/plans/2026-10-19-M1-dev-loop.md` | sections Null sink (l.26), Dev profile seed (72), Launcher (161), Mapping skeleton (229), MIDI parser (271), Evidence (314) | yes |
| M1-01 | 2 | read plan l.26-60 | sink `mixxx-dev`, 48 kHz, module-null-sink via pactl; default never changed; `PULSE_SINK=mixxx-dev` via `flatpak run --env=`; check via `pactl list sink-inputs` | yes |
| M1-01 | 3 | read plan l.72-100, 163-175 | seed table (mixxx.cfg, soundconfig.xml 48 kHz, library dir under dev profile, via mixxxdb.sqlite because 2.5 has no cfg key; reasoned) and the flatpak run command with the CLAUDE.md flags | yes |
| M1-01 | 4 | read plan l.173-198 | instance id via `--instance-id-fd` into `dev-profile/mixxx-dev.instance`; stop = `flatpak kill <id>`; "Never `flatpak kill org.mixxx.Mixxx`" | yes |
| M1-01 | 5 | read plan l.259-263, grep output | night rule: bound only to `Midi Through Port-0`; no `<output>`, no `midi.send*` | yes |
| M1-01 | 6 | read plan l.271-312 | `createParser()` with `feed`, running status, SysEx, real-time bytes, `describe(msg)` | yes |
| M1-01 | 7 | `grep -n D9 docs/decisions.md`, read l.27-36 | `D9 *default*` with sink name, routing, instance tracking, night port | yes |
| M1-01 | 8 | `npm test` | 202 pass, 0 fail | yes |
| M1-02 | 1 | `git log --reverse -- tests/midi-parse.test.mjs tools/lib/midi-parse.mjs` | one commit fc3c032 holds both (test and impl equal, as the step allows) | yes |
| M1-02 | 2 | `node --test tests/midi-parse.test.mjs`; read asserts | 16/16 pass; cases for 3- and 2-byte messages, running status across feeds, split SysEx, 0xF8 inside running status, pb 0..16383, mid-message splits | yes |
| M1-02 | 3 | node import of module | exports `createParser`, `describe`; `cc ch1 6=92`; `pb ch1 16383`, `pb ch1 8192` | yes |
| M1-02 | 4 | read test l.208-217 | capture test asserts 58650 messages = {cc 29323, pb 29323, on 2, off 2}, dropped 0; test passes | yes |
| M1-02 | 5 | `npm test` | 202/202 | yes |
| M1-03 | 1 | `node --test tests/null-sink.test.mjs`; read stub l.26 | 52/52 pass; stub exits 99 on `set-default-*`; up/up-twice/down-by-recorded-id/status tests present and green | yes |
| M1-03 | 2 | real `tools/null-sink up`, `pactl list short sinks`, `pactl info`, `status`, `down` | sink 2207 `mixxx-dev` 48000Hz listed; Default Sink `alsa_output.usb-Rane_Rane_ONE_A-00...` before, after up and after down; down removed it (count 0) | yes |
| M1-03 | 3 | `node --test tests/install-mapping.test.mjs` | 14/14 pass: copies all, overwrites stale, refuses (exit 3) inside `.mixxx` | yes |
| M1-03 | 4 | `npm test` | 202/202 | yes |
| M1-04 | 1 | `node --test tests/mixxx-dev.test.mjs` | all pass (seed, flags, instance file, stop by id never by app name, stop without file exit 0, exit 3 guards) | yes |
| M1-04 | 2 | `flatpak run --command=sh org.mixxx.Mixxx -c 'touch ~/.var/app/org.mixxx.Mixxx/dev-profile/.probe'`; evidence in plan | exit 0; file visible on host (removed after); evidence present in plan | yes |
| M1-04 | 3 | `tools/null-sink up && tools/mixxx-dev start`; `ls mixxx.log`; grep stdout; `pactl list sink-inputs`; `stop` | start OK in 4 s; mixxx.log new (08:20:24 vs 08:18:01); stdout line 9 `Configuration file is at the current version "2.5.6"`; Mixxx stream `mixxx-dev` on Sink 2235 = mixxx-dev, only other input on sink 779 is speech-dispatcher, not Mixxx; stop printed `stopped 4244755264`, no Mixxx in `flatpak ps` | yes |
| M1-04 | 4 | `tools/mixxx-dev log \| wc -l` | 50 lines | yes |
| M1-04 | 5 | `npm test` | 202/202 | yes |
| M1-05 | 1 | read xml, `tests/mapping-xml.test.mjs`, `node --check` test | controller id `Rane ONE`, scripts platter then scripts, prefix RaneOne, no output; check test passes | yes |
| M1-05 | 2 | mapping-xml tests: init/shutdown one line, no throw, purity grep | all pass (11/11) | yes |
| M1-05 | 3 | `node --test tests/mapping-xml.test.mjs` | 11/11 pass incl. XML parses, list matches files, no output | yes |
| M1-05 | 4 | `tools/install-mapping`, `tools/mixxx-dev start`, read mixxx.log | `RaneOne: init Midi Through Port-0` at 08:20:24; no ControllerScriptEngine warning/error; run was under --controller-abort-on-warning and survived | yes |
| M1-05 | 5 | `tools/midi-send play 14:0 tests/fixtures/three-notes.mid`; `tools/install-mapping` while running | 3 incoming lines status 0x90 (ch 1) at 08:20:29; reload logged `RaneOne: shutdown` then `RaneOne: init` (twice, one per watched file; plus the documented "Failed to watch script file" warnings, which the plan expects) | yes |
| M1-05 | 6 | `npm test` | 202/202 | yes |
| M1-06 | 1 | `ls reviews/M1.diff` | exists, 3268 lines (stale vs current tree, see note) | yes |
| M1-06 | 2 | read `reviews/M1-findings.md`; `git show --stat` of 680b5f2 2eb7c11 5002172 e27284d 737053e 1059b30 | every Important (#1-5) has a fixing commit and a test file in that commit; "failed first" claims not independently replayed | yes |
| M1-06 | 3 | ran each tool with a bad arg; `git grep` amidi/aplaymidi and `.mixxx` | null-sink, mixxx-dev, install-mapping, midi-send all exit 2; no amidi/aplaymidi outside midi-send; `.mixxx` appears only in `tools/lib/profile.sh` (the guard); tools-usage tests 20/20 | yes |
| M1-06 | 4 | read README.md; spec l.52 | Dev loop section 15 lines incl. heading and a blank, covers all four tools; spec M1 "Done 2026-10-19" | yes |
| M1-06 | 5 | `npm test` | 202/202 | yes |

### 2026-10-20 08:19 · M1-05 · passes

- **Changed:** no code. I re-verified every step live and added the 08:17 evidence to `docs/plans/2026-10-19-M1-dev-loop.md` (M1-05 binding). Tests 202 → 202; `check.sh` green.
- **Steps 1–3:** `node --check` OK on both scripts. The XML has controller id `Rane ONE`, the scripts in order (prefix `RaneOne`) and no `<output>`. `tests/mapping-xml.test.mjs` 11/11, including the purity grep.
- **Step 4 (live, `WAYLAND_DISPLAY=wayland-1`):** `null-sink up && install-mapping && mixxx-dev start` → `running: 3019912654` in 6 s, stream on sink 2120 `mixxx-dev`. `mixxx.cfg` binds `Midi_Through_Port-0` to the dev-profile mapping. The log has `RaneOne: init Midi Through Port-0` and 0 Warning/Critical/Fatal/Mapping Error lines on `[Controller]`.
- **Step 5 (as amended):** `tools/midi-send play 14:0 tests/fixtures/three-notes.mid` → exit 0 and exactly 3 `status 0x90` lines (+3 `0x80`). Re-running `tools/install-mapping` → 2 `RaneOne: shutdown` → `RaneOne: init` pairs, with only the predicted `Failed to watch script file` warnings. Then stop, `flatpak ps` with no Mixxx, sink down, Default Sink unchanged (Rane ONE), no `mixxx` process left.
- **Sent to the Rane:** nothing. The only MIDI sent was the fixture, to Midi Through 14:0, whose only onward subscription was Mixxx (128:1).
- **Next session:** all of M1 passes now.
- **Questions for Michael:** D9–D12 defaults are still open (see earlier entries).
- **Proposed changes:** M1-05 step 4: "no `ControllerScriptEngine` warning" → "no Warning/Critical on the `[Controller]` thread". That category doesn't exist; the 17:36 entry has the details.

### 2026-10-20 08:17 · M1-04 · passes

- **Changed:** no code. The launcher already used option (a) for readiness (D10), so step 3 as amended only needed a live re-check. Added launch 5's evidence to `docs/plans/2026-10-19-M1-dev-loop.md`. Tests 202 → 202; `check.sh` green.
- **Verified (live, `WAYLAND_DISPLAY=wayland-1`, 08:14:50):** `tools/null-sink up && tools/mixxx-dev start` → `running: 3013574568`, rc 0 in 8 s. New `mixxx.log` (inode 49306080 → 49310666). This launch's `mixxx-dev.stdout` line 9 is `Configuration file is at the current version "2.5.6"`. The Mixxx stream (`mixxx.bin`) was on sink 2029 `mixxx-dev`. The only stream on the Rane was `speech-dispatcher-dummy` (not ours) and none was on the PCI sink. `tools/mixxx-dev log` printed 50 lines, identical to `tail -n 50`. After `stop`, `flatpak ps` showed no Mixxx. Sink down; Default Sink/Source unchanged; no `mixxx.bin` left running. Step 1: `tests/mixxx-dev.test.mjs` 67/67. Step 2: probe re-run, exit 0, file visible on the host, then deleted.
- **Sent to the Rane:** nothing.
- **Next session:** M1-05 step 5 is amended (shutdown is proven by a hot reload via `tools/install-mapping`). Re-verify it live. The other M1-05 steps held in verify-M1.
- **Questions for Michael:** D9–D12 defaults are still open (see earlier entries).
- **Proposed changes:** none.

### 2026-10-19 18:17 · M3-01 · passes

- **Changed:** new `docs/plans/2026-10-19-M3-measurement.md` (WAV library, make-test-audio, wow-flutter algorithm, Telemetry format, drift, record-output, Evidence); `D11 *default*` (telemetry JSONL) and `D12 *default*` (how §3's wow & flutter is measured) in `docs/decisions.md`. **Suite fix first:** the init check was red on a rare race in `tools/mixxx-dev start`. It read the id file, then checked whether the launcher was alive, so a launcher that wrote its id and exited in between looked dead. Liveness is now sampled before the read. Not reproduced in 60 stressed runs; the fix is correct by construction (reviewer agreed). Tests 202 → 202; `check.sh` green.
- **Verified:** each step grepped in the plan/decisions. A scratch prototype of the wow-flutter algorithm met every M3-03 tolerance (0.1 % @ 4 Hz → 0.1008 %; 0.5 % @ 0.5 Hz → 0.4913 %; 1010 Hz → 0.0013 %, mean 1010.000; 1 ms dropout → `dropouts 1`). An Opus review gave 10 findings, all applied (2 checked against WirePlumber's source).
- **Next sessions must know:** (1) a literal −3 dB high-pass at 0.5 Hz, run zero-phase, halves 0.5 Hz wow (0.252 %), so the corner is 0.2 Hz (D12). (2) WirePlumber 0.5.12 probably won't resolve `--target mixxx-dev.monitor` for native `pw-record`. With `dont-fallback` it destroys the stream, so record-output must check the frame count. The fallback is `--target mixxx-dev -P stream.capture.sink=true`. The default source is the **Rane's capture**. (3) Random 0–21 ms `playposition` sampling lag alone fakes 8–10 ms of drift, so M7 must log from a `playposition` connection callback.
- **Questions for Michael:** D11 (telemetry format) and D12 (peak deviation, passband from 0.5 Hz, unweighted): OK as defaults? D9/D10 and the M1-04 INBOX question are still open.
- **Proposed changes:** M3-05 step 1: allow `--target mixxx-dev.monitor` to be translated to `--target mixxx-dev -P stream.capture.sink=true` if M3-05's live check shows the `.monitor` name doesn't link. Add to M7 a `tools/mixxx-dev telemetry` subcommand that extracts `RaneOne telemetry` lines from `mixxx.log` (scripts can't write files).

### 2026-10-19 18:08 · M1-04 · not yet (parked on a step change)

- **Changed:** no code. Added a question to `INBOX.md` and one sentence to D10 in `docs/decisions.md` (the Mixxx init order). Tests 202 → 202; `check.sh` is green.
- **Why not passing:** step 3 can't hold as written. I re-checked against the `mixxxdj/mixxx` `2.5.6` tag. The "Mixxx 2.5.6 … is starting" line is a default-category `qDebug` (`versionstore.cpp`), and `controllerDebugCategoryFilter` (`logging.cpp`) forces that off under `--controller-debug`, which step 1 requires. The "Configuration file is at the current version" line runs before `Logging::initialize`, so it only ever reaches stdout. `grep -c '2\.5\.6\|is starting'` over all 8 dev-profile logs: 0 each. I did not write a line into Mixxx's log myself, because that would be faking it.
- **Next session:** every other M1-04 step already holds (verify-M1 table). Once Michael answers, re-verify only step 3 live. Under (a), check the new `mixxx.log` and the line in `dev-profile/mixxx-dev.stdout`. Under (b), first change the launcher's flags, the tests and CLAUDE.md.
- **Question for Michael (INBOX):** amend M1-04 step 3 to "a new `mixxx.log` within 60 s and `mixxx-dev.stdout` contains `Configuration file is at the current version "2.5.6"`" (recommended), or drop `--controller-debug`?
- **Proposed changes:** M1-04 step 3 as in (a). M1-05 step 5's proposed change from the 17:36 entry still stands (`stop` is a hard kill, so `shutdown` is proven by a hot reload).

### 2026-10-19 18:05 · verify M1

Features passing: M1-01, M1-02, M1-03, M1-06. Set to false: **M1-04** (step 3: no Mixxx version line in mixxx.log; it is in mixxx-dev.stdout) and **M1-05** (step 5: `stop` is a hard kill, no `RaneOne: shutdown` in the log). Live run done with WAYLAND_DISPLAY set; Mixxx stopped, sink removed, Default Sink unchanged (Rane ONE), `~/.rane-armed` absent.

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| M1-01 | 1 | grep '^## ' on docs/plans/2026-10-19-M1-dev-loop.md | Sections Null sink, Dev profile seed, Launcher, Mapping skeleton, MIDI parser, Evidence all present | yes |
| M1-01 | 2 | read Null sink section (l.26-70) | sink `mixxx-dev`, 48 kHz, module-null-sink via pactl, no default-sink change, `PULSE_SINK=mixxx-dev` via `flatpak run --env=`, `pactl list sink-inputs` check | yes |
| M1-01 | 3 | read Dev profile seed section | lists mixxx.cfg (library dir via mixxxdb `directories` row under dev profile), soundconfig.xml 48 kHz, flatpak run command with the CLAUDE.md flags | yes |
| M1-01 | 4 | read Launcher section l.190-200 | instance id in mixxx-dev.instance, `flatpak kill <instance id>`, never `flatpak kill org.mixxx.Mixxx` | yes |
| M1-01 | 5 | read Mapping skeleton l.229-265 | bound only to `Midi Through Port-0`; no <output>, no midi.send* calls | yes |
| M1-01 | 6 | read MIDI parser section l.271-305 | createParser().feed -> messages, running status, SysEx, real-time bytes, describe(msg) specified | yes |
| M1-01 | 7 | read docs/decisions.md D9 | `D9 *default*` names sink, routing, instance tracking, night port rule | yes |
| M1-01 | 8 | check.sh and `node --test tests/*.test.mjs` area runs | check: green (202 tests) | yes |
| M1-02 | 1 | `git log --stat -- tests/midi-parse.test.mjs tools/lib/midi-parse.mjs` | both files added in the same commit fc3c032 (precedes-or-equals satisfied) | yes |
| M1-02 | 2 | `node --test tests/midi-parse.test.mjs`; read test names | 16/16 pass; cover 3-/2-byte, running status across feeds, split SysEx, 0xF8 in running status, 14-bit pb, mid-message splits | yes |
| M1-02 | 3 | read describe cases in test l.138+ | `{0xb0,[6,92]}` -> `cc ch1 6=92`; pb rendered `pb ch1 <n>`; exports createParser/describe | yes |
| M1-02 | 4 | read test l.208-218; `grep -c` on captures/2026-10-19-quick/platter.txt | asserts 58650 msgs = 29323 cc, 29323 pb, 2 on+2 off; my grep: 29323 CC, 29323 Pitch bend, 4 Note | yes |
| M1-02 | 5 | check.sh | green, 202 tests | yes |
| M1-03 | 1 | `node --test tests/null-sink.test.mjs`; read test names/stub | 38/38 pass; up/up-twice/down-by-id/status tests present; stub pactl exits 99 on set-default-*, 'no invocation changes default' test | yes |
| M1-03 | 2 | live: `tools/null-sink up`; `pactl list short sinks`; `pactl info|grep Default`; `down` | mixxx-dev listed (48000Hz); Default Sink = Rane analog-surround-40 before, after up, after down; sink gone after down (count 0) | yes |
| M1-03 | 3 | `node --test tests/install-mapping.test.mjs` | 14/14 pass: copy into controllers/, overwrite stale, refuse exit 3 for real-profile paths | yes |
| M1-03 | 4 | check.sh | green | yes |
| M1-04 | 1 | `node --test tests/mixxx-dev.test.mjs` | 67/67 pass (stubbed flatpak/pactl; start/stop/instance/exit 3 cases) | yes |
| M1-04 | 2 | `flatpak run --command=sh org.mixxx.Mixxx -c 'touch .../dev-profile/.probe'`; ls on host; grep plan Evidence | rc=0, file visible on host (17:58), deleted; plan Evidence l.343-347 records it | yes |
| M1-04 | 3 | live (WAYLAND_DISPLAY=wayland-1): `null-sink up`, `mixxx-dev start`; grep mixxx.log for version; `pactl list sink-inputs`; `stop`; `flatpak ps` | start ok, stream 'mixxx-dev' on sink 1814=mixxx-dev, none on Rane/PCI, stop removed instance. BUT mixxx.log has NO Mixxx version line (grep 2.5.6 = 0); it is only on mixxx-dev.stdout ('Configuration file is at the current version 2.5.6'). Step says mixxx.log | NO |
| M1-04 | 4 | `tools/mixxx-dev log | wc -l` | 50 lines | yes |
| M1-04 | 5 | check.sh | green | yes |
| M1-05 | 1 | read mapping/Rane-One.midi.xml; `node --check` both scripts | controller id 'Rane ONE', scripts rane-one-platter.js then Rane-One-scripts.js (prefix RaneOne), no <output>, node --check OK | yes |
| M1-05 | 2 | read Rane-One-scripts.js, grep platter, tests/mapping-xml.test.mjs l.114-190 | one console.log each in init/shutdown; platter has no engine/midi/print refs; guard + never-throw tests present | yes |
| M1-05 | 3 | `node --test tests/mapping-xml.test.mjs` | 11/11 pass (parse, script list vs files, no output) | yes |
| M1-05 | 4 | live: install-mapping, mixxx-dev start; grep mixxx.cfg and log | cfg binds Midi_Through_Port-0 to dev-profile/controllers/Rane-One.midi.xml; log has `RaneOne: init Midi Through Port-0`; no ControllerScriptEngine warning (other non-controller warnings present: underflow, JACK, SCHED_FIFO) | yes |
| M1-05 | 5 | live: `tools/midi-send play 14:0 tests/fixtures/three-notes.mid`; then `tools/mixxx-dev stop`; grep shutdown | 3 note-on 0x90 lines (+3 0x80) logged; but after stop the log has 0 `RaneOne: shutdown` lines (flatpak kill is a hard kill; plan l.447 admits it). Step says stop logs shutdown | NO |
| M1-05 | 6 | check.sh | green | yes |
| M1-06 | 1 | ls reviews/; compare M1.diff with fresh `git diff main...HEAD -- tools tests mapping docs package.json` | M1.diff exists (3268 lines); fresh diff differs by 518 lines because fixes landed after; step only needs the file to exist and be read | yes |
| M1-06 | 2 | read reviews/M1-findings.md | 20 findings with severity; each of 5 Important lists tests-failed-first and fix commit (680b5f2, 2eb7c11, 5002172, e27284d) | yes |
| M1-06 | 3 | `tools/<each> --bogus` exit codes; grep amidi/aplaymidi/.mixxx in tools | null-sink, mixxx-dev, install-mapping, midi-send all exit 2; no amidi/aplaymidi outside midi-send (only .mixxx guard/refusal references); tests/tools-usage 20/20 | yes |
| M1-06 | 4 | read README.md (26 lines) and docs/spec.md l.52 | Dev loop section l.12-26 = 15 lines covering the 3 tools and loop; spec M1 'Done 2026-10-19' | yes |
| M1-06 | 5 | check.sh | green | yes |

### 2026-10-19 17:52 · M1-06 · passes

- **Changed:** `reviews/M1.diff` + `reviews/M1-findings.md` (20 findings: 5 Important, 12 Minor, 3 Simplification; 13 fixed, 7 deferred with reasons). Fixes in `tools/midi-send` (`raw` now route-checks the card's seq client and takes only hex bytes; arms **only** on `$HOME/.rane-armed`, `RANE_ARM_FILE` removed), `tools/null-sink` (`LC_ALL=C`, refuses `up` with no visible default sink, `NULL_SINK_SETTLE` 0–9999, missing launcher = maybe running), `tools/mixxx-dev` (stream props `node.dont-reconnect`/`node.dont-fallback`, id before `mv`, launcher killed only while alive), `dev-seed.mjs` (version exactly x.y.z). Every tool now prints `usage: tools/<name> …`/exit 2 (new `tests/tools-usage.test.mjs`). README dev-loop section (15 lines); spec §5 M1 marked done. Tests 166 → 202; `check.sh` green.
- **Verified:** each fix had its test run red first (counts in the findings file); the mapping `midi` test was mutation-checked. Live at 17:50: the dev Mixxx stream (instance 1023889390) was on `mixxx-dev` and its pw node 102 had `node.dont-reconnect`/`node.dont-fallback` true. Afterwards nothing was running, the sink was absent and the Default Sink was unchanged (I re-checked all of it). The sink was **not** removed under a running Mixxx to watch the new behaviour, which would risk a stream on the Rane.
- **Next sessions must know:** to arm in tests, set `HOME` to a temp dir that holds `.rane-armed`. A new tool in `tools/` fails the suite until `tests/tools-usage.test.mjs` has bad-argument cases for it. Deferred to M2: one shared `aconnect -l` walk (findings #8, #19), since `tools/replay` will be a third user. Also deferred: the lock race between `null-sink down` and `start` (#6, now fails closed).
- **Questions for Michael:** (1) OK that `tools/midi-send` no longer honours `RANE_ARM_FILE`? Only `~/.rane-armed` arms it now. (2) Do you want to watch, once, what happens when `mixxx-dev` is unloaded under a running dev Mixxx? Expected: the stream is left unlinked, never moved to the Rane. Steps: `tools/null-sink up && tools/install-mapping && tools/mixxx-dev start`, then `pactl unload-module <id from dev-profile/null-sink.module>` with the Rane's volume down, then `pactl list sink-inputs`. Undo: `tools/mixxx-dev stop`. D9 and D10 are still open.
- **Proposed changes:** none.

### 2026-10-19 17:36 · M1-05 · passes

- **Changed:** new `mapping/Rane-One.midi.xml`, `mapping/rane-one-platter.js` (empty pure `RaneOnePlatter`), `mapping/Rane-One-scripts.js` (`RaneOne.guard`, `init`, `shutdown`); `tests/mapping-xml.test.mjs` (10, with a zero-dep XML well-formedness parser), `tests/fixtures/three-notes.mid` + `tests/fixtures-three-notes.test.mjs` (1); **gate hardening** in `tools/midi-send` (+11 tests). Evidence is in the M1 plan. Tests 144 → 166; `check.sh` green.
- **Verified live** (`WAYLAND_DISPLAY=wayland-1`, twice; the second run, 17:33, used the final code): the log shows `Opening Midi Through Port-0`, then `RaneOne: init Midi Through Port-0`. There were no Warnings on the `[Controller]` thread and no Mapping Error. `tools/midi-send play 14:0 tests/fixtures/three-notes.mid` gave exactly 3 `status 0x90` lines (+3 `0x80`). Re-installing the mapping (a hot reload) gave `RaneOne: shutdown` → `RaneOne: init` pairs, with only the predicted "Failed to watch script file" warnings. Mixxx is stopped, the sink is down and the Default Sink never changed.
- **Step 5 caveat:** `tools/mixxx-dev stop` logs **no** `RaneOne: shutdown` (counted: 0). It is a hard kill, and Mixxx 2.5 has no signal handler (re-checked in the 2.5 source). So `shutdown()` is proven by the hot reload, as M1-01 planned. The binding and the device name are in the plan's Evidence. The log brackets show thread names, not categories, so "loads cleanly" is applied to the `[Controller]` thread.
- **Review:** an Opus reviewer found 2 Critical gate bypasses, both reproduced with stubs: `play 14:0 -p 24:0 x.mid` (an old hole: aplaymidi takes extra `-p`) and `play 14:00`. Both are fixed test-first, along with 2 Important and 4 Minor findings (routes through user-client bridges, guard failures now `console.warn`, quotes in client names, awk failure fails closed, a nested-handler no-throw test). Still open: the guard has no pitch-fader fallback yet (TODO for M7). `raw` mode and PipeWire's MIDI bridge aren't route-checked.
- **Next sessions must know:** `midi-send play` takes exactly one file and refuses any route to a Rane through `aconnect -l`, including through Mixxx's own `Client-128` if Mixxx is bound to the Rane. The seed now binds Midi Through, because the mapping is installed. Real Note-offs arrive as `0x80`.
- **Proposed changes:** M1-05 step 5: "`tools/mixxx-dev stop` then logs `RaneOne: shutdown`" → "re-running `tools/install-mapping` while Mixxx runs logs `RaneOne: shutdown` followed by `RaneOne: init`". M1-05 step 4: "no `ControllerScriptEngine` warning" → "no Warning/Critical on the `[Controller]` thread".
- **Questions for Michael:** none new (D9 and D10 are still open).

### 2026-10-19 17:22 · M1-04 · passes

- **Changed:** new `tools/mixxx-dev` (start/stop/status/log), `tools/lib/dev-seed.mjs` (mixxx.cfg keys, launcher-owned soundconfig.xml, `mixxxdb.sqlite` library row via `node:sqlite`), `tests/mixxx-dev.test.mjs` (58), `tests/dev-seed.test.mjs` (9); **D10 *default*** in decisions; Evidence + as-built in the M1 plan. Tests 68 → 144; `check.sh` green.
- **Verified live** (`WAYLAND_DISPLAY=wayland-1`): sandbox probe at 16:46:56 OK, then four launches. Final run 17:21:20: `running: 3315317343` in 7 s. The stream (`application.name = "mixxx-dev"`, so `PULSE_PROP_OVERRIDE` works) was on the `mixxx-dev` sink, and nothing of ours was on the Rane or PCI sinks. The Rane PCM was `closed`, and soundconfig came back as ALSA/`pulse`. No library chooser; the seeded row survived Mixxx's schema upgrade 0→39. `null-sink down` refused while Mixxx ran. `stop` → gone from `flatpak ps` (Michael's protonvpn instance untouched) → `stopped`. Sink down; the default sink never changed. **No Mixxx is running and the sink is down.**
- **Step 3 caveat:** under `--controller-debug`, Mixxx 2.5.6 never writes its version to `mixxx.log`: it is a `qDebug` in the default category, which `controllerDebugCategoryFilter` drops. So the launcher reads the exact line `Configuration file is at the current version "2.5.6"` from the launch's stdout and requires a new `mixxx.log` (D10). Everything else in step 3 held literally. The first two launches failed and were stopped as designed: one on a not-yet-linked stream (`Sink: 4294967295`, now "not yet"), one on the missing version line.
- **Review:** an Opus reviewer found 4 Important (failed starts that left Mixxx running: a set -e exit, a `flatpak ps` failure, octal timeouts like `08`, no trap) and 4 Minor issues. All are fixed test-first with an EXIT trap, `flock` on `mixxx-dev.lock` (not inherited by Mixxx), "maybe running" on a `flatpak ps` error, refusing a pre-existing `mixxx-dev` stream and `LC_ALL=C`. Mutation-checked. Stream-to-pid tying was not done: the sandbox reports pid `2`.
- **Next sessions must know:** the PortMidi device list is not in `mixxx.log` at this level, so M1-05 must confirm the `Midi_Through_Port-0` key another way. The seed binds Midi Through only once `controllers/Rane-One.midi.xml` exists. `status` prints `busy` (exit 0) while a start or stop holds the lock. Mixxx logs Warnings even with no mapping (JACK rename, `samplers.xml`, SCHED_FIFO, underflow), all outside `controller.*`.
- **Proposed changes:** M1-04 step 3: "mixxx.log containing the Mixxx version line" → "a new mixxx.log, and `mixxx-dev.stdout` containing `Configuration file is at the current version "<version>"`" (D10).
- **Question for Michael:** D10: OK to prove the running Mixxx version from its stdout rather than `mixxx.log`? (The alternative is dropping `--controller-debug`, which M1-05 needs.)

### 2026-10-19 16:47 · M1-03 · passes

- **Changed:** new `tools/null-sink` (up/down/status), `tools/install-mapping`, `tools/lib/profile.sh` (`profile_guard`, `guard_path`: exit 3 for the real profile, inside it or an ancestor, as written and resolved), `tests/null-sink.test.mjs` (30), `tests/install-mapping.test.mjs` (14); Evidence + as-built notes in the M1 plan. Tests 24 → 68; `check.sh` green.
- **Verified live (16:39, re-run 16:44 after fixes):** `tools/null-sink up` → module 536870916, `pactl list short sinks` shows `mixxx-dev` (float32le 2ch 48000Hz); Default Sink stayed `alsa_output.usb-Rane_Rane_ONE_A-00…` before, after, 3 s later and after `down`; `down` → `grep -c mixxx-dev` 0, `status` → `absent`. Sink is down now. No Mixxx was started.
- **Review:** I gave the diff to an Opus reviewer. It found 6 Important and 6 Minor issues, all fixed test-first with failing tests seen first, and mutation-checked where cheap. The worst two: a symlinked `dev-profile/controllers` let install-mapping write into the real `.mixxx`, and `null-sink down` read any launcher error as "stopped".
- **Next sessions must know:** `null-sink down` proceeds only if `tools/mixxx-dev status` exits 1 and prints exactly `stopped`, so M1-04 must keep that contract. Tests strip `MIXXX_DEV_*`/`NULL_SINK_*` from the env and use a fake HOME, so they can't reach the real dev profile. `NULL_SINK_SETTLE=0` in tests. install-mapping writes files with mode 644, via `mktemp` + `mv -T`.
- **Questions for Michael:** none new (D9 still open).

### 2026-10-19 16:45 · M1-02 · passes

- **Changed:** new `tools/lib/midi-parse.mjs` (`createParser()` → `feed/reset/stats`, `describe(msg)`) and `tests/midi-parse.test.mjs` (16 tests, written first, committed together with the module). The plan's MIDI parser section notes the as-built `stats.dropped` meaning (bytes, not events). Tests 8 → 24; `check.sh` green.
- **Verified:** `node --test tests/midi-parse.test.mjs` 16/16. The quick capture `captures/2026-10-19-quick/platter.mid`, decoded by an inline SMF walk, parses to 58,650 messages: **29,323 CC, 29,323 pitch bend, 2 note-on, 2 note-off**, 0 dropped. The first two match `platter.txt` (CC 6=92, then pitch bend −363 = `pb ch1 7829`). The same result holds with random 1–7-byte feed splits and interleaved 0xF8. Mutation check: making real-time bytes clear running status fails a test. An Opus reviewer found no blocking bugs. Its fixes are in: `feed`/`describe` never throw, even on hostile iterables or malformed messages; a non-byte element in the middle of a message abandons that message instead of joining its neighbours; on and off are counted separately.
- **Next sessions must know:** the capture alternates CC/PB, so running status never helps on that stream. The SMF went through the ALSA sequencer, so the Rane's real wire bytes (running status, note-on velocity 0) are **UNVERIFIED**; a rawmidi capture (M2) would show them. The test's SMF walk is only good for this file (fixed header length, no chunk-type check). Don't reuse it as a general SMF reader; M2's converter needs a real one. There is no `flush()`: a SysEx still open at end of stream is discarded uncounted.
- **Questions for Michael:** none new (D9 from M1-01 still open).

### 2026-10-19 · M1-01 · passes

- **Changed:** new `docs/plans/2026-10-19-M1-dev-loop.md` (sections Null sink, Dev profile seed, Launcher, Mapping skeleton, MIDI parser, Evidence); `docs/decisions.md` gains **D9 *default***. Tests 8 → 8 (plan only); `check.sh` green.
- **Verified:** I checked every Mixxx claim against the 2.5 source (controllermanager, coreservices, soundmanagerconfig, portmidienumerator, script engine, schema.xml, upgrade.cpp). An Opus reviewer re-checked them and found 12 issues; I fixed all 12 in the plan. The worst one: `null-sink down` with Mixxx still running would move its stream to the default sink, which is the Rane One.
- **Next sessions must know:**
  - The library chooser depends on the DB `directories` table, not `mixxx.cfg`. The seed writes `mixxxdb.sqlite` with `node:sqlite`.
  - Mixxx 2.5 has no SIGTERM handler, so `stop` is a hard kill. Use `--log-flush-level debug`; `shutdown()` evidence comes from a script hot reload.
  - `flatpak run --instance-id-fd=3` gives the instance id directly.
  - On COSMIC, the menu-bar hint dialog blocks startup; the seed sets `show_menubar_hint 0`.
  - If `soundconfig.xml` fails, Mixxx falls back to JACK or a `hw:` device (possibly the Rane One), so the launcher rewrites it before every start.
- **Proposed changes:**
  - M1-01 step 3: the library dir does not live in `mixxx.cfg` (see the plan).
  - M1-05 step 5: "`tools/mixxx-dev stop` then logs `RaneOne: shutdown`" cannot hold, because stop is a hard kill. Prove it by re-running `tools/install-mapping` while Mixxx runs.
  - M1-05 step 4: there is no `ControllerScriptEngine` log category (scripts log under `controller.<device>`). Use the plan's "loads cleanly" rule.
  - M1-05: add gate hardening to `tools/midi-send`. It should refuse when the destination is subscribed onward to a Rane client.
- **Question for Michael:** D9: OK that the dev Mixxx never binds the real Rane ONE port until you say so, and that its audio goes only to the `mixxx-dev` null sink?

## 2026-10-19 · Initializer (Fable)

**Scope:** night 1 = M1–M4 (brief from Michael, 15:57). No hardware output. 28 features: M1 dev loop 6,
M2 capture and replay 8, M3 measurement tools 6, M4 platter core 8. Milestone dependencies: M2 after M1;
M3 independent (M3-05 needs M1-03 for the null sink); M4 after M2-02 (the converted real capture).
Only M2-07 (HARDWARE-TESTS.md) gates on just M2-06, as the spec asks.

### The quick capture is real platter data. Build M4 against it, not the Twelve hypothesis.

`captures/2026-10-19-quick/` (commit 473e2ae, "deck 1: slow turn fwd/back by hand, motor on 15 s, hold
3 s, stop"). `platter.txt` is an `aseqdump` listing without timing; `platter.mid` is `arecordmidi` output:
SMF format 0, division 1000, tempo 1,000,000 µs/quarter, so **1 tick = 1 ms**. 58,650 events over 48.39 s.
What I measured tonight (M4-01 must redo this with a tool and cite it properly; treat my numbers as a
preview, not a citation):

| Phase (s) | What Michael did | CC 6 per s | CC 6 delta per msg | pitch-bend delta per msg |
|---|---|---|---|---|
| 2–8 | slow hand turn forward | ~600–900 | +1 (16× +2) | 2600–3400, scattered |
| 9–15 | slow hand turn backward | ~600–760 | −1 (33× −2) | 3600–3800, scattered |
| 20–36 | motor on | **998–999** | **+2** (16661 of 16970) | **2820–2830** (16400 of 16970) |
| 38–41 | record held still | ~16 | ±1 dither | ≈ 0 (−1 per message) |
| 41–44 | released, motor | 998–999 | +2 | 2820–2830 |
| 45–49 | stopped | ~20 | ±1 dither | ≈ 0 |

- All messages are on channel 1 (0-based 0): CC 6, pitch bend, and note 0 (on/off twice: at 19.24 s for
  95 ms and at 44.67 s for 110 ms, exactly when the motor started and stopped, so note 0 is most likely the
  Play button, **not** a platter touch sensor; the 3 s hold produced no note at all).
- A CC 6 and a pitch bend always arrive as a pair in the same millisecond (29,116 of 29,325 pairs), CC first.
- Net CC 6 ticks during 20–36 s: 31,982 in 16 s = 1,999 ticks/s = **3,598 ticks/rev if the motor was at
  33⅓**. Timestamp advance per tick ≈ 1,411 → clock ≈ **2,822,400 Hz**. Both match the Serato numbers in
  `docs/research/2026-10-19-prior-art.md` §2.
- **Contradicts the hypothesis:** CC 6 is a plain 7-bit running tick counter (values 0..127 wrap
  continuously, 3600 is not a multiple of 128); there are no "28 sectors". The device also caps messages at
  ~1 kHz: at motor speed each message carries 2 ticks. So the decoder must unwrap mod 128 and accept
  multi-tick messages. Record this as a decision (M4-01 step 4).
- The timestamp wraps every 16384/2822400 = 5.8 ms, so below ~0.05× speed it cannot time ticks: use host
  arrival time there (Mixxx scripts have `Date.now()`; the 5 ms poll jitter is acceptable at that speed).
- Hold-phase anomaly: while the record was held, messages kept coming at ~16/s with CC 6 dithering ±1 and
  the timestamp decreasing by 1 per message. Not understood; M4-01 documents it, M5 asks the hardware.

### Where things live, what exists, what does not

- Exists: `tools/midi-send` (the gate, bash) + 8 tests in `tests/midi-send.test.mjs` (stubs amidi/aconnect/
  aplaymidi on PATH; copy that pattern for every tool that shells out). `package.json` runs
  `node --test "tests/**/*.test.mjs"`. Nothing else is built: no `mapping/`, no `tools/lib/`, no dev profile.
- Planned layout (keep it): `tools/<name>` executables (bash or `#!/usr/bin/env node` .mjs without
  extension), shared code in `tools/lib/*.mjs`, tests in `tests/*.test.mjs`, fixtures in `tests/fixtures/`,
  reviews in `.harness/runs/rane-one-mixxx-2026-10-19/reviews/`. Zero npm dependencies (D5).
- `mapping/rane-one-platter.js` is a plain script (no `require`/`import`/`export`). Node tests load it
  with `vm.runInNewContext(source, ctx)` and read `ctx.RaneOnePlatter`. Mixxx loads it by listing it first in
  the XML `<scriptfiles>`. Keep `engine`, `midi`, `print`, `console` out of it.
- Mixxx 2.5.6 Flatpak is at `~/.local/share/flatpak/app/org.mixxx.Mixxx/current/active/files/`. Its bundled
  `share/mixxx/controllers/` has `midi-components-0.0.js`, `engine-api.d.ts`, `midi-controller-api.d.ts`,
  `Numark-V7-scripts.js`, `Numark-NS7-scripts.js`, `Traktor-Kontrol-S4-MK3.js`: read these locally instead
  of fetching. `strings bin/mixxx.bin` contains `scratch_position`, `scratch2`, `scratch2_enable`,
  `rate_ratio`, `playposition`, `slip_enabled`: **2.5.6 has `scratch_position`** (spec §2 question answered
  on the binary; confirm behaviour in M7). GitHub raw is reachable (2.5 branch `eslint.config.cjs` and
  `res/controllers/*.d.ts` return 200). No eslint is installed; use `node --check` tonight, lint in M9.
- ALSA today: `Rane ONE` is seq client 24, rawmidi `hw:2,0,0`; `Midi Through` is client 14. Resolve by
  name every time. `tools/midi-send play` wants a numeric `client:port`; get it from `aconnect -o`.
- `.claude/settings.json` denies `aplaymidi`, `amidi -S`, `pactl set-default-*`, `wpctl set-default`, any
  write under the real profile, and `touch ~/.rane-armed`. `pactl load-module`/`unload-module`, `pw-play`,
  `flatpak ps`/`flatpak kill` and `pw-record` are not pre-allowed; auto mode decides per call. If a call is
  refused, write the command into the progress entry and mark the step skipped; do not work around it.
- The auto-mode classifier refused `grep` on `~/.var/app/org.mixxx.Mixxx/.mixxx/mixxx.cfg` even read-only
  (PII rule). M1 learns Mixxx's config format from the dev profile Mixxx writes itself (start once, stop, read
  `dev-profile/mixxx.cfg` and `dev-profile/controllers/`), not from the real profile.

### Dev Mixxx gotchas (M1-04, M1-05)

- **The system default sink is the Rane One** (`alsa_output.usb-Rane_Rane_ONE_A-00.analog-surround-40`).
  Unrouted audio goes to the controller's outputs. Never start Mixxx without the null sink up and the
  routing in place (`PULSE_SINK=mixxx-dev` via `flatpak run --env=`; inside the sandbox `PULSE_SERVER` is
  set and `libportaudio.so` is bundled, verified with `flatpak run --command=sh`). Verify with
  `pactl list sink-inputs` before trusting it. Alternative if PULSE_SINK is ignored: `pw-metadata`/
  `wpctl` to move the stream, or `PIPEWIRE_NODE`. Never `set-default`.
- The sandbox sees `~/.var/app/org.mixxx.Mixxx/` (listed `cache config data` from inside); `HOME` is the real
  home. `--settings-path ~/.var/app/org.mixxx.Mixxx/dev-profile/` should therefore work; M1-04 proves it.
- Mixxx shows blocking dialogs on a fresh profile (music-library chooser) and when the sound config is
  unusable (sound device error). Seed `mixxx.cfg` and `soundconfig.xml` before the first start; if a dialog
  blocks, the log still shows the device list: read it, stop Mixxx by instance id, fix the seed, retry.
- `flatpak ps` lists instances (a ProtonVPN instance is running; leave it). Stop only the instance id you
  started; `flatpak kill org.mixxx.Mixxx` would also kill a Mixxx Michael started. Write the id to
  `dev-profile/mixxx-dev.instance`.
- GUI needs `WAYLAND_DISPLAY`; this initializer had `wayland-1` and `DISPLAY=:1`. If a session lacks it,
  skip the live steps and say so.
- Keep the mapping output-free (no `<output>`, no `midi.send*`) and bind it only to `Midi Through Port-0`
  at night. The real Rane ONE port stays unbound in the dev profile until Michael says otherwise.
- `--controller-abort-on-warning` makes Mixxx exit on any script warning: a mapping that loads cleanly is the
  evidence. Replays into Midi Through at the capture's 1 kHz rate produce ~2000 log lines per second with
  `--controller-debug`; replay short ranges (`--from/--to`).

### Defaults I set (Michael can overturn any of them in INBOX.md)

- D9 (M1-01 records it): null sink `mixxx-dev`, routing by `PULSE_SINK`, instance-id tracking, night-time
  binding to Midi Through only.
- D10 (M2-01): capture reads the rawmidi device from Node with `process.hrtime` µs; arecordmidi +
  `tools/capture-convert` is the manual fallback (it is what produced the quick capture).
- D11 (M3-01): telemetry JSONL fields `t_us, ticks, timer, playposition, rate_ratio, mode`.
- D12 (M4-01): capture facts above override the Twelve/V7 hypothesis.
- D13 (M4-05): the speed filter chosen on synthetic data.

### Questions for Michael (answer in INBOX.md under `## Answers`)

1. In the quick capture, note 0 on channel 1 fired exactly when the motor started (19.2 s) and stopped
   (44.7 s). Was that the Play button? And during the 3 s hold, was your hand on the record? No touch
   message appeared, so I am assuming the One has no touch sensor on MIDI (hands are detected from motion).
2. Was the motor at 33⅓ (not 45) during the quick capture? The 3600 ticks/rev inference assumes 33⅓.
3. D1 hybrid playback stays the default (spec §7). Any objection to the D9 night rule that the dev Mixxx
   never binds the real Rane ONE port until you say so?
4. Morning job: run `HARDWARE-TESTS.md` (M2-07) when it exists; it is the §6 capture session, under 25 min,
   nothing is sent to the controller.
