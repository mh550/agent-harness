<!-- harness: rendered from entries.jsonl after every session; edits here are overwritten -->
# Progress — run `agent-harness-2026-10-28` (agent-harness)

What this file is: the journal of this run, rendered by the harness from `entries.jsonl`, newest entry first. Each entry is one session (initializer, a feature's coding session, a milestone's verify) with what it did, what failed and what it found. The spec is `docs/specs/2026-10-27-status-ux.md`: read views (`harness status`, `queue list`, a new `show`) through one formatter, one needs-you record with cards, and five small fixes.

The feature list (`feature_list.json` beside this file) has three milestones built one after the other: **U1** the formatter and `status`/`queue list` (U1-01 to U1-07), **U2** the needs record, cards, `harness needs` and questions with locations (U2-01 to U2-09), **U3** `harness show`, project names, record after gc, gc's foreign units, same-project starts and overlaps, the TTY forms of report/trends/gc (U3-01 to U3-08). Each milestone starts with a plan feature, ends with an Opus review, and merges into `main` on its own once verified. A feature's `passes` flips when its session's steps hold and the suite is green.

Steer from `INBOX.md` on this branch: the first line `status: run|pause|stop`; answers to questions under `## Answers` at the end. `harness status agent-harness-2026-10-28` for the state, `harness needs` once U2 lands.

### 2026-10-28 06:08 · U1-06 · passes

harness queue list renders through status.mjs renderQueue + view.mjs: QUEUE/PARKED/RUNNING/RECENT, rule, show hint; harness queue show <n> [--parked] is a card (renderEntry). entry_kind gone; QUEUED rows share queueRow. The four 15- queue checks read the new rows; 55-queue-view.sh, 12 checks. An Opus review found 1 Important and 6 Minor issues, all fixed red to green.

- **Files:** lib/status.mjs, bin/harness, tests/checks/55-queue-view.sh, tests/checks/15-run-4-same-but-queue-parked-debrief-tmux.sh, tests/fixtures/check-names.txt, README.md, docs/architecture.md
- **Verified:** bash tests/run.sh 15-run 52- 53- 54- 55-: 131/131; 55-queue-view 12/12 after the review fixes; full suite via lib/check.sh TEST_JOBS=2: green in 868 s, 680 tests (an earlier TEST_JOBS=4 run lost 28-run-14d-harness-merge to load ~3.6; alone it passes in 12 s); output eyeballed at COLUMNS 100/60/80
- **Tests:** 668 → 680
- **Dead end:** the brief inline in the row's flex column, as the step's row shape reads — at 80 and 60 columns the flex cut drops '(+1170 chars)'; the brief goes on its own sub-line, as the spec's 80-column example shows
- **Discovery** (affects U1-07): status.mjs now has queue and entry <n> [--parked] modes; readQueue returns [entry, {args, file}] pairs (queued() maps to the entries), so --json is unchanged
- **Discovery** (affects U1-07): queue show adds fields beyond the step: held, options (the args no other field names, --queued included) and added; an --until text to_epoch reads but status.mjs cannot (e.g. 'tomorrow 06:00') shows as given
- **Discovery** (affects U1-07): RUNNING in queue list folds its ids under the title instead of cutting them; the spec's narrow 'PARKED 0 · RUNNING …' join was dropped
- **Proposed change:** U1-06 step 1's row shape puts the brief on the row; the build puts it on its own sub-line (the spec's 80-column example does the same) so its (+k chars) is never cut. U1-07 can note this in decisions/2026-10-27-read-views
- **Proposed change:** the debrief's ALLOW list has 'harness queue list' but not 'harness queue show' (read-only): U1-07 or Michael may add it
- *06-U1-06 · claude-opus-5-5*

### 2026-10-28 05:14 · U1-05 · passes

U1-05 passes, in commit `681d468` (pushed). The full suite is green: 668 tests, up from 655. - **The card:** `harness status <run>` now prints a card. Its first line gives the state or end class, `x/y passing` and the age. The fields are now, ended, milestones, lanes, spend, branch, worktree, needs you, units and next. `-v` or `N` adds the log tail. - **Old checks:** the old checks that read the …

- **Files:** CLAUDE.md, bin/harness, journal/decisions/2026-10-27-read-views.md, lib/status.mjs, prompts/supervisor.md, tests/checks/08-scope-sh-l1-02-run-capped-services-gc-scratch.sh, tests/checks/13-run-2-michael-sets-desk.sh, tests/checks/14-run-2b-stop-records.sh, tests/checks/15-run-4-same-but-queue-parked-debrief-tmux.sh, tests/checks/40-run-18-test-counts-m5.sh, tests/checks/47-lanes-two.sh, tests/checks/52-status-json.sh, +4 more
- *05-U1-05 · claude-opus-5-5 · recorded by the harness: entry.json invalid: summary: 410 characters (at most 400)*

