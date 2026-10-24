# M4 review findings (M4-08, 2026-10-21)

Input: `reviews/M4.diff` (5635 lines), `git diff f837cbf..4fb6aca` with the harness files left out. f837cbf is
"HARNESS: M3 verified" and 4fb6aca is the M4-07 commit.

Reviewer: one Opus subagent. It read the diff from a copy in the scratch dir and had read-only access to the repo.
It ran its reproductions under `/tmp/harness/rane-one-mixxx/rane-one-mixxx-2026-10-19/review-m4/`. No MIDI was
sent and no Mixxx was run. The per-feature reviews (M4-01..M4-07) had already fixed their own findings, so this
pass looked across M4. The reviewer wrapped up early at my request: it did not audit every test file's assertions
or check the analysis doc's tables line by line.

I re-ran each Important reproduction before fixing it, and the numbers below are mine.

"Failing test first" means the test was added and run red before the fix (the red result is quoted below). The
fix and the test were then committed together in the named commit.

## Critical

None. 300 random streams of 3000 messages each (random bytes, gaps up to 200 ms, `expectedRatio` toggling) went
through all three stages. None threw, and none gave a non-finite ratio or position. Handback position is exact.

## Important

| # | Finding | Outcome |
|---|---------|---------|
| 1 | **A timestamp wrap behind a run of lost messages was timed.** In the decoder (`advanceTimer`), the 14-bit timestamp wraps after 5.8 ms of device time, but a delta was only distrusted after a host gap over `TIMER_GAP_MAX_US` (20 ms). Take synth constant33 and drop 5, 6, 8, 12 or 19 consecutive CC+PB pairs at 1.0 s. The first sample after the gap read **29.76, 5.73, 2.76, 9.23 and 7.67×** respectively, all `timed`, with `untrustedTimers` 0. `TAKEOVER_MS` hides this in `motor_at_speed`, but in `settling` (T14) or under platter control it is a 5–30× spike. | **Fixed** in d15b323. After a host gap of at least half the timer span (2.9 ms), a delta whose per-tick device interval is `WRAP_JUMP` (1.8) times shorter than the last timed delta's, or more, counts as `untrusted`. A wrap always shrinks the interval at least 2×. In the capture it never shrinks more than 1.40× from one timed delta to the next (I measured all 29,037 consecutive pairs), so the capture gets no new untrusted sample and its M4-07 timeline is unchanged. `WRAP_JUMP` is a new constant (header and plan table, UNVERIFIED in fast scratches). Tests written first: "a timestamp wrap hidden by a run of lost pairs under TIMER_GAP_MAX_US is untrusted" (red: `sample.untrusted` undefined), "a run of 5-19 lost pairs … leaves constant33 within 1.00 ± 0.05" (red: `5 lost: untrustedTimers 0`), and a guard: a real 1.4× speed-up or 3× slow-down after a 7 ms gap stays timed. After the fix all five read 1.00. |
| 2 | **The plan told M7 to time heartbeats on the decoder's absorbed clock (D21), but the decoder had no way to return it.** Scenario: motor off, a hand turn at 0.5, the wall clock steps back 1 s at 1.5 s, and the hand stops dead at 2.0 s. The ratio stayed 0.500 for about 1.1 s after the stop, the estimator clamped 75 heartbeats, and the state machine counted 75 malformed updates. | **Fixed** in 6f4811e. New `decoder.now(hostTimeUs)` returns the host time on the decoder's clock (or null), and `runCore` times its heartbeats with it. The plan's API line and its "For M7" note say so. Tests written first: "now(hostTimeUs) returns the absorbed host clock" (red: `TypeError: dec.now is not a function`), and "runCore: a wall clock stepping back 1 s doesn't hold the ratio after a dead stop" (red: `ratio 0.5000708717221828 at 1800000 µs`). |
| 3 | **D24's burst window was `PAIR_WINDOW_US` (2 ms of host time).** A stall's backlog handed to the script one message after another lost most of the fix. At 50 µs per message on a 1 ms clock, the track skipped **100 ticks (50 ms)** after an 80, 120 or 200 ms stall. At 100 µs per message it skipped 130 ticks (65 ms), close to the 58–81 ms D24 was built to remove. | **Fixed** in 92e0ecb. The window is its own constant, `BURST_MS` (20 ms, **UNVERIFIED** until M7 sees how Mixxx delivers a backlog). Now 20, 50 and 100 µs per message all skip 0 at 80/120/200 ms. The reviewer's two stall sweeps (20–300 ms, 158 runs, re-run after the fix) stay within −2..+1 tick. A hand that slowed during the stall still moves the track, after at most `BURST_MS`. D24 is amended with the numbers. Test written first: "D24 with a spread-out backlog: a stall's burst arriving over 8-12 ms still doesn't skip the track" (red: `100.00000000000091 ticks off` at 80 ms). |

