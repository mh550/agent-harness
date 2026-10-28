# Context pack for `U1-06`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## Discoveries for this feature

- Discovery (U1-04, affects U1-05, U1-06): renderView(doc, {runs, extra, verbose, all, project, env}, ctx) in lib/status.mjs renders the default view from the v1 document; laneLine(l) (exported) rebuilds P2-06's lane line from a run object's lanes.open entry, text identical: U1-05's card can use both → entries.jsonl:6
- Discovery (U1-04, affects U1-06): QUEUED rows already use the queue-list row shape (n, verb, '<run> (requested)' or '<project> (new run)', spec basenames · brief "<30>…" (+k chars), age; 'held: <p> busy (<run>)' as a sub-line): U1-06 can reuse the qrows mapping → entries.jsonl:6
- Discovery (U1-04, affects run): lanes admission (47-lanes-two, five-hour window at 80 %) failed once in a full run at load ~2.9 with TEST_JOBS=3; it never reads the status view → entries.jsonl:6
- Discovery (U1-03, affects U1-04, U1-05, U1-06): status_stubs [<bulk>] (tests/lib.sh) builds the 8 U1 stub runs (done2h, done3d, stopped, running+lane M1+2 units, parked, givenup, gcd via ledger, crashed) and a 3-entry queue at HARNESS_NOW=1793145600, TZ=UTC; status_bulk <n> adds bulk-01..n. 53-55 can source them → entries.jsonl:5
- Discovery (U1-03, affects run): the full suite at TEST_JOBS=4 flaked 1-2 timing checks per run tonight (load around 3.7 with other lanes); TEST_JOBS=2 ran green in 866 s → entries.jsonl:5
- Discovery (U1-02, affects U1-04, U1-06): view.mjs table: put the glyph in the same cell as the id (glyph + space) to get the spec's '⚠ run-id' look; columns are joined by two spaces → entries.jsonl:3
- Discovery (U1-02, affects run): the full suite took 478 s and 481 s tonight (TEST_JOBS=4) → entries.jsonl:3
- Discovery (init, affects run): P1 and P2 of the lanes run are on origin/main (PRs #40 and #41): lib/lane.sh and lib/record.sh exist. The spec's check `git log --oneline origin/main | grep -c 'agent-harness-2026-10-26: P[12]'` prints 0 only because the merge subjects read `Merge pull request #40 from mh550/harness-merge/agent-harness-2026-10-26-P1`. The list is planned against the merged code; U1's lane rows build on P2-06's lane lines in cmd_status. → entries.jsonl:1
- Discovery (init, affects run): Driver sites by function, as the code stands: sync_main, needs_you, notify_park, merge_one, slot_open (the base-conflict note) in lib/record.sh; verify, the park branch and the given-up end in lib/lane.sh; finish, the EXIT trap and the coordinator loop in lib/driver.sh; cmd_status, cmd_report, cmd_queue, cmd_parked, cmd_gc, cmd_start, cmd_continue in bin/harness. → entries.jsonl:1
- Discovery (init, affects run): tests/checks/ ends at 50-lanes-record-pr.sh (new files from 51); tests/fixtures/check-names.txt has 601 names and the suite 602 checks. The init's full suite took 477 s on this box tonight, not the 208 s CLAUDE.md quotes: budget for it when a feature runs the suite more than once. → entries.jsonl:1
- Discovery (init, affects run): The step lint's outside-repo rule flags a tilde path and $HOME in step text; steps say 'the home directory shortened to a tilde' for the view's `home` rule. A grep in command position on progress.md, entries.jsonl, feature_list.json or context.md whose pattern matches the step itself is flagged too; harness-log.md greps are fine. → entries.jsonl:1

## What it builds on

- 2026-10-28 05:14 · U1-05 · passes: U1-05 passes, in commit `681d468` (pushed). The full suite is green: 668 tests, up from 655. - **The card:** `harness status <run>` now prints a card. Its first line gives the state or end class, `x/y passing` and the age. The fields are now, ended, milestones, lanes, spend, branch, worktree, needs you, units and next. `-v` or `N` adds the log tail. - **Old checks:** the old checks that read the …; files CLAUDE.md, bin/harness, journal/decisions/2026-10-27-read-views.md, lib/status.mjs, prompts/supervisor.md, … → entries.jsonl:7

## Lately in the run

- 2026-10-28 04:45 · U1-04 · passes: harness status (no run) is one screen via status.mjs renderView + view.mjs: NEEDS YOU, RUNNING, QUEUED, FINISHED, footer; --all, --since, -p, -v, N; fits 60/80; colour on a TTY only; ASCII under LC_ALL=C. STATUS_SINCE default + template; catch-up prompt; decision updated. 53-status-view.sh, 15 checks. An Opus review found 11 Minor issues; 9 fixed red to green.; tests 640 → 655; files lib/status.mjs, bin/harness, lib/config.sh, templates/user/config.sh, prompts/project-catchup.md, … → entries.jsonl:6
- 2026-10-28 03:52 · U1-03 · passes: lib/status.mjs builds the run, needs and queue objects (pure runObject, needsItems, queueEntry, sections) from run_rows' stdin; harness status [<run>] --json prints v1. status_stubs/status_bulk in tests/lib.sh; 52-status-json.sh, 15 checks; key-paths and pre-change text fixtures. Text unchanged. An Opus review found 3 Important and 3 Minor issues, all fixed red to green.; tests 625 → 640; files lib/status.mjs, bin/harness, tests/lib.sh, tests/checks/52-status-json.sh, tests/fixtures/status-json-keys.txt, … → entries.jsonl:5

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
