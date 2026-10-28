# Context pack for `U2-08`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## Discoveries for this feature

- Discovery (U2-07, affects U2-09, run): status_stubs now opens the parked and givenup runs' records (nopen, at the stub's old times); the given-up headline is the template's 'C given up after 2 attempts', so 52/53 read that instead of U1's '(2 attempts)' → entries.jsonl:18
- Discovery (U2-07, affects U2-09, run): With U1's run_end row gone, a run that ended failed or waiting with no record (e.g. 'no feature left to try', an unknown POLICY) shows in neither NEEDS YOU nor harness needs, only as FINISHED's red glyph → entries.jsonl:18
- Discovery (U2-06, affects run, U2-09): lib/driver.sh coordinator: alive was counted before the second reap, so a lane reaped there skipped the open and the run ended 'no feature left to try' with an independent milestone untried; alive is recounted now (a likely source of earlier lane flakes) → entries.jsonl:17
- Discovery (U2-06, affects U2-07, U2-08, U2-09): tests/stub-claude.sh STUB_MAIN_TOUCH=<id|verify-<m>>:<path> lands another run's PR merge (#7, other-M3) on origin main adding <path>; STUB_THIN_VERIFY=all keeps every verify round thin → entries.jsonl:17
- Discovery (U2-05, affects U2-06, U2-07, U2-08): tests/stub-claude.sh STUB_GIVE_UP=<id>: every coding session of that feature ends not passing; with MAX_ATTEMPTS=1 in the user config it is given up after one → entries.jsonl:16
- Discovery (U2-05, affects run): 46-lanes-continue's 'record-only run … ends done' failed once in a full TEST_JOBS=2 run at load, passing alone and twice under load: a timing flake → entries.jsonl:16
- Discovery (U2-02, affects U2-03, U2-04, U2-05, U2-08): lib/inbox.mjs has answers/insert/question/repair CLIs and pure question, questionLine (1-based line of the question's first line), files ([{path,line}] from Files: lines) for U2-04/05/08; parked.mjs questionFor and notify.mjs inboxQuestion are aliases of question/added → entries.jsonl:13
- Discovery (U2-02, affects U2-05, U2-08): tests/stub-claude.sh STUB_INBOX_IN_COMMENT=<id>: that feature's first session splits the steering comment after 'under ' with '## Questions' + '**Q1 (<id>, stub).** set the gatus vars, then answer' and parks → entries.jsonl:13
- Discovery (U2-02, affects U2): added() now ignores HTML comments and reads the repaired text; inbox_repair (lib/record.sh) is a no-op when a session only rewords the comment → entries.jsonl:13
- Discovery (U2-01, affects U2-02, U2-03, U2-04, U2-05, U2-06, U2-07, U2-08): tests/checks/56- is taken (56-status-review.sh): U2's new check files are 57-inbox, 58-needs-record, 59-needs-cards, 60-needs-driver, 61-needs-git, 62-needs-readers, 63-question-locations → entries.jsonl:12
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

## Promote to Gotchas

- status-json-keys.txt now lists every key path of the stubs' three needs records (parked, given_up, synthesized driver_crash); a new card field in those templates changes it → entries.jsonl:18

## What it builds on

- 2026-10-28 13:34 · U2-07 · passes: Status reads the needs records: lib/status.mjs imports needs.mjs list (now exported) for NEEDS YOU, --json needs (whole records) and the card's needs you (count, 3 headlines, +k more); U1's derived rows gone. The desk prompt and answer skill read harness needs; the debrief adds a #### needs block. 62-needs-readers (6 checks). Opus review fixes.; tests 763 → 769; files lib/status.mjs, lib/needs.mjs, lib/debrief.sh, prompts/desk.md, skills/harness-answer/SKILL.md, … → entries.jsonl:18

## Lately in the run

- 2026-10-28 12:57 · U2-06 · passes: Git-side stop paths open needs records: sync_main's main_conflict (files, PR subjects, notified once per main commit, resolved by a clean merge or the milestone merged), merge_one's merge_conflict/merge_refused, verify's three, rebase_fail, slot_open/slot_fail base_conflict, reap driver_crash; needs_you sends the record. 61-needs-git (10 checks). Coordinator stale-alive race fixed.; tests 753 → 763; files lib/record.sh, lib/lane.sh, lib/driver.sh, lib/needs.mjs, tests/checks/61-needs-git.sh, … → entries.jsonl:17

_1 items left out at 8192 bytes: entries.jsonl has them all._
