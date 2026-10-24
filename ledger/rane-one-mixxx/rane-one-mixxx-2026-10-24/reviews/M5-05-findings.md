# M5-05 review (Opus, 2026-10-24): findings and what was done

About 40 doc numbers re-ran exactly (crossings, backspin states, hold statistics, stopped tails, press times, stray pairs). All nine steps met.

## Important (all fixed)
1. `tools/platter-windows --json` was cut at 64 KiB through a pipe (`process.exit` after `write`). Fixed: no exit after a write; test pipes a ~1 MB JSON through `cat`.
2. Hold: "both decks creep in the motor's direction": only 31 does (+17 in 5 s); 17 nets −4 / 0. Fixed; the cause is marked UNVERIFIED.
3. Deck 2 sag list incomplete (stopped at 49.8 s). Fixed: all 27 windows, plus 24/33/34's dips.
4. "Deck 1 doesn't sag" / "within 0.32 %" came from reverse take 15 alone; forward 25 dips 0.64 %, 23 0.40 %. Fixed in § Motor, For M5-07, the plan.

## Minor
- `crossings()` ignored `--to`: now bounded by the span (test added); help says so.
- Start backlog inflates the first window's net ticks/host ratio: documented in `--help` (`--from 0.001`).
- Span edges (last message excluded, `--to` clamped): documented in `--help`. `--from` past the end prints an empty span: left.
- State column uses press-toggled expectedRatio: documented in `--help`; the doc takes states from `platter-run --expected`.
- Stop Time in 23/25 inferred: now cites 61 at the end of 20 (31.875 s) and 60 from the power-on dump.
- Return sweeps of 20/34 added. "Torque HIGH never captured" → "never against a hand".
- Shift+Slip labels and "what the One sends for motor-off mode": now "toggled with the motors stopped", note 10 as the toggle rests on Michael's account (UNVERIFIED).
- Causes without UNVERIFIED (35 ppm timer difference, roll-back cause, gentler reverse spin-up): reworded / marked.
- "0 control flips" → "no flip under 20 ms"; 18's states before the backspin added; gap share 41 %/48 %; take 26's lone pair wording.
