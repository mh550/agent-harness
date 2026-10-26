<!-- harness: rendered from entries.jsonl after every session; edits here are overwritten -->
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

### 2026-10-26 05:28 · verify M6 · passes

All 9 M6 features hold. Suite 1262/1262. Independently replayed census takes 03,04,06,27,28 into dev Mixxx: init clean, no controller warnings, 3303 control log lines, null sink only, Mixxx stopped. 0 midi.send. Some doc tables were spot-checked, not audited cell by cell.

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| M6-01 | 1 | grep -n ^## docs/plans/2026-10-24-M6-mapping.md | sections Control table, Script structure, Test harness, Replay check, Out of scope all present | yes |
| M6-01 | 2 | read plan Control table; wc reference/rane-one-mk1-controls.csv | Control table section lines 19-202 (≈145 CSV rows covered); not row-by-row audited, but the pad/mixer/deck/FX tests assert its controls | yes |
| M6-01 | 3 | read plan Script structure; grep midi.send in script | section present; I2 14-bit rule updated in place; guard on every XML key (m6-review suite green); 0 midi.send | yes |
| M6-01 | 4 | read tests/helpers/fake-mixxx.mjs and tests/mapping-harness.test.mjs; npm test --silent | harness tests run (0 skipped, so Flatpak resources present); fake midi send throws | yes |
| M6-01 | 5 | read plan Replay check; re-ran that sequence myself | install-mapping --debug, null-sink up, mixxx-dev start, replay, log grep, stop all worked as described | yes |
| M6-01 | 6 | grep D30-D35 in docs/decisions.md | D30-D35 each *default* and each has a To undo line | yes |
| M6-01 | 7 | npm test --silent | 1262/1262 pass, 0 fail, 0 skipped | yes |
| M6-02 | 1 | tests/mapping-harness.test.mjs in npm test --silent | 1262/1262 pass, 0 fail, 0 skipped; includes midi.send throws test | yes |
| M6-02 | 2 | same suite | components.Button/Pot tests green in the fake; 0 skipped | yes |
| M6-02 | 3 | same suite; Flatpak present | skip path not exercised (resources present, 0 skipped); header comment not re-read in full | yes |
| M6-02 | 4 | tests/mapping-xml.test.mjs in npm test --silent | green with 0 todo (the todo assertion was promoted by M6-06) | yes |
| M6-02 | 5 | npm test --silent | 1262/1262 pass, 0 fail, 0 skipped | yes |
| M6-03 | 1 | tests/mapping-deck.test.mjs in npm test --silent | 1262/1262 pass, 0 fail, 0 skipped | yes |
| M6-03 | 2 | mapping-deck + m6-review tests | XML has script-binding entries; throwing-engine handler test green | yes |
| M6-03 | 3 | tests/mapping-fx.test.mjs replay table in npm test --silent; replayed takes 03,04,06,27,28 into real Mixxx | all exit 0; 0 unhandled in suite | yes |
| M6-03 | 4 | node --check mapping/Rane-One-scripts.js; grep -c midi.send | syntax ok; 0 | yes |
| M6-03 | 5 | npm test --silent | 1262/1262 pass, 0 fail, 0 skipped | yes |
| M6-04 | 1 | tests/mapping-mixer.test.mjs and m6-review I2 tests in npm test --silent | 1262/1262 pass, 0 fail, 0 skipped; take 23 rate written once per pair (4476) | yes |
| M6-04 | 2 | mapping-mixer tests; review finding table | 17 Pots all with softTakeover, encoders tested; suite green | yes |
| M6-04 | 3 | replay of take 02 in mixxx-replay.md and suite | M6-replay.md take 02: 23 controls changed, 0 gaps; suite green | yes |
| M6-04 | 4 | tests/mapping-xml.test.mjs | duplicate-entry test and both 14-bit bytes covered; green | yes |
| M6-04 | 5 | npm test --silent | 1262/1262 pass, 0 fail, 0 skipped | yes |
| M6-05 | 1 | tests/mapping-pads.test.mjs in npm test --silent | 1262/1262 pass, 0 fail, 0 skipped | yes |
| M6-05 | 2 | suite replay of takes 04/06 | 0 thrown, none unhandled; real Mixxx replay of 04,06,27,28 exit 0, hotcue_N_activate lines logged | yes |
| M6-05 | 3 | grep midi.send; read XML | 0 midi.send; per-pad-note XML entries | yes |
| M6-05 | 4 | grep decisions D30 and pad code comment | D30 cites mode table; comment present in RaneOne.Pad (not re-read line by line) | yes |
| M6-05 | 5 | npm test --silent | 1262/1262 pass, 0 fail, 0 skipped | yes |
| M6-06 | 1 | tests/mapping-fx.test.mjs in npm test --silent | 1262/1262 pass, 0 fail, 0 skipped | yes |
| M6-06 | 2 | tests/mapping-xml.test.mjs | platter placeholders and Counted no-ops asserted; green (plan names RaneOne.Counted not noop, review M2 recorded) | yes |
| M6-06 | 3 | suite: todo assertion and census replay table | 0 todo, 0 unhandled, 0 exceptions in suite | yes |
| M6-06 | 4 | mapping-xml test UNVERIFIED comment assertion | green | yes |
| M6-06 | 5 | npm test --silent | 1262/1262 pass, 0 fail, 0 skipped | yes |
| M6-07 | 1 | tools/install-mapping --debug; tools/mixxx-dev start (WAYLAND_DISPLAY=wayland-1) | started; RaneOne: init logged once; 0 Warning [Controller / Critical / exception lines | yes |
| M6-07 | 2 | tools/replay --to-port Midi Through --speed 8 on takes 03,04,06,27,28 (02,05 not re-run) | all exit 0; 3303 RaneOne control log lines, 164 distinct controls | yes |
| M6-07 | 3 | read checks/M6-replay.md | per-take tables, sample lines and gap columns present for all 7 takes (0 gaps) | yes |
| M6-07 | 4 | tools/mixxx-dev stop; status; pactl list sink-inputs | stopped; mixxx-dev stream on sink 475 (mixxx-dev) only; M6-replay.md quotes same | yes |
| M6-07 | 5 | npm test --silent | 1262/1262 pass, 0 fail, 0 skipped | yes |
| M6-08 | 1 | read docs/mapping-reference.md existence via spec/README links | file exists, linked from README; platter-not-wired noted in README (tables not audited cell by cell) | yes |
| M6-08 | 2 | sed HARDWARE-TESTS.md Round 2/3 | Round 2 ≈14 min (<15); Round 3 9.5 min splits the overflow | yes |
| M6-08 | 3 | grep mapping-reference README.md | linked with M6 status line | yes |
| M6-08 | 4 | npm test --silent | 1262/1262 pass, 0 fail, 0 skipped | yes |
| M6-09 | 1 | ls reviews/ | M6.diff and M6-findings.md exist; I1-I3 fixed in d956007 with red outputs quoted; simplifications S1,S2,S4 listed | yes |
| M6-09 | 2 | read M6-findings.md; grep midi.send; grep skeleton | findings file states all five checks; midi.send 0; no M1 skeleton in mapping/ | yes |
| M6-09 | 3 | grep M6 docs/spec.md; D30-D35 | spec marks M6 done 2026-10-26 with plan/findings/replay links; each decision has To undo | yes |
| M6-09 | 4 | npm test --silent | 1262/1262 pass, 0 fail, 0 skipped | yes |

- *052454-verify-M6 · claude-sonnet-5-5*

### 2026-10-26 05:24 · M6-09 · passes

M6 reviewed (Opus, reviews/M6.diff): 0 Critical, 3 Important fixed test-first in d956007: one slip hold per deck for overlapping rolls/censor, 14-bit MSB stores and LSB applies (one rate write per pair), control names pinned to M6-07's dev run. Minor M1 (re-init keeps a playing deck's volume), docs M2-M4, simplifications S1/S2/S4. Spec §5 M6 done.

