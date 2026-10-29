# Context pack for `N2`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## This feature's earlier attempts

- Dead end (N2-04, 10-N2-04): asserting `lane M2 closed (M2 verified; its re-base waits)` in the refused run — a lane whose re-base waits closes with no such note; the check counts two `lane M2 opened` lines instead → entries.jsonl:12
- Dead end (N2-04, 10-N2-04): inspecting the slot after a stub run for MERGE_HEAD — finish removes the slots; the e2e checks compare origin's lane branch with the tag, and a unit on resolve alone checks MERGE_HEAD and HEAD → entries.jsonl:12
- Dead end (N2-03, 09-N2-03): a stray-path restore over `git ls-files -s | awk` lines and `awk -v p=path` membership — the Opus review showed it deletes tracked paths with a blank, writes junk for quoted non-ASCII paths and writes through symlinks; replaced by -z snapshots in associative arrays and checkout-index → entries.jsonl:11
- 2026-10-29 08:34 · N2-06 · passes: N2 review + simplify + docs. merge-sorted.sh: an unsorted side now gets git merge-file (markers kept; git keeps %A whatever the exit). sync_main and rebase share merge_main (lib/record.sh). report's Spend by role names resolve. architecture.md §3-§12, README, decision completed. 0 Critical, 1 Important, 7 Minor; tests 924 → 925; files lib/merge-sorted.sh, lib/record.sh, lib/lane.sh, lib/summary.mjs, tests/checks/75-merge-sorted.sh, … → entries.jsonl:14
- 2026-10-29 08:13 · N2-05 · passes: Resolutions are visible, never asked about: resolved_note (lib/resolve.sh) from rebase and sync_main; summary.mjs conflicts {resolved, escalated, sessions} plus resolutions [{milestone, files}] and report's Conflicts row after Flakes; pr_body's `Merged main in with a resolve session: <files>` from resolved-<m>. 6 new checks in 76/77; decision updated.; tests 918 → 924; files lib/resolve.sh, lib/lane.sh, lib/record.sh, lib/summary.mjs, tests/checks/76-resolve-session.sh, … → entries.jsonl:13
- 2026-10-29 07:46 · N2-04 · passes: Layer 2 fallbacks: stub STUB_MERGE_RESOLVE markers/stray/give-up, STUB_RESOLVE_LIMIT, STUB_MAIN_TOUCH=resolve-<m>; sync_main resolves in a lane (verify defers on a refusal, skips sync_main in rebase mode); needs cards' tried; rebase records conflict-<m>; 77-resolve-fallbacks (12). Opus review: 0 Critical, 2 Important, 1 Minor, all fixed.; tests 905 → 918; files lib/record.sh, lib/lane.sh, lib/resolve.sh, lib/needs.mjs, bin/harness, … → entries.jsonl:12
- 2026-10-29 07:04 · N2-03 · passes: Layer 2 happy path: lib/resolve.sh (resolve_ok, resolve: snapshot, session on RESOLVE_*, journal, metrics row, checks, NUL-safe restore, commit), prompts/resolve.md, CONFLICTS/RESOLVE_*/MAX_RESOLVES, stub # Resolve session (both) and STUB_CONFLICT; merge_one returns 3 in a lane, rebase resolves then verifies; 76-resolve-session (12 checks). Opus review: 1 Critical, 3 Important, 7 Minor, all fixed.; tests 893 → 905; files lib/resolve.sh, prompts/resolve.md, lib/lane.sh, lib/record.sh, lib/config.sh, … → entries.jsonl:11
- 2026-10-29 06:07 · N2-02 · passes: Layer 1: lib/merge-sorted.sh (three-way sorted union; an unsorted side exits 1, A untouched), .gitattributes opts check-names.txt in, merge_drivers (lib/record.sh) sets the driver as worktree config in the record worktree each segment and in slot_open; STUB_SORTED; 75-merge-sorted.sh (7 checks, ~14 s); decision started.; tests 886 → 893; files lib/merge-sorted.sh, lib/record.sh, lib/driver.sh, .gitattributes, tests/stub-claude.sh, … → entries.jsonl:10
- 2026-10-29 05:40 · N2-01 · passes: Wrote docs/plans/2026-10-29-N2-conflict-resolution.md: merge-sorted.sh + merge_drivers, resolve/resolve_ok in lib/resolve.sh (rc 0/1/2, RESOLVE_END, snapshot, checks, bounds), exact changes in sync_main, verify, rebase, merge_one(+--open) and slot_open (stays), the gate, stub flags and modes, tried, visible, checks by file. Opus review: 0 Critical, 7 Important, 5 Minor, all folded in.; tests 886 → 886; files docs/plans/2026-10-29-N2-conflict-resolution.md → entries.jsonl:9

