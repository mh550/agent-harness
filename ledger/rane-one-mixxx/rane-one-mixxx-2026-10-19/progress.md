# Progress log · run rane-one-mixxx-2026-10-19

What this is: the shared memory of this harness run. Every session appends one entry **at the top** (newest
first) when it finishes: what it built, what it verified (commands and numbers), what it could not do, and
questions for Michael. Sessions start with an empty context; this file, `feature_list.json`, `CLAUDE.md`,
`docs/spec.md` and `docs/decisions.md` are all they know.

How to read `feature_list.json`: features are in priority order; the harness hands a session the first
feature whose `passes` is false and whose `after` dependencies all pass. A session edits only its own
feature's `passes`. Steps are what the verifier re-runs, so meet them literally.

How Michael steers: edit `INBOX.md` on this branch (`status: pause|stop`; answers under `## Answers`).
Every session reads it at startup.

---

### 2026-10-20 09:40 · M2-04 · passes

- **Changed:** new `tools/replay` (JSONL → SMF at 1 tick = 1 ms → `tools/midi-send play <client>:0`; never starts a player itself). It drops non-channel messages and counts them, has `--from/--to/--speed`, `--dry-run [--out [--force]] [--to-port]`, and exits 4 when two clients have the same name. The gate's route walk moved byte-identical into `tools/lib/rane-route.awk`; replay runs it armed or not. New `tests/replay.test.mjs` (22), 2 midi-send tests and 17 usage cases. Tests 274 → 315; `check.sh` green.
- **Verified:** the tests check SMF bytes and ticks within 0.5 ms of the scaled `t_us`, `--speed 2`, `--from 20 --to 37` and the quick capture's 3396/1697. The stub call log shows exactly one `aplaymidi -p 14:0 -- <tmp>` (from midi-send), the source grep finds no `aplaymidi`, and Rane names and routes exit 3. Mutation checks: 9 of 10 sabotages caught. **Live twice** (dev Mixxx, null sink): `--from 19 --to 21` gave 3396 log lines, **1697 CC 6** (the plan's predicted count; the step's "about 2000"), 0 `[Controller]` warnings and 0 mapping errors. Mixxx was stopped by its id, the default sink was unchanged and the temp SMF was removed.
- **Sent:** twice, `tools/midi-send play 14:0 /tmp/replay-{tka3Fk,h1YK8v}/replay.mid` (3396 channel messages each, Midi Through → Mixxx only; the route walk passed). Nothing went to the Rane One.
- **Review:** an Opus reviewer found 0 Critical, 1 Important and 7 Minor issues. The Important one: `--dry-run --out` could overwrite the input capture. It is now refused unless `--force`. Also fixed test-first: early signal handlers with temp cleanup, exit 128+n, midi-send codes other than 3/4 → 1, and midi-send's `here` via `readlink -f` with `CDPATH` cleared. Left as documented: port 0 only, and the route is checked once, before sending.
- **Next session:** `tools/replay` is ready for M3 replays. Run the dry run first, and use a fresh `--out` (it now refuses to overwrite).
- **Questions for Michael:** none new. D9–D12 and D14–D16 are still open.
- **Proposed change:** M2-04 step 3: "about 2000" → "1697" (or use `--from 20 --to 22` for 1996), as M2-01 proposed.

### 2026-10-20 09:20 · M2-03 · passes

- **Changed:** new `tools/capture`, the read-only rawmidi capture to M2 JSONL. A `--reader` child does the only open, `fs.openSync(path, "r")`, and sends hrtime-stamped frames; the parent writes JSONL through `jsonl.mjs`. New `tests/capture.test.mjs` (15 tests) and 13 capture cases in `tools-usage`. The plan's Capture backend section now matches the build: 4 frame kinds, `CAPTURE_SND_DIR` for tests, exit-4 text, `--force` and stop semantics. Tests 246 → 274; `check.sh` green.
- **Verified:** the FIFO tests cover 3 chunks (a split pitch bend, a SysEx, running status) with strict `readJsonl`, `--seconds 1`, SIGINT/SIGTERM/SIGHUP, and Ctrl-C to the process group. They also cover the stubbed `amidi -l` (exact name, input-only, subdevice ≠ 0 refused), `--wait`, exit 4, and ENOSPC on /dev/full ending the reader. Stable: 5 runs in a row, then 3 in parallel. The step-3 grep shows one open line (54). **Live, read-only:** `--port 'Rane ONE MIDI 1'` gave hw:2,0,0 → `/dev/snd/midiC2D0`, 0 messages in 2.0 s, exit 0. With my own aseqdump holding the port: exit 5 in 2.14 s, no file. aseqdump was killed by pid.
- **Review:** an Opus reviewer found 1 Important issue: a parent dying outside `finish` (an output write error, SIGHUP) left the reader blocked, holding the device. I reproduced it as a hanging test and fixed it test-first (try/catch, an exit handler, SIGHUP). I also fixed 5 Minors (busy/opened race, subdevice, a lost partial frame reported, `--force` not deleting, wider test timing). Two stay documented, not fixed: a stop before the open exits 1, and the microsecond loss window at a stop.
- **Sent:** nothing to any MIDI port. No Mixxx was started.
- **Next session (M2-04+):** a capture of the One needs Mixxx closed (the port is exclusive; exit 5 otherwise). The busy path is not in the suite (a FIFO can't be busy), only live-checked.
- **Questions for Michael:** none new. D9–D12 and D14–D16 are still open.

### 2026-10-20 09:45 · M2-02 · passes

- **Changed:** new `tools/lib/smf.mjs` (SMF read/write, tempo map → µs), `tools/lib/jsonl.mjs` (the only implementation of the M2 line format), `tools/capture-convert`, and the parser's new `flush()` in `midi-parse.mjs`. Committed `captures/2026-10-19-quick/platter.jsonl` (58650 lines, 4.8 MB) and a README line. New tests: `smf` 14, `jsonl` 7, `capture-convert` 14, plus usage cases. Tests 202 → 246; `check.sh` green.
- **Verified:** `tools/capture-convert captures/2026-10-19-quick/platter.mid` on a fresh tree wrote 58650 lines (cc 29323, all `d1` 6; pb 29323; on 2; off 2). The last `t_us` is 48390000 and nothing was dropped. A second conversion was byte-identical to the committed file. Its type/d1/value sequence also matches aseqdump's `platter.txt` line for line (`cmp`: all 58650 messages identical). The plan's 3 example lines are the file's first 3 (asserted).
- **Review:** an Opus reviewer found 10 issues (1 Important, 9 Minor), and I fixed all of them test-first. The Important one: SysEx divided across an F0 packet and F7 continuations was rejected. That fix is recorded as **D16 *default*** and in the plan. The other fixes: an open SysEx at EOF is now written truncated, dropped bytes fail unless `--allow-dropped`, F7 events are flagged `escape`, `parseLine` accepts only the canonical form, `--out` parsing is stricter, `--force` goes through a temp file and rename, `.midi` is accepted, and there are rounding and SysEx running-status tests.
- **Step 2 re-runs:** without `--force`, converting onto an identical existing file is a no-op (exit 0, "already up to date"), so the verifier can run step 2 literally on the committed file. A file that differs is still refused.
- **Sent:** nothing to any MIDI port. No Mixxx was started.
- **Next session (M2-03+):** use `createJsonlWriter`, `readJsonl` and `parser.flush()` (at the end of a capture) from `tools/lib`, and `writeSmf` for replay (it rejects F7 escapes, real-time, system common and truncated SysEx).
- **Questions for Michael:** D16: is it OK that capture-convert refuses dropped bytes by default (`--allow-dropped` overrides)? D9–D12, D14 and D15 are still open.

### 2026-10-20 08:50 · M2-01 · passes

- **Changed:** new `docs/plans/2026-10-19-M2-capture-replay.md` with the sections JSONL format, SMF library, Capture backend, Replay, Census, Capture session, HARDWARE-TESTS outline and Evidence. New `D14 *default*` (capture backend) and `D15 *default*` (session timing) in `docs/decisions.md`. Tests 202 → 202; `check.sh` green.
- **Verified:** I checked each step against the plan with grep. The 3 example JSONL lines are decoded from `platter.mid`'s hex (CC 6 = 92 at 2651 ms, pitch bend 7829 = aseqdump's −363). Read-only probes of `/dev/snd/midiC2D0`: an `O_RDONLY` open takes 42 µs. A blocking open waits indefinitely while aseqdump holds the port (so capture times out after 2 s and exits 5). `process.exit()` hangs while a worker is blocked in `readSync`, so the reader runs in a child process; I prototyped that on a FIFO. When motor-on, the One sends ≈ 1998 messages/s. An Opus review returned 15 findings (8 Important), and I applied all of them.
- **Sent:** nothing to any MIDI port. All my probe processes were stopped.
- **Next session (M2-02+):** build from the plan. M2-04 step 3's `--from 19 --to 21` gives **1697** CC 6, not 2000 (the motor starts at 19.236 s). Replay drops non-channel messages and runs midi-send's route walk via a new `tools/lib/rane-route.awk`. Close Mixxx before any capture (the port is exclusive).
- **Questions for Michael:** (1) D15: honest estimates put the §6 session at ≈ 28 min of steps plus 5 min setup, over the 25 min in M2-06/M2-07. Raise the cap to 30, or cut (pads with Shift in one mode only, the 45 step at 30 s)? (2) D14: is reading the rawmidi device OK as the backend (arecordmidi as fallback)? D9–D12 are still open.
- **Proposed changes:** M2-01 step 3 says `D10 *default*`, but D10 was already the launcher check, so the backend is **D14**; amend the step to D14. M2-06 step 2 and M2-07 step 1: "under 25 minutes" → "under 30 minutes" (D15). M2-04 step 3: "about 2000" → "about 1700", or use `--from 20 --to 22` (1996).