- **Files:** mapping/Rane-One-scripts.js, tests/m6-review.test.mjs, tests/helpers/fake-mixxx.mjs, tests/mapping-mixer.test.mjs, tests/fixtures/mixxx-2.5.6-connected-keys.txt, tests/fixtures/README.md, docs/spec.md, docs/decisions.md, docs/plans/2026-10-24-M6-mapping.md, docs/mapping-reference.md, .harness/runs/rane-one-mixxx-2026-10-24/reviews/M6.diff, .harness/runs/rane-one-mixxx-2026-10-24/reviews/M6-findings.md
- **Verified:** check.sh green, 1262 tests; tests/m6-review.test.mjs 12 tests, I1/I2/M1 red before the fix (quoted in M6-findings.md); I3 mutation loop_halve->loop_halv fails it; grep -c midi.send = 0; D30-D35 each have To undo. Mixxx 2.5.6 roll/censor slip behaviour read from loopingcontrol.cpp and ratecontrol.cpp at tag 2.5.6. No MIDI sent, no Mixxx run.
- **Tests:** 1250 → 1262
- **Dead end:** I3 test with num_samplers set after the DEBUG init — debugConnect skips samplers past num_samplers at init, so the sampler keys looked unproven; the dev Mixxx had 8 at init (M6-replay.md logs [Sampler7])
- **Discovery** (affects M7): The fake Mixxx now applies 2.5.6's own side effects: beatlooproll_X_activate forces slip_enabled 1 (0 when the last roll ends), reverseroll forces reverse and slip 1/0. Tests that set this state by hand still pass.
- **Discovery** (affects M7): tests/fixtures/mixxx-2.5.6-connected-keys.txt pins every control name to M6-07's dev-Mixxx run: a mapping change that uses a new (group, key) fails tests/m6-review.test.mjs I3 until a dev-Mixxx DEBUG run proves it and it is added. M7's platter keys (scratch2, scratch2_enable, …) will need that.
- **Discovery** (affects M7): 14-bit pairs now write once (MSB stores, LSB applies); census has 0 lone MSBs in 16,479 pairs, LSB at most 190 us after its MSB. M7's fader history gets one sample per pair.
- **Discovery** (affects M7): Pitch bend keying (fake by status alone, XML midino 0x00) is still UNVERIFIED: M7 must settle it before the platter relies on it (review M5).
- **Proposed change:** M6-09 step 2's 'every handler path is guarded' could name the one residual path: a container that fails to build leaves its XML keys resolving to null inside Mixxx's wrapper (needs a JS bug; noted in M6-findings.md).
- *10-M6-09 · claude-opus-5-5*

### 2026-10-26 05:05 · M6-08 · passes

Added docs/mapping-reference.md (deck, pads per mode, mixer, FX, Shift tables; MIDI row, Mixxx control, UNVERIFIED for mk2/unknown rows; platters not wired until M7), a Round 3 press-each-control list in HARDWARE-TESTS.md (9.5 min), and README status.

- **Files:** docs/mapping-reference.md, HARDWARE-TESTS.md, README.md
- **Verified:** check.sh green, 1250 tests; 84 mk2/unknown rows counted by awk; tables written from the mapping's XML and scripts.
- **Tests:** 1250 → 1250
- **Question for Michael:** Round 3 (HARDWARE-TESTS.md, about 9.5 min) presses each UNVERIFIED control once: do it after Round 2?
- *09-M6-08 · claude-sonnet-5-5*

