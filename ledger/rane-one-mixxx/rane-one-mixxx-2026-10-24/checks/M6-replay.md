# M6-07: the census replayed into the dev Mixxx

2026-10-26 04:51–04:58, Mixxx 2.5.6 (Flatpak) on the dev profile in Michael's desktop session (`WAYLAND_DISPLAY=wayland-1`),
mapping bound to `Midi Through Port-0`. The Rane One was not connected (no Rane client in `aconnect -l`), and nothing
was sent to it. The audio went to the `mixxx-dev` null sink, which this session brought up and took down again.

## How

```sh
tools/null-sink up                       # mixxx-dev up (module 536870916); default sink still alsa_output.pci-0000_00_1f.3.analog-stereo
tools/install-mapping --debug            # RaneOne.DEBUG = true in the dev profile's copy
tools/mixxx-dev start
# per take, at --speed 4: tools/replay --to-port 'Midi Through' --speed 4 captures/2026-10-23-census/<take>.jsonl,
# with the log lines it added cut to a slice per take
node .harness/runs/rane-one-mixxx-2026-10-24/checks/M6-replay-compare.mjs captures/2026-10-23-census/<take>.jsonl <slice>
tools/mixxx-dev stop && tools/mixxx-dev status
tools/null-sink down
```

`M6-replay-compare.mjs` (next to this file) replays the same take through the Node harness (`tests/helpers/fake-mixxx.mjs`,
RaneOne.DEBUG on, 8 samplers like the dev Mixxx), so each MIDI row gets the (group, key) set the mapping changes for it.
It then checks the Mixxx slice for `RaneOne: <group>,<key> = <value>` lines. A row is **logged** when Mixxx logged
one of its keys, **quiet** when the harness changes no logged control for it either, and a **gap** when the harness
expects keys and Mixxx logged none. *Expected, not logged* counts every expected key that never appears in the slice.

The plan's grep `RaneOne: \[[^]]+\]+,…` misses groups with nested brackets (`[EqualizerRack1_[Channel1]_Effect1]`,
`[QuickEffectRack1_[Channel1]]`). The script uses `RaneOne: (\[[^,]*\]),(\S+) = ` instead.

## Step 1: start, init, no mapping warning

`tools/mixxx-dev start` printed its route check:

```
running: 1846563878 (stream on mixxx-dev; log /home/mh550/.var/app/org.mixxx.Mixxx/dev-profile/mixxx.log)
```

`pactl list sink-inputs` right after it: the one `application.name = "mixxx-dev"` stream is on sink 327, which
`pactl list short sinks` lists as `mixxx-dev`. The only other stream was `speech-dispatcher-dummy` on the analog
output (not Mixxx). So Mixxx played to the mixxx-dev null sink only.

The log has `04:54:10.106 Debug [Controller] RaneOne: init Midi Through Port-0`. Over the whole run (start, seven
replays, stop) it has **0** lines matching `Warning [Controller`, `Critical`, `Fatal`, `exception`, `Uncaught` or
`threw`. The run's warnings are Mixxx's own: 8 `[Main]` (portaudio JACK rename, no samplers.xml, …), 4 `[Engine]`
(no SCHED_FIFO, underflows, PortAudio time stamps) and 1 thread warning, none from the mapping. Mixxx ran with
`--controller-debug --controller-abort-on-warning` and did not abort.

Hot reload, tried once before the clean start: `tools/install-mapping` with Mixxx running ran `RaneOne.shutdown`
(`RaneOne: shutdown`, every debug connection disconnected) and `RaneOne.init` again, **twice** (the watcher fires
for each renamed file). Mixxx then logged three `Warning [Controller] Failed to watch script file …` lines for the
files it re-watches. Those come from Mixxx's file watcher, not the mapping, and did not abort. The clean evidence
below is from a fresh `stop`/`start`.

## Step 2: replays

| take | events | duration at --speed 4 | exit |
|---|---|---|---|
| 02-census-mixer | 5415 | 49.216 s | 0 |
| 03-census-d1-controls | 6592 | 38.677 s | 0 |
| 04-census-d1-pads | 174 | 18.075 s | 0 |
| 05-census-d2-controls | 6734 | 24.161 s | 0 |
| 06-census-d2-pads | 190 | 18.492 s | 0 |
| 27-census-d1-pads-shift | 80 | 7.157 s | 0 |
| 28-census-d2-pads-shift | 80 | 4.744 s | 0 |

