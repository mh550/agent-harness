# Context pack for `U1-07`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## This feature's earlier attempts

- Dead end (U1-07, 07-U1-07): a live session = the newest session line with no coding row at or after its stamp — the second Opus round: a refused (env) row never closes it, another lane's row hides it, and rows share a second with the next line; log order per id fixed all three → entries.jsonl:9
- Question (U1-07): The U1 review deferred four Minor findings (continued-run wall hours, MAIN_BRANCH in the card's branch line, lane liveness by cmdline, the --since 3d hint). Should they go in a later milestone's list, or be dropped? → entries.jsonl:9
- 2026-10-28 07:11 · U1-07 · passes: U1 review: 1 Critical, 3 Important, 11 Minor over two Opus rounds. Critical (session counted every metrics row) and all Important fixed red to green in 56-status-review.sh; 7 Minor fixed, 4 deferred; simplifications applied. README, architecture §3/§10/§12, config template and read-views decision complete.; tests 680 → 689; files lib/status.mjs, lib/view.mjs, bin/harness, tests/lib.sh, tests/checks/56-status-review.sh, … → entries.jsonl:9

## Discoveries for this feature

- Discovery (U1-07, affects run): status_stubs' mx now takes [<kind>:]<feature> (init:, verify:, refused:) and writes every row's at MX_AT s before HARNESS_NOW (default 1900); fl and mx stay defined after status_stubs → entries.jsonl:9
- Discovery (U1-07, affects U2, run): Deferred from the U1 review (docs/plans/2026-10-28-U1-review.md, Not done): wall hours of a continued run, the card's branch line hardcodes origin/main, lane liveness lacks lane_live's cmdline test, and the footer's --since 3d hint is not conditional on hidden runs → entries.jsonl:9
- Discovery (U1-07, affects run): Under load (~3.7, other lanes), full runs flaked once each in 28-run-14d-harness-merge and 48-lanes-rebase (an unknown run/<id>/M2 tag); both pass alone and neither reads status → entries.jsonl:9
- Discovery (U1-06, affects U1-07): status.mjs now has queue and entry <n> [--parked] modes; readQueue returns [entry, {args, file}] pairs (queued() maps to the entries), so --json is unchanged → entries.jsonl:8
- Discovery (U1-06, affects U1-07): queue show adds fields beyond the step: held, options (the args no other field names, --queued included) and added; an --until text to_epoch reads but status.mjs cannot (e.g. 'tomorrow 06:00') shows as given → entries.jsonl:8
- Discovery (U1-06, affects U1-07): RUNNING in queue list folds its ids under the title instead of cutting them; the spec's narrow 'PARKED 0 · RUNNING …' join was dropped → entries.jsonl:8
- Discovery (U1-04, affects run): lanes admission (47-lanes-two, five-hour window at 80 %) failed once in a full run at load ~2.9 with TEST_JOBS=3; it never reads the status view → entries.jsonl:6
- Discovery (U1-03, affects run): the full suite at TEST_JOBS=4 flaked 1-2 timing checks per run tonight (load around 3.7 with other lanes); TEST_JOBS=2 ran green in 866 s → entries.jsonl:5
- Discovery (U1-02, affects run): the full suite took 478 s and 481 s tonight (TEST_JOBS=4) → entries.jsonl:3
- Discovery (init, affects run): P1 and P2 of the lanes run are on origin/main (PRs #40 and #41): lib/lane.sh and lib/record.sh exist. The spec's check `git log --oneline origin/main | grep -c 'agent-harness-2026-10-26: P[12]'` prints 0 only because the merge subjects read `Merge pull request #40 from mh550/harness-merge/agent-harness-2026-10-26-P1`. The list is planned against the merged code; U1's lane rows build on P2-06's lane lines in cmd_status. → entries.jsonl:1
- Discovery (init, affects run): Driver sites by function, as the code stands: sync_main, needs_you, notify_park, merge_one, slot_open (the base-conflict note) in lib/record.sh; verify, the park branch and the given-up end in lib/lane.sh; finish, the EXIT trap and the coordinator loop in lib/driver.sh; cmd_status, cmd_report, cmd_queue, cmd_parked, cmd_gc, cmd_start, cmd_continue in bin/harness. → entries.jsonl:1
- Discovery (init, affects run): tests/checks/ ends at 50-lanes-record-pr.sh (new files from 51); tests/fixtures/check-names.txt has 601 names and the suite 602 checks. The init's full suite took 477 s on this box tonight, not the 208 s CLAUDE.md quotes: budget for it when a feature runs the suite more than once. → entries.jsonl:1
- Discovery (init, affects run): The step lint's outside-repo rule flags a tilde path and $HOME in step text; steps say 'the home directory shortened to a tilde' for the view's `home` rule. A grep in command position on progress.md, entries.jsonl, feature_list.json or context.md whose pattern matches the step itself is flagged too; harness-log.md greps are fine. → entries.jsonl:1

## What it builds on

- 2026-10-28 06:08 · U1-06 · passes: harness queue list renders through status.mjs renderQueue + view.mjs: QUEUE/PARKED/RUNNING/RECENT, rule, show hint; harness queue show <n> [--parked] is a card (renderEntry). entry_kind gone; QUEUED rows share queueRow. The four 15- queue checks read the new rows; 55-queue-view.sh, 12 checks. An Opus review found 1 Important and 6 Minor issues, all fixed red to green.; tests 668 → 680; files lib/status.mjs, bin/harness, tests/checks/55-queue-view.sh, tests/checks/15-run-4-same-but-queue-parked-debrief-tmux.sh, tests/fixtures/check-names.txt, … → entries.jsonl:8

## Lately in the run

- 2026-10-28 05:14 · U1-05 · passes: U1-05 passes, in commit `681d468` (pushed). The full suite is green: 668 tests, up from 655. - **The card:** `harness status <run>` now prints a card. Its first line gives the state or end class, `x/y passing` and the age. The fields are now, ended, milestones, lanes, spend, branch, worktree, needs you, units and next. `-v` or `N` adds the log tail. - **Old checks:** the old checks that read the …; files CLAUDE.md, bin/harness, journal/decisions/2026-10-27-read-views.md, lib/status.mjs, prompts/supervisor.md, … → entries.jsonl:7

## Current rules

- The review gate: a milestone review's model by its measured diff, one Opus round after a Sonnet finding → journal/decisions/2026-10-27-review-gate.md
- Read views: one formatter, `lib/view.mjs`, that every read view renders through → journal/decisions/2026-10-27-read-views.md
- Merging the memory run into lanes: main's driver changes in their lane-era homes, the review round per lane → journal/decisions/2026-10-27-p1-main-merge.md
- Lane branches go when their PR merges; gc reaps lane branches, leftover slots and a killed run's lane units → journal/decisions/2026-10-27-lane-branches-and-slots.md
- Where things go: one routing block in every session's prompt, unless CLAUDE.md has its own; one decisions store per project → journal/decisions/2026-10-26-where-things-go.md
- Verify runs the suite in full: the verified tree's cached green is removed first → journal/decisions/2026-10-26-verify-runs-the-suite.md
- Verify before the deadline: one session per complete milestone, then finish → journal/decisions/2026-10-26-verify-before-deadline.md
- A test-count contract: a suite's own `HARNESS_TESTS=<n>` line wins over scraping its summary → journal/decisions/2026-10-26-test-count-contract.md
- The suite is a runner over check files cut from the single file by its markers, grouped where a section reads another's state → journal/decisions/2026-10-26-suite-split.md
- A stop records why: `harness stop --why` and `status: stop <why>` → journal/decisions/2026-10-26-stop-reason.md
- Step lint: four pure rules over the feature list, reported and never applied → journal/decisions/2026-10-26-step-lint.md
- Reviews sized to the milestone: small milestones fold the review into their last build feature → journal/decisions/2026-10-26-reviews-sized-to-milestone.md

_47 older rules: journal/decisions._