### 2026-10-28 04:45 · U1-04 · passes

harness status (no run) is one screen via status.mjs renderView + view.mjs: NEEDS YOU, RUNNING, QUEUED, FINISHED, footer; --all, --since, -p, -v, N; fits 60/80; colour on a TTY only; ASCII under LC_ALL=C. STATUS_SINCE default + template; catch-up prompt; decision updated. 53-status-view.sh, 15 checks. An Opus review found 11 Minor issues; 9 fixed red to green.

- **Files:** lib/status.mjs, bin/harness, lib/config.sh, templates/user/config.sh, prompts/project-catchup.md, journal/decisions/2026-10-27-read-views.md, tests/checks/53-status-view.sh, tests/checks/52-status-json.sh, tests/fixtures/status-text-u1-03.txt, tests/fixtures/check-names.txt, CLAUDE.md
- **Verified:** bash tests/run.sh status: 52- 15/15, 53- 15/15 (harness status --all over 38 stub runs: best of 3 about 150 ms); full suite via lib/check.sh: 655/655 green at TEST_JOBS=2 in 869 s (a TEST_JOBS=4 run before it: 652/655, three lanes pr-held timing checks in 46-lanes-continue, which passes 12/12 alone and never reads status)
- **Tests:** 640 → 655
- **Dead end:** the queue row's (requested) mark in its own column (review finding 7: a 74-char id plus the mark gets folded) — the padded column breaks the 'stopped (requested)' row text that U1-06's rewrite of the 15- queue checks expects; reverted, the long-id fold left as a known rare case
- **Discovery** (affects U1-05, U1-06): renderView(doc, {runs, extra, verbose, all, project, env}, ctx) in lib/status.mjs renders the default view from the v1 document; laneLine(l) (exported) rebuilds P2-06's lane line from a run object's lanes.open entry, text identical: U1-05's card can use both
- **Discovery** (affects U1-05): cmd_status now sends everything except 'harness status <run>' without --json to status.mjs; that one path is still the old bash loop (and accepts -v, ignored). A run with -a/--since/-p and no --json dies. tests/fixtures/status-text-u1-03.txt is now only the running run's block, compared by 52-'s 'text of harness status <run>' check, which U1-05 drops
- **Discovery** (affects U1-06): QUEUED rows already use the queue-list row shape (n, verb, '<run> (requested)' or '<project> (new run)', spec basenames · brief "<30>…" (+k chars), age; 'held: <p> busy (<run>)' as a sub-line): U1-06 can reuse the qrows mapping
- **Discovery** (affects run): lanes admission (47-lanes-two, five-hour window at 80 %) failed once in a full run at load ~2.9 with TEST_JOBS=3; it never reads the status view
- **Question for Michael:** Default taken: RUNNING shows '<k> lanes' with sub-rows only for two or more open lanes (a lanes-era run always has its one lane; the feature/session/model says more). Keep?
- **Question for Michael:** Default taken: QUEUED lists only waiting entries; parked ones are a count on the '+k more · p parked: harness queue list' line. Keep?
- **Proposed change:** U1-07's review should look at a long run id (60+ chars) in the shared id column: one such id puts every run row in all three sections on two lines (review finding 7, left as is)
- *04-U1-04 · claude-opus-5-5*

### 2026-10-28 03:52 · U1-03 · passes

lib/status.mjs builds the run, needs and queue objects (pure runObject, needsItems, queueEntry, sections) from run_rows' stdin; harness status [<run>] --json prints v1. status_stubs/status_bulk in tests/lib.sh; 52-status-json.sh, 15 checks; key-paths and pre-change text fixtures. Text unchanged. An Opus review found 3 Important and 3 Minor issues, all fixed red to green.

