# M1 review findings (M1-06, 2026-10-19)

Input: `reviews/M1.diff` (`git diff main...HEAD -- tools tests mapping docs package.json`, 3268 lines, at 3fef1af
plus the usage fix of 1059b30). Reviewer: one Opus subagent that read the diff from that file, read-only, and
reproduced findings with stubs under `/tmp/harness/rane-one-mixxx/rane-one-mixxx-2026-10-19/review/`.
Earlier per-feature reviews (M1-02..M1-05) had already fixed their own findings; this pass looked across M1.

"Failing test first" means the test was added and run red before the fix (counts below), then the fix and the test
were committed together in the named commit.

## Important

| # | Finding | Outcome |
|---|---------|---------|
| 1 | `tools/null-sink`: `NULL_SINK_SETTLE=08`, `09` or a huge value made `(( settle * 4 ))` fail or overflow, so the default-sink watch never ran and `up` still exited 0. | **Fixed** in 680b5f2: same bound as mixxx-dev, `^(0\|[1-9][0-9]{0,3})$`. Tests first: 4 new cases in `tests/null-sink.test.mjs` (`08`, `09`, `10000`, `99999999999999999999`) failed (exit 0, not 2). |
| 2 | `tools/null-sink`: the default-sink check passed trivially when `pactl info` had no `Default Sink:` line (other locale, changed output): before and after were both empty. | **Fixed** in 680b5f2: `export LC_ALL=C`, and `up` refuses before loading if no default sink is visible. Tests first: "refuses before loading when pactl info shows no default sink" and "reads pactl in the C locale…" (stub prints `Standard-Ziel:` unless `LC_ALL=C`) both failed. |
| 3 | `tools/midi-send`: `RANE_ARM_FILE` overrides `~/.rane-armed`; test-only env hooks in `mixxx-dev`/`null-sink` (`MIXXX_DEV_NULL_SINK`, `MIXXX_DEV_PROC`, `MIXXX_DEV_LAUNCHER`) can switch checks off. | **Fixed for the gate** in 2eb7c11: the arm file is `$HOME/.rane-armed` only; the midi-send tests arm through a temp `HOME`. Test first: "RANE_ARM_FILE pointing at an existing file does not arm the gate" failed (exit 0 on `raw hw:2,0,0`). The 8 original safety tests stay green. The mixxx-dev/null-sink test hooks are **deferred**: they need a deliberate env var (as does `HOME=`), and the tests strip them from the inherited env. |
| 4 | `tools/midi-send raw` had no route check: a snd-virmidi device forwards what is written to it to its seq subscribers, so `raw hw:<virmidi>` reached a subscribed Rane unarmed. | **Fixed** in 5002172: unarmed `raw` walks from every port of the card's kernel seq client (`[type=kernel,card=N]`), with the same transitive walk as `play`; an unparseable card or a failing `aconnect -l` refuses (exit 3). Tests first: "refuses a virtual device whose seq client is subscribed to the Rane One" (direct and through a user client) and "refuses when the subscriptions cannot be listed" failed; the 8 original safety tests stay green. |
| 5 | Routing is checked once at start; if `mixxx-dev` disappears (PipeWire restart, external unload) WirePlumber moves the dev Mixxx stream to the default sink, the Rane One. Plausible, not reproduced. | **Fixed** in e27284d: `PULSE_PROP_OVERRIDE` adds `node.dont-reconnect=true node.dont-fallback=true` (WirePlumber 0.5.12 here: `linking/prepare-link.lua` does not move a dont-reconnect stream; `find-defined-target.lua` destroys a dont-fallback stream whose target is missing). Test first: the start test now reads the exact argv and failed on the new value. Live: see "Live check" below. The move itself was **not** provoked (that would risk a stream on the Rane). |

## Minor