Each replay printed `dropped 0 sysex, 0 system, 0 real-time`. The log kept up at `--speed 4`: no take has an
expected key Mixxx didn't log, so no run at `--speed 1` was needed.

## Step 3: per take

None of these seven takes has a platter message (CC 6 or pitch bend on channels 1/2), so no platter row appears below.
Every quiet row is a counted no-op, state the mapping keeps for itself, or `playposition` (left out of the log on
purpose). **No take has a gap, and no expected key is missing.**

### 02-census-mixer

| messages sent | replay exit | debug lines | distinct controls changed | rows | rows logged | rows quiet | gaps | expected, not logged |
|---|---|---|---|---|---|---|---|---|
| 5415 | 0 | 6429 | 23 | 28 | 21 | 7 | 0 | 0 |

Logged but not set by the mapping: none.

Ten sample lines:

```
RaneOne: [Master],crossfader = -0.015625
RaneOne: [Channel1],volume = 0.0020168579686868607
RaneOne: [QuickEffectRack1_[Channel1]],super1 = 0.3984375
RaneOne: [EqualizerRack1_[Channel1]_Effect1],parameter1 = 1.2461349536208917
RaneOne: [Channel1],pregain = 1.8077686769634345
RaneOne: [EqualizerRack1_[Channel2]_Effect1],parameter3 = 0.41014446597775894
RaneOne: [EffectRack1_EffectUnit2],mix = 0.6904761904761905
RaneOne: [EffectRack1_EffectUnit2],mix = 0.7777777777777778
RaneOne: [EffectRack1_EffectUnit2],mix = 0.7380952380952381
RaneOne: [EffectRack1_EffectUnit2],mix = 0.5
```

Rows with no log line (the harness changes no logged control for them either):

| row (status, channel, number) | messages | handler | why |
|---|---|---|---|
| 90 ch10 3 | 12 | `RaneOne.fx.fxState.input` | FX1–6 state: counted no-op (D32) |
| 90 ch10 4 | 12 | `RaneOne.fx.fxState.input` | FX1–6 state: counted no-op (D32) |
| 90 ch10 5 | 12 | `RaneOne.fx.fxState.input` | FX1–6 state: counted no-op (D32) |
| 90 ch16 4 | 10 | `RaneOne.fx.tap.input` | Tap: `bpm_tap` only on a paddled deck; no paddle was up at these taps, so nothing in the harness either (D32) |
| 90 ch9 0 | 12 | `RaneOne.fx.fxState.input` | FX1–6 state: counted no-op (D32) |
| 90 ch9 1 | 12 | `RaneOne.fx.fxState.input` | FX1–6 state: counted no-op (D32) |
| 90 ch9 2 | 12 | `RaneOne.fx.fxState.input` | FX1–6 state: counted no-op (D32) |

### 03-census-d1-controls

| messages sent | replay exit | debug lines | distinct controls changed | rows | rows logged | rows quiet | gaps | expected, not logged |
|---|---|---|---|---|---|---|---|---|
| 6592 | 0 | 5523 | 43 | 54 | 43 | 11 | 0 | 0 |

Logged but not set by the mapping: `[Channel1],rate_ratio` (Mixxx computes it).

Ten sample lines:

```
RaneOne: [Channel1],cue_default = 1
RaneOne: [Channel1],rate = -0.3203516054205835
RaneOne: [Channel1],rate = -0.7110242949578804
RaneOne: [Channel1],rate = -0.8672933707727992
RaneOne: [Channel1],rate = -0.42973995849102664
RaneOne: [Channel1],rate = -0.007813453790745939
RaneOne: [Channel1],rate = 0.4140625
RaneOne: [Channel1],rate = 0.8046875
RaneOne: [Channel1],rate = 0.8203125
RaneOne: [Channel1],rate = 0.4296875
```

Rows with no log line (the harness changes no logged control for them either):

