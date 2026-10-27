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
