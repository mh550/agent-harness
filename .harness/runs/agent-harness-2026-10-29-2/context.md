# Context pack for `R2`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## This feature's earlier attempts

- Dead end (R2-05, 04-R2-05): the resume setting A's passes to true in the stub — A's session had already passed, so cmp saw no change and no restore note; the stub toggles it → entries.jsonl:11
- Dead end (R2-05, 04-R2-05): committing resumed.txt in the overreach mode — check redits greps git log --all for resumed.txt across every run of the file; the overreach mode commits overreach.txt → entries.jsonl:11
- Dead end (R2-04, 02-R2-04): a 16th Gotchas line (entry_resume resumes any unrefused session…) — memlint counts 15 already (grep '^- ' says 14): 39-memlint-m4 went red; dropped it → entries.jsonl:9
- Dead end (R2-01, 03-R2-01): attempt 1 adding a 16th Gotchas line — memlint caps ## Gotchas at 15 and the suite lints this worktree → entries.jsonl:4
- 2026-10-29 14:31 · resolve R2 · passes: CLAUDE.md Gotchas: lane reworded the stub-runs line and added the 399+… cut fact; main added the merge-driver %A and HARNESS_HOME facts. Kept the reword and both main facts. To stay at memlint's 15 (comment counts, as both sides meant), dropped the 399 line (R2's ingest trim covers it) and the end-reasons line (check 51 enforces it; it stored a count).; files CLAUDE.md → entries.jsonl:12
- 2026-10-29 14:29 · R2-05 · passes: 0 Critical, 3 Important, 8 Minor. One Opus round on R2.diff. Fixed RED→GREEN: a result-less resume's negative cost (resumeRow), a list an init's resume writes now removed, untested resume paths (stub good-overreach, STUB_INIT_NO_LIST, STUB_NO_INIT_LINE); 6 Minors fixed, 2 left. Decision entries-survive; architecture §4/§5, README.; tests 908 → 915; files docs/plans/2026-10-29-R2-review.md, journal/decisions/2026-10-29-entries-survive.md, docs/architecture.md, README.md, lib/metrics.mjs, … → entries.jsonl:11
- 2026-10-29 13:27 · R2-04 · passes: entry_resume (lib/record.sh), from journal before the ingest, outside the lock: a coding/verify/init session left with no valid entry and not refused is resumed once through session() (S_RESUME/S_TURNS/S_TIMEOUT/S_BUDGET); then list/INBOX restored, edits dropped, restrict, an entry-resume metrics row. prompts/entry-resume.md, config defaults; summary.mjs and metrics summary count it as cost only.; tests 900 → 908; files lib/record.sh, lib/config.sh, lib/prompt.sh, lib/summary.mjs, lib/metrics.mjs, … → entries.jsonl:9
- 2026-10-29 10:48 · R2-03 · passes: Stub: each headless session prints first.jsonl's init line with a fresh session_id (kept in $STUB_DIR/sessions/<id>); --resume logs argv to resume.log, answers an unknown id as unknown-id.out (exit 1), a known one with resumed.jsonl and cumulative cost/modelUsage. STUB_NO_ENTRY, STUB_RESUME_ENTRY=good|bad|good-edits. metrics.mjs: sessionId, resumeRow, session-id, cost, append-resume. 7 checks.; tests 893 → 900; files tests/stub-claude.sh, lib/metrics.mjs, tests/checks/05-metrics-pure-tokens-cache.sh, tests/checks/76-entries-survive.sh, tests/fixtures/check-names.txt → entries.jsonl:7
- 2026-10-29 10:23 · R2-02 · passes: Entry check: prompt_env exports HARNESS_ENTRY_CHECK; the coding, verify and init prompts end by running it and forbid ending on background work. entries.mjs: onlyCaps, the header's own '<n> characters (at most 2000)', validate exit 2 on caps only; journalEntry cuts summary/header to 399+… and keeps the entry, ingest prints 'trimmed summary <n>', journal_ notes it. STUB_LONG_SUMMARY. 7 checks.; tests 886 → 893; files lib/entries.mjs, lib/prompt.sh, lib/record.sh, prompts/coding.md, prompts/verify.md, … → entries.jsonl:6
- 2026-10-29 10:01 · R2-01 · passes: Attempt 1's plan (docs/plans/2026-10-29-R2-entries.md) holds every step; the suite was red only because its new Gotchas line made CLAUDE.md's ## Gotchas 16 lines, which 39-memlint-m4 fails. Dropped the narrowest line (brief.md move); memlint on the worktree prints nothing; full suite green, 886 tests.; tests 886 → 886; files CLAUDE.md → entries.jsonl:4
- 2026-10-29 09:19 · R2-01 · passes: Wrote docs/plans/2026-10-29-R2-entries.md: the entry check, the trim (399 + … so readEntries keeps it), the background rule, the resume (entry_resume in record.sh, decided before the ingest, outside the record lock, reusing session() with S_RESUME/S_TURNS/S_TIMEOUT/S_BUDGET), metrics resumeRow, the stubs, 76-entries-survive.sh's check names. N2 not on main.; tests 886 → 886; files docs/plans/2026-10-29-R2-entries.md, CLAUDE.md → entries.jsonl:2