| row (status, channel, number) | messages | handler | why |
|---|---|---|---|
| 90 ch1 43 | 2 | `RaneOne.deck1.range.input` | Range: changes nothing (D27); pressed without Shift here |
| 90 ch16 50 | 56 | `RaneOne.shift.input` | Shift: mapping state only (`RaneOne.shifted`), no Mixxx control |
| 90 ch5 0 | 4 | `RaneOne.deck1.padMode.input` | pad mode: mapping state only (D30) |
| 90 ch5 10 | 2 | `RaneOne.deck1.slip.input` | every press here is Shift+Slip, the One's motor off: nothing in Mixxx |
| 90 ch5 11 | 4 | `RaneOne.deck1.padMode.input` | pad mode: mapping state only (D30) |
| 90 ch5 12 | 4 | `RaneOne.deck1.padMode.input` | pad mode: mapping state only (D30) |
| 90 ch5 13 | 4 | `RaneOne.deck1.padMode.input` | pad mode: mapping state only (D30) |
| 90 ch5 7 | 4 | `RaneOne.deck1.padMode.input` | pad mode: mapping state only (D30) |
| b0 ch1 43 | 1566 | `RaneOne.deck1.strip.inputMSB` | strip: `playposition`, left out of the debug log on purpose (M6-06) |
| b0 ch1 72 | 543 | `RaneOne.deck1.stopTimeKnob.input` | Stop Time: stored for M7, no Mixxx control |
| b0 ch1 75 | 1566 | `RaneOne.deck1.strip.inputLSB` | strip: `playposition`, left out of the debug log on purpose (M6-06) |

### 04-census-d1-pads

| messages sent | replay exit | debug lines | distinct controls changed | rows | rows logged | rows quiet | gaps | expected, not logged |
|---|---|---|---|---|---|---|---|---|
| 174 | 0 | 160 | 41 | 21 | 16 | 5 | 0 | 0 |

Logged but not set by the mapping: none.

Ten sample lines:

```
RaneOne: [Channel1],hotcue_1_activate = 1
RaneOne: [Channel1],hotcue_9_activate = 1
RaneOne: [Channel1],beatlooproll_0.0625_activate = 1
RaneOne: [Channel1],beatlooproll_2_activate = 0
RaneOne: [Channel1],beatjump_1_forward = 1
RaneOne: [Channel1],hotcue_5_activate = 1
RaneOne: [Channel1],hotcue_13_activate = 1
RaneOne: [Channel1],slip_enabled = 1
RaneOne: [Channel1],beatjump_1_backward = 1
RaneOne: [Channel1],hotcue_1_clear = 1
```

Rows with no log line (the harness changes no logged control for them either):

| row (status, channel, number) | messages | handler | why |
|---|---|---|---|
| 90 ch16 50 | 12 | `RaneOne.shift.input` | Shift: mapping state only (`RaneOne.shifted`), no Mixxx control |
| 90 ch5 0 | 6 | `RaneOne.deck1.padMode.input` | pad mode: mapping state only (D30) |
| 90 ch5 12 | 4 | `RaneOne.deck1.padMode.input` | pad mode: mapping state only (D30) |
| 90 ch5 13 | 4 | `RaneOne.deck1.padMode.input` | pad mode: mapping state only (D30) |
| 90 ch5 7 | 4 | `RaneOne.deck1.padMode.input` | pad mode: mapping state only (D30) |

### 05-census-d2-controls

| messages sent | replay exit | debug lines | distinct controls changed | rows | rows logged | rows quiet | gaps | expected, not logged |
|---|---|---|---|---|---|---|---|---|
| 6734 | 0 | 5696 | 27 | 34 | 28 | 6 | 0 | 0 |

Logged but not set by the mapping: `[Channel2],rate_ratio` (Mixxx computes it).

Ten sample lines:

```
RaneOne: [Channel2],cue_default = 1
RaneOne: [Channel2],rate_ratio = 1.1907581491881334
RaneOne: [Channel2],rate = -0.7717006470516421
RaneOne: [Channel2],rate_ratio = 1.39457941643267
RaneOne: [Channel2],rate = -0.36723232816505913
RaneOne: [Channel2],rate_ratio = 0.97210693359375
RaneOne: [Channel2],rate = 0.457763671875
RaneOne: [Channel2],rate_ratio = 0.56640625
RaneOne: [Channel2],rate = 0.7265625
RaneOne: [Channel2],rate_ratio = 0.84857177734375
```

Rows with no log line (the harness changes no logged control for them either):

| row (status, channel, number) | messages | handler | why |
|---|---|---|---|
| 90 ch16 50 | 34 | `RaneOne.shift.input` | Shift: mapping state only (`RaneOne.shifted`), no Mixxx control |
| 90 ch2 43 | 3 | `RaneOne.deck2.range.input` | Range: changes nothing (D27); pressed without Shift here |
| 90 ch6 10 | 4 | `RaneOne.deck2.slip.input` | every press here is Shift+Slip, the One's motor off: nothing in Mixxx |
| b0 ch2 43 | 1737 | `RaneOne.deck2.strip.inputMSB` | strip: `playposition`, left out of the debug log on purpose (M6-06) |
| b0 ch2 72 | 279 | `RaneOne.deck2.stopTimeKnob.input` | Stop Time: stored for M7, no Mixxx control |
| b0 ch2 75 | 1737 | `RaneOne.deck2.strip.inputLSB` | strip: `playposition`, left out of the debug log on purpose (M6-06) |

