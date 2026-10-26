# M6 review findings (M6-09, 2026-10-26)

Input: `reviews/M6.diff` (6889 lines), `git diff 6abb8c4 c9df998 -- . ':!.harness'`. 6abb8c4 is "HARNESS: after
M5-10 (passes=true)", c9df998 "HARNESS: after M6-08 (passes=true)". The CLAUDE.md, `.claude/settings.json` and
temp-dir cleanup hunks came in from `main` by merge and were only glanced at.

Reviewer: one Opus subagent. It read the diff from a copy in `/tmp/harness/rane-one-mixxx/rane-one-mixxx-2026-10-24/review-m6/`
and had read-only access to the repo. Its experiments ran on a `git archive c9df998` copy there (scratch scripts
c1–c6.mjs). It sent no MIDI and ran no Mixxx. In that copy, `node --test tests/mapping-*.test.mjs` gave 195 pass and 0 fail.

I re-ran each Important reproduction before fixing it. "Failing test first" means the test was added to
`tests/m6-review.test.mjs` and run red before the fix, and the red output is quoted. Tests and fixes are in one commit,
**d956007**. I checked Mixxx 2.5.6's own behaviour against its source at the `2.5.6` tag:
`src/engine/controls/loopingcontrol.cpp` `slotBeatLoopActivateRoll`/`DeactivateRoll`, and `ratecontrol.cpp`
`slotReverseRollActivate`.

## The five checks the feature names

| Check | Result | Evidence |
|---|---|---|
| `grep -c 'midi.send' mapping/Rane-One-scripts.js` | **0** (also after d956007) | `grep -n send` finds only comments. There is no `sendSysexMsg` and no `controller.`. Components' `send()` returns early without `this.midi`, and no component gets a `midi` option. The only `outKey` components, CueButton and SyncButton, pass `outConnect: false`. After init with DEBUG off there are 0 `makeConnection` calls. Replaying all 34 census takes (864,411 messages) plus shutdown gave 0 `midi` reads. |
| Every XML `<control>` function exists | **yes**, all 252 keys | After init, reviewer c1.mjs checked `typeof` of every key, with no duplicate (status, midino). The suite has "every <control> key resolves to a guarded function". |
| Every Pot has soft takeover | **yes**, 17 Pots | c2.mjs sent every Pot CC twice. The (group, key) set written by `setParameter` equals the set given `softTakeover(…, true)`: trim, EQ ×3, filter and volume ×2, the crossfader, headMix, headGain, and the two depth `mix` Pots. The absolute controls without it are deliberate: the pitch fader (D27), the strip (D34, a position), and Stop Time and torque (stored only). |
| Every handler path is guarded | **yes** | Every XML key's function has `.guarded`. Guarded too: `init`, `shutdown`, `build`, `setStart`, `heard`, `debugConnect`/`debugDisconnect` and the FxDepth timer. Not guarded: Components' SyncButton long-press timer (it only calls `engine.setValue`) and the debug-connection callbacks (`console.log` only), which the reviewer judged unable to throw. The one residual path: if a container fails to build, its XML keys resolve to `null.…` inside Mixxx's wrapper. That takes a JS bug, because nothing in construction calls `engine`. |
| XML `<info>` no longer says `M1 skeleton` | **yes** | `grep -rn skeleton mapping/` finds nothing. The description reads "Unfinished mapping … Work in progress (M6) …". |

## Critical

None.

## Important