## Discoveries for this feature

- Discovery (N2-06, affects run): open Minor review findings: resolved-<m> is written with > (sync_main's then rebase's resolution keeps only the last files in the PR body; the plan said >>); slot_open's reset after a killed resolve still commits the session's untracked files as WIP; resolve ignores S_EXIT (a timed-out session that git-added clean files is committed, the verify still gates it); a rebase refused by resolve's mem_gate (lanes-end/stop, no RESOLVE_END) exits the lane 0 'its re-base waits' not 16/14; rebase's main_clear runs before the re-base's outcome; 77's slot_open check's `! -e resolve-called` half can't fail → entries.jsonl:14
- Discovery (N2-06, affects run): merge_main <m> <resolve|""> (lib/record.sh) is the one conflict path into resolve: 0 merged (MERGE_RESOLVED when a session settled it), 1 aborted (MERGE_FILES, RESOLVE_TRIED), 2 refused → entries.jsonl:14
- Discovery (N2-05, affects N2-06): summary.json's conflicts is exactly {resolved, escalated, sessions} (the step's jq ==), so the report row's files live in a sibling key `resolutions: [{milestone, files}]`; docs (§ state/summary) should name both → entries.jsonl:13
- Discovery (N2-05, affects N2-06): RESOLVE_FILES is now comma-joined ("a, b"), as the conflict note had it; rebase's `resolved by a session (...)` how text uses it too → entries.jsonl:13
- Discovery (N2-05, affects N2-06): the resolution note and the PR paragraph say $MAIN_BRANCH, not a literal `main`; summary.mjs matches any branch word (`\S+ merged in by a resolve session`) → entries.jsonl:13
- Discovery (N2-04, affects N2-05, N2-06): resolve's tried is stored in the resolve-<m>-<main> marker, so a later record for the same main (resolve_ok: already ran) keeps tried; MAX_RESOLVES sets tried to `its <n> resolve session(s) used` → entries.jsonl:12
- Discovery (N2-04, affects N2-05, N2-06): rebase writes conflict-<m> before rebase_fail: without it the run's-end merge_one re-opened merge_conflict, dropping tried and the rebase variant, and notified twice → entries.jsonl:12
- Discovery (N2-04, affects N2-06): merge_one's resolve branch returns 1 when main-conflict-<m> is this main (the lane's sync_main already tried it); rebase calls main_clear once its merge went through → entries.jsonl:12
- Discovery (N2-04, affects N2-05): stub resolve sessions report 0 min (S_WALL 0): a check on tried's minutes matches [0-9]+ → entries.jsonl:12
- Discovery (N2-04, affects N2-05, N2-06): a unit calling resolve() needs USAGE and REC set (weekly gate, metrics row) or it dies under set -u mid-function → entries.jsonl:12
- Discovery (N2-03, affects N2-04): resolve.sh already holds N2-04's failure code (resolve_ok bounds, MAX_RESOLVES note, refused deferral with RESOLVE_END, marker/UNRESOLVED/unmerged checks, stray restore, resolve_undo); N2-04 needs its stub modes and checks, the sync_main call site, the verify caller's rc 2 and needs.mjs `tried` (rebase already passes tried= only when set) → entries.jsonl:11
- Discovery (N2-03, affects N2-04): the stray restore is covered by a unit check in 76 (resolve with a function session: a blank, café.txt, a symlink, a created and an added file); N2-04's stub `stray` run is the end-to-end one → entries.jsonl:11
- Discovery (N2-03, affects N2-04, N2-06): merge_one keeps today's merge_conflict at the run's end ($STATE/ended, written by finish before merge_milestones and cleared at each segment start): no lane could re-base then → entries.jsonl:11
- Discovery (N2-03, affects N2-06): slot_open now undoes a MERGE_HEAD left in a reused slot (a lane killed mid-resolve) with a note `<m>: its slot-<k> had a merge left in progress; undone`, before the WIP commit → entries.jsonl:11
- Discovery (N2-03, affects N2-04): the marker check counts marker-like lines (diff3's ||||||| too) above what either side (:2:/:3:) already had, so a setext ======= underline isn't a false marker → entries.jsonl:11
- Discovery (N2-03, affects N2-05): resolved-<m> is overwritten (>) on each successful resolve, not appended, so N2-05's PR body lists the last resolution's files once → entries.jsonl:11
- Discovery (N2-03, affects N2-04): verify's `sync_main` still runs in rebase mode (the plan's skip is N2-04's); harmless in 76's runs → entries.jsonl:11
- Discovery (N2-02, affects N2-03, N2-04, N2-06): merge_drivers is called right after the driver's first sync_record (lib/driver.sh), before the resumed start's sync_main; slot_open calls it in place of its extensions.worktreeConfig line → entries.jsonl:10
- Discovery (N2-02, affects N2-04, N2-06): STUB_SORTED=<file> in tests/stub-claude.sh: A adds `b A check`, C `b C check`, re-sorted, in their first coding session → entries.jsonl:10
- Discovery (N2-01, affects N2-02, N2-03): git 2.43 merge-tree --write-tree runs a configured merge driver (attributes from the checkout's .gitattributes), so layer 1 also settles merge_one's merge-tree → entries.jsonl:9
- Discovery (N2-01, affects N2-02, project): git worktree add copies the current worktree's config.worktree into the new one: slots added from the record worktree inherit its --worktree driver; Michael's checkout never sees it → entries.jsonl:9
- Discovery (N2-01, affects N2-03): 61-needs-git.sh's mc and mr runs hit sync_main/merge_one conflicts: with CONFLICTS=resolve as default they need CONFLICTS=michael in user-config to keep testing today's path → entries.jsonl:9
- Discovery (N2-01, affects N2-04): a needs card key that is always present (even null) changes 52-status-json.sh's key-path fixture: add tried only when set → entries.jsonl:9
- Discovery (N2-01, affects N2-04): verify runs sync_main in rebase mode too (lane.sh:62); the plan skips it there so a re-base round never resolves twice → entries.jsonl:9
- Discovery (N1-05, affects R1, run): 08-scope-sh-l1-02 flakes under the full suite's load (memory gate waits, the real 64M scope check), green alone: an R1 flaker beside 45-lanes-run → entries.jsonl:7
- Discovery (N1-05, affects run): review findings left open (Minor): run_init tests-start falls back to a red check.out's passes when a flake's marker is empty (suites with no N/M line); testcount --total undercounts a file killed mid-way; the debrief prints the project-wide #### flakes block once per run, not once per project; a fractional CHECK_TIMEOUT (1.5h) makes why() miss a timeout's 137 → entries.jsonl:7
- Discovery (N1-03, affects run): the live suite check.sh (projects/agent-harness, main) has no rerun yet: a full run from a session goes red on one flake until N1 merges → entries.jsonl:4
- Discovery (N1-03, affects R1, run): 47-lanes-two `lanes admission: with the five-hour window at 80 %…` and 45-lanes-run `a lane opened after the default lane…` fail under the full suite`s load, pass alone: R1 flakers → entries.jsonl:4
- Discovery (init, affects run): the suite took 604 s at init here (859 checks); each full run inside a feature costs about 10 min, so a build feature runs it twice at most → entries.jsonl:1
- Discovery (init, affects run): HARNESS_LANE is not exported anywhere today; N1-02 exports it from lib/lane.sh so flakes.jsonl rows and resolve sessions can name their lane → entries.jsonl:1
- Discovery (init, affects run): the stub project's CHECK_CMD (`test ! -f BROKEN`, tests/lib.sh) prints no HARNESS_FAILED= line, so in stub runs CHECK_RERUN=auto reruns the whole suite: the flaky note reads `flaky: whole suite` → entries.jsonl:1
- Discovery (init, affects run): scope_run clears <unit>.started and .show before each call, so check.sh can run its rerun through run() with the same unit name → entries.jsonl:1
- Discovery (init, affects run): the last run's build features took 25 to 78 min each (the lane-wiring ones the longest); N2-03 and N2-04 are the big ones here and may take two attempts → entries.jsonl:1

## Current rules

- The rerun guard: a red full suite is rerun once; a flake is green, named and counted, never quarantined → journal/decisions/2026-10-29-rerun-guard.md
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
- Real test counts: one rule per runner, proven on a fixture each; a suite with no count is said once per run → journal/decisions/2026-10-26-real-test-counts.md
- Queue numbers count parked entries; a park never overwrites one → journal/decisions/2026-10-26-queue-numbering-and-park.md

_42 older rules: journal/decisions._
