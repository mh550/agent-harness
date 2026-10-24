## 2026-10-24 00:27
Build-only run: milestones M5 (Truth) and then M6 (Non-platter mapping) of docs/spec.md §5, in that order, and nothing else. Do not start M7 (no platter wiring into Mixxx).

Base: this run starts from origin/harness/rane-one-mixxx-2026-10-19, which holds Michael's full capture session `captures/2026-10-23-census/` (34 takes: the 26 §6 steps plus the 8 extras; per-step notes in its README.md). main does not have the captures yet.

## Michael's answers (2026-10-24, after the session)
1. Shift+Slip turns on the One's "motor off" mode: the platter stops / does not spin when Play/Stop is pressed. Shift+Slip again turns it off and the platter spins again (take 25).
2. Yes, there is a strip search (take 26).
3. The ten turns ended on the mark, mostly (his take notes have the specifics; on deck 1 he steadied the platter onto the mark at the end).
4. No deck 1 creep seen.
5. Playback model: hybrid. D1 is settled (update it in place, no longer *default*). New requirement: the threshold between motor (Mixxx clock) and digital (platter) control must be configurable, so Michael can tune what feels right: at least the takeover and handback tolerances (now ±3 % / ±1 %) and the related timers. Record this as a decision; make sure those values are config in the core (they should already be named DEFAULTS); add "expose them as user settings in Mixxx's controller preferences (2.5's mapping `<settings>`, check the 2.5 branch supports it)" to spec §5 M7. Don't build M7.
6. Nothing from Serato he'd change.

## Facts from the session to handle with care (each still needs its capture citation)
- Setup for the whole session: Stop Time knob at 12 o'clock on both decks, motor torque switch LOW. Torque HIGH was not captured.
- The MK1 has no hardware 33/45 switch: 45 rpm is set in Serato's software. Takes 16 and 22 are not 45 rpm takes; don't treat them as data. 45 rpm in Mixxx would need the host to command the motor: record that as an open question. Do not send anything to try it (no SysEx, nothing firmware-shaped; the D13 rules stand).
- Deck 1's reverse mode (toggled by a deck pad, not the contour reverse switch) was ON for deck 1's motor takes before take 18, and Michael turned it off at take 18. Measured: take 15 net -126,082 counts in 65 s, deck 2's take 21 net +125,540, take 17 net -18,517. Use 15 and 17 as mirrored-direction data; check whether the reverse pad itself sends MIDI.
- Ten turns: take 09 (deck 1) net +36,008 counts, take 13 (deck 2) net +35,987. Settle ticks-per-revolution from these.
- The pitch fader changes the platter motor's speed directly (takes 23, 24; three sweeps each, Range pressed between sweeps). Michael saw no platter difference between Range settings. Find out from the captures whether Range sends MIDI and what platter speed each end of the fader gives at each Range. Mixxx's expected speed (rate_ratio and its range) must match what the motor actually does, or hybrid playback fights the platter: this is a key M5 answer.
- Touch takes 10/14 were five taps on the vinyl top (12 and 6 messages): check whether any of them is a touch message.
- Census gaps, not to stop for: FX section not recorded with Shift; Play omitted from census takes 03/05 (it is in the motor takes); Michael doesn't know what deck/layer buttons are (the MK1 may have none); the deck contour section (a slow-fast knob and per-deck reverse switches) was not touched. Take 02's note describes the FX paddles (lever, locks in the up position), FX1-6 buttons, a depth knob, an endless beat knob and a tap button.
- Write every gap and anything M5/M6 can't answer from captures into HARDWARE-TESTS.md as a short "round 2" session (exact steps, under 15 min), and ask for it in progress. Carry on with what the captures do answer.

## What done looks like
- M5: spec §5 M5's answers and its 7 open questions, each answered from a cited take or marked UNVERIFIED with the reason; decoder/estimator/state-machine constants corrected test-first where the captures disagree; `tools/census` writes `reference/rane-one-mk1-midi-map.csv` and the MK2 diff; `tools/platter-run` over every platter take on both decks with the glitch count (control flips under 20 ms) reported per take.
- M6: every control in the MK1 map wired in the mapping per spec §5 M6 and CLAUDE.md (Components JS, soft takeover, handlers never throw, no outputs), and a replayed census through Midi Through drives the right Mixxx controls, checked in the dev Mixxx log.

## Rules for this run
Michael is asleep: a new question gets the simplest reversible default, recorded as D<n> *default* in docs/decisions.md with the next free number, and the run carries on. The other existing *default* decisions stand. MERGE_POLICY is the pr default: open PRs, merge nothing.