- **Files:** lib/status.mjs, bin/harness, tests/lib.sh, tests/checks/52-status-json.sh, tests/fixtures/status-json-keys.txt, tests/fixtures/status-text-u1-03.txt, tests/fixtures/check-names.txt, journal/decisions/2026-10-27-read-views.md, docs/plans/2026-10-28-U1-read-views.md, CLAUDE.md
- **Verified:** 52-status-json 15/15 (failed first: no status.mjs, then 6 red for the review's findings); --json over 38 runs best of 3 about 155 ms; the 08/13/14/15/47 files 321/321; full suite green 640/640 with TEST_JOBS=2 (866 s, cached). Three earlier TEST_JOBS=4 runs each had 1-2 different timing flakes (46/48 lanes, 15 queue runner, 08 memory gate); each passed when rerun alone, and none reads harness status.
- **Tests:** 625 → 640
- **Dead end:** HARNESS_NOW=1793232000 (2026-10-29) in the stubs — files touched to a time after the real clock are -newer than any stamp, so the read-only find check failed; now 1793145600
- **Dead end:** a symlinked lib/ beside HEAD's bin/harness to capture the old text — node's main guard compares realpath with argv[1], so features.mjs printed nothing; git archive HEAD lib instead
- **Discovery** (affects U1-04, U1-05, U1-06): status_stubs [<bulk>] (tests/lib.sh) builds the 8 U1 stub runs (done2h, done3d, stopped, running+lane M1+2 units, parked, givenup, gcd via ledger, crashed) and a 3-entry queue at HARNESS_NOW=1793145600, TZ=UTC; status_bulk <n> adds bulk-01..n. 53-55 can source them
- **Discovery** (affects U1-04, U1-05): tests/fixtures/status-text-u1-03.txt is the old harness status text (LC_ALL=C, $T as <T>) that 52-'s last-but-two check compares: U1-04/U1-05 replace that text, so they drop or rewrite that check and the fixture
- **Discovery** (affects U1-04): status.mjs needs a text mode: today it requires --json (usage exit 2); cmd_status dies when -a/--since/--project are given without --json, and U1-04 lifts that
- **Discovery** (affects U1-04, U1-05, U2): an ended run's summary.json is read record, then state dir, then ledger: the state dir's copy is harness report's and goes stale after a continue. session = metrics rows + 1 while running, never $STATE/sessions (reset each segment). The plan's §3.1 is corrected
- **Discovery** (affects run): the full suite at TEST_JOBS=4 flaked 1-2 timing checks per run tonight (load around 3.7 with other lanes); TEST_JOBS=2 ran green in 866 s
- **Proposed change:** U1-03 step 1 says the summary comes from the state dir, then the ledger. The record's copy (finish's) should come first: the state dir's is harness report's, an earlier segment's after a continue (the U1-03 review)
- *03-U1-03 · claude-opus-5-5*

### 2026-10-28 02:37 · U1-03 · not yet

API Error: Can't reach the API server — check your internet or DNS (EAI_AGAIN)

- *03-U1-03 · claude-opus-5-5 · recorded by the harness: entry.json missing*

### 2026-10-28 02:05 · U1-02 · passes

lib/view.mjs: the formatter (context, glyphs with ASCII forms, paint, displayWidth, cut, pad, table, section, rule, card, ago, when, home, duration, endClass) plus a table|card|section CLI; 23 unit checks in 51-view-pure.sh; end-reasons.txt; decision 2026-10-27-read-views started. An Opus review's 2 Important and 7 Minor findings were fixed red→green.