### 06-census-d2-pads

| messages sent | replay exit | debug lines | distinct controls changed | rows | rows logged | rows quiet | gaps | expected, not logged |
|---|---|---|---|---|---|---|---|---|
| 190 | 0 | 176 | 49 | 22 | 16 | 6 | 0 | 0 |

Logged but not set by the mapping: none.

Ten sample lines:

```
RaneOne: [Channel2],hotcue_1_activate = 1
RaneOne: [Channel2],hotcue_9_activate = 0
RaneOne: [Channel2],slip_enabled = 0
RaneOne: [Channel2],beatlooproll_4_activate = 0
RaneOne: [Sampler7],cue_gotoandplay = 1
RaneOne: [Channel2],beatjump_4_forward = 0
RaneOne: [Channel2],hotcue_8_activate = 1
RaneOne: [Channel2],hotcue_16_activate = 0
RaneOne: [Channel2],beatlooproll_2_activate = 0
RaneOne: [Channel2],beatjump_1_forward = 0
```

Rows with no log line (the harness changes no logged control for them either):

| row (status, channel, number) | messages | handler | why |
|---|---|---|---|
| 90 ch16 50 | 10 | `RaneOne.shift.input` | Shift: mapping state only (`RaneOne.shifted`), no Mixxx control |
| 90 ch6 0 | 6 | `RaneOne.deck2.padMode.input` | pad mode: mapping state only (D30) |
| 90 ch6 11 | 2 | `RaneOne.deck2.padMode.input` | pad mode: mapping state only (D30) |
| 90 ch6 12 | 4 | `RaneOne.deck2.padMode.input` | pad mode: mapping state only (D30) |
| 90 ch6 13 | 4 | `RaneOne.deck2.padMode.input` | pad mode: mapping state only (D30) |
| 90 ch6 7 | 4 | `RaneOne.deck2.padMode.input` | pad mode: mapping state only (D30) |

### 27-census-d1-pads-shift

| messages sent | replay exit | debug lines | distinct controls changed | rows | rows logged | rows quiet | gaps | expected, not logged |
|---|---|---|---|---|---|---|---|---|
| 80 | 0 | 64 | 32 | 13 | 8 | 5 | 0 | 0 |

Logged but not set by the mapping: none.

Ten sample lines:

```
RaneOne: [Channel1],hotcue_9_clear = 1
RaneOne: [Channel1],hotcue_12_clear = 1
RaneOne: [Channel1],hotcue_15_clear = 1
RaneOne: [Channel1],beatloop_0.125_toggle = 1
RaneOne: [Channel1],beatloop_1_toggle = 1
RaneOne: [Channel1],beatloop_8_toggle = 1
RaneOne: [Sampler3],cue_gotoandstop = 1
RaneOne: [Sampler6],cue_gotoandstop = 1
RaneOne: [Channel1],beatjump_4_backward = 1
RaneOne: [Channel1],beatjump_32_backward = 1
```

Rows with no log line (the harness changes no logged control for them either):

| row (status, channel, number) | messages | handler | why |
|---|---|---|---|
| 90 ch16 50 | 8 | `RaneOne.shift.input` | Shift: mapping state only (`RaneOne.shifted`), no Mixxx control |
| 90 ch5 11 | 2 | `RaneOne.deck1.padMode.input` | pad mode: mapping state only (D30) |
| 90 ch5 12 | 2 | `RaneOne.deck1.padMode.input` | pad mode: mapping state only (D30) |
| 90 ch5 13 | 2 | `RaneOne.deck1.padMode.input` | pad mode: mapping state only (D30) |
| 90 ch5 7 | 2 | `RaneOne.deck1.padMode.input` | pad mode: mapping state only (D30) |

### 28-census-d2-pads-shift

| messages sent | replay exit | debug lines | distinct controls changed | rows | rows logged | rows quiet | gaps | expected, not logged |
|---|---|---|---|---|---|---|---|---|
| 80 | 0 | 64 | 32 | 13 | 8 | 5 | 0 | 0 |

Logged but not set by the mapping: none.

Ten sample lines:

