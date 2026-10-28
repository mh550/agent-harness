<!-- harness: rendered from entries.jsonl after every session; edits here are overwritten -->
# Progress — run `agent-harness-2026-10-28` (agent-harness)

What this file is: the journal of this run, rendered by the harness from `entries.jsonl`, newest entry first. Each entry is one session (initializer, a feature's coding session, a milestone's verify) with what it did, what failed and what it found. The spec is `docs/specs/2026-10-27-status-ux.md`: read views (`harness status`, `queue list`, a new `show`) through one formatter, one needs-you record with cards, and five small fixes.

The feature list (`feature_list.json` beside this file) has three milestones built one after the other: **U1** the formatter and `status`/`queue list` (U1-01 to U1-07), **U2** the needs record, cards, `harness needs` and questions with locations (U2-01 to U2-09), **U3** `harness show`, project names, record after gc, gc's foreign units, same-project starts and overlaps, the TTY forms of report/trends/gc (U3-01 to U3-08). Each milestone starts with a plan feature, ends with an Opus review, and merges into `main` on its own once verified. A feature's `passes` flips when its session's steps hold and the suite is green.

Steer from `INBOX.md` on this branch: the first line `status: run|pause|stop`; answers to questions under `## Answers` at the end. `harness status agent-harness-2026-10-28` for the state, `harness needs` once U2 lands.

### 2026-10-28 13:34 · U2-07 · passes

Status reads the needs records: lib/status.mjs imports needs.mjs list (now exported) for NEEDS YOU, --json needs (whole records) and the card's needs you (count, 3 headlines, +k more); U1's derived rows gone. The desk prompt and answer skill read harness needs; the debrief adds a #### needs block. 62-needs-readers (6 checks). Opus review fixes.

- **Files:** lib/status.mjs, lib/needs.mjs, lib/debrief.sh, prompts/desk.md, skills/harness-answer/SKILL.md, tests/checks/62-needs-readers.sh, tests/lib.sh, tests/checks/13-run-2-michael-sets-desk.sh, tests/checks/15-run-4-same-but-queue-parked-debrief-tmux.sh, tests/checks/52-status-json.sh, tests/checks/53-status-view.sh, tests/fixtures/status-json-keys.txt, +4 more
- **Verified:** full suite via check.sh (TEST_JOBS=2, 25m timeout): green in 953 s, 769 tests; 62 6/6, the status files 52-56 all pass; 13- (66) and 15- (79) pass with the new desk/skill/debrief checks; red first: 62 was 0/5 before the code
- **Tests:** 763 → 769
- **Dead end:** a feature list with a null entry as 62's unreadable state dir — status.mjs's own features() crashes on it, before needs.mjs is asked (older than U2); used a parked.json with an empty id instead
- **Discovery** (affects U2-09, run): status_stubs now opens the parked and givenup runs' records (nopen, at the stub's old times); the given-up headline is the template's 'C given up after 2 attempts', so 52/53 read that instead of U1's '(2 attempts)'
- **Discovery** (affects U2-09): status.mjs computes needs only in view and card mode, for the runs it shows (needsOf), so queue list/show never touch needs.mjs; needs.mjs list skips a state dir it can't read (stderr 'needs.mjs: <dir>: <msg>'), and status passes that line through
- **Discovery** (affects U2-09, run): With U1's run_end row gone, a run that ended failed or waiting with no record (e.g. 'no feature left to try', an unknown POLICY) shows in neither NEEDS YOU nor harness needs, only as FINISHED's red glyph
- **Discovery** (affects U2-09, project): status-json-keys.txt now lists every key path of the stubs' three needs records (parked, given_up, synthesized driver_crash); a new card field in those templates changes it
- **Question for Michael:** U1 showed any failed or waiting end without another item as a NEEDS YOU row (run_end); with the records it shows only where finish opened one (feature_list_edits, initializer_failed, the limits). Default taken: no generic item, so 'no feature left to try' is visible only in FINISHED. Should finish open a record for every failed or waiting end (a new reason, say run_end), in U2-09 or U3?
- **Proposed change:** U2-09 review: lib/desk.sh's notification still says 'Or by hand: harness parked <run>' (the plan keeps the alias); switch it to harness needs if wanted
- **Proposed change:** U2-09 review: 52/53's 'the gc'd run none' clauses pass only because the gcd stub has no records; a gc'd run whose harness/<run> branch survives keeps its non-parked records in both harness needs and status (needs.mjs's removed rule)
- *15-U2-07 · claude-opus-5-5*

### 2026-10-28 12:57 · U2-06 · passes

Git-side stop paths open needs records: sync_main's main_conflict (files, PR subjects, notified once per main commit, resolved by a clean merge or the milestone merged), merge_one's merge_conflict/merge_refused, verify's three, rebase_fail, slot_open/slot_fail base_conflict, reap driver_crash; needs_you sends the record. 61-needs-git (10 checks). Coordinator stale-alive race fixed.