## Discoveries for this feature

- Discovery (R2-05, affects R2): A verify session's resume has no stub run of its own: entry_resume is the same path for verify, checked for coding and init only → entries.jsonl:11
- Discovery (R2-05, affects run): Left by the review (Minor): the resume ignores a stop/lanes-end/deadline (bounded 10m, $1), and a refused resume is not fed to limit_raise → entries.jsonl:11
- Discovery (R1-03, affects R1-07, run): 13-run-2-michael-sets-desk 'harness desk --list' flakes under the full suite's load (R2-02 and R1-03 each saw it once, green on the rerun); not in the plan's flaker table → entries.jsonl:10
- Discovery (R1-03, affects run): origin/main came with 16 Gotchas lines (memlint red on main itself); this lane dropped the end-reasons line when it merged main → entries.jsonl:10
- Discovery (R2-04, affects R2-05): entry_resume declares S_EXIT/S_WALL/S_PEAK/S_NOTES/S_UNIT local just before its session(): the callers' MET limit/append after journal still read the session's own figures → entries.jsonl:9
- Discovery (R2-04, affects R2-05): Check 25 now greps 'B: entry.json still invalid (not JSON: .*) after one resume; recorded a minimal entry'. The PARKED and STUB_OOM stub paths are resumed too (note 'still missing after one resume'); no check was red on it, so the stub's PARKED paths still write no entry → entries.jsonl:9
- Discovery (R2-04, affects R2-05): summary.mjs: entry-resume rows are out of `all` (sessions, per-feature counts, tokens, time) and in cost.total, by_role and by_model; metrics.mjs summary's session counts skip them, its cost and by-kind keep them → entries.jsonl:9
- Discovery (R2-04, affects R2-05): The resume's restrict only runs when HEAD moved: otherwise its WIP commit would commit the initializer's entry.json into the record branch → entries.jsonl:9
- Discovery (R1-02, affects run): ## Gotchas holds 14 bullets at most: memlint counts its <!-- --> comment line among the 15 → entries.jsonl:8
- Discovery (R2-03, affects R2-04): Stub resume is the '# Entry resume' prompt plus --resume <id>; Feature:/Kind: lines under '# This session' give id and kind. The stub has metrics.mjs cost and append-resume <session> <resume> <metrics> <run> <feature> <model> <role> [wall exit peak lane] ready for entry_resume. → entries.jsonl:7
- Discovery (R2-03, affects R2-04): 76's direct stub runs use STUB_DIR=$T/direct/stub, so $T/resume.log stays absent for R2-04's 'refused → no resume.log' check. → entries.jsonl:7
- Discovery (R2-03, affects R2-04): A stub resume with no STUB_DIR, or of a session whose sessions/<id> file is empty (a refused one), starts from cost 0 and resumed.jsonl's model with zeroed tokens. → entries.jsonl:7
- Discovery (R2-02, affects R2-03, R2-04): 76-entries-survive.sh exists now with a STUB_LONG_SUMMARY run (run id longsum) whose state dir the prompt checks render from; R2-03/R2-04 append to it and must reset main between stub runs → entries.jsonl:6
- Discovery (R2-02, affects R2-04): entries.mjs exports onlyCaps(errs) and validate's CLI exits 2 when only caps fail: entry_resume (R2-04) resumes only on exit 1, as the plan says → entries.jsonl:6
- Discovery (R2-01, affects run): 39-memlint-m4 lints this worktree's CLAUDE.md: a 16th Gotchas line turns the suite red; replace a line, never add past 15 → entries.jsonl:4
- Discovery (R1-01, affects run): N2 is not on origin main (1 of N1/N2 merged): an overlap conflict between lanes needs Michael → entries.jsonl:3
- Discovery (R2-01, affects R2-04): The resume must be decided before the ingest (ingest appends the minimal line before exit 3) and outside record's lock (journal_ holds it; a 10m resume would stall the other lane): entry_resume runs in journal(), not journal_. → entries.jsonl:2
- Discovery (R2-01, affects R2-02): A trimmed summary of 400 + … (401) fails validate and readEntries drops it: cut to 399 + … as minimal() does. → entries.jsonl:2
- Discovery (R2-01, affects R2-02): validate's header message is the same for a long string and a non-string; R2-02 gives a long one 'header: <n> characters (at most 2000)' and validate exits 2 when only caps fail. → entries.jsonl:2
- Discovery (R2-01, affects R2-03, R2-04): summary.mjs counts unmatched metrics rows as sessions; entry-resume rows must be filtered out of sessions and kept in cost (summary.mjs and metrics.mjs summary). → entries.jsonl:2
- Discovery (R2-01, affects R2-04): restrict commits a WIP first, so resumed.txt would be in history: drop the resume's uncommitted edits (checkout + clean outside .harness/runs) before restrict. → entries.jsonl:2
- Discovery (R2-01, affects R2-04): Check 25 (STUB_BAD_ENTRY=B) gets resumed after R2-04; its note becomes 'still invalid (...) after one resume'. STUB_PARK/STUB_INBOX_IN_COMMENT write no entry and will be resumed too. → entries.jsonl:2
- Discovery (init, affects run): N2 (conflict resolution) is not on origin main: N2-02 waits on Michael. Only N1 merged (grep -c harness-merge/...-N[12] = 1). A text conflict between two lanes needs Michael as before; each plan says so in one line. → entries.jsonl:1
- Discovery (init, affects run): R2 and R3 both edit lib/record.sh and prompts/coding.md; R2-02 and R3-02 both edit prompts/initializer.md. Whichever merges second takes a re-base verify round; a text conflict needs Michael (no N2). → entries.jsonl:1

