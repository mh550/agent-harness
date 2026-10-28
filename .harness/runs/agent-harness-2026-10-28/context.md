# Context pack for `U2-06`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## Discoveries for this feature

- Discovery (U2-05, affects U2-06, U2-07): needs.mjs record() now fills body (bodyOf: renderCard at 60 columns, plain; a park's PARKED:/question/blocked-where-do/Answer) and click (needs.md on the record branch; a click= fact wins, for merge_refused's PR) → entries.jsonl:16
- Discovery (U2-05, affects U2-06): needs_notify <ref> <msg> [k=v…] sends the record's title/body/click/priority/actions over the caller's k=v (the caller's are the fallback and tags=); U2-06's needs_you can use it → entries.jsonl:16
- Discovery (U2-05, affects U2-06, U2-07): needs_open's stdout is the ref alone (its failure note goes to stderr); open and sweep rewrite <record>/needs.md only when its text changes, and never create it for a run with no item → entries.jsonl:16
- Discovery (U2-05, affects U2-06, U2-07, U2-08): tests/stub-claude.sh STUB_GIVE_UP=<id>: every coding session of that feature ends not passing; with MAX_ATTEMPTS=1 in the user config it is given up after one → entries.jsonl:16
- Discovery (U2-05, affects run): 46-lanes-continue's 'record-only run … ends done' failed once in a full TEST_JOBS=2 run at load, passing alone and twice under load: a timing flake → entries.jsonl:16
- Discovery (U2-04, affects U2-05, U2-06): blocked's waits are computed in needs.mjs (waitsOn over features.mjs deps) when no waits= is passed; no needs_waits shell function exists. needs_open now passes state= and suite= ($CHECK_CMD). U2-05/06 openers pass list= and inbox= and get blocked, where and question for free → entries.jsonl:15
- Discovery (U2-03, affects U2-05, U2-06): needs.mjs open defaults feature to the subject for parked/given_up, milestone to the subject for verify_*/merge_*/main_conflict/base_conflict/driver_crash (not run/record), else the list's milestone (list= fact); positional run/reason/subject beat key=value → entries.jsonl:14
- Discovery (U2-03, affects U2-04, U2-05, U2-06): needs_fixture <reason> open|resolved [<at epoch>] [<run>] in tests/lib.sh writes $HARNESS_STATE/proj/<run> with markers per plan §2.1 → entries.jsonl:14
- Discovery (U2-02, affects U2): added() now ignores HTML comments and reads the repaired text; inbox_repair (lib/record.sh) is a no-op when a session only rewords the comment → entries.jsonl:13
- Discovery (U2-01, affects U2-02, U2-03, U2-04, U2-05, U2-06, U2-07, U2-08): tests/checks/56- is taken (56-status-review.sh): U2's new check files are 57-inbox, 58-needs-record, 59-needs-cards, 60-needs-driver, 61-needs-git, 62-needs-readers, 63-question-locations → entries.jsonl:12
- Discovery (U2-01, affects U2-05, U2-06): Two 13- checks assert today's clicks: the park notification's Click is INBOX.md and verify's is progress.md; the spec's needs.md click changes exactly those two assertions (U2-05, U2-06) → entries.jsonl:12
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
- Discovery (init, affects run): The step lint's outside-repo rule flags a tilde path and $HOME in step text; steps say 'the home directory shortened to a tilde' for the view's `home` rule. A grep in command position on progress.md, entries.jsonl, feature_list.json or context.md whose pattern matches the step itself is flagged too; harness-log.md greps are fine. → entries.jsonl:1

## What it builds on

- 2026-10-28 11:38 · U2-05 · passes: Stop paths open needs records: the lane's park (question line/URL, actions) and given_up, finish's four reasons, the EXIT trap's driver_crash. Records carry a 60-col body and click = needs.md (markdown, committed with the record). Park notification is the record's (needs_notify). Sweeps: lane and coordinator after unpark, finish, continue, gc. 60-needs-driver (9 checks).; tests 744 → 753; files lib/needs.mjs, lib/needs.sh, lib/lane.sh, lib/record.sh, lib/driver.sh, … → entries.jsonl:16

## Lately in the run

- 2026-10-28 10:31 · U2-04 · passes: Cards by code: TEMPLATES (15, data) in lib/needs.mjs, card(reason, facts) and the card CLI, waitsOn, mergedBy; 15 fixtures in tests/fixtures/needs; harness needs as view.mjs cards (cutFront, card rule:false) with footer, 60 columns clean; harness parked = needs for text, --json joined with ref and card; notify.mjs urls compare; 59-needs-cards; Opus review fixed.; tests 715 → 744; files lib/needs.mjs, lib/view.mjs, lib/notify.mjs, lib/parked.mjs, lib/needs.sh, … → entries.jsonl:15

_1 items left out at 8192 bytes: entries.jsonl has them all._
