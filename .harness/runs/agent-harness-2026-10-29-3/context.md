# Context pack for `S1`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## This feature's earlier attempts

- Dead end (S1-05, 05-S1-05): removing green-<key> too when an init failed — a green isn't harmful and carries the test count; only the red marker answers wrongly → entries.jsonl:6
- Dead end (S1-05, 05-S1-05): a Gotchas line about red-<key> answering a red tree's second full call — memlint counts the section's comment line: 15 bullets is 16 lines, over its cap; dropped rather than displace one → entries.jsonl:6
- Dead end (S1-04, 04-S1-04): grepping harness-log.md for `suite red before the session` — run_init writes it with log(), so it is only in $STATE/run.log; the check reads run.log → entries.jsonl:5
- Dead end (S1-03, 03-S1-03): the full suite after the check.sh change alone — 08's ck() runs many CHECK_CMDs on one tree: after its `exit 3` every full call answered the cached red (the 124 line and the TERM check); 74's fe needed finish's suite to run on C's red tree → entries.jsonl:4
- Dead end (S1-02, 02-S1-02): {{SUITE_LENGTH}} in prompts/parts/run.md's Suite line, as the spec and step 4 say — 08/13/14/15 require two sessions' prompts byte-identical through # This session; a per-tree wall differs per session (stub walls 0 vs 1 s flaked 08), and every real run would split the shared prefix (decisions/2026-10-21-static-first-prompts, E3-05 amendment) → entries.jsonl:3
- Question (S1-05): Review minor M5 left: 79's rw check can't tell the rerun's wall from start-to-end (a slow-first/instant-rerun inverse case would). And I1's residue: a session on a tree cached red by something outside the key (a port, a tool) has no form that runs the full suite on it; should check.sh get an escape hatch (e.g. HARNESS_CHECK_FRESH=1 skipping the red lookup), default: none? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-10-29-3/slot-0/lib/check.sh:77, /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-10-29-3/slot-0/journal/decisions/2026-10-30-red-marker.md → entries.jsonl:6
- Question (S1-02): S1-02 put the suite's wall under # This session (a `Suite: last full run …` line) rather than in run.md's This run Suite line, because the latter split the prompts' shared prefix that 08/13/14/15 check (default; decision file). Keep it there, or move it to run.md and relax the prefix checks to stop at the Suite line? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-10-29-3/slot-0/journal/decisions/2026-10-30-suite-length-in-prompt.md, /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-10-29-3/slot-0/prompts/coding.md:132 → entries.jsonl:3
- 2026-10-30 00:46 · S1-05 · passes: S1 review: 0 Critical, 3 Important, 5 Minor. Fixed, each red first: I1 run_init keeps no red-<key> around a failed init; I2 the cached red shows check-<key>.out or says it is gone; I3 suite_length reads every green wall before a red; M1 no red cached for codes ≥128; M2 atomic marker writes; M3 green_count in record.sh; M4. Docs: architecture §3/§4/§7/prompt, README.; tests 1039 → 1044; files lib/check.sh, lib/record.sh, lib/prompt.sh, tests/checks/79-suite-length.sh, tests/checks/80-red-marker.sh, … → entries.jsonl:6
- 2026-10-30 00:03 · S1-04 · passes: run_init fresh removes red-<key> beside green-<key> (lib/record.sh, one line), so verify's tree always runs in full. 80-red-marker gains 3 stub-run checks with a counting CHECK_CMD: the retry's init is the cached red (2 suite calls on the red tree), and STUB_PLANT_MARKERS (new stub hook) proves verify clears both markers. Decision red-marker gains the driver bullet.; tests 1036 → 1039; files lib/record.sh, tests/checks/80-red-marker.sh, tests/stub-claude.sh, tests/fixtures/check-names.txt, journal/decisions/2026-10-30-red-marker.md → entries.jsonl:5
- 2026-10-29 23:42 · S1-03 · passes: check.sh full form writes red-<key> (rc, HARNESS_FAILED names, wall, RED line) after a red where both runs were `exit <rc> after`, answers the next full call on that tree from it, removes it on green; subsets read none. New 80-red-marker (8 checks); 08, 74 adapted; 10-e2 drops S1-02s wall line from its prompt compare; decisions/2026-10-30-red-marker.; tests 1028 → 1036; files lib/check.sh, tests/checks/80-red-marker.sh, tests/checks/08-scope-sh-l1-02-run-capped-services-gc-scratch.sh, tests/checks/74-flakes-run.sh, tests/fixtures/check-names.txt, … → entries.jsonl:4
- 2026-10-29 22:50 · S1-02 · passes: green-<key> is two lines (count, wall <s>); check.sh/run_init/tests_end read line 1 with read -r; prompt.sh suite_length gives SUITE_LENGTH. Deviation (default): the wall line sits under # This session in coding/initializer/verify/resolve, not run.md's Suite line (that broke 08's prefix check: walls 0 vs 1 s); run.md points there. A whole-suite rerun sets the wall. Rule, CLAUDE.md, decision.; tests 1016 → 1028; files lib/check.sh, lib/record.sh, lib/prompt.sh, prompts/parts/run.md, prompts/coding.md, … → entries.jsonl:3
- 2026-10-29 21:53 · S1-01 · passes: Wrote docs/plans/2026-10-30-S1-suite-time.md: the three marker readers (check.sh:67, run_init record.sh:461, tests_end record.sh:488) and their read -r, the wall line, suite_length in prompt_render, the red-<key> lines and placement, the driver's fresh rm, the checks of 34/79/80 with a counting run.env CHECK_CMD and STUB_PLANT_MARKERS, both decision files. No code changed.; tests 1016 → 1016; files docs/plans/2026-10-30-S1-suite-time.md → entries.jsonl:2

