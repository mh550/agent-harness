# Context pack for `F1-06`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## This feature's earlier attempts

- 2026-10-30 21:11 · F1-06 · passes: Review of F1 (Sonnet, one round): 0 Critical, 1 Important, 3 Minor. Fixed 47's uh check (wait for count-hold before release). Wrote decision cpu-time-bound-and-stopped-files, review file, architecture §3/§7/§15 and README Tests lines.; tests 1083 → 1083; files tests/checks/47-lanes-two.sh, docs/plans/2026-10-30-F1-review.md, journal/decisions/2026-10-30-cpu-time-bound-and-stopped-files.md, docs/architecture.md, README.md → entries.jsonl:7

## Discoveries for this feature

- Discovery (F1-06, affects run): The Important finding is a race in the check's own ordering (needs M1 to finish within one 1 s poll): no deterministic red; fixed by the 45 pattern → entries.jsonl:7
- Discovery (F1-05, affects F1-06): F1-05 narrowed the plan's default: only a missing name literal (grep -F) in a stopped/killed file's source goes uncounted; all 22 of file 15's missing names at lc-8-a.out:1339 are literal; 30 of 1082 fixture names are literal nowhere (a cut file holding one keeps the whole-suite rerun). The decision file should say this → entries.jsonl:6
- Discovery (F1-05, affects F1-06): A file that exits non-zero partway (set -u, a stray exit) is not in `cut`: its unprinted names still count as missing and rerun the whole suite (kept out of scope, as the plan names only stopped and killed files); the decision file should say so → entries.jsonl:6
- Discovery (F1-05, affects F1-06, run): 08's `scope.sh: a real 64M scope kills a 256 MB allocation with exit 137 and leaves no unit` went red once in F1-05's full run (load 4.5 falling), green on check.sh's rerun of 08 alone; F1-04's 10/10 of 08 didn't see it → entries.jsonl:6
- Discovery (F1-04, affects F1-06, run): 13's desk --list flake was the check's `"$H" help | grep -qF` (SIGPIPE under pipefail), not the desk windows; force such a pipe red with taskset -c <n> beside a busy loop on the same CPU → entries.jsonl:5
- Discovery (F1-04, affects F1-06): check-names.txt's diff against origin/main removes two lines: F1-02's two renamed timing checks; F1-04 changes nothing there → entries.jsonl:5
- Discovery (F1-03, affects F1-04, F1-06): The coordinator's opens counted live pids, so a lane exited after the reap freed its slot and admit count before its close (and any lanes-end reason) was noted; fixed with lanes_held (decisions/2026-10-30-opens-wait-for-reap). The same window exists at MAX_LANES=1 between reap and count: a lead for 46's post-R1 sightings → entries.jsonl:4
- Discovery (F1-03, affects F1-06): Sightings 29-2:99 (48) and 29-2:120 (46) ran on trees without R1-05's fix df107cd (R3-02 a4c864c, R3-04 07b837b) → entries.jsonl:4
- Discovery (F1-03, affects F1-06): docs/architecture.md's coordinator lines (§ components, the open/end lines) now name the new rule; §7/§15 and README stay F1-06's → entries.jsonl:4
- Discovery (F1-03, affects F1-04, F1-06): HARNESS_COUNT_HOLD=1 parks the coordinator after its count until the counted lanes exit, so a check counting notes over polls on that run sees one poll: hold a run of its own → entries.jsonl:4
- Discovery (F1-03, affects run): The Gotchas section of CLAUDE.md is full: memlint counts its comment line, so 14 facts is the limit; a new one replaces one → entries.jsonl:4
- Discovery (F1-02, affects F1-06): 28's two sightings (29-2:69,70, 14:29) are R2-05's, whose tree fe95a4f lacks R1-05's HARNESS_COUNT_HOLD fix df107cd (15:06): no red of 28 is known after that fix → entries.jsonl:3
- Discovery (F1-02, affects F1-06): harness status costs more CPU than wall idle (438 ms CPU, 340 ms wall for --json over 38 runs): node's threads; the 1000 ms CPU bound has about 2x headroom → entries.jsonl:3
- Discovery (F1-02, affects F1-06): 52/53's checks keep a 5 s wall bound beside the CPU bound (not in the plan's default): CPU alone would pass a status that stalls on a lock or git/gh; F1-06's decision file should say it → entries.jsonl:3
- Discovery (F1-02, affects run): bash reads a script as it runs: never edit a check file while a run or --repeat of it goes on → entries.jsonl:3
- Discovery (F1-01, affects F1-06): Decision slug for F1-06: journal/decisions/2026-10-30-cpu-time-bound-and-stopped-files.md → entries.jsonl:2
- Discovery (init, affects run): The run's spec docs/specs/2026-10-30-suite-cpu-and-flakes.md exists on no local or remote branch (git fetch --all, every ref checked); the only 2026-10-30 spec, suite-time.md (S1, S2), was built and merged by run agent-harness-2026-10-29-3 (checks 79-82). The list is planned from docs/plans/2026-10-29-suite-time.md §2 fixes, findings-and-research/2026-10-30-suite-load-curve.md and the three 10-29 run records' flaky: lines. → entries.jsonl:1
- Discovery (init, affects run): Flaker sightings since R1 (harness-log.md flaky: lines of the 10-29, 10-29-2, 10-29-3 records plus the load curve's FAIL lines): 08 five rows, 47 three, 46 three, 13 three, 28 two, 52 two, 53 one, 32/74/10/48 one each, one `whole suite` rerun (805 s) whose cause is the runner's conformance after a stopped file. → entries.jsonl:1
- Discovery (init, affects run): The suite is 1080 checks and 817 s at init on an idle box with TEST_JOBS=4; a session's full run needs a background call with a timeout of at least twice that, as the prompt's Suite line says. → entries.jsonl:1

## What it builds on

- 2026-10-30 17:47 · F1-02 · passes: 52/53/28 reproduced with --repeat 10: all 10/10 green (not reproduced). 52 and 53's best-of-3 checks now bound CPU time (user+sys, bash time) under 1000 ms plus the same call's wall under 5000 ms (a stall costs no CPU); renamed. 28 needs no fix: its sightings predate R1-05's lane-count fix. Plan rows filled.; tests 1080 → 1080; files tests/checks/52-status-json.sh, tests/checks/53-status-view.sh, tests/fixtures/check-names.txt, docs/plans/2026-10-30-F1-flakes.md → entries.jsonl:3
- 2026-10-30 19:02 · F1-03 · passes: Reproduced 47 (9/10: M2's lane opened in M1's slot before M1's close was noted). Fixed in lib/driver.sh: the opens stop for the poll while a lane has exited unreaped (lanes_held), and the end check counts held lanes. New check on its own HARNESS_COUNT_HOLD run (uh), red then green. 46 and 48 not reproduced (10/10). Decision opens-wait-for-reap.; tests 1080 → 1081; files lib/driver.sh, tests/checks/47-lanes-two.sh, tests/fixtures/check-names.txt, journal/decisions/2026-10-30-opens-wait-for-reap.md, docs/plans/2026-10-30-F1-flakes.md, … → entries.jsonl:4
- 2026-10-30 20:18 · F1-04 · passes: 13 reproduced (8/10): `harness desk --list` failed on its own `"$H" help | grep -qF` under pipefail (help writes 8361 bytes in 3 writes, match in the 2nd; SIGPIPE 141), not the windows (all five up: instrumented copy). Fixed to `grep -F … > /dev/null`; forced 32/400 red before, 0/400 after. 08, 32, 74, 10 not reproduced (10/10); their sightings mostly predate R1's fixes. Plan rows filled.; tests 1081 → 1081; files tests/checks/13-run-2-michael-sets-desk.sh, docs/plans/2026-10-30-F1-flakes.md → entries.jsonl:5
- 2026-10-30 20:45 · F1-05 · passes: tests/run.sh keeps stopped/killed files in `cut`; a conformance `missing` name found literally in a cut file's source is printed but not counted (one line says so), so HARNESS_FAILED= names the files and check.sh reruns them, not the whole suite. Any other missing, new or doubled name still fails. A TEST_CHECKS dir with its own check-names.txt gets conformance. Two checks in 33.; tests 1081 → 1083; files tests/run.sh, tests/checks/33-suite-runner.sh, tests/fixtures/check-names.txt, docs/plans/2026-10-30-F1-flakes.md → entries.jsonl:6

## Current rules

_81 older rules: journal/decisions._
