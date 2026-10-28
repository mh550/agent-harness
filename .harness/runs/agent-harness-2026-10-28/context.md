# Context pack for `U1-04`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## Discoveries for this feature

- Discovery (U1-03, affects U1-04, U1-05, U1-06): status_stubs [<bulk>] (tests/lib.sh) builds the 8 U1 stub runs (done2h, done3d, stopped, running+lane M1+2 units, parked, givenup, gcd via ledger, crashed) and a 3-entry queue at HARNESS_NOW=1793145600, TZ=UTC; status_bulk <n> adds bulk-01..n. 53-55 can source them → entries.jsonl:5
- Discovery (U1-03, affects U1-04, U1-05): tests/fixtures/status-text-u1-03.txt is the old harness status text (LC_ALL=C, $T as <T>) that 52-'s last-but-two check compares: U1-04/U1-05 replace that text, so they drop or rewrite that check and the fixture → entries.jsonl:5
- Discovery (U1-03, affects U1-04): status.mjs needs a text mode: today it requires --json (usage exit 2); cmd_status dies when -a/--since/--project are given without --json, and U1-04 lifts that → entries.jsonl:5
- Discovery (U1-03, affects U1-04, U1-05, U2): an ended run's summary.json is read record, then state dir, then ledger: the state dir's copy is harness report's and goes stale after a continue. session = metrics rows + 1 while running, never $STATE/sessions (reset each segment). The plan's §3.1 is corrected → entries.jsonl:5
- Discovery (U1-03, affects run): the full suite at TEST_JOBS=4 flaked 1-2 timing checks per run tonight (load around 3.7 with other lanes); TEST_JOBS=2 ran green in 866 s → entries.jsonl:5
- Discovery (U1-02, affects U1-04, U1-06): view.mjs table: put the glyph in the same cell as the id (glyph + space) to get the spec's '⚠ run-id' look; columns are joined by two spaces → entries.jsonl:3
- Discovery (U1-02, affects U1-04): view.mjs section(title, 0, hint) prints the bare line without the rule (the spec's 'QUEUED 0 · runner off'); count null drops the count ('FINISHED · last 24h · 3') → entries.jsonl:3
- Discovery (U1-02, affects run): the full suite took 478 s and 481 s tonight (TEST_JOBS=4) → entries.jsonl:3
- Discovery (U1-01, affects U1-03, U1-04): The ended file holds '<reason> · YYYY-MM-DD HH:MM:SS' (finish, EXIT trap), but checks also write a bare reason or an empty meta.env (15-'s stoppy-o): status.mjs and run_rows must tolerate both (run_rows uses cmd_parked's '|| true' subshell). → entries.jsonl:2
- Discovery (init, affects run): P1 and P2 of the lanes run are on origin/main (PRs #40 and #41): lib/lane.sh and lib/record.sh exist. The spec's check `git log --oneline origin/main | grep -c 'agent-harness-2026-10-26: P[12]'` prints 0 only because the merge subjects read `Merge pull request #40 from mh550/harness-merge/agent-harness-2026-10-26-P1`. The list is planned against the merged code; U1's lane rows build on P2-06's lane lines in cmd_status. → entries.jsonl:1
- Discovery (init, affects run): Driver sites by function, as the code stands: sync_main, needs_you, notify_park, merge_one, slot_open (the base-conflict note) in lib/record.sh; verify, the park branch and the given-up end in lib/lane.sh; finish, the EXIT trap and the coordinator loop in lib/driver.sh; cmd_status, cmd_report, cmd_queue, cmd_parked, cmd_gc, cmd_start, cmd_continue in bin/harness. → entries.jsonl:1
- Discovery (init, affects run): tests/checks/ ends at 50-lanes-record-pr.sh (new files from 51); tests/fixtures/check-names.txt has 601 names and the suite 602 checks. The init's full suite took 477 s on this box tonight, not the 208 s CLAUDE.md quotes: budget for it when a feature runs the suite more than once. → entries.jsonl:1
- Discovery (init, affects run): The step lint's outside-repo rule flags a tilde path and $HOME in step text; steps say 'the home directory shortened to a tilde' for the view's `home` rule. A grep in command position on progress.md, entries.jsonl, feature_list.json or context.md whose pattern matches the step itself is flagged too; harness-log.md greps are fine. → entries.jsonl:1

## What it builds on

- 2026-10-28 03:52 · U1-03 · passes: lib/status.mjs builds the run, needs and queue objects (pure runObject, needsItems, queueEntry, sections) from run_rows' stdin; harness status [<run>] --json prints v1. status_stubs/status_bulk in tests/lib.sh; 52-status-json.sh, 15 checks; key-paths and pre-change text fixtures. Text unchanged. An Opus review found 3 Important and 3 Minor issues, all fixed red to green.; tests 625 → 640; files lib/status.mjs, bin/harness, tests/lib.sh, tests/checks/52-status-json.sh, tests/fixtures/status-json-keys.txt, … → entries.jsonl:5

## Lately in the run

- 2026-10-28 02:37 · U1-03 · not yet: API Error: Can't reach the API server — check your internet or DNS (EAI_AGAIN) → entries.jsonl:4
- 2026-10-28 02:05 · U1-02 · passes: lib/view.mjs: the formatter (context, glyphs with ASCII forms, paint, displayWidth, cut, pad, table, section, rule, card, ago, when, home, duration, endClass) plus a table|card|section CLI; 23 unit checks in 51-view-pure.sh; end-reasons.txt; decision 2026-10-27-read-views started. An Opus review's 2 Important and 7 Minor findings were fixed red→green.; tests 602 → 625; files lib/view.mjs, tests/checks/51-view-pure.sh, tests/fixtures/end-reasons.txt, tests/fixtures/check-names.txt, journal/decisions/2026-10-27-read-views.md, … → entries.jsonl:3

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
- The retro backlog: the retro proposes as data, the driver is the only writer → journal/decisions/2026-10-26-retro-backlog.md

_46 older rules: journal/decisions._