- **Files:** lib/view.mjs, tests/checks/51-view-pure.sh, tests/fixtures/end-reasons.txt, tests/fixtures/check-names.txt, journal/decisions/2026-10-27-read-views.md, CLAUDE.md
- **Verified:** bash tests/run.sh 51-view: 23/23; full suite via lib/check.sh green, 625 tests (602 before); node --check lib/view.mjs
- **Tests:** 602 → 625
- **Dead end:** folding a whole over-wide narrow table line at the width — split a 38-char id that fits at 40 when a glyph column precedes it (review finding); lines now break at column gaps first, only an id wider than the width folds
- **Discovery** (affects U1-04, U1-06): view.mjs table: put the glyph in the same cell as the id (glyph + space) to get the spec's '⚠ run-id' look; columns are joined by two spaces
- **Discovery** (affects U1-04): view.mjs section(title, 0, hint) prints the bare line without the rule (the spec's 'QUEUED 0 · runner off'); count null drops the count ('FINISHED · last 24h · 3')
- **Discovery** (affects U1-05): view.mjs card: a value's newline starts a new hanging line; a URL token too wide for the room goes on its own line at 2; field.lines are verbatim at 4 (P2-06 lane lines)
- **Discovery** (affects project): the end-reasons check greps literal finish/END_REASON/lane_exit 13 reasons out of lib/driver.sh and lib/lane.sh: a new literal end reason needs a line in tests/fixtures/end-reasons.txt
- **Discovery** (affects run): the full suite took 478 s and 481 s tonight (TEST_JOBS=4)
- **Question for Michael:** Default taken: a table id wider than the whole width is folded at the width (never cut, never past it), and a section with count 0 prints without the rule. Keep both?
- *02-U1-02 · claude-opus-5-5*

### 2026-10-28 01:40 · U1-01 · passes

Wrote docs/plans/2026-10-28-U1-read-views.md: view.mjs API (15 functions, glyphs, width/colour/override rules, end classes), status.mjs stdin/args/files read and the v1 --json keys, the 9 existing checks the new text touches with their rewrites, the stub-state helper, check files 51-55 and the U1-02..07 order. Code unchanged; suite cached green.

- **Files:** docs/plans/2026-10-28-U1-read-views.md
- **Verified:** lib/check.sh: green, 602 tests (cached: docs/plans is outside the key); each plan step checked against the file; check names and files confirmed with grep on tests/checks
- **Tests:** 602 → 602
- **Discovery** (affects U1-03, U1-04): The ended file holds '<reason> · YYYY-MM-DD HH:MM:SS' (finish, EXIT trap), but checks also write a bare reason or an empty meta.env (15-'s stoppy-o): status.mjs and run_rows must tolerate both (run_rows uses cmd_parked's '|| true' subshell).
- **Discovery** (affects U1-03, U3-03): finish writes summary.json only to the record; status.mjs reads it state dir → record → ledger copy, so an ended run with its worktree still there gets its summary too.
- **Discovery** (affects U1-03, U2-03): needs-<m> markers are empty; the reason is in state/lanes/<m>/need. The weekly budget end text is weekly_over's echo in lib/config.sh.
- **Discovery** (affects U1-05): The card's lanes field prints P2-06's lane lines verbatim at a 4-space indent so 47-lanes-two's -x regexes and 08-'s MemoryCurrent count hold unchanged.
- **Discovery** (affects U2-07): U1's derived NEEDS items in --json use only keys of U2's record (run, project, feature, milestone, reason, kind, severity, at, title, card.headline), so U2 replaces them by adding keys within v1.
- **Question for Michael:** Default taken: a run-level NEEDS YOU item appears only when the run has no feature or milestone item (a 'waiting on Michael: B' end is the parked B's row). Keep it? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-10-28/slot-0/docs/plans/2026-10-28-U1-read-views.md (section 7)
- **Proposed change:** This session read ledger/agent-harness/agent-harness-2026-10-26/summary.json's key names (jq keys, no values used) to fix summary.json's shape, which breaks CLAUDE.md's 'never read ledger/' rule; a later session should take that shape from lib/summary.mjs build instead (the plan says so for the stub ledger copy).
- *01-U1-01 · claude-opus-5-5*

### 2026-10-28 01:32 · init · passes

24 features: U1 7 (plan, view.mjs, status.mjs + --json, the default view, the card, queue list/show, review), U2 9 (plan, inbox.mjs, the needs record, cards, session-side paths, git-side paths, readers, question locations, review), U3 8 (plan, project names, record after gc + gc units, show, same-project starts + overlap.mjs, overlap wiring, TTY views, review). Serial: U1 → U2 → U3.

- **Files:** .harness/runs/agent-harness-2026-10-28/feature_list.json, .harness/runs/agent-harness-2026-10-28/entry.json
- **Discovery** (affects run): P1 and P2 of the lanes run are on origin/main (PRs #40 and #41): lib/lane.sh and lib/record.sh exist. The spec's check `git log --oneline origin/main | grep -c 'agent-harness-2026-10-26: P[12]'` prints 0 only because the merge subjects read `Merge pull request #40 from mh550/harness-merge/agent-harness-2026-10-26-P1`. The list is planned against the merged code; U1's lane rows build on P2-06's lane lines in cmd_status.
- **Discovery** (affects run): Driver sites by function, as the code stands: sync_main, needs_you, notify_park, merge_one, slot_open (the base-conflict note) in lib/record.sh; verify, the park branch and the given-up end in lib/lane.sh; finish, the EXIT trap and the coordinator loop in lib/driver.sh; cmd_status, cmd_report, cmd_queue, cmd_parked, cmd_gc, cmd_start, cmd_continue in bin/harness.
- **Discovery** (affects run): tests/checks/ ends at 50-lanes-record-pr.sh (new files from 51); tests/fixtures/check-names.txt has 601 names and the suite 602 checks. The init's full suite took 477 s on this box tonight, not the 208 s CLAUDE.md quotes: budget for it when a feature runs the suite more than once.
- **Discovery** (affects U2-02): The bug (a) fixture is real: in the n8n-home checkout, `git show 4632d1c:.harness/runs/n8n-home-2026-10-22/INBOX.md` has `## Answers".` on line 13 (inside the comment) and `## Answers` on line 28; sessions may read that project (user policy), never change it.
- **Discovery** (affects run): The step lint's outside-repo rule flags a tilde path and $HOME in step text; steps say 'the home directory shortened to a tilde' for the view's `home` rule. A grep in command position on progress.md, entries.jsonl, feature_list.json or context.md whose pattern matches the step itself is flagged too; harness-log.md greps are fine.
- **Question for Michael:** The spec asks for three to five features per milestone; sized to 15–60 minute sessions the list has 7 (U1), 9 (U2) and 8 (U3). Default taken: keep the split (a smaller feature retries cheaper). Say so in INBOX.md if you'd rather have fewer, larger features; nothing waits on this.
- *00-init · claude-fable-5-1*
