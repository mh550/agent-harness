<!-- harness: rendered from entries.jsonl after every session; edits here are overwritten -->
# Progress — run `agent-harness-2026-10-30` (agent-harness)

What this file is: the run's journal, rendered by the harness from `entries.jsonl`, newest entry first; one entry per session (init, each feature's coding session, verify, retro). Read the feature list in `feature_list.json`: one milestone, F1 (the suite's flakes fixed where they start, as R1 did on 2026-10-29): F1-01 plans, F1-02 to F1-05 reproduce each flaker with `bash tests/run.sh --repeat 10 <file>` and fix it (timing checks, lanes, desk/scope/one-offs, the runner's whole-suite rerun after a stopped file), F1-06 reviews and writes the docs and decision. The run's named spec `docs/specs/2026-10-30-suite-cpu-and-flakes.md` was on no branch when the run started: the init planned the flakes half only and asked about the rest (see the init entry's question). Steer via `INBOX.md` on this branch: set its first line to `status: pause` or `status: stop`, or write an answer under `## Answers`; every session reads it at startup.

### 2026-10-30 20:18 · F1-04 · passes

13 reproduced (8/10): `harness desk --list` failed on its own `"$H" help | grep -qF` under pipefail (help writes 8361 bytes in 3 writes, match in the 2nd; SIGPIPE 141), not the windows (all five up: instrumented copy). Fixed to `grep -F … > /dev/null`; forced 32/400 red before, 0/400 after. 08, 32, 74, 10 not reproduced (10/10); their sightings mostly predate R1's fixes. Plan rows filled.

- **Files:** tests/checks/13-run-2-michael-sets-desk.sh, docs/plans/2026-10-30-F1-flakes.md
- **Verified:** before: 13-run-2-michael-sets-desk: 8/10 green (copies 1, 3 FAIL harness desk --list), 08-…: 10/10 green, 32-l5-queue-runner-re: 10/10 green, 74-flakes-run: 10/10 green, 10-harness-eval-run-e2: 10/10 green. Instrumented 13 (10 copies, 1 red): 5 windows before/after the listing and after the check, DL=0, 5 lines, in every copy. Clause pinned to one busy CPU: old 32/400 fail (all rc 141), new 0/400 (old interleaved 17/400). after: 13: 10/10 green, 08: 10/10, 32: 10/10, 74: 10/10, 10: 10/10. Full suite: 1081/1081 checks passed (check: green in 1220 s). lint-sleeps and bash -n print nothing.
- **Tests:** 1081 → 1081
- **Dead end:** reproducing the SIGPIPE with 12 parallel loops of 300 unpinned — 0/3600: the window needs the reader scheduled between the producer's 2nd and 3rd write; pinning producer, reader and a busy loop to one CPU (taskset -c 5) gives 32/400
- **Dead end:** set -x tracing the check in 20 copies — 20/20 green: the trace's writes change the timing
- **Discovery** (affects F1-06, run): 13's desk --list flake was the check's `"$H" help | grep -qF` (SIGPIPE under pipefail), not the desk windows; force such a pipe red with taskset -c <n> beside a busy loop on the same CPU
- **Discovery** (affects F1-06): check-names.txt's diff against origin/main removes two lines: F1-02's two renamed timing checks; F1-04 changes nothing there
- **Proposed change:** F1-04 step 5 (check-names.txt added lines only) can't hold against origin/main while F1-02's renames are on the branch: it should read `git diff <the feature's base> -- tests/fixtures/check-names.txt`
- **Proposed change:** A lint like lint-sleeps for `| grep -q`/`| head` behind a known multi-write producer (`"$H" help`, `git show`, `cat` of a log) in tests/checks would have caught 13:425
- *04-F1-04 · claude-opus-5-5*

### 2026-10-30 19:02 · F1-03 · passes