## Lately in the run

- 2026-10-29 14:32 · R1-04 · passes: The lanes flakes (44, 46, 48, and 45's also-seen) were one coordinator race in lib/driver.sh: a lane exiting between the lane count and the end check ended the run 'no feature left to try' with M2 ready. Fixed: the end check also needs alive == 0. Its own check in 45 forces the window (HARNESS_COUNT_HOLD=1, tests only). Decision file; plan table rows filled.; tests 943 → 944; files lib/driver.sh, bin/harness, tests/checks/45-lanes-run.sh, tests/fixtures/check-names.txt, journal/decisions/2026-10-29-lane-count-end-check.md, … → entries.jsonl:13

## Current rules

- The rerun guard: a red full suite is rerun once; a flake is green, named and counted, never quarantined → journal/decisions/2026-10-29-rerun-guard.md
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
- The suite is a runner over check files cut from the single file by its markers, grouped where a section reads another's state → journal/decisions/2026-10-26-suite-split.md
- A stop records why: `harness stop --why` and `status: stop <why>` → journal/decisions/2026-10-26-stop-reason.md
- Step lint: four pure rules over the feature list, reported and never applied → journal/decisions/2026-10-26-step-lint.md
- Reviews sized to the milestone: small milestones fold the review into their last build feature → journal/decisions/2026-10-26-reviews-sized-to-milestone.md
- The retro backlog: the retro proposes as data, the driver is the only writer → journal/decisions/2026-10-26-retro-backlog.md
- Resolved questions leave the pack; `project` facts wait under `Promote to Gotchas` until a Gotchas line carries them → journal/decisions/2026-10-26-resolved-and-project-facts.md
- Requested continuations run; automatic ones still skip a run Michael stopped → journal/decisions/2026-10-26-requested-continuations.md

_44 older rules: journal/decisions._
