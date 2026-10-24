# M2 review findings (M2-08, 2026-10-21)

Input: `reviews/M2.diff` (`git diff ea48c15..35eaac1 -- tools tests mapping docs package.json HARDWARE-TESTS.md
README.md reference ':!tests/fixtures/*.jsonl'`, 5154 lines; ea48c15 is "HARNESS: M1 verified", the point M2 starts
from). Reviewer: one Opus subagent that read the diff from a copy in the scratch dir, read-only, and reproduced
findings with stubs under `/tmp/harness/rane-one-mixxx/rane-one-mixxx-2026-10-19/review-m2/`. No MIDI was sent.
The per-feature reviews (M2-02..M2-06) had already fixed their own findings; this pass looked across M2.

"Failing test first" means the test was added and run red before the fix (the red result is quoted), then the fix
and the test were committed together in the named commit.

No Critical findings. Safety: no path found where replay or another M2 tool reaches the One or bypasses
`tools/midi-send` (replay's only sender is `midi-send play`; Rane names refused before any ALSA call; the route
walk runs armed or not; capture opens `"r"` only; capture-session only runs capture).

## Important

| # | Finding | Outcome |
|---|---------|---------|
| 1 | `tools/lib/jsonl.mjs` `createJsonlWriter.write` ignored `writeSync`'s return: a short write (ENOSPC, quota, RLIMIT_FSIZE) left a cut-off last line, `count` over-reported, and `readJsonl` then refused the whole take, so replay and census could not read any of it. | **Fixed** in 5b4809d: writes loop until done; a failing write is cut back (`ftruncate`) to its last whole line before it throws, and `count` is the lines really in the file. Test first: "a write cut short by the file size limit leaves only whole lines, counted right" (`ulimit -f 2`) failed with `short.jsonl:28: last line has no newline`. |
| 2 | `tools/capture-session` read takes privately (`JSON.parse` of the last line, a `split("\n")` count): a `.part` with a cut-off last line (power loss, SIGKILL, #1) made every `--resume` crash with a SyntaxError, and a take was renamed to `.jsonl` without validation. | **Fixed** in 1169eb9: takes are read with `readJsonl`; a damaged one is renamed to `<file>.part.damaged` (never kept, never deleted) and the step starts over. Tests first: "--resume with a damaged unreviewed take sets it aside…" (the session died after the step header) and "a take that isn't valid JSONL is set aside, never kept" (it offered "Enter keeps the take") both failed. |

## Minor

| # | Finding | Outcome |
|---|---------|---------|
| 3 | `tools/capture-session` handled only SIGINT: a SIGTERM or SIGHUP to the session alone orphaned `tools/capture` and its reader, still holding the One's port. | **Fixed** in 1169eb9: SIGTERM and SIGHUP stop the capture like Ctrl-C, keep the take as `.part`, exit 143/129. Test first: "SIGTERM or SIGHUP to the session alone…" failed (status null, killed by the signal). |
| 4 | `tools/lib/census.mjs` pair order: an LSB-first pair with one orphan LSB at the end (capture stopped mid-pair) tied the neighbour counts and flipped to MSB-first, pairing every value wrongly (min 10 / max 148 instead of 100 / 138). | **Fixed** in 68ad766: a tie goes to the direction whose neighbours are closer in time (the two halves of a value come together), then MSB first. Test first: "a capture stopped mid-pair ties the neighbour counts…" failed with `[10, 148]`. |

## Duplication (step 2) and simplification

| # | Finding | Outcome |
|---|---------|---------|
| 5 | `tools/capture-convert` joined JSONL lines itself (`formatLine(toRecord(…))`). | **Fixed** in 5b4809d: `formatMessages(msgs, t_us)` exported from jsonl.mjs. |
| 6 | Local-date formatting in `tools/census` duplicated `localDate` in `tools/lib/capture-session.mjs`. | **Fixed** in 1169eb9: `tools/lib/local-date.mjs`, used by both. |
| 7 | `hex` in capture-convert and smf.mjs, `CHANNEL_LEN` in smf.mjs, and the type-name tables in jsonl.mjs and midi-parse's `describe` were private copies. | **Fixed** in 5b4809d: `hexBytes`, `CHANNEL_LEN`, `CHANNEL_TYPE`, `SYSTEM_TYPE` exported from midi-parse.mjs; `describe` uses the tables (its tests unchanged and green). |
| 8 | `tools/replay`'s `aconnect -o` client lookup is a second parser beside midi-send's `sed`; the regexes differ for odd client names. Not a bypass (replay passes a number; its own route walk is the gate). | Deferred: both refuse rather than mis-route; one shared lookup belongs with M1 #8/#19 (one shared route walk). |
| 9 | `jsonl.mjs` `derive` had a special branch for truncated SysEx. | **Fixed** in 5b4809d: `feed` + `flush` and the existing round-trip check; same accept/reject on `F001`, `F00190`, `F001F8`, `F00102F7`, `F0`. |
| 10 | `tools/replay` re-derives the drop category from the bytes instead of `rec.type`. | No change: the byte test is one line; `rec.type` would need a name→category table. |
| 11 | `tools/capture` called `toRecord` a second time per message only to count types. | **Fixed** in 5b4809d: `writer.write` returns the records it wrote. capture-convert's `summary()` keeps its one call per message (it runs once). |

Step 2 evidence (after the fixes): `grep -nE 'JSON\.(parse|stringify)|formatLine|"t_us"' tools/capture
tools/capture-convert tools/capture-session tools/replay tools/census tools/lib/*.mjs` outside jsonl.mjs finds only
capture's reader↔parent error frame and census/dev-seed error messages; no JSONL line is built or read anywhere but
`tools/lib/jsonl.mjs`. capture, capture-convert, capture-session, replay and census import jsonl.mjs; jsonl.mjs and
smf.mjs import midi-parse.mjs.

Housekeeping: an orphaned `capture-stub` (ppid 1, from a review repro of #3) was killed by its pid; no other process
from this session was left running.