| # | Finding | Outcome |
|---|---------|---------|
| I1 | **Overlapping Roll pads leave Slip latched on and turn it off mid-roll.** `slipBefore` was per pad. The second roll pad read `slip_enabled` after the first roll had already forced it to 1. Releasing the first pad then wrote its own 0 while the second still rolled, and releasing the second wrote back 1. A roll overlapping the censor had the same bug. Sliding across roll pads is the normal technique. The fake didn't model Mixxx's side effects, so the tests set state by hand, one pad at a time. | **Fixed** in d956007. The deck has one slip hold (`RaneOne.Deck.holdSlip`/`releaseSlip`) shared by every Roll pad and the censor. The first press keeps the deck's Slip and the last release writes it back. A release while another is still held puts back the 1 that Mixxx's censor release takes from a running roll. The fake now applies Mixxx 2.5.6's slip and reverse side effects inside `setValue`, from the source above. Tests written first: "I1: two overlapping Roll pads …", "I1: the censor let go during a roll …" and "I1: a roll let go during the censor …", each with Slip 0 and 1 before. Red: the three Slip-0 cases failed with `actual: 0, expected: 1` (Slip off mid-roll). |
| I2 | **The 14-bit rule wrote `rate` (and the strip's `playposition`) twice per pair.** The CC 9 alone applied `(MSB << 7) + 64` and its CC 41, at the same t_us, applied the exact value. A slow move near centre therefore pulsed `rate` by up to 0.0078 (≈ 0.39 % speed) on every message, and a strip pair seeked twice. The M6-04 discovery had raised the same point. | **Fixed** in d956007: the MSB is stored and the LSB applies. A CC 9 whose LSB was lost applies at `+ 64` when the next CC 9 comes. A CC 41 with no new CC 9 applies with the last MSB, and a CC 41 before any CC 9 is still dropped. Measured on the captures: 0 lone CC 9/43 in 16,479 pairs (01, 03, 05, 23, 24, 26), with the LSB at most 190 µs after its MSB. So the only cost is a lost LSB, applied one message late, and none was seen. Tests written first: "I2: a CC 9 + CC 41 pair writes rate once …", "I2: replaying take 23 writes [Channel1],rate once per CC 9/41 pair (4,476)", "I2: a CC 9 whose CC 41 never came …" and "I2: a strip pair with Shift held while playing seeks once". Red: `actual: 2, expected: 1`, `actual: 8952, expected: 4476`, `[0.0078…]` vs `[]`, and `[0.50394, 0.50003]` vs `[0.50003]`. `tests/mapping-mixer.test.mjs`'s two old-rule tests were rewritten to the new rule, and the plan's § Script structure rule was updated in place. |
| I3 | **The fake accepted any control name, so a misspelled Mixxx control couldn't fail a test.** Real 2.5 warns on an unknown control, and the dev run aborts on that warning. The reviewer found no wrong name. | **Fixed** in d956007. `tests/fixtures/mixxx-2.5.6-connected-keys.txt` holds the 214 (group, key) that `RaneOne.init` connects with DEBUG on and 8 samplers, at the code M6-07 ran in the dev Mixxx under `--controller-abort-on-warning` without an abort. The mapping is unchanged from 8c7b29f to c9df998, and the list is byte-identical at c9df998 and after d956007. The test "I3: every control the mapping connects, reads or writes …" fails on any key outside that list. It allows 9 read-only keys, each checked by name in 2.5.6's source: `rate_dir` and `rateRange` (ratecontrol.cpp), `loop_enabled` (loopingcontrol.cpp), `playposition` (enginebuffer.cpp) and `[App],num_samplers` (playermanager.cpp). The test exercises 8 census takes, every pad of every mode on both layers, and the auto loop. There was no bug to turn red, because no wrong name exists. Its first run failed only on the test's own setup (samplers set after the debug init). The mutation check: `loop_halve` → `loop_halv` failed it with `'[Channel1],loop_halv'`, and the typo was reverted. |

## Minor

| # | Finding | Outcome |
|---|---------|---------|
| M1 | Every init muted both channels (D35), so a hot reload mid-set silenced a playing deck until its fader moved. | **Fixed** in d956007: `setStart` zeroes `volume` only where `play` is 0. D35 updated in place. Test first: "M1: init sets volume 0 only on a deck that isn't playing". Red: `[0]` vs `[]`. |
| M2 | The plan named `RaneOne.noop` for the no-op rows, but the code uses `RaneOne.Counted` components and no XML key reached `RaneOne.noop`. | **Fixed**: the plan says `RaneOne.Counted`, and `RaneOne.noop` is deleted (S1). |
| M3 | `docs/mapping-reference.md` said the pitch fader matches the motor "whatever `rateRange` is", but under 0.5 the ends clamp. | **Fixed**: "at any `rateRange` of 0.5 or more (under 0.5 the ends clamp and a warning is logged once)". |
| M4 | The plan said `guardInputs` walks with `forEachComponent`. The code uses `RaneOne.forEachObject`, which also follows layers, `pots` and back-references. | **Fixed** in the plan's § Script structure. |
| M5 | Pitch bend keying (by status alone in the fake, `<midino>0x00</midino>` in the XML) is UNVERIFIED in both places, so the platter-count tests may pass whatever 2.5 does. | **No change**: both are already marked UNVERIFIED. M7 must settle it before relying on them (discovery for M7). |

## Simplifications

| # | Pass | Outcome |
|---|------|---------|
| S1 | `RaneOne.noop` was dead (no XML key reached it). | **Applied**: deleted, along with its mention in `RaneOne.heard`'s comment. |
| S2 | `Store` and `MotorOffButton` subclassed `Counted`, and `Paddle` subclassed `StateButton`, but all three replaced `input` entirely. | **Applied**: `Store` and `MotorOffButton` subclass `Component`. `Paddle` keeps `StateButton` and calls its `input` after setting `on`. |
| S3 | `RaneOne.shift.input` re-runs `guardInputs` on every Shift message, though nothing in `sameNote` swaps its input today. | **Kept** as a safeguard: Components' `shift()` may swap inputs, and the code comment at `guardInputs` already says so. |
| S4 | `releaseAll` passed `obj.note`, which only `Layered` has. | **Applied**: it passes `undefined`. The release path reads no number. |

## Also verified (reviewer)

- D27 direction: with `rate_dir` −1 the fader top gives `rate` −1 (rate_ratio 1.5) and the bottom gives +1 (0.5).
- No stuck Shift states:
  - A pitch bend held across a Shift press and release ends on `rate_temp_up` 0.
  - Shift+Cue with Shift let go first, then released on note 1, gives `start` 1/0.
  - Shift+pad released on the unshifted note gives `hotcue_1_clear` 1/0.
- Capture 02's paddle-on order is `BF0400`, then the `980000` burst, then the paddle. The FxDepth hold/drop rule matches it.
- Replaying all 34 takes leaves 45 unhandled messages, all of them power-on dump CCs in take 01.
