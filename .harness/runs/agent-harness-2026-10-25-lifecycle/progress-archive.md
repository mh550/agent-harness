<!-- harness: rendered from entries.jsonl after every session; edits here are overwritten -->
# Progress — run `agent-harness-2026-10-25-lifecycle` (agent-harness)

What this file is: the run's journal, rendered from `entries.jsonl` after every session, newest entry first (the full record is `progress-archive.md`; the driver's own notes are `harness-log.md`). Each entry says what one session did, what passed, what it found (discoveries) and what it needs from you (questions).

The spec is `docs/specs/2026-10-25-resource-lifecycle.md`: everything a run starts is capped by a systemd user scope and stopped when the run stops. Milestones: L1 capped sessions and suites · L2 run services, teardown hook, stop points · L3 scratch and tmux cleanup · L4 `harness gc` fixes (`--all-merged`, R9, `--deps`, the runner's gc) · L5 `MAX_PARALLEL_RUNS` reload (optional, last). L2 waits for L1; L3, L4 and L5 are independent, so a stuck feature in one never blocks the others. Each verified milestone merges into `main` by itself.

How to read the feature list: `feature_list.json` lists features in priority order; `passes` is the session's claim, the verify entry for a milestone is what counts. Steps are the checks a verifier re-runs. A build feature writes its decision file under `journal/decisions/`, its checks in `tests/run.sh` first, and its `docs/architecture.md` and `README.md` lines.

To steer: edit `INBOX.md` on this branch (GitHub app). Line 1 `status: pause` or `status: stop` takes effect before the next session; answers go under `## Answers`. Sessions never park on this run (the brief): they take the spec's default and record it in the decision file, so the questions below are for after the run.

### 2026-10-26 02:08 · verify L4 · passes

All five L4 features hold: check.sh green (322 checks, 0 FAIL), bash -n clean, named checks read and match each step, docs/decisions/plan present.

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| L4-01 | 1 | ls docs/plans; wc -l | L4-gc.md, 65 lines | yes |
| L4-01 | 2 | grep for-each-ref bin/harness | per-prefix refs/heads/ and refs/remotes/origin/ loop, no * pattern, lstrip | yes |
| L4-01 | 3 | read tests/run.sh:803 check | spec/x docs/y harness/z harness-merge/w flat deleted both places; spec/u survives | yes |
| L4-01 | 4 | read tests/run.sh:795 check | plain gc deletes only harness/z, harness-merge/w; others survive | yes |
| L4-01 | 5 | ls journal/decisions; grep | gc-all-merged.md has finding/choice/rejected | yes |
| L4-01 | 6 | bash -n bin/harness; check.sh | syntax ok; suite green, 0 FAIL | yes |
| L4-02 | 1 | read bin/harness gc loop via architecture §3 and tests | remove --force, prune, rm -rf only when unlisted; ! could not remove line | yes |
| L4-02 | 2 | read tests/run.sh:817 | gcw-a (.next) and gcw-b removed with + lines | yes |
| L4-02 | 3 | read tests/run.sh:821 check | read-only parent prints ! could not remove, gcw-d still removed, dry-run 4 would lines | yes |
| L4-02 | 4 | ls decisions | gc-removal-finishes.md present | yes |
| L4-02 | 5 | check.sh | green | yes |
| L4-03 | 1 | grep DEPS_DIRS lib/config.sh templates | default set, template commented; --deps in gc | yes |
| L4-03 | 2 | read tests/run.sh:864,868 | ended run emptied, live/checkout kept, dry-run would: freed | yes |
| L4-03 | 3 | read tests/run.sh:870 | queued continuation keeps dirs | yes |
| L4-03 | 4 | ls decisions | gc-deps.md present | yes |
| L4-03 | 5 | grep architecture/README | §3 and README gc row list --deps, DEPS_DIRS; suite green | yes |
| L4-04 | 1 | read lib/queue.sh:73-79; bash -n | per-project gc --all-merged --deps with gc <name>: prefix, failure logged, before debrief | yes |
| L4-04 | 2 | read tests/run.sh:980 | gc line precedes harness debrief line, argv matches | yes |
| L4-04 | 3 | read tests/run.sh:1016 | failed/hung gc logged, debrief still starts | yes |
| L4-04 | 4 | ls decisions; grep docs | runner-gc.md present; docs mention runner gc | yes |
| L4-04 | 5 | check.sh | green | yes |
| L4-05 | 1 | ls docs/plans | L4-review.md with severities (Critical/Important) | yes |
| L4-05 | 2 | read tests/run.sh:839-845 | checks for non-run worktree, locked, untracked-hidden, default branch/live branch | yes |
| L4-05 | 3 | grep architecture §3/§10, README, retro-fixes R9 | all current; R9 says Landed | yes |
| L4-05 | 4 | grep finding/choice/rejected in 5 decision files; bash -n | 3 each; syntax ok | yes |
| L4-05 | 5 | lib/check.sh | green (cached for this tree), 0 FAIL | yes |

- *020716-verify-L4 · claude-sonnet-5-5*

### 2026-10-26 01:58 · L4-05 · passes

Opus review of the L4 diff: 3 Critical, 4 Important fixed RED→GREEN. gc now removes only harness/<run> worktrees, never rm -rfs one git refused (locked), sees hidden untracked files, survives a gone dir or du error, keeps main/origin's default/running branches; runner gc has a timeout and no git prompt. Prefix loop simplified, L4 docs done. 316→322 checks.

- **Files:** bin/harness, lib/queue.sh, tests/run.sh, docs/plans/2026-10-25-L4-review.md, journal/decisions/2026-10-26-gc-unattended-guards.md, journal/decisions/2026-10-25-gc-removal-finishes.md, journal/decisions/2026-10-25-gc-all-merged.md, journal/decisions/2026-10-25-runner-gc.md, docs/architecture.md, README.md, docs/specs/2026-10-21-retro-fixes.md
- **Verified:** check.sh: 322/322 (green in 548 s). RED first: 316/317 then 5 new FAILs; the untracked-file and default/live-branch checks passed vacuously in the suite (gc died at the gone dir first), so scratch repro.sh ran old bin/harness (git archive HEAD) vs new: old deleted the hidden untracked file, local trunk and origin harness/live, new kept all. bash -n on bin/harness, lib/queue.sh, tests/run.sh.
- **Tests:** 316 → 322
- **Dead end:** printing git's last stderr line in '! could not remove' — for a locked tree it is 'use remove -f -f … or unlock first', not the cause; the first line is
- **Discovery** (affects run): The full suite takes ~9-10 min under load now (548 s): a Bash background waiter needs a timeout over 600 s or it is killed.
- **Discovery** (affects L5, run): gc's worktree loop now only removes harness/<run> worktrees; a merged clean one on another branch prints 'keeps <wt>: not a run worktree (branch <b>)'. The local branch pass skips branches checked out in any worktree (no more 'cannot delete branch … used by worktree' noise).
- **Discovery** (affects L5, run): HARNESS_GC_TIMEOUT (env, default 10m) bounds the runner's gc; the suite's runner-gc failure check uses 2s with a fetch that sleeps 60.
- **Question for Michael:** Should a project be able to name branches gc never deletes (GC_KEEP_BRANCHES, e.g. 'production release/*')? Default taken: no setting; main and the origin's default branch are kept, every other branch merged into origin/main goes under the runner's nightly --all-merged.
- *24-L4-05 · claude-opus-5-5*

### 2026-10-26 01:05 · L4-04 · passes

lib/queue.sh: as it exits having started runs, runs `harness gc <dir> --all-merged --deps` once per distinct PROJECT_DIR of its runs, lines `gc <name>: …` in runner.log before the debrief line; a non-zero exit logs `gc <name> failed (exit <n>)` and the debrief still starts. Two checks; docs, README, decision file.

- **Files:** lib/queue.sh, tests/run.sh, docs/architecture.md, README.md, journal/decisions/2026-10-25-runner-gc.md
- **Verified:** tests: 314 → 316, red first (only the two new checks failed), then 316/316 via lib/check.sh (green in 541 s); runner.log in a KEEP=1 run showed the gc line, its removals and branch deletes before 'harness debrief (detached'; the gcfail runner logged 'gc proj failed (exit 1)' and the debrief count rose by one; bash -n lib/queue.sh tests/run.sh
- **Tests:** 314 → 316
- **Dead end:** letting the suite's runners gc proj as is — they removed stoppy, demo, walled and other merged fixture worktrees that later debrief and desk checks read (5 FAILs): tests/run.sh now keeps them dirty with an untracked marker (keep_wts/unkeep_wts) around the three runners that start runs
- **Discovery** (affects L4-05, L5, run): Every queue runner in tests/run.sh that starts a run now gcs $T/proj: a new runner test that starts runs must wrap itself in keep_wts … settle; unkeep_wts if later checks read existing worktrees. The queue's own runs' worktrees are gone afterwards; their records are read from $T/ledger/proj/<run>/.
- **Discovery** (affects L4-05, run): A meta.env without PROJECT_DIR inherits the caller's PROJECT_DIR when sourced (sessions export one): queue.sh unsets it before sourcing. debrief.sh rec_dir and other `source meta.env` sites may have the same leak.
- **Discovery** (affects run): The 'queue holds an entry whose project has a live run' flake: busy3 now sleeps 5 and the runner's --until is +3 s (was 3 and +1), so a slow runner start-up no longer misses starting stoppy-o.
- *23-L4-04 · claude-opus-5-5*

### 2026-10-26 00:14 · L4-03 · passes

harness gc --deps deletes DEPS_DIRS (default node_modules .next .next-check .venv) in worktrees of ended runs, merged or not: meta.env WT= must name the worktree; no live driver, queued continuation or open desk; never the checkout, a symlink, a path out of the tree or tracked files. Prints '+ freed <n> MB in <wt>: <dirs>' / 'would: freed'. 3 checks; decision, README, architecture §3/§10.

- **Files:** bin/harness, lib/config.sh, templates/user/config.sh, tests/run.sh, journal/decisions/2026-10-25-gc-deps.md, docs/architecture.md, README.md
- **Verified:** RED first: 312/314 (two new --deps checks failed on 'unknown option'); then lib/check.sh green, 314/314. KEEP=1 run: gcd1/gcd2 output read by hand (one freed line, deps-end only).
- **Tests:** 311 → 314
- **Dead end:** the queued-continuation check as `! grep -q deps-q` — the branch pass prints '! failed: branch -d harness/deps-q' (merged branch checked out in a worktree); narrowed to the freed line
- **Discovery** (affects L4-05, L4-04): cmd_gc's branch passes try `branch -d` on merged branches checked out in a worktree (a live or queued run's, a dirty one gc kept): git refuses, gc prints 'error: cannot delete branch … used by worktree' and '! failed: …'. Harmless but noisy; the passes could skip branches `running` or listed in `git worktree list`.
- **Discovery** (affects L4-04, L4-05): --deps runs after the worktree removal loop and reads DEPS_DIRS via harness_config "$p" in a subshell (user config, then the checkout's .harness/config.sh). tests/run.sh has gd_run <run> [<wt>] (state dir with ended + meta.env, worktree on harness/<run> at origin/main, node_modules/x.js).
- *22-L4-03 · claude-opus-5-5*

### 2026-10-25 23:27 · L4-02 · passes

gc removes a clean, merged worktree with `worktree remove --force`, then `rm -rf` if it stays, then `worktree prune`; a failure prints `! could not remove <wt>: <why>` and the loop goes on; --dry-run prints `would: … --force` for each. Two new checks (watched red first); the loop never touches the project's own checkout. 309 → 311 checks.

- **Files:** bin/harness, tests/run.sh, journal/decisions/2026-10-25-gc-removal-finishes.md, docs/architecture.md, README.md
- **Verified:** bash tests/run.sh before the fix: 309/311 (both new checks FAIL); after: 311/311 via lib/check.sh (green in 526 s); bash -n bin/harness and tests/run.sh
- **Tests:** 309 → 311
- **Discovery** (affects L4-03, L4-05): A worktree whose parent is read-only: `git worktree remove --force` empties it, removes its .git file and fails with `error: failed to delete '<wt>': Permission denied`; rm -rf then fails too; after `worktree prune` git no longer lists it, so the branch pass can still delete its branch. gc's worktree loop now skips the project checkout ($wt == $p) explicitly, since rm -rf follows a failed remove.
- **Discovery** (affects L4-03): tests/run.sh has gw_add/gw_listed helpers and $T/proj/.git/info/exclude now lists .next/ (L4-02 block after the L4-01 branch checks); the gcw-* worktrees and branches are cleaned up after.
- *21-L4-02 · claude-opus-5-5*

### 2026-10-25 22:58 · L4-01 · passes

gc --all-merged now lists branches by prefix (refs/heads/, refs/remotes/origin/; plain gc harness/ and harness-merge/) and runs every pass, deleting merged spec/x, docs/y, flat etc. A second bug found by the check: a refused `branch -d` (no upstream, HEAD behind origin/main) ended gc under set -e; act now prints `! failed: <argv>` and gc goes on. L4 plan written.

- **Files:** bin/harness, tests/run.sh, docs/plans/2026-10-25-L4-gc.md, journal/decisions/2026-10-25-gc-all-merged.md, docs/architecture.md, README.md
- **Verified:** RED first: 306/308 (both new checks failed: --all-merged deleted only flat; plain gc died on harness/z's refused -d). GREEN: bash tests/run.sh 309/309 and lib/check.sh 309/309; bash -n bin/harness tests/run.sh; scratch repro in the scratch dir shows dry-run prints each would: once.
- **Tests:** 306 → 309
- **Dead end:** fixture branches pushed without -u — branch -d measures against upstream or HEAD; the suite's $T/proj main is behind origin/main, so -d refused every fixture branch
- **Discovery** (affects L4-02): git 2.43 here: `git worktree remove` (no --force) removes a clean worktree whose only extra files are ignored (.next/ via .gitignore or info/exclude). R9's refusal had another cause (an undeletable file, or the loop dying under set -e); the fallback chain is the fix. `git worktree list` sorts worktrees by path (main first), so fixtures can fix the order by name.
- **Discovery** (affects L4-02, L4-03, L4-05): cmd_gc's act no longer exits non-zero on a failed command: it prints `! failed: <argv>` and returns 0, so `act git worktree remove` failures no longer end gc either (L4-02 replaces that call with its own fallback and `! could not remove` line). $T/proj's local main is behind origin/main in the suite, so `branch -d` of a branch with no upstream is refused there.
- **Discovery** (affects L4-04): Plan fixes L4-04's failure fixture: a `git` wrapper first on PATH for one runner that fails `-C <dir> fetch -q --prune origin` (only gc runs that argv); no STUB_GC_FAIL in production code.
- **Question for Michael:** D1 default (decisions/2026-10-25-gc-all-merged): gc keeps `branch -d`, so a merged branch with no upstream in a checkout whose main is behind origin/main stays locally (`! failed:` line; its origin copy goes). Would you rather gc delete it with `git update-ref -d refs/heads/<b> <sha>` after its origin/main check (as safe, never refused)?
- *20-L4-01 · claude-opus-5-5*

### 2026-10-25 22:19 · verify L3 · passes

L3-01..05 hold: suite re-run 306/306, syntax checks clean, each named check PASS, docs/plan/template/decisions read against the steps.

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| L3-01 | 1 | read plan, templates/user/harness-tmpfiles.conf, README | plan §1 covers scratch_done, newest check-out, HARNESS_CACHE, tmpfiles; template has `e /tmp/harness - - - 3d` plus x live.lock; README has install command | yes |
| L3-01 | 2 | read plan driver-window and reaper sections | capture-pane -S -, TMUX_KEEP_HOURS=24, shared tmux_reap in lib/tmux.sh, matches step | yes |
| L3-01 | 3 | read plan test-driving section | private tmux server, PATH shim, decoy sessions described and implemented in tests/run.sh | yes |
| L3-01 | 4 | read plan check list | checks named; all present as PASS in suite | yes |
| L3-01 | 5 | bash tests/run.sh | bash tests/run.sh: 306/306 checks passed | yes |
| L3-02 | 1 | check 'finish keeps check-last.out and init.out…' | PASS: state files, scratch gone, live.lock intact | yes |
| L3-02 | 2 | check KEEP_SCRATCH=1; grep config files | PASS; default 0, template commented | yes |
| L3-02 | 3 | check 'check.sh keeps one check-<key>.out' | PASS | yes |
| L3-02 | 4 | check 'init and sessions see HARNESS_CACHE' | PASS | yes |
| L3-02 | 5 | cat tmpfiles template; grep README | rule and install command; Playwright guidance | yes |
| L3-02 | 6 | grep architecture §4; read decision | Scratch/Cache rows; decision has Finding/Choice/Rejected | yes |
| L3-02 | 7 | bash -n lib/*.sh; suite | bash tests/run.sh: 306/306 checks passed | yes |
| L3-03 | 1 | grep lib/config.sh, template, bin/harness:199-201 | default 24; command captures pane, kills supervisor window, prints, sleeps, kill-session | yes |
| L3-03 | 2 | check 'tmux: TMUX_KEEP_HOURS=0…' | PASS | yes |
| L3-03 | 3 | check 'tmux: a keep window keeps h-<run>…' | PASS | yes |
| L3-03 | 4 | check 'tmux: run id dot.run…' | PASS | yes |
| L3-03 | 5 | read decision, architecture §3/§10 | present, Finding/Choice/Rejected | yes |
| L3-03 | 6 | bash -n bin/harness; suite | bash tests/run.sh: 306/306 checks passed | yes |
| L3-04 | 1 | read lib/tmux.sh, bin/harness:376 | log line, dry-run via act flag, continues after failed kill | yes |
| L3-04 | 2 | check 'harness gc reaps only the ended runs…' | PASS; decoys survive, second ended run reaped | yes |
| L3-04 | 3 | check 'harness gc --dry-run kills no tmux session' | PASS | yes |
| L3-04 | 4 | check 'queue runner reaps…'; lib/queue.sh:69 | PASS; reap before debrief | yes |
| L3-04 | 5 | read decision, architecture, README | present | yes |
| L3-04 | 6 | bash -n bin/harness lib/queue.sh; suite | bash tests/run.sh: 306/306 checks passed | yes |
| L3-05 | 1 | read docs/plans/2026-10-25-L3-review.md | findings with severities | yes |
| L3-05 | 2 | checks scratch_rm refuses…, start refuses…, exact targets | PASS; 17 refusals; RED→GREEN checks per Important finding | yes |
| L3-05 | 3 | grep architecture §4/§10/§14, README | complete, tmux-driver.txt named | yes |
| L3-05 | 4 | read decisions; bash -n; node --check | three-part decisions; syntax clean | yes |
| L3-05 | 5 | bash tests/run.sh | bash tests/run.sh: 306/306 checks passed | yes |

- *221005-verify-L3 · claude-sonnet-5-5*

### 2026-10-25 22:10 · L3-05 · passes

Opus review of the L3 diff: no Critical; 2 Important fixed RED→GREEN (start killed another run's same-name tmux session; h-queue/attach prefix targets). Guard now refuses symlinked paths; scratch_done moved to lib/prompt.sh, keeps scratch on a failed copy, honest notes, final tree's check-last.out. Docs §4/§14/§15, README, decisions.

- **Files:** bin/harness, lib/tmux.sh, lib/prompt.sh, lib/driver.sh, lib/eval.sh, templates/project/init.sh, tests/run.sh, docs/architecture.md, README.md, docs/plans/2026-10-25-L3-review.md, journal/decisions/2026-10-25-scratch-cleanup.md, journal/decisions/2026-10-25-tmux-reaper.md
- **Verified:** bash tests/run.sh: 301/306 with the five new checks failing, then 306/306; lib/check.sh green in 526 s (306/306); bash -n on every L3 shell file, no .mjs touched
- **Tests:** 301 → 306
- **Dead end:** letting rm's stderr through scratch_done — it lands in the note capture; the note carries rm's exit instead
- **Discovery** (affects L4, run): harness start now refuses a run id whose h-<run> another run that isn't done holds (any project, a.b vs a-b): this also closes L2 review #5 (shared harness-<id>-* units). A crashed run of another project with the same id blocks the id until it is continued or ended.
- **Discovery** (affects L4, L5): scratch_done <key> and scratch_rm live in lib/prompt.sh; scratch_rm returns 2 on refusal. entry-stale-*/entry-failed-* now go to the state dir.
- **Discovery** (affects run): Deferred from the L3 review: queue runner reap spares no attached session (#11); kill re-check and '! could not kill' path unexercised (#14).
- *19-L3-05 · claude-opus-5-5*

### 2026-10-25 21:17 · L3-04 · passes

New lib/tmux.sh: tmux_name (moved from bin/harness) and tmux_reap, which kills h-<run> of runs with meta.env+ended, no live driver (re-checked), no PAUSE; spares a resume's newer session and a name a live/paused run shares (a.b vs a-b). harness gc calls it before git fetch; queue.sh as it exits, before the debrief. start refuses run id queue. 3 checks; 299 → 302.

- **Files:** lib/tmux.sh, bin/harness, lib/queue.sh, tests/run.sh, docs/architecture.md, README.md, journal/decisions/2026-10-25-tmux-reaper.md
- **Verified:** tests: 302/302 (bash tests/run.sh, then lib/check.sh green in 524 s); the three new checks watched failing first (298/302, plus one desk check cascading on the unreaped sleep 600 decoys, fixed by unconditional cleanup); mutation run on a scratch private tmux server: with the shared-name guard off h-held-x would be killed, with fresh's ended touched now h-fresh would be.
- **Tests:** 299 → 302
- **Discovery** (affects L3-05, run): tmux_name is lossy (a.b and a-b of any project are both h-a-b): tmux_reap checks every state dir of the root for a same-name run that is live, paused or not ended and keeps the session then. cmd_start's resume kill-session still kills a same-name session of another run (pre-existing, like L2-06's svc note).
- **Discovery** (affects L3-05): The queue-runner reap check (tests/run.sh, first runner block) creates h-proj-$D, h-proj-$D-2, h-queue and the desk session before the runner and kills all four after, so the desk checks still start with no desk session and no 'sleep 600' pane. The gc reap block is the last before the summary and removes its decoy state dirs (livey/held-x hold the suite's pid).
- **Proposed change:** L3-04 step 1 says gc calls the helper 'through act': gc prints the helper's own lines (+ reaped … / would: tmux kill-session -t =<s> (<run> ended) / ! could not kill …), the unit step's shape, as plan §9 says; act couldn't name the run.
- **Proposed change:** L3-04 step 2's paused decoy has no ended, so it can't exercise the PAUSE guard: the check adds pausx (PAUSE + ended), fresh (a resume's session) and held.x/held-x (a shared name), per plan §6.3.
- *18-L3-04 · claude-opus-5-5*

### 2026-10-25 20:47 · L3-03 · passes

Driver window: when the driver exits it saves scrollback to <state>/tmux-driver.txt, kills the supervisor window, prints the line, sleeps TMUX_KEEP_HOURS (default 24) and kills h-<run>; `trap : INT` so a Ctrl-C never skips it; exact =targets. Suite PATH shim for the supervisor's claude. Three tmux checks; decision, architecture §3/§4/§10, README. 296 → 299.

- **Files:** bin/harness, lib/config.sh, templates/user/config.sh, tests/run.sh, docs/architecture.md, README.md, journal/decisions/2026-10-25-tmux-driver-window.md
- **Verified:** lib/check.sh: 299/299 (check: green in 519 s); the three new tmux checks watched failing first (0/3), the Ctrl-C part watched failing without the trap; bash -n on bin/harness, tests/run.sh, lib/config.sh. An Opus review's four findings fixed (Ctrl-C, leading-zero hours, supervisor-window race, vacuous -s check).
- **Tests:** 296 → 299
- **Dead end:** asserting the printed line with plain capture-pane -p — the pane wraps at 80 columns; -J joins it (also used for tmux-driver.txt)
- **Dead end:** printf %q of the whole message — under a C locale it makes the em-dash $'…', bash-only; now only the path is %q'd
- **Discovery** (affects L3-04, L3-05): tests/run.sh now exports PATH=$T/bin:$PATH at the top with $T/bin/claude wrapping stub-claude.sh; tmux runs end through --until-epoch in the past and are waited on with tended <state> / tgone <session> (defined in the L3-03 block, reusable by L3-04's checks). Each tmux run's tmux-driver.txt holds the driver's 'deadline reached' line.
- **Discovery** (affects L3-04): The window's message promises 'or sooner on harness gc', which holds only once L3-04's reaper lands. bin/harness's tmux new-window targets now use =<s>:, and the supervisor prompt is rendered before new-session.
- **Discovery** (affects run): The known flake 'queue holds an entry whose project has a live run' failed once more while two tmux iteration runs loaded the box; the clean rerun passed.
- **Proposed change:** L3-03 step 1 names `tmux capture-pane -p -S -`: built as `-pJ` (joins wrapped lines) plus `trap : INT` on the window shell, both from the review; recorded in decisions/2026-10-25-tmux-driver-window
- *17-L3-03 · claude-opus-5-5*

### 2026-10-25 20:25 · L3-02 · passes

finish copies init.out, teardown.out, check-last.out to $STATE and deletes the run's scratch via a guarded scratch_rm (KEEP_SCRATCH=1 keeps it); check.sh keeps one check-<key>.out, the test count now lives in the green marker; HARNESS_CACHE exported and created; tmpfiles template, README, docs, decision. Review fixes: continued-run tests-end, eval probes' init output, merge's empty scratch.

- **Files:** lib/driver.sh, lib/prompt.sh, lib/check.sh, lib/config.sh, lib/eval.sh, templates/user/config.sh, templates/user/harness-tmpfiles.conf, tests/run.sh, tests/stub-claude.sh, README.md, docs/architecture.md, journal/decisions/2026-10-25-scratch-cleanup.md
- **Verified:** suite 296/296 (lib/check.sh, green in 514 s). The 6 planned checks plus a continued-run tests-end check failed first (0/6 on old code; the continuation check failed with only the old tests-end line restored), then passed; the eval probe check failed with HEAD's scratch deletion and passed after KEEP_SCRATCH=1 in eval safety (15/16 then 16/16).
- **Tests:** 289 → 296
- **Dead end:** the guard check's env vars GP/GR/GQ — GP is a pid variable earlier in the suite (gatestop); renamed SR_ROOT/SR_PROJ/SR_RUN
- **Dead end:** hlog demo for the KEEP_SCRATCH note — gc removes demo's worktree before the end of the suite; read $T/demo-hlog.md instead
- **Dead end:** { cat marker; testcount; } | grep -m1 . for the count — grep -m1 can SIGPIPE its producers under pipefail; plain assignments instead
- **Discovery** (affects run): systemctl --user is-enabled systemd-tmpfiles-clean.timer prints `disabled` on this box: the tmpfiles install command in README also runs `systemctl --user enable --now systemd-tmpfiles-clean.timer`.
- **Discovery** (affects L3-03, L3-04, L3-05): tests/run.sh: KEEP_SCRATCH=1 is in base-config.sh and every line that rewrites user-config.sh (13 lines); a new config line that starts from scratch must add it, or later checks lose the stub's scratch files. XDG_CACHE_HOME=$T/cache is exported at the top. The scrub run (KEEP_SCRATCH=0, its own HARNESS_CONFIG and a counting CHECK_CMD in its run.env) is at the end, before the summary: L3-03's tmux block can follow it.
- **Discovery** (affects L3-05, run): green-<key> markers in $STATE/green now hold `<n> tests` (empty when the output has none); check.sh's cached line and finish's tests-end read the marker first.
- **Discovery** (affects L3-05): Eval runs set KEEP_SCRATCH=1 (lib/eval.sh safety), since probes render the next prompt after the run ends; `harness merge` rmdirs its empty scratch.
- **Question for Michael:** Install the optional scratch age rule (3 days, never live.lock)? `mkdir -p ~/.config/user-tmpfiles.d && cp templates/user/harness-tmpfiles.conf ~/.config/user-tmpfiles.d/harness.conf && systemd-tmpfiles --user --create && systemctl --user enable --now systemd-tmpfiles-clean.timer`
- **Proposed change:** L3-02 step 1 names run demo: the check runs on a new run `scrub` with KEEP_SCRATCH=0 (demo's checks read its scratch after the run; plan §9), and demo shows KEEP_SCRATCH=1 instead.
- *16-L3-02 · claude-opus-5-5*

### 2026-10-25 19:55 · L3-01 · passes

Wrote docs/plans/2026-10-25-L3-scratch-and-tmux.md: finish's scratch_done + scratch_rm guard, check.sh newest-only, HARNESS_CACHE, tmpfiles template, the H1a driver-window command, lib/tmux.sh (tmux_name + tmux_reap) for gc and queue.sh, how the suite drives real tmux runs, and the 12 L3 checks by name. Plan only; suite 289/289.

- **Files:** docs/plans/2026-10-25-L3-scratch-and-tmux.md
- **Verified:** check.sh full run: 289/289 green in 505 s; tmux facts probed on a throwaway private server (tmux 3.4); each plan reference checked against bin/harness, lib/driver.sh, lib/check.sh, lib/prompt.sh, lib/queue.sh, tests/run.sh
- **Tests:** 289 → 289
- **Discovery** (affects L3-02): 26 tests/run.sh lines read $T/scratch/<p>/<run>/ after a run ends (3 on demo); the stub's count-* files span continuations. Plan §2: KEEP_SCRATCH=1 in base-config.sh and every line that rewrites user-config.sh from scratch; the scratch checks use their own HARNESS_CONFIG on a new run `scrub`.
- **Discovery** (affects L3-03, L3-04): The private tmux server's windows get the suite's env from when the server started, not the caller's: PATH (the $T/bin/claude wrapper, not a symlink: the stub finds fixtures by dirname $0) and XDG_CACHE_HOME=$T/cache must be exported at the top of tests/run.sh. Per-command STUB_* flags never reach a tmux window; tmux runs end through --until-epoch in the past (initializer, then deadline).
- **Discovery** (affects L3-04): tmux display-message -p -t =<s>: '#{session_created}' needs the trailing colon (without it, nothing is printed). The reaper skips a session created after its run's ended (a resume's session before its driver writes driver.pid), so checks create decoy sessions first and write ended after.
- **Discovery** (affects L3-04): bin/harness runs under set -e: the reaper wraps kill-session in if/else and goes before cmd_gc's git fetch.
- **Question for Michael:** Defaults taken (plan §8): KEEP_SCRATCH=0 and teardown.out kept beside init.out/check-last.out; the tmpfiles template also excludes /tmp/harness/*/live.lock; TMUX_KEEP_HOURS whole hours (else 24); `queue` becomes a refused run id. Keep these?
- **Proposed change:** L3-02 step 1: run the scratch check on a new run `scrub` with KEEP_SCRATCH=0, not `demo` (demo's checks read its scratch after the run); demo shows KEEP_SCRATCH=1 instead
- **Proposed change:** L3-04 step 1: gc's reap lines come from the helper (`+ reaped tmux session …`, `would: tmux kill-session -t =<s> (<run> ended)`), the unit step's shape, not through act
- **Proposed change:** L3-04 step 2: add a paused decoy with PAUSE and ended (pausx) and a resume decoy (fresh), so the PAUSE and session-created guards are exercised
- *15-L3-01 · claude-opus-5-5*

### 2026-10-25 19:37 · verify L2 · passes

Suite 289/289 green. All six L2 features hold: scope+timeout init, teardown hook and services_down on every stop point, gc orphan units, status MemoryCurrent, review fixes and docs checked against named tests.

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| L2-01 | 1 | read step, ran bash tests/run.sh (289/289), grepped named checks/docs/files | plan docs/plans/2026-10-25-L2-run-services.md present; fixtures present; suite green | yes |
| L2-01 | 2 | read step, ran bash tests/run.sh (289/289), grepped named checks/docs/files | plan docs/plans/2026-10-25-L2-run-services.md present; fixtures present; suite green | yes |
| L2-01 | 3 | read step, ran bash tests/run.sh (289/289), grepped named checks/docs/files | plan docs/plans/2026-10-25-L2-run-services.md present; fixtures present; suite green | yes |
| L2-01 | 4 | read step, ran bash tests/run.sh (289/289), grepped named checks/docs/files | plan docs/plans/2026-10-25-L2-run-services.md present; fixtures present; suite green | yes |
| L2-01 | 5 | read step, ran bash tests/run.sh (289/289), grepped named checks/docs/files | plan docs/plans/2026-10-25-L2-run-services.md present; fixtures present; suite green | yes |
| L2-02 | 1 | read step, ran bash tests/run.sh (289/289), grepped named checks/docs/files | config defaults, check at run_init stop-then-systemd-run at tests/run.sh:637, STUB_NO_SYSTEMD bare check :633, decision file exists | yes |
| L2-02 | 2 | read step, ran bash tests/run.sh (289/289), grepped named checks/docs/files | config defaults, check at run_init stop-then-systemd-run at tests/run.sh:637, STUB_NO_SYSTEMD bare check :633, decision file exists | yes |
| L2-02 | 3 | read step, ran bash tests/run.sh (289/289), grepped named checks/docs/files | config defaults, check at run_init stop-then-systemd-run at tests/run.sh:637, STUB_NO_SYSTEMD bare check :633, decision file exists | yes |
| L2-02 | 4 | read step, ran bash tests/run.sh (289/289), grepped named checks/docs/files | config defaults, check at run_init stop-then-systemd-run at tests/run.sh:637, STUB_NO_SYSTEMD bare check :633, decision file exists | yes |
| L2-02 | 5 | read step, ran bash tests/run.sh (289/289), grepped named checks/docs/files | config defaults, check at run_init stop-then-systemd-run at tests/run.sh:637, STUB_NO_SYSTEMD bare check :633, decision file exists | yes |
| L2-02 | 6 | read step, ran bash tests/run.sh (289/289), grepped named checks/docs/files | config defaults, check at run_init stop-then-systemd-run at tests/run.sh:637, STUB_NO_SYSTEMD bare check :633, decision file exists | yes |
| L2-03 | 1 | read step, ran bash tests/run.sh (289/289), grepped named checks/docs/files | services_down in driver.sh:62; checks :646 (marker, stop after, one note), :662-666 (TERM -> driver exited, ended), template+README, decision file | yes |
| L2-03 | 2 | read step, ran bash tests/run.sh (289/289), grepped named checks/docs/files | services_down in driver.sh:62; checks :646 (marker, stop after, one note), :662-666 (TERM -> driver exited, ended), template+README, decision file | yes |
| L2-03 | 3 | read step, ran bash tests/run.sh (289/289), grepped named checks/docs/files | services_down in driver.sh:62; checks :646 (marker, stop after, one note), :662-666 (TERM -> driver exited, ended), template+README, decision file | yes |
| L2-03 | 4 | read step, ran bash tests/run.sh (289/289), grepped named checks/docs/files | services_down in driver.sh:62; checks :646 (marker, stop after, one note), :662-666 (TERM -> driver exited, ended), template+README, decision file | yes |
| L2-03 | 5 | read step, ran bash tests/run.sh (289/289), grepped named checks/docs/files | services_down in driver.sh:62; checks :646 (marker, stop after, one note), :662-666 (TERM -> driver exited, ended), template+README, decision file | yes |
| L2-03 | 6 | read step, ran bash tests/run.sh (289/289), grepped named checks/docs/files | services_down in driver.sh:62; checks :646 (marker, stop after, one note), :662-666 (TERM -> driver exited, ended), template+README, decision file | yes |
| L2-03 | 7 | read step, ran bash tests/run.sh (289/289), grepped named checks/docs/files | services_down in driver.sh:62; checks :646 (marker, stop after, one note), :662-666 (TERM -> driver exited, ended), template+README, decision file | yes |
| L2-04 | 1 | read step, ran bash tests/run.sh (289/289), grepped named checks/docs/files | SVC_IDLE_STOP_MIN default; checks paused :688, stoppy :785, 11/9 min :820-825, memory wait :704; architecture §5/§7 + decision file | yes |
| L2-04 | 2 | read step, ran bash tests/run.sh (289/289), grepped named checks/docs/files | SVC_IDLE_STOP_MIN default; checks paused :688, stoppy :785, 11/9 min :820-825, memory wait :704; architecture §5/§7 + decision file | yes |
| L2-04 | 3 | read step, ran bash tests/run.sh (289/289), grepped named checks/docs/files | SVC_IDLE_STOP_MIN default; checks paused :688, stoppy :785, 11/9 min :820-825, memory wait :704; architecture §5/§7 + decision file | yes |
| L2-04 | 4 | read step, ran bash tests/run.sh (289/289), grepped named checks/docs/files | SVC_IDLE_STOP_MIN default; checks paused :688, stoppy :785, 11/9 min :820-825, memory wait :704; architecture §5/§7 + decision file | yes |
| L2-04 | 5 | read step, ran bash tests/run.sh (289/289), grepped named checks/docs/files | SVC_IDLE_STOP_MIN default; checks paused :688, stoppy :785, 11/9 min :820-825, memory wait :704; architecture §5/§7 + decision file | yes |
| L2-04 | 6 | read step, ran bash tests/run.sh (289/289), grepped named checks/docs/files | SVC_IDLE_STOP_MIN default; checks paused :688, stoppy :785, 11/9 min :820-825, memory wait :704; architecture §5/§7 + decision file | yes |
| L2-04 | 7 | read step, ran bash tests/run.sh (289/289), grepped named checks/docs/files | SVC_IDLE_STOP_MIN default; checks paused :688, stoppy :785, 11/9 min :820-825, memory wait :704; architecture §5/§7 + decision file | yes |
| L2-05 | 1 | read step, ran bash tests/run.sh (289/289), grepped named checks/docs/files | gc checks :765-771 (would:, ? unmatched, stops), status MemoryCurrent :657; docs, README, decision file | yes |
| L2-05 | 2 | read step, ran bash tests/run.sh (289/289), grepped named checks/docs/files | gc checks :765-771 (would:, ? unmatched, stops), status MemoryCurrent :657; docs, README, decision file | yes |
| L2-05 | 3 | read step, ran bash tests/run.sh (289/289), grepped named checks/docs/files | gc checks :765-771 (would:, ? unmatched, stops), status MemoryCurrent :657; docs, README, decision file | yes |
| L2-05 | 4 | read step, ran bash tests/run.sh (289/289), grepped named checks/docs/files | gc checks :765-771 (would:, ? unmatched, stops), status MemoryCurrent :657; docs, README, decision file | yes |
| L2-05 | 5 | read step, ran bash tests/run.sh (289/289), grepped named checks/docs/files | gc checks :765-771 (would:, ? unmatched, stops), status MemoryCurrent :657; docs, README, decision file | yes |
| L2-06 | 1 | read step, ran bash tests/run.sh (289/289), grepped named checks/docs/files | review doc has severities; RED->GREEN checks for Important findings; one-note check :646; §10/§14 docs; bash -n ok | yes |
| L2-06 | 2 | read step, ran bash tests/run.sh (289/289), grepped named checks/docs/files | review doc has severities; RED->GREEN checks for Important findings; one-note check :646; §10/§14 docs; bash -n ok | yes |
| L2-06 | 3 | read step, ran bash tests/run.sh (289/289), grepped named checks/docs/files | review doc has severities; RED->GREEN checks for Important findings; one-note check :646; §10/§14 docs; bash -n ok | yes |
| L2-06 | 4 | read step, ran bash tests/run.sh (289/289), grepped named checks/docs/files | review doc has severities; RED->GREEN checks for Important findings; one-note check :646; §10/§14 docs; bash -n ok | yes |
| L2-06 | 5 | read step, ran bash tests/run.sh (289/289), grepped named checks/docs/files | review doc has severities; RED->GREEN checks for Important findings; one-note check :646; §10/§14 docs; bash -n ok | yes |

- *192902-verify-L2 · claude-sonnet-5-5*

### 2026-10-25 19:28 · L2-06 · passes

Opus review of the L2 diff (docs/plans/2026-10-25-L2-review.md: 2 Important, 8 Minor). Fixed: a TERM mid-init stops the init before the teardown; a TERM mid-teardown waits for it, no second; .harness/teardown.sh looked up at each stop point, not at load_config; the trap commits its note; template runnable by hand; docs. 4 new checks RED→GREEN.

- **Files:** lib/driver.sh, lib/config.sh, tests/run.sh, tests/stub-claude.sh, templates/project/teardown.sh, docs/architecture.md, README.md, journal/decisions/2026-10-25-teardown-hook.md, docs/plans/2026-10-25-L2-review.md
- **Verified:** lib/check.sh green twice (289/289); RED runs: 285/289 (the 4 new checks failing), the hook-lookup check re-proved alone 288/289 with HEAD's config.sh; bash -n on every touched shell file, node --check lib/*.mjs; template run by hand (My.Run → harness-my-run, unset id → message, exit 1)
- **Tests:** 285 → 289
- **Dead end:** STUB_SLOW_INIT as the init command's knob — stub-claude.sh already uses it to slow the initializer session; renamed STUB_SLOW_INITCMD
- **Dead end:** sd_at (first stop) to prove a stop before the trap's teardown — run_init's own stop-first matched; the check counts svc stops before the hook (sd_before == 2)
- **Discovery** (affects L4, run): Deferred L2 review Minors: two projects' runs of one id share harness-<id>-svc (refuse in cmd_start); SVC_UP is shell-only, so a continue segment with no init leaves a SIGKILLed segment's svc scope to gc ($STATE/svc-up sketch); without user systemd the note says services stopped while bare init children run on.
- **Discovery** (affects L3, L4, L5): The suite project's INIT_CMD now takes STUB_SLOW_INITCMD=<s> (touches $HARNESS_SCRATCH/init-begin, sleeps) and its teardown.sh STUB_SLOW_TEARDOWN=<s> (touches teardown-begin); stub-claude STUB_ADD_TEARDOWN=1 makes the initializer write an executable .harness/teardown.sh. tests/run.sh has sd_before <key> <index>.
- **Discovery** (affects L4, run): TEARDOWN_CMD defaults to empty now; services_down picks .harness/teardown.sh when executable at call time.
- **Discovery** (affects run): The known 'queue holds an entry whose project has a live run' flake (busy3 sleep 3) failed once more in a KEEP=1 run under load.
- *14-L2-06 · claude-opus-5-5*

### 2026-10-25 18:21 · L2-05 · passes

harness gc first stops the units of this project's runs with no live driver (+ stopped <u> (<run> ended|: driver gone), --dry-run would:, ? for no run of this project); harness status lists a running run's units with MemoryCurrent. scope_owns in lib/scope.sh is the shared match; stub systemctl answers MemoryCurrent and the described list-units shape.

- **Files:** bin/harness, lib/scope.sh, tests/run.sh, tests/stub-systemctl.sh, docs/architecture.md, README.md, journal/decisions/2026-10-25-gc-orphan-units.md
- **Verified:** tests/run.sh 282 → 285/285 (scope_owns unit check, gc unit check with a.b/a-b collision decoy, status check in the termed block); the three failed before the code; lib/check.sh green in 493 s; Opus review of the diff, findings 1-3 and 5 fixed
- **Tests:** 282 → 285
- **Dead end:** a waited `sleep 0` pid as the dead driver.pid — a reused pid would count as live (review): 999999999 is over any pid_max
- **Discovery** (affects L4, L2-06): gc's unit step runs first in cmd_gc, before the fetch: a review found an offline fetch or a prunable worktree ends gc under set -e before a later step, and a worktree could be removed while a SIGKILLed run's session still ran in it. L4's per-worktree error handling should keep that order.
- **Discovery** (affects L3, L2-06): scope_owns <run> <unit>.scope (lib/scope.sh) is the one unit→run match (roles s<n>, check-<pid>, svc); bin/harness now sources lib/scope.sh. L3's gc of tmux sessions can follow the same candidates-over-every-project pattern.
- **Discovery** (affects L2-06): Not fixed (display only): two running runs whose ids reduce to one prefix (a.b, a-b) each list both runs' units in harness status.
- **Discovery** (affects run): One full-suite run failed 'queue holds an entry whose project has a live run' (its busy3 driver is a `sleep 3`); the next two runs passed unchanged: a timing flake under load.
- **Question for Michael:** D1 default (decisions/2026-10-25-gc-orphan-units): harness status calls list-units without a scope_available probe first (a failing list-units gives nothing; the probe would start a transient scope per status). Keep it?
- **Proposed change:** L2-05 step 1: the unit step runs first in cmd_gc, not after the branch passes (review finding); its lines are gc's own, not act's; a run with no live driver qualifies with or without ended (plan §11).
- *13-L2-05 · claude-opus-5-5*

### 2026-10-25 17:36 · L2-04 · passes

Services now also stop on pause (services_down paused, then commit+push), before a usage-limit wait over SVC_IDLE_STOP_MIN=10 min, and on the memory wait (renamed `memory wait`); STOP already went through finish. New key in config.sh/template/architecture §10; §5/§7, README and decisions/2026-10-25-services-stop-points updated.

- **Files:** lib/driver.sh, lib/scope.sh, lib/config.sh, templates/user/config.sh, tests/run.sh, tests/stub-claude.sh, docs/architecture.md, README.md, journal/decisions/2026-10-25-services-stop-points.md
- **Verified:** Wrote 5 checks + the mg unit-check rename first: 4 failed (mg block, PAUSE, memory wait, usage-limit wait 11 min); stoppy and the 9-minute check passed already as the plan predicted (check-only). After the change bash tests/run.sh 282/282; lib/check.sh green in 492 s.
- **Tests:** 277 → 282
- **Discovery** (affects L2-05, L2-06): stub-claude.sh has STUB_PAUSE=<id>: that id's first coding session touches $HARNESS_STATE/*/<run>/PAUSE. Run `paused` in tests/run.sh drives it in the background and resumes with `harness resume paused` once hlog has `services stopped (paused)`.
- **Discovery** (affects run): Run waiter's window is now +660 s (11 min) and waiter9 (+540 s) is new; the suite has two more full runs (about +20 s).
- **Question for Michael:** D1 default: SVC_IDLE_STOP_MIN=10 (a usage-limit wait of more than 10 minutes stops the services; shorter keeps them). Keep 10?
- *12-L2-04 · claude-opus-5-5*

### 2026-10-25 17:08 · L2-03 · passes

services_down runs .harness/teardown.sh (TEARDOWN_CMD) under timeout -k 10s 2m, stops harness-<run>-svc, notes once per started init; on finish and in the EXIT trap, which first ignores TERM/INT/HUP and stops the running session's scope. verify re-inits after a memory wait. Stubs kill a stopped scope's tree. Template, README, arch, decision. Tests 274 → 277.

- **Files:** lib/driver.sh, lib/config.sh, templates/user/config.sh, templates/project/teardown.sh, tests/run.sh, tests/stub-systemd-run.sh, tests/stub-systemctl.sh, README.md, docs/architecture.md, journal/decisions/2026-10-25-teardown-hook.md
- **Verified:** 3 new checks, each seen RED on a snapshot (finish teardown→stop→one note on demo; a TERM to run termed's driver mid-session: session scope stop < teardown < svc stop, no stub claude left, ended/driver.pid; lowmem: every session before finish starts with svc up). bash tests/run.sh 277/277; lib/check.sh green in 470 s; no harness-test-* unit left.
- **Tests:** 274 → 277
- **Discovery** (affects L2-04): verify() now does `mem_gate || run_init` (pulled forward from L2-04: with a real services_down the gate after verify's run_init stopped the services before the verify session). L2-04 only needs to rename mem_gate's `services_down memory` to `memory wait` and add its checks; the lowmem run notes `services stopped (memory)` until then.
- **Discovery** (affects L2-04, L2-05, L2-06): The suite's project now has an executable .harness/teardown.sh writing $HARNESS_SCRATCH/teardown-<why-safe>.marker and a `teardown\n<run>\n<why>` record into systemd.log; helpers sd_last (last record index) and svc_gaps <run> (sessions started with svc down) are in tests/run.sh. Every run in proj now notes `services stopped (<finish reason>)`.
- **Discovery** (affects L2-05): stub-systemd-run.sh runs its command in the background (<&0 keeps stdin) with the pid in <unit>.cmd; stub-systemctl stop TERMs that pid and its descendants (parents first) plus .pids. Run termed (TERMed mid-session, STUB_SLOW_CODING=30) is left ended in state with an uncommitted `services stopped (driver exited)` in its harness-log.md, which L2-05's status/gc checks can use.
- **Discovery** (affects L2-06): Review findings left for L2-06: a TERM during run_init runs the teardown while the init may still be starting containers; a TERM during finish's own teardown runs a second teardown concurrently; TEARDOWN_CMD is picked at load_config, so a teardown.sh added mid-run is seen only after a config reload; the trap's note stays uncommitted after a kill.
- **Proposed change:** L2-03 step 3 names one teardown.marker; the plan's hook writes one per why (teardown-done.marker here) and orders teardown and stop in systemd.log rather than by mtime (plan §11).
- **Proposed change:** L2-04 step 1's verify `mem_gate || run_init` is done in L2-03.
- *11-L2-03 · claude-opus-5-5*

### 2026-10-25 16:30 · L2-02 · passes

run_init now stops harness-<run>-svc, then runs INIT_CMD in it (MemoryMax=SVC_MEMORY_MAX 3G, timeout -k 10s INIT_TIMEOUT 10m, stdin /dev/null); a refused unit notes `init ran uncapped`. Stub systemd-run refuses a still-loaded unit like real systemd. 4 checks (3 seen RED), decision file, arch/README/config docs. Tests 270 → 274.

- **Files:** lib/driver.sh, lib/config.sh, templates/user/config.sh, tests/run.sh, tests/stub-systemd-run.sh, docs/architecture.md, README.md, journal/decisions/2026-10-25-services-scope.md
- **Verified:** RED on a git copy with the old driver: the dup-unit, the stop-then-scope order and the backgrounded-init checks failed (bare check passed, as a regression guard). GREEN: lib/check.sh green in 473 s, 274/274; no harness-test-* unit or sleep 300 left. Opus review: 0 Critical/Important, 3 Minor (2 fixed).
- **Tests:** 270 → 274
- **Dead end:** running the RED suite on a tar copy of the tree without git — the eval checks need a git repo; git init + commit in the copy works
- **Discovery** (affects L2-03, L2-04, L2-05): stub-systemd-run.sh now refuses a unit whose .alive is set and that is .running or holds a live pid (fixtures/systemd-run-unit-exists.txt, exit 1, command not run). Any new code that reuses a unit name must scope_stop it first.
- **Discovery** (affects L2-03): run_init sets SVC_UP=1 before the start (plan §1); services_down (L2-03) can key on it. The bp1 check (tests/run.sh ~960) counts `stop harness-bp1-svc.scope` >= 2, so finish's stop in L2-03 keeps it green.
- **Discovery** (affects L2-06): GNU timeout (no --foreground) kills its whole process group on expiry, so an init that times out takes the servers it already backgrounded with it; docs say so. Plan's `timeout -k 10s 10m` kept as the step names it.
- **Discovery** (affects L2-05, L2-06): Review Minor not fixed: run ids are unique per project only, and scope_unit maps . to -, so two projects' runs with the same id share harness-<id>-svc and run_init's stop-first would kill the other's services (was: refused, bare). gc's unit match (L2-05) has the same ambiguity; consider the project in the unit name or refusing a duplicate id.
- **Question for Michael:** D *default* (decisions/2026-10-25-services-scope): the init's stdin is now /dev/null instead of the tmux pane, so an interactive init prompt fails fast instead of waiting for you in the window. OK?
- *10-L2-02 · claude-opus-5-5*

### 2026-10-25 16:02 · L2-01 · passes

Wrote docs/plans/2026-10-25-L2-run-services.md: svc scope in run_init (stop first), services_down/SVC_UP, the trap (session scope too), six stop points, suite observation per stop point, gc's unit match rule and status lines. Captured 4 real fixtures. An Opus review found 1 Critical and 4 Important plan bugs; all fixed in the plan. Tests 270 → 270.

- **Files:** docs/plans/2026-10-25-L2-run-services.md, tests/fixtures/systemctl-show-current.txt, tests/fixtures/systemctl-show-current-gone.txt, tests/fixtures/systemctl-list-units-described.txt, tests/fixtures/systemd-run-unit-exists.txt
- **Verified:** check.sh: green in 454 s, 270/270; fixtures captured from real 64M harness-test-<pid>-cur/-dup scopes, each stopped; list-units 'harness-test-*' printed nothing afterwards; bash TERM probe: EXIT trap ran in 13 ms, child lived on
- **Tests:** 270 → 270
- **Dead end:** stub-systemd-run recording the command pid in <unit>.pids — pids count in the stub's TasksCurrent, so every clean session would 'leave 1 process'; plan uses <unit>.cmd plus a tree kill
- **Dead end:** INIT_CMD for check 6.9 in the user config — the project's .harness/config.sh is sourced after it and wins (lib/config.sh:31); use a dproj project
- **Discovery** (affects L2-03): Bash runs the EXIT trap at once on SIGTERM while a foreground child runs, and the child lives on: a TERM to the driver mid-session leaves claude running in harness-<run>-s<n>. Plan §4: the trap stops S_UNIT first, then services_down.
- **Discovery** (affects L2-05): A SIGKILLed driver leaves no `ended` (the driver removes it at start; only finish and the trap write it), so gc stops units of runs with no live driver.pid, ended or not (plan §7.1).
- **Discovery** (affects L2-02): systemd-run with a unit name still loaded exits 1: 'Failed to start transient scope unit: Unit <u>.scope was already loaded or has a fragment file.' (fixtures/systemd-run-unit-exists.txt). run_init must stop the old svc scope first.
- **Discovery** (affects L2-03, L2-04, L2-05): verify() runs run_init before its mem_gate, so a memory wait leaves the verify without services: L2-04 makes it `mem_gate || run_init`. bin/harness is set -euo pipefail: TEARDOWN_CMD's default line and cmd_status's systemctl calls must always succeed (plan §2, §7.2).
- **Question for Michael:** D2 default: the driver's EXIT trap also stops the running session's scope, not only the services. OK?
- **Question for Michael:** gc stops a run's units when its driver is dead even without `ended` (a SIGKILL writes none), not only for ended runs as the spec says. OK?
- **Proposed change:** L2-03 step 3: one marker per why (teardown-done.marker), and the order is read from systemd.log (the teardown logs a record there), not from the marker's mtime
- **Proposed change:** L2-03 step 4: the TERM goes to driver.pid (--foreground runs the driver as a child of bin/harness); the trap also stops the session's scope
- **Proposed change:** L2-04 step 2: the stub sets PAUSE ($STATE/PAUSE) and the suite resumes with harness resume (no session runs during a pause); the pause branch commits its note
- **Proposed change:** L2-04: verify() needs `mem_gate || run_init`
- **Proposed change:** L2-05 step 1: units qualify with no live driver.pid, `ended` or not; gc prints its own `+ stopped <unit> (<run> ended|: driver gone)` lines rather than act's raw argv
- *09-L2-01 · claude-opus-5-5*

### 2026-10-25 15:34 · verify L1 · passes

All 8 L1 features hold: suite re-run 270/270, artifacts, stubs, fixtures, docs and decision files checked against each step; no leftover harness-test units.

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| L1-01 | 1 | re-ran bash tests/run.sh and inspected files/greps for this step | read docs/plans/2026-10-25-L1-capped-sessions.md and listed fixtures; files present, real captures, config keys in plan; suite 270/270 | yes |
| L1-01 | 2 | re-ran bash tests/run.sh and inspected files/greps for this step | read docs/plans/2026-10-25-L1-capped-sessions.md and listed fixtures; files present, real captures, config keys in plan; suite 270/270 | yes |
| L1-01 | 3 | re-ran bash tests/run.sh and inspected files/greps for this step | read docs/plans/2026-10-25-L1-capped-sessions.md and listed fixtures; files present, real captures, config keys in plan; suite 270/270 | yes |
| L1-01 | 4 | re-ran bash tests/run.sh and inspected files/greps for this step | read docs/plans/2026-10-25-L1-capped-sessions.md and listed fixtures; files present, real captures, config keys in plan; suite 270/270 | yes |
| L1-01 | 5 | re-ran bash tests/run.sh and inspected files/greps for this step | read docs/plans/2026-10-25-L1-capped-sessions.md and listed fixtures; files present, real captures, config keys in plan; suite 270/270 | yes |
| L1-01 | 6 | re-ran bash tests/run.sh and inspected files/greps for this step | read docs/plans/2026-10-25-L1-capped-sessions.md and listed fixtures; files present, real captures, config keys in plan; suite 270/270 | yes |
| L1-02 | 1 | re-ran bash tests/run.sh and inspected files/greps for this step | read lib/scope.sh + stubs; suite checks 'scope.sh: scope_run wraps…', 'scope_stop…', 'run id becomes a unit name', 'STUB_NO_SYSTEMD', 'a real 64M scope kills… exit 137 and leaves no unit' PASS; list-units harness-test-* empty; decision file present | yes |
| L1-02 | 2 | re-ran bash tests/run.sh and inspected files/greps for this step | read lib/scope.sh + stubs; suite checks 'scope.sh: scope_run wraps…', 'scope_stop…', 'run id becomes a unit name', 'STUB_NO_SYSTEMD', 'a real 64M scope kills… exit 137 and leaves no unit' PASS; list-units harness-test-* empty; decision file present | yes |
| L1-02 | 3 | re-ran bash tests/run.sh and inspected files/greps for this step | read lib/scope.sh + stubs; suite checks 'scope.sh: scope_run wraps…', 'scope_stop…', 'run id becomes a unit name', 'STUB_NO_SYSTEMD', 'a real 64M scope kills… exit 137 and leaves no unit' PASS; list-units harness-test-* empty; decision file present | yes |
| L1-02 | 4 | re-ran bash tests/run.sh and inspected files/greps for this step | read lib/scope.sh + stubs; suite checks 'scope.sh: scope_run wraps…', 'scope_stop…', 'run id becomes a unit name', 'STUB_NO_SYSTEMD', 'a real 64M scope kills… exit 137 and leaves no unit' PASS; list-units harness-test-* empty; decision file present | yes |
| L1-02 | 5 | re-ran bash tests/run.sh and inspected files/greps for this step | read lib/scope.sh + stubs; suite checks 'scope.sh: scope_run wraps…', 'scope_stop…', 'run id becomes a unit name', 'STUB_NO_SYSTEMD', 'a real 64M scope kills… exit 137 and leaves no unit' PASS; list-units harness-test-* empty; decision file present | yes |
| L1-02 | 6 | re-ran bash tests/run.sh and inspected files/greps for this step | read lib/scope.sh + stubs; suite checks 'scope.sh: scope_run wraps…', 'scope_stop…', 'run id becomes a unit name', 'STUB_NO_SYSTEMD', 'a real 64M scope kills… exit 137 and leaves no unit' PASS; list-units harness-test-* empty; decision file present | yes |
| L1-02 | 7 | re-ran bash tests/run.sh and inspected files/greps for this step | read lib/scope.sh + stubs; suite checks 'scope.sh: scope_run wraps…', 'scope_stop…', 'run id becomes a unit name', 'STUB_NO_SYSTEMD', 'a real 64M scope kills… exit 137 and leaves no unit' PASS; list-units harness-test-* empty; decision file present | yes |
| L1-02 | 8 | re-ran bash tests/run.sh and inspected files/greps for this step | read lib/scope.sh + stubs; suite checks 'scope.sh: scope_run wraps…', 'scope_stop…', 'run id becomes a unit name', 'STUB_NO_SYSTEMD', 'a real 64M scope kills… exit 137 and leaves no unit' PASS; list-units harness-test-* empty; decision file present | yes |
| L1-03 | 1 | re-ran bash tests/run.sh and inspected files/greps for this step | config.sh/template keys grep; checks 'sessions run in harness-<run>-s<n> with the three caps and timeout -k 30s', 'scope is stopped after it returns', 'no user systemd…', 'killed at its memory cap (STUB_OOM)', leftover note check PASS; bin/harness line 177 passes stubs; arch §7 row; bash -n ok | yes |
| L1-03 | 2 | re-ran bash tests/run.sh and inspected files/greps for this step | config.sh/template keys grep; checks 'sessions run in harness-<run>-s<n> with the three caps and timeout -k 30s', 'scope is stopped after it returns', 'no user systemd…', 'killed at its memory cap (STUB_OOM)', leftover note check PASS; bin/harness line 177 passes stubs; arch §7 row; bash -n ok | yes |
| L1-03 | 3 | re-ran bash tests/run.sh and inspected files/greps for this step | config.sh/template keys grep; checks 'sessions run in harness-<run>-s<n> with the three caps and timeout -k 30s', 'scope is stopped after it returns', 'no user systemd…', 'killed at its memory cap (STUB_OOM)', leftover note check PASS; bin/harness line 177 passes stubs; arch §7 row; bash -n ok | yes |
| L1-03 | 4 | re-ran bash tests/run.sh and inspected files/greps for this step | config.sh/template keys grep; checks 'sessions run in harness-<run>-s<n> with the three caps and timeout -k 30s', 'scope is stopped after it returns', 'no user systemd…', 'killed at its memory cap (STUB_OOM)', leftover note check PASS; bin/harness line 177 passes stubs; arch §7 row; bash -n ok | yes |
| L1-03 | 5 | re-ran bash tests/run.sh and inspected files/greps for this step | config.sh/template keys grep; checks 'sessions run in harness-<run>-s<n> with the three caps and timeout -k 30s', 'scope is stopped after it returns', 'no user systemd…', 'killed at its memory cap (STUB_OOM)', leftover note check PASS; bin/harness line 177 passes stubs; arch §7 row; bash -n ok | yes |
| L1-03 | 6 | re-ran bash tests/run.sh and inspected files/greps for this step | config.sh/template keys grep; checks 'sessions run in harness-<run>-s<n> with the three caps and timeout -k 30s', 'scope is stopped after it returns', 'no user systemd…', 'killed at its memory cap (STUB_OOM)', leftover note check PASS; bin/harness line 177 passes stubs; arch §7 row; bash -n ok | yes |
| L1-03 | 7 | re-ran bash tests/run.sh and inspected files/greps for this step | config.sh/template keys grep; checks 'sessions run in harness-<run>-s<n> with the three caps and timeout -k 30s', 'scope is stopped after it returns', 'no user systemd…', 'killed at its memory cap (STUB_OOM)', leftover note check PASS; bin/harness line 177 passes stubs; arch §7 row; bash -n ok | yes |
| L1-03 | 8 | re-ran bash tests/run.sh and inspected files/greps for this step | config.sh/template keys grep; checks 'sessions run in harness-<run>-s<n> with the three caps and timeout -k 30s', 'scope is stopped after it returns', 'no user systemd…', 'killed at its memory cap (STUB_OOM)', leftover note check PASS; bin/harness line 177 passes stubs; arch §7 row; bash -n ok | yes |
| L1-03 | 9 | re-ran bash tests/run.sh and inspected files/greps for this step | config.sh/template keys grep; checks 'sessions run in harness-<run>-s<n> with the three caps and timeout -k 30s', 'scope is stopped after it returns', 'no user systemd…', 'killed at its memory cap (STUB_OOM)', leftover note check PASS; bin/harness line 177 passes stubs; arch §7 row; bash -n ok | yes |
| L1-04 | 1 | re-ran bash tests/run.sh and inspected files/greps for this step | checks 'metrics.mjs: append writes mem_peak_mb', 'metrics.jsonl: every session line has mem_peak_mb', 'null when uncapped', 'report.md lists… peaks over 2 GB' PASS; arch §11 line 319, README Memory row; decision file; node --check ok | yes |
| L1-04 | 2 | re-ran bash tests/run.sh and inspected files/greps for this step | checks 'metrics.mjs: append writes mem_peak_mb', 'metrics.jsonl: every session line has mem_peak_mb', 'null when uncapped', 'report.md lists… peaks over 2 GB' PASS; arch §11 line 319, README Memory row; decision file; node --check ok | yes |
| L1-04 | 3 | re-ran bash tests/run.sh and inspected files/greps for this step | checks 'metrics.mjs: append writes mem_peak_mb', 'metrics.jsonl: every session line has mem_peak_mb', 'null when uncapped', 'report.md lists… peaks over 2 GB' PASS; arch §11 line 319, README Memory row; decision file; node --check ok | yes |
| L1-04 | 4 | re-ran bash tests/run.sh and inspected files/greps for this step | checks 'metrics.mjs: append writes mem_peak_mb', 'metrics.jsonl: every session line has mem_peak_mb', 'null when uncapped', 'report.md lists… peaks over 2 GB' PASS; arch §11 line 319, README Memory row; decision file; node --check ok | yes |
| L1-04 | 5 | re-ran bash tests/run.sh and inspected files/greps for this step | checks 'metrics.mjs: append writes mem_peak_mb', 'metrics.jsonl: every session line has mem_peak_mb', 'null when uncapped', 'report.md lists… peaks over 2 GB' PASS; arch §11 line 319, README Memory row; decision file; node --check ok | yes |
| L1-04 | 6 | re-ran bash tests/run.sh and inspected files/greps for this step | checks 'metrics.mjs: append writes mem_peak_mb', 'metrics.jsonl: every session line has mem_peak_mb', 'null when uncapped', 'report.md lists… peaks over 2 GB' PASS; arch §11 line 319, README Memory row; decision file; node --check ok | yes |
| L1-05 | 1 | re-ran bash tests/run.sh and inspected files/greps for this step | check.sh sources scope.sh, scope_run+timeout -k 30s; checks 'exit 137 prints the memory-cap RED line', 'subset call is scoped too and never cached', TERM stops scope PASS; arch/README rows; capped-suites decision | yes |
| L1-05 | 2 | re-ran bash tests/run.sh and inspected files/greps for this step | check.sh sources scope.sh, scope_run+timeout -k 30s; checks 'exit 137 prints the memory-cap RED line', 'subset call is scoped too and never cached', TERM stops scope PASS; arch/README rows; capped-suites decision | yes |
| L1-05 | 3 | re-ran bash tests/run.sh and inspected files/greps for this step | check.sh sources scope.sh, scope_run+timeout -k 30s; checks 'exit 137 prints the memory-cap RED line', 'subset call is scoped too and never cached', TERM stops scope PASS; arch/README rows; capped-suites decision | yes |
| L1-05 | 4 | re-ran bash tests/run.sh and inspected files/greps for this step | check.sh sources scope.sh, scope_run+timeout -k 30s; checks 'exit 137 prints the memory-cap RED line', 'subset call is scoped too and never cached', TERM stops scope PASS; arch/README rows; capped-suites decision | yes |
| L1-05 | 5 | re-ran bash tests/run.sh and inspected files/greps for this step | check.sh sources scope.sh, scope_run+timeout -k 30s; checks 'exit 137 prints the memory-cap RED line', 'subset call is scoped too and never cached', TERM stops scope PASS; arch/README rows; capped-suites decision | yes |
| L1-05 | 6 | re-ran bash tests/run.sh and inspected files/greps for this step | check.sh sources scope.sh, scope_run+timeout -k 30s; checks 'exit 137 prints the memory-cap RED line', 'subset call is scoped too and never cached', TERM stops scope PASS; arch/README rows; capped-suites decision | yes |
| L1-05 | 7 | re-ran bash tests/run.sh and inspected files/greps for this step | check.sh sources scope.sh, scope_run+timeout -k 30s; checks 'exit 137 prints the memory-cap RED line', 'subset call is scoped too and never cached', TERM stops scope PASS; arch/README rows; capped-suites decision | yes |
| L1-06 | 1 | re-ran bash tests/run.sh and inspected files/greps for this step | checks 'mem_available_gb reads the real meminfo fixture', 'memory gate: under 5 GB…', '9 GB passes without a note' PASS; bin/harness passes HARNESS_MEMINFO/MEM_POLL; arch gate row; memory-gate decision | yes |
| L1-06 | 2 | re-ran bash tests/run.sh and inspected files/greps for this step | checks 'mem_available_gb reads the real meminfo fixture', 'memory gate: under 5 GB…', '9 GB passes without a note' PASS; bin/harness passes HARNESS_MEMINFO/MEM_POLL; arch gate row; memory-gate decision | yes |
| L1-06 | 3 | re-ran bash tests/run.sh and inspected files/greps for this step | checks 'mem_available_gb reads the real meminfo fixture', 'memory gate: under 5 GB…', '9 GB passes without a note' PASS; bin/harness passes HARNESS_MEMINFO/MEM_POLL; arch gate row; memory-gate decision | yes |
| L1-06 | 4 | re-ran bash tests/run.sh and inspected files/greps for this step | checks 'mem_available_gb reads the real meminfo fixture', 'memory gate: under 5 GB…', '9 GB passes without a note' PASS; bin/harness passes HARNESS_MEMINFO/MEM_POLL; arch gate row; memory-gate decision | yes |
| L1-06 | 5 | re-ran bash tests/run.sh and inspected files/greps for this step | checks 'mem_available_gb reads the real meminfo fixture', 'memory gate: under 5 GB…', '9 GB passes without a note' PASS; bin/harness passes HARNESS_MEMINFO/MEM_POLL; arch gate row; memory-gate decision | yes |
| L1-06 | 6 | re-ran bash tests/run.sh and inspected files/greps for this step | checks 'mem_available_gb reads the real meminfo fixture', 'memory gate: under 5 GB…', '9 GB passes without a note' PASS; bin/harness passes HARNESS_MEMINFO/MEM_POLL; arch gate row; memory-gate decision | yes |
| L1-07 | 1 | re-ran bash tests/run.sh and inspected files/greps for this step | checks 'every session passes --strict-mcp-config…', 'worktree with .mcp.json…', 'rendered coding prompt has the deepEqual rule' PASS; decision file; arch line 51; README line 59 | yes |
| L1-07 | 2 | re-ran bash tests/run.sh and inspected files/greps for this step | checks 'every session passes --strict-mcp-config…', 'worktree with .mcp.json…', 'rendered coding prompt has the deepEqual rule' PASS; decision file; arch line 51; README line 59 | yes |
| L1-07 | 3 | re-ran bash tests/run.sh and inspected files/greps for this step | checks 'every session passes --strict-mcp-config…', 'worktree with .mcp.json…', 'rendered coding prompt has the deepEqual rule' PASS; decision file; arch line 51; README line 59 | yes |
| L1-07 | 4 | re-ran bash tests/run.sh and inspected files/greps for this step | checks 'every session passes --strict-mcp-config…', 'worktree with .mcp.json…', 'rendered coding prompt has the deepEqual rule' PASS; decision file; arch line 51; README line 59 | yes |
| L1-07 | 5 | re-ran bash tests/run.sh and inspected files/greps for this step | checks 'every session passes --strict-mcp-config…', 'worktree with .mcp.json…', 'rendered coding prompt has the deepEqual rule' PASS; decision file; arch line 51; README line 59 | yes |
| L1-08 | 1 | re-ran bash tests/run.sh and inspected files/greps for this step | review doc with severities (1 Important, fixed RED→GREEN by named check); arch §4 Scopes row + §10 keys; README oomd/list-units lines; no decision file numbers D-H; bash -n/node --check ok; suite 270/270 | yes |
| L1-08 | 2 | re-ran bash tests/run.sh and inspected files/greps for this step | review doc with severities (1 Important, fixed RED→GREEN by named check); arch §4 Scopes row + §10 keys; README oomd/list-units lines; no decision file numbers D-H; bash -n/node --check ok; suite 270/270 | yes |
| L1-08 | 3 | re-ran bash tests/run.sh and inspected files/greps for this step | review doc with severities (1 Important, fixed RED→GREEN by named check); arch §4 Scopes row + §10 keys; README oomd/list-units lines; no decision file numbers D-H; bash -n/node --check ok; suite 270/270 | yes |
| L1-08 | 4 | re-ran bash tests/run.sh and inspected files/greps for this step | review doc with severities (1 Important, fixed RED→GREEN by named check); arch §4 Scopes row + §10 keys; README oomd/list-units lines; no decision file numbers D-H; bash -n/node --check ok; suite 270/270 | yes |
| L1-08 | 5 | re-ran bash tests/run.sh and inspected files/greps for this step | review doc with severities (1 Important, fixed RED→GREEN by named check); arch §4 Scopes row + §10 keys; README oomd/list-units lines; no decision file numbers D-H; bash -n/node --check ok; suite 270/270 | yes |

- *152548-verify-L1 · claude-sonnet-5-5*

### 2026-10-25 15:25 · L1-08 · passes

Opus review of the L1 diff in docs/plans/2026-10-25-L1-review.md: 7 findings (1 Important, 4 Minor, 2 Simpl.). Fixed RED→GREEN: mem_gate moved out of session() to before the attempt bump/prompt (stop and deadline seen after a wait), refused scope noted, HARNESS_MEM_POLL=0 ends. Docs: arch §4 Scopes row, §7; README Memory row and After the run. Tests 267 → 270.

- **Files:** lib/driver.sh, lib/scope.sh, tests/run.sh, tests/stub-claude.sh, tests/stub-systemd-run.sh, tests/fixtures/systemd-run-bad-property.txt, docs/plans/2026-10-25-L1-review.md, docs/architecture.md, README.md, journal/decisions/2026-10-25-memory-gate.md, journal/decisions/2026-10-25-scoped-sessions.md
- **Verified:** full suite 270/270 (check: green in 459 s); each new check run alone failed before its fix (gate-stop: coding session ran; refused scope: no note; poll 0: timeout 124); bash -n on lib/*.sh, bin/harness, tests/*.sh and node --check on lib/*.mjs clean; decision files all cite the spec, finding·choice·rejected, no D-H<n>
- **Tests:** 267 → 270
- **Discovery** (affects L2, run): mem_gate now exits 1 after any wait and is called by the driver loop (after the pick, before F bump; the loop starts over once, gated=1), verify() before each round clock, and the init before run_init; session() no longer gates. L2 services_down hooks into the same place.
- **Discovery** (affects L2): scope_run sets SCOPE_BARE when systemd-run fails after the probe passed; session() notes <kind> session ran uncapped: <why>. Real systemd-run on an unparseable MemoryMax: `Failed to parse MemoryMax=bogus: Invalid argument`, exit 1, no unit (tests/fixtures/systemd-run-bad-property.txt).
- **Discovery** (affects L2): Deferred review findings for L2: check.sh stop() misses a TERM before the scope registers or on the bare fallback (orphaned suite up to CHECK_TIMEOUT); systemctl-list-units.txt fixture predates --description (recapture before parsing its DESCRIPTION column); check.sh probes a real scope every call (pass the driver SCOPE_OK down).
- *08-L1-08 · claude-opus-5-5*

### 2026-10-25 15:06 · L1-07 · passes

session() always passes --strict-mcp-config, plus --mcp-config <wt>/.mcp.json when the worktree has one; run.log gets an 'MCP servers:' line at run start. prompts/parts/rules.md gains the deepEqual / bounded-rerun-after-137 rule. Decision file quotes the real claude --help lines (2.1.310). Docs: architecture §3 driver row, README .mcp.json row. Tests 264 → 267.

- **Files:** lib/driver.sh, prompts/parts/rules.md, tests/run.sh, journal/decisions/2026-10-25-strict-mcp-and-deepequal-rule.md, docs/architecture.md, README.md
- **Verified:** 3 new checks failed first (264/267), then lib/check.sh full: 267/267 checks passed. Checks: every demo session's systemd-run argv has --strict-mcp-config and none --mcp-config; run mp1 on a project committing .mcp.json gets --mcp-config $T/wt/mp/mp1/.mcp.json; lib/prompt.sh renders demo's coding prompt for A with deepEqual, exit 137, --test-name-pattern.
- **Tests:** 264 → 267
- **Discovery** (affects run): prompts/parts/rules.md is only included when the worktree has a CLAUDE.md (lib/prompt.sh prompt_render), so the deepEqual rule reaches only projects with one (all of them today). The MCP line is logged to run.log beside the permissions line, not noted in harness-log.md (same for every session).
- *07-L1-07 · claude-opus-5-5*

### 2026-10-25 14:48 · L1-06 · passes

Memory gate: mem_available_gb and mem_gate in lib/scope.sh; session() calls mem_gate for init/coding/verify (not retro) before t0. Under MEM_MIN_AVAILABLE_GB=5 it notes, calls services_down memory (no-op in driver until L2), checks at once then every HARNESS_MEM_POLL s up to MEM_WAIT_MAX=30m, then starts anyway. Config, template, docs, decision. Tests 260 → 264.

- **Files:** lib/scope.sh, lib/driver.sh, lib/config.sh, templates/user/config.sh, tests/run.sh, docs/architecture.md, README.md, journal/decisions/2026-10-25-memory-gate.md
- **Verified:** bash tests/run.sh 264/264; lib/check.sh green in 453 s; new checks: mem_available_gb on the real fixture (9), mem_gate unit (still-low and freed-by-services_down paths), run lowmem (2 GB copy, MEM_WAIT_MAX=2s: both notes once per init/coding/verify session, 3/3 passing), demo has no memory note; bash -n on every touched shell file
- **Tests:** 260 → 264
- **Discovery** (affects L2): mem_gate lives in lib/scope.sh (not the driver as the plan said) and calls services_down only when declared; driver.sh defines a no-op services_down() unless one exists. L2 should define the real one before or instead of it (driver.sh:57: `declare -F services_down || services_down() { :; }`).
- **Discovery** (affects L2): mem_gate checks right after services_down before its first sleep, so a teardown that frees memory starts the session at once (note 'memory: <n> GB available after 0 s; starting the session').
- **Question for Michael:** D default: MEM_MIN_AVAILABLE_GB=5 and MEM_WAIT_MAX=30m (the audit's figures), starting the session anyway after the wait rather than parking. Keep?
- *06-L1-06 · claude-opus-5-5*

### 2026-10-25 14:30 · L1-05 · passes

check.sh runs full and subset suites in harness-<run>-check-<pid> (MemoryMax=CHECK_MEMORY_MAX 3G, no MemoryHigh) under timeout -k 30s CHECK_TIMEOUT 15m, stopped after; RED lines for the cap (scope_capped) and the timeout; a TERM/INT/HUP stops the check scope; prompt_env exports prefix/cap/timeout; dur_s in scope.sh. Tests 254 → 260.

- **Files:** lib/check.sh, lib/scope.sh, lib/prompt.sh, lib/config.sh, templates/user/config.sh, tests/run.sh, docs/architecture.md, README.md, journal/decisions/2026-10-25-capped-suites.md
- **Verified:** bash tests/run.sh 260/260; harness check.sh green in 421 s; new checks watched failing first (old RED lines, no scope; TERM check fails with the traps removed); by hand with real systemd-run under harness-test-<pid>-*, 64M, swap 0: a 256 MB node allocation → check: RED (killed at its 64M memory cap, exit 137 …), a TERM to check.sh → 143, no unit, sleep or scope file left
- **Tests:** 254 → 260
- **Dead end:** a real 64M check scope with the default 1G swap — the 256 MB allocation swapped and passed: check scopes always get scope_run's 1G MemorySwapMax (SESSION_SWAP_MAX is not exported to check.sh)
- **Discovery** (affects L1-08, L2): Only systemd-run's child moves into the check scope; check.sh stays in its caller's. Without the TERM trap, stopping a session's scope orphaned its suite in harness-<run>-check-<pid> for up to 15m. check.sh now runs the suite in the background, waits, and stops the check scope on TERM/INT/HUP (SIGKILL still can't be caught).
- **Discovery** (affects L3): check.sh leaves no scopes/<unit>.started/.show (EXIT trap); session scopes still do, one pair per session, until L3 deletes scratch.
- **Discovery** (affects L1-08): Check scopes get MemorySwapMax=1G always (template comment corrected); a suite can reach 4G before the kill.
- **Question for Michael:** CHECK_MEMORY_MAX=3G and CHECK_TIMEOUT=15m are the spec's defaults (this repo's own suite runs ~7 min, well under). D6 default: suites get no MemoryHigh. Keep both?
- **Proposed change:** L1-05 step 3: the cap line needs scope_capped (peak reached the cap), not just exit 137 in a scope, so a suite's own 137 keeps the plain RED line; the plan §7 says any scoped 137
- *05-L1-05 · claude-opus-5-5*

### 2026-10-25 14:02 · L1-04 · passes

metrics.mjs append takes a 12th arg (mem_peak_mb: number, null when uncapped) via exported metricsRow; every MET append passes $S_PEAK; report(s, metrics) adds '### Memory peaks over 2 GB' (- <feature> · <model> · <peak> MB) from metrics.jsonl beside summary.json; harness report copies metrics.jsonl into the state dir. Docs, decision file. Tests 249 → 254.

- **Files:** lib/metrics.mjs, lib/summary.mjs, lib/driver.sh, bin/harness, tests/run.sh, docs/architecture.md, README.md, journal/decisions/2026-10-25-session-memory-peaks.md
- **Verified:** lib/check.sh: 254/254 checks passed (406 s). New checks: metrics.mjs pure append (2048/''/null/undefined), summary.mjs pure report (1500 vs 2500, no section when none, no summary.json key), demo every row mem_peak_mb == 2, bare run all null, leftover run's report.md and `harness report leftover` list `- A · claude-sonnet-5-5 · 6144 MB` once. Pure checks watched failing first.
- **Tests:** 249 → 254
- **Dead end:** `grep -qxF "- A · …"` in a check — a pattern starting with '-' is read as an option: use -e
- **Dead end:** `"$H" report leftover | grep -q …` in a check — under pipefail grep -q's early exit SIGPIPEs the producer and the pipeline fails; capture into a variable first
- **Dead end:** editing tests/run.sh while a suite run was going — bash reads the script as it runs: the run goes wrong; stop it and rerun
- **Discovery** (affects L1-08): report.md's peaks section is `### Memory peaks over 2 GB` (not the plan's `##`): it nests under the run's `## <run> · <project>` heading. `harness report` now also writes $STATE/metrics.jsonl (a copy) beside $STATE/summary.json.
- *04-L1-04 · claude-opus-5-5*

### 2026-10-25 13:35 · L1-03 · passes

session() runs every claude session (init, coding, verify, retro) as timeout -k 30s SESSION_TIMEOUT inside scope harness-<run>-s<n> (5G/6G/1G, n from state/scope-seq), stops the scope after it returns, notes leftovers and cap kills; one probe per segment notes 'no user systemd'; exit 137 now spends the attempt. Tests 243 → 249.

- **Files:** lib/driver.sh, lib/config.sh, lib/scope.sh, lib/metrics.mjs, tests/run.sh, tests/stub-claude.sh, templates/user/config.sh, docs/architecture.md, journal/decisions/2026-10-25-scoped-sessions.md
- **Verified:** 6 new checks written first and seen failing (5 red, the no-note one trivially green), then lib/check.sh green: 249/249 in 405 s. Real check: systemd-run --description works on this box (Description=harness-test-<pid>-desc), no harness-test-* unit left.
- **Tests:** 243 → 249
- **Dead end:** noting the retro's leftovers inside session() — restrict nothing reverts harness-log.md after a retro; its notes are deferred (S_NOTES) until after restrict
- **Discovery** (affects L1-04): session() sets S_PEAK (scope_peak MB, empty when uncapped) and S_NOTES; who is its 4th argument (initializer, <id>, verify <m>, retro). L1-04 passes $S_PEAK to MET append.
- **Discovery** (affects L1-05, L2): scope_run now passes --description=<unit>: without it systemd made each session's whole prompt the unit's Description (user journal, systemctl status, list-units). The list-units fixture was captured without it, so its description column is the old command-line shape.
- **Discovery** (affects L1-08): Review leftovers (Minor/Important, not built): the cap note needs exit 137, so an OOM kill of a child (a build the agent ran) with claude exiting 0 goes unnoted, memory.events oom_kill would catch it; a 137 under the cap and under SESSION_TIMEOUT (oomd, global OOM) spends the attempt silently; summary.mjs labels only 124 as timeout; TasksCurrent counts threads, so one node leftover reads as ~10 'process(es)'; scope_bytes rejects decimal sizes like 6.5G; a leftover note on a fully committed session makes a WIP commit holding only harness-log.md.
- **Discovery** (affects L1-05, L1-08): A check.sh run inside a session starts its own scope (L1-05) in app.slice, i.e. outside the session's scope: the suite's memory won't count against the session's 6G cap.
- **Proposed change:** L1-08 should take the review leftovers in discoveries (cap note via memory.events oom_kill, a note for 137 below the cap, summary.mjs 137 label, decimal sizes, WIP commit for a note-only change)
- *03-L1-03 · claude-opus-5-5*

### 2026-10-25 13:05 · L1-02 · passes

lib/scope.sh (scope_available/unit/bytes/run/stop/peak/left/capped; peak read by a wrapper inside the scope, OOMPolicy=continue, bare fallback that never runs a command twice), stubs tests/stub-systemd-run.sh + stub-systemctl.sh over the real fixtures, 7 checks incl. one real 64M scope (137, peak 64, no unit left), decision file. Tests 236 → 243.

- **Files:** lib/scope.sh, tests/stub-systemd-run.sh, tests/stub-systemctl.sh, tests/run.sh, bin/harness, docs/architecture.md, journal/decisions/2026-10-25-scoped-sessions.md
- **Verified:** 7 new checks watched failing (0/6, then the not-writable one against the old wrapper), then passing; full suite via lib/check.sh 243/243 green in 376 s; systemctl --user list-units 'harness-test-*' empty after; bash -n on every touched shell file. An Opus review of the diff found 1 Important (a command could run twice when scratch is unwritable), fixed with a check, plus stub fidelity fixes.
- **Tests:** 236 → 243
- **Dead end:** running the full suite in the background while still editing tests/run.sh — bash reads the script as it runs it: the run died on a syntax error at the edit point; rerun on the final tree
- **Discovery** (affects L1-03, L1-04, L2): Stub state: stub-systemd-run.sh clears $STUB_DIR/scope/<unit>.* at each start and holds <unit>.running while the command runs; stub-systemctl.sh treats a unit as alive only while .running exists or a pid in <unit>.pids is alive and not a zombie (a real scope is collected once empty). stub claude's STUB_OOM must touch <unit>.oom from inside the command (after the start), and STUB_LEAVE_PROCESS appends to <unit>.pids.
- **Discovery** (affects L1-03, L1-05, L1-06): sd_with/sd_count (tests/run.sh, in the scope.sh block) parse $T/systemd.log; the suite exports HARNESS_SYSTEMD_RUN/SYSTEMCTL/MEMINFO/MEM_POLL and unsets HARNESS_SCOPE_PREFIX and SCOPE_OK; bin/harness already passes all four overrides to the tmux-started driver (done here, ahead of L1-03 step 7).
- **Discovery** (affects L1-03, L1-08): scope_capped is peak >= cap only; page cache counts in MemoryPeak, so L1-03 must pair it with exit 137 before noting a cap kill. The probe can pass on a box whose user manager has no memory controller delegated (caps silently ignored); this box has it (the real check sees 137 at 64M).
- **Discovery** (affects L1-03, L1-05): scope_run's bare fallback covers any systemd-run failure, including a unit name still held by a crashed segment's scope: L1-03's per-run scope-seq avoids reuse; L1-05's check-<pid> could collide only on pid reuse while an old scope still holds leftovers.
- **Proposed change:** L1-02 step 6 should read 'MemoryMax=64M, no MemoryHigh, SESSION_SWAP_MAX=0, outer timeout 30s' (plan §13: 48M/64M throttles for minutes instead of killing); the check is built that way and also asserts scope_peak = 64 and scope_capped.
- **Proposed change:** L1-02 step 3: the logged argv also carries -p OOMPolicy=continue and the wrapper (bash -c <wrap> _ <unit> <dir> <systemctl>) before the command; the check compares the first 16 lines exactly and the command's last 3.
- *02-L1-02 · claude-opus-5-5*

### 2026-10-25 12:23 · L1-01 · passes

Wrote docs/plans/2026-10-25-L1-capped-sessions.md (scope.sh API, unit names, in-scope wrapper and timeout placement, stub contract, config keys, exact notes, 24 named checks) and captured 8 real fixtures (systemctl show/list-units/stop, no-bus, meminfo). Probes found three things the spec missed: an emptied scope vanishes, OOMPolicy=stop kills the wrapper, MemoryHigh near MemoryMax stalls.

- **Files:** docs/plans/2026-10-25-L1-capped-sessions.md, tests/fixtures/systemctl-show-scope.txt, tests/fixtures/systemctl-show-scope-clean.txt, tests/fixtures/systemctl-show-scope-oom.txt, tests/fixtures/systemctl-show-gone.txt, tests/fixtures/systemctl-list-units.txt, tests/fixtures/systemctl-stop-missing.txt, tests/fixtures/systemd-no-bus.txt, tests/fixtures/meminfo.txt
- **Verified:** check.sh full run: 236/236 green in 376 s (tests/run.sh untouched). Real probes on harness-test-<pid>-* scopes (64M), each stopped; `systemctl --user list-units 'harness-*' --plain --no-legend` prints nothing afterwards. claude --help (2.1.310) has both MCP flags.
- **Tests:** 236 → 236
- **Dead end:** a real scope with MemoryHigh=48M MemoryMax=64M MemorySwapMax=0 around a 256 MB node allocation — it stalled for over 2 minutes under memory.high throttling (high events 1821, oom_kill 0) and had to be stopped by hand; MemoryMax alone kills it with 137 in ~80 ms
- **Dead end:** reading MemoryPeak with systemctl show after the command returns — a --collect scope with no processes left is gone at once: show prints MemoryPeak=[not set]; the plan reads it from a wrapper inside the scope
- **Dead end:** the in-scope wrapper with systemd's default OOMPolicy=stop — an OOM kill stops the whole scope, the wrapper dies with 143 and records nothing; -p OOMPolicy=continue keeps it and passes 137 on
- **Discovery** (affects L1-02, L1-03, L1-04): scope_run must pass -p OOMPolicy=continue and run the command under an in-scope wrapper that writes `systemctl --user show -p MemoryPeak,ControlGroup,TasksCurrent` to <scratch>/scopes/<unit>.show before exiting; leftovers = TasksCurrent - 2 (the wrapper's bash and its systemctl). Plan §2.
- **Discovery** (affects L1-02): The L1-02 real-scope check must not set MemoryHigh (it stalls instead of killing) and needs SESSION_SWAP_MAX=0 (with 1G swap a 256 MB allocation survives) and an outer timeout 30s. Plan §10, §13.
- **Discovery** (affects L1-03, L1-05): timeout -k 30s goes inside the scope, around claude or the suite: outside it would signal the wrapper's bash and leave claude alive. GNU timeout exits 137 (not 124) when -k had to KILL, so check.sh calls 137 after >= CHECK_TIMEOUT a timeout, not the cap.
- **Discovery** (affects L1-03): metrics.mjs environmental() treats an exit 137 with no result under 120 s as environmental (attempt given back); L1-03 must return null for 137 like 124 so a cap kill spends the attempt.
- **Discovery** (affects L1-02, L1-06): tests/run.sh must export HARNESS_MEMINFO to the real fixture (9 GB) and HARNESS_MEM_POLL=1 globally, or the box's real memory could gate every suite session for 30 min; and unset HARNESS_SCOPE_PREFIX inherited from the outer session.
- **Discovery** (affects L1-02, L1-03, L2): systemctl --user stop of a unit already gone exits 5 ('Unit … not loaded.'); scope_stop treats 5 as done, and the stub mirrors it (exit 0 only for a live unit).
- **Question for Michael:** D5 default: the deepEqual line goes in prompts/parts/rules.md as the spec says, but that part renders only when a project has CLAUDE.md. Move it to prompts/coding.md §2 next to Test-driven instead?
- **Question for Michael:** D6 default: suites get no MemoryHigh (only CHECK_MEMORY_MAX=3G) so a runaway test dies at once; sessions keep MemoryHigh=5G under MemoryMax=6G, which throttles (can stall up to SESSION_TIMEOUT) before killing. Keep the session gap?
- **Proposed change:** L1-02 step 6: drop MemoryHigh=48M from the real-scope check; run it with SESSION_SWAP_MAX=0 under timeout 30s (plan §10, §13)
- **Proposed change:** L1-02 step 3: -p OOMPolicy=continue and the wrapper (bash -c <wrap> _ <unit> <dir> <systemctl>) sit between -p MemorySwapMax and the command; check parts, not adjacency
- **Proposed change:** L1-03 step 5 needs environmental() in lib/metrics.mjs to return null for exit 137
- **Proposed change:** L1-04 step 3: report() needs metrics.jsonl beside summary.json as its second input
- **Proposed change:** L1-01 step 2 says stub-systemctl exits 0 for stop; the plan's stub exits 5 for a unit already gone, as the real command does
- *01-L1-01 · claude-opus-5-5*

### 2026-10-25 12:05 · init · passes

25 features: L1 8 (plan, scope.sh, scoped sessions, peaks, capped suites, memory gate, strict MCP + prompt line, review), L2 6 (plan, svc scope, teardown + trap, stop points, gc units + status, review), L3 5 (plan, scratch, tmux window, reaper, review), L4 5 (all-merged, removal, --deps, runner gc, review), L5 1 (config reload, optional). L2 after L1; L3, L4, L5 independent.

- **Discovery** (affects run): Real-command shapes to copy into fixtures (captured 2026-10-25 on this box, systemd 255): `systemctl --user show -p MemoryPeak,ControlGroup harness-test-<pid>-probe.scope` printed `ControlGroup=/user.slice/user-1000.slice/user@1000.service/app.slice/harness-test-<pid>-probe.scope` then `MemoryPeak=262144`: systemd prints properties in its own order, not the asked order, so parse by key, never by line number. `systemctl --user list-units 'harness-*' --plain --no-legend` prints nothing when none exist. The probe `systemd-run --user --scope --collect --quiet --unit=harness-test-<pid>-probe -p MemoryMax=64M true` exits 0 here.
- **Discovery** (affects L1-07, L1-01): `claude --help` (installed CLI, 2026-10-25) has both flags: `--mcp-config <configs...> Load MCP servers from JSON files or ...` and `--strict-mcp-config Only use MCP servers from --mcp-config, ...`. Quote the real lines in the L1-07 decision file.
- **Discovery** (affects run): bin/harness passes HARNESS_* overrides to the tmux-started driver window from an explicit list (bin/harness, cmd_start, the `for v in HARNESS_CLAUDE HARNESS_GH ...` loop). Every new override the suite relies on (HARNESS_SYSTEMD_RUN, HARNESS_SYSTEMCTL, HARNESS_MEMINFO, HARNESS_MEM_POLL) must be added there, or a tmux-started run silently uses the real commands.
- **Discovery** (affects L3): The supervisor window runs bare `claude` (bin/harness, cmd_start, `tmux new-window ... -n supervisor`), not $HARNESS_CLAUDE. An L3 check that needs a supervisor window on the private tmux server must put a `claude` shim on PATH pointing at tests/stub-claude.sh (the stub's interactive mode already handles no `-p`). Every existing suite run uses --foreground, so no test starts a tmux session for a run yet.
- **Discovery** (affects L2): lib/driver.sh: the one EXIT trap (near `echo $$ > "$STATE/driver.pid"`) writes `ended` and removes driver.pid; finish() ends with `exit 0`, so the trap runs after finish too: services_down must be idempotent (finish's call and the trap's call must give one `services stopped` note). `note` writes harness-log.md (committed), `log` only run.log.
- **Discovery** (affects L1-05, L3-02): lib/check.sh is called both by the driver (run_init, green) and by sessions ({{CHECK}} in prompts); it reads only HARNESS_* env vars (HARNESS_CHECK_CMD, HARNESS_SCRATCH, HARNESS_CHECK_CACHE) exported by prompt_env in lib/prompt.sh. New inputs for it (scope prefix, cap, timeout) go through prompt_env the same way.
- **Discovery** (affects run): tests/run.sh: `check "<name>" '<bash expr>'` evals its second argument; stubs log calls to $STUB_DIR (= $T) files with `===` separators (see curl_with/curl_last helpers for the parsing pattern); the suite already runs on a private tmux server (TMUX_TMPDIR=$T/tmux, HARNESS_DESK_SESSION=h-desk-test-$$) and kills it in its EXIT trap. 235 checks today; the full suite takes about 6 minutes here. Run a single new check while iterating by copying its lines into a scratch script, not by editing the suite's flow.
- **Discovery** (affects L2-05, L3-04, L4): cmd_gc in bin/harness already has `act` (dry-run prints `would: ...`, else `+ ...` and runs it), `running` (live driver or queued continuation) and `desk_open` helpers: reuse them for the unit stop (L2-05), the tmux reap (L3-04) and --deps (L4-03). The existing gc test (run 1, `harness gc proj` after demo) is the place new gc checks follow.
- **Discovery** (affects run): Config keys: defaults live in harness_config in lib/config.sh (one assignment block), the user's commented copy in templates/user/config.sh, and docs/architecture.md §10 lists every key with its default. Add every new key in all three places in the feature that introduces it.
- **Discovery** (affects L3-04, L4-04, L5-01): lib/queue.sh's exit path (after the while loop: `started=$(grep -lsx -- "$RID" "$STATE_ROOT"/*/*/runners | wc -l)`) is where L3-04's reap and L4-04's gc go, before `setsid -f "$H" debrief`. The runner's whole body is one `{ ... }` block parsed before it runs, because lib/sync.sh may rewrite the file underneath; keep new code inside that block.
- **Discovery** (affects L4-01): git 2.43 here: `git for-each-ref 'refs/heads/*'` lists only branches without a `/`; the trailing-slash prefix `refs/heads/` lists all. The suite's fake origin is $T/origin.git (bare), reached through an insteadOf rewrite of git@github.com:test/proj.git.
- **Discovery** (affects L1-02, L1-06, L2-01): Never start a real scope in the suite other than harness-test-<pid>-* with MemoryMax 64M or less, stopped in the check's own cleanup; the memory-gate fixture is a real /proc/meminfo copy with only its MemAvailable line rewritten for the low case (say so in the decision file).
- **Question for Michael:** L5 (runner config reload) is the last feature and optional per the brief; it is dropped by not being reached. Say in INBOX.md if it should be skipped outright.
- **Question for Michael:** HARNESS_CACHE defaults to ${XDG_CACHE_HOME:-~/.cache}/harness/<project>, kept across runs and boots; the spec's ~/.cache/harness/<project> is the same with XDG_CACHE_HOME unset. Change it in config if another place is wanted.
- **Question for Michael:** The memory-gate fixture is a copy of this box's /proc/meminfo with only MemAvailable edited to 2 GB for the low case (the box can't be made low during the suite); the unedited copy covers the high case. Say if a different fixture is wanted.
- *00-init · claude-fable-5-1*
