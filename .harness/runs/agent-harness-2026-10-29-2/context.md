# Context pack for `R4-01`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## Discoveries for this feature

- Discovery (R3-05, affects run): Promote item 'tests/lib.sh now holds tended, held…' does not hold on R3's branch (R1-07's lib.sh is not merged here; 47/48/49/76/77-resolve define held and ats themselves): left for a session on a branch with R1 in → entries.jsonl:24
- Discovery (R3-04, affects R3-06, run): 08-scope flaked twice in this session's full runs (gatestop memory gate; M2's lane never started, 2/3 passing): R1-06's fixes (HARNESS_COUNT_HOLD, gatestop at 2 GB) are not on this lane's base → entries.jsonl:22
- Discovery (R1-07, affects run): The coordinator's opens skip a milestone whose lanes/<m>/pid is still there (exited, unreaped); HARNESS_COUNT_HOLD leaves state/count-hold while holding, so a check can act inside the window → entries.jsonl:21
- Discovery (R1-07, affects run): 13-run-2-michael-sets-desk (harness desk --list) not reproduced: --repeat 10 was 10/10 green, 718 s → entries.jsonl:21
- Discovery (R3-03, affects R3-05, run): To test a main that moved after a milestone's verify, use STUB_MAIN_TOUCH=verify-<m>:<path>: a touch in a coding session is merged into the lane before the verify → entries.jsonl:20
- Discovery (R1-06, affects R1-07, run): Every stub run is M1 (A, B) then M2 (C, after M1): any check on a run's 3/3, M2's tag or its packs can hit R1-04's lane-count race; HARNESS_COUNT_HOLD=1 on that start holds the window every time → entries.jsonl:19
- Discovery (R1-06, affects R1-07, run): pgrep in a check is box-wide (sibling copies, other lanes' suites): match this copy's process by grep -zqF "HARNESS_SCRATCH=$T/" /proc/<pid>/environ (08's init_left) → entries.jsonl:19
- Discovery (R3-02, affects R3-06, run): 13/14-run-2 pin the initializer's lint sentence ending `milestone's size doesn't call for). No output means clean.`: a new lint item goes before the review one → entries.jsonl:18
- Discovery (R3-02, affects R1-07, run): Under this box's load (~21) the full suite took 1237 s and 08-scope and 48-lanes-rebase (a non-fast-forward push to origin main) flaked once each, green on the rerun → entries.jsonl:18
- Discovery (R1-05, affects run): Merging origin/main brought R2 in: its stub-claude.sh header comments conflicted with R1-02's STUB_BARRIER comment. Both are kept; the suite went from 944 to 973 checks. → entries.jsonl:17
- Discovery (R3-01, affects R3-02, run): unreproducible flags 3 steps of this run's list (R1-02 step 4 'below 5 s', R3-01 step 3, R3-02 step 3 quoting the examples): expected, reported never applied → entries.jsonl:16
- Discovery (R2, affects run): N2 is on origin main now (grep -c ...-N[12]$ = 2; 645d87e, in R2's HEAD): the R2/R1 plans' 'needs Michael' dependency line is stale → entries.jsonl:15
- Discovery (R2-05, affects run): Left by the review (Minor): the resume ignores a stop/lanes-end/deadline (bounded 10m, $1), and a refused resume is not fed to limit_raise → entries.jsonl:11
- Discovery (R1-03, affects R1-07, run): 13-run-2-michael-sets-desk 'harness desk --list' flakes under the full suite's load (R2-02 and R1-03 each saw it once, green on the rerun); not in the plan's flaker table → entries.jsonl:10
- Discovery (R1-03, affects run): origin/main came with 16 Gotchas lines (memlint red on main itself); this lane dropped the end-reasons line when it merged main → entries.jsonl:10
- Discovery (R1-02, affects run): ## Gotchas holds 14 bullets at most: memlint counts its <!-- --> comment line among the 15 → entries.jsonl:8
- Discovery (R2-01, affects run): 39-memlint-m4 lints this worktree's CLAUDE.md: a 16th Gotchas line turns the suite red; replace a line, never add past 15 → entries.jsonl:4
- Discovery (R1-01, affects run): N2 is not on origin main (1 of N1/N2 merged): an overlap conflict between lanes needs Michael → entries.jsonl:3
- Discovery (init, affects run): N2 (conflict resolution) is not on origin main: N2-02 waits on Michael. Only N1 merged (grep -c harness-merge/...-N[12] = 1). A text conflict between two lanes needs Michael as before; each plan says so in one line. → entries.jsonl:1
- Discovery (init, affects run): R2 and R3 both edit lib/record.sh and prompts/coding.md; R2-02 and R3-02 both edit prompts/initializer.md. Whichever merges second takes a re-base verify round; a text conflict needs Michael (no N2). → entries.jsonl:1

## Promote to Gotchas

- tests/lib.sh now holds tended, held (clears vwait-* too), ats and debriefs: a check file must not redefine them differently → entries.jsonl:21

## What it builds on

- 2026-10-29 10:01 · R2-01 · passes: Attempt 1's plan (docs/plans/2026-10-29-R2-entries.md) holds every step; the suite was red only because its new Gotchas line made CLAUDE.md's ## Gotchas 16 lines, which 39-memlint-m4 fails. Dropped the narrowest line (brief.md move); memlint on the worktree prints nothing; full suite green, 886 tests.; tests 886 → 886; files CLAUDE.md → entries.jsonl:4
- 2026-10-29 10:23 · R2-02 · passes: Entry check: prompt_env exports HARNESS_ENTRY_CHECK; the coding, verify and init prompts end by running it and forbid ending on background work. entries.mjs: onlyCaps, the header's own '<n> characters (at most 2000)', validate exit 2 on caps only; journalEntry cuts summary/header to 399+… and keeps the entry, ingest prints 'trimmed summary <n>', journal_ notes it. STUB_LONG_SUMMARY. 7 checks.; tests 886 → 893; files lib/entries.mjs, lib/prompt.sh, lib/record.sh, prompts/coding.md, prompts/verify.md, … → entries.jsonl:6
- 2026-10-29 10:48 · R2-03 · passes: Stub: each headless session prints first.jsonl's init line with a fresh session_id (kept in $STUB_DIR/sessions/<id>); --resume logs argv to resume.log, answers an unknown id as unknown-id.out (exit 1), a known one with resumed.jsonl and cumulative cost/modelUsage. STUB_NO_ENTRY, STUB_RESUME_ENTRY=good|bad|good-edits. metrics.mjs: sessionId, resumeRow, session-id, cost, append-resume. 7 checks.; tests 893 → 900; files tests/stub-claude.sh, lib/metrics.mjs, tests/checks/05-metrics-pure-tokens-cache.sh, tests/checks/76-entries-survive.sh, tests/fixtures/check-names.txt → entries.jsonl:7
- 2026-10-29 13:27 · R2-04 · passes: entry_resume (lib/record.sh), from journal before the ingest, outside the lock: a coding/verify/init session left with no valid entry and not refused is resumed once through session() (S_RESUME/S_TURNS/S_TIMEOUT/S_BUDGET); then list/INBOX restored, edits dropped, restrict, an entry-resume metrics row. prompts/entry-resume.md, config defaults; summary.mjs and metrics summary count it as cost only.; tests 900 → 908; files lib/record.sh, lib/config.sh, lib/prompt.sh, lib/summary.mjs, lib/metrics.mjs, … → entries.jsonl:9
- 2026-10-29 14:29 · R2-05 · passes: 0 Critical, 3 Important, 8 Minor. One Opus round on R2.diff. Fixed RED→GREEN: a result-less resume's negative cost (resumeRow), a list an init's resume writes now removed, untested resume paths (stub good-overreach, STUB_INIT_NO_LIST, STUB_NO_INIT_LINE); 6 Minors fixed, 2 left. Decision entries-survive; architecture §4/§5, README.; tests 908 → 915; files docs/plans/2026-10-29-R2-review.md, journal/decisions/2026-10-29-entries-survive.md, docs/architecture.md, README.md, lib/metrics.mjs, … → entries.jsonl:11

_3 items left out at 8192 bytes: entries.jsonl has them all._
