# Context pack for `U1-01`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## Discoveries for this feature

- Discovery (init, affects U1-01, U1-03, run): Under `node --test --test-isolation=none <glob>` process.argv is [node, <glob>] (checked 2026-11-03 in /tmp): lib/testcount.mjs's CLI tail (process.argv.slice(2)) is inert on import, so no lib/ guard is needed for the move; a module that reads argv[1] would not be. → entries.jsonl:1
- Discovery (init, affects U1-01): A test file that throws at import gets node's own test:fail event for the file, so the reporter prints `FAIL <absolute file path>`; the `exited <rc> with no FAIL line` guard in 00-unit-tier.sh fires only for a non-zero exit with no FAIL line, e.g. `process.exit(3)` at import. U1-01's check uses process.exit for the guard line and accepts either shape for a throw. → entries.jsonl:1
- Discovery (init, affects U1-01): The reporter spike (/tmp, deleted): node expands the quoted `*.test.mjs` glob itself, `--test-reporter=<path> --test-reporter-destination=stdout` prints only the reporter's lines on stdout, and the assert diff for `assert.equal(1, 2)` is `Expected values to be strictly equal:` then a blank line then `1 !== 2`, each indented two spaces by the reporter. → entries.jsonl:1

## Lately in the run

- 2026-11-03 19:35 · init · passes: 6 features, one milestone U1: U1-01 the node:test reporter, tests/checks/00-unit-tier.sh, tests/unit/ (testcount's eval first), CLAUDE.md, the decision file; U1-02 the 37 evals of 51-view-pure and 12-journal-pure; U1-03 the nine smaller -pure- files; U1-04 the scenario files' evals, kept ones listed; U1-05 the before/after table (sonnet); U1-06 review + simplify, docs. → entries.jsonl:1

## Current rules

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
- Questions wait in `harness needs` until answered: one item per question, moved forward, no push → journal/decisions/2026-10-29-questions-wait.md

_72 older rules: journal/decisions._
