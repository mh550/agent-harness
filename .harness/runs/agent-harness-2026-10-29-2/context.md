# Context pack for `R1-02`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## Discoveries for this feature

- Discovery (R1-01, affects R1-02, R1-03): waitf is defined identically in 32, 47, 48, 49; settle and ran are copied in file 15 (175-178, 263): the sweep removes the copies, calls become wait_for <s> eval '<expr>' → entries.jsonl:3
- Discovery (R1-01, affects run): N2 is not on origin main (1 of N1/N2 merged): an overlap conflict between lanes needs Michael → entries.jsonl:3
- Discovery (init, affects run): N2 (conflict resolution) is not on origin main: N2-02 waits on Michael. Only N1 merged (grep -c harness-merge/...-N[12] = 1). A text conflict between two lanes needs Michael as before; each plan says so in one line. → entries.jsonl:1
- Discovery (init, affects R1): The flaker features (R1-04..06) run `bash tests/run.sh --repeat 10 <file>` directly in the session, never through the suite command: its CHECK_TIMEOUT is the whole suite's. One file's ten copies take minutes under load; the spec caps repeats at 30 min per flaker, then `not reproduced`. → entries.jsonl:1
- Discovery (init, affects run): R2 and R3 both edit lib/record.sh and prompts/coding.md; R2-02 and R3-02 both edit prompts/initializer.md. Whichever merges second takes a re-base verify round; a text conflict needs Michael (no N2). → entries.jsonl:1

## Promote to Gotchas

- settle (tests/lib.sh:74, copy at 15:177) pgreps every debrief of this checkout and 08:239 pgreps `sleep 31` box-wide: another file or a --repeat copy matches them; a cross-file wait under load, first lead for 15 and 08 → entries.jsonl:3

## Lately in the run

- 2026-10-29 09:58 · R1-01 · passes: Wrote docs/plans/2026-10-29-R1-flakes.md: the four tools (wait_for, stub_wait/stub_go + STUB_BARRIER, the sleep lint, --repeat) with signatures, output and named checks in 75-suite-tools.sh; the flaker table (8 rows, cause not yet, 44's missing lane branch first) with code leads; all 96 sleep lines in 22 files marked poll/order/work/text.; tests 886 → 886; files docs/plans/2026-10-29-R1-flakes.md → entries.jsonl:3
- 2026-10-29 09:19 · R2-01 · passes: Wrote docs/plans/2026-10-29-R2-entries.md: the entry check, the trim (399 + … so readEntries keeps it), the background rule, the resume (entry_resume in record.sh, decided before the ingest, outside the record lock, reusing session() with S_RESUME/S_TURNS/S_TIMEOUT/S_BUDGET), metrics resumeRow, the stubs, 76-entries-survive.sh's check names. N2 not on main.; tests 886 → 886; files docs/plans/2026-10-29-R2-entries.md, CLAUDE.md → entries.jsonl:2
- 2026-10-29 09:12 · init · passes: 23 features: R1 7 (plan, wait_for/barriers/--repeat, sleep lint, three flaker groups, review), R2 5 (plan, entry check + trim, stub + metrics, the one resume, review), R3 6 (plan, features.mjs writes + two lint rules, merge/finish/test-count, suite-ran note + reviewer model, two lanes checks, review), R4 5 (plan, question items, ingest wiring, readers + skill, review). N1 merged, N2 not.; files .harness/runs/agent-harness-2026-10-29-2/feature_list.json → entries.jsonl:1

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
