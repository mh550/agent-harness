# Context pack for `U3-02`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## Discoveries for this feature

- Discovery (U2-09, affects run): needs card commands now run in fix_root/fix-<run>-<subject> (HARNESS_SCRATCH_ROOT/<project>, needs_open passes it) at origin's copy of the branch; merge_conflict's last command is harness merge, which re-tags at a hand-merged lane tip → entries.jsonl:20
- Discovery (U2-09, affects run): Not done from the U2 review: a park card's where can take other features' Files: lines when the INBOX has no ### <id> section; pre-U2 runs' needs-/refused-/conflict- markers show no items; needs.md rewritten by needs done is committed only at the run's next driver commit → entries.jsonl:20
- Discovery (U2-08, affects U2-09, run): tests/stub-claude.sh STUB_ASK_TOUCH=<path> (the STUB_ASK session also changes it), STUB_PARK_FILES=<value> (a Files: line under the park's ### heading), STUB_PARK_TOUCH=<path> (the parking session changes it) → entries.jsonl:19
- Discovery (U2-07, affects U2-09, run): status_stubs now opens the parked and givenup runs' records (nopen, at the stub's old times); the given-up headline is the template's 'C given up after 2 attempts', so 52/53 read that instead of U1's '(2 attempts)' → entries.jsonl:18
- Discovery (U2-07, affects U2-09, run): With U1's run_end row gone, a run that ended failed or waiting with no record (e.g. 'no feature left to try', an unknown POLICY) shows in neither NEEDS YOU nor harness needs, only as FINISHED's red glyph → entries.jsonl:18
- Discovery (U2-06, affects run, U2-09): lib/driver.sh coordinator: alive was counted before the second reap, so a lane reaped there skipped the open and the run ended 'no feature left to try' with an independent milestone untried; alive is recounted now (a likely source of earlier lane flakes) → entries.jsonl:17
- Discovery (U2-05, affects run): 46-lanes-continue's 'record-only run … ends done' failed once in a full TEST_JOBS=2 run at load, passing alone and twice under load: a timing flake → entries.jsonl:16
- Discovery (U1-07, affects run): At load ~3.6 (other lanes) every TEST_JOBS=4 full run tonight failed 1-4 timing-bound e2e checks, a different file each time; TEST_JOBS=2 with HARNESS_CHECK_TIMEOUT=25m is the way to a green → entries.jsonl:10
- Discovery (U1-07, affects run): status_stubs' mx now takes [<kind>:]<feature> (init:, verify:, refused:) and writes every row's at MX_AT s before HARNESS_NOW (default 1900); fl and mx stay defined after status_stubs → entries.jsonl:9
- Discovery (U1-07, affects U2, run): Deferred from the U1 review (docs/plans/2026-10-28-U1-review.md, Not done): wall hours of a continued run, the card's branch line hardcodes origin/main, lane liveness lacks lane_live's cmdline test, and the footer's --since 3d hint is not conditional on hidden runs → entries.jsonl:9
- Discovery (U1-07, affects run): Under load (~3.7, other lanes), full runs flaked once each in 28-run-14d-harness-merge and 48-lanes-rebase (an unknown run/<id>/M2 tag); both pass alone and neither reads status → entries.jsonl:9
- Discovery (U1-04, affects run): lanes admission (47-lanes-two, five-hour window at 80 %) failed once in a full run at load ~2.9 with TEST_JOBS=3; it never reads the status view → entries.jsonl:6
- Discovery (U1-03, affects run): the full suite at TEST_JOBS=4 flaked 1-2 timing checks per run tonight (load around 3.7 with other lanes); TEST_JOBS=2 ran green in 866 s → entries.jsonl:5
- Discovery (U1-02, affects run): the full suite took 478 s and 481 s tonight (TEST_JOBS=4) → entries.jsonl:3
- Discovery (init, affects run): P1 and P2 of the lanes run are on origin/main (PRs #40 and #41): lib/lane.sh and lib/record.sh exist. The spec's check `git log --oneline origin/main | grep -c 'agent-harness-2026-10-26: P[12]'` prints 0 only because the merge subjects read `Merge pull request #40 from mh550/harness-merge/agent-harness-2026-10-26-P1`. The list is planned against the merged code; U1's lane rows build on P2-06's lane lines in cmd_status. → entries.jsonl:1
- Discovery (init, affects run): Driver sites by function, as the code stands: sync_main, needs_you, notify_park, merge_one, slot_open (the base-conflict note) in lib/record.sh; verify, the park branch and the given-up end in lib/lane.sh; finish, the EXIT trap and the coordinator loop in lib/driver.sh; cmd_status, cmd_report, cmd_queue, cmd_parked, cmd_gc, cmd_start, cmd_continue in bin/harness. → entries.jsonl:1
- Discovery (init, affects run): tests/checks/ ends at 50-lanes-record-pr.sh (new files from 51); tests/fixtures/check-names.txt has 601 names and the suite 602 checks. The init's full suite took 477 s on this box tonight, not the 208 s CLAUDE.md quotes: budget for it when a feature runs the suite more than once. → entries.jsonl:1
- Discovery (init, affects run): The step lint's outside-repo rule flags a tilde path and $HOME in step text; steps say 'the home directory shortened to a tilde' for the view's `home` rule. A grep in command position on progress.md, entries.jsonl, feature_list.json or context.md whose pattern matches the step itself is flagged too; harness-log.md greps are fine. → entries.jsonl:1

## Promote to Gotchas

- status-json-keys.txt now lists every key path of the stubs' three needs records (parked, given_up, synthesized driver_crash); a new card field in those templates changes it → entries.jsonl:18

## What it builds on

- 2026-10-28 15:59 · U3-01 · passes: Wrote docs/plans/2026-10-28-U3-show-and-fixes.md: project_dir's order and six callers, report's worktree→state→ledger order and finish's copy, gc's unit rule, harness show (fields, CHANGES, CONFLICTS, NEEDS, feature form, --json), project_busy, overlap.mjs and its wiring/sweep, TTY report/trends/gc, checks 65-72, fixtures, U3-02..08 order, four decisions. Code unchanged.; tests 785 → 785; files docs/plans/2026-10-28-U3-show-and-fixes.md → entries.jsonl:22

## Lately in the run

- 2026-10-28 15:42 · verify U2 · passes: All 9 U2 features hold. Full suite 783/785: the 2 memory-gate checks in 08-scope failed only under 4-job load; alone 08-scope passes 125/125. Files, syntax checks, docs, cards, prompts, fixtures verified against each step. → entries.jsonl:21
- 2026-10-28 15:29 · U2-09 · passes: U2 review: 0 Critical, 3 Important, 11 Minor (one Opus round, no second: nothing Critical). Fixed red to green in 64-needs-review: harness merge takes a hand merge of main, card commands in a fix worktree, needs done refuses a park and locks; 7 minors fixed. Docs: architecture §7 INBOX repair, §8 hand merge; README n8n record path; both U2 decisions updated.; tests 775 → 785; files lib/needs.mjs, lib/needs.sh, lib/record.sh, lib/lane.sh, lib/inbox.mjs, … → entries.jsonl:20

## Current rules

- The review gate: a milestone review's model by its measured diff, one Opus round after a Sonnet finding → journal/decisions/2026-10-27-review-gate.md
- Read views: one formatter, `lib/view.mjs`, that every read view renders through → journal/decisions/2026-10-27-read-views.md
- Questions where Michael sees them: one INBOX parser, the steering comment repaired → journal/decisions/2026-10-27-question-locations.md
- Merging the memory run into lanes: main's driver changes in their lane-era homes, the review round per lane → journal/decisions/2026-10-27-p1-main-merge.md
- What waits on Michael: one needs record per item, swept by its reason's rule → journal/decisions/2026-10-27-needs-record.md
- Lane branches go when their PR merges; gc reaps lane branches, leftover slots and a killed run's lane units → journal/decisions/2026-10-27-lane-branches-and-slots.md
- Where things go: one routing block in every session's prompt, unless CLAUDE.md has its own; one decisions store per project → journal/decisions/2026-10-26-where-things-go.md

_54 older rules: journal/decisions._
