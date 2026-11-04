# Context pack for `U1-03`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## Discoveries for this feature

- Discovery (U1-02, affects U1-03, U1-04, U1-06): A check that is an eval plus a CLI run splits: the part its name describes keeps the name, the other gets a new fixture name (decisions/2026-11-03-unit-tier, default); 12-journal gained 3 bash names and 1 unit name. → entries.jsonl:3
- Discovery (U1-02, affects U1-03, U1-04): An eval run under TZ=… node becomes a test that sets process.env.TZ and restores it in finally (node rereads it on assignment); tests stay synchronous so the zone can't leak. → entries.jsonl:3
- Discovery (U1-02, affects U1-03, U1-04): assert.throws(fn, /re/) tests String(err) ("Error: …"): an anchored message regex needs { message: /^…/ }. → entries.jsonl:3
- Discovery (U1-02, affects run): Memlint counts the Gotchas comment line: CLAUDE.md's section is at its 15-line cap now; a new line must replace one. → entries.jsonl:3
- Discovery (U1-01, affects U1-02, U1-03, U1-04, U1-05, U1-06): `node --test tests/unit/` fails on node 24.21 (ERR_UNSUPPORTED_DIR_IMPORT, prints ✖): every later step's `node --test --test-isolation=none tests/unit/ prints no ✖ line` must read `tests/unit/*.test.mjs` → entries.jsonl:2
- Discovery (U1-01, affects U1-06, run): The CLAUDE.md check went in tests/checks/79-suite-length.sh (already in CHECK_KEY_MAP for CLAUDE.md), not 33-suite-runner.sh: a CLAUDE.md read there would have to join the map (82-key-map-lint). → entries.jsonl:2
- Discovery (U1-01, affects U1-02, U1-03, U1-04, U1-05, U1-06): The reporter prints a non-assertion error's stack without node: frames, and a skipped test as `PASS <name> (skipped: <reason>)` (run.sh strips the suffix); decisions/2026-11-03-unit-tier has empty `## Kept evals` and `## Measured` sections for U1-02..05. → entries.jsonl:2
- Discovery (init, affects U1-01, U1-03, run): Under `node --test --test-isolation=none <glob>` process.argv is [node, <glob>] (checked 2026-11-03 in /tmp): lib/testcount.mjs's CLI tail (process.argv.slice(2)) is inert on import, so no lib/ guard is needed for the move; a module that reads argv[1] would not be. → entries.jsonl:1

## What it builds on

- 2026-11-03 20:16 · U1-01 · passes: The unit tier: tests/unit/reporter.mjs (PASS/FAIL lines, the failure indented), tests/checks/00-unit-tier.sh (one node --test process, own N/M, a no-FAIL-line guard, TEST_UNIT_DIR), testcount's eval moved to tests/unit/testcount.test.mjs under its old name, CLAUDE.md's node ≥ 22.8 and tier lines, the decision file.; tests 1141 → 1146; files tests/unit/reporter.mjs, tests/unit/testcount.test.mjs, tests/checks/00-unit-tier.sh, tests/checks/33-suite-runner.sh, tests/checks/79-suite-length.sh, … → entries.jsonl:2

## Lately in the run

- 2026-11-03 20:41 · U1-02 · passes: The 37 evals of 51-view-pure and 12-journal-pure moved to tests/unit/view.test.mjs (20), entries.test.mjs (14) and memlint.test.mjs (2) under their exact names, each compared value asserted; the CLI parts stay bash checks (3 under new names, the validate cases joined the vx check). Full run 1150/1150, conformance PASS.; tests 1146 → 1150; files tests/unit/view.test.mjs, tests/unit/entries.test.mjs, tests/unit/memlint.test.mjs, tests/checks/51-view-pure.sh, tests/checks/12-journal-pure-e4-entrys.sh, … → entries.jsonl:3
- 2026-11-03 19:35 · init · passes: 6 features, one milestone U1: U1-01 the node:test reporter, tests/checks/00-unit-tier.sh, tests/unit/ (testcount's eval first), CLAUDE.md, the decision file; U1-02 the 37 evals of 51-view-pure and 12-journal-pure; U1-03 the nine smaller -pure- files; U1-04 the scenario files' evals, kept ones listed; U1-05 the before/after table (sonnet); U1-06 review + simplify, docs. → entries.jsonl:1

## Current rules

- The unit tier: node evals become `node:test` files in one process, reported as the suite's PASS/FAIL lines → journal/decisions/2026-11-03-unit-tier.md
- A run never starts on a spec that isn't there: `harness start` and `queue add` refuse a spec absent from the run's base ref → journal/decisions/2026-10-31-spec-must-exist.md
- One full run per coding session, last: the prompt's rule and §3 order, and `Suite runs` in the report → journal/decisions/2026-10-31-one-full-run.md
- Fewer node starts: where a stub run's process starts come from, and the cuts C1 makes → journal/decisions/2026-10-31-fewer-node-starts.md
- The suite's length in every prompt: a green marker's `wall` line, and a timeout rule → journal/decisions/2026-10-30-suite-length-in-prompt.md
- A red tree is cached: `red-<key>`, so the next full call on the tree just found red runs nothing → journal/decisions/2026-10-30-red-marker.md
- A mapped path's change runs only its readers: `CHECK_KEY_MAP`, the `part-<key>` sidecar, the partial run, the lint → journal/decisions/2026-10-30-partial-key.md
- The coordinator opens no lane while a lane that exited is not reaped yet → journal/decisions/2026-10-30-opens-wait-for-reap.md
- The lane guard reverts against the lane's merge-base with main, in the index only → journal/decisions/2026-10-30-lane-guard-base.md
- Timing checks bound CPU time; a stopped file's missing names don't void `HARNESS_FAILED=` → journal/decisions/2026-10-30-cpu-time-bound-and-stopped-files.md
- The suite waits on a condition or a barrier, never on the clock; a flake is reproduced with --repeat and fixed at its cause → journal/decisions/2026-10-29-tests-wait-not-sleep.md
- The rerun guard: a red full suite is rerun once; a flake is green, named and counted, never quarantined → journal/decisions/2026-10-29-rerun-guard.md

_73 older rules: journal/decisions._