## Discoveries for this feature

- Discovery (S1-05, affects S2, run): run_init now writes init-failed in the lane dir (driver: state dir) while an init fails; the next run_init drops the tree's red-<key> before its suite → entries.jsonl:6
- Discovery (S1-05, affects S2, run): the cached red answer no longer prints the stored RED line verbatim: its `— last lines of …:` tail is replaced with check-<key>.out's or `its output is gone from scratch` → entries.jsonl:6
- Discovery (S1-05, affects S2, run): suite_length reads every green marker (cwd tree's, then newest) before any red one → entries.jsonl:6
- Discovery (S1-04, affects S1-05, run): the retry's init output is best read from its session prompt ($STATE/logs/<nn>-<id>.prompt.md, ## Init output): init.out in scratch is overwritten by every later run_init, KEEP_SCRATCH or not → entries.jsonl:5
- Discovery (S1-04, affects S1-05): step 1 already held after S1-03 (the retry's run_init answers from the marker with no driver change); only the verify invariant needed the record.sh line → entries.jsonl:5
- Discovery (S1-03, affects S1-04, S1-05): a green run removing a planted red-<key> is only reachable when the marker appears mid-run (the lookup answers first): 80's `plant` mode has the stub suite write it → entries.jsonl:4
- Discovery (S1-03, affects S1-04, S1-05): 74-flakes-run's fe now makes C's red an `exit 124` (a timeout, never cached) so finish's suite runs; 08's ck() rm's red-* before each call. A stub run whose session leaves BROKEN now gets a cached red at the retry's run_init: S1-04's retry check sees it → entries.jsonl:4
- Discovery (S1-03, affects S1-04): run_init fresh does not yet remove red-<key> (S1-04 step 3): until it does, a verify on a tree found red answers cached → entries.jsonl:4
- Discovery (S1-03, affects S1-05, run): 10-harness-eval-run-e2 flaked (probe prompt vs prompt-coding.md): its noinit() kept S1-02s `Suite: last full run <s> s` line, which differs between renders; it now drops it like Clock. Any check comparing two rendered prompts below # This session must too → entries.jsonl:4
- Discovery (S1-02, affects S1-03, S1-04, S1-05): The wall is rendered as `Suite: last full run <s> s: …` under # This session of coding/initializer/verify/resolve; run.md's Suite line ends `its last full run is under *This session*)`. S1-03..05 grep that line, not run.md's. → entries.jsonl:3
- Discovery (S1-02, affects S1-03, S1-05): check.sh: after a whole-suite rerun (a red with no HARNESS_FAILED names) the marker's wall is the rerun's seconds; after a named-files rerun it stays the first run's. → entries.jsonl:3
- Discovery (S1-02, affects S1-05): The command form (lib/prompt.sh <state> coding <id>) keys suite_length on $WT, the record worktree, not the lane's slot, so it can show a different wall than the lane's session got (reviewer finding, left as is: the command form reads CLAUDE.md there too). → entries.jsonl:3
- Discovery (S1-02, affects S1-04): 79-suite-length's planted-marker run needs `mkdir -p $HARNESS_CHECK_CACHE` in its INIT_CMD: the state's green/ doesn't exist before the first check.sh → entries.jsonl:3
- Discovery (S1-01, affects S1-02): two existing checks cat a whole green marker and go red once it has a wall line: 08-scope-sh…:525 and 73-check-rerun.sh:34; switch them to sed -n 1p → entries.jsonl:2
- Discovery (S1-01, affects S1-02): $(cat) of a marker with an empty line 1 (the stub's test ! -f BROKEN suite prints no count) gives \nwall 0, which skips the testcount fallback and writes \nwall into tests-start: the real reason for read -r → entries.jsonl:2
- Discovery (S1-01, affects S1-02): the stub-run markers' walls are all 0: 79 pins suite_length by rewriting markers and rendering with the command form lib/prompt.sh <state> coding <id> → entries.jsonl:2
- Discovery (S1-01, affects S1-02): a planted one-line green before the first suite: a run.env INIT_CMD writes it to $HARNESS_CHECK_CACHE/green-<treekey> (the init runs before run_init takes the key; load_config exports the cache) → entries.jsonl:2
- Discovery (S1-01, affects S1-03): the red marker's write needs both whys to start 'exit ': keep the rerun's why in a variable (last) and the RED line in another (line) so it is stored as printed → entries.jsonl:2
- Discovery (init, affects run): the stub project's suite in tests/lib.sh is `test ! -f BROKEN`, which counts nothing: the stub-run checks of S1-04 and S2-05 set CHECK_CMD in the run's config to a counting, argument-recording suite as 73-check-rerun.sh's rr-suite.sh → entries.jsonl:1
- Discovery (init, affects run): rendered prompts live in the run's state dir as prompt-<kind>.md (08-scope-sh checks grep $HARNESS_STATE/proj/<run>/prompt-coding.md) and per session under logs/*-<id>.prompt.md: 79-suite-length.sh reads them there → entries.jsonl:1
- Discovery (init, affects run): the spec's `prompt()` is lib/prompt.sh's prompt_render (prompt_vars/prompt_env/prompt_render); HARNESS_SUITE_LENGTH belongs with the other per-render variables set on the render line, and {{SUITE_LENGTH}} in parts/run.md is under {{SECTIONS}} → entries.jsonl:1
- Discovery (init, affects run): the init suite was green after a rerun: 47-lanes-two flaked (one flakes.jsonl row); a red there in a session is a known flake, not necessarily the session's → entries.jsonl:1
- Discovery (init, affects run): no .harness/runs/agent-harness-2026-10-29-2 directory is in this tree (only its ledger line): the 10-29-2 numbers the spec cites are the spec's, not re-derivable here → entries.jsonl:1

## Current rules

- The suite's length in every prompt: a green marker's `wall` line, and a timeout rule → journal/decisions/2026-10-30-suite-length-in-prompt.md
- A red tree is cached: `red-<key>`, so the next full call on the tree just found red runs nothing → journal/decisions/2026-10-30-red-marker.md
- The suite waits on a condition or a barrier, never on the clock; a flake is reproduced with --repeat and fixed at its cause → journal/decisions/2026-10-29-tests-wait-not-sleep.md
- The rerun guard: a red full suite is rerun once; a flake is green, named and counted, never quarantined → journal/decisions/2026-10-29-rerun-guard.md
- Questions wait in `harness needs` until answered: one item per question, moved forward, no push → journal/decisions/2026-10-29-questions-wait.md
- Lanes leftovers: atomic list writes, a record-only main, the finish order, two lint rules, two checks, the suite-ran note → journal/decisions/2026-10-29-lanes-leftovers.md
- The coordinator ends a run only when the lane count its opens used saw no lane → journal/decisions/2026-10-29-lane-count-end-check.md
- Entries that survive: the session checks its own, a long summary is cut and kept, one resume for a missing one → journal/decisions/2026-10-29-entries-survive.md
- A parked run's continue advice names another live run of its project and gives Michael the choice → journal/decisions/2026-10-29-continue-advice-busy-project.md
- Merge conflicts resolved without Michael: a sorted merge for lists first, then a resolve session, verified → journal/decisions/2026-10-29-conflict-resolution.md
- This repo's suite gets a 25-minute check timeout; TEST_JOBS stays at its default → journal/decisions/2026-10-29-check-timeout-25m.md
- `harness show`: where a run's work is, from local refs, one change counted once → journal/decisions/2026-10-28-show.md
- A plain start or continue queues behind a live run of its project; overlaps are named, never held → journal/decisions/2026-10-27-same-project-starts.md
- The review gate: a milestone review's model by its measured diff, one Opus round after a Sonnet finding → journal/decisions/2026-10-27-review-gate.md
- A finished run keeps its record after gc: report reads worktree → state → ledger → journal/decisions/2026-10-27-record-after-gc.md
- Read views: one formatter, `lib/view.mjs`, that every read view renders through → journal/decisions/2026-10-27-read-views.md
- Questions where Michael sees them: one INBOX parser, the steering comment repaired → journal/decisions/2026-10-27-question-locations.md
- Project names: one resolver takes a path or a bare name → journal/decisions/2026-10-27-project-names.md
- Merging the memory run into lanes: main's driver changes in their lane-era homes, the review round per lane → journal/decisions/2026-10-27-p1-main-merge.md
- What waits on Michael: one needs record per item, swept by its reason's rule → journal/decisions/2026-10-27-needs-record.md
- Lane branches go when their PR merges; gc reaps lane branches, leftover slots and a killed run's lane units → journal/decisions/2026-10-27-lane-branches-and-slots.md
- gc's foreign units: another project's are silent, an unowned one is said with its command → journal/decisions/2026-10-27-gc-foreign-units.md
- Where things go: one routing block in every session's prompt, unless CLAUDE.md has its own; one decisions store per project → journal/decisions/2026-10-26-where-things-go.md
- Verify runs the suite in full: the verified tree's cached green is removed first → journal/decisions/2026-10-26-verify-runs-the-suite.md
- Verify before the deadline: one session per complete milestone, then finish → journal/decisions/2026-10-26-verify-before-deadline.md
- A test-count contract: a suite's own `HARNESS_TESTS=<n>` line wins over scraping its summary → journal/decisions/2026-10-26-test-count-contract.md

_51 older rules: journal/decisions._
