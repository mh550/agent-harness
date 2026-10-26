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
