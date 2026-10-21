# M3 review findings (M3-06, 2026-10-21)

Input: `reviews/M3.diff` (3311 lines): part 1 is `git show 9451137 -- docs tools/mixxx-dev` (M3-01, the plan,
committed before M2 was done), part 2 is `git diff cadb770..2b59a39 -- tools tests docs README.md package.json`
(cadb770 is "HARNESS: M2 verified"; 2b59a39 is the last M3-05 commit). Reviewer: one Opus subagent that read the
diff from a copy in the scratch dir, read-only, and ran its reproductions under
`/tmp/harness/rane-one-mixxx/rane-one-mixxx-2026-10-19/review-m3/`. No MIDI was sent, no Mixxx was run, nothing
was played or recorded. The per-feature reviews (M3-02..M3-05) had already fixed their own findings; this pass
looked across M3.

"Failing test first" means the test was added and run red before the fix (the red result is quoted), then the fix
and the test were committed together in the named commit.

## Critical

| # | Finding | Outcome |
|---|---------|---------|
| 1 | `tools/lib/wow-flutter.mjs` step 5: any cycle more than 5 % off the median period was a "dropout" even at full level, so a speed excursion was cut out of the statistics. The worse the glitch, the better the reading: 4 % for 30 ms read `peak 3.9446 %`, but 8 % for 50 ms and 20 % for 100 ms read `peak 0.0000 %  dropouts 1`, exit 0. A motor hiccup would pass spec §3. I reproduced it before fixing it. | **Fixed** in 0d6f840: a run of ≥ 3 bad cycles that are all at full level and all off the same way is a speed change (flutter), not excluded. A gap, or a dropped or repeated 256-sample block, gives 1–2 odd cycles and stays a dropout (checked: both `dropouts 1`, peak 0.0000 %). The tool now warns on stderr whenever `dropouts > 0`; D12 says a §3 measurement needs `dropouts 0`. After: 8 %/50 ms reads 7.8065 %, 20 %/100 ms reads 18.9018 %, both `dropouts 0`. Tests first: "a speed step of +8 % for 50 ms or -5.5 % for 30 ms at full level is flutter…" (red: `actual: 1, expected: 0` dropouts), "6 % flutter at 4 Hz reads about 6 %, not as dropouts" (red: `actual: 80, expected: 0`), and the CLI warning in "--channel picks the channel; the dropout file reports dropouts 1" (red: stderr `''`). |

## Important

| # | Finding | Outcome |
|---|---------|---------|
| 2 | `tools/lib/wow-flutter.mjs` `EDGE_S = 1`: the zero-phase high-pass rings for about 1 s after the padded edges, so slow wow read high. On a 30 s tone, 0.1 % at 0.5 Hz read 0.1055 % (the worst window right at 1.0 s). Once-per-turn wow at 33⅓ rpm is 0.556 Hz, so a good platter near the limit would fail. | **Fixed** in 0d6f840: the edge is 2 s, shortened to no less than 1 s, so a tone keeps a whole window plus one hop (a 5 s tone uses 1.9 s, and `make-test-audio tone --seconds 5` still measures). Tests first: "0.1 % wow at 0.500 Hz / 0.556 Hz over 30 s is not over-read at the edges: peak 0.095–0.100 %", three phases each (red: `peak % 0.1054882044088429 not in [0.095, 0.1]` and `0.1083219583421298`). All M3-03 tolerance tests are unchanged and green. |

## Minor

