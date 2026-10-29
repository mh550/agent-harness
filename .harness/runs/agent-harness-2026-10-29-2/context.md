# Context pack for `R2-02`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## Discoveries for this feature

- Discovery (R2-01, affects run): 39-memlint-m4 lints this worktree's CLAUDE.md: a 16th Gotchas line turns the suite red; replace a line, never add past 15 → entries.jsonl:4
- Discovery (R1-01, affects run): N2 is not on origin main (1 of N1/N2 merged): an overlap conflict between lanes needs Michael → entries.jsonl:3
- Discovery (R2-01, affects R2-02): A trimmed summary of 400 + … (401) fails validate and readEntries drops it: cut to 399 + … as minimal() does. → entries.jsonl:2
- Discovery (R2-01, affects R2-02): validate's header message is the same for a long string and a non-string; R2-02 gives a long one 'header: <n> characters (at most 2000)' and validate exits 2 when only caps fail. → entries.jsonl:2
- Discovery (init, affects run): N2 (conflict resolution) is not on origin main: N2-02 waits on Michael. Only N1 merged (grep -c harness-merge/...-N[12] = 1). A text conflict between two lanes needs Michael as before; each plan says so in one line. → entries.jsonl:1
- Discovery (init, affects run): R2 and R3 both edit lib/record.sh and prompts/coding.md; R2-02 and R3-02 both edit prompts/initializer.md. Whichever merges second takes a re-base verify round; a text conflict needs Michael (no N2). → entries.jsonl:1

## Promote to Gotchas

- settle (tests/lib.sh:74, copy at 15:177) pgreps every debrief of this checkout and 08:239 pgreps `sleep 31` box-wide: another file or a --repeat copy matches them; a cross-file wait under load, first lead for 15 and 08 → entries.jsonl:3

## Lately in the run

- 2026-10-29 10:01 · R2-01 · passes: Attempt 1's plan (docs/plans/2026-10-29-R2-entries.md) holds every step; the suite was red only because its new Gotchas line made CLAUDE.md's ## Gotchas 16 lines, which 39-memlint-m4 fails. Dropped the narrowest line (brief.md move); memlint on the worktree prints nothing; full suite green, 886 tests.; tests 886 → 886; files CLAUDE.md → entries.jsonl:4
- 2026-10-29 09:58 · R1-01 · passes: Wrote docs/plans/2026-10-29-R1-flakes.md: the four tools (wait_for, stub_wait/stub_go + STUB_BARRIER, the sleep lint, --repeat) with signatures, output and named checks in 75-suite-tools.sh; the flaker table (8 rows, cause not yet, 44's missing lane branch first) with code leads; all 96 sleep lines in 22 files marked poll/order/work/text.; tests 886 → 886; files docs/plans/2026-10-29-R1-flakes.md → entries.jsonl:3
- 2026-10-29 09:19 · R2-01 · passes: Wrote docs/plans/2026-10-29-R2-entries.md: the entry check, the trim (399 + … so readEntries keeps it), the background rule, the resume (entry_resume in record.sh, decided before the ingest, outside the record lock, reusing session() with S_RESUME/S_TURNS/S_TIMEOUT/S_BUDGET), metrics resumeRow, the stubs, 76-entries-survive.sh's check names. N2 not on main.; tests 886 → 886; files docs/plans/2026-10-29-R2-entries.md, CLAUDE.md → entries.jsonl:2

## Current rules

- The rerun guard: a red full suite is rerun once; a flake is green, named and counted, never quarantined → journal/decisions/2026-10-29-rerun-guard.md
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

_55 older rules: journal/decisions._
