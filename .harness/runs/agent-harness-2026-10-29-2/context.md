# Context pack for `R2-05`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## Discoveries for this feature

- Discovery (R2-04, affects R2-05): entry_resume declares S_EXIT/S_WALL/S_PEAK/S_NOTES/S_UNIT local just before its session(): the callers' MET limit/append after journal still read the session's own figures → entries.jsonl:9
- Discovery (R2-04, affects R2-05): Check 25 now greps 'B: entry.json still invalid (not JSON: .*) after one resume; recorded a minimal entry'. The PARKED and STUB_OOM stub paths are resumed too (note 'still missing after one resume'); no check was red on it, so the stub's PARKED paths still write no entry → entries.jsonl:9
- Discovery (R2-04, affects R2-05): summary.mjs: entry-resume rows are out of `all` (sessions, per-feature counts, tokens, time) and in cost.total, by_role and by_model; metrics.mjs summary's session counts skip them, its cost and by-kind keep them → entries.jsonl:9
- Discovery (R2-04, affects R2-05): The resume's restrict only runs when HEAD moved: otherwise its WIP commit would commit the initializer's entry.json into the record branch → entries.jsonl:9
- Discovery (R1-02, affects run): ## Gotchas holds 14 bullets at most: memlint counts its <!-- --> comment line among the 15 → entries.jsonl:8
- Discovery (R2-01, affects run): 39-memlint-m4 lints this worktree's CLAUDE.md: a 16th Gotchas line turns the suite red; replace a line, never add past 15 → entries.jsonl:4
- Discovery (R1-01, affects run): N2 is not on origin main (1 of N1/N2 merged): an overlap conflict between lanes needs Michael → entries.jsonl:3
- Discovery (init, affects run): N2 (conflict resolution) is not on origin main: N2-02 waits on Michael. Only N1 merged (grep -c harness-merge/...-N[12] = 1). A text conflict between two lanes needs Michael as before; each plan says so in one line. → entries.jsonl:1
- Discovery (init, affects run): R2 and R3 both edit lib/record.sh and prompts/coding.md; R2-02 and R3-02 both edit prompts/initializer.md. Whichever merges second takes a re-base verify round; a text conflict needs Michael (no N2). → entries.jsonl:1

## Lately in the run

- 2026-10-29 13:27 · R2-04 · passes: entry_resume (lib/record.sh), from journal before the ingest, outside the lock: a coding/verify/init session left with no valid entry and not refused is resumed once through session() (S_RESUME/S_TURNS/S_TIMEOUT/S_BUDGET); then list/INBOX restored, edits dropped, restrict, an entry-resume metrics row. prompts/entry-resume.md, config defaults; summary.mjs and metrics summary count it as cost only.; tests 900 → 908; files lib/record.sh, lib/config.sh, lib/prompt.sh, lib/summary.mjs, lib/metrics.mjs, … → entries.jsonl:9
- 2026-10-29 12:50 · R1-02 · passes: Attempt 2 of R1-02: the code from c319ca4 was right; the suite was red only on 39-memlint-m4, because the Gotchas line the first attempt added made 16 non-blank lines (the section's comment line counts). Dropped that line (its fact is now a run discovery). Every step re-checked.; tests 892 → 892; files CLAUDE.md → entries.jsonl:8
- 2026-10-29 10:48 · R2-03 · passes: Stub: each headless session prints first.jsonl's init line with a fresh session_id (kept in $STUB_DIR/sessions/<id>); --resume logs argv to resume.log, answers an unknown id as unknown-id.out (exit 1), a known one with resumed.jsonl and cumulative cost/modelUsage. STUB_NO_ENTRY, STUB_RESUME_ENTRY=good|bad|good-edits. metrics.mjs: sessionId, resumeRow, session-id, cost, append-resume. 7 checks.; tests 893 → 900; files tests/stub-claude.sh, lib/metrics.mjs, tests/checks/05-metrics-pure-tokens-cache.sh, tests/checks/76-entries-survive.sh, tests/fixtures/check-names.txt → entries.jsonl:7

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