| # | Finding | Outcome |
|---|---------|---------|
| 3 | `tools/lib/drift.mjs` `parseTelemetry`: backward `t_us` was detected across decks and the shift carried forward. Deck 2 stamped 1 ms before deck 1 gave 5992 warnings and stretched deck 1 (span 306.00 s, slope 1.961 instead of 300.00 / 2.000). | **Fixed** in 3b04e6b: the clock is checked per deck. Test first: "deck 2 lines stamped just before deck 1's are not backsteps…" was red. |
| 4 | `parseRpm("33.0")` returned 33 while `"33"` returned 100/3: 1 % of false drift. | **Fixed** in 3b04e6b (`33.0`, `33.00`), and in 7a4f64c (`33.`, once `--rpm` takes the shared DECIMAL). Test first: the parseRpm spellings test was red. |
| 5 | `tools/record-output`: an empty `RECORD_OUTPUT_GRACE_MS` became 0 ms of grace, and `Infinity` or `3000000000` overflowed `setTimeout` to 1 ms, so every recording timed out. | **Fixed** in 3b04e6b: it must be whole milliseconds from 0 to 600000, checked before pw-record runs. Test first: "RECORD_OUTPUT_GRACE_MS must be whole milliseconds…" was red. |
| 6 | wow-flutter is unweighted up to half the cycle rate (500 Hz), so broadband noise uses up the budget: SNR 70 dB reads 0.0185 %, SNR 60 dB 0.0578 % on a perfect tone. | **Deferred, documented here.** The null-sink path is digital (no noise), so it is harmless for M7. An analog loopback in M8 would need a 200 Hz low-pass (the usual flutter band). That is Michael's call with D12. |

## Duplication

| # | Finding | Outcome |
|---|---------|---------|
| 7 | `writeWav` (wav.mjs) and `writeSmfFile` (smf.mjs) had the same temp-file-and-rename body. | **Fixed** in 7a4f64c: `tools/lib/atomic-write.mjs` `writeFileAtomic`. |
| 8 | `median` was identical in wow-flutter.mjs and drift.mjs. | **Fixed** in 7a4f64c: `tools/lib/numbers.mjs`. |
| 9 | Each of the 4 M3 tools (and the older `replay` and `census`) has its own usage, `--help`, seen-twice and "needs a value" scaffolding. | **Deferred.** A shared `tools/lib/cli.mjs` would touch 6 tools and their 100+ usage tests, which is out of proportion for a review pass. It is recorded for M9's cleanup. |
| 10 | Four decimal regexes behaved differently: `--track-seconds 5.` was accepted, but `--rpm 45.` was refused. | **Fixed** in 7a4f64c: `DECIMAL` is in numbers.mjs and used by drift, wow-flutter and `parseRpm`. make-test-audio's signed `NUMBER` and record-output's 3-decimal `--seconds` stay deliberately different. |

## Simplification (the wow-flutter tolerance tests pass after each change)

| # | Finding | Outcome |
|---|---------|---------|
| 11 | `stats(from, to)` shadowed the outer `from`/`to` that `used()` reads. | **Fixed** in 7a4f64c: the parameters are `ws`/`we`. |
| 12 | Four `splice` calls trimmed the tone. | **Fixed** in 7a4f64c: two `slice`s. |
| 13 | Check finiteness before building `result`. | No change: it is one line either way, and the check already runs before anything is returned. |

## Docs

| # | Finding | Outcome |
|---|---------|---------|
| 14 | spec §3 named no tools. "≤ 0.1 %" didn't say it is the peak, and "< 10 ms" didn't say max or final. | **Fixed** in 2136806: each row names its tool (`make-test-audio` + `record-output` + `wow-flutter`; `drift` on D11 telemetry), says "peak, `dropouts 0`" and "max \|drift\|", and says that return-to-mark and switch-over have no M3 tool. |
| 15 | D12's "Dropouts are counted separately" hid #1. | **Fixed** in 2136806: D12 now records the speed-run rule, the 2 s edges and "needs `dropouts 0`". |
| 16 | The plan's odd reflection, its `.monitor` argv and blocklist, the `null-sink` stub, `[--csv] [--json]` and "under-reported peak" were superseded only under "As built". | **Fixed** in 2136806: each is marked inline. |
| 17 | README didn't say that dropouts invalidate the peak. | **Fixed** in 2136806: "dropouts (need 0)". |

Tests: 611 → 617 (`check.sh`). `check.sh` is green.
