<!-- fixture: rane-one-mixxx commit aa88421^ path docs/decisions.md, lines 1-6, 30-47, 103-119 (line 110 is fixture line 33) -->
# Decisions

Newest last. `*default*` = taken as the simplest reversible default, waiting for Michael to confirm.
This file is the current rule set: when a decision is overturned, the old entry is rewritten in place to the
rule that holds now, with one "(Updated in place <date>: …)" line naming what replaced it. History is in git.

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
- **D15 *default* · The capture session keeps spec §6 whole and is timed honestly at ≈ 28 min**, over the 25 min
  that M2-06 step 2 and M2-07 step 1 ask for. The plan's per-step estimates come to 28.15 min of recording plus
  about 5 min of setup. Most of it is the census: every pad in every pad mode with and without Shift, and every
  button held 1 s with and without Shift. Why: estimates squeezed to fit 25 would mislead Michael at the
  controller, and dropping §6 content loses census rows M6 needs. If Michael wants 25: pads with Shift in one mode
  only (−2 min), and the 45 step at 30 s (−1 min). Plan: `docs/plans/2026-10-19-M2-capture-replay.md` § Capture
  session. (2026-10-20)
  **Superseded in part by D17** (2026-10-21): the timing stays honest, but some recordings became optional extras.
- **D16 *default* · `tools/capture-convert` accepts divided SysEx and refuses dropped bytes.** The M2 plan said an
  F0 event must make exactly one message. SMF 1.0 lets a long SysEx be split into an F0 packet without F7 plus F7
  continuations, and arecordmidi is believed to write long SysEx that way (UNVERIFIED: no SysEx from the One
  seen yet). So only a channel event or a complete `F0 … F7` must end in its own message. An F0 packet or an F7
  event may make any number, a SysEx still open at the end is written truncated, and `readSmf` flags F7 events
  `escape: true`. Bytes the parser can't place in any message make the conversion fail (exit 1, no file) unless
  `--allow-dropped`, because `bytes` is the ground truth and the JSONL can't show them. `--force` replaces the
  output through a temp file and rename; without it, an existing output identical to the conversion is a no-op
  (exit 0), so the step command re-runs on a committed file. Found by the M2-02 review. (2026-10-20)