- **Files:** lib/record.sh, lib/lane.sh, lib/driver.sh, lib/needs.mjs, tests/checks/61-needs-git.sh, tests/stub-claude.sh, tests/fixtures/merge-tree-name-only.txt, tests/checks/13-run-2-michael-sets-desk.sh, tests/checks/58-needs-record.sh, tests/fixtures/check-names.txt, journal/decisions/2026-10-27-needs-record.md, docs/architecture.md, +2 more
- **Verified:** full suite green: 763 tests in 941 s (TEST_JOBS=2); 61-needs-git 10/10 (main_conflict once over 2 verifies, resolved after a hand merge + continue; merge_conflict, merge_refused with PR click, verify_thin, verify_recheck, base_conflict, coordinator merge_one), 13- 66/66, 58- 15/15; the coordinator check watched failing without its fix
- **Tests:** 753 → 763
- **Dead end:** the plan's `git log --merges <base>..origin/main -- <files>` for main_conflict's subjects — history simplification hides a merge that took the file whole from its second parent: prints nothing; --first-parent lists main's merges
- **Dead end:** several stub runs in 61- on one origin main — the first run's continue merged M1/M2 into main, so later runs found work files already there; main is reset (update-ref) between runs
- **Discovery** (affects run, U2-09): lib/driver.sh coordinator: alive was counted before the second reap, so a lane reaped there skipped the open and the run ended 'no feature left to try' with an independent milestone untried; alive is recounted now (a likely source of earlier lane flakes)
- **Discovery** (affects U2-07, U2-09): a main conflict now notifies and starts/briefs the desk (needs_you); 13-'s strict continue meets one (other runs merged work-A.txt), so its desk check accepts the verify reaching the open desk
- **Discovery** (affects U2-07, U2-09): needs.mjs rule: verify_* wait on needs-<m> before verified-<m> (a failed re-base keeps verified-<m>) and resolve on merged-<m>; main_conflict resolves on merged-<m> too; 58-'s sweep unit check changed accordingly
- **Discovery** (affects U2-07, U2-08, U2-09): tests/stub-claude.sh STUB_MAIN_TOUCH=<id|verify-<m>>:<path> lands another run's PR merge (#7, other-M3) on origin main adding <path>; STUB_THIN_VERIFY=all keeps every verify round thin
- **Discovery** (affects project): stub runs in one check file share origin main: reset it (update-ref refs/heads/main <first>) between runs that write the same work files
- **Discovery** (affects U2-09): not done (review minor): conflict_files reads merge-tree output without -z, so a path git quotes stays quoted in the card
- **Question for Michael:** A main conflict and merge_one's conflict on the same main are one notification (merge_one's skipped when the lane's main-conflict-<m> holds that main), but two records: keep both, or fold merge_conflict into main_conflict then? (default: both records)
- **Proposed change:** U2-06 step 3 names tests/checks/60-needs-git.sh; 60- is U2-05's needs-driver, the file is 61-needs-git.sh as the plan says
- **Proposed change:** plan §4.2's sync_main subjects command needs --first-parent
- *14-U2-06 · claude-opus-5-5*

### 2026-10-28 11:38 · U2-05 · passes

Stop paths open needs records: the lane's park (question line/URL, actions) and given_up, finish's four reasons, the EXIT trap's driver_crash. Records carry a 60-col body and click = needs.md (markdown, committed with the record). Park notification is the record's (needs_notify). Sweeps: lane and coordinator after unpark, finish, continue, gc. 60-needs-driver (9 checks).

