# Context pack for `H1-02`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## Discoveries for this feature

- Discovery (H1-01, affects H1-02): A served main still resolves a relative path argument against the process's cwd (readFileSync(a), existsSync(b), resolve(a)); only treekey.mjs uses io.cwd by name. lib/helper.mjs must process.chdir(req.cwd) per request (requests are one at a time) or ask must spawn on a relative path, or a lane that has cd'd gets the wrong file. → entries.jsonl:2
- Discovery (H1-01, affects H1-02): helper.mjs's reply must not exit before its write's callback: on stdin EOF wait for the last write, as runCli does (a pipe write over 64 KB is async). → entries.jsonl:2
- Discovery (H1-01, affects H1-02, H1-02b): main's stderr is still console.error, so in the helper it lands on the helper's stderr: it stays in H1-02b's call-site table. main takes stdin only through io.stdin: readStdin throws /no stdin/ without it, so the helper's request pipe is safe and such a call comes back rc 70 unless ask spawns it first. → entries.jsonl:2
- Discovery (H1-01, affects H1-02, H1-05): git spawned in needs.mjs and overlap.mjs (gitIn) inherits process.env, not io.env: all use git -C <dir>, so the cwd is safe, but a GIT_ variable set on one call would not reach them through the helper. treekey.mjs does pass io.env to its git. → entries.jsonl:2
- Discovery (H1-01, affects run): tests/unit/cli-same.mjs is the shared comparison (sameAsCli, cli, mainOf, sameBytes); it swallows main's console.error. needs.mjs moves a sibling state dir's open question forward, so a test's twin state dir must not sit beside the first. → entries.jsonl:2
- Discovery (init, affects run): Three things the spec's request line (id, script, args, cwd) does not carry decide byte-for-byte identity. stdin: `inbox.mjs insert` (lib/record.sh, piped) and `notify.mjs trim` (lib/notify.sh) read fd 0, which inside the helper is the request pipe. Environment: lib/prompt.sh sets HARNESS_SUITE_LENGTH, HARNESS_SUITE_FAST_LENGTH and HARNESS_FIX on its render.mjs call, lib/record.sh sets HARNESS_CHECK_KEY_IGNORE on `treekey.mjs --pathspec`; treekey also reads HARNESS_CHECK_KEY_MAP, memlint MEMLINT_LINES, needs HARNESS_NOW and HOME. stderr: about 30 call sites in lib/*.sh redirect a served script's stderr (a file, run.log, /dev/null). H1-01 steps 4, H1-02 steps 3 and 6 and H1-02b step 1 cover them. → entries.jsonl:1
- Discovery (init, affects run): tests/checks/84-node-memo.sh and 81-partial-key.sh count node starts through a `node` shim (NODE_COUNT) in a shell that sourced lib/record.sh: once F asks the helper their counts fall. H1-02b sets HARNESS_HELPER=0 for their counting shells, the one kind of edit to an existing check the list allows (the spec's `every existing check passes unchanged` holds for every other file). → entries.jsonl:1
- Discovery (init, affects run): 91 and 92 are the next free check-file numbers. The spec's one NN-resident-helper.sh is planned as two files, as 86/87 were: 91-resident-helper.sh (H1-02: `ask` in a shell that sources lib/record.sh) and 92-resident-helper-run.sh (H1-02b: the stub start and the two-lane run), each with its tier by the 30 s rule; `bash tests/run.sh resident-helper` runs both. → entries.jsonl:1
- Discovery (init, affects run): bash 5.2 here; its manual (Coprocesses) says a coproc's file descriptors are not available in subshells other than command and process substitutions: H1-02 checks `( ask … ) &` and `$( ask … )` on this bash rather than assuming either. None of the eleven served scripts has a module-level `let`/`var`; testcount.mjs reads process.argv at module level (its CLI tail) and has no main yet; render.mjs's main is not wrapped in process.exit. → entries.jsonl:1
- Discovery (init, affects run): harness status at init: RUNNING 1 (this run), QUEUED 0, runner going. H1-04 re-checks before each timed run (the brief: no other suite alive). Its wall is long by design: two solo full suites (last full run 957 s, timeout 2400 s each) and four runs of file 13, one at a time, in the background. → entries.jsonl:1

## What it builds on

- 2026-11-05 10:36 · H1-01 · passes: All eleven served scripts export main(argv, io) → { rc, out } and share lib/cli.mjs's isMain/runCli tail; no shell file changed. 37 unit tests compare main to the CLI. Fixed a spec bug: its write-then-exit tail cuts a pipe at 64 KB, so runCli exits from the write's callback. Fast tier green.; tests 1332 → 1369; files lib/cli.mjs, lib/features.mjs, lib/metrics.mjs, lib/treekey.mjs, lib/testcount.mjs, … → entries.jsonl:2

## Lately in the run

- 2026-11-05 10:19 · init · passes: 6 features, one milestone H1: H1-01 main(argv, io) + lib/cli.mjs; H1-02 lib/helper.mjs + ask (91-resident-helper.sh); H1-02b call sites, lifecycle, helper-on/off logs identical (92-resident-helper-run.sh); H1-03 treekey cut; H1-04 the proof (last build); H1-05 review + docs. Lint clean. → entries.jsonl:1

## Current rules

- A merge survives an origin outage: bounded retries, a card past them, a tag that isn't claimed, gc holds verified work → journal/decisions/2026-11-04-origin-retries.md
- No run ends on a clock unless asked to: `HOURS` defaults to none, and the night leaves the docs → journal/decisions/2026-11-04-no-default-end-time.md
- A red verify opens a fix round, not a card: at most `MAX_FIX_ROUNDS` per milestone, each one counted → journal/decisions/2026-11-04-fix-rounds.md
- The unit tier: node evals become `node:test` files in one process, reported as the suite's PASS/FAIL lines → journal/decisions/2026-11-03-unit-tier.md
- The suite's tiers: every check file declares `fast` or `slow` on line 2, and `tests/run.sh --tier` runs one tier → journal/decisions/2026-11-03-suite-tiers.md
- The resident helper: one warm node process per driver and lane answers the `.mjs` questions over a coproc → journal/decisions/2026-11-03-resident-helper.md
- The fast gate: `check.sh --fast` runs the fast tier, marks `fast-<key>`, and a fast-green is never read as a green → journal/decisions/2026-11-03-fast-gate.md
- A run never starts on a spec that isn't there: `harness start` and `queue add` refuse a spec absent from the run's base ref → journal/decisions/2026-10-31-spec-must-exist.md
- One full run per coding session, last: the prompt's rule and §3 order, and `Suite runs` in the report → journal/decisions/2026-10-31-one-full-run.md
- Fewer node starts: where a stub run's process starts come from, and the cuts C1 makes → journal/decisions/2026-10-31-fewer-node-starts.md
- The suite's length in every prompt: a green marker's `wall` line, and a timeout rule → journal/decisions/2026-10-30-suite-length-in-prompt.md
- A red tree is cached: `red-<key>`, so the next full call on the tree just found red runs nothing → journal/decisions/2026-10-30-red-marker.md

_79 older rules: journal/decisions._
