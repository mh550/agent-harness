<!-- fixture: rane-one-mixxx commit aa88421 path docs/decisions.md, whole file -->
# Decisions

Newest last. `*default*` = taken as the simplest reversible default, waiting for Michael to confirm.
This file is the current rule set: when a decision is overturned, the old entry is rewritten in place to the
rule that holds now, with one "(Updated in place <date>: …)" line naming what replaced it. History is in git.

- **D1 *default* · Playback model: hybrid.** Mixxx's clock plays the track while the platter is within tolerance
  of the expected speed; the platter takes over through absolute position on deviation (hand, nudge, backspin,
  stop) and hands back when it settles. Why: clean pitch when nobody touches the platter (encoder jitter and
  Mixxx's 5 ms MIDI polling would otherwise be audible), while scratching stays drift-free. The alternative,
  "the platter is the record" (Numark V7 style), is more vinyl-authentic but showed audible wobble in the Rane
  Twelve tests. (2026-10-19)
- **D2 · Target Mixxx 2.5.6 (Flatpak)**, Michael's gig install, written to upstream conventions so it can be
  PR'd to `mixxxdj/mixxx` later. (2026-10-19)
- **D3 · Separate Mixxx dev profile** at `~/.var/app/org.mixxx.Mixxx/dev-profile/` via `--settings-path`. The
  real profile (`.mixxx/`) holds the gig library and is never touched. (2026-10-19)
- **D4 · Outbound MIDI to the Rane One only through `tools/midi-send`, and only while `~/.rane-armed` exists.**
  Shipping motor/LED/display output in the mapping stays out of v1. (Updated in place 2026-10-21: the original
  "no outbound MIDI in v1" was lifted by D13 on 2026-10-20.) Whether the host can command the motor at all is unknown (the manual suggests the One
  runs its motor itself: Play starts/stops the platter, Stop Time knob, rear torque switch). (2026-10-19)
- **D5 · Node 24, zero npm dependencies** for tools and tests; Mixxx-side JS is plain script for QJSEngine with a
  pure platter core shared with Node tests. (2026-10-19)
- **D6 · Captures are the ground truth.** Every MIDI fact cites a file in `captures/`; anything else is
  `UNVERIFIED`. The MK2 djay map is a hint only (Michael's unit is an MK1). (2026-10-19)
- **D7 · Unattended audio goes to a PipeWire null sink**, never to the Rane One or speakers, and the system
  default sink is never changed. (2026-10-19)
- **D8 · `rea` and Serato reverse engineering are a later phase**, starting with a USB capture of Serato driving
  the One on Michael's Windows laptop; decompiling Serato only as a last resort, and only protocol facts (never
  code) go into this repo. (2026-10-19)
- **D9 *default* · Dev-loop safety: null sink, routing, instance tracking, port binding.** Mixxx's audio goes
  to a PipeWire null sink named `mixxx-dev` (48 kHz, 2 ch, `pactl load-module module-null-sink`), created and
  removed by `tools/null-sink`, which unloads only the module id it loaded and never changes the default sink.
  `tools/null-sink down` refuses while a stream is on the sink (PipeWire would move it to the default sink, the
  Rane One). Routing: `flatpak run --env=PULSE_SINK=mixxx-dev` (PortAudio ALSA `pulse` device, in a
  `soundconfig.xml` the launcher rewrites before every start), the stream named `mixxx-dev` via
  `PULSE_PROP_OVERRIDE`, checked after every launch with `pactl list sink-inputs`; on a mismatch the launcher
  stops its Mixxx at once. A dev Mixxx is tracked by
  the Flatpak instance id that `flatpak run --instance-id-fd` writes to `dev-profile/mixxx-dev.instance`, and
  stopped with `flatpak kill <that id>`, never `flatpak kill org.mixxx.Mixxx` (this is how "stop it by its pid"
  is met: the id maps to the wrapper pid in `flatpak ps`). The launch adds
  `--log-flush-level debug` to the CLAUDE.md command, because the stop is a hard kill (Mixxx 2.5 has no
  SIGTERM handler) and the log must not lose its tail. The dev profile binds the mapping to
  `Midi Through Port-0`, and also to the real `Rane ONE` port when a test needs it (D13); the shipped mapping
  has no `<output>` and no `midi.send*`. (Updated in place 2026-10-21: the original night-time rule, "Midi
  Through only until Michael says otherwise", was superseded by D13 on 2026-10-20.) Why: the system default sink is the Rane One, so unrouted audio would
  play from the controller; an id from `--instance-id-fd` cannot be confused with a Mixxx Michael started.
  Plan: `docs/plans/2026-10-19-M1-dev-loop.md`. (2026-10-19)
- **D10 *default* · The dev launcher's "Mixxx started" check reads the version from Mixxx's stdout, not
  `mixxx.log`.** Mixxx 2.5.6 logs its version only through `qDebug()` in the default category
  (`src/util/versionstore.cpp`, `logBuildDetails`). Under `--controller-debug`, which the CLAUDE.md launch
  command requires, `controllerDebugCategoryFilter` (`src/util/logging.cpp`) turns Debug off for every category
  except `controller.*` and `js`, so no version line ever reaches `mixxx.log`. Seen live 2026-10-19 (M1-04): two
  launches, one with `--log-level debug` added, and both logs held only Info and Warning lines. `tools/mixxx-dev
  start` therefore treats Mixxx as started when two things hold: a new `mixxx.log` (new inode, non-empty), and the
  exact line `Configuration file is at the current version "<flatpak info version>"` on this launch's stdout
  (`dev-profile/mixxx-dev.stdout`, truncated at every launch). `src/preferences/upgrade.cpp` prints that line
  with the running binary's `VersionStore::version()` once `mixxx.cfg`'s `Version` matches it, which the seed
  makes sure of. That line never reaches `mixxx.log` either: the `CoreServices` constructor runs
  `initializeSettings()` (the upgrade) before `initializeLogging()` (re-checked on the `2.5.6` tag, M1-04 retry). Why: it is the only place the running version shows, without dropping `--controller-debug`.
  The same session also found that a new PipeWire stream briefly reports `Sink: 4294967295` (not linked yet).
  The routing check counts such a stream as neither routed nor misrouted. (2026-10-19)
- **D11 *default* · Telemetry format for drift.** One JSON object per line in `dev-profile/telemetry.jsonl`, with
  the required keys `t_us` (host µs, non-decreasing), `ticks` (unwrapped encoder ticks), `timer` (unwrapped
  controller timestamp counter), `playposition` (Mixxx's, nominally 0..1), `rate_ratio` (the platter speed
  ratio the core estimated) and `mode` (`clock`|`platter`), plus the optional `deck` (1|2, default 1) and
  `duration` (track seconds). Readers ignore unknown keys, reject a missing key naming the line, and clamp a
  backward `t_us` (wall clock) with a warning. Mixxx scripts can't write
  files (no file API in the 2.5 `engine-api.d.ts`), so M7 logs `RaneOne telemetry <json>` through
  `console.log`, at most 20 Hz per deck, and a host step extracts those lines from `mixxx.log` into the file.
  Why: `tools/drift` (M3) and the mapping (M7) can then be built independently; JSONL matches the M2 capture
  files. Plan: `docs/plans/2026-10-19-M3-measurement.md` § Telemetry format. (2026-10-19)
- **D12 *default* · How "wow & flutter" in spec §3 is measured.** Unweighted, in percent of the mean frequency, by
  `tools/wow-flutter`: rising zero crossings with linear interpolation, per-cycle frequency, then a high-pass
  with its passband from 0.5 Hz (a 2nd-order Butterworth with its corner at 0.2 Hz, run zero-phase; net gain 0.975
  at 0.5 Hz). The target (≤ 0.1 %) applies to the **peak** deviation; RMS and the worst 1-s window are reported
  too. Dropouts are counted separately, not as flutter, and a measurement for §3 needs `dropouts 0` (the peak
  leaves them out; the tool warns). A run of ≥ 3 full-level cycles off the same way is a speed change, so it is
  flutter, not a dropout; statistics skip 2 s at each end (filter ringing), down to 1 s for short tones (M3
  review #1, #2, 2026-10-21). Why: a corner at 0.5 Hz itself halves a 0.5 Hz wow when
  run zero-phase (prototype: 0.252 % for a 0.5 % tone), which would let slow motor wobble pass unseen and fails
  M3-03's 0.5 Hz test. Plan: `docs/plans/2026-10-19-M3-measurement.md` § wow-flutter algorithm. (2026-10-19)
- **D13 · Sending to the Rane One is allowed, armed standing (Michael, 2026-10-20).** Lifted D4's "no
  outbound MIDI" as a safety rule and D9's night-time port rule (both updated in place 2026-10-21): the One has nothing plugged into it and is not
  in use, so a session may send to it through `tools/midi-send` and may bind the dev profile's mapping to the
  real `Rane ONE` port as well as `Midi Through Port-0` when that helps a test. `~/.rane-armed` stays the switch:
  Michael created it and leaves it in place; when it is gone, nothing is sent. Still out of scope (D4 scope part):
  shipping motor/LED/display output in the mapping. Replays still go through `Midi Through` so they stay
  repeatable. Guard: send only messages traceable to a capture, Mixxx's docs or the MK2 djay map, never SysEx,
  and log every send in progress. Audio rules (D7, D9 null sink) are unchanged: the measurements read the null
  sink. (2026-10-20)
- **D14 *default* · Capture backend: `tools/capture` reads the rawmidi device read-only.** It resolves the port
  by name from `amidi -l` (`--port 'Rane ONE MIDI 1'` → `hw:C,D,0` → `/dev/snd/midiC<C>D<D>`, resolved on every
  run because card numbers change on replug). A child process opens the device with `fs.openSync(path, "r")`
  (O_RDONLY) and stamps each `read()` with `process.hrtime`. The output is the M2 JSONL format (`t_us`, `bytes`,
  `type`, `ch`, `d1`, `d2`, `value`). `--device <path>` skips the lookup, for tests (a FIFO). The manual fallback is
  `arecordmidi -p 'Rane ONE' -b 60 -t 1000` (1 ms ticks, the header of `captures/2026-10-19-quick/platter.mid`)
  plus `tools/capture-convert`. Why: zero dependencies, µs host stamps rather than arecordmidi's 1 ms ticks, and
  a read-only fd can't send anything. The child exists because `process.exit()` hung while a worker thread was
  blocked reading the One's rawmidi device, and a SIGTERM to a child ends a blocked read or open (seen
  2026-10-20). A busy port (Mixxx, aseqdump) makes a blocking open wait indefinitely, so after 2 s capture exits 5
  and says who to close. The feature list's M2-01 step 3 names this decision D10, which was already taken.
  Plan: `docs/plans/2026-10-19-M2-capture-replay.md` § Capture backend. (2026-10-20)
- **D15 *default* · The capture session keeps spec §6 whole and its time estimates honest**, rather than squeezing
  them to fit the 25 min that M2-06 step 2 and M2-07 step 1 ask for. The plan's per-step estimates come to 28.15 min
  of recording plus about 5 min of setup. Most of it is the census: every pad in every pad mode with and without
  Shift, and every button held 1 s with and without Shift. Why: estimates squeezed to fit 25 would mislead Michael
  at the controller, and dropping §6 content loses census rows M6 needs. D17 says how the session fits under 25 min
  anyway. Plan: `docs/plans/2026-10-19-M2-capture-replay.md` § Capture session. (2026-10-20)
  (Updated in place 2026-10-25: the single ≈ 28 min session and its two suggested cuts gave way to D17's 24.75 min
  of §6 plus optional extras on 2026-10-21.)
- **D16 *default* · `tools/capture-convert` accepts divided SysEx and refuses dropped bytes.** The M2 plan said an
  F0 event must make exactly one message. SMF 1.0 lets a long SysEx be split into an F0 packet without F7 plus F7
  continuations, and arecordmidi is believed to write long SysEx that way (UNVERIFIED: no SysEx from the One
  seen yet). So only a channel event or a complete `F0 … F7` must end in its own message. An F0 packet or an F7
  event may make any number, a SysEx still open at the end is written truncated, and `readSmf` flags F7 events
  `escape: true`. Bytes the parser can't place in any message make the conversion fail (exit 1, no file) unless
  `--allow-dropped`, because `bytes` is the ground truth and the JSONL can't show them. `--force` replaces the
  output through a temp file and rename; without it, an existing output identical to the conversion is a no-op
  (exit 0), so the step command re-runs on a committed file. Found by the M2-02 review. (2026-10-20)
- **D17 *default* · The capture session is 24.75 min of §6 steps, plus 4.4 min of optional extras at the end.**
  M2-06 step 2 (and M2-07 step 1) still say "under 25 minutes", and D15's two cuts only reach 25.15. Estimates are
  kept honest (D15) and no §6 content is dropped. Eight recordings move to the end of the session as extras that
  `tools/capture-session` offers after §6.7, each skippable with `s`: deck pads with Shift in every mode but the
  first (deck 1 and 2, 1.1 min each), and deck 2's fast and other-mode hand turns, motor hold, backspin and both
  Stop Time stops (2.2 min). Why these: deck 1 covers each behaviour in the main session, deck 2's channel and
  rates are still in it (slow, ten turns, touch, 33, 45, pitch), and the Shift pattern on pads shows in one mode.
  The main pad steps grew from 2.0 to 1.4 + 1.1 min, because 2.0 was under the 128 presses it asked for. `--list`
  prints the 7 groups (24.75 min), then the extras (4.40 min). To undo it: set `extra: false` on those steps in
  `tools/lib/capture-session.mjs` (the total goes to 29.15 min) and change the cap in the two steps. Plan:
  `docs/plans/2026-10-19-M2-capture-replay.md` § Capture session. (2026-10-21)
- **D18 *default* · `tools/null-sink` gives `mixxx-dev` the `object.path` `mixxx-dev.monitor`, so `tools/record-output`
  calls `pw-record --target mixxx-dev.monitor --rate 48000 --format s32 --channels 2 -P stream.capture.sink=true`.**
  WirePlumber 0.5.12 links the first input-direction node (a sink, or another capture stream) whose `node.name` or
  `object.path` equals a named target (`find-defined-target.lua`), and `mixxx-dev.monitor` is otherwise a name only Pulse clients see. Seen live
  2026-10-21: on a plain null sink, `pw-record --target mixxx-dev.monitor … -P node.dont-fallback=true` printed
  "defined target not found", exited 1 and left a 44-byte header-only WAV. With `object.path=mixxx-dev.monitor` in
  the module's `sink_properties` (default sink and source unchanged), the same `--target` plus
  `-P stream.capture.sink=true` linked `mixxx-dev:monitor_FL/FR` to it, nothing from any `alsa_input`, and wrote
  96000 frames for `--sample-count 96000` (COUNT is frames); a 1 kHz tone played into `mixxx-dev` read 1000.000 Hz,
  peak 0.0000 %, -6.00 dBFS. `pw-record` 1.6.8 also exits 1 after a complete recording, so the tool judges the WAV
  it wrote (exact frame count, 48000 Hz, 2 ch, pcm32), never the exit code. Because pw-record also reads `auto` as
  the default sink and a number as an `object.serial` (looked up with no sink check), the sink name must be plain
  (`[A-Za-z][A-Za-z0-9_-]*`, not `auto`, no `rane`/`alsa_`/`bluez_`); `pactl -f json list sinks` must show exactly
  one sink by that name, as `support.null-audio-sink`, with `object.path` `<sink>.monitor`, and no other sink
  named or pathed `<sink>.monitor`, nor any recording stream in `pactl -f json list source-outputs` (WirePlumber
  could pick either first; one that appears between that check and the link isn't seen). A `mixxx-dev` made before this lacks the
  path: the tool exits 1 and says to run `tools/null-sink down && tools/null-sink up`. The stream also gets
  `node.dont-move=true`, so a later move can't relink it. This replaced the first form of D18 (same day), which
  sent `--target mixxx-dev -P stream.capture.sink=true`; it recorded the same monitor but didn't match M3-05 step 1
  (`--target mixxx-dev.monitor`), so the M3 verify failed it. To undo: drop `object.path` from `tools/null-sink`
  and pass `--target <sink>` in `tools/record-output` (the first form). Plan: `docs/plans/2026-10-19-M3-measurement.md`
  § record-output. (2026-10-21)
- **D19 · Capture wins (D6): the One's platter format, from `captures/2026-10-19-quick/platter.jsonl`.** Where the
  capture contradicts `docs/research/2026-10-19-prior-art.md` §2 (the Twelve/V7 hypothesis), the M4 core follows the
  capture. Measured with `tools/analyze-platter`; every number, phase and the command are in
  `docs/research/2026-10-19-quick-capture-analysis.md`.
  - **CC 6 is a 7-bit running tick counter (mod 128), not sector + position.** It wraps 127 → 0 continuously (3600
    is not a multiple of 128); there are no 28 sectors. It is signed by direction: +1 per message by hand forward
    (3,536 of 3,552, 2–8 s), −1 backward (3,610 of 3,647, 9–15 s), and +2 per message with the motor on (15,679 of
    15,972, 20–36 s), because the One sends at most about one CC 6 + pitch-bend pair per millisecond (998–999/s)
    and folds the ticks in between into it (up to +4 seen).
  - **The timestamp clock is 2,822,400 Hz and 3600 ticks/rev hold within 0.1 %, at an assumed exact 33⅓.** The
    pitch bend is a 14-bit timestamp that rises even when the ticks fall (9–15 s). 20–36 s: 2,822,469 timer counts
    per host second (+0.002 %; this needs no rpm), and 31,984 ticks in 16 s = 3598.2 ticks/rev if the motor turned
    at exactly 33⅓ (−0.05 %; 1411.9 timer counts per tick against 1411.2 is the same figure restated). 3600 against
    the hypothesis's 3584 (28 × 128, a motor 0.4 % fast) is UNVERIFIED until a mark-to-mark count (spec §6 step 3).
    The counter spans 5.805 ms; a longer gap arrives as −1 (or −2), UNVERIFIED as a saturation marker. So the
    timestamp can time ticks only above 1 / 5.805 ms = 172 ticks/s, 0.086 of 33⅓ at one tick per message: the
    prior art's 0.05 × low-speed limit (§5 "Low speed") is too low for the One.
  - **Note 0 on channel 1 is a button press (UNVERIFIED which), not a touch sensor.** It came twice (19.236 s for
    95 ms, 44.670 s for 110 ms), each just before the motor started or stopped: Play is the guess.
  - **No touch message was seen.** A 3 s hold (38–41 s) and the hand turns sent only CC 6 and pitch bend, so the
    core infers a touch from speed. The hold sends ≈ 16 pairs/s with CC 6 dithering ±1 and the timestamp falling by
    1 per pair; that pattern and its M5 checks are in the analysis document.
  The feature list's M4-01 step 4 names this decision D12, which was already taken (D12 is the wow & flutter
  measurement). Why: CLAUDE.md and D6, a capture beats the research notes. To undo: none needed; a later capture
  that contradicts this one wins in turn and amends this entry. (2026-10-21)
- **D20 *default* · The M4 platter core's API, constants and rules are those of `docs/plans/2026-10-19-M4-platter-core.md`,
  except its speed gate, which D23 replaced.** The capture fact the gate rested on still holds, and D23 relies on it:
  the One's timestamp covers only 5.805 ms (16384 / 2,822,400 Hz) and sends −1/−2 for any longer gap, so a tick can be
  timed only above 172.3 ticks/s, which is 0.086 of 33⅓ (0.064 of 45) at one tick per message
  (`captures/2026-10-19-quick/platter.jsonl`, analysis document). The rest of the plan's defaults:
  - The decoder reads the timestamp unsigned, and unsigned deltas ≥ 16382 count as saturation markers adding −1/−2,
    so 0 → 16383 still adds −1 as M4-03 step 2 asks.
  - `update` takes `ticks` and returns `position`, which M4-06 step 3 needs.
  - Control leaves the clock beyond ±3 % for 10 ms and returns within ±1 % held for 150 ms.
  - A motor stop (expectedRatio → 0) spins down under platter control.
  - `backspin` needs the motor on. With it off, a fast backward hand turn stays `scratching`: the capture reaches
    −0.6 by hand at 9.4–9.8 s.
  - A heartbeat moves the ratio only after `STALL_MS` 50 of silence, so a host-side MIDI stall under about 60 ms
    can't take control from the clock. A longer one does take over (a stall-made `held`); D24 keeps its burst from
    moving the track twice (corrected in the M4-08 review, #8).
  - The switch-over snapshot is keyed to the change in `control`, not to particular transitions.
  - `TIMER_GAP_MAX_US` is 20 ms, `STOPPED_RATIO` 0.03 and `MOVE_RATIO` 0.05.

  Every tuning value is UNVERIFIED and listed with its source in the plan's Constants table. M4-05's filter choice
  becomes D22, because its step 2 names D13, which is taken (D21 went to M4-03's host-clock rule). To undo: edit the
  plan's Constants table and `RaneOnePlatter.DEFAULTS` together. (2026-10-21)
  (Updated in place 2026-10-25: the gate itself, `MIN_TIMED_SPEED_RATIO` 0.1 with re-entry at 0.125 in place of M4-02
  step 2's 0.05, was dropped by D23 on 2026-10-21. The constant is gone from `DEFAULTS`, and so is the question to
  Michael about 0.1.)

- **D21 *default* · The platter decoder absorbs a host clock that steps backwards instead of rejecting messages.**
  The M4 plan had a decreasing `hostTimeUs` count as malformed. M7's glue passes `Date.now() * 1000`, a wall clock
  that can step back (NTP, suspend/resume, a manual change), and the M4-03 review showed that a 1 s step back then
  drops every platter message for 1 s, live. `createDecoder` now adds the step to an internal offset, so its host
  time carries on from the last value, and counts it in `stats().clockSteps` (test: "a host clock stepping
  backwards is absorbed" in `tests/platter-decoder.test.mjs`). No capture involved; host-side only. To undo:
  make `hostTime()` in `mapping/rane-one-platter.js` return null when `t < lastHostUs`. Michael: OK, or would you
  rather the glue find a monotonic clock in Mixxx's QJSEngine (UNVERIFIED that one exists)? (2026-10-21)

- **D22 *default* · The speed estimator's filter is the 1-Euro filter (min cutoff 1 Hz, beta 10, derivative cutoff
  20 Hz) on the per-message timed speed, not α-β.** M4-05 step 2 names this decision D13, which is taken (D13 is the
  standing permission to send to the One), so it is D22. Both candidates were grid-searched on synthetic
  `constant33` + `step` only (fastest settle to ±0.01 whose constant33 peak stays within 0.001, half the ±0.002
  acceptance), then measured unseen on the other scripts and the real capture (`node tests/helpers/filter-bench.mjs`;
  table in the M4 plan, Filter choice). The plan's pick rule is the smaller scratch lag, α-β on a tie within 1 ms:
  1-Euro 2 ms against α-β (α 0.5, β 0.1) 5.5 ms. 1-Euro is also ahead on settle after a step (3 vs 14 ms), steady
  peak (0.00038 vs 0.00074) and the real motor phase 20–36 s (peak |r − 1| 0.0036 vs 0.0047,
  `captures/2026-10-19-quick/platter.jsonl`). Both pass every acceptance test. The parameters are tuned on synthetic
  data whose fast timer noise is about 4.8× the One's, so they are UNVERIFIED on other decks, speeds and torque
  settings (M5). Why it matters little: 1-Euro with these values follows the device timestamps nearly raw, and the
  capture's raw per-message ratio already stays within 0.9945–1.0041. To undo: set `FILTER: "alpha-beta"` in
  `RaneOnePlatter.DEFAULTS` (its tuned values are kept there). Michael: OK with 1-Euro, or do you prefer α-β
  because Mixxx's own scratch filter is α-β, at 3.5 ms more lag? (2026-10-21)
- **D23 *default* · The estimator times every valid timer delta, however slow; host time only covers samples with no
  device time, and a saturation marker bounds the speed.** This replaces the plan's (and D20's) rule of falling
  back to host time whenever the filtered |ratio| drops under `MIN_TIMED_SPEED_RATIO` 0.1 and resuming at 0.125,
  and `MIN_TIMED_SPEED_RATIO` is gone from `DEFAULTS`. Why: with that rule, every scratch reversal crosses 0.1, and
  the 200 ms host window then reads the last 200 ms of the stroke: about 0.9 at the turn of the synthetic scratch
  (200 ticks, 0.5 s period), true ratio 0. The bench measured a scratch peak error of 1.02–1.22 with that rule
  (first run, before the final tuning), from the 15–16 untimed samples at the reversals. A −0.9 there would fire the plan's T1 (backspin when
  `r < −0.5` with the motor on, at once). D20's reason for the limit doesn't need it: the device only sends a
  valid delta when its ticks are under 5.8 ms apart, so below 0.086 of 33⅓ every delta is a marker and goes to
  host time anyway (capture, D20). The rules now (as fixed after the M4-05 review):
  - A valid delta is always timed. After any untimed sample the filter re-seeds from that delta.
  - A saturation marker, whatever the host gap, reads the host-time ratio clamped between 0 and the smaller of
    `dTicks · TIMER_PER_TICK / TIMER_MARKER_MIN` (0.086 per tick) and `dTicks` over the host time since the
    previous timed-or-marker sample, in the ticks' direction. The device saw at least 5.8 ms since its last tick,
    so the speed over the span can't be more. That reading of 16382/16383 is the decoder's, UNVERIFIED (M5
    check 2).
  - The decoder now flags a sample whose −1 comes from a host gap or an unwrap error (`untrusted: true`), so it is
    no longer mistaken for a marker. Such a sample keeps the timed ratio within `STALL_MS` of the last timed
    sample (the first of a host-side burst), as heartbeats do, and otherwise reads the host-time window. A lost
    pitch bend within `TIMER_GAP_MAX_US` of the last timed sample keeps the timed ratio too.
  - A heartbeat after `STALL_MS` reads the window clamped to one tick in the silence since the last sample.
  The review's first version held the timed ratio on any marker after a 20 ms gap. That froze a creep or a held
  record at its last timed speed, because the capture's hold sends markers 20–90 ms apart. Unclamped heartbeats
  also read −0.99 after a back-cue and a dead stop. Both now have tests. With these rules, the scratch's peak
  error is 0.095 with 8 untimed samples and no false backspin (heartbeats included). On the real capture the
  estimator gives 3–7 s +0.24 to +0.54 (all timed), 10–14 s −0.45 to −0.23, 20–36 s 0.996–1.003, hold 38.5–40.5 s
  within −0.012 to 0.022, and stopped tail 46–48 s within −0.018 to 0.005. Tests: "every valid timer delta is
  timed…", "a marker … bounds the speed…", "after timed motion, a creep…", "a back-cue then a dead stop…" and
  "a scratch … nothing below −0.5…" in `tests/platter-speed.test.mjs`. To undo: restore the 0.1/0.125 gate in
  `createSpeedEstimator` (git history of M4-05) and drop the marker clamp. Michael: OK to drop the speed gate? It
  goes against the M4 plan as written, and D20's 0.1 question no longer applies. (2026-10-21)
- **D24 *default* · After a host-side MIDI stall at speed, the burst's ticks don't move the track a second time.**
  The plan's switch-over pairs the clock's position with the takeover update's ticks. After a stall those ticks are
  stale. The estimator reads about 0 after `STALL_MS` (M4-05's known stall-made `held`), and T7 takes over while
  the clock has already played the stall at speed. The burst then reports that same motion again. Measured on
  synthetic stalls at 1.0 with the plan's rule: 60–80 ms stalls left the track **116–162 ticks (58–81 ms) ahead**
  of the untouched clock, and the skip landed when the burst arrived. What D24 does:
  - **Arming.** It applies to a takeover from `motor_at_speed` that comes `STALL_MS` or more after the last tick
    change. Any other takeover absorbs nothing.
  - **Confirmation.** The first tick change after the takeover decides. If that sample is the decoder's
    `untrusted` one (a host gap of more than 20 ms while the device still timed its ticks under 5.8 ms apart), it
    was a stall. The next forward ticks are then absorbed, up to the clock's advance since the last tick. If T7
    fires on that untrusted sample itself, the ticks the sample carries are taken off the advance.
  - **Dead hand stop.** A dead stop with no dither ends with a saturation marker instead (the device saw no tick),
    so it absorbs nothing and the track follows the record at once. The first version absorbed about 160 ticks
    there, a 126 ms dead zone on release (Opus review of M4-06, Important).
  - **Only the burst.** What has been absorbed `BURST_MS` (20 ms, **UNVERIFIED**) after the confirming sample is
    final. If a hand slowed the record during the stall, the burst carries fewer ticks than the clock played, and
    the motion after it still moves the track (review round 2). That motion waits at most `BURST_MS`. Amended in
    the M4-08 review (#3): the window was `PAIR_WINDOW_US` (2 ms). The synth delivers a backlog at one host time,
    but a backlog handed over one message after another (50 µs each, on a 1 ms clock) skipped 100 ticks (50 ms)
    after an 80 ms stall. With 20 ms it skips 0 at 20–100 µs per message and 80–200 ms stalls. How Mixxx really
    delivers a backlog is M7's to measure.
  - Backward motion always counts. Position never steps, it only waits.
  - `update` takes an optional `untrusted`, and only `true` counts. Without it, D24 never confirms, and the plan's
    rule applies.

  Tests are in `tests/platter-state.test.mjs` ("D24 …"). The 40–150 ms stall sweep ends within 3 ticks of the
  clock. The dead-stop synth absorbs 0. A first tick that isn't untrusted absorbs 0. So does T5a. Where D24
  absorbs, the handback position is the plan's integrated platter position minus the absorbed ticks.
  Two UNVERIFIED dependencies:
  - **The saturation reading of 16382/16383 (M5 check 2).** Under the Twelve wrap hypothesis (synth
    `saturate: false`), a dead stop's release reads `untrusted`, and D24 would bring back the 126 ms dead zone.
    The capture favours saturation (16383 ×274, no delta above 16,304).
  - **How Mixxx delivers a stalled backlog (M7).** If it keeps the original timestamps, no host gap exceeds
    20 ms, nothing is untrusted and D24 never confirms. That is safe, and the plan's rule and its skip apply. To undo: drop `armed`/`absorb` from `createStateMachine` and the `untrusted` input. Michael: keep it, or take
  the plan's rule and the up-to-81 ms skip per stall? (2026-10-21)
