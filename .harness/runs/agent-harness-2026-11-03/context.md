# Context pack for `C1`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## This feature's earlier attempts

- Dead end (C1-06, 08-C1-06): adding the promoted key-map-lint gotcha beside 14 bullets — memlint counts the section's comment line too: 16 over 15; dropped the queue .args line (narrowest) instead → entries.jsonl:10
- Dead end (C1-05, 07-C1-05): a full run before the key-map lint subset — 82-key-map-lint flagged 85's "'"$HH"'/lib" import as a root read: a second full run (the rule's own paid-twice case); run 82 with any new check file first → entries.jsonl:9
- Dead end (C1-04, 06-C1-04): the step's literal `time -v TEST_JOBS=4 bash tests/run.sh` — time runs TEST_JOBS=4 as the command (exit 127); use `time -v env TEST_JOBS=4 bash …` → entries.jsonl:8
- Dead end (C1-03, 05-C1-03): starting the idle window at the first sweep after the barrier's .held — the lane bumps attempts.json just before its session, so the next poll's lanes_v misses once inside the window (flaky); the window now opens a full poll later → entries.jsonl:7
- Dead end (C1-03, 05-C1-03): test path "'"$HH"'/lib/features.mjs" inside a node -e script — 82-key-map-lint reads the quote after $HH as the bare root reading CLAUDE.md; pass it through an env var (FMJS) instead → entries.jsonl:7
- Dead end (C1-02, 04-C1-02): a Gotchas line appended as a 15th item — memlint counts the section's comment line: 39-memlint-m4 went red at 16; replaced the check.sh partial-map line in place instead → entries.jsonl:6
- Dead end (C1-01, 03-C1-01): ${ cmd; } (current-shell command substitution) for a memo filled inside $( ) — bash 5.2.21 on this box: bad substitution (5.3 only) → entries.jsonl:5
- Question (C1-05): Default taken: the TEST_JOBS=2 sentence sits in the shared prompts/coding.md (every project's sessions read it), not a project file. Keep it there? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-03/slot-1/prompts/coding.md:24, /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-03/slot-1/journal/decisions/2026-10-31-one-full-run.md → entries.jsonl:9
- 2026-11-03 16:58 · C1-06 · passes: C1 review: 0 Critical, 0 Important, 7 Minor (Opus, one round, docs/plans/2026-11-03-C1-review.md). Fixed: f_poll_seed set -u guard (red-first check in 84), laneState→lanes_key comment, retro suite_runs wording. Simplified: end check's poll as a memo fill with the pre-C1 lines, lane loop's unused Fv. architecture.md §3/§11 and README report row updated.; tests 1140 → 1141; files lib/record.sh, lib/driver.sh, lib/lane.sh, lib/features.mjs, prompts/retro.md, … → entries.jsonl:10
- 2026-11-03 16:17 · C1-05 · passes: coding.md: one full run, last, after the final edit; TEST_JOBS=2 rule; §3 Gotchas before the suite step (step 1 names it). lane.sh passes suite_runs/suite_full to MET append; metricsRow writes them (null without the log); summary.mjs suiteRuns + Suite runs row after Flakes; retro {{SUITE_RUNS}}. Stub suite calls under set +e. Decision one-full-run. Opus review: 2 Important, fixed.; tests 1129 → 1140; files prompts/coding.md, prompts/retro.md, lib/lane.sh, lib/metrics.mjs, lib/summary.mjs, … → entries.jsonl:9
- 2026-11-03 15:17 · C1-04 · passes: Two solo timed suites. Before (d595498): wall 854.1 s, 3,361.8 CPU-s, 1102/1102. After (5a11f9d): wall 803.8 s, 3,136.1 CPU-s, 1129/1129. Spec target MISSED: CPU -6.7% (needed -20%), wall 803.8 s (bound 650). Rows in the decision file.; tests 1129 → 1129; files journal/decisions/2026-10-31-fewer-node-starts.md → entries.jsonl:8
- 2026-11-03 14:48 · C1-03 · passes: features.mjs poll answers summary/parked/blocked/next/milestone-done in one start and fills F's memo for all five; the end check and the lane loop use it. The idle poll starts node once (needs sweep): unpark_warm, unparks, lanes_v (F lanes on a laneState fingerprint). treekey --partial --names: one start. No builtins. Opus review: 2 minors, fixed.; tests 1121 → 1129; files lib/features.mjs, lib/record.sh, lib/driver.sh, lib/lane.sh, lib/check.sh, … → entries.jsonl:7
- 2026-11-03 13:55 · C1-02 · passes: lib/record.sh's F memoizes features.mjs's pure subcommands in a per-process assoc array keyed on sub + sha1 of each file arg + other args; Fv answers into a var in the current shell; models fills every alias in run_paths; answers_hash memoized on INBOX.md's hash; a throw exits 70. Busiest $(F …) sites moved to Fv. Decision Choice/Rejected written. Opus review: no Critical/Important, minors fixed.; tests 1102 → 1121; files lib/record.sh, lib/features.mjs, lib/lane.sh, lib/driver.sh, tests/checks/84-node-memo.sh, … → entries.jsonl:6
- 2026-11-03 13:05 · C1-01 · passes: Exec table: one stub harness start of file 13 under strace (402 node starts = 10.8 of 20.4 CPU-s) plus the whole file (3,139 node; lanes 1,945, driver 975, stub 48, checks 9; node 49% of 170.6 CPU-s) in the fewer-node-starts decision; plan names the memo, the subshell constraint, the poll collapse, no builtins. No code change.; tests 1102 → 1102; files journal/decisions/2026-10-31-fewer-node-starts.md, docs/plans/2026-11-03-C1-suite-cpu.md, findings-and-research/2026-11-03-exec-table/ → entries.jsonl:5

## Discoveries for this feature

- Discovery (C1-05, affects run): tests/stub-claude.sh's STUB_RUN_SUITE subset (`test ! -f BROKEN x`) exits 2, which under the stub's set -e ended A's first session before its entry (a limit retry); now under set +e, so 77's sr A session completes → entries.jsonl:9
- Discovery (C1-05, affects C1-06): C1-06: the retro prompt carries {{SUITE_RUNS}} (summary.mjs suite-runs; `not counted` fallback in driver.sh retro); docs/architecture.md and README still need the Suite runs row and the two metrics fields → entries.jsonl:9
- Discovery (C1-04, affects run): C1 cut CPU only 6.7% and wall 5.9%: sys time (~36% of CPU) barely moved; next levers are metrics.mjs collapse, testcount.mjs, then git/bash forks → entries.jsonl:8
- Discovery (C1-03, affects C1-06): Lines with note " can't change in C1, so the end check's summaries and the idle poll's `for id in $(record F unpark … $(answers_hash))` line stay as they are: F poll fills the memo for summary (f_poll_seed), and unpark_warm fills answers_hash and an empty unpark in the coordinator's shell first → entries.jsonl:7
- Discovery (C1-03, affects C1-06): lanes_v (lib/record.sh) is the coordinator's F lanes, memoized on a fingerprint of laneState's reads (verified-/needs- marks, pid + /proc existence, review-escalate size, meta.env); a pid file that isn't one number is no key. C1-06 should read this key hardest → entries.jsonl:7
- Discovery (C1-03, affects C1-04, run): metrics.mjs in the lane (MET usage twice and MET limit 2-3 times per finished session log, third of the top five) is not collapsed: the plan's §4 default is the next lever if C1-04 is short of the -20 % target → entries.jsonl:7
- Discovery (C1-03, affects run): CLAUDE.md's Gotchas is at memlint's 15-line cap (39-memlint-m4 goes red at 16): a new line must replace one → entries.jsonl:7
- Discovery (C1-02, affects C1-03): F_MEMO_PID: a miss in a subshell runs node straight and keeps nothing, so a $(F …) site gains only when its parent shell already holds the key; the coordinator's idle-poll calls ($(record F unpark … "$(answers_hash)"), rebase_due in < <(…)) still start node each poll until C1-03 moves them into the current shell (Fv, a var for answers_hash) → entries.jsonl:6
- Discovery (C1-02, affects C1-03, C1-06): features.mjs now exits 70 on a throw (was node's 1): 1 is an answer the memo keeps for passes/milestone-done/evidence/lint; a new subcommand whose 1 is an answer goes in f_memo's case list → entries.jsonl:6
- Discovery (C1-02, affects C1-03, C1-04): lines with note " can't change in C1 (the step grep), so $(F summary …) inside note lines (lane.sh 387, driver.sh 498/571/581) stay subshell calls: they hit only when the shell already holds that list's summary → entries.jsonl:6
- Discovery (C1-01, affects C1-02, C1-03): bash 5.2: an F memo entry written inside $(F …), < <(…) or a pipe dies with the subshell; most answer-reading F sites are $( ). The plan's default: F model fills every alias at once (a models subcommand), Fv <var> <sub> … runs F in the current shell → entries.jsonl:5
- Discovery (C1-01, affects C1-03): An idle coordinator poll with a free slot starts node 5 times: F unpark, inbox answers, needs.mjs sweep, F milestones (rebase_due), F lanes. needs sweep is not memoizable, so C1-03's at-most-one bound needs F lanes memoized on the state inputs laneState reads (plan §4) → entries.jsonl:5
- Discovery (C1-01, affects C1-03, C1-04): treekey.mjs --names ran 0 times in file 13: the check.sh treekey merge saves nothing there; date/cat are not in the top five, so no builtin change → entries.jsonl:5
- Discovery (C1-01, affects C1-04): Plan §6 predicts 11-16% of file 13's CPU from C1-02+C1-03, under the spec's -20%: C1-04 may record a miss → entries.jsonl:5
- Discovery (Q1-02, affects run): lib/spec.sh now has spec_args (a start's run id/--spec/--base), spec_new_run (resume and --brief skips) and spec_entry (a .args file, project config in a subshell); bin/harness spec_refuse and queue add use them → entries.jsonl:3
- Discovery (Q1-02, affects run): editing the worktree while a full check.sh runs can cache red-<key> for the pre-edit tree: never edit during a full run → entries.jsonl:3
- Discovery (Q1-01, affects run): a stub check that starts a new run with --spec <file> now needs the file pushed to the stub's origin/main (SPEC.md is, from suite_setup) → entries.jsonl:2
- Discovery (init, affects run): C1-04's two timed suites (about 15 min each on this box) run outside the suite command, in the session, in the background with a timeout: the full run per session comes on top, so that feature needs a session well over 40 min → entries.jsonl:1
- Discovery (init, affects run): An idle coordinator poll with one lane open and MAX_LANES=1 (the default) makes no F call at all; C1-03's idle-poll check needs MAX_LANES=2 in the stub project's .harness/config.sh so a free slot exists and F unpark, F lanes and answers_hash (inbox.mjs) run each poll → entries.jsonl:1
- Discovery (init, affects run): F unpark mutates the parked file when it unparks: C1-02 may serve a memoized unpark answer only when the stored answer was empty (no mutation); F lanes reads the state dir (verified-/needs- marks), so it is not memoizable on the list alone → entries.jsonl:1

## Current rules

- A run never starts on a spec that isn't there: `harness start` and `queue add` refuse a spec absent from the run's base ref → journal/decisions/2026-10-31-spec-must-exist.md
- One full run per coding session, last: the prompt's rule and §3 order, and `Suite runs` in the report → journal/decisions/2026-10-31-one-full-run.md
- Fewer node starts: where a stub run's process starts come from, and the cuts C1 makes → journal/decisions/2026-10-31-fewer-node-starts.md
- The suite's length in every prompt: a green marker's `wall` line, and a timeout rule → journal/decisions/2026-10-30-suite-length-in-prompt.md
- A red tree is cached: `red-<key>`, so the next full call on the tree just found red runs nothing → journal/decisions/2026-10-30-red-marker.md
- A mapped path's change runs only its readers: `CHECK_KEY_MAP`, the `part-<key>` sidecar, the partial run, the lint → journal/decisions/2026-10-30-partial-key.md
- The coordinator opens no lane while a lane that exited is not reaped yet → journal/decisions/2026-10-30-opens-wait-for-reap.md
- The lane guard reverts against the lane's merge-base with main, in the index only → journal/decisions/2026-10-30-lane-guard-base.md
- Timing checks bound CPU time; a stopped file's missing names don't void `HARNESS_FAILED=` → journal/decisions/2026-10-30-cpu-time-bound-and-stopped-files.md
- The suite waits on a condition or a barrier, never on the clock; a flake is reproduced with --repeat and fixed at its cause → journal/decisions/2026-10-29-tests-wait-not-sleep.md
- The rerun guard: a red full suite is rerun once; a flake is green, named and counted, never quarantined → journal/decisions/2026-10-29-rerun-guard.md
- Questions wait in `harness needs` until answered: one item per question, moved forward, no push → journal/decisions/2026-10-29-questions-wait.md
- Lanes leftovers: atomic list writes, a record-only main, the finish order, two lint rules, two checks, the suite-ran note → journal/decisions/2026-10-29-lanes-leftovers.md
- The coordinator ends a run only when the lane count its opens used saw no lane → journal/decisions/2026-10-29-lane-count-end-check.md
- Entries that survive: the session checks its own, a long summary is cut and kept, one resume for a missing one → journal/decisions/2026-10-29-entries-survive.md
- A parked run's continue advice names another live run of its project and gives Michael the choice → journal/decisions/2026-10-29-continue-advice-busy-project.md
- Merge conflicts resolved without Michael: a sorted merge for lists first, then a resolve session, verified → journal/decisions/2026-10-29-conflict-resolution.md
- This repo's suite gets a 25-minute check timeout; TEST_JOBS stays at its default → journal/decisions/2026-10-29-check-timeout-25m.md
- `harness show`: where a run's work is, from local refs, one change counted once → journal/decisions/2026-10-28-show.md
- A plain start or continue queues behind a live run of its project; overlaps are named, never held → journal/decisions/2026-10-27-same-project-starts.md
- The review gate: a milestone review's model by its measured diff, one Opus round after a Sonnet finding → journal/decisions/2026-10-27-review-gate.md
- A finished run keeps its record after gc: report reads worktree → state → ledger → journal/decisions/2026-10-27-record-after-gc.md
- Read views: one formatter, `lib/view.mjs`, that every read view renders through → journal/decisions/2026-10-27-read-views.md
- Questions where Michael sees them: one INBOX parser, the steering comment repaired → journal/decisions/2026-10-27-question-locations.md
- Project names: one resolver takes a path or a bare name → journal/decisions/2026-10-27-project-names.md
- Merging the memory run into lanes: main's driver changes in their lane-era homes, the review round per lane → journal/decisions/2026-10-27-p1-main-merge.md
- What waits on Michael: one needs record per item, swept by its reason's rule → journal/decisions/2026-10-27-needs-record.md

_57 older rules: journal/decisions._
