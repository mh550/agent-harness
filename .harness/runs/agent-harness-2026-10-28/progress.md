<!-- harness: rendered from entries.jsonl after every session; edits here are overwritten -->
# Progress — run `agent-harness-2026-10-28` (agent-harness)

What this file is: the journal of this run, rendered by the harness from `entries.jsonl`, newest entry first. Each entry is one session (initializer, a feature's coding session, a milestone's verify) with what it did, what failed and what it found. The spec is `docs/specs/2026-10-27-status-ux.md`: read views (`harness status`, `queue list`, a new `show`) through one formatter, one needs-you record with cards, and five small fixes.

The feature list (`feature_list.json` beside this file) has three milestones built one after the other: **U1** the formatter and `status`/`queue list` (U1-01 to U1-07), **U2** the needs record, cards, `harness needs` and questions with locations (U2-01 to U2-09), **U3** `harness show`, project names, record after gc, gc's foreign units, same-project starts and overlaps, the TTY forms of report/trends/gc (U3-01 to U3-08). Each milestone starts with a plan feature, ends with an Opus review, and merges into `main` on its own once verified. A feature's `passes` flips when its session's steps hold and the suite is green.

Steer from `INBOX.md` on this branch: the first line `status: run|pause|stop`; answers to questions under `## Answers` at the end. `harness status agent-harness-2026-10-28` for the state, `harness needs` once U2 lands.

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
