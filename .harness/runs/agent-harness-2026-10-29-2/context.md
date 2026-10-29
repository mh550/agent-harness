# Context pack for `R2-04`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## Discoveries for this feature

- Discovery (R2-03, affects R2-04): Stub resume is the '# Entry resume' prompt plus --resume <id>; Feature:/Kind: lines under '# This session' give id and kind. The stub has metrics.mjs cost and append-resume <session> <resume> <metrics> <run> <feature> <model> <role> [wall exit peak lane] ready for entry_resume. → entries.jsonl:7
- Discovery (R2-03, affects R2-04): 76's direct stub runs use STUB_DIR=$T/direct/stub, so $T/resume.log stays absent for R2-04's 'refused → no resume.log' check. → entries.jsonl:7
- Discovery (R2-03, affects R2-04): A stub resume with no STUB_DIR, or of a session whose sessions/<id> file is empty (a refused one), starts from cost 0 and resumed.jsonl's model with zeroed tokens. → entries.jsonl:7
- Discovery (R2-02, affects R2-03, R2-04): 76-entries-survive.sh exists now with a STUB_LONG_SUMMARY run (run id longsum) whose state dir the prompt checks render from; R2-03/R2-04 append to it and must reset main between stub runs → entries.jsonl:6
- Discovery (R2-02, affects R2-04): entries.mjs exports onlyCaps(errs) and validate's CLI exits 2 when only caps fail: entry_resume (R2-04) resumes only on exit 1, as the plan says → entries.jsonl:6
- Discovery (R2-01, affects run): 39-memlint-m4 lints this worktree's CLAUDE.md: a 16th Gotchas line turns the suite red; replace a line, never add past 15 → entries.jsonl:4
- Discovery (R1-01, affects run): N2 is not on origin main (1 of N1/N2 merged): an overlap conflict between lanes needs Michael → entries.jsonl:3
- Discovery (R2-01, affects R2-04): The resume must be decided before the ingest (ingest appends the minimal line before exit 3) and outside record's lock (journal_ holds it; a 10m resume would stall the other lane): entry_resume runs in journal(), not journal_. → entries.jsonl:2
- Discovery (R2-01, affects R2-03, R2-04): summary.mjs counts unmatched metrics rows as sessions; entry-resume rows must be filtered out of sessions and kept in cost (summary.mjs and metrics.mjs summary). → entries.jsonl:2
- Discovery (R2-01, affects R2-04): restrict commits a WIP first, so resumed.txt would be in history: drop the resume's uncommitted edits (checkout + clean outside .harness/runs) before restrict. → entries.jsonl:2
- Discovery (R2-01, affects R2-04): Check 25 (STUB_BAD_ENTRY=B) gets resumed after R2-04; its note becomes 'still invalid (...) after one resume'. STUB_PARK/STUB_INBOX_IN_COMMENT write no entry and will be resumed too. → entries.jsonl:2
- Discovery (init, affects run): N2 (conflict resolution) is not on origin main: N2-02 waits on Michael. Only N1 merged (grep -c harness-merge/...-N[12] = 1). A text conflict between two lanes needs Michael as before; each plan says so in one line. → entries.jsonl:1
- Discovery (init, affects run): R2 and R3 both edit lib/record.sh and prompts/coding.md; R2-02 and R3-02 both edit prompts/initializer.md. Whichever merges second takes a re-base verify round; a text conflict needs Michael (no N2). → entries.jsonl:1

## What it builds on

- 2026-10-29 10:23 · R2-02 · passes: Entry check: prompt_env exports HARNESS_ENTRY_CHECK; the coding, verify and init prompts end by running it and forbid ending on background work. entries.mjs: onlyCaps, the header's own '<n> characters (at most 2000)', validate exit 2 on caps only; journalEntry cuts summary/header to 399+… and keeps the entry, ingest prints 'trimmed summary <n>', journal_ notes it. STUB_LONG_SUMMARY. 7 checks.; tests 886 → 893; files lib/entries.mjs, lib/prompt.sh, lib/record.sh, prompts/coding.md, prompts/verify.md, … → entries.jsonl:6
- 2026-10-29 10:48 · R2-03 · passes: Stub: each headless session prints first.jsonl's init line with a fresh session_id (kept in $STUB_DIR/sessions/<id>); --resume logs argv to resume.log, answers an unknown id as unknown-id.out (exit 1), a known one with resumed.jsonl and cumulative cost/modelUsage. STUB_NO_ENTRY, STUB_RESUME_ENTRY=good|bad|good-edits. metrics.mjs: sessionId, resumeRow, session-id, cost, append-resume. 7 checks.; tests 893 → 900; files tests/stub-claude.sh, lib/metrics.mjs, tests/checks/05-metrics-pure-tokens-cache.sh, tests/checks/76-entries-survive.sh, tests/fixtures/check-names.txt → entries.jsonl:7

## Lately in the run

- 2026-10-29 10:16 · R1-02 · passes: tests/lib.sh gains wait_for (clock-bounded 0.1 s poll), stub_wait/stub_go; in_has, settle's poll and ran run on wait_for. stub-claude.sh learns STUB_BARRIER=<id>:<name>. tests/run.sh --repeat <n> <name>… runs n fresh copies per file, prints <file>: k/n green and red copies' FAIL lines. Six checks in 75-suite-tools.sh, watched failing first.; tests 886 → 892; files tests/lib.sh, tests/run.sh, tests/stub-claude.sh, tests/checks/75-suite-tools.sh, tests/fixtures/check-names.txt, … → entries.jsonl:5

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
