# Context pack for `N1-02`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## Discoveries for this feature

- Discovery (N1-01, affects N1-02): check.sh's find deletes every check-*.out but check-<key>.out after the full run: check-rerun.out must be written after it, and rm'd before the first run → entries.jsonl:2
- Discovery (N1-01, affects N1-02): 08-scope-sh's ck() calls check.sh with exit 3 and exit 137 (short of the cap) and greps '— last lines of .../check.out': under auto they rerun; pin HARNESS_CHECK_RERUN=off in ck() → entries.jsonl:2
- Discovery (N1-01, affects N1-02): a rerun-green with no N/M total leaves an empty marker, and the cached line and tests_end then fall back to check-<key>.out, the red run's count: the plan removes check-<key>.out then → entries.jsonl:2
- Discovery (init, affects run): the suite took 604 s at init here (859 checks); each full run inside a feature costs about 10 min, so a build feature runs it twice at most → entries.jsonl:1
- Discovery (init, affects run): HARNESS_LANE is not exported anywhere today; N1-02 exports it from lib/lane.sh so flakes.jsonl rows and resolve sessions can name their lane → entries.jsonl:1
- Discovery (init, affects run): the stub project's CHECK_CMD (`test ! -f BROKEN`, tests/lib.sh) prints no HARNESS_FAILED= line, so in stub runs CHECK_RERUN=auto reruns the whole suite: the flaky note reads `flaky: whole suite` → entries.jsonl:1
- Discovery (init, affects run): scope_run clears <unit>.started and .show before each call, so check.sh can run its rerun through run() with the same unit name → entries.jsonl:1
- Discovery (init, affects run): the last run's build features took 25 to 78 min each (the lane-wiring ones the longest); N2-03 and N2-04 are the big ones here and may take two attempts → entries.jsonl:1

## What it builds on

- 2026-10-29 01:46 · N1-01 · passes: Wrote docs/plans/2026-10-29-N1-rerun-guard.md: the rerun's place and rules in lib/check.sh (CHECK_RERUN table, never-rerun exits, marker from the first run's total via testcount --total), the HARNESS_FAILED= guard in tests/run.sh, the flakes.jsonl row, flakes_note's sites and lock, summary/report/debrief, every new check name by file, docs.; tests 859 → 859; files docs/plans/2026-10-29-N1-rerun-guard.md → entries.jsonl:2

## Lately in the run

- 2026-10-29 01:40 · init · passes: 11 features: N1 5 (plan, 3 build, review), N2 6 (plan, 4 build, review); in series, N2 after N1 as the spec asks. First N1-01 (plan), N1-02 (HARNESS_FAILED= and the check.sh rerun), N1-03 (flakes_note and the invariant). → entries.jsonl:1

## Current rules

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

_54 older rules: journal/decisions._
