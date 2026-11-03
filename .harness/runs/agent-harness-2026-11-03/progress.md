<!-- harness: rendered from entries.jsonl after every session; edits here are overwritten -->
# Progress — run `agent-harness-2026-11-03` (agent-harness)

What this file is: the run's journal, newest entry first, rendered by the harness from `entries.jsonl` for a phone. Spec: `docs/specs/2026-10-31-suite-cpu.md` (brief: Q1 then C1, on the spec's defaults).

The feature list (`feature_list.json`, 8 features): **Q1** (2) makes `harness start` and `harness queue add` refuse a `--spec` path absent from the project's `origin/main` (or `--base`), and the queue runner parks such an entry at dequeue instead of starting it. **C1** (6), after Q1 merges: fewer process starts in the suite (an strace table of one stub start, a per-process memo of `F`'s pure answers keyed on content, one `F poll` node start for the coordinator's end check, then two solo full suites before/after as the proof) and, last, one full run per coding session (the coding prompt's rule and §3 order, `suite_runs`/`suite_full` on the coding row, a `Suite runs` report row), then a review + simplify feature. Each feature's steps are what its verifier re-runs; the last step is always a green suite.

Steer through `INBOX.md` in this directory: set its first line to `status: pause` or `status: stop`, or write answers under `## Answers`. Questions from sessions appear here and in `INBOX.md` with a `Files:` line naming what to open first.

### 2026-11-03 16:58 · C1-06 · passes

C1 review: 0 Critical, 0 Important, 7 Minor (Opus, one round, docs/plans/2026-11-03-C1-review.md). Fixed: f_poll_seed set -u guard (red-first check in 84), laneState→lanes_key comment, retro suite_runs wording. Simplified: end check's poll as a memo fill with the pre-C1 lines, lane loop's unused Fv. architecture.md §3/§11 and README report row updated.

