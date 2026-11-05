# Context pack for `H1-02b`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## Discoveries for this feature

- Discovery (H1-02, affects H1-02b): Only the shell that sourced record.sh starts a helper, and a $( ask ) before it has one spawns and starts none. Most driver call sites are $( ), so H1-02b must call helper_start itself in run_paths or at the lane's start, outside any 2> redirect: the helper's stderr is the shell's at that moment for its whole life. → entries.jsonl:3
- Discovery (H1-02, affects H1-02b): helper_start clobbers $!: coproc sets it. Today's four `$!` reads (check.sh:67, driver.sh:96 and :161, record.sh:294) are each right after their `&`, and `wait -n` in lane_wait names its pids, so none breaks; a new `$!` read must stay adjacent. No bare `wait` in lib/ or bin/ (it would wait on the coproc for ever). → entries.jsonl:3
- Discovery (H1-02, affects H1-02b): A served script's stderr goes to the helper's stderr whatever the call redirects: `F x 2> /dev/null` no longer silences a throw's stack, and `2>> run.log` no longer lands there. needs.mjs fields prints NULs (the helper declines, the spawn answers): that call site stays a spawn. → entries.jsonl:3
- Discovery (H1-02, affects H1-02b, H1-04): ask spawns in a ( ), a pipeline's side or a job: bash closes the coproc's fds there and leaves the variables. So `ask x | y` is a spawn, and a check counting starts must not wrap ask in ( ). `export -p`-free environment enumeration is compgen -e through scratch's helper-<shell>.names. → entries.jsonl:3
- Discovery (H1-02, affects H1-02b): Scratch gains helper-<shell>.lock, .names and, after a failure, .restarts. A check that lists a run's scratch directory exactly would see them once call sites ask. → entries.jsonl:3
- Discovery (H1-01, affects H1-02, H1-02b): main's stderr is still console.error, so in the helper it lands on the helper's stderr: it stays in H1-02b's call-site table. main takes stdin only through io.stdin: readStdin throws /no stdin/ without it, so the helper's request pipe is safe and such a call comes back rc 70 unless ask spawns it first. → entries.jsonl:2
- Discovery (H1-01, affects H1-02b, H1-05): A throw now exits 70 in all eleven (10 of them exited 1 uncaught). lib/record.sh:447 reads `(( $? == 1 )) || return 0` after entries.mjs validate, so a validate that throws (an unreadable entry.json) now skips the resume and goes on to the ingest. No check depends on it; H1-05 should look at that line. → entries.jsonl:2
- Discovery (H1-01, affects run): tests/unit/cli-same.mjs is the shared comparison (sameAsCli, cli, mainOf, sameBytes); it swallows main's console.error. needs.mjs moves a sibling state dir's open question forward, so a test's twin state dir must not sit beside the first. → entries.jsonl:2
- Discovery (init, affects run): Three things the spec's request line (id, script, args, cwd) does not carry decide byte-for-byte identity. stdin: `inbox.mjs insert` (lib/record.sh, piped) and `notify.mjs trim` (lib/notify.sh) read fd 0, which inside the helper is the request pipe. Environment: lib/prompt.sh sets HARNESS_SUITE_LENGTH, HARNESS_SUITE_FAST_LENGTH and HARNESS_FIX on its render.mjs call, lib/record.sh sets HARNESS_CHECK_KEY_IGNORE on `treekey.mjs --pathspec`; treekey also reads HARNESS_CHECK_KEY_MAP, memlint MEMLINT_LINES, needs HARNESS_NOW and HOME. stderr: about 30 call sites in lib/*.sh redirect a served script's stderr (a file, run.log, /dev/null). H1-01 steps 4, H1-02 steps 3 and 6 and H1-02b step 1 cover them. → entries.jsonl:1
- Discovery (init, affects run): tests/checks/84-node-memo.sh and 81-partial-key.sh count node starts through a `node` shim (NODE_COUNT) in a shell that sourced lib/record.sh: once F asks the helper their counts fall. H1-02b sets HARNESS_HELPER=0 for their counting shells, the one kind of edit to an existing check the list allows (the spec's `every existing check passes unchanged` holds for every other file). → entries.jsonl:1
- Discovery (init, affects run): 91 and 92 are the next free check-file numbers. The spec's one NN-resident-helper.sh is planned as two files, as 86/87 were: 91-resident-helper.sh (H1-02: `ask` in a shell that sources lib/record.sh) and 92-resident-helper-run.sh (H1-02b: the stub start and the two-lane run), each with its tier by the 30 s rule; `bash tests/run.sh resident-helper` runs both. → entries.jsonl:1
- Discovery (init, affects run): bash 5.2 here; its manual (Coprocesses) says a coproc's file descriptors are not available in subshells other than command and process substitutions: H1-02 checks `( ask … ) &` and `$( ask … )` on this bash rather than assuming either. None of the eleven served scripts has a module-level `let`/`var`; testcount.mjs reads process.argv at module level (its CLI tail) and has no main yet; render.mjs's main is not wrapped in process.exit. → entries.jsonl:1
- Discovery (init, affects run): harness status at init: RUNNING 1 (this run), QUEUED 0, runner going. H1-04 re-checks before each timed run (the brief: no other suite alive). Its wall is long by design: two solo full suites (last full run 957 s, timeout 2400 s each) and four runs of file 13, one at a time, in the background. → entries.jsonl:1

## What it builds on

- 2026-11-05 11:06 · H1-02 · passes: lib/helper.mjs answers {id,script,args,cwd,env} one at a time as `<id> <rc> <bytes>` + bytes; ask in lib/record.sh asks over a coproc, spawning whenever off, absent, busy or broken. ask 3.1 ms, a spawn 32.8 ms. No call site uses it yet. New 91-resident-helper.sh, 50 checks, fast tier. Fast tier green.; tests 1369 → 1419; files lib/helper.mjs, lib/record.sh, lib/cli.mjs, tests/checks/91-resident-helper.sh, tests/fixtures/check-names.txt, … → entries.jsonl:3

## Lately in the run

- 2026-11-05 10:36 · H1-01 · passes: All eleven served scripts export main(argv, io) → { rc, out } and share lib/cli.mjs's isMain/runCli tail; no shell file changed. 37 unit tests compare main to the CLI. Fixed a spec bug: its write-then-exit tail cuts a pipe at 64 KB, so runCli exits from the write's callback. Fast tier green.; tests 1332 → 1369; files lib/cli.mjs, lib/features.mjs, lib/metrics.mjs, lib/treekey.mjs, lib/testcount.mjs, … → entries.jsonl:2
- 2026-11-05 10:19 · init · passes: 6 features, one milestone H1: H1-01 main(argv, io) + lib/cli.mjs; H1-02 lib/helper.mjs + ask (91-resident-helper.sh); H1-02b call sites, lifecycle, helper-on/off logs identical (92-resident-helper-run.sh); H1-03 treekey cut; H1-04 the proof (last build); H1-05 review + docs. Lint clean. → entries.jsonl:1

## Current rules

- A merge survives an origin outage: bounded retries, a card past them, a tag that isn't claimed, gc holds verified work → journal/decisions/2026-11-04-origin-retries.md
- No run ends on a clock unless asked to: `HOURS` defaults to none, and the night leaves the docs → journal/decisions/2026-11-04-no-default-end-time.md
- A red verify opens a fix round, not a card: at most `MAX_FIX_ROUNDS` per milestone, each one counted → journal/decisions/2026-11-04-fix-rounds.md
- The unit tier: node evals become `node:test` files in one process, reported as the suite's PASS/FAIL lines → journal/decisions/2026-11-03-unit-tier.md
- The suite's tiers: every check file declares `fast` or `slow` on line 2, and `tests/run.sh --tier` runs one tier → journal/decisions/2026-11-03-suite-tiers.md
- The resident helper: one warm node process per driver and lane answers the `.mjs` questions over a coproc → journal/decisions/2026-11-03-resident-helper.md
- The fast gate: `check.sh --fast` runs the fast tier, marks `fast-<key>`, and a fast-green is never read as a green → journal/decisions/2026-11-03-fast-gate.md

_84 older rules: journal/decisions._
