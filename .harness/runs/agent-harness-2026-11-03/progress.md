<!-- harness: rendered from entries.jsonl after every session; edits here are overwritten -->
# Progress — run `agent-harness-2026-11-03` (agent-harness)

What this file is: the run's journal, newest entry first, rendered by the harness from `entries.jsonl` for a phone. Spec: `docs/specs/2026-10-31-suite-cpu.md` (brief: Q1 then C1, on the spec's defaults).

The feature list (`feature_list.json`, 8 features): **Q1** (2) makes `harness start` and `harness queue add` refuse a `--spec` path absent from the project's `origin/main` (or `--base`), and the queue runner parks such an entry at dequeue instead of starting it. **C1** (6), after Q1 merges: fewer process starts in the suite (an strace table of one stub start, a per-process memo of `F`'s pure answers keyed on content, one `F poll` node start for the coordinator's end check, then two solo full suites before/after as the proof) and, last, one full run per coding session (the coding prompt's rule and §3 order, `suite_runs`/`suite_full` on the coding row, a `Suite runs` report row), then a review + simplify feature. Each feature's steps are what its verifier re-runs; the last step is always a green suite.

Steer through `INBOX.md` in this directory: set its first line to `status: pause` or `status: stop`, or write answers under `## Answers`. Questions from sessions appear here and in `INBOX.md` with a `Files:` line naming what to open first.

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