### 2026-10-20 08:30 · verify M1

All 6 features hold; I changed no `passes`. Live run: WAYLAND_DISPLAY=wayland-1, own Mixxx instance 4244755264 started and stopped, null sink up/down, default sink unchanged throughout. `npm test` 202/202. Note: `reviews/M1.diff` no longer equals a fresh `git diff main...HEAD` (779 differing lines, later commits); the file exists, which is all the step needs.

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| M1-01 | 1 | `grep '^## ' docs/plans/2026-10-19-M1-dev-loop.md` | sections Null sink (l.26), Dev profile seed (72), Launcher (161), Mapping skeleton (229), MIDI parser (271), Evidence (314) | yes |
| M1-01 | 2 | read plan l.26-60 | sink `mixxx-dev`, 48 kHz, module-null-sink via pactl; default never changed; `PULSE_SINK=mixxx-dev` via `flatpak run --env=`; check via `pactl list sink-inputs` | yes |
| M1-01 | 3 | read plan l.72-100, 163-175 | seed table (mixxx.cfg, soundconfig.xml 48 kHz, library dir under dev profile, via mixxxdb.sqlite because 2.5 has no cfg key; reasoned) and the flatpak run command with the CLAUDE.md flags | yes |
| M1-01 | 4 | read plan l.173-198 | instance id via `--instance-id-fd` into `dev-profile/mixxx-dev.instance`; stop = `flatpak kill <id>`; "Never `flatpak kill org.mixxx.Mixxx`" | yes |
| M1-01 | 5 | read plan l.259-263, grep output | night rule: bound only to `Midi Through Port-0`; no `<output>`, no `midi.send*` | yes |
| M1-01 | 6 | read plan l.271-312 | `createParser()` with `feed`, running status, SysEx, real-time bytes, `describe(msg)` | yes |
| M1-01 | 7 | `grep -n D9 docs/decisions.md`, read l.27-36 | `D9 *default*` with sink name, routing, instance tracking, night port | yes |
| M1-01 | 8 | `npm test` | 202 pass, 0 fail | yes |
| M1-02 | 1 | `git log --reverse -- tests/midi-parse.test.mjs tools/lib/midi-parse.mjs` | one commit fc3c032 holds both (test and impl equal, as the step allows) | yes |
| M1-02 | 2 | `node --test tests/midi-parse.test.mjs`; read asserts | 16/16 pass; cases for 3- and 2-byte messages, running status across feeds, split SysEx, 0xF8 inside running status, pb 0..16383, mid-message splits | yes |
| M1-02 | 3 | node import of module | exports `createParser`, `describe`; `cc ch1 6=92`; `pb ch1 16383`, `pb ch1 8192` | yes |
| M1-02 | 4 | read test l.208-217 | capture test asserts 58650 messages = {cc 29323, pb 29323, on 2, off 2}, dropped 0; test passes | yes |
| M1-02 | 5 | `npm test` | 202/202 | yes |
| M1-03 | 1 | `node --test tests/null-sink.test.mjs`; read stub l.26 | 52/52 pass; stub exits 99 on `set-default-*`; up/up-twice/down-by-recorded-id/status tests present and green | yes |
| M1-03 | 2 | real `tools/null-sink up`, `pactl list short sinks`, `pactl info`, `status`, `down` | sink 2207 `mixxx-dev` 48000Hz listed; Default Sink `alsa_output.usb-Rane_Rane_ONE_A-00...` before, after up and after down; down removed it (count 0) | yes |
| M1-03 | 3 | `node --test tests/install-mapping.test.mjs` | 14/14 pass: copies all, overwrites stale, refuses (exit 3) inside `.mixxx` | yes |
| M1-03 | 4 | `npm test` | 202/202 | yes |
| M1-04 | 1 | `node --test tests/mixxx-dev.test.mjs` | all pass (seed, flags, instance file, stop by id never by app name, stop without file exit 0, exit 3 guards) | yes |
| M1-04 | 2 | `flatpak run --command=sh org.mixxx.Mixxx -c 'touch ~/.var/app/org.mixxx.Mixxx/dev-profile/.probe'`; evidence in plan | exit 0; file visible on host (removed after); evidence present in plan | yes |
| M1-04 | 3 | `tools/null-sink up && tools/mixxx-dev start`; `ls mixxx.log`; grep stdout; `pactl list sink-inputs`; `stop` | start OK in 4 s; mixxx.log new (08:20:24 vs 08:18:01); stdout line 9 `Configuration file is at the current version "2.5.6"`; Mixxx stream `mixxx-dev` on Sink 2235 = mixxx-dev, only other input on sink 779 is speech-dispatcher, not Mixxx; stop printed `stopped 4244755264`, no Mixxx in `flatpak ps` | yes |
| M1-04 | 4 | `tools/mixxx-dev log \| wc -l` | 50 lines | yes |
| M1-04 | 5 | `npm test` | 202/202 | yes |
| M1-05 | 1 | read xml, `tests/mapping-xml.test.mjs`, `node --check` test | controller id `Rane ONE`, scripts platter then scripts, prefix RaneOne, no output; check test passes | yes |
| M1-05 | 2 | mapping-xml tests: init/shutdown one line, no throw, purity grep | all pass (11/11) | yes |
| M1-05 | 3 | `node --test tests/mapping-xml.test.mjs` | 11/11 pass incl. XML parses, list matches files, no output | yes |
| M1-05 | 4 | `tools/install-mapping`, `tools/mixxx-dev start`, read mixxx.log | `RaneOne: init Midi Through Port-0` at 08:20:24; no ControllerScriptEngine warning/error; run was under --controller-abort-on-warning and survived | yes |
| M1-05 | 5 | `tools/midi-send play 14:0 tests/fixtures/three-notes.mid`; `tools/install-mapping` while running | 3 incoming lines status 0x90 (ch 1) at 08:20:29; reload logged `RaneOne: shutdown` then `RaneOne: init` (twice, one per watched file; plus the documented "Failed to watch script file" warnings, which the plan expects) | yes |
| M1-05 | 6 | `npm test` | 202/202 | yes |
| M1-06 | 1 | `ls reviews/M1.diff` | exists, 3268 lines (stale vs current tree, see note) | yes |
| M1-06 | 2 | read `reviews/M1-findings.md`; `git show --stat` of 680b5f2 2eb7c11 5002172 e27284d 737053e 1059b30 | every Important (#1-5) has a fixing commit and a test file in that commit; "failed first" claims not independently replayed | yes |
| M1-06 | 3 | ran each tool with a bad arg; `git grep` amidi/aplaymidi and `.mixxx` | null-sink, mixxx-dev, install-mapping, midi-send all exit 2; no amidi/aplaymidi outside midi-send; `.mixxx` appears only in `tools/lib/profile.sh` (the guard); tools-usage tests 20/20 | yes |
| M1-06 | 4 | read README.md; spec l.52 | Dev loop section 15 lines incl. heading and a blank, covers all four tools; spec M1 "Done 2026-10-19" | yes |
| M1-06 | 5 | `npm test` | 202/202 | yes |

### 2026-10-20 08:19 · M1-05 · passes

- **Changed:** no code. I re-verified every step live and added the 08:17 evidence to `docs/plans/2026-10-19-M1-dev-loop.md` (M1-05 binding). Tests 202 → 202; `check.sh` green.
- **Steps 1–3:** `node --check` OK on both scripts. The XML has controller id `Rane ONE`, the scripts in order (prefix `RaneOne`) and no `<output>`. `tests/mapping-xml.test.mjs` 11/11, including the purity grep.
- **Step 4 (live, `WAYLAND_DISPLAY=wayland-1`):** `null-sink up && install-mapping && mixxx-dev start` → `running: 3019912654` in 6 s, stream on sink 2120 `mixxx-dev`. `mixxx.cfg` binds `Midi_Through_Port-0` to the dev-profile mapping. The log has `RaneOne: init Midi Through Port-0` and 0 Warning/Critical/Fatal/Mapping Error lines on `[Controller]`.
- **Step 5 (as amended):** `tools/midi-send play 14:0 tests/fixtures/three-notes.mid` → exit 0 and exactly 3 `status 0x90` lines (+3 `0x80`). Re-running `tools/install-mapping` → 2 `RaneOne: shutdown` → `RaneOne: init` pairs, with only the predicted `Failed to watch script file` warnings. Then stop, `flatpak ps` with no Mixxx, sink down, Default Sink unchanged (Rane ONE), no `mixxx` process left.
- **Sent to the Rane:** nothing. The only MIDI sent was the fixture, to Midi Through 14:0, whose only onward subscription was Mixxx (128:1).
- **Next session:** all of M1 passes now.
- **Questions for Michael:** D9–D12 defaults are still open (see earlier entries).
- **Proposed changes:** M1-05 step 4: "no `ControllerScriptEngine` warning" → "no Warning/Critical on the `[Controller]` thread". That category doesn't exist; the 17:36 entry has the details.

### 2026-10-20 08:17 · M1-04 · passes

- **Changed:** no code. The launcher already used option (a) for readiness (D10), so step 3 as amended only needed a live re-check. Added launch 5's evidence to `docs/plans/2026-10-19-M1-dev-loop.md`. Tests 202 → 202; `check.sh` green.
- **Verified (live, `WAYLAND_DISPLAY=wayland-1`, 08:14:50):** `tools/null-sink up && tools/mixxx-dev start` → `running: 3013574568`, rc 0 in 8 s. New `mixxx.log` (inode 49306080 → 49310666). This launch's `mixxx-dev.stdout` line 9 is `Configuration file is at the current version "2.5.6"`. The Mixxx stream (`mixxx.bin`) was on sink 2029 `mixxx-dev`. The only stream on the Rane was `speech-dispatcher-dummy` (not ours) and none was on the PCI sink. `tools/mixxx-dev log` printed 50 lines, identical to `tail -n 50`. After `stop`, `flatpak ps` showed no Mixxx. Sink down; Default Sink/Source unchanged; no `mixxx.bin` left running. Step 1: `tests/mixxx-dev.test.mjs` 67/67. Step 2: probe re-run, exit 0, file visible on the host, then deleted.
- **Sent to the Rane:** nothing.
- **Next session:** M1-05 step 5 is amended (shutdown is proven by a hot reload via `tools/install-mapping`). Re-verify it live. The other M1-05 steps held in verify-M1.
- **Questions for Michael:** D9–D12 defaults are still open (see earlier entries).
- **Proposed changes:** none.

### 2026-10-19 18:17 · M3-01 · passes

- **Changed:** new `docs/plans/2026-10-19-M3-measurement.md` (WAV library, make-test-audio, wow-flutter algorithm, Telemetry format, drift, record-output, Evidence); `D11 *default*` (telemetry JSONL) and `D12 *default*` (how §3's wow & flutter is measured) in `docs/decisions.md`. **Suite fix first:** the init check was red on a rare race in `tools/mixxx-dev start`. It read the id file, then checked whether the launcher was alive, so a launcher that wrote its id and exited in between looked dead. Liveness is now sampled before the read. Not reproduced in 60 stressed runs; the fix is correct by construction (reviewer agreed). Tests 202 → 202; `check.sh` green.
- **Verified:** each step grepped in the plan/decisions. A scratch prototype of the wow-flutter algorithm met every M3-03 tolerance (0.1 % @ 4 Hz → 0.1008 %; 0.5 % @ 0.5 Hz → 0.4913 %; 1010 Hz → 0.0013 %, mean 1010.000; 1 ms dropout → `dropouts 1`). An Opus review gave 10 findings, all applied (2 checked against WirePlumber's source).
- **Next sessions must know:** (1) a literal −3 dB high-pass at 0.5 Hz, run zero-phase, halves 0.5 Hz wow (0.252 %), so the corner is 0.2 Hz (D12). (2) WirePlumber 0.5.12 probably won't resolve `--target mixxx-dev.monitor` for native `pw-record`. With `dont-fallback` it destroys the stream, so record-output must check the frame count. The fallback is `--target mixxx-dev -P stream.capture.sink=true`. The default source is the **Rane's capture**. (3) Random 0–21 ms `playposition` sampling lag alone fakes 8–10 ms of drift, so M7 must log from a `playposition` connection callback.
- **Questions for Michael:** D11 (telemetry format) and D12 (peak deviation, passband from 0.5 Hz, unweighted): OK as defaults? D9/D10 and the M1-04 INBOX question are still open.
- **Proposed changes:** M3-05 step 1: allow `--target mixxx-dev.monitor` to be translated to `--target mixxx-dev -P stream.capture.sink=true` if M3-05's live check shows the `.monitor` name doesn't link. Add to M7 a `tools/mixxx-dev telemetry` subcommand that extracts `RaneOne telemetry` lines from `mixxx.log` (scripts can't write files).

### 2026-10-19 18:08 · M1-04 · not yet (parked on a step change)

- **Changed:** no code. Added a question to `INBOX.md` and one sentence to D10 in `docs/decisions.md` (the Mixxx init order). Tests 202 → 202; `check.sh` is green.
- **Why not passing:** step 3 can't hold as written. I re-checked against the `mixxxdj/mixxx` `2.5.6` tag. The "Mixxx 2.5.6 … is starting" line is a default-category `qDebug` (`versionstore.cpp`), and `controllerDebugCategoryFilter` (`logging.cpp`) forces that off under `--controller-debug`, which step 1 requires. The "Configuration file is at the current version" line runs before `Logging::initialize`, so it only ever reaches stdout. `grep -c '2\.5\.6\|is starting'` over all 8 dev-profile logs: 0 each. I did not write a line into Mixxx's log myself, because that would be faking it.
- **Next session:** every other M1-04 step already holds (verify-M1 table). Once Michael answers, re-verify only step 3 live. Under (a), check the new `mixxx.log` and the line in `dev-profile/mixxx-dev.stdout`. Under (b), first change the launcher's flags, the tests and CLAUDE.md.
- **Question for Michael (INBOX):** amend M1-04 step 3 to "a new `mixxx.log` within 60 s and `mixxx-dev.stdout` contains `Configuration file is at the current version "2.5.6"`" (recommended), or drop `--controller-debug`?
- **Proposed changes:** M1-04 step 3 as in (a). M1-05 step 5's proposed change from the 17:36 entry still stands (`stop` is a hard kill, so `shutdown` is proven by a hot reload).

### 2026-10-19 18:05 · verify M1

Features passing: M1-01, M1-02, M1-03, M1-06. Set to false: **M1-04** (step 3: no Mixxx version line in mixxx.log; it is in mixxx-dev.stdout) and **M1-05** (step 5: `stop` is a hard kill, no `RaneOne: shutdown` in the log). Live run done with WAYLAND_DISPLAY set; Mixxx stopped, sink removed, Default Sink unchanged (Rane ONE), `~/.rane-armed` absent.

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| M1-01 | 1 | grep '^## ' on docs/plans/2026-10-19-M1-dev-loop.md | Sections Null sink, Dev profile seed, Launcher, Mapping skeleton, MIDI parser, Evidence all present | yes |
| M1-01 | 2 | read Null sink section (l.26-70) | sink `mixxx-dev`, 48 kHz, module-null-sink via pactl, no default-sink change, `PULSE_SINK=mixxx-dev` via `flatpak run --env=`, `pactl list sink-inputs` check | yes |
| M1-01 | 3 | read Dev profile seed section | lists mixxx.cfg (library dir via mixxxdb `directories` row under dev profile), soundconfig.xml 48 kHz, flatpak run command with the CLAUDE.md flags | yes |
| M1-01 | 4 | read Launcher section l.190-200 | instance id in mixxx-dev.instance, `flatpak kill <instance id>`, never `flatpak kill org.mixxx.Mixxx` | yes |
| M1-01 | 5 | read Mapping skeleton l.229-265 | bound only to `Midi Through Port-0`; no <output>, no midi.send* calls | yes |
| M1-01 | 6 | read MIDI parser section l.271-305 | createParser().feed -> messages, running status, SysEx, real-time bytes, describe(msg) specified | yes |
| M1-01 | 7 | read docs/decisions.md D9 | `D9 *default*` names sink, routing, instance tracking, night port rule | yes |
| M1-01 | 8 | check.sh and `node --test tests/*.test.mjs` area runs | check: green (202 tests) | yes |
| M1-02 | 1 | `git log --stat -- tests/midi-parse.test.mjs tools/lib/midi-parse.mjs` | both files added in the same commit fc3c032 (precedes-or-equals satisfied) | yes |
| M1-02 | 2 | `node --test tests/midi-parse.test.mjs`; read test names | 16/16 pass; cover 3-/2-byte, running status across feeds, split SysEx, 0xF8 in running status, 14-bit pb, mid-message splits | yes |
| M1-02 | 3 | read describe cases in test l.138+ | `{0xb0,[6,92]}` -> `cc ch1 6=92`; pb rendered `pb ch1 <n>`; exports createParser/describe | yes |
| M1-02 | 4 | read test l.208-218; `grep -c` on captures/2026-10-19-quick/platter.txt | asserts 58650 msgs = 29323 cc, 29323 pb, 2 on+2 off; my grep: 29323 CC, 29323 Pitch bend, 4 Note | yes |
| M1-02 | 5 | check.sh | green, 202 tests | yes |
| M1-03 | 1 | `node --test tests/null-sink.test.mjs`; read test names/stub | 38/38 pass; up/up-twice/down-by-id/status tests present; stub pactl exits 99 on set-default-*, 'no invocation changes default' test | yes |
| M1-03 | 2 | live: `tools/null-sink up`; `pactl list short sinks`; `pactl info|grep Default`; `down` | mixxx-dev listed (48000Hz); Default Sink = Rane analog-surround-40 before, after up, after down; sink gone after down (count 0) | yes |
| M1-03 | 3 | `node --test tests/install-mapping.test.mjs` | 14/14 pass: copy into controllers/, overwrite stale, refuse exit 3 for real-profile paths | yes |
| M1-03 | 4 | check.sh | green | yes |
| M1-04 | 1 | `node --test tests/mixxx-dev.test.mjs` | 67/67 pass (stubbed flatpak/pactl; start/stop/instance/exit 3 cases) | yes |
| M1-04 | 2 | `flatpak run --command=sh org.mixxx.Mixxx -c 'touch .../dev-profile/.probe'`; ls on host; grep plan Evidence | rc=0, file visible on host (17:58), deleted; plan Evidence l.343-347 records it | yes |
| M1-04 | 3 | live (WAYLAND_DISPLAY=wayland-1): `null-sink up`, `mixxx-dev start`; grep mixxx.log for version; `pactl list sink-inputs`; `stop`; `flatpak ps` | start ok, stream 'mixxx-dev' on sink 1814=mixxx-dev, none on Rane/PCI, stop removed instance. BUT mixxx.log has NO Mixxx version line (grep 2.5.6 = 0); it is only on mixxx-dev.stdout ('Configuration file is at the current version 2.5.6'). Step says mixxx.log | NO |
| M1-04 | 4 | `tools/mixxx-dev log | wc -l` | 50 lines | yes |
| M1-04 | 5 | check.sh | green | yes |
| M1-05 | 1 | read mapping/Rane-One.midi.xml; `node --check` both scripts | controller id 'Rane ONE', scripts rane-one-platter.js then Rane-One-scripts.js (prefix RaneOne), no <output>, node --check OK | yes |
| M1-05 | 2 | read Rane-One-scripts.js, grep platter, tests/mapping-xml.test.mjs l.114-190 | one console.log each in init/shutdown; platter has no engine/midi/print refs; guard + never-throw tests present | yes |
| M1-05 | 3 | `node --test tests/mapping-xml.test.mjs` | 11/11 pass (parse, script list vs files, no output) | yes |
| M1-05 | 4 | live: install-mapping, mixxx-dev start; grep mixxx.cfg and log | cfg binds Midi_Through_Port-0 to dev-profile/controllers/Rane-One.midi.xml; log has `RaneOne: init Midi Through Port-0`; no ControllerScriptEngine warning (other non-controller warnings present: underflow, JACK, SCHED_FIFO) | yes |
| M1-05 | 5 | live: `tools/midi-send play 14:0 tests/fixtures/three-notes.mid`; then `tools/mixxx-dev stop`; grep shutdown | 3 note-on 0x90 lines (+3 0x80) logged; but after stop the log has 0 `RaneOne: shutdown` lines (flatpak kill is a hard kill; plan l.447 admits it). Step says stop logs shutdown | NO |
| M1-05 | 6 | check.sh | green | yes |
| M1-06 | 1 | ls reviews/; compare M1.diff with fresh `git diff main...HEAD -- tools tests mapping docs package.json` | M1.diff exists (3268 lines); fresh diff differs by 518 lines because fixes landed after; step only needs the file to exist and be read | yes |
| M1-06 | 2 | read reviews/M1-findings.md | 20 findings with severity; each of 5 Important lists tests-failed-first and fix commit (680b5f2, 2eb7c11, 5002172, e27284d) | yes |
| M1-06 | 3 | `tools/<each> --bogus` exit codes; grep amidi/aplaymidi/.mixxx in tools | null-sink, mixxx-dev, install-mapping, midi-send all exit 2; no amidi/aplaymidi outside midi-send (only .mixxx guard/refusal references); tests/tools-usage 20/20 | yes |
| M1-06 | 4 | read README.md (26 lines) and docs/spec.md l.52 | Dev loop section l.12-26 = 15 lines covering the 3 tools and loop; spec M1 'Done 2026-10-19' | yes |
| M1-06 | 5 | check.sh | green | yes |

### 2026-10-19 17:52 · M1-06 · passes

- **Changed:** `reviews/M1.diff` + `reviews/M1-findings.md` (20 findings: 5 Important, 12 Minor, 3 Simplification; 13 fixed, 7 deferred with reasons). Fixes in `tools/midi-send` (`raw` now route-checks the card's seq client and takes only hex bytes; arms **only** on `$HOME/.rane-armed`, `RANE_ARM_FILE` removed), `tools/null-sink` (`LC_ALL=C`, refuses `up` with no visible default sink, `NULL_SINK_SETTLE` 0–9999, missing launcher = maybe running), `tools/mixxx-dev` (stream props `node.dont-reconnect`/`node.dont-fallback`, id before `mv`, launcher killed only while alive), `dev-seed.mjs` (version exactly x.y.z). Every tool now prints `usage: tools/<name> …`/exit 2 (new `tests/tools-usage.test.mjs`). README dev-loop section (15 lines); spec §5 M1 marked done. Tests 166 → 202; `check.sh` green.
- **Verified:** each fix had its test run red first (counts in the findings file); the mapping `midi` test was mutation-checked. Live at 17:50: the dev Mixxx stream (instance 1023889390) was on `mixxx-dev` and its pw node 102 had `node.dont-reconnect`/`node.dont-fallback` true. Afterwards nothing was running, the sink was absent and the Default Sink was unchanged (I re-checked all of it). The sink was **not** removed under a running Mixxx to watch the new behaviour, which would risk a stream on the Rane.
- **Next sessions must know:** to arm in tests, set `HOME` to a temp dir that holds `.rane-armed`. A new tool in `tools/` fails the suite until `tests/tools-usage.test.mjs` has bad-argument cases for it. Deferred to M2: one shared `aconnect -l` walk (findings #8, #19), since `tools/replay` will be a third user. Also deferred: the lock race between `null-sink down` and `start` (#6, now fails closed).
- **Questions for Michael:** (1) OK that `tools/midi-send` no longer honours `RANE_ARM_FILE`? Only `~/.rane-armed` arms it now. (2) Do you want to watch, once, what happens when `mixxx-dev` is unloaded under a running dev Mixxx? Expected: the stream is left unlinked, never moved to the Rane. Steps: `tools/null-sink up && tools/install-mapping && tools/mixxx-dev start`, then `pactl unload-module <id from dev-profile/null-sink.module>` with the Rane's volume down, then `pactl list sink-inputs`. Undo: `tools/mixxx-dev stop`. D9 and D10 are still open.
- **Proposed changes:** none.

### 2026-10-19 17:36 · M1-05 · passes

- **Changed:** new `mapping/Rane-One.midi.xml`, `mapping/rane-one-platter.js` (empty pure `RaneOnePlatter`), `mapping/Rane-One-scripts.js` (`RaneOne.guard`, `init`, `shutdown`); `tests/mapping-xml.test.mjs` (10, with a zero-dep XML well-formedness parser), `tests/fixtures/three-notes.mid` + `tests/fixtures-three-notes.test.mjs` (1); **gate hardening** in `tools/midi-send` (+11 tests). Evidence is in the M1 plan. Tests 144 → 166; `check.sh` green.
- **Verified live** (`WAYLAND_DISPLAY=wayland-1`, twice; the second run, 17:33, used the final code): the log shows `Opening Midi Through Port-0`, then `RaneOne: init Midi Through Port-0`. There were no Warnings on the `[Controller]` thread and no Mapping Error. `tools/midi-send play 14:0 tests/fixtures/three-notes.mid` gave exactly 3 `status 0x90` lines (+3 `0x80`). Re-installing the mapping (a hot reload) gave `RaneOne: shutdown` → `RaneOne: init` pairs, with only the predicted "Failed to watch script file" warnings. Mixxx is stopped, the sink is down and the Default Sink never changed.
- **Step 5 caveat:** `tools/mixxx-dev stop` logs **no** `RaneOne: shutdown` (counted: 0). It is a hard kill, and Mixxx 2.5 has no signal handler (re-checked in the 2.5 source). So `shutdown()` is proven by the hot reload, as M1-01 planned. The binding and the device name are in the plan's Evidence. The log brackets show thread names, not categories, so "loads cleanly" is applied to the `[Controller]` thread.
- **Review:** an Opus reviewer found 2 Critical gate bypasses, both reproduced with stubs: `play 14:0 -p 24:0 x.mid` (an old hole: aplaymidi takes extra `-p`) and `play 14:00`. Both are fixed test-first, along with 2 Important and 4 Minor findings (routes through user-client bridges, guard failures now `console.warn`, quotes in client names, awk failure fails closed, a nested-handler no-throw test). Still open: the guard has no pitch-fader fallback yet (TODO for M7). `raw` mode and PipeWire's MIDI bridge aren't route-checked.
- **Next sessions must know:** `midi-send play` takes exactly one file and refuses any route to a Rane through `aconnect -l`, including through Mixxx's own `Client-128` if Mixxx is bound to the Rane. The seed now binds Midi Through, because the mapping is installed. Real Note-offs arrive as `0x80`.
- **Proposed changes:** M1-05 step 5: "`tools/mixxx-dev stop` then logs `RaneOne: shutdown`" → "re-running `tools/install-mapping` while Mixxx runs logs `RaneOne: shutdown` followed by `RaneOne: init`". M1-05 step 4: "no `ControllerScriptEngine` warning" → "no Warning/Critical on the `[Controller]` thread".
- **Questions for Michael:** none new (D9 and D10 are still open).

### 2026-10-19 17:22 · M1-04 · passes

- **Changed:** new `tools/mixxx-dev` (start/stop/status/log), `tools/lib/dev-seed.mjs` (mixxx.cfg keys, launcher-owned soundconfig.xml, `mixxxdb.sqlite` library row via `node:sqlite`), `tests/mixxx-dev.test.mjs` (58), `tests/dev-seed.test.mjs` (9); **D10 *default*** in decisions; Evidence + as-built in the M1 plan. Tests 68 → 144; `check.sh` green.
- **Verified live** (`WAYLAND_DISPLAY=wayland-1`): sandbox probe at 16:46:56 OK, then four launches. Final run 17:21:20: `running: 3315317343` in 7 s. The stream (`application.name = "mixxx-dev"`, so `PULSE_PROP_OVERRIDE` works) was on the `mixxx-dev` sink, and nothing of ours was on the Rane or PCI sinks. The Rane PCM was `closed`, and soundconfig came back as ALSA/`pulse`. No library chooser; the seeded row survived Mixxx's schema upgrade 0→39. `null-sink down` refused while Mixxx ran. `stop` → gone from `flatpak ps` (Michael's protonvpn instance untouched) → `stopped`. Sink down; the default sink never changed. **No Mixxx is running and the sink is down.**
- **Step 3 caveat:** under `--controller-debug`, Mixxx 2.5.6 never writes its version to `mixxx.log`: it is a `qDebug` in the default category, which `controllerDebugCategoryFilter` drops. So the launcher reads the exact line `Configuration file is at the current version "2.5.6"` from the launch's stdout and requires a new `mixxx.log` (D10). Everything else in step 3 held literally. The first two launches failed and were stopped as designed: one on a not-yet-linked stream (`Sink: 4294967295`, now "not yet"), one on the missing version line.
- **Review:** an Opus reviewer found 4 Important (failed starts that left Mixxx running: a set -e exit, a `flatpak ps` failure, octal timeouts like `08`, no trap) and 4 Minor issues. All are fixed test-first with an EXIT trap, `flock` on `mixxx-dev.lock` (not inherited by Mixxx), "maybe running" on a `flatpak ps` error, refusing a pre-existing `mixxx-dev` stream and `LC_ALL=C`. Mutation-checked. Stream-to-pid tying was not done: the sandbox reports pid `2`.
- **Next sessions must know:** the PortMidi device list is not in `mixxx.log` at this level, so M1-05 must confirm the `Midi_Through_Port-0` key another way. The seed binds Midi Through only once `controllers/Rane-One.midi.xml` exists. `status` prints `busy` (exit 0) while a start or stop holds the lock. Mixxx logs Warnings even with no mapping (JACK rename, `samplers.xml`, SCHED_FIFO, underflow), all outside `controller.*`.
- **Proposed changes:** M1-04 step 3: "mixxx.log containing the Mixxx version line" → "a new mixxx.log, and `mixxx-dev.stdout` containing `Configuration file is at the current version "<version>"`" (D10).
- **Question for Michael:** D10: OK to prove the running Mixxx version from its stdout rather than `mixxx.log`? (The alternative is dropping `--controller-debug`, which M1-05 needs.)

### 2026-10-19 16:47 · M1-03 · passes

- **Changed:** new `tools/null-sink` (up/down/status), `tools/install-mapping`, `tools/lib/profile.sh` (`profile_guard`, `guard_path`: exit 3 for the real profile, inside it or an ancestor, as written and resolved), `tests/null-sink.test.mjs` (30), `tests/install-mapping.test.mjs` (14); Evidence + as-built notes in the M1 plan. Tests 24 → 68; `check.sh` green.
- **Verified live (16:39, re-run 16:44 after fixes):** `tools/null-sink up` → module 536870916, `pactl list short sinks` shows `mixxx-dev` (float32le 2ch 48000Hz); Default Sink stayed `alsa_output.usb-Rane_Rane_ONE_A-00…` before, after, 3 s later and after `down`; `down` → `grep -c mixxx-dev` 0, `status` → `absent`. Sink is down now. No Mixxx was started.
- **Review:** I gave the diff to an Opus reviewer. It found 6 Important and 6 Minor issues, all fixed test-first with failing tests seen first, and mutation-checked where cheap. The worst two: a symlinked `dev-profile/controllers` let install-mapping write into the real `.mixxx`, and `null-sink down` read any launcher error as "stopped".
- **Next sessions must know:** `null-sink down` proceeds only if `tools/mixxx-dev status` exits 1 and prints exactly `stopped`, so M1-04 must keep that contract. Tests strip `MIXXX_DEV_*`/`NULL_SINK_*` from the env and use a fake HOME, so they can't reach the real dev profile. `NULL_SINK_SETTLE=0` in tests. install-mapping writes files with mode 644, via `mktemp` + `mv -T`.
- **Questions for Michael:** none new (D9 still open).

### 2026-10-19 16:45 · M1-02 · passes

- **Changed:** new `tools/lib/midi-parse.mjs` (`createParser()` → `feed/reset/stats`, `describe(msg)`) and `tests/midi-parse.test.mjs` (16 tests, written first, committed together with the module). The plan's MIDI parser section notes the as-built `stats.dropped` meaning (bytes, not events). Tests 8 → 24; `check.sh` green.
- **Verified:** `node --test tests/midi-parse.test.mjs` 16/16. The quick capture `captures/2026-10-19-quick/platter.mid`, decoded by an inline SMF walk, parses to 58,650 messages: **29,323 CC, 29,323 pitch bend, 2 note-on, 2 note-off**, 0 dropped. The first two match `platter.txt` (CC 6=92, then pitch bend −363 = `pb ch1 7829`). The same result holds with random 1–7-byte feed splits and interleaved 0xF8. Mutation check: making real-time bytes clear running status fails a test. An Opus reviewer found no blocking bugs. Its fixes are in: `feed`/`describe` never throw, even on hostile iterables or malformed messages; a non-byte element in the middle of a message abandons that message instead of joining its neighbours; on and off are counted separately.
- **Next sessions must know:** the capture alternates CC/PB, so running status never helps on that stream. The SMF went through the ALSA sequencer, so the Rane's real wire bytes (running status, note-on velocity 0) are **UNVERIFIED**; a rawmidi capture (M2) would show them. The test's SMF walk is only good for this file (fixed header length, no chunk-type check). Don't reuse it as a general SMF reader; M2's converter needs a real one. There is no `flush()`: a SysEx still open at end of stream is discarded uncounted.
- **Questions for Michael:** none new (D9 from M1-01 still open).

### 2026-10-19 · M1-01 · passes

- **Changed:** new `docs/plans/2026-10-19-M1-dev-loop.md` (sections Null sink, Dev profile seed, Launcher, Mapping skeleton, MIDI parser, Evidence); `docs/decisions.md` gains **D9 *default***. Tests 8 → 8 (plan only); `check.sh` green.
- **Verified:** I checked every Mixxx claim against the 2.5 source (controllermanager, coreservices, soundmanagerconfig, portmidienumerator, script engine, schema.xml, upgrade.cpp). An Opus reviewer re-checked them and found 12 issues; I fixed all 12 in the plan. The worst one: `null-sink down` with Mixxx still running would move its stream to the default sink, which is the Rane One.
- **Next sessions must know:**
  - The library chooser depends on the DB `directories` table, not `mixxx.cfg`. The seed writes `mixxxdb.sqlite` with `node:sqlite`.
  - Mixxx 2.5 has no SIGTERM handler, so `stop` is a hard kill. Use `--log-flush-level debug`; `shutdown()` evidence comes from a script hot reload.
  - `flatpak run --instance-id-fd=3` gives the instance id directly.
  - On COSMIC, the menu-bar hint dialog blocks startup; the seed sets `show_menubar_hint 0`.
  - If `soundconfig.xml` fails, Mixxx falls back to JACK or a `hw:` device (possibly the Rane One), so the launcher rewrites it before every start.
- **Proposed changes:**
  - M1-01 step 3: the library dir does not live in `mixxx.cfg` (see the plan).
  - M1-05 step 5: "`tools/mixxx-dev stop` then logs `RaneOne: shutdown`" cannot hold, because stop is a hard kill. Prove it by re-running `tools/install-mapping` while Mixxx runs.
  - M1-05 step 4: there is no `ControllerScriptEngine` log category (scripts log under `controller.<device>`). Use the plan's "loads cleanly" rule.
  - M1-05: add gate hardening to `tools/midi-send`. It should refuse when the destination is subscribed onward to a Rane client.
- **Question for Michael:** D9: OK that the dev Mixxx never binds the real Rane ONE port until you say so, and that its audio goes only to the `mixxx-dev` null sink?

## 2026-10-19 · Initializer (Fable)

**Scope:** night 1 = M1–M4 (brief from Michael, 15:57). No hardware output. 28 features: M1 dev loop 6,
M2 capture and replay 8, M3 measurement tools 6, M4 platter core 8. Milestone dependencies: M2 after M1;
M3 independent (M3-05 needs M1-03 for the null sink); M4 after M2-02 (the converted real capture).
Only M2-07 (HARDWARE-TESTS.md) gates on just M2-06, as the spec asks.

### The quick capture is real platter data. Build M4 against it, not the Twelve hypothesis.

`captures/2026-10-19-quick/` (commit 473e2ae, "deck 1: slow turn fwd/back by hand, motor on 15 s, hold
3 s, stop"). `platter.txt` is an `aseqdump` listing without timing; `platter.mid` is `arecordmidi` output:
SMF format 0, division 1000, tempo 1,000,000 µs/quarter, so **1 tick = 1 ms**. 58,650 events over 48.39 s.
What I measured tonight (M4-01 must redo this with a tool and cite it properly; treat my numbers as a
preview, not a citation):

| Phase (s) | What Michael did | CC 6 per s | CC 6 delta per msg | pitch-bend delta per msg |
|---|---|---|---|---|
| 2–8 | slow hand turn forward | ~600–900 | +1 (16× +2) | 2600–3400, scattered |
| 9–15 | slow hand turn backward | ~600–760 | −1 (33× −2) | 3600–3800, scattered |
| 20–36 | motor on | **998–999** | **+2** (16661 of 16970) | **2820–2830** (16400 of 16970) |
| 38–41 | record held still | ~16 | ±1 dither | ≈ 0 (−1 per message) |
| 41–44 | released, motor | 998–999 | +2 | 2820–2830 |
| 45–49 | stopped | ~20 | ±1 dither | ≈ 0 |

- All messages are on channel 1 (0-based 0): CC 6, pitch bend, and note 0 (on/off twice: at 19.24 s for
  95 ms and at 44.67 s for 110 ms, exactly when the motor started and stopped, so note 0 is most likely the
  Play button, **not** a platter touch sensor; the 3 s hold produced no note at all).
- A CC 6 and a pitch bend always arrive as a pair in the same millisecond (29,116 of 29,325 pairs), CC first.
- Net CC 6 ticks during 20–36 s: 31,982 in 16 s = 1,999 ticks/s = **3,598 ticks/rev if the motor was at
  33⅓**. Timestamp advance per tick ≈ 1,411 → clock ≈ **2,822,400 Hz**. Both match the Serato numbers in
  `docs/research/2026-10-19-prior-art.md` §2.
- **Contradicts the hypothesis:** CC 6 is a plain 7-bit running tick counter (values 0..127 wrap
  continuously, 3600 is not a multiple of 128); there are no "28 sectors". The device also caps messages at
  ~1 kHz: at motor speed each message carries 2 ticks. So the decoder must unwrap mod 128 and accept
  multi-tick messages. Record this as a decision (M4-01 step 4).
- The timestamp wraps every 16384/2822400 = 5.8 ms, so below ~0.05× speed it cannot time ticks: use host
  arrival time there (Mixxx scripts have `Date.now()`; the 5 ms poll jitter is acceptable at that speed).
- Hold-phase anomaly: while the record was held, messages kept coming at ~16/s with CC 6 dithering ±1 and
  the timestamp decreasing by 1 per message. Not understood; M4-01 documents it, M5 asks the hardware.

### Where things live, what exists, what does not

- Exists: `tools/midi-send` (the gate, bash) + 8 tests in `tests/midi-send.test.mjs` (stubs amidi/aconnect/
  aplaymidi on PATH; copy that pattern for every tool that shells out). `package.json` runs
  `node --test "tests/**/*.test.mjs"`. Nothing else is built: no `mapping/`, no `tools/lib/`, no dev profile.
- Planned layout (keep it): `tools/<name>` executables (bash or `#!/usr/bin/env node` .mjs without
  extension), shared code in `tools/lib/*.mjs`, tests in `tests/*.test.mjs`, fixtures in `tests/fixtures/`,
  reviews in `.harness/runs/rane-one-mixxx-2026-10-19/reviews/`. Zero npm dependencies (D5).
- `mapping/rane-one-platter.js` is a plain script (no `require`/`import`/`export`). Node tests load it
  with `vm.runInNewContext(source, ctx)` and read `ctx.RaneOnePlatter`. Mixxx loads it by listing it first in
  the XML `<scriptfiles>`. Keep `engine`, `midi`, `print`, `console` out of it.
- Mixxx 2.5.6 Flatpak is at `~/.local/share/flatpak/app/org.mixxx.Mixxx/current/active/files/`. Its bundled
  `share/mixxx/controllers/` has `midi-components-0.0.js`, `engine-api.d.ts`, `midi-controller-api.d.ts`,
  `Numark-V7-scripts.js`, `Numark-NS7-scripts.js`, `Traktor-Kontrol-S4-MK3.js`: read these locally instead
  of fetching. `strings bin/mixxx.bin` contains `scratch_position`, `scratch2`, `scratch2_enable`,
  `rate_ratio`, `playposition`, `slip_enabled`: **2.5.6 has `scratch_position`** (spec §2 question answered
  on the binary; confirm behaviour in M7). GitHub raw is reachable (2.5 branch `eslint.config.cjs` and
  `res/controllers/*.d.ts` return 200). No eslint is installed; use `node --check` tonight, lint in M9.
- ALSA today: `Rane ONE` is seq client 24, rawmidi `hw:2,0,0`; `Midi Through` is client 14. Resolve by
  name every time. `tools/midi-send play` wants a numeric `client:port`; get it from `aconnect -o`.
- `.claude/settings.json` denies `aplaymidi`, `amidi -S`, `pactl set-default-*`, `wpctl set-default`, any
  write under the real profile, and `touch ~/.rane-armed`. `pactl load-module`/`unload-module`, `pw-play`,
  `flatpak ps`/`flatpak kill` and `pw-record` are not pre-allowed; auto mode decides per call. If a call is
  refused, write the command into the progress entry and mark the step skipped; do not work around it.
- The auto-mode classifier refused `grep` on `~/.var/app/org.mixxx.Mixxx/.mixxx/mixxx.cfg` even read-only
  (PII rule). M1 learns Mixxx's config format from the dev profile Mixxx writes itself (start once, stop, read
  `dev-profile/mixxx.cfg` and `dev-profile/controllers/`), not from the real profile.

### Dev Mixxx gotchas (M1-04, M1-05)

- **The system default sink is the Rane One** (`alsa_output.usb-Rane_Rane_ONE_A-00.analog-surround-40`).
  Unrouted audio goes to the controller's outputs. Never start Mixxx without the null sink up and the
  routing in place (`PULSE_SINK=mixxx-dev` via `flatpak run --env=`; inside the sandbox `PULSE_SERVER` is
  set and `libportaudio.so` is bundled, verified with `flatpak run --command=sh`). Verify with
  `pactl list sink-inputs` before trusting it. Alternative if PULSE_SINK is ignored: `pw-metadata`/
  `wpctl` to move the stream, or `PIPEWIRE_NODE`. Never `set-default`.
- The sandbox sees `~/.var/app/org.mixxx.Mixxx/` (listed `cache config data` from inside); `HOME` is the real
  home. `--settings-path ~/.var/app/org.mixxx.Mixxx/dev-profile/` should therefore work; M1-04 proves it.
- Mixxx shows blocking dialogs on a fresh profile (music-library chooser) and when the sound config is
  unusable (sound device error). Seed `mixxx.cfg` and `soundconfig.xml` before the first start; if a dialog
  blocks, the log still shows the device list: read it, stop Mixxx by instance id, fix the seed, retry.
- `flatpak ps` lists instances (a ProtonVPN instance is running; leave it). Stop only the instance id you
  started; `flatpak kill org.mixxx.Mixxx` would also kill a Mixxx Michael started. Write the id to
  `dev-profile/mixxx-dev.instance`.
- GUI needs `WAYLAND_DISPLAY`; this initializer had `wayland-1` and `DISPLAY=:1`. If a session lacks it,
  skip the live steps and say so.
- Keep the mapping output-free (no `<output>`, no `midi.send*`) and bind it only to `Midi Through Port-0`
  at night. The real Rane ONE port stays unbound in the dev profile until Michael says otherwise.
- `--controller-abort-on-warning` makes Mixxx exit on any script warning: a mapping that loads cleanly is the
  evidence. Replays into Midi Through at the capture's 1 kHz rate produce ~2000 log lines per second with
  `--controller-debug`; replay short ranges (`--from/--to`).

### Defaults I set (Michael can overturn any of them in INBOX.md)

- D9 (M1-01 records it): null sink `mixxx-dev`, routing by `PULSE_SINK`, instance-id tracking, night-time
  binding to Midi Through only.
- D10 (M2-01): capture reads the rawmidi device from Node with `process.hrtime` µs; arecordmidi +
  `tools/capture-convert` is the manual fallback (it is what produced the quick capture).
- D11 (M3-01): telemetry JSONL fields `t_us, ticks, timer, playposition, rate_ratio, mode`.
- D12 (M4-01): capture facts above override the Twelve/V7 hypothesis.
- D13 (M4-05): the speed filter chosen on synthetic data.

### Questions for Michael (answer in INBOX.md under `## Answers`)

1. In the quick capture, note 0 on channel 1 fired exactly when the motor started (19.2 s) and stopped
   (44.7 s). Was that the Play button? And during the 3 s hold, was your hand on the record? No touch
   message appeared, so I am assuming the One has no touch sensor on MIDI (hands are detected from motion).
2. Was the motor at 33⅓ (not 45) during the quick capture? The 3600 ticks/rev inference assumes 33⅓.
3. D1 hybrid playback stays the default (spec §7). Any objection to the D9 night rule that the dev Mixxx
   never binds the real Rane ONE port until you say so?
4. Morning job: run `HARDWARE-TESTS.md` (M2-07) when it exists; it is the §6 capture session, under 25 min,
   nothing is sent to the controller.
