M5-08 review findings

1. Important: tests/platter-state.test.mjs:1004 (core: mapping/rane-one-platter.js:919). The D29 mirror tests never reach the reverse D24 branch where T7 fires on the untrusted sample itself (`absorb = Math.max(0, advance - d * (ticks - lastTicks))`). How I checked: mutation runs on a scratch copy (/tmp/.../review/wt), running `node --test --test-name-pattern 'D29|D24|census|M5-08'` on platter-state and platter-run tests. Dropping `d *` there gives "pass 23, fail 0", even though in reverse it over-absorbs by |delta| and the position jumps. The forward branch is covered: setting `absorb = 0` fails "D24 for every stall length". Fix: also run that stall-length sweep through `assertMirrored`. A second survivor: deriving `d`/`dir` from `lastE` in place of `lastPlay` (line 901) also gives 23/0. No test feeds a playRatio whose sign differs from e, so nothing pins the "clock's direction" choice in D29.

2. Minor: docs/decisions.md:414. The D29 "Risk" sentence says the problem is a direction change "while the platter is in control". In fact the common case is the clock in control: with e going +1 to -1 in `motor_at_speed`, T1 hands over to the platter on the same update (no TAKEOVER_MS hold) and labels it `backspin`. How I checked: /tmp/.../review/flip.mjs printed `1501 ms backspin platter r 1.000 e -1` on the flip update, then scratching, held, scratching, settling, and `2249 ms motor_at_speed`. Also, eRoseUs is not re-armed on a direct sign flip (line 858). A mutation that re-arms it passes every test, so this behaviour is untested either way. Neither path is a <20 ms glitch, but the risk text should say this.

3. Minor: docs/research/2026-10-24-census-analysis.md, three small inaccuracies.
   - :821 says "15 read as a 63 s backspin". `tools/platter-run 15-motor-d1-33.jsonl` (default +1) gives scratching at 2.781 s, then backspin to the end at 65.000 s: 62.2 s.
   - :887 says "2.63× (29) outside the first ms". 18's 3.76× is at 0.0012 s and 32's 5.31× at 0.0010 s (platter-run-all --json maxShrinkUs). The prose below says "first 1.2 ms", and the test uses <1.5 ms.
   - :809 says platter-run-all.test "checks the two give the same states". It re-runs only 15, 24 and 29, not all 24 takes.

4. Minor: tools/census:128-130. `--diff` without `--out` still does `stdout.write` then `process.exit(0)`, the same truncation pattern this diff fixes elsewhere. Output today is 23,085 bytes, the same through a pipe and to a file, so it is latent. It is not one of the touched tools. The fix is complete in platter-run, take-events and analyze-platter: piped `--json` gave 430,967 bytes (24) and 10,326,308 bytes (take-events 15).

5. Minor: tools/lib/platter-run-cli.mjs:9. The comment says parseRunArgs may return `{ error: null }` "for the bare usage". It never does: a missing file comes back as `file: null`. Otherwise the parser behaves the same as the old inline one: same messages, same order, exit 2.

Checked, no finding:
- Forward behaviour (e >= 0) is unchanged. JSON from `tools/platter-run --json` is byte-identical between HEAD's core and the new core on all 22 non-reversed takes. `npm test` passes 1049, fails 0.
- Every row of § Platter runs reproduces from `tools/platter-run-all`, and so does the WRAP_JUMP table. Spot-checked rows 07, 08, 09, 10, 11, 12, 14, 15, 17, 18, 19, 21, 24, 25, 29, 30, 31, 32, 33 and 34, including entry ratios, directions and the T8 spin-down durations. Also confirmed: 08 1.40×/1.29×, 29 2.63×/1.34×, 32 1.48× at 3.387 s, 17 21.44× at 0.0003 s, and 31's 2.44× at 9.235 s with the backlog stripped. 15's and 21's untrusted samples are host gaps (1.790 s and 2.127 s after the last sample at 0.000 s).
- The --expected choices hold. 17, 18, 19, 31, 32 and 33 have about 228 CC 6 messages in their first 100 ms with no note-on before them, and 17's ticks fall. The press times are note-ons: 15 at 1.773677, 19 at 7.042559, 33 at 8.912328.
- Each of the five M5-08 steps is met as written.
- The core stays pure: no engine/midi/print, and update() is wrapped in try.

## Outcome (M5-08 session)

1. Fixed: new test "D29: the mirror holds for every stall length, 40-150 ms, …" (runs the D24 sweep through
   assertMirrored); dropping `d *` from the untrusted-sample absorb now fails it. The `lastPlay`-vs-`lastE` choice
   is left unpinned and stated in D29 (they differ only if the glue makes them).
2. Fixed: D29's risk text now describes the +1 → −1 flip at speed (T1 backspin at once, back at speed ~0.75 s
   later, SPINUP_MS not re-armed, unpinned).
3. Fixed: "62.2 s" from 2.781 s; "outside the first 1.2 ms"; the run-all test re-runs 15, 24 and 29 alone.
4. Fixed: tools/census no longer calls process.exit after writing the diff to stdout.
5. Fixed: the parseRunArgs comment.