- **Files:** lib/record.sh, lib/driver.sh, lib/lane.sh, lib/features.mjs, prompts/retro.md, tests/checks/84-node-memo.sh, tests/fixtures/check-names.txt, docs/architecture.md, README.md, docs/plans/2026-11-03-C1-review.md, journal/decisions/2026-10-31-fewer-node-starts.md, CLAUDE.md
- **Verified:** Full check.sh: green in 834 s, 1141 tests (first full run red only on 39-memlint-m4: Gotchas at 16 lines; fixed, 39 subset 20/20, then the full call green). Subset 79/84/85: 49/49. New check red without the guard (kp[4]: unbound variable), green with it. bash -n, node --check, lint-sleeps clean; note-line grep empty.
- **Tests:** 1140 → 1141
- **Dead end:** adding the promoted key-map-lint gotcha beside 14 bullets — memlint counts the section's comment line too: 16 over 15; dropped the queue .args line (narrowest) instead
- **Discovery** (affects project): memlint's Gotchas cap counts the section's leading <!-- --> comment line, so the section holds 14 bullets
- **Resolved:** 82-key-map-lint reads a node import string "'"$HH"'/lib/x.mjs" as a read of the repo root (CLAUDE.md): a new check file uses "'$HERE'/../lib/x.mjs" (11's form)
- **Proposed change:** The coding prompt's Gotchas rule says '15 lines at most'; memlint counts the section's comment too, so it is 14 bullets: say so in the prompt or have memlint skip the comment
- *08-C1-06 · claude-opus-5-5*

### 2026-11-03 16:17 · C1-05 · passes

coding.md: one full run, last, after the final edit; TEST_JOBS=2 rule; §3 Gotchas before the suite step (step 1 names it). lane.sh passes suite_runs/suite_full to MET append; metricsRow writes them (null without the log); summary.mjs suiteRuns + Suite runs row after Flakes; retro {{SUITE_RUNS}}. Stub suite calls under set +e. Decision one-full-run. Opus review: 2 Important, fixed.

- **Files:** prompts/coding.md, prompts/retro.md, lib/lane.sh, lib/metrics.mjs, lib/summary.mjs, lib/driver.sh, tests/stub-claude.sh, tests/checks/85-suite-runs.sh, tests/checks/79-suite-length.sh, tests/fixtures/check-names.txt, journal/decisions/2026-10-31-one-full-run.md, CLAUDE.md
- **Verified:** 85 and 79 red first (7 + 2 FAIL), then green; check.sh full: green in 808 s, 1140 tests (/tmp/harness/agent-harness/agent-harness-2026-11-03/lanes/C1/full2.out). The first full run was red only on 82-key-map-lint (85 used "'"$HH"'/lib/…", read as the root); fixed to '$HERE'/../lib/…
- **Tests:** 1129 → 1140
- **Dead end:** a full run before the key-map lint subset — 82-key-map-lint flagged 85's "'"$HH"'/lib" import as a root read: a second full run (the rule's own paid-twice case); run 82 with any new check file first
- **Discovery** (affects run): tests/stub-claude.sh's STUB_RUN_SUITE subset (`test ! -f BROKEN x`) exits 2, which under the stub's set -e ended A's first session before its entry (a limit retry); now under set +e, so 77's sr A session completes
- **Discovery** (affects project): 82-key-map-lint reads a node import string "'"$HH"'/lib/x.mjs" as a read of the repo root (CLAUDE.md): a new check file uses "'$HERE'/../lib/x.mjs" (11's form)
- **Discovery** (affects C1-06): C1-06: the retro prompt carries {{SUITE_RUNS}} (summary.mjs suite-runs; `not counted` fallback in driver.sh retro); docs/architecture.md and README still need the Suite runs row and the two metrics fields
- **Question for Michael:** Default taken: the TEST_JOBS=2 sentence sits in the shared prompts/coding.md (every project's sessions read it), not a project file. Keep it there? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-03/slot-1/prompts/coding.md:24, /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-03/slot-1/journal/decisions/2026-10-31-one-full-run.md
- **Resolved:** CLAUDE.md Gotchas line dropped for the stub set -e line (section at memlint's 15-line cap): git keeps a merge driver's %A as the file whatever its exit: a driver that exits 1 must write the markers itself (git merge-file)
- **Proposed change:** C1-05 step 3: the retro prompt held only summary.json's path, not its content; the session added {{SUITE_RUNS}} to prompts/retro.md so the rendered prompt carries the number
- **Proposed change:** The spec's 'a run with no coding row' case is tested as rows without a count (build() rebuilds coding rows from run.log) plus the pure suiteRuns([])
- *07-C1-05 · claude-opus-5-5*

### 2026-11-03 15:17 · C1-04 · passes

Two solo timed suites. Before (d595498): wall 854.1 s, 3,361.8 CPU-s, 1102/1102. After (5a11f9d): wall 803.8 s, 3,136.1 CPU-s, 1129/1129. Spec target MISSED: CPU -6.7% (needed -20%), wall 803.8 s (bound 650). Rows in the decision file.

- **Files:** journal/decisions/2026-10-31-fewer-node-starts.md
- **Verified:** before.out and after.out in /tmp/harness/agent-harness/agent-harness-2026-11-03/lanes/C1 (time -v lines included); before worktree removed; git diff origin/main --stat shows only C1-02/03 files; check.sh green cached, 1129 tests
- **Tests:** 1129 → 1129
- **Dead end:** the step's literal `time -v TEST_JOBS=4 bash tests/run.sh` — time runs TEST_JOBS=4 as the command (exit 127); use `time -v env TEST_JOBS=4 bash …`
- **Discovery** (affects run): C1 cut CPU only 6.7% and wall 5.9%: sys time (~36% of CPU) barely moved; next levers are metrics.mjs collapse, testcount.mjs, then git/bash forks
- **Proposed change:** C1-04 step 1 should read `/usr/bin/time -v env TEST_JOBS=4 bash tests/run.sh`
- **Proposed change:** The spec's -20% CPU / 650 s target was not reached by C1-02/03; consider a further cut feature (metrics.mjs, testcount.mjs)
- *06-C1-04 · claude-sonnet-5-5*

### 2026-11-03 14:48 · C1-03 · passes

features.mjs poll answers summary/parked/blocked/next/milestone-done in one start and fills F's memo for all five; the end check and the lane loop use it. The idle poll starts node once (needs sweep): unpark_warm, unparks, lanes_v (F lanes on a laneState fingerprint). treekey --partial --names: one start. No builtins. Opus review: 2 minors, fixed.

- **Files:** lib/features.mjs, lib/record.sh, lib/driver.sh, lib/lane.sh, lib/check.sh, lib/treekey.mjs, tests/checks/84-node-memo.sh, tests/checks/81-partial-key.sh, tests/fixtures/check-names.txt, journal/decisions/2026-10-31-fewer-node-starts.md, docs/architecture.md
- **Verified:** Full suite via check.sh: check: green in 788 s, 1129/1129 (scratch full2.out). The 8 new checks were red before the code (84: 6 FAIL, 81: 2 FAIL). The idle-poll check, run 6 times under 4 jobs (run.sh --repeat 6), counted 5 coordinator node starts in 5 polls, all needs.mjs sweep. Subset 45/46/47/48/49/50/13/34/73/80: 177/177. bash -n on the touched shell files and node --check on features.mjs and treekey.mjs are clean; the note-line grep against origin/main prints nothing.
- **Tests:** 1121 → 1129
- **Dead end:** starting the idle window at the first sweep after the barrier's .held — the lane bumps attempts.json just before its session, so the next poll's lanes_v misses once inside the window (flaky); the window now opens a full poll later
- **Dead end:** test path "'"$HH"'/lib/features.mjs" inside a node -e script — 82-key-map-lint reads the quote after $HH as the bare root reading CLAUDE.md; pass it through an env var (FMJS) instead
- **Discovery** (affects C1-06): Lines with note " can't change in C1, so the end check's summaries and the idle poll's `for id in $(record F unpark … $(answers_hash))` line stay as they are: F poll fills the memo for summary (f_poll_seed), and unpark_warm fills answers_hash and an empty unpark in the coordinator's shell first
- **Discovery** (affects C1-06): lanes_v (lib/record.sh) is the coordinator's F lanes, memoized on a fingerprint of laneState's reads (verified-/needs- marks, pid + /proc existence, review-escalate size, meta.env); a pid file that isn't one number is no key. C1-06 should read this key hardest
- **Discovery** (affects C1-04, run): metrics.mjs in the lane (MET usage twice and MET limit 2-3 times per finished session log, third of the top five) is not collapsed: the plan's §4 default is the next lever if C1-04 is short of the -20 % target
- **Discovery** (affects run): CLAUDE.md's Gotchas is at memlint's 15-line cap (39-memlint-m4 goes red at 16): a new line must replace one
- **Proposed change:** C1-03 step 3: the window's poll count is the coordinator's needs.mjs sweep starts (one per idle poll, unconditional) because the driver writes no per-poll line to run.log; a later spec could name that counter directly
- *05-C1-03 · claude-opus-5-5*

### 2026-11-03 13:55 · C1-02 · passes

lib/record.sh's F memoizes features.mjs's pure subcommands in a per-process assoc array keyed on sub + sha1 of each file arg + other args; Fv answers into a var in the current shell; models fills every alias in run_paths; answers_hash memoized on INBOX.md's hash; a throw exits 70. Busiest $(F …) sites moved to Fv. Decision Choice/Rejected written. Opus review: no Critical/Important, minors fixed.

- **Files:** lib/record.sh, lib/features.mjs, lib/lane.sh, lib/driver.sh, tests/checks/84-node-memo.sh, tests/fixtures/check-names.txt, journal/decisions/2026-10-31-fewer-node-starts.md, CLAUDE.md
- **Verified:** tests/checks/84-node-memo.sh 20/20 (a node shim on PATH counts starts: F model twice = 1 start, summary twice = 1, a flip = 1 more, the restored content = 0, unpark that unparked = node each time, a subshell miss not kept, a throw rc 70 not kept); subset 13-run/lanes-rebase/lanes-record/verify 110/110; full check.sh green in 799 s, 1121 tests; git diff origin/main -- lib/*.sh | grep note text: nothing; bash -n, node --check clean.
- **Tests:** 1102 → 1121
- **Dead end:** a Gotchas line appended as a 15th item — memlint counts the section's comment line: 39-memlint-m4 went red at 16; replaced the check.sh partial-map line in place instead
- **Discovery** (affects C1-03): F_MEMO_PID: a miss in a subshell runs node straight and keeps nothing, so a $(F …) site gains only when its parent shell already holds the key; the coordinator's idle-poll calls ($(record F unpark … "$(answers_hash)"), rebase_due in < <(…)) still start node each poll until C1-03 moves them into the current shell (Fv, a var for answers_hash)
- **Discovery** (affects C1-03, C1-06): features.mjs now exits 70 on a throw (was node's 1): 1 is an answer the memo keeps for passes/milestone-done/evidence/lint; a new subcommand whose 1 is an answer goes in f_memo's case list
- **Discovery** (affects C1-03, C1-04): lines with note " can't change in C1 (the step grep), so $(F summary …) inside note lines (lane.sh 387, driver.sh 498/571/581) stay subshell calls: they hit only when the shell already holds that list's summary
- **Proposed change:** C1-06's review brief could add: the F_MEMO_PID rule (a subshell never stores) and features.mjs's exit 70 on a throw
- *04-C1-02 · claude-opus-5-5*

### 2026-11-03 13:05 · C1-01 · passes

Exec table: one stub harness start of file 13 under strace (402 node starts = 10.8 of 20.4 CPU-s) plus the whole file (3,139 node; lanes 1,945, driver 975, stub 48, checks 9; node 49% of 170.6 CPU-s) in the fewer-node-starts decision; plan names the memo, the subshell constraint, the poll collapse, no builtins. No code change.

- **Files:** journal/decisions/2026-10-31-fewer-node-starts.md, docs/plans/2026-11-03-C1-suite-cpu.md, findings-and-research/2026-11-03-exec-table/
- **Verified:** KEEP=1 tests/run.sh 13 (66/66, kept /tmp/tmp.udNNEx7iBD); by-hand start under strace+time -v: /tmp/harness/agent-harness/agent-harness-2026-11-03/lanes/C1/execs.strace, /tmp/harness/agent-harness/agent-harness-2026-11-03/lanes/C1/stubstart.out, /tmp/harness/agent-harness/agent-harness-2026-11-03/lanes/C1/stubstart.time; plain: /tmp/harness/agent-harness/agent-harness-2026-11-03/lanes/C1/stubstart-plain.time (19.0 s, 12.93+7.51); whole file: /tmp/harness/agent-harness/agent-harness-2026-11-03/lanes/C1/file13.strace, /tmp/harness/agent-harness/agent-harness-2026-11-03/lanes/C1/file13-plain.time (185 s, 170.6 CPU-s); git diff origin/main --stat -- bin lib tests prompts empty; check.sh green (cached, 1102 tests)
- **Tests:** 1102 → 1102
- **Dead end:** ${ cmd; } (current-shell command substitution) for a memo filled inside $( ) — bash 5.2.21 on this box: bad substitution (5.3 only)
- **Discovery** (affects C1-02, C1-03): bash 5.2: an F memo entry written inside $(F …), < <(…) or a pipe dies with the subshell; most answer-reading F sites are $( ). The plan's default: F model fills every alias at once (a models subcommand), Fv <var> <sub> … runs F in the current shell
- **Discovery** (affects C1-03): An idle coordinator poll with a free slot starts node 5 times: F unpark, inbox answers, needs.mjs sweep, F milestones (rebase_due), F lanes. needs sweep is not memoizable, so C1-03's at-most-one bound needs F lanes memoized on the state inputs laneState reads (plan §4)
- **Discovery** (affects C1-03, C1-04): treekey.mjs --names ran 0 times in file 13: the check.sh treekey merge saves nothing there; date/cat are not in the top five, so no builtin change
- **Discovery** (affects C1-04): Plan §6 predicts 11-16% of file 13's CPU from C1-02+C1-03, under the spec's -20%: C1-04 may record a miss
- **Proposed change:** C1-03 step 2/3: name the F lanes memo keyed on the list/attempts/parked hashes plus a bash fingerprint of laneState's inputs (verified-/needs- marks, lane pids alive, review-escalate, meta.env RUN_ID); without it the idle poll's floor is 2 node starts (needs.mjs sweep + F lanes) and step 3's bound can't hold
- **Proposed change:** C1-03: add metrics.mjs (third of the top five, 314 per file): MET limit memoized on the session log's hash + wall + exit, the two MET usage calls in one start
- *03-C1-01 · claude-opus-5-5*

### 2026-11-03 12:48 · verify Q1 · passes

Q1-01 and Q1-02 hold: suite green (init full run, 843 s, 1102 tests), 83-spec-must-exist 18/18 re-run, bash -n clean, check names sorted, docs and decision present.

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| Q1-01 | 1 | read lib/spec.sh spec_missing; bash tests/run.sh 83-spec | fetch, cat-file -e per path, prints 'spec <p>: not in <ref> (fetched now); commit and push it, or name its ref with --base'; checks 1-4 PASS | yes |
| Q1-01 | 2 | read bin/harness:284 (spec_refuse before first queue_add) and :541 (queue add); checks resume/--brief PASS | check precedes queue_add; resume and --brief-only skip; queue add checked | yes |
| Q1-01 | 3 | bash tests/run.sh 83-spec | PASS missing/unpushed/pushed/'a b' checks (no worktree, state dir, .args) | yes |
| Q1-01 | 4 | bash tests/run.sh 83-spec | PASS --base, SPEC_FILES, --brief alone, resume, queue add missing/present | yes |
| Q1-01 | 5 | grep journal/decisions/2026-10-31-spec-must-exist.md | default marked, rejected alternatives, runner part added in place (Updated in place line) | yes |
| Q1-01 | 6 | bash -n bin/harness lib/queue.sh lib/spec.sh; git diff origin/main 1a22f2d -- lib/queue.sh \| wc -l | bash -n silent; queue.sh diff empty (0) at the Q1-01 commit; later changes are Q1-02's | yes |
| Q1-01 | 7 | check.sh init output | green in 843 s, 1102 tests | yes |
| Q1-02 | 1 | read lib/queue.sh:84 and lib/spec.sh spec_entry | spec_entry after chosen entry, before mv; park to held/ with .why, runner.log line, loop continues | yes |
| Q1-02 | 2 | bash tests/run.sh 83-spec | PASS runner parks, goes on to next entry, planted .args parked, queue list shows reason; 18/18 | yes |
| Q1-02 | 3 | grep README.md, docs/architecture.md, decision | README rows 56-57, arch §3 rows, §7 guard row 365, §12 text, decision updated in place | yes |
| Q1-02 | 4 | read entries.jsonl verified_how | Opus review of Q1.diff: 0 Critical/Important, minors fixed RED to GREEN with checks | yes |
| Q1-02 | 5 | bash -n bin/harness lib/queue.sh lib/spec.sh tests/checks/83-spec-must-exist.sh | no output | yes |
| Q1-02 | 6 | check.sh init output | green in 843 s, 1102 tests | yes |

- *124716-verify-Q1 · claude-sonnet-5-5*

### 2026-11-03 12:33 · Q1-02 · passes

The queue runner re-checks a start entry's spec at dequeue (lib/spec.sh spec_entry, after the limit/weekly gates, before sync and the mv to done/) and parks a miss in queue/held/ with the line as .why, a parked line in runner.log, then starts the next entry. README, architecture §3/§7/§12 and the decision updated; Opus review: no Critical/Important, 4 minors fixed.

- **Files:** lib/spec.sh, lib/queue.sh, bin/harness, tests/checks/83-spec-must-exist.sh, tests/fixtures/check-names.txt, README.md, docs/architecture.md, journal/decisions/2026-10-31-spec-must-exist.md
- **Verified:** TDD: 4 runner checks red then green (83: 14/14 → 18/18 → 19/19); queue files 32, 15, 55 green; full suite green: check.sh 1102 tests in 857 s. Opus review of $HARNESS_SCRATCH/Q1.diff: check order in cmd_start, resume and --brief skips, park loop all hold; 0 Critical, 0 Important. Minors fixed RED→GREEN: taken held/ name parked under another name, non-repo project not parked, empty reason replaced, absolute --spec inside the project.
- **Tests:** 1094 → 1102
- **Dead end:** checking $T/wt/proj/<run> after a lib/queue.sh run — the runner's exit gc --all-merged removes merged worktrees; the check reads $HARNESS_STATE/proj/<run> instead
- **Dead end:** a Gotchas line edited in CLAUDE.md while a full check.sh ran — the section was already at 15 (memlint red), and check.sh had taken the tree key at its start, so it cached red-<key> for the clean tree; a real code change (review minor 5) gave a new key
- **Discovery** (affects run): lib/spec.sh now has spec_args (a start's run id/--spec/--base), spec_new_run (resume and --brief skips) and spec_entry (a .args file, project config in a subshell); bin/harness spec_refuse and queue add use them
- **Discovery** (affects run): editing the worktree while a full check.sh runs can cache red-<key> for the pre-edit tree: never edit during a full run
- **Question for Michael:** Default taken: an absolute --spec outside the project is checked as given and so refused (the run reads its worktree). Should one outside the project be allowed unchecked instead? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-03/slot-0/journal/decisions/2026-10-31-spec-must-exist.md, /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-03/slot-0/lib/spec.sh:29
- **Proposed change:** Review minors left open (not in Q1's scope): the runner's fetch has no timeout (ssh prompt or stalled network hangs the runner; cmd_start and lib/sync.sh have the same); `harness continue` of a run whose worktree gc removed is checked against SPEC_FILES (resume = worktree exists only); cmd_start makes the worktree from origin/main while the check reads origin/$MAIN_BRANCH
- **Proposed change:** The session prompt could say: never edit the worktree while a full check.sh runs (the key is taken at its start)
- *02-Q1-02 · claude-opus-5-5*

### 2026-11-03 11:15 · Q1-01 · passes

harness start and queue add now refuse a --spec (or SPEC_FILES) path absent from origin/$MAIN_BRANCH (or --base) before anything is queued or started: lib/spec.sh spec_missing, bin/harness spec_refuse (before cmd_start's first queue_add; in queue add via a config subshell). A resume, --brief alone and add --continue skip it.

- **Files:** lib/spec.sh, bin/harness, tests/checks/83-spec-must-exist.sh, tests/fixtures/check-names.txt, journal/decisions/2026-10-31-spec-must-exist.md
- **Verified:** 83-spec-must-exist.sh: 4/10 before the code (only the proceed cases), 10/10 after; bash -n on bin/harness lib/queue.sh lib/spec.sh; git diff origin/main -- lib/queue.sh empty; LC_ALL=C sort -c check-names.txt clean; full suite (lib/check.sh) green in 839 s, 1094 tests (1084 → 1094)
- **Tests:** 1084 → 1094
- **Discovery** (affects Q1-02): spec_refuse in bin/harness takes (project dir, run id, --spec, --base) with the project's config loaded; Q1-02's runner can call spec_missing directly after sourcing lib/spec.sh (not sourced by lib/queue.sh yet)
- **Discovery** (affects run): a stub check that starts a new run with --spec <file> now needs the file pushed to the stub's origin/main (SPEC.md is, from suite_setup)
- **Proposed change:** README.md's start/queue rows and docs/architecture.md §3/§7/§12 are left for Q1-02's step 3, which names them for the whole milestone
- *01-Q1-01 · claude-opus-5-5*

### 2026-11-03 10:57 · init · passes

8 features: Q1 2 (the spec check in start and queue add; the runner's park at dequeue, docs and folded review), C1 6 (C1-01 strace exec table and plan; C1-02 F memo keyed on content; C1-03 F poll, treekey merge, builtins; C1-04 before/after solo suites; C1-05 one full run per session and the Suite runs row; C1-06 review + simplify). Q1 then C1, in series.

- **Discovery** (affects run): C1-04's two timed suites (about 15 min each on this box) run outside the suite command, in the session, in the background with a timeout: the full run per session comes on top, so that feature needs a session well over 40 min
- **Discovery** (affects run): An idle coordinator poll with one lane open and MAX_LANES=1 (the default) makes no F call at all; C1-03's idle-poll check needs MAX_LANES=2 in the stub project's .harness/config.sh so a free slot exists and F unpark, F lanes and answers_hash (inbox.mjs) run each poll
- **Discovery** (affects run): F unpark mutates the parked file when it unparks: C1-02 may serve a memoized unpark answer only when the stored answer was empty (no mutation); F lanes reads the state dir (verified-/needs- marks), so it is not memoizable on the list alone
- **Proposed change:** Q1 is two build features, not the spec's one: the CLI refusals (Q1-01) and the runner's dequeue park with docs (Q1-02) are each a 30–60 min session with its own checks; the review stays folded (two builds), so the milestone's shape is what decisions/2026-10-26-reviews-sized-to-milestone asks.
- *00-init · claude-fable-5-1*
