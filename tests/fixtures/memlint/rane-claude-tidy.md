<!-- fixture: rane-one-mixxx commit 3d7abc9 path CLAUDE.md, whole file -->
# rane-one-mixxx

A Mixxx controller mapping for the **Rane One (MK1)** with its motorized 7" platters, built for Michael's own
live DJ use on Mixxx 2.5.6 (Flatpak), and written to upstream standards so it can go to `mixxxdj/mixxx` later.
**Accuracy beats features**: this will be played at live events. Nothing is live yet.

## Hardware facts (verified 2026-10-19 on Michael's desktop)
- USB `1cc5:0022` "Rane ONE", class-compliant on Linux (`snd-usb-audio`; the kernel logs "falling back to MIDI 1.0").
- MIDI: one port, rawmidi `hw:<card>,0,0` "Rane ONE MIDI 1", ALSA sequencer client "Rane ONE". **Card and client
  numbers change on replug: always resolve by name** (`amidi -l`, `aconnect -l`).
- Audio: 4 playback channels (Main = 1–2, Cue = 3–4), 6 capture channels, S32_LE/24-bit, **48 kHz only**.
- After power-on, the first port open delivered a burst of Note-offs (channels 0, 4, 8, 9, 15) once; a second
  listen got nothing. Probably a buffered state dump. Unverified beyond that one observation.
- Everything else about the protocol is UNVERIFIED until a capture in `captures/` shows it.

## Hardware and Mixxx rules (binding on every session)
- **Sending to the Rane One is allowed while `~/.rane-armed` exists** (D13: Michael armed it standing on
  2026-10-20; nothing is plugged into the One and it is not in use, so sending is useful for tests). All outbound MIDI
  still goes through `tools/midi-send`; never bypass it (no amidi/aplaymidi/python-rtmidi/mido writes of your own).
  If the file is gone, Michael has disarmed it: stop sending and don't ask him to re-arm it. Send only messages
  you can trace to a capture, Mixxx's docs or the MK2 djay map, never SysEx or anything firmware-shaped, and
  log what you sent in progress. Michael is usually asleep during runs: nobody will see the LEDs or the platter.
- **Test in the dev profile.** The real profile `~/.var/app/org.mixxx.Mixxx/.mixxx/` is on-limits (see
  `## On-limits`), but runs use `--settings-path ~/.var/app/org.mixxx.Mixxx/dev-profile/` (inside the Flatpak's
  own data dir, so the sandbox can reach it; `~/projects` is not visible inside the Flatpak, so mappings are
  copied into the dev profile, not symlinked).
- **No audio to the Rane One or speakers while unattended.** Unattended audio goes to a PipeWire null sink.
  Never change the system's default sink or source.
- Stop every Mixxx you start (by its pid) before your session ends. Never kill a Mixxx you did not start.
- **Every MIDI fact cites a capture** (`captures/<session>/<file>`). A fact without one is marked `UNVERIFIED` in
  code and docs. When a capture contradicts the research notes, the capture wins; record it in
  `docs/decisions.md`.
- If a step needs hands on the hardware, don't guess: write the procedure into `HARDWARE-TESTS.md` and ask for
  it as a question in your progress entry.
- Out of scope until Michael says otherwise: Mixxx C++ changes, building motor/LED/display output into the
  mapping, `rea`, Serato reverse engineering. Sending test messages to learn how the One responds is in scope (D13).

## Code rules
- Mixxx side: `mapping/Rane-One.midi.xml` + plain-script JS files loaded by Mixxx's QJSEngine (no `import`, no
  `require`). The platter core (`mapping/rane-one-platter.js`) is **pure**: no `engine`, `midi` or `print`
  calls, so Node tests can load it too. Glue code adapts it to Mixxx.
- Input handlers **never throw**. Wrap them; on any anomaly fall back to Mixxx playing at the pitch fader's rate.
- Follow Mixxx's mapping conventions: Components JS, its ESLint config and the typings in
  `mixxxdj/mixxx` `res/controllers/`. Use the 2.5 branch as the reference for what 2.5.6 supports.
- Tools and tests: Node 24, **zero npm dependencies** unless recorded as a decision. No Python numpy here.
  Tools live in `tools/`, tests in `tests/*.test.mjs`.

## How to verify
- Suite: `npm test` (`node --test`). It starts with the `tools/midi-send` safety tests, which must stay green.
- In Mixxx: `tools/mixxx-dev start` / `stop` runs the dev profile with `--controller-abort-on-warning`, so a
  mapping that loads cleanly is the evidence. The log is `dev-profile/mixxx.log`. Replays go through
  `Midi Through` (ALSA seq client 14) into Mixxx with the mapping bound to that port.
- Mixxx is a GUI app: it needs the harness to run inside Michael's desktop session (`WAYLAND_DISPLAY` set). If it
  isn't, say so in progress and skip the Mixxx step rather than fake it.

## Decisions and plans
- Spec: `docs/spec.md`. Decisions: `docs/decisions.md` (an entry without `*default*` is settled). A new default is
  recorded there as `D<n> *default*`, with the next free number.
- Plans: `docs/plans/<date>-<milestone>-<topic>.md`.
- Research: `docs/research/`. `2026-10-19-prior-art.md` is the current summary; the 2026-09-17 files are older.
- Reference: `reference/rane-one-mk2-djay-midi-map.csv` is a djay mapping for the **MK2**: a hint, not truth.

## Where things go
- What happened, what you tried, what failed: your progress entry (in a harness run, `entry.json`).
- A decision: `docs/decisions.md`. Overturned: rewrite the entry in place plus one `(Updated in place <date>: …)`
  line, never a new entry beside a dead one.
- A fact a fresh session would otherwise rediscover: one line under `## Gotchas` below, edited in place.
- Tonight's scope: the run brief, never this file. How to work here is Michael's: propose it in `proposed_changes`.
- Anything the code, git or the suite can tell: nowhere (no test counts, file lists or constants).

## Gotchas
- `pw-record` 1.6.8 exits 1 even after a good recording: `tools/record-output` judges the WAV's frame count instead.
  (rane-one-mixxx-2026-10-19 2026-10-21)
- A new tool in `tools/` fails the suite until `tests/tools-usage.test.mjs` has bad-argument cases for it.
  (rane-one-mixxx-2026-10-19 2026-10-19)
- A feature step that names a decision number may name a taken one: use the next free number and say so in the
  entry. (rane-one-mixxx-2026-10-19 2026-10-20)
- A capture from the One needs Mixxx closed: the rawmidi port is exclusive, and `tools/capture` exits 5 while it is
  busy. (rane-one-mixxx-2026-10-19 2026-10-20)
- Tests arm with a temp `HOME` holding `.rane-armed` and strip `MIXXX_DEV_*`/`NULL_SINK_*`, so they never reach
  the real home or dev profile. (rane-one-mixxx-2026-10-19 2026-10-19)
- Mixxx 2.5 has no SIGTERM handler, so `tools/mixxx-dev stop` is a hard kill: prove `shutdown()` with a hot reload
  (`tools/install-mapping` while Mixxx runs). (rane-one-mixxx-2026-10-19 2026-10-20)
- The system default sink and source are the Rane One's: audio that isn't routed to the null sink goes to the
  controller (D9). (rane-one-mixxx-2026-10-19 2026-10-19)

## On-limits
- `~/.var/app/org.mixxx.Mixxx/.mixxx/` (Michael's real Mixxx profile and library. This is on limits because I don't
  yet use Mixxx, so modifying things in here won't affect me and my workflow.)

## Off-limits
- `~/.rane-armed`: only Michael creates or removes it.