| # | Finding | Outcome |
|---|---------|---------|
| 6 | `mixxx-dev start` checks the sink before taking the lock; `null-sink down` never takes `mixxx-dev.lock`, so a concurrent `down` can race a start. | Deferred. #5's `dont-fallback` makes the race fail closed (no target → stream destroyed, then `route()` fails the start). |
| 7 | `mixxx-dev` `on_exit` signalled the launcher pid after it was known to be dead (pid reuse). | **Fixed** in e27284d: only kills while `kill -0` succeeds. No test: `kill` is a bash builtin the stubs cannot see. |
| 8 | `mixxx-dev`'s pre-launch Rane check looks one hop from Midi Through; `midi-send` walks transitively. | Deferred, with #19 (one shared walk). |
| 9 | `mixxx-dev`: `id` was set after `mv` of the instance file; a failing `mv` would leave the new Mixxx running. | **Fixed** in e27284d: `id=$got` before the `mv`. |
| 10 | `profile.sh` derives the real profile from `$HOME`, so `HOME=/tmp/x` plus `MIXXX_DEV_PROFILE=<real>` passes. | Deferred; needs two deliberate overrides (same reasoning as #3). |
| 11 | `null-sink down` treated a missing default launcher as "stopped" (pre-M1-04 fallback). | **Fixed** in 680b5f2: a missing launcher is "maybe running". Test "down refuses when the default launcher tools/mixxx-dev is missing" failed first. |
| 12 | `dev-seed.mjs` version check was not anchored; a version with newlines would write extra keys into mixxx.cfg. | **Fixed** in e27284d: exactly `x.y.z` in `applyCfg` and the CLI, and in `mixxx-dev`. Test "applyCfg and the CLI refuse a version that is not exactly x.y.z" failed first. |
| 13 | `midi-send` cannot see PipeWire's MIDI bridge routing (direct addressing, no seq subscription). | Deferred (already listed as not covered in the M1 plan). Matters only if a PipeWire MIDI bridge is set up to forward to the Rane. |
| 14 | `midi-send raw` passed any bytes to `amidi -S`. | **Fixed** in 5002172: each byte argument must be hex pairs, else usage/exit 2. Test failed first. |
| 15 | `tests/null-sink.test.mjs`: settle cases missed `08`/overflow; the hijack stub only changed the default synchronously. | **Fixed** in 680b5f2: cases added (#1) and a `hijack-at` stub state that flips the default on the Nth `pactl info`, tested with `NULL_SINK_SETTLE=1`. |
| 16 | `tests/mapping-xml.test.mjs`: the hostile `midi` proxy's error is swallowed by the guard, so a `midi["sendShortMsg"]` would pass. | **Fixed** in 737053e: a recording `midi` proxy, permissive `engine`/`script`, every handler called, no `midi` property may be read. Mutation-checked: `var m = midi; m["sendShortMsg"](…)` in `init` fails the new test (the lexical check did not catch it). |
| 17 | `tests/mixxx-dev.test.mjs` never observes the launcher kill path. | Deferred (see #7). |

## Simplification

| # | Finding | Outcome |
|---|---------|---------|
| 18 | Remove the pre-M1-04 launcher fallback in `null-sink`. | Done with #11. |
| 19 | Two `aconnect -l` parsers (`midi-send`, `mixxx-dev`) with different semantics; extract one walk. | Deferred to M2, where `tools/replay` adds a third user of the walk. |
| 20 | Tests repeat the env filter and stub writers; a shared `tests/lib/stub-env.mjs`. | Deferred; no behaviour change. |

## Added by this session (not from the reviewer)

- Every tool prints `usage: tools/<name> …` (it printed the raw `#   tools/…` comment line) and exits 2 on bad
  arguments, before running anything: 1059b30, `tests/tools-usage.test.mjs` (20 tests, 19 failed first). The test
  discovers `tools/*`, so a new tool without bad-argument cases fails the suite.

## Evidence (feature step 3)

Bad arguments (temp `HOME` and profile, nothing created):

```
$ tools/null-sink sideways → exit 2 · usage: tools/null-sink up|down|status
$ tools/mixxx-dev restart → exit 2 · usage: tools/mixxx-dev start|stop|status|log [n]
$ tools/install-mapping now → exit 2 · usage: tools/install-mapping
$ tools/midi-send play 14:0 → exit 2 · usage: tools/midi-send raw  <rawmidi device, e.g. hw:3,0,0> <hex bytes…>    (amidi -S)
```

`tests/tools-usage.test.mjs` also checks that no stubbed command (flatpak, pactl, aplaymidi, amidi, aconnect, pw-*)
runs and no profile is created on those paths.

Greps over the M1 tree (tools, mapping):

```
$ git grep -nE '\b(amidi|aplaymidi)\b' -- tools mapping ':!tools/midi-send'
(no output, rc=1)
$ git grep -nE 'rtmidi|mido|midi\s*\.\s*send|sendShortMsg|sendSysex' -- tools mapping
mapping/Rane-One-scripts.js:3:// midi.send* calls).          ← a comment saying there are none
$ git grep -n 'Mixxx/\.mixxx' -- tools mapping
tools/lib/profile.sh:3,7,8                                  ← the guard that refuses it (exit 3)
$ git grep -n 'set-default' -- tools
(no output, rc=1)
```

The only writes the tools make go under `$PROFILE` (the dev profile, checked by `profile_guard`/`guard_path`) and
`/tmp`; `tests/{install-mapping,null-sink,mixxx-dev}.test.mjs` run every write path with a temp `HOME` containing a
fake `.mixxx` and assert it stays empty.

## Live check (#5)

A Sonnet subagent ran it, and I re-checked the end state and the saved `pw-dump`. Run at 17:50 EDT:

- Before: Default Sink `alsa_output.usb-Rane_Rane_ONE_A-00.analog-surround-40`; `mixxx-dev status` `stopped`;
  `null-sink status` `absent`.
- `tools/null-sink up` (module 536870916), `tools/install-mapping`, `tools/mixxx-dev start` → `running: 1023889390`.
- `pactl list sink-inputs`: input #1754, `application.name = "mixxx-dev"`, `Sink: 1692` (= `mixxx-dev`),
  `node.dont-reconnect = "true"`, `node.dont-fallback = "true"`. Nothing of ours on the Rane (779) or PCI (172).
- `pw-dump`: node 102 `node.dont-reconnect: true`, `node.dont-fallback: true`, `target.object: "mixxx-dev"`.
- After: `stopped 1023889390`, `flatpak ps` shows only `com.protonvpn.www`, `null-sink status` `absent`, the
  Default Sink is the same as before.

Not observed: what happens when the sink vanishes under a running Mixxx (not provoked; see #5).