### 2026-10-26 05:02 · M6-07 · passes

Seven census takes replayed through Midi Through into the dev Mixxx 2.5.6 (debug mapping, null sink): all exit 0, RaneOne: init, 0 controller warnings. Every row the Node harness says changes a control logged it in Mixxx; 0 gaps, 0 expected keys missing. D27's rate_ratio formula holds exactly (1.5/1/0.5). Mixxx stopped. Tests 1249 → 1250.

- **Files:** .harness/runs/rane-one-mixxx-2026-10-24/checks/M6-replay.md, .harness/runs/rane-one-mixxx-2026-10-24/checks/M6-replay-compare.mjs, mapping/Rane-One-scripts.js, tests/mapping-fx.test.mjs, docs/decisions.md, docs/plans/2026-10-24-M6-mapping.md, CLAUDE.md
- **Verified:** tools/mixxx-dev start (WAYLAND_DISPLAY=wayland-1; route check: the mixxx-dev stream on the mixxx-dev sink only), tools/replay --speed 4 on takes 02/03/04/05/06/27/28 (exit 0 each), M6-replay-compare.mjs per log slice against the harness (0 gaps, 0 missing), log grep for Warning [Controller|Critical|exception (0), tools/mixxx-dev stop then status printed 'stopped', null sink back down; check.sh green, 1250 tests.
- **Tests:** 1249 → 1250
- **Dead end:** the plan's grep 'RaneOne: \[[^]]+\]+,…' — it misses groups with nested brackets ([EqualizerRack1_[Channel1]_Effect1], [QuickEffectRack1_[Channel1]]); fixed to 'RaneOne: \[[^,]*\],…' in the plan
- **Dead end:** hot reload (tools/install-mapping into the running Mixxx) as the evidence run — it reloads twice and Mixxx logs its own 'Failed to watch script file' warnings; evidence taken from a fresh start instead (gotcha extended)
- **Discovery** (affects M7): Dev Mixxx has rate_dir −1: the mapping writes rate −1 for 1.5×, and rate_ratio = 1 + rate × rateRange × rate_dir held exactly over 5474 pairs on both decks. M7 can use rate_ratio as playRatio as planned.
- **Discovery** (affects M6-09): ReverseRoll's write-back works in real Mixxx 2.5.6: Mixxx's forced reverse/slip zeros come first, then the mapping's restore (M6-03's assumption confirmed).
- **Discovery** (affects M6-09): The fake's [App],num_samplers is 0, so sampler pads change nothing in harness replays unless a test sets it; the dev Mixxx has 8 samplers. The compare script sets 8.
- **Discovery** (affects M7, M6-09): Preferences Apply keeps rateRange 0.5 (read from 2.5.6 dlgprefdeck.cpp: slotUpdate fills the combo box from the live rateRange) but writes RateRangePercent=50 to mixxx.cfg. A live click is still UNVERIFIED.
- **Question for Michael:** Optional, 1 minute, no hardware: in the dev Mixxx, open Preferences → Decks, press Apply, and check whether the rate range still reads 50 %. The 2.5.6 source says it does, but nobody has clicked it.
- **Proposed change:** M6-07 step 3's 'expected: the platter CC 6 / pitch bend rows and the no-op rows only' should also allow rows that only change mapping state (Shift, pad mode, Stop Time, Shift+Slip motor off) and the strip (playposition is left out of the debug log on purpose). None of the seven takes has a platter message.
- *08-M6-07 · claude-opus-5-5*

### 2026-10-26 04:51 · M6-06 · passes

FX section mapped per D32 (paddles set their unit's enable, FX1–6 counted no-ops, Tap on the paddled deck, depth's held paddle-on zero), platter CC 6/pitch bend to counting M7 placeholders, RaneOne.DEBUG log and install-mapping --debug. M6-02's todo check is on; 9 takes replay with 0 unhandled, 0 thrown.

