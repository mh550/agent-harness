# Context pack for `R1-05`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## Discoveries for this feature

- Discovery (R1-04, affects R1-05, R1-06, R1-07): HARNESS_COUNT_HOLD=1 (bin/harness passes it) holds the coordinator after its lane count until the lanes exit; logs 'count hold: …' in run.log. Use it to test whether a lanes flaker is the count/end race → entries.jsonl:13
- Discovery (R1-04, affects R1-05): 28-run-14d-harness-merge (harness merge path) and 48's MERGE_POLICY=pr check ended early with the window forced before the fix; 28 may be this race too: try it forced first → entries.jsonl:13
- Discovery (R2-05, affects run): Left by the review (Minor): the resume ignores a stop/lanes-end/deadline (bounded 10m, $1), and a refused resume is not fed to limit_raise → entries.jsonl:11
- Discovery (R1-03, affects R1-04, R1-05, R1-06, R1-07): wait_for <s> eval '<expr>' runs the expr in wait_for's frame: $1/$2 there are 'eval' and the expr; a helper copies its argument to a local first (gone, tended, tgone do) → entries.jsonl:10
- Discovery (R1-03, affects R1-05, R1-07): settle no longer sleeps 0.5: its pgrep pattern also matches $HERE/../bin/harness debrief (the runner's H, before it execs $HH/lib/debrief.sh), so a debrief that hasn't exec'd yet counts as running → entries.jsonl:10
- Discovery (R1-03, affects R1-07, run): 13-run-2-michael-sets-desk 'harness desk --list' flakes under the full suite's load (R2-02 and R1-03 each saw it once, green on the rerun); not in the plan's flaker table → entries.jsonl:10
- Discovery (R1-03, affects run): origin/main came with 16 Gotchas lines (memlint red on main itself); this lane dropped the end-reasons line when it merged main → entries.jsonl:10
- Discovery (R1-02, affects run): ## Gotchas holds 14 bullets at most: memlint counts its <!-- --> comment line among the 15 → entries.jsonl:8
- Discovery (R1-02, affects R1-03, R1-04, R1-05, R1-06): settle (tests/lib.sh:83) pgreps debriefs box-wide and file 08's `sleep 31` too: a sibling check file or a --repeat copy matches them (R1-04..06 flakers) → entries.jsonl:8
- Discovery (R1-02, affects R1-04, R1-05, R1-06): --repeat keys each copy <file>.c<i> in run.sh's $out; it prints no per-copy PASS lines, only the per-file count, red copies' FAIL lines (copy <i>: …) and the wall time; KEEP=1 adds `copy <i> kept: <T>` → entries.jsonl:5
- Discovery (R2-01, affects run): 39-memlint-m4 lints this worktree's CLAUDE.md: a 16th Gotchas line turns the suite red; replace a line, never add past 15 → entries.jsonl:4
- Discovery (R1-01, affects run): N2 is not on origin main (1 of N1/N2 merged): an overlap conflict between lanes needs Michael → entries.jsonl:3
- Discovery (init, affects run): N2 (conflict resolution) is not on origin main: N2-02 waits on Michael. Only N1 merged (grep -c harness-merge/...-N[12] = 1). A text conflict between two lanes needs Michael as before; each plan says so in one line. → entries.jsonl:1
- Discovery (init, affects R1): The flaker features (R1-04..06) run `bash tests/run.sh --repeat 10 <file>` directly in the session, never through the suite command: its CHECK_TIMEOUT is the whole suite's. One file's ten copies take minutes under load; the spec caps repeats at 30 min per flaker, then `not reproduced`. → entries.jsonl:1
- Discovery (init, affects run): R2 and R3 both edit lib/record.sh and prompts/coding.md; R2-02 and R3-02 both edit prompts/initializer.md. Whichever merges second takes a re-base verify round; a text conflict needs Michael (no N2). → entries.jsonl:1

## What it builds on

- 2026-10-29 12:50 · R1-02 · passes: Attempt 2 of R1-02: the code from c319ca4 was right; the suite was red only on 39-memlint-m4, because the Gotchas line the first attempt added made 16 non-blank lines (the section's comment line counts). Dropped that line (its fact is now a run discovery). Every step re-checked.; tests 892 → 892; files CLAUDE.md → entries.jsonl:8

## Lately in the run

- 2026-10-29 14:32 · R1-04 · passes: The lanes flakes (44, 46, 48, and 45's also-seen) were one coordinator race in lib/driver.sh: a lane exiting between the lane count and the end check ended the run 'no feature left to try' with M2 ready. Fixed: the end check also needs alive == 0. Its own check in 45 forces the window (HARNESS_COUNT_HOLD=1, tests only). Decision file; plan table rows filled.; tests 943 → 944; files lib/driver.sh, bin/harness, tests/checks/45-lanes-run.sh, tests/fixtures/check-names.txt, journal/decisions/2026-10-29-lane-count-end-check.md, … → entries.jsonl:13
- 2026-10-29 14:31 · resolve R2 · passes: CLAUDE.md Gotchas: lane reworded the stub-runs line and added the 399+… cut fact; main added the merge-driver %A and HARNESS_HOME facts. Kept the reword and both main facts. To stay at memlint's 15 (comment counts, as both sides meant), dropped the 399 line (R2's ingest trim covers it) and the end-reasons line (check 51 enforces it; it stored a count).; files CLAUDE.md → entries.jsonl:12
- 2026-10-29 14:29 · R2-05 · passes: 0 Critical, 3 Important, 8 Minor. One Opus round on R2.diff. Fixed RED→GREEN: a result-less resume's negative cost (resumeRow), a list an init's resume writes now removed, untested resume paths (stub good-overreach, STUB_INIT_NO_LIST, STUB_NO_INIT_LINE); 6 Minors fixed, 2 left. Decision entries-survive; architecture §4/§5, README.; tests 908 → 915; files docs/plans/2026-10-29-R2-review.md, journal/decisions/2026-10-29-entries-survive.md, docs/architecture.md, README.md, lib/metrics.mjs, … → entries.jsonl:11

## Current rules

- The rerun guard: a red full suite is rerun once; a flake is green, named and counted, never quarantined → journal/decisions/2026-10-29-rerun-guard.md
- The coordinator ends a run only when the lane count its opens used saw no lane → journal/decisions/2026-10-29-lane-count-end-check.md
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

_58 older rules: journal/decisions._
