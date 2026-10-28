# Context pack for `U2-02`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## Discoveries for this feature

- Discovery (U2-01, affects U2-02, U2-03, U2-04, U2-05, U2-06, U2-07, U2-08): tests/checks/56- is taken (56-status-review.sh): U2's new check files are 57-inbox, 58-needs-record, 59-needs-cards, 60-needs-driver, 61-needs-git, 62-needs-readers, 63-question-locations → entries.jsonl:12
- Discovery (U2-01, affects U2-02): With lanes, a session writes only its slot copy of INBOX.md; take_question_ copies the added lines into the record. So the INBOX repair belongs on the slot copy (against $LS/inbox-before.md) before take_question, plus the record's INBOX after the initializer. answers_hash and take_question_ also cut at /^## Answers/ and must move to inbox.mjs (answers, insert) → entries.jsonl:12
- Discovery (U2-01, affects U2-02): The n8n-home fixture can be read without git in that checkout: git clone -q --no-checkout ~/projects/n8n-home <scratch>/n8n-home, then git -C <scratch>/n8n-home show 4632d1c:.harness/runs/n8n-home-2026-10-22/INBOX.md → entries.jsonl:12
- Discovery (U1-07, affects run): At load ~3.6 (other lanes) every TEST_JOBS=4 full run tonight failed 1-4 timing-bound e2e checks, a different file each time; TEST_JOBS=2 with HARNESS_CHECK_TIMEOUT=25m is the way to a green → entries.jsonl:10
- Discovery (U1-07, affects run): status_stubs' mx now takes [<kind>:]<feature> (init:, verify:, refused:) and writes every row's at MX_AT s before HARNESS_NOW (default 1900); fl and mx stay defined after status_stubs → entries.jsonl:9
- Discovery (U1-07, affects U2, run): Deferred from the U1 review (docs/plans/2026-10-28-U1-review.md, Not done): wall hours of a continued run, the card's branch line hardcodes origin/main, lane liveness lacks lane_live's cmdline test, and the footer's --since 3d hint is not conditional on hidden runs → entries.jsonl:9
- Discovery (U1-07, affects run): Under load (~3.7, other lanes), full runs flaked once each in 28-run-14d-harness-merge and 48-lanes-rebase (an unknown run/<id>/M2 tag); both pass alone and neither reads status → entries.jsonl:9
- Discovery (U1-04, affects run): lanes admission (47-lanes-two, five-hour window at 80 %) failed once in a full run at load ~2.9 with TEST_JOBS=3; it never reads the status view → entries.jsonl:6
- Discovery (U1-03, affects U1-04, U1-05, U2): an ended run's summary.json is read record, then state dir, then ledger: the state dir's copy is harness report's and goes stale after a continue. session = metrics rows + 1 while running, never $STATE/sessions (reset each segment). The plan's §3.1 is corrected → entries.jsonl:5
- Discovery (U1-03, affects run): the full suite at TEST_JOBS=4 flaked 1-2 timing checks per run tonight (load around 3.7 with other lanes); TEST_JOBS=2 ran green in 866 s → entries.jsonl:5
- Discovery (U1-02, affects run): the full suite took 478 s and 481 s tonight (TEST_JOBS=4) → entries.jsonl:3
- Discovery (init, affects run): P1 and P2 of the lanes run are on origin/main (PRs #40 and #41): lib/lane.sh and lib/record.sh exist. The spec's check `git log --oneline origin/main | grep -c 'agent-harness-2026-10-26: P[12]'` prints 0 only because the merge subjects read `Merge pull request #40 from mh550/harness-merge/agent-harness-2026-10-26-P1`. The list is planned against the merged code; U1's lane rows build on P2-06's lane lines in cmd_status. → entries.jsonl:1
- Discovery (init, affects run): Driver sites by function, as the code stands: sync_main, needs_you, notify_park, merge_one, slot_open (the base-conflict note) in lib/record.sh; verify, the park branch and the given-up end in lib/lane.sh; finish, the EXIT trap and the coordinator loop in lib/driver.sh; cmd_status, cmd_report, cmd_queue, cmd_parked, cmd_gc, cmd_start, cmd_continue in bin/harness. → entries.jsonl:1
- Discovery (init, affects run): tests/checks/ ends at 50-lanes-record-pr.sh (new files from 51); tests/fixtures/check-names.txt has 601 names and the suite 602 checks. The init's full suite took 477 s on this box tonight, not the 208 s CLAUDE.md quotes: budget for it when a feature runs the suite more than once. → entries.jsonl:1
- Discovery (init, affects U2-02): The bug (a) fixture is real: in the n8n-home checkout, `git show 4632d1c:.harness/runs/n8n-home-2026-10-22/INBOX.md` has `## Answers".` on line 13 (inside the comment) and `## Answers` on line 28; sessions may read that project (user policy), never change it. → entries.jsonl:1
- Discovery (init, affects run): The step lint's outside-repo rule flags a tilde path and $HOME in step text; steps say 'the home directory shortened to a tilde' for the view's `home` rule. A grep in command position on progress.md, entries.jsonl, feature_list.json or context.md whose pattern matches the step itself is flagged too; harness-log.md greps are fine. → entries.jsonl:1

## What it builds on

- 2026-10-28 08:40 · U2-01 · passes: Wrote docs/plans/2026-10-28-U2-needs-record.md: the record's 24 keys (13 = event v1, in order) and card keys, file locations, the 15 reasons mapped to their functions with kind/severity/priority/key/sweep rule, a card template per reason, needs.sh/needs.mjs/inbox.mjs APIs, notification texts, check files 57-63, fixtures, touched checks, order U2-02..09. Code unchanged; suite cached green.; tests 689 → 689; files docs/plans/2026-10-28-U2-needs-record.md → entries.jsonl:12

## Lately in the run

- 2026-10-28 08:22 · verify U1 · passes: All 40 steps of U1-01..07 hold. Init suite red (7 checks in 08-scope, 45-lanes) was load flakes: both files pass alone (135/135); 51-56 pass 86/86; 25-run-13b flaked once, passes alone. Docs, fixtures, decision, prompts, syntax checked. → entries.jsonl:11
- 2026-10-28 08:07 · U1-07 · passes: U1 review: 1 Critical, 3 Important, 11 Minor (two Opus rounds, in f8ea1f6). This attempt changed no code: it re-verified all four steps and got a green full suite for the tree. TEST_JOBS=4 runs failed one to four different e2e timing checks each (46, 38, 32, 08), every file green alone.; tests 689 → 689 → entries.jsonl:10

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

_48 older rules: journal/decisions._