- **Files:** lib/needs.mjs, lib/needs.sh, lib/lane.sh, lib/record.sh, lib/driver.sh, bin/harness, tests/checks/60-needs-driver.sh, tests/checks/13-run-2-michael-sets-desk.sh, tests/stub-claude.sh, tests/fixtures/check-names.txt, docs/architecture.md, README.md, +2 more
- **Verified:** bash tests/run.sh 60-needs: 9/9 (red 1/9 before the code); 13/15/08/14/16/46/58/59 subset 342/342; full suite TEST_JOBS=2: 752/753 with one 46-lanes-continue timing check failing once, 12/12 alone and twice under load, then the full suite again: green in 953 s, 753 tests (check.sh). One Opus review: 3 Minor, all fixed (needs_open's failure note on stderr so nref is the ref alone; the park keeps INBOX.md as the fallback click; gc's sweep can't end gc under set -e; no needs.md for a run that never had an item).
- **Tests:** 744 → 753
- **Dead end:** a given_up opener at the lane's exit 10 as well — redundant (every give-up follows a session) and its refresh changed needs.md, adding a record commit
- **Dead end:** needs.md showing 'seen N times' — the coordinator's refreshes would rewrite it every poll
- **Discovery** (affects U2-06, U2-07): needs.mjs record() now fills body (bodyOf: renderCard at 60 columns, plain; a park's PARKED:/question/blocked-where-do/Answer) and click (needs.md on the record branch; a click= fact wins, for merge_refused's PR)
- **Discovery** (affects U2-06): needs_notify <ref> <msg> [k=v…] sends the record's title/body/click/priority/actions over the caller's k=v (the caller's are the fallback and tags=); U2-06's needs_you can use it
- **Discovery** (affects U2-06, U2-07): needs_open's stdout is the ref alone (its failure note goes to stderr); open and sweep rewrite <record>/needs.md only when its text changes, and never create it for a run with no item
- **Discovery** (affects U2-06, U2-07, U2-08): tests/stub-claude.sh STUB_GIVE_UP=<id>: every coding session of that feature ends not passing; with MAX_ATTEMPTS=1 in the user config it is given up after one
- **Discovery** (affects run): 46-lanes-continue's 'record-only run … ends done' failed once in a full TEST_JOBS=2 run at load, passing alone and twice under load: a timing flake
- **Question for Michael:** Default kept (plan §8 Q3): the park notification's tap opens needs.md, with Edit INBOX still an action button. Keep it?
- **Question for Michael:** Default: harness needs done doesn't re-render needs.md (the next sweep under a driver does), so an ended run's worktree stays clean for gc. Fine?
- **Proposed change:** U2-05 step 1 says the existing park notification checks pass unchanged, but plan §5.2 (and step 3's click) changes the 13- Click assertion to needs.md: only that line changed
- **Proposed change:** U2-05 step 4 names tests/checks/59-needs-driver.sh; 59 is taken by the cards, so the file is 60-needs-driver.sh (as U2-01 planned)
- *13-U2-05 · claude-opus-5-5*

### 2026-10-28 10:31 · U2-04 · passes

Cards by code: TEMPLATES (15, data) in lib/needs.mjs, card(reason, facts) and the card CLI, waitsOn, mergedBy; 15 fixtures in tests/fixtures/needs; harness needs as view.mjs cards (cutFront, card rule:false) with footer, 60 columns clean; harness parked = needs for text, --json joined with ref and card; notify.mjs urls compare; 59-needs-cards; Opus review fixed.

- **Files:** lib/needs.mjs, lib/view.mjs, lib/notify.mjs, lib/parked.mjs, lib/needs.sh, bin/harness, tests/checks/59-needs-cards.sh, tests/checks/58-needs-record.sh, tests/checks/13-run-2-michael-sets-desk.sh, tests/fixtures/needs/*.json, tests/fixtures/check-names.txt, prompts/desk.md, +5 more
- **Verified:** bash tests/run.sh 59: 29/29; 58: 15/15; 13-run-2: 66/66; 03: 7/7; full suite via check.sh TEST_JOBS=2: green, 744 tests in 907 s. One Opus review of the diff (0 Critical, 2 Important, 12 Minor): 13 fixed (desk/skill read --json commands, mergedBy splits merge heads at the last - so default lanes and own merges are left out, fences/tabs in questions, bad at, narrow ref keeps since, ~ in Files:, empty waits=, re-merge newest PR, commit row, gc'd parks hidden, card needs run, jq null guard), one check for them; ASCII content glyphs left (record text is Unicode by plan §1.1).
- **Tests:** 715 → 744
- **Dead end:** inline node -e JS with nested backtick/quote escaping inside a check's single-quoted command — unreadable and broke; a quoted heredoc writing $T/review.mjs, run with paths as argv, works
- **Discovery** (affects U2-05, U2-06): blocked's waits are computed in needs.mjs (waitsOn over features.mjs deps) when no waits= is passed; no needs_waits shell function exists. needs_open now passes state= and suite= ($CHECK_CMD). U2-05/06 openers pass list= and inbox= and get blocked, where and question for free
- **Discovery** (affects U2-05, U2-07): A park's headline keeps its why ('B parked: set the gatus vars'); a stored parked card's commands and run_state are recomputed by list (asOfNow) from driver.pid, ended, the runner and queue/*-continue-<run>.args; parks of gc'd worktrees are not listed
- **Discovery** (affects U2-05): record body is still the headline: the 60-column plain card body (plan §1.1 #9, §3.2) is U2-05's, via renderCard with HARNESS_GLYPHS=unicode, no colour
- **Discovery** (affects U2-07): prompts/desk.md and the answer skill now say to run a parked feature's commands from harness parked <run> --json (the text view wraps them and shortens paths); U2-07 still switches the desk to COLUMNS=60 harness needs
- **Proposed change:** U2-04 step 3's header: when '<glyph> <run> · <headline> · since … · <ref>' is wider than the line, the card uses '… · <ago>' and a 'ref <ref> · since <HH:MM> (<ago>)' field (default, in decisions/2026-10-27-needs-record)
- *12-U2-04 · claude-opus-5-5*

### 2026-10-28 09:53 · U2-03 · passes

lib/needs.mjs: the needs record (24 keys, first 13 = event v1), REASONS (15), pure record/refresh/sweep/synthesize/order, CLI open (0 new, 3 refreshed)/sweep/done/list; lib/needs.sh needs_open (sourced by driver, lane, harness; no caller); harness needs [--all] [--json] and needs done; needs_fixture; 58-needs-record (15 checks); decision needs-record.

- **Files:** lib/needs.mjs, lib/needs.sh, bin/harness, lib/driver.sh, lib/lane.sh, tests/checks/58-needs-record.sh, tests/lib.sh, tests/checks/57-inbox.sh, tests/fixtures/check-names.txt, journal/decisions/2026-10-27-needs-record.md, docs/architecture.md, README.md, +1 more
- **Verified:** 58-needs-record 15/15, each check watched red under a mutation of needs.mjs (no severity order, never removed, never unparked, no seen bump, no crash synth, no subject defaults); 03/13/53/54/57 130/130; full suite green in 628 s (TEST_JOBS=3), 715 tests; bash -n and node --check clean; needs_open sanity with stub record: 0, 3, 1 + note.
- **Tests:** 700 → 715
- **Dead end:** extracting check names with sed 's/^check "(.*)" .*/' — greedy on a one-line check with " inside its command: the conformance check failed once
- **Discovery** (affects U2-04, U2-05): Deferred from U2-03 to the features that use them: needs.mjs md/fields CLIs and <record>/needs.md (U2-05 commits and clicks it), needs_waits and the waits fact (U2-04's blocked field). The card has every §1.2 key but only headline filled.
- **Discovery** (affects U2-05, U2-06): needs.mjs open defaults feature to the subject for parked/given_up, milestone to the subject for verify_*/merge_*/main_conflict/base_conflict/driver_crash (not run/record), else the list's milestone (list= fact); positional run/reason/subject beat key=value
- **Discovery** (affects U2-04, U2-07): harness needs prints one line per item '<glyph> <run> · <headline> · <ref>' (synthesized parked headline '<id> parked: <why>', so 54's 'harness needs parked' check still greps the why); U2-04 replaces it with cards
- **Discovery** (affects U2-05): needs.mjs list applies only 'run removed' in memory; a resolved-but-unswept item still lists until a sweep (lane loop, finish, continue, gc in U2-05)
- **Discovery** (affects U2-04, U2-05, U2-06): needs_fixture <reason> open|resolved [<at epoch>] [<run>] in tests/lib.sh writes $HARNESS_STATE/proj/<run> with markers per plan §2.1
- **Proposed change:** The plan's §6 lists md/fields under U2-03 but its steps don't; U2-05's steps should name needs.md (md) and fields
- *11-U2-03 · claude-opus-5-5*

### 2026-10-28 09:19 · U2-02 · passes

lib/inbox.mjs: one INBOX parser (answersLine outside the steering comment, question, questionLine, added, answers, insert, files, repair + CLI); parked/notify/entries/record.sh on it; inbox_repair after each lane session (slot copy) and the initializer, noted; template comment without ## Answers; STUB_INBOX_IN_COMMENT; 57-inbox (11 checks), n8n-home fixture.

- **Files:** lib/inbox.mjs, lib/parked.mjs, lib/notify.mjs, lib/entries.mjs, lib/record.sh, lib/lane.sh, lib/driver.sh, tests/stub-claude.sh, tests/checks/57-inbox.sh, tests/fixtures/inbox-q-in-comment.md, tests/fixtures/check-names.txt, journal/decisions/2026-10-27-question-locations.md, +3 more
- **Verified:** 57-inbox 11/11; its run check fails with lane.sh's inbox_repair call disabled (8/9 then). 03-harness-parked 4/4. Full suite (TEST_JOBS=2) on the pre-review tree 697/698, the one failure conformance from names added mid-run; full suite on the final tree green: 700 tests in 904 s (check.sh, TEST_JOBS=2). One Opus review (1 Important, 6 Minor), every finding fixed red to green in 57's two review checks.
- **Tests:** 689 → 700
- **Dead end:** repair by the comments' greedy longest common prefix/suffix alone — an edited comment's text was moved as a 'question', a --> inside the question ended the comment early, and a rotated insertion lost its tail (review); now: anchor on the comment's first and last lines, line/word-aligned placement, LCS runs for edits
- **Discovery** (affects U2-03, U2-04, U2-05, U2-08): lib/inbox.mjs has answers/insert/question/repair CLIs and pure question, questionLine (1-based line of the question's first line), files ([{path,line}] from Files: lines) for U2-04/05/08; parked.mjs questionFor and notify.mjs inboxQuestion are aliases of question/added
- **Discovery** (affects U2-05, U2-08): tests/stub-claude.sh STUB_INBOX_IN_COMMENT=<id>: that feature's first session splits the steering comment after 'under ' with '## Questions' + '**Q1 (<id>, stub).** set the gatus vars, then answer' and parks
- **Discovery** (affects U2): added() now ignores HTML comments and reads the repaired text; inbox_repair (lib/record.sh) is a no-op when a session only rewords the comment
- **Proposed change:** U2-02 step 5 says the lane repairs the record's INBOX.md; with lanes the session writes the slot copy, so the repair runs there (before take_question) and on the record's INBOX after the initializer, as the U2-01 plan §4.4/§7.5 says
- **Proposed change:** U2-02 step 3 names tests/checks/56-inbox-pure.sh; 56 is taken, the file is 57-inbox.sh (plan §5.1)
- *10-U2-02 · claude-opus-5-5*

### 2026-10-28 08:40 · U2-01 · passes

Wrote docs/plans/2026-10-28-U2-needs-record.md: the record's 24 keys (13 = event v1, in order) and card keys, file locations, the 15 reasons mapped to their functions with kind/severity/priority/key/sweep rule, a card template per reason, needs.sh/needs.mjs/inbox.mjs APIs, notification texts, check files 57-63, fixtures, touched checks, order U2-02..09. Code unchanged; suite cached green.

- **Files:** docs/plans/2026-10-28-U2-needs-record.md
- **Verified:** Each plan step checked against the code at fc23bf9 (grep of lib/record.sh, lib/lane.sh, lib/driver.sh, bin/harness, tests/checks/13-, 03-, 15-); the n8n fixture read via a scratch clone (31 lines, line 13 '## Answers".', line 28 '## Answers'); merge-tree --name-only output captured from a real scratch conflict; lib/check.sh: green, 689 tests (cached).
- **Tests:** 689 → 689
- **Discovery** (affects U2-02, U2-03, U2-04, U2-05, U2-06, U2-07, U2-08): tests/checks/56- is taken (56-status-review.sh): U2's new check files are 57-inbox, 58-needs-record, 59-needs-cards, 60-needs-driver, 61-needs-git, 62-needs-readers, 63-question-locations
- **Discovery** (affects U2-02): With lanes, a session writes only its slot copy of INBOX.md; take_question_ copies the added lines into the record. So the INBOX repair belongs on the slot copy (against $LS/inbox-before.md) before take_question, plus the record's INBOX after the initializer. answers_hash and take_question_ also cut at /^## Answers/ and must move to inbox.mjs (answers, insert)
- **Discovery** (affects U2-02): The n8n-home fixture can be read without git in that checkout: git clone -q --no-checkout ~/projects/n8n-home <scratch>/n8n-home, then git -C <scratch>/n8n-home show 4632d1c:.harness/runs/n8n-home-2026-10-22/INBOX.md
- **Discovery** (affects U2-04, U2-05): harness parked's text is read by seven 13- checks (parky · proj · B, running:, next commands); making parked an alias in U2-04 before U2-05 opens records needs list to synthesize parked items from parked.json (plan §2.2), and those checks rewritten to the card's words (plan §5.2)
- **Discovery** (affects U2-05, U2-06): Two 13- checks assert today's clicks: the park notification's Click is INBOX.md and verify's is progress.md; the spec's needs.md click changes exactly those two assertions (U2-05, U2-06)
- **Question for Michael:** Should a given-up feature (and a run ending on feature-list edits or a crash) send its own high notification when it happens, not only via the run-end notification? Default: no (plan §7.3).
- **Question for Michael:** Is one main_conflict item per lane (refreshed as main moves, notified once per main commit via a main-conflict-<m> marker) right, rather than one item per main commit? Default: per lane (plan §7.1).
- **Question for Michael:** Should the park notification's tap open needs.md instead of INBOX.md (Edit INBOX stays a button)? Default: needs.md (plan §7.4).
- **Proposed change:** U2-02 step 5: run the repair on the session's copy of INBOX.md (the slot's) before take_question, and on the record's INBOX.md after the initializer, not on the record's INBOX.md after each session (sessions never write it with lanes); and name answers_hash and take_question_ in lib/record.sh as callers of inbox.mjs
- **Proposed change:** U2-03 step 1: needs.mjs may import ./inbox.mjs and ./notify.mjs (pure) as well as ./view.mjs
- **Proposed change:** U2-05 step 1 and U2-06 step 2: 'existing park/verify notification checks pass unchanged' except the one Click assertion each (INBOX.md and progress.md become needs.md)
- **Proposed change:** U2-06 step 1: main_conflict's key subject is the lane milestone, not the origin/main commit; once per main commit comes from a main-conflict-<m> marker (plan §7.1)
- *09-U2-01 · claude-opus-5-5*

### 2026-10-28 08:22 · verify U1 · passes

All 40 steps of U1-01..07 hold. Init suite red (7 checks in 08-scope, 45-lanes) was load flakes: both files pass alone (135/135); 51-56 pass 86/86; 25-run-13b flaked once, passes alone. Docs, fixtures, decision, prompts, syntax checked.

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| U1-01 | 1 | read step, checked files/docs/prompts by grep, node --check, bash -n, ran tests/run.sh 08-scope 45-lanes and 51-..56- and 25-run-13b | artifact present and matches step; covering checks in 51-56 (and rewritten 08/13/14/15/47) pass; suite failures in init were load flakes, green on rerun | yes |
| U1-01 | 2 | read step, checked files/docs/prompts by grep, node --check, bash -n, ran tests/run.sh 08-scope 45-lanes and 51-..56- and 25-run-13b | artifact present and matches step; covering checks in 51-56 (and rewritten 08/13/14/15/47) pass; suite failures in init were load flakes, green on rerun | yes |
| U1-01 | 3 | read step, checked files/docs/prompts by grep, node --check, bash -n, ran tests/run.sh 08-scope 45-lanes and 51-..56- and 25-run-13b | artifact present and matches step; covering checks in 51-56 (and rewritten 08/13/14/15/47) pass; suite failures in init were load flakes, green on rerun | yes |
| U1-01 | 4 | read step, checked files/docs/prompts by grep, node --check, bash -n, ran tests/run.sh 08-scope 45-lanes and 51-..56- and 25-run-13b | artifact present and matches step; covering checks in 51-56 (and rewritten 08/13/14/15/47) pass; suite failures in init were load flakes, green on rerun | yes |
| U1-01 | 5 | read step, checked files/docs/prompts by grep, node --check, bash -n, ran tests/run.sh 08-scope 45-lanes and 51-..56- and 25-run-13b | artifact present and matches step; covering checks in 51-56 (and rewritten 08/13/14/15/47) pass; suite failures in init were load flakes, green on rerun | yes |
| U1-01 | 6 | read step, checked files/docs/prompts by grep, node --check, bash -n, ran tests/run.sh 08-scope 45-lanes and 51-..56- and 25-run-13b | artifact present and matches step; covering checks in 51-56 (and rewritten 08/13/14/15/47) pass; suite failures in init were load flakes, green on rerun | yes |
| U1-02 | 1 | read step, checked files/docs/prompts by grep, node --check, bash -n, ran tests/run.sh 08-scope 45-lanes and 51-..56- and 25-run-13b | artifact present and matches step; covering checks in 51-56 (and rewritten 08/13/14/15/47) pass; suite failures in init were load flakes, green on rerun | yes |
| U1-02 | 2 | read step, checked files/docs/prompts by grep, node --check, bash -n, ran tests/run.sh 08-scope 45-lanes and 51-..56- and 25-run-13b | artifact present and matches step; covering checks in 51-56 (and rewritten 08/13/14/15/47) pass; suite failures in init were load flakes, green on rerun | yes |
| U1-02 | 3 | read step, checked files/docs/prompts by grep, node --check, bash -n, ran tests/run.sh 08-scope 45-lanes and 51-..56- and 25-run-13b | artifact present and matches step; covering checks in 51-56 (and rewritten 08/13/14/15/47) pass; suite failures in init were load flakes, green on rerun | yes |
| U1-02 | 4 | read step, checked files/docs/prompts by grep, node --check, bash -n, ran tests/run.sh 08-scope 45-lanes and 51-..56- and 25-run-13b | artifact present and matches step; covering checks in 51-56 (and rewritten 08/13/14/15/47) pass; suite failures in init were load flakes, green on rerun | yes |
| U1-02 | 5 | read step, checked files/docs/prompts by grep, node --check, bash -n, ran tests/run.sh 08-scope 45-lanes and 51-..56- and 25-run-13b | artifact present and matches step; covering checks in 51-56 (and rewritten 08/13/14/15/47) pass; suite failures in init were load flakes, green on rerun | yes |
| U1-02 | 6 | read step, checked files/docs/prompts by grep, node --check, bash -n, ran tests/run.sh 08-scope 45-lanes and 51-..56- and 25-run-13b | artifact present and matches step; covering checks in 51-56 (and rewritten 08/13/14/15/47) pass; suite failures in init were load flakes, green on rerun | yes |
| U1-02 | 7 | read step, checked files/docs/prompts by grep, node --check, bash -n, ran tests/run.sh 08-scope 45-lanes and 51-..56- and 25-run-13b | artifact present and matches step; covering checks in 51-56 (and rewritten 08/13/14/15/47) pass; suite failures in init were load flakes, green on rerun | yes |
| U1-03 | 1 | read step, checked files/docs/prompts by grep, node --check, bash -n, ran tests/run.sh 08-scope 45-lanes and 51-..56- and 25-run-13b | artifact present and matches step; covering checks in 51-56 (and rewritten 08/13/14/15/47) pass; suite failures in init were load flakes, green on rerun | yes |
| U1-03 | 2 | read step, checked files/docs/prompts by grep, node --check, bash -n, ran tests/run.sh 08-scope 45-lanes and 51-..56- and 25-run-13b | artifact present and matches step; covering checks in 51-56 (and rewritten 08/13/14/15/47) pass; suite failures in init were load flakes, green on rerun | yes |
| U1-03 | 3 | read step, checked files/docs/prompts by grep, node --check, bash -n, ran tests/run.sh 08-scope 45-lanes and 51-..56- and 25-run-13b | artifact present and matches step; covering checks in 51-56 (and rewritten 08/13/14/15/47) pass; suite failures in init were load flakes, green on rerun | yes |
| U1-03 | 4 | read step, checked files/docs/prompts by grep, node --check, bash -n, ran tests/run.sh 08-scope 45-lanes and 51-..56- and 25-run-13b | artifact present and matches step; covering checks in 51-56 (and rewritten 08/13/14/15/47) pass; suite failures in init were load flakes, green on rerun | yes |
| U1-03 | 5 | read step, checked files/docs/prompts by grep, node --check, bash -n, ran tests/run.sh 08-scope 45-lanes and 51-..56- and 25-run-13b | artifact present and matches step; covering checks in 51-56 (and rewritten 08/13/14/15/47) pass; suite failures in init were load flakes, green on rerun | yes |
| U1-03 | 6 | read step, checked files/docs/prompts by grep, node --check, bash -n, ran tests/run.sh 08-scope 45-lanes and 51-..56- and 25-run-13b | artifact present and matches step; covering checks in 51-56 (and rewritten 08/13/14/15/47) pass; suite failures in init were load flakes, green on rerun | yes |
| U1-03 | 7 | read step, checked files/docs/prompts by grep, node --check, bash -n, ran tests/run.sh 08-scope 45-lanes and 51-..56- and 25-run-13b | artifact present and matches step; covering checks in 51-56 (and rewritten 08/13/14/15/47) pass; suite failures in init were load flakes, green on rerun | yes |
| U1-04 | 1 | read step, checked files/docs/prompts by grep, node --check, bash -n, ran tests/run.sh 08-scope 45-lanes and 51-..56- and 25-run-13b | artifact present and matches step; covering checks in 51-56 (and rewritten 08/13/14/15/47) pass; suite failures in init were load flakes, green on rerun | yes |
| U1-04 | 2 | read step, checked files/docs/prompts by grep, node --check, bash -n, ran tests/run.sh 08-scope 45-lanes and 51-..56- and 25-run-13b | artifact present and matches step; covering checks in 51-56 (and rewritten 08/13/14/15/47) pass; suite failures in init were load flakes, green on rerun | yes |
| U1-04 | 3 | read step, checked files/docs/prompts by grep, node --check, bash -n, ran tests/run.sh 08-scope 45-lanes and 51-..56- and 25-run-13b | artifact present and matches step; covering checks in 51-56 (and rewritten 08/13/14/15/47) pass; suite failures in init were load flakes, green on rerun | yes |
| U1-04 | 4 | read step, checked files/docs/prompts by grep, node --check, bash -n, ran tests/run.sh 08-scope 45-lanes and 51-..56- and 25-run-13b | artifact present and matches step; covering checks in 51-56 (and rewritten 08/13/14/15/47) pass; suite failures in init were load flakes, green on rerun | yes |
| U1-04 | 5 | read step, checked files/docs/prompts by grep, node --check, bash -n, ran tests/run.sh 08-scope 45-lanes and 51-..56- and 25-run-13b | artifact present and matches step; covering checks in 51-56 (and rewritten 08/13/14/15/47) pass; suite failures in init were load flakes, green on rerun | yes |
| U1-04 | 6 | read step, checked files/docs/prompts by grep, node --check, bash -n, ran tests/run.sh 08-scope 45-lanes and 51-..56- and 25-run-13b | artifact present and matches step; covering checks in 51-56 (and rewritten 08/13/14/15/47) pass; suite failures in init were load flakes, green on rerun | yes |
| U1-04 | 7 | read step, checked files/docs/prompts by grep, node --check, bash -n, ran tests/run.sh 08-scope 45-lanes and 51-..56- and 25-run-13b | artifact present and matches step; covering checks in 51-56 (and rewritten 08/13/14/15/47) pass; suite failures in init were load flakes, green on rerun | yes |
| U1-05 | 1 | read step, checked files/docs/prompts by grep, node --check, bash -n, ran tests/run.sh 08-scope 45-lanes and 51-..56- and 25-run-13b | artifact present and matches step; covering checks in 51-56 (and rewritten 08/13/14/15/47) pass; suite failures in init were load flakes, green on rerun | yes |
| U1-05 | 2 | read step, checked files/docs/prompts by grep, node --check, bash -n, ran tests/run.sh 08-scope 45-lanes and 51-..56- and 25-run-13b | artifact present and matches step; covering checks in 51-56 (and rewritten 08/13/14/15/47) pass; suite failures in init were load flakes, green on rerun | yes |
| U1-05 | 3 | read step, checked files/docs/prompts by grep, node --check, bash -n, ran tests/run.sh 08-scope 45-lanes and 51-..56- and 25-run-13b | artifact present and matches step; covering checks in 51-56 (and rewritten 08/13/14/15/47) pass; suite failures in init were load flakes, green on rerun | yes |
| U1-05 | 4 | read step, checked files/docs/prompts by grep, node --check, bash -n, ran tests/run.sh 08-scope 45-lanes and 51-..56- and 25-run-13b | artifact present and matches step; covering checks in 51-56 (and rewritten 08/13/14/15/47) pass; suite failures in init were load flakes, green on rerun | yes |
| U1-05 | 5 | read step, checked files/docs/prompts by grep, node --check, bash -n, ran tests/run.sh 08-scope 45-lanes and 51-..56- and 25-run-13b | artifact present and matches step; covering checks in 51-56 (and rewritten 08/13/14/15/47) pass; suite failures in init were load flakes, green on rerun | yes |
| U1-06 | 1 | read step, checked files/docs/prompts by grep, node --check, bash -n, ran tests/run.sh 08-scope 45-lanes and 51-..56- and 25-run-13b | artifact present and matches step; covering checks in 51-56 (and rewritten 08/13/14/15/47) pass; suite failures in init were load flakes, green on rerun | yes |
| U1-06 | 2 | read step, checked files/docs/prompts by grep, node --check, bash -n, ran tests/run.sh 08-scope 45-lanes and 51-..56- and 25-run-13b | artifact present and matches step; covering checks in 51-56 (and rewritten 08/13/14/15/47) pass; suite failures in init were load flakes, green on rerun | yes |
| U1-06 | 3 | read step, checked files/docs/prompts by grep, node --check, bash -n, ran tests/run.sh 08-scope 45-lanes and 51-..56- and 25-run-13b | artifact present and matches step; covering checks in 51-56 (and rewritten 08/13/14/15/47) pass; suite failures in init were load flakes, green on rerun | yes |
| U1-06 | 4 | read step, checked files/docs/prompts by grep, node --check, bash -n, ran tests/run.sh 08-scope 45-lanes and 51-..56- and 25-run-13b | artifact present and matches step; covering checks in 51-56 (and rewritten 08/13/14/15/47) pass; suite failures in init were load flakes, green on rerun | yes |
| U1-07 | 1 | read step, checked files/docs/prompts by grep, node --check, bash -n, ran tests/run.sh 08-scope 45-lanes and 51-..56- and 25-run-13b | artifact present and matches step; covering checks in 51-56 (and rewritten 08/13/14/15/47) pass; suite failures in init were load flakes, green on rerun | yes |
| U1-07 | 2 | read step, checked files/docs/prompts by grep, node --check, bash -n, ran tests/run.sh 08-scope 45-lanes and 51-..56- and 25-run-13b | artifact present and matches step; covering checks in 51-56 (and rewritten 08/13/14/15/47) pass; suite failures in init were load flakes, green on rerun | yes |
| U1-07 | 3 | read step, checked files/docs/prompts by grep, node --check, bash -n, ran tests/run.sh 08-scope 45-lanes and 51-..56- and 25-run-13b | artifact present and matches step; covering checks in 51-56 (and rewritten 08/13/14/15/47) pass; suite failures in init were load flakes, green on rerun | yes |
| U1-07 | 4 | read step, checked files/docs/prompts by grep, node --check, bash -n, ran tests/run.sh 08-scope 45-lanes and 51-..56- and 25-run-13b | artifact present and matches step; covering checks in 51-56 (and rewritten 08/13/14/15/47) pass; suite failures in init were load flakes, green on rerun | yes |

- *081544-verify-U1 · claude-sonnet-5-5*

### 2026-10-28 08:07 · U1-07 · passes

U1 review: 1 Critical, 3 Important, 11 Minor (two Opus rounds, in f8ea1f6). This attempt changed no code: it re-verified all four steps and got a green full suite for the tree. TEST_JOBS=4 runs failed one to four different e2e timing checks each (46, 38, 32, 08), every file green alone.

- **Verified:** steps 1-3 read back (U1-review.diff, docs/plans/2026-10-28-U1-review.md, 9 names from 56-status-review in check-names.txt, README status/queue show/STATUS_SINCE/NO_COLOR, architecture §3/§12, template, decision); bash -n and node --check clean; 46+38 alone 24/24, 08 alone 125/125; full suite through check.sh at TEST_JOBS=2 (HARNESS_CHECK_TIMEOUT=25m): green in 871 s, 689 tests
- **Tests:** 689 → 689
- **Dead end:** rerunning the full suite at TEST_JOBS=4 with other lanes loading the box (~3.6) — four runs, four different e2e flakes (46 pr-held, 38 pack bytes, 32 MAX_PARALLEL_RUNS, 08 no user systemd); none in code U1 changed
- **Discovery** (affects run): At load ~3.6 (other lanes) every TEST_JOBS=4 full run tonight failed 1-4 timing-bound e2e checks, a different file each time; TEST_JOBS=2 with HARNESS_CHECK_TIMEOUT=25m is the way to a green
- **Question for Michael:** The U1 review deferred four Minor findings (continued-run wall hours, MAIN_BRANCH in the card's branch line, lane liveness by cmdline, the --since 3d hint). Should they go in a later milestone's list, or be dropped?
- **Question for Michael:** The full suite flakes under load at TEST_JOBS=4 (a different e2e check each run). Should the harness's check use TEST_JOBS=2 (and a 25m check timeout) while lanes run in parallel?
- **Proposed change:** When lanes share the box, run the suite with fewer jobs (TEST_JOBS=2) or tie TEST_JOBS to the load average, so a milestone's last feature isn't un-passed by a load flake
- *08-U1-07 · claude-opus-5-5*

### 2026-10-28 07:11 · U1-07 · passes

U1 review: 1 Critical, 3 Important, 11 Minor over two Opus rounds. Critical (session counted every metrics row) and all Important fixed red to green in 56-status-review.sh; 7 Minor fixed, 4 deferred; simplifications applied. README, architecture §3/§10/§12, config template and read-views decision complete.

- **Files:** lib/status.mjs, lib/view.mjs, bin/harness, tests/lib.sh, tests/checks/56-status-review.sh, tests/checks/53-status-view.sh, tests/checks/54-status-card.sh, tests/checks/55-queue-view.sh, tests/fixtures/check-names.txt, docs/plans/2026-10-28-U1-review.md, journal/decisions/2026-10-27-read-views.md, docs/architecture.md, +2 more
- **Verified:** 56-status-review.sh: 9 checks, each watched red against the old code (the out-of-range epoch reproduced a RangeError); full suite via lib/check.sh green, 689/689 (TEST_JOBS=2, 874 s); bash -n and node --check on every touched file.
- **Tests:** 680 → 689
- **Dead end:** a live session = the newest session line with no coding row at or after its stamp — the second Opus round: a refused (env) row never closes it, another lane's row hides it, and rows share a second with the next line; log order per id fixed all three
- **Discovery** (affects run): status_stubs' mx now takes [<kind>:]<feature> (init:, verify:, refused:) and writes every row's at MX_AT s before HARNESS_NOW (default 1900); fl and mx stay defined after status_stubs
- **Discovery** (affects U2, run): Deferred from the U1 review (docs/plans/2026-10-28-U1-review.md, Not done): wall hours of a continued run, the card's branch line hardcodes origin/main, lane liveness lacks lane_live's cmdline test, and the footer's --since 3d hint is not conditional on hidden runs
- **Discovery** (affects run): Under load (~3.7, other lanes), full runs flaked once each in 28-run-14d-harness-merge and 48-lanes-rebase (an unknown run/<id>/M2 tag); both pass alone and neither reads status
- **Question for Michael:** The U1 review deferred four Minor findings (continued-run wall hours, MAIN_BRANCH in the card's branch line, lane liveness by cmdline, the --since 3d hint). Should they go in a later milestone's list, or be dropped?
- **Proposed change:** U1-07 step 1 writes the diff under /tmp/harness/<project>/<run>/ while the session's scratch is .../lanes/U1; the step could name the scratch directory instead
- *07-U1-07 · claude-opus-5-5*

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
