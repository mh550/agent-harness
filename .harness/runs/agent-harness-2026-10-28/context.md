# Context pack for `U2-04`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## Discoveries for this feature

- Discovery (U2-03, affects U2-04, U2-05): Deferred from U2-03 to the features that use them: needs.mjs md/fields CLIs and <record>/needs.md (U2-05 commits and clicks it), needs_waits and the waits fact (U2-04's blocked field). The card has every §1.2 key but only headline filled. → entries.jsonl:14
- Discovery (U2-03, affects U2-04, U2-07): harness needs prints one line per item '<glyph> <run> · <headline> · <ref>' (synthesized parked headline '<id> parked: <why>', so 54's 'harness needs parked' check still greps the why); U2-04 replaces it with cards → entries.jsonl:14
- Discovery (U2-03, affects U2-04, U2-05, U2-06): needs_fixture <reason> open|resolved [<at epoch>] [<run>] in tests/lib.sh writes $HARNESS_STATE/proj/<run> with markers per plan §2.1 → entries.jsonl:14
- Discovery (U2-02, affects U2-03, U2-04, U2-05, U2-08): lib/inbox.mjs has answers/insert/question/repair CLIs and pure question, questionLine (1-based line of the question's first line), files ([{path,line}] from Files: lines) for U2-04/05/08; parked.mjs questionFor and notify.mjs inboxQuestion are aliases of question/added → entries.jsonl:13
- Discovery (U2-02, affects U2): added() now ignores HTML comments and reads the repaired text; inbox_repair (lib/record.sh) is a no-op when a session only rewords the comment → entries.jsonl:13
- Discovery (U2-01, affects U2-02, U2-03, U2-04, U2-05, U2-06, U2-07, U2-08): tests/checks/56- is taken (56-status-review.sh): U2's new check files are 57-inbox, 58-needs-record, 59-needs-cards, 60-needs-driver, 61-needs-git, 62-needs-readers, 63-question-locations → entries.jsonl:12
- Discovery (U2-01, affects U2-04, U2-05): harness parked's text is read by seven 13- checks (parky · proj · B, running:, next commands); making parked an alias in U2-04 before U2-05 opens records needs list to synthesize parked items from parked.json (plan §2.2), and those checks rewritten to the card's words (plan §5.2) → entries.jsonl:12
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

- 2026-10-28 09:53 · U2-03 · passes: lib/needs.mjs: the needs record (24 keys, first 13 = event v1), REASONS (15), pure record/refresh/sweep/synthesize/order, CLI open (0 new, 3 refreshed)/sweep/done/list; lib/needs.sh needs_open (sourced by driver, lane, harness; no caller); harness needs [--all] [--json] and needs done; needs_fixture; 58-needs-record (15 checks); decision needs-record.; tests 700 → 715; files lib/needs.mjs, lib/needs.sh, bin/harness, lib/driver.sh, lib/lane.sh, … → entries.jsonl:14

## Lately in the run

- 2026-10-28 09:19 · U2-02 · passes: lib/inbox.mjs: one INBOX parser (answersLine outside the steering comment, question, questionLine, added, answers, insert, files, repair + CLI); parked/notify/entries/record.sh on it; inbox_repair after each lane session (slot copy) and the initializer, noted; template comment without ## Answers; STUB_INBOX_IN_COMMENT; 57-inbox (11 checks), n8n-home fixture.; tests 689 → 700; files lib/inbox.mjs, lib/parked.mjs, lib/notify.mjs, lib/entries.mjs, lib/record.sh, … → entries.jsonl:13
- 2026-10-28 08:40 · U2-01 · passes: Wrote docs/plans/2026-10-28-U2-needs-record.md: the record's 24 keys (13 = event v1, in order) and card keys, file locations, the 15 reasons mapped to their functions with kind/severity/priority/key/sweep rule, a card template per reason, needs.sh/needs.mjs/inbox.mjs APIs, notification texts, check files 57-63, fixtures, touched checks, order U2-02..09. Code unchanged; suite cached green.; tests 689 → 689; files docs/plans/2026-10-28-U2-needs-record.md → entries.jsonl:12

## Current rules

- The review gate: a milestone review's model by its measured diff, one Opus round after a Sonnet finding → journal/decisions/2026-10-27-review-gate.md
- Read views: one formatter, `lib/view.mjs`, that every read view renders through → journal/decisions/2026-10-27-read-views.md
- Questions where Michael sees them: one INBOX parser, the steering comment repaired → journal/decisions/2026-10-27-question-locations.md
- Merging the memory run into lanes: main's driver changes in their lane-era homes, the review round per lane → journal/decisions/2026-10-27-p1-main-merge.md

_57 older rules: journal/decisions._