- **Files:** mapping/Rane-One-scripts.js, mapping/Rane-One.midi.xml, tests/mapping-fx.test.mjs, tests/helpers/fake-mixxx.mjs, tools/install-mapping, tests/install-mapping.test.mjs, tests/tools-usage.test.mjs, tests/mapping-xml.test.mjs, tests/mapping-mixer.test.mjs, docs/decisions.md, docs/plans/2026-10-24-M6-mapping.md, HARDWARE-TESTS.md
- **Verified:** check.sh green, 1249 tests. mapping-fx 27/27, including the replay table: takes 02-06, 27, 28, 25, 26 have 0 unhandled, 0 thrown and 0 warnings (25: 34,394 platter messages counted). The todo test now passes. install-mapping --debug run into a scratch profile: the copy says DEBUG = true and mapping/ still says false. An Opus review gave 8 findings and 7 are fixed.
- **Tests:** 1213 → 1249
- **Dead end:** a pitch bend <control> keyed by its LSB in the fake — the LSB changes with every message, and Mixxx's shipped pitch bend faders (Icon-iControls, MVave-SMC-Mixer) use one entry with no <midino>, so the fake now keys a pitch bend by its status alone
- **Discovery** (affects M7): How Mixxx 2.5 keys pitch bend inputs is UNVERIFIED. Its shipped 14-bit pitch-bend faders bind one entry with no <midino>, so the fake ignores data1 for 0xEn. M7's platter wiring must confirm this in real Mixxx.
- **Discovery** (affects M6-07): With RaneOne.DEBUG on, init connects about 214 (group, key) pairs and logs 'RaneOne: <g>,<k> = <v>'. playposition is left out because it moves all the time during play, so M6-07 sees no log line for the strip. If Mixxx refuses one connection, the others still connect.
- **Discovery** (affects M7, M6-07): RaneOne.heard runs before every input (it settles D32's held depth zero). Platter messages are skipped there so the 1 ms motor traffic can't apply the paddle-on zero; only the 50 ms timer can. Whether a platter message can come between the zero and the burst is UNVERIFIED (round 2, optional step 13).
- **Question for Michael:** D32 update: a depth 0 that comes before any depth value is now held as well, because all of take 02's paddle-ons happen before its depth sweep. Is that OK?
- **Proposed change:** M6-06 step 1 names the paddle notes as 'channel 9 notes 0–2 and channel 10 notes 3–5'. The controls CSV and D32 have the paddles on note 16 of ch 9/10, and 0–2/3–5 are the FX1–6 state rows. The step should say note 16.
- **Proposed change:** M6-06 step 2: no controls-CSV row is left unmapped as 'unknown'. The plan maps the unknown rows by a guess marked UNVERIFIED, and only no-op rows go to RaneOne.noop or RaneOne.Counted. The step should say that.
- *07-M6-06 · claude-opus-5-5*

### 2026-10-26 04:22 · M6-05 · passes

Pads and pad modes are mapped per D30: RaneOne.PadMode (mode notes 0/13/7/11/12 on ch 5/6, Hot Cue at init) and eight RaneOne.Pad per deck (notes 20–27, Shift 28–35), momentary targets read at the press. There are 84 new XML entries. Takes 03–06/27/28 replay with nothing unhandled. Review fix: a Roll pad writes back the deck's Slip.

- **Files:** mapping/Rane-One-scripts.js, mapping/Rane-One.midi.xml, tests/mapping-pads.test.mjs, tests/mapping-deck.test.mjs, docs/decisions.md, docs/plans/2026-10-24-M6-mapping.md
- **Verified:** check.sh green, 1213 tests. mapping-pads: 25 tests, covering all five modes × 8 pads × both layers on both decks, per-deck mode, release across a mode change or the other note, the sampler past num_samplers counted, shutdown releasing a held roll, the guarded throw, the XML keys, and replays of 04/06/27/28 (0 thrown, ch 5/6 unhandled empty, one set per pad press). node --check ok. grep -c midi.send is 0. An Opus review found no Critical or Important issues.
- **Tests:** 1188 → 1213
- **Discovery** (affects M6-06): After M6-05, takes 03, 04, 05, 06, 27 and 28 replay with zero unhandled messages. Still unhandled: 02's FX rows (ch 9 notes 0–2/16, ch 10 notes 3–5/16, ch 16 note 4) plus the platter CC 6 and pitch bend in 25/26: all M6-06's. mapping-deck's 03/05 replay test now asserts that nothing is unhandled.
- **Discovery** (affects M6-07, M6-08, M6-09): Pad mode state is RaneOne.deckN.padMode.mode (the PadMode component, not in sameNote); the pads are RaneOne.deckN.pads.pad1..8. Mixxx 2.5's roll forces slip_enabled 1 and then 0, so Pad saves the deck's Slip and writes it back after the roll.
- **Question for Michael:** D30: pad mode lives only in the mapping and resets to Hot Cue on every init or hot reload, with no LED to show it. A Shift+pad meant for Roll or Beat Jump then clears a hot cue. Is that acceptable, or should Shift+pad in Hot Cue mode do something non-destructive? Also: do the One's mode buttons light by themselves (round 2)?
- **Proposed change:** M6-05 step 3 says RaneOne.Pad 'swaps its input on mode change'. It reads the deck's mode at each press instead, so a held pad releases what it pressed even after a mode change. Reword the step to allow that.
- **Proposed change:** M6-08 round 2: add 'press a pad-mode button after a hot reload: does its LED light without Mixxx?'
- *06-M6-05 · claude-opus-5-5*

### 2026-10-26 04:09 · M6-04 · passes

Pitch fader (14-bit, D27 live-range rate, no takeover), mixer Pots with soft takeover, cue-state buttons, crossfader, front-panel knobs, library encoders, FX depth/beat knobs, strip (D34) and Stop Time/torque stores are mapped and guarded; 40 XML entries. Review fixes: orphan LSB dropped, per-container guarded build, D35 faders start at 0.

- **Files:** mapping/Rane-One-scripts.js, mapping/Rane-One.midi.xml, tests/mapping-mixer.test.mjs, tests/mapping-deck.test.mjs, tests/mapping-xml.test.mjs, docs/decisions.md, docs/plans/2026-10-24-M6-mapping.md
- **Verified:** tests/mapping-mixer.test.mjs 36 pass (take 23 top/centre/bottom → rate −1/0/+1, lone CC 9 exact (MSB<<7)+64, every Pot sweeps 0..1 in take 02 with softTakeover(g,k,true), take 26 strip, no duplicate XML entry); full suite green 1188; node --check ok; grep -c midi.send = 0; an Opus review (1 Important, 5 Minor) acted on except M1.
- **Tests:** 1152 → 1188
- **Dead end:** setting rateRange inside init before building the decks — a throwing engine then stopped init before any deck was built; it now runs last in its own guard (RaneOne.setStart)
- **Discovery** (affects M6-05, M6-06): M6-04 also did the strip (D34), the Stop Time/torque stores and the FX depth (Pots on both units' mix) and beat knobs; M6-06 is left with the paddles, FX1-6 state, Tap, D32's depth-0-at-paddle-on rule, no-ops, platter placeholders and DEBUG. Only pads (ch 5/6) and ch 9/10 + note 4 ch 16 are still without <control> entries.
- **Discovery** (affects M6-05, M6-06): init now writes rateRange 0.5 and volume 0 (D35) on both channels: tests that compare h.sets exactly must clear h.sets after loadMapping (mapping-deck's fresh() does).
- **Discovery** (affects M6-06): Components' Pot maps 7-bit 64 to exactly 0.5 (inValueScale's centre rule), not 64/127.
- **Discovery** (affects M6-09, M7): Review M1, not acted on: the plan's MSB-alone rule writes rate twice per pair (the first up to 64 steps, ~0.39 % speed, off for the moment until the LSB at the same t_us). Alternative: MSB stores, LSB applies, +64 only on a lost LSB (next MSB or a timer). For M6-09 to weigh.
- **Discovery** (affects M6-07): Review M5: PitchFader warns once per deck when rateRange < 0.5; whether applying Preferences resets rateRange is still for M6-07 to check (D27).
- **Question for Michael:** D35 (default): channel faders start at 0 in Mixxx until the One reports them, since it only sends positions at power-on. OK that a fader left up stays silent until you nudge it?
- **Proposed change:** M6-04 step 2's 'presses (channel 16 note 4 and the deck notes the plan names) load or select': per the plan and D32, ch 16 note 4 is FX Tap (M6-06), Load/Back are M6-03's, and the census has no encoder press; the step should drop that clause or point to M6-06's Tap.
- *05-M6-04 · claude-opus-5-5*

### 2026-10-26 03:50 · M6-03 · passes

Deck buttons on ch 1/2 and 5/6 (Play, Cue, Sync, Load, Back, pitch bends, Range/keylock, Reverse/censor, Slip/motor-off, pad parameter, loop and auto-loop buttons) and Shift are mapped as Components in RaneOne.Deck, with 108 XML entries (0x9n and 0x8n). Every input is guarded, nothing is sent, and the suite is green.

- **Files:** mapping/Rane-One-scripts.js, mapping/Rane-One.midi.xml, tests/mapping-deck.test.mjs, tests/mapping-xml.test.mjs
- **Verified:** Suite 1074 → 1152 green. mapping-deck: 76 tests; one per CSV deck row on both decks, Shift via note 50 ch 16. mapping-xml: 2 new tests (every key guarded; full init on a hostile engine); a mutation with guardInputs disabled fails 4 tests. Replay of 03: 6592 msgs, 24 controls changed, 0 thrown. Replay of 05: 6734 msgs, 24 controls, 0 thrown. node --check ok; grep -c midi.send = 0. Opus review: 1 Important finding (fixed test-first), 6 Minor.
- **Tests:** 1074 → 1152
- **Dead end:** defining the component classes when the script loads — mapping-xml's load() runs the script without Components when the Flatpak is absent, so the classes are defined in RaneOne.defineComponents at init
- **Discovery** (affects M6-05, M6-03): Take 03 also presses deck 1's pads and pad-mode buttons (ch 5 notes 0, 7, 11–13, 20–35). After M6-03 these stay unhandled until M6-05; take 05's unhandled list is only CC 9/41 and the deck knobs (CC 0/1/43/72/75).
- **Discovery** (affects M6-05, M6-06): guardInputs replaces each input with a wrapper, so ComponentContainer.shift() no longer zeroes a held Components push Button. sameNote may hold only components that track their own held key (RaneOne.PushButton/BendButton). This matters for the M6-05 pad-mode buttons.
- **Discovery** (affects M6-07, M7): Mixxx 2.5.6 forces reverse and slip_enabled to 0 when reverseroll is released (RateControl::slotReverseRollActivate, per the reviewer reading the 2.5.6 source). RaneOne.ReverseRoll writes back the earlier values. It assumes the slot runs inside setValue (direct connection); M6-07's dev-Mixxx replay can confirm.
- **Discovery** (affects M6-04, M6-05, M6-06): Building blocks for later M6 features: RaneOne.Layered (two notes, release on either), RaneOne.PushButton (tracks its held key), RaneOne.Button (a note-off is a release), RaneOne.noop/count (keys like '90 ch 1 43'), RaneOne.releaseAll (called in shutdown), RaneOne.shifted.
- **Proposed change:** M6-03 step 3 should also allow deck 1's pads and pad-mode buttons (M6-05) in take 03's unhandled list. The take presses them, and the test lists them as M6-05's.
- **Proposed change:** M6 plan table: 'press only' rows on Mixxx push controls (start, Load, Back, beatjump, loop_halve/double, loop_in/out) are momentary in the code, 1 on press and 0 on release. Mixxx's loop_in/loop_out act on the release, and Components' push Button does the same.
- **Proposed change:** Reviewer Minor finding, not fixed: if init fails, keys like RaneOne.deck1.cue.input throw a TypeError in Mixxx's wrapper. M6-09 could add stub decks or a guarded dispatcher.
- *04-M6-03 · claude-opus-5-5*

### 2026-10-26 03:28 · M6-02 · passes

M6-02 passes; commit `3007be8` is pushed to `harness/rane-one-mixxx-2026-10-24`. The suite is green: 1058 → 1074 tests. - **Harness:** `tests/helpers/fake-mixxx.mjs` loads Mixxx 2.5.6's own scripts and Components library from the Flatpak, records engine calls, and makes `midi` sends throw. Without the Flatpak its tests skip with the reason. - **Real mapping:** it has no controls yet, so the three…

- **Files:** mapping/Rane-One-scripts.js, mapping/Rane-One.midi.xml, tests/fixtures/README.md, tests/fixtures/mapping-harness/Probe.midi.xml, tests/fixtures/mapping-harness/probe-scripts.js, tests/fixtures/mapping-harness/three-messages.jsonl, tests/helpers/fake-mixxx.mjs, tests/helpers/xml.mjs, tests/mapping-harness.test.mjs, tests/mapping-xml.test.mjs
- *03-M6-02 · claude-opus-5-5 · recorded by the harness: entry.json invalid: summary: 401 characters (at most 400)*

### 2026-10-26 03:13 · M6-01 · passes

Wrote docs/plans/2026-10-24-M6-mapping.md: a 137-row control table generated from the controls CSV (every row except the platter pair), the script structure (decks, mixer, FX, Shift by note vs by state, 14-bit rule, guarded inputs), the fake-Mixxx harness, the dev-Mixxx replay check, out of scope. D30-D34 defaults added. Suite 1058 green.

- **Files:** docs/plans/2026-10-24-M6-mapping.md, docs/decisions.md
- **Verified:** Table rows counted against the CSV (137 = 141 - 4 platter rows); awk: every Pot row has soft takeover, every mk2/unknown row says UNVERIFIED; each D30-D34 has an MK2 hint and a To undo line; control names grepped in the Flatpak 2.5.6 controllers/skins; check.sh green, 1058 tests.
- **Tests:** 1058 → 1058
- **Dead end:** planning note-offs to reuse the 0x9n XML entry — the One sends real 0x8n note-offs (414 in takes 02-06, 25-28) and Mixxx binds by exact status byte, so every note needs a 0x8n entry too
- **Discovery** (affects M6-02, M6-03, M6-05, M6-06): The One releases buttons with 0x8n note-offs (414 in the census takes) and reports states as 0x9n value 0 (78): the XML needs 0x90 and 0x80 entries per note.
- **Discovery** (affects M6-02, M6-04): Components' Pot calls engine.softTakeover only from its first input (Pot.input -> connect), so a takeover test must send a value first.
- **Discovery** (affects M6-06): FX1-6 rows only ever send value 0, all six with each paddle change, and CC 4 = 0 rides along with each paddle-on: mapping FX1-6 to effect enables would turn every effect off at each paddle move (D32 makes them no-ops; depth drops that zero).
- **Discovery** (affects M6-04, M6-05): Mixxx 2.5.6 has no [Mixer] group in shipped mappings or skins ([Master] still), and no beatjump_size_halve/double.
- **Discovery** (affects M6-02): tests/mapping-xml.test.mjs asserts the two-file script list and loads scripts without Components; M6-02 must change both (plan section Test harness).
- **Question for Michael:** D30: are Hot Cue / Saved Loop / Roll / Sampler / Beat Jump the pad modes you want (Beat Jump on the MK2's Stems button, since Mixxx 2.5 has no stems)?
- **Question for Michael:** D31: OK that Shift+Play is just Play, and Shift+Cue jumps to the start without stopping?
- **Question for Michael:** D32: is each FX paddle its own deck's effect unit, and should Tap change a track's BPM (bpm_tap) at all?
- **Question for Michael:** D33: should Shift+Load eject or clone the other deck instead of loading, and which way should the browse knob scroll?
- **Question for Michael:** D34: keep the strip-search guard (only while stopped or with Shift), or let it always jump?
- **Proposed change:** M6-04 step 2 names 'channel 16 note 4' as an encoder press: per the controls CSV it is FX Tap (M6-06); there is no encoder press row. It should say Load (notes 6/8) and Back (7/18) per D33.
- **Proposed change:** M6-06 step 1 calls ch 9 notes 0-2 / ch 10 notes 3-5 the paddles: per the controls CSV those are the FX1-6 state rows, and the paddles are note 16 on ch 9/10. FX1-6 are counted no-ops by D32, not effect selectors.
- **Proposed change:** M6-01 step 2's 'no-op (counted) for unknown rows' read as rows with no Mixxx function; confidence-unknown rows with a guessable function (trim, EQ, cue, CC 35/36) are mapped and marked UNVERIFIED (plan, How to read it).
- *02-M6-01 · claude-opus-5-5*

### 2026-10-26 03:01 · verify M5 · passes

All 10 M5 features hold. Suite 1058/1058 green; census CSVs and diff regenerate identically; platter-run-all gives 0 glitches on 24 takes; ticks/rev, rates, fader sweeps and spin tables re-derived. M5-06 step 4 judged by Michael's reworded answer (a).

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| M5-01 | 1 | read artifact named in step + named test files (node --test platter-*/census* all pass) and spot-checked tool output | artifact present and matches the step; cited numbers re-derived where tools applied | yes |
| M5-01 | 2 | read artifact named in step + named test files (node --test platter-*/census* all pass) and spot-checked tool output | artifact present and matches the step; cited numbers re-derived where tools applied | yes |
| M5-01 | 3 | read artifact named in step + named test files (node --test platter-*/census* all pass) and spot-checked tool output | artifact present and matches the step; cited numbers re-derived where tools applied | yes |
| M5-01 | 4 | read artifact named in step + named test files (node --test platter-*/census* all pass) and spot-checked tool output | artifact present and matches the step; cited numbers re-derived where tools applied | yes |
| M5-01 | 5 | read artifact named in step + named test files (node --test platter-*/census* all pass) and spot-checked tool output | artifact present and matches the step; cited numbers re-derived where tools applied | yes |
| M5-01 | 6 | read artifact named in step + named test files (node --test platter-*/census* all pass) and spot-checked tool output | artifact present and matches the step; cited numbers re-derived where tools applied | yes |
| M5-01 | 7 | npm test (check.sh, cached green) | 1058 tests, 1058 pass, 0 fail | yes |
| M5-02 | 1 | read artifact named in step + named test files (node --test platter-*/census* all pass) and spot-checked tool output | artifact present and matches the step; cited numbers re-derived where tools applied | yes |
| M5-02 | 2 | tools/analyze-platter 12-hand-d2-slow.jsonl --deck 2; same without --deck | CC 6 deltas -1 x2870, +1 x3198 (+-2 minor), net -4; without --deck 0 CC 6; --help says default 1 | yes |
| M5-02 | 3 | tools/platter-run 21-motor-d2-33.jsonl --deck 2 | runs to end, 'control flips under 20 ms: 0', 0 timer unwrap errors | yes |
| M5-02 | 4 | read artifact named in step + named test files (node --test platter-*/census* all pass) and spot-checked tool output | artifact present and matches the step; cited numbers re-derived where tools applied | yes |
| M5-02 | 5 | npm test (check.sh, cached green) | 1058 tests, 1058 pass, 0 fail | yes |
| M5-03 | 1 | tools/census on the 7 takes --shift 16:50 and --diff vs MK2, diffed against committed CSVs | identical (134 rows; both 125/only-mk1 12/only-mk2 75) | yes |
| M5-03 | 2 | read controls CSV; script: every map row has one controls row | 141 rows, 0 missing, 0 duplicates; capture 57 / mk2 72 / unknown 12 | yes |
| M5-03 | 3 | read artifact named in step + named test files (node --test platter-*/census* all pass) and spot-checked tool output | artifact present and matches the step; cited numbers re-derived where tools applied | yes |
| M5-03 | 4 | read artifact named in step + named test files (node --test platter-*/census* all pass) and spot-checked tool output | artifact present and matches the step; cited numbers re-derived where tools applied | yes |
| M5-03 | 5 | read artifact named in step + named test files (node --test platter-*/census* all pass) and spot-checked tool output | artifact present and matches the step; cited numbers re-derived where tools applied | yes |
| M5-03 | 6 | npm test (check.sh, cached green) | 1058 tests, 1058 pass, 0 fail | yes |
| M5-04 | 1 | analyze-platter 09 and 13 --deck 2 | net +36008 and +35987; doc gives 3600, mark error, 3584 excluded, 3598 excluded by period | yes |
| M5-04 | 2 | analyze-platter 07 --markers; read doc saturation table | 3 timed -1 at 0.97-0.99, 5 band deltas, 3 exceptions on backward CC0 passes; 'saturation confirmed with one exception'; D24 marked VERIFIED/amended | yes |
| M5-04 | 3 | read artifact named in step + named test files (node --test platter-*/census* all pass) and spot-checked tool output | artifact present and matches the step; cited numbers re-derived where tools applied | yes |
| M5-04 | 4 | read artifact named in step + named test files (node --test platter-*/census* all pass) and spot-checked tool output | artifact present and matches the step; cited numbers re-derived where tools applied | yes |
| M5-04 | 5 | read artifact named in step + named test files (node --test platter-*/census* all pass) and spot-checked tool output | artifact present and matches the step; cited numbers re-derived where tools applied | yes |
| M5-04 | 6 | read artifact named in step + named test files (node --test platter-*/census* all pass) and spot-checked tool output | artifact present and matches the step; cited numbers re-derived where tools applied | yes |
| M5-04 | 7 | npm test (check.sh, cached green) | 1058 tests, 1058 pass, 0 fail | yes |
| M5-05 | 1 | analyze-platter 15 and 21 --phases 4-63 | timer 2,822,403/s and 2,822,501/s, net -117950/+117792; matches doc table (33.318/33.273 rpm) | yes |
| M5-05 | 2 | read artifact named in step + named test files (node --test platter-*/census* all pass) and spot-checked tool output | artifact present and matches the step; cited numbers re-derived where tools applied | yes |
| M5-05 | 3 | read artifact named in step + named test files (node --test platter-*/census* all pass) and spot-checked tool output | artifact present and matches the step; cited numbers re-derived where tools applied | yes |
| M5-05 | 4 | read artifact named in step + named test files (node --test platter-*/census* all pass) and spot-checked tool output | artifact present and matches the step; cited numbers re-derived where tools applied | yes |
| M5-05 | 5 | read artifact named in step + named test files (node --test platter-*/census* all pass) and spot-checked tool output | artifact present and matches the step; cited numbers re-derived where tools applied | yes |
| M5-05 | 6 | take-events 25 --no-platter; read doc | Shift 50 ch16, note 10 ch5/6, cc ch15 96 at 34.571/37.606 s as documented; reverse pad marked UNVERIFIED round 2 | yes |
| M5-05 | 7 | read artifact named in step + named test files (node --test platter-*/census* all pass) and spot-checked tool output | artifact present and matches the step; cited numbers re-derived where tools applied | yes |
| M5-05 | 8 | read artifact named in step + named test files (node --test platter-*/census* all pass) and spot-checked tool output | artifact present and matches the step; cited numbers re-derived where tools applied | yes |
| M5-05 | 9 | npm test (check.sh, cached green) | 1058 tests, 1058 pass, 0 fail | yes |
| M5-06 | 1 | tools/fader-sweeps 23 and 24 --deck 2 | holds table identical to doc: +-50 % range, 16383 -> 1.5, 0 -> 0.5; deck 2 bottom 0.464 sag | yes |
| M5-06 | 2 | read artifact named in step + named test files (node --test platter-*/census* all pass) and spot-checked tool output | artifact present and matches the step; cited numbers re-derived where tools applied | yes |
| M5-06 | 3 | read artifact named in step + named test files (node --test platter-*/census* all pass) and spot-checked tool output | artifact present and matches the step; cited numbers re-derived where tools applied | yes |
| M5-06 | 4 | read tests/platter-fader.test.mjs, doc; node --test | passes; top/centre within 0.5 %; deck 2 bottom pinned as sag per Michael's answer (a) reword (feature text itself not edited) | yes |
| M5-06 | 5 | read artifact named in step + named test files (node --test platter-*/census* all pass) and spot-checked tool output | artifact present and matches the step; cited numbers re-derived where tools applied | yes |
| M5-06 | 6 | npm test (check.sh, cached green) | 1058 tests, 1058 pass, 0 fail | yes |
| M5-07 | 1 | read artifact named in step + named test files (node --test platter-*/census* all pass) and spot-checked tool output | artifact present and matches the step; cited numbers re-derived where tools applied | yes |
| M5-07 | 2 | read artifact named in step + named test files (node --test platter-*/census* all pass) and spot-checked tool output | artifact present and matches the step; cited numbers re-derived where tools applied | yes |
| M5-07 | 3 | read artifact named in step + named test files (node --test platter-*/census* all pass) and spot-checked tool output | artifact present and matches the step; cited numbers re-derived where tools applied | yes |
| M5-07 | 4 | read artifact named in step + named test files (node --test platter-*/census* all pass) and spot-checked tool output | artifact present and matches the step; cited numbers re-derived where tools applied | yes |
| M5-07 | 5 | npm test (check.sh, cached green) | 1058 tests, 1058 pass, 0 fail | yes |
| M5-08 | 1 | tools/platter-run-all | 24 rows (07-15,17-21,23-26,29-34), 'glitches 0' on every take, 24 takes: 0 control flips under 20 ms | yes |
| M5-08 | 2 | read artifact named in step + named test files (node --test platter-*/census* all pass) and spot-checked tool output | artifact present and matches the step; cited numbers re-derived where tools applied | yes |
| M5-08 | 3 | read artifact named in step + named test files (node --test platter-*/census* all pass) and spot-checked tool output | artifact present and matches the step; cited numbers re-derived where tools applied | yes |
| M5-08 | 4 | read artifact named in step + named test files (node --test platter-*/census* all pass) and spot-checked tool output | artifact present and matches the step; cited numbers re-derived where tools applied | yes |
| M5-08 | 5 | npm test (check.sh, cached green) | 1058 tests, 1058 pass, 0 fail | yes |
| M5-09 | 1 | read artifact named in step + named test files (node --test platter-*/census* all pass) and spot-checked tool output | artifact present and matches the step; cited numbers re-derived where tools applied | yes |
| M5-09 | 2 | read artifact named in step + named test files (node --test platter-*/census* all pass) and spot-checked tool output | artifact present and matches the step; cited numbers re-derived where tools applied | yes |
| M5-09 | 3 | read artifact named in step + named test files (node --test platter-*/census* all pass) and spot-checked tool output | artifact present and matches the step; cited numbers re-derived where tools applied | yes |
| M5-09 | 4 | read artifact named in step + named test files (node --test platter-*/census* all pass) and spot-checked tool output | artifact present and matches the step; cited numbers re-derived where tools applied | yes |
| M5-09 | 5 | npm test (check.sh, cached green) | 1058 tests, 1058 pass, 0 fail | yes |
| M5-10 | 1 | read artifact named in step + named test files (node --test platter-*/census* all pass) and spot-checked tool output | artifact present and matches the step; cited numbers re-derived where tools applied | yes |
| M5-10 | 2 | read artifact named in step + named test files (node --test platter-*/census* all pass) and spot-checked tool output | artifact present and matches the step; cited numbers re-derived where tools applied | yes |
| M5-10 | 3 | read artifact named in step + named test files (node --test platter-*/census* all pass) and spot-checked tool output | artifact present and matches the step; cited numbers re-derived where tools applied | yes |
| M5-10 | 4 | read artifact named in step + named test files (node --test platter-*/census* all pass) and spot-checked tool output | artifact present and matches the step; cited numbers re-derived where tools applied | yes |
| M5-10 | 5 | npm test (check.sh, cached green) | 1058 tests, 1058 pass, 0 fail | yes |

- *025628-verify-M5 · claude-sonnet-5-5*

### 2026-10-26 02:56 · M5-06 · passes

Step 4 verified as Michael reworded it (answer (a)): deck 1 top/centre/bottom and deck 2 top/centre within ±0.5 %, deck 2 bottom pinned as a 0.8–7.3 % sag (bounds tightened to match), 0.5x ±0.5 % in every 250 ms window in sweeps 2 and 3. Also fixed the red suite: two temp dirs from the main merge now use tempDir().

- **Files:** tests/platter-fader.test.mjs, tests/census.test.mjs, tests/census-map.test.mjs, docs/research/2026-10-24-census-analysis.md
- **Verified:** check.sh green, 1058 tests (red at start: census --diff --out ReferenceError mkdtempSync, temp-cleanup census-map x2). Steps 1-3, 5 re-read in doc § Pitch fader and Range and D27; step 4 by tests/platter-fader.test.mjs (16 pass).
- **Tests:** 1058 → 1058
- **Discovery** (affects run): Merging main's tempDir() cleanup missed branch-only call sites (census.test.mjs:312 lost its mkdtempSync import; census-map.test.mjs never converted). Check new test files after merges from main.
- **Proposed change:** M5-06 step 4 text: use Michael's answer (a) wording; also 'whether 0 is the top' can't be read from the takes (16383 is the fast end, physical end UNVERIFIED, round 2).
- *01-M5-06 · claude-opus-5-5*

<!-- harness: progress.md before the journal, kept as it was -->
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
