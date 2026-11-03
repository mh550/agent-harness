<!-- harness: rendered from entries.jsonl after every session; edits here are overwritten -->
# Progress — run `agent-harness-2026-11-03` (agent-harness)

What this file is: the run's journal, newest entry first, rendered by the harness from `entries.jsonl` for a phone. Spec: `docs/specs/2026-10-31-suite-cpu.md` (brief: Q1 then C1, on the spec's defaults).

The feature list (`feature_list.json`, 8 features): **Q1** (2) makes `harness start` and `harness queue add` refuse a `--spec` path absent from the project's `origin/main` (or `--base`), and the queue runner parks such an entry at dequeue instead of starting it. **C1** (6), after Q1 merges: fewer process starts in the suite (an strace table of one stub start, a per-process memo of `F`'s pure answers keyed on content, one `F poll` node start for the coordinator's end check, then two solo full suites before/after as the proof) and, last, one full run per coding session (the coding prompt's rule and §3 order, `suite_runs`/`suite_full` on the coding row, a `Suite runs` report row), then a review + simplify feature. Each feature's steps are what its verifier re-runs; the last step is always a green suite.

Steer through `INBOX.md` in this directory: set its first line to `status: pause` or `status: stop`, or write answers under `## Answers`. Questions from sessions appear here and in `INBOX.md` with a `Files:` line naming what to open first.

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
