# Context pack for `C1-01`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## Discoveries for this feature

- Discovery (Q1-02, affects run): lib/spec.sh now has spec_args (a start's run id/--spec/--base), spec_new_run (resume and --brief skips) and spec_entry (a .args file, project config in a subshell); bin/harness spec_refuse and queue add use them → entries.jsonl:3
- Discovery (Q1-02, affects run): editing the worktree while a full check.sh runs can cache red-<key> for the pre-edit tree: never edit during a full run → entries.jsonl:3
- Discovery (Q1-01, affects run): a stub check that starts a new run with --spec <file> now needs the file pushed to the stub's origin/main (SPEC.md is, from suite_setup) → entries.jsonl:2
- Discovery (init, affects run): C1-04's two timed suites (about 15 min each on this box) run outside the suite command, in the session, in the background with a timeout: the full run per session comes on top, so that feature needs a session well over 40 min → entries.jsonl:1
- Discovery (init, affects run): An idle coordinator poll with one lane open and MAX_LANES=1 (the default) makes no F call at all; C1-03's idle-poll check needs MAX_LANES=2 in the stub project's .harness/config.sh so a free slot exists and F unpark, F lanes and answers_hash (inbox.mjs) run each poll → entries.jsonl:1
- Discovery (init, affects run): F unpark mutates the parked file when it unparks: C1-02 may serve a memoized unpark answer only when the stored answer was empty (no mutation); F lanes reads the state dir (verified-/needs- marks), so it is not memoizable on the list alone → entries.jsonl:1

## What it builds on

- 2026-11-03 11:15 · Q1-01 · passes: harness start and queue add now refuse a --spec (or SPEC_FILES) path absent from origin/$MAIN_BRANCH (or --base) before anything is queued or started: lib/spec.sh spec_missing, bin/harness spec_refuse (before cmd_start's first queue_add; in queue add via a config subshell). A resume, --brief alone and add --continue skip it.; tests 1084 → 1094; files lib/spec.sh, bin/harness, tests/checks/83-spec-must-exist.sh, tests/fixtures/check-names.txt, journal/decisions/2026-10-31-spec-must-exist.md → entries.jsonl:2
- 2026-11-03 12:33 · Q1-02 · passes: The queue runner re-checks a start entry's spec at dequeue (lib/spec.sh spec_entry, after the limit/weekly gates, before sync and the mv to done/) and parks a miss in queue/held/ with the line as .why, a parked line in runner.log, then starts the next entry. README, architecture §3/§7/§12 and the decision updated; Opus review: no Critical/Important, 4 minors fixed.; tests 1094 → 1102; files lib/spec.sh, lib/queue.sh, bin/harness, tests/checks/83-spec-must-exist.sh, tests/fixtures/check-names.txt, … → entries.jsonl:3

## Lately in the run

- 2026-11-03 12:48 · verify Q1 · passes: Q1-01 and Q1-02 hold: suite green (init full run, 843 s, 1102 tests), 83-spec-must-exist 18/18 re-run, bash -n clean, check names sorted, docs and decision present. → entries.jsonl:4

## Current rules

- A run never starts on a spec that isn't there: `harness start` and `queue add` refuse a spec absent from the run's base ref → journal/decisions/2026-10-31-spec-must-exist.md
- The suite's length in every prompt: a green marker's `wall` line, and a timeout rule → journal/decisions/2026-10-30-suite-length-in-prompt.md
- A red tree is cached: `red-<key>`, so the next full call on the tree just found red runs nothing → journal/decisions/2026-10-30-red-marker.md
- A mapped path's change runs only its readers: `CHECK_KEY_MAP`, the `part-<key>` sidecar, the partial run, the lint → journal/decisions/2026-10-30-partial-key.md
- The coordinator opens no lane while a lane that exited is not reaped yet → journal/decisions/2026-10-30-opens-wait-for-reap.md
- The lane guard reverts against the lane's merge-base with main, in the index only → journal/decisions/2026-10-30-lane-guard-base.md
- Timing checks bound CPU time; a stopped file's missing names don't void `HARNESS_FAILED=` → journal/decisions/2026-10-30-cpu-time-bound-and-stopped-files.md
- The suite waits on a condition or a barrier, never on the clock; a flake is reproduced with --repeat and fixed at its cause → journal/decisions/2026-10-29-tests-wait-not-sleep.md
- The rerun guard: a red full suite is rerun once; a flake is green, named and counted, never quarantined → journal/decisions/2026-10-29-rerun-guard.md
- Questions wait in `harness needs` until answered: one item per question, moved forward, no push → journal/decisions/2026-10-29-questions-wait.md
- Lanes leftovers: atomic list writes, a record-only main, the finish order, two lint rules, two checks, the suite-ran note → journal/decisions/2026-10-29-lanes-leftovers.md
- The coordinator ends a run only when the lane count its opens used saw no lane → journal/decisions/2026-10-29-lane-count-end-check.md

_70 older rules: journal/decisions._