## Minor

| # | Finding | Outcome |
|---|---------|---------|
| 4 | The three factories read separate configs, but `TIMER_HZ`, `TIMER_MARKER_MIN`, `TIMER_GAP_MAX_US` (decoder and estimator) and `STALL_MS`, `TICKS_PER_REV`, `rpm` (estimator and state machine) must agree. | **Documented** in 1fbac8d: the core's header says the glue passes one config object to all three. A `createDeck(config)` wrapper is left for M7, which writes the glue. |
| 5 | With the motor off, a creep under `MOVE_RATIO` never moves the track. At 0.02 for 5 s, 200 ticks of record give 0 ticks of track. At 0.04 the core takes over. | **Documented** in 1fbac8d, in the plan's `MOVE_RATIO` row. It depends on M5 check 3 (is the ±1 dither real motion?). |
| 6 | `tools/lib/platter-analysis.mjs` counted only 16383 as a marker. The core and the synth use 16382 too, so `analyze-platter` added each −2 as 16,382 counts of time (38–41 s printed "timer +16382"). | **Fixed** in df968c0: `TIMER_MARKER_MIN` = 16382, and the line now prints `markers (-1/-2)`. The analysis document's Output block was regenerated. No prose number changed: the 20–36 s figures have no marker. Test written first: "a -2 delta (16382 unsigned) is a marker too" (red: markers 2, not 3). |
| 7 | Nothing guarded the core's syntax level for QJSEngine. | **Fixed** in 1fbac8d: `tests/platter-pure.test.mjs` refuses `?.`, `??`, `class`, private fields, BigInt literals, `.at(` and `async`/`await` in the core's code. The core already had none, so this is a guard, not a fix. ESLint against Mixxx's config is M9. |

## Docs

| # | Finding | Outcome |
|---|---------|---------|
| 8 | D20 said a host-side stall "can't take control from the clock", but from about 60 ms one does. The plan's "Stalls vs a stopped hand" still said the burst "drives position", which D24 changed. | **Fixed** in 1fbac8d. Both now point to D24. |
| 9 | The plan's `update(…)` signature lacked `untrusted`. | **Fixed** in 1fbac8d. |
| 10 | The decoder's channel defaults (0xB0, 6, 0xE0) were not cited in the header. The ring-compaction 512 had no comment, and `numbers.mjs` still said "M3 tools". | **Fixed** in 1fbac8d. Deck 2's channel is marked UNVERIFIED. |

## Duplication

| # | Finding | Outcome |
|---|---------|---------|
| 11 | `platter-run`, `analyze-platter` and `synth-platter` each copy the CLI scaffolding (usage, `--help`, seen-twice, `readJsonl` errors). Six older tools do too. | **Deferred** to M9's cleanup, as M3-findings #9 did: a shared `tools/lib/cli.mjs` touches nine tools and 100+ usage tests. |
| 12 | `plain` (×3) and the capture path (×3) were repeated across the platter tests. | **Fixed** in 6af27c6: both now come from `tests/helpers/load-platter.mjs`. The constants copied into `synth-platter.mjs` stay on purpose: the synth is an independent model of the device. |

Also in this feature (step 2), commit 629a738. The core's header now lists every `DEFAULTS` constant with its
capture citation or UNVERIFIED, one per line. `tests/platter-pure.test.mjs` fails if a key is missing or uncited
(checked red against the old header: `HOST_WINDOW_MS`, `TAKEOVER_TOL`, `STALL_MS` and `RETARGET_MS` were missing).

Tests: 853 → see the progress entry for the final count (`check.sh`).