Reproduced 47 (9/10: M2's lane opened in M1's slot before M1's close was noted). Fixed in lib/driver.sh: the opens stop for the poll while a lane has exited unreaped (lanes_held), and the end check counts held lanes. New check on its own HARNESS_COUNT_HOLD run (uh), red then green. 46 and 48 not reproduced (10/10). Decision opens-wait-for-reap.

- **Files:** lib/driver.sh, tests/checks/47-lanes-two.sh, tests/fixtures/check-names.txt, journal/decisions/2026-10-30-opens-wait-for-reap.md, docs/plans/2026-10-30-F1-flakes.md, docs/architecture.md
- **Verified:** Before: 46-lanes-continue: 10/10 green · 47-lanes-two: 9/10 green (copy 9 FAIL lanes admission: with the five-hour window at 80 % …; u5 run.log: lane M2 opened 17:58:03 above lane M1 closed 17:58:04) · 48-lanes-rebase: 10/10 green. New check red without the driver fix (14/15), green with it (15/15). After: 47-lanes-two: 10/10 green (twice: before and after the uh split) · 46-lanes-continue: 10/10 green · 48-lanes-rebase: 10/10 green. lint-sleeps silent, bash -n clean. Full suite (check.sh): green in 882 s, 1081/1081 checks passed, no FAIL line.
- **Tests:** 1080 → 1081
- **Dead end:** holding the u5 run itself with HARNESS_COUNT_HOLD=1 — the hold parks the coordinator, so u5's `noted once` saw one poll instead of four (a weaker check, found by the review); the hold moved to its own run, uh
- **Dead end:** a Gotchas line in CLAUDE.md, written while a full suite ran — the section was full (14 facts plus its comment line, memlint's limit 15), so 39-memlint-m4 went red, and the mid-run edit left a red-<key> marker for the tree as it started; the line was dropped and the suite run again on a tree changed by one comment
- **Discovery** (affects F1-04, F1-06): The coordinator's opens counted live pids, so a lane exited after the reap freed its slot and admit count before its close (and any lanes-end reason) was noted; fixed with lanes_held (decisions/2026-10-30-opens-wait-for-reap). The same window exists at MAX_LANES=1 between reap and count: a lead for 46's post-R1 sightings
- **Discovery** (affects F1-06): Sightings 29-2:99 (48) and 29-2:120 (46) ran on trees without R1-05's fix df107cd (R3-02 a4c864c, R3-04 07b837b)
- **Discovery** (affects F1-06): docs/architecture.md's coordinator lines (§ components, the open/end lines) now name the new rule; §7/§15 and README stay F1-06's
- **Discovery** (affects F1-04, F1-06): HARNESS_COUNT_HOLD=1 parks the coordinator after its count until the counted lanes exit, so a check counting notes over polls on that run sees one poll: hold a run of its own
- **Discovery** (affects run): The Gotchas section of CLAUDE.md is full: memlint counts its comment line, so 14 facts is the limit; a new one replaces one
- **Proposed change:** F1-03 step 4 (`git diff origin/main -- tests/fixtures/check-names.txt` shows added lines only) can't hold on this lane's branch: F1-02's two renames (8307b34) show as removed lines. F1-03's own diff (git diff 8307b34 -- tests/fixtures/check-names.txt) adds one line and removes none. Steps like it should diff against the feature's start commit.
- *03-F1-03 · claude-opus-5-5*

### 2026-10-30 17:47 · F1-02 · passes

52/53/28 reproduced with --repeat 10: all 10/10 green (not reproduced). 52 and 53's best-of-3 checks now bound CPU time (user+sys, bash time) under 1000 ms plus the same call's wall under 5000 ms (a stall costs no CPU); renamed. 28 needs no fix: its sightings predate R1-05's lane-count fix. Plan rows filled.

- **Files:** tests/checks/52-status-json.sh, tests/checks/53-status-view.sh, tests/fixtures/check-names.txt, docs/plans/2026-10-30-F1-flakes.md
- **Verified:** before (clean tree, load avg 11.6): `52-status-json: 10/10 green`, `53-status-view: 10/10 green`, `28-run-14d-harness-merge: 10/10 green`; after: the same three lines (load avg 9.6). Red first on throwaway copies of 52: a J burning 1.1 s CPU → `best of 3: 1533 ms CPU (wall 1444 ms)` FAIL; a J sleeping 5.1 s → `426 ms CPU (wall 5435 ms)` FAIL. Real: 438 ms CPU (wall 340) and 364 ms CPU (wall 294). check-names: 2 lines removed, 2 added, sort -c clean; bash -n clean. Full suite via check.sh: `check: green in 849 s, 1080 tests` (first full run 1079/1080: 39-memlint-m4 red on a 16th Gotchas line this session added; line dropped)
- **Tests:** 1080 → 1080
- **Dead end:** editing 52/53 while their first --repeat ran — bash reads a script as it runs, so copies could run the edit; reverted and reran the before-repeats on the clean tree
- **Dead end:** adding a Gotchas line about editing running check files — Gotchas was already at 15 (memlint counts 16 → 39-memlint-m4 red); dropped, the fact kept as a run discovery
- **Discovery** (affects F1-06): 28's two sightings (29-2:69,70, 14:29) are R2-05's, whose tree fe95a4f lacks R1-05's HARNESS_COUNT_HOLD fix df107cd (15:06): no red of 28 is known after that fix
- **Discovery** (affects F1-06): harness status costs more CPU than wall idle (438 ms CPU, 340 ms wall for --json over 38 runs): node's threads; the 1000 ms CPU bound has about 2x headroom
- **Discovery** (affects F1-06): 52/53's checks keep a 5 s wall bound beside the CPU bound (not in the plan's default): CPU alone would pass a status that stalls on a lock or git/gh; F1-06's decision file should say it
- **Discovery** (affects run): bash reads a script as it runs: never edit a check file while a run or --repeat of it goes on
- **Question for Michael:** Default taken: beside the 1 s CPU bound, 52 and 53 keep a 5 s wall bound from the same `time` call, so a status that stalls without CPU (a lock, a git or gh wait) still fails; the load curve's worst wall was 1.4 s. Keep the 5 s wall bound, or drop it to the CPU bound alone as the plan's default had it? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-10-30/slot-0/tests/checks/52-status-json.sh:73, /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-10-30/slot-0/docs/plans/2026-10-30-F1-flakes.md:51
- **Proposed change:** F1-02 step 2 could name the wall guard beside the CPU bound; the plan's default named CPU time only
- *02-F1-02 · claude-opus-5-5*

### 2026-10-30 17:09 · F1-01 · passes

Wrote docs/plans/2026-10-30-F1-flakes.md: provenance (named spec on no branch, flakes half only, CPU fixes 6-7 wait), a 12-row flaker table with sightings, R1's method, the CPU-time default for the 52/53 timing checks, the tests/run.sh whole-suite rerun mechanism and its default fix, what is left out, shared docs and the decision slug. No code changed.

- **Files:** docs/plans/2026-10-30-F1-flakes.md
- **Verified:** check.sh: green (cached for this code tree, 1080 tests); every sighting cited was read: grep 'flaky:' in the three 10-29 records' harness-log.md, grep '^FAIL' in lc-*.out; tests/run.sh lines 104-127 read; 52:70, 53:81, 13:425 line numbers checked
- **Tests:** 1080 → 1080
- **Discovery** (affects F1-02): The load curve's best-of-3 walls for 53/52: 274-326 ms idle, 443-474 ms at 8 jobs solo, 487-556 ms at 4 paired, 972-1367 ms only at 8 paired (lc-*.out 'best of 3:' lines)
- **Discovery** (affects F1-05): Plan default for F1-05: a full run of a TEST_CHECKS directory that holds its own check-names.txt checks conformance against it (no new env var)
- **Discovery** (affects F1-06): Decision slug for F1-06: journal/decisions/2026-10-30-cpu-time-bound-and-stopped-files.md
- **Discovery** (affects F1-02, F1-03, F1-04): The 10-29 run's harness-log.md has no flaky: line; sightings are in 10-29-2 (11 lines) and 10-29-3 (5 lines)
- **Question for Michael:** Default taken: the two 'under 1 s (best of 3)' status checks keep their 1000 ms bound but measure CPU time (user+sys) instead of wall. OK, or would you rather keep wall and accept their rare red at 8-job paired load? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-10-30/slot-0/docs/plans/2026-10-30-F1-flakes.md
- **Question for Michael:** Default taken: when a file is stopped or killed, conformance's 'missing' names no longer suppress HARNESS_FAILED= (new/doubled still do), so check.sh reruns the broken files, not the whole suite; a check dropped elsewhere in the same tree is then caught only by the next full run. OK? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-10-30/slot-0/docs/plans/2026-10-30-F1-flakes.md
- *01-F1-01 · claude-opus-5-5*

### 2026-10-30 17:05 · init · passes

6 features: F1 6 (1 plan, 4 build, 1 review): the flakes half of the run's title, planned from the plan's fixes and the run records because the named spec docs/specs/2026-10-30-suite-cpu-and-flakes.md is on no branch; the CPU half (plan fixes 6 and 7) waits for the spec.

- **Verified:** node lib/features.mjs lint on the list prints nothing; node lib/entries.mjs validate on this entry prints nothing; the suite was green at init (check: green, the init output).
- **Discovery** (affects run): The run's spec docs/specs/2026-10-30-suite-cpu-and-flakes.md exists on no local or remote branch (git fetch --all, every ref checked); the only 2026-10-30 spec, suite-time.md (S1, S2), was built and merged by run agent-harness-2026-10-29-3 (checks 79-82). The list is planned from docs/plans/2026-10-29-suite-time.md §2 fixes, findings-and-research/2026-10-30-suite-load-curve.md and the three 10-29 run records' flaky: lines.
- **Discovery** (affects run): Flaker sightings since R1 (harness-log.md flaky: lines of the 10-29, 10-29-2, 10-29-3 records plus the load curve's FAIL lines): 08 five rows, 47 three, 46 three, 13 three, 28 two, 52 two, 53 one, 32/74/10/48 one each, one `whole suite` rerun (805 s) whose cause is the runner's conformance after a stopped file.
- **Discovery** (affects run): The suite is 1080 checks and 817 s at init on an idle box with TEST_JOBS=4; a session's full run needs a background call with a timeout of at least twice that, as the prompt's Suite line says.
- **Question for Michael:** The run was queued on `docs/specs/2026-10-30-suite-cpu-and-flakes.md`, which is on no branch of the repo (fetched every ref; the live checkout is clean). I planned only what the title's flakes half supports from the data (F1: 6 features, fixes at the cause as R1 did, nothing in lib/check.sh or the driver's design); the CPU half (plan fixes 6 and 7: fewer process starts, the 8-job token) needs your spec. Options: (a) (recommended) let F1 run tonight, commit the spec, then queue a run on it: `harness queue add agent-harness --spec docs/specs/2026-10-30-suite-cpu-and-flakes.md --brief "F1 of agent-harness-2026-10-30 did the flakes; build the CPU half"`; (b) stop this run now if the flakes half isn't wanted: set `INBOX.md`'s first line to `status: stop` on branch harness/agent-harness-2026-10-30; (c) if the spec was meant to be suite-time.md: nothing to do, S1 and S2 are on main since run agent-harness-2026-10-29-3. Files: /home/mh550/worktrees/agent-harness/agent-harness-2026-10-30/docs/specs/, /home/mh550/worktrees/agent-harness/agent-harness-2026-10-30/.harness/runs/agent-harness-2026-10-30/feature_list.json, /home/mh550/worktrees/agent-harness/agent-harness-2026-10-30/docs/plans/2026-10-29-suite-time.md:56, /home/mh550/worktrees/agent-harness/agent-harness-2026-10-30/findings-and-research/2026-10-30-suite-load-curve.md
- **Proposed change:** harness start/queue: refuse (or park the queue entry with a reason) when a --spec file does not exist on the base ref at start, before the initializer session spends anything; today the initializer discovers it.
- *00-init · claude-fable-5-1*
