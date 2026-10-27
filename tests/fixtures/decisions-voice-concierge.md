# Decisions

## D7 *default*: turn detection is silero VAD only (2026-10-20, C1-01)

**Finding.** B1 leaves the builder a choice between LiveKit's turn-detector model and VAD-only turn detection. In the

## D8 *default*: a per-fact `forget` leaves the turn's text in the journal (2026-10-20, C2-01)

**Finding.** Spec §4.2 puts turn text in the journal (`user_turn`, and `agent_turn` with the heard text), and §4.0