```
RaneOne: [Channel2],hotcue_9_clear = 1
RaneOne: [Channel2],hotcue_12_clear = 1
RaneOne: [Channel2],hotcue_15_clear = 1
RaneOne: [Channel2],beatloop_0.125_toggle = 1
RaneOne: [Channel2],beatloop_1_toggle = 1
RaneOne: [Channel2],beatloop_8_toggle = 1
RaneOne: [Sampler3],cue_gotoandstop = 1
RaneOne: [Sampler6],cue_gotoandstop = 1
RaneOne: [Channel2],beatjump_4_backward = 1
RaneOne: [Channel2],beatjump_32_backward = 1
```

Rows with no log line (the harness changes no logged control for them either):

| row (status, channel, number) | messages | handler | why |
|---|---|---|---|
| 90 ch16 50 | 8 | `RaneOne.shift.input` | Shift: mapping state only (`RaneOne.shifted`), no Mixxx control |
| 90 ch6 11 | 2 | `RaneOne.deck2.padMode.input` | pad mode: mapping state only (D30) |
| 90 ch6 12 | 2 | `RaneOne.deck2.padMode.input` | pad mode: mapping state only (D30) |
| 90 ch6 13 | 2 | `RaneOne.deck2.padMode.input` | pad mode: mapping state only (D30) |
| 90 ch6 7 | 2 | `RaneOne.deck2.padMode.input` | pad mode: mapping state only (D30) |

## D27's open items

**`rate_ratio` = 1 + rate × rateRange × rate_dir: holds exactly.** With RaneOne.DEBUG on, the pitch fader now also
connects `rate_ratio`, which Mixxx computes (test: `tests/mapping-fx.test.mjs`, "the pitch fader's rate_ratio is
connected on both decks"). Mixxx logs each `rate_ratio` line just before its `rate` line. Pairing them that way
(rateRange 0.5 set at init, `rate_dir` −1 in this profile):

| deck (take) | pairs | max error | rate −1 | rate 0 | rate +1 |
|---|---|---|---|---|---|
| 1 (03) | 2704 | 0 | rate_ratio 1.5 | 1 | 0.5 |
| 2 (05) | 2770 | 0 | rate_ratio 1.5 | 1 | 0.5 |

So Mixxx's speed at the fader's ends and centre is the motor's 1.5× / 1× / 0.5× (census 23, 24). `rate_dir` is −1
here, so the mapping writes rate −1 for 1.5×: it reads the live `rate_dir`, as D27 says.

**Does applying Preferences reset `rateRange`? Read from the source; no live click (this session can't drive the
GUI).** In Mixxx 2.5.6 `src/preferences/dialog/dlgprefdeck.cpp`, `slotApply()` calls
`setRateRangeForAllDecks(m_iRateRangePercent)`, and `m_iRateRangePercent` follows the combo box
(`slotRateRangeComboBox`). `slotUpdate()`, which runs when the dialog opens, sets the combo box from the live
`[Channel1],rateRange` (0.5 → its "50%" item). So opening Preferences and pressing Apply keeps ±50 % unless the user
picks another range. Apply also writes `RateRangePercent` = 50 to mixxx.cfg (a side effect the user may not expect).
If the user picks another range, the fader's next move rescales `rate` to the new range (D27's live-range formula),
and under 50 % the mapping logs its once-per-deck warning. Still UNVERIFIED live: one click in the dev Mixxx
(Preferences → Decks → Apply, then read `rateRange`). Nothing in the hardware path depends on it.

## M6-03's open item: ReverseRoll's write-back

Confirmed in Mixxx 2.5.6. Take 03 (deck 1, reverse on, slip off before the press):
`reverseroll 1` … on release Mixxx logs `reverse 0`, `slip_enabled 0`, `reverseroll 0`, then the mapping's
write-back `reverse 1`, `slip_enabled 0`. (The `slip_enabled 1` 150 ms later is the take's next message, ch 5
note 9, which the harness also maps to `slip_enabled`.) Take 05 (deck 2, reverse off, slip on before the press) ends `reverse 0`,
`slip_enabled 1`. The forced zeros come first and the write-back lands after them, so
`RateControl::slotReverseRollActivate` does run inside `setValue`, as M6-03 assumed.

## Step 4: stopped

```
$ tools/mixxx-dev stop
stopped 1846563878
$ tools/mixxx-dev status
stopped
```

The earlier instance (1826359931, the hot-reload try) was stopped the same way. `tools/null-sink down` then printed
`mixxx-dev down (unloaded module 536870916)`, and `status` printed `absent`.
