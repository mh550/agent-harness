<!-- harness: rendered from entries.jsonl after every session; edits here are overwritten -->
# Progress — run `agent-harness-2026-10-25-lifecycle` (agent-harness)

What this file is: the run's journal, rendered from `entries.jsonl` after every session, newest entry first (the full record is `progress-archive.md`; the driver's own notes are `harness-log.md`). Each entry says what one session did, what passed, what it found (discoveries) and what it needs from you (questions).

The spec is `docs/specs/2026-10-25-resource-lifecycle.md`: everything a run starts is capped by a systemd user scope and stopped when the run stops. Milestones: L1 capped sessions and suites · L2 run services, teardown hook, stop points · L3 scratch and tmux cleanup · L4 `harness gc` fixes (`--all-merged`, R9, `--deps`, the runner's gc) · L5 `MAX_PARALLEL_RUNS` reload (optional, last). L2 waits for L1; L3, L4 and L5 are independent, so a stuck feature in one never blocks the others. Each verified milestone merges into `main` by itself.

How to read the feature list: `feature_list.json` lists features in priority order; `passes` is the session's claim, the verify entry for a milestone is what counts. Steps are the checks a verifier re-runs. A build feature writes its decision file under `journal/decisions/`, its checks in `tests/run.sh` first, and its `docs/architecture.md` and `README.md` lines.

To steer: edit `INBOX.md` on this branch (GitHub app). Line 1 `status: pause` or `status: stop` takes effect before the next session; answers go under `## Answers`. Sessions never park on this run (the brief): they take the spec's default and record it in the decision file, so the questions below are for after the run.

### 2026-10-26 02:39 · L5-01 · passes

lib/queue.sh re-runs harness_config at the top of each poll and logs `MAX_PARALLEL_RUNS <old> → <new> (config reloaded)`; lowering only gates starts. A value that is no plain whole number (2x, 08) keeps the old, logged once. 3 checks (two parallel tmux-started runs in proj/proj2, held by a stub file switch), decision file, §12, README, template line. 322 → 325.

- **Files:** lib/queue.sh, tests/run.sh, tests/stub-claude.sh, journal/decisions/2026-10-25-runner-config-reload.md, docs/architecture.md, README.md, templates/user/config.sh
- **Verified:** Red first: on the old runner l5b started only after l5a ended (no reload line); the guard check failed on a reload-only copy, which started a run past a full slot. Then the L5 block 3/3 in a scratch copy of the suite (41 s), and the full suite via check.sh 325/325 in 600 s.
- **Tests:** 322 → 325
- **Dead end:** an empty MAX_PARALLEL_RUNS= as the bad-value case — bash arithmetic reads empty as 0, so starts are held anyway and the check didn't show the danger; 2x and 08 (octal) make `(( a >= x ))` fail and fall through to a start
- **Discovery** (affects run): tests/stub-claude.sh: with $STUB_DIR/hold-coding present, a run's coding sessions touch $STUB_DIR/held-<run> and wait (≤180 s) for $STUB_DIR/release-<run>. It is a file switch, so it reaches tmux-started runs. STUB_* flags reach those runs through `tmux set-environment -g` on the private server (unset afterwards).
- **Discovery** (affects run): The suite now has a second throwaway project, $T/proj2: a clone with its own bare origin $T/origin2.git, reached through url.insteadOf git@github.com:test/proj2.git. It is created in the L5 block at the end of tests/run.sh.
- **Discovery** (affects run): The full suite took 600 s under check.sh this session, right at a 600 s Bash foreground limit: run it in the background.
- **Question for Michael:** MAX_PARALLEL_RUNS=0 is now accepted on reload and holds every start, a quiet way to pause the queue without stopping it. Keep that, or reject 0 like 2x? (default: kept, undocumented)
- *25-L5-01 · claude-opus-5-5*

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

## Older entries (in full in progress-archive.md)

- 2026-10-25 18:21 · L2-05 · passes · harness gc first stops the units of this project's runs with no live driver (+ stopped <u> (<run> en… ([in full](progress-archive.md))
- 2026-10-25 17:36 · L2-04 · passes · Services now also stop on pause (services_down paused, then commit+push), before a usage-limit wait … ([in full](progress-archive.md))
- 2026-10-25 17:08 · L2-03 · passes · services_down runs .harness/teardown.sh (TEARDOWN_CMD) under timeout -k 10s 2m, stops harness-<run>-… ([in full](progress-archive.md))
- 2026-10-25 16:30 · L2-02 · passes · run_init now stops harness-<run>-svc, then runs INIT_CMD in it (MemoryMax=SVC_MEMORY_MAX 3G, timeout… ([in full](progress-archive.md))
- 2026-10-25 16:02 · L2-01 · passes · Wrote docs/plans/2026-10-25-L2-run-services.md: svc scope in run_init (stop first), services_down/SV… ([in full](progress-archive.md))
- 2026-10-25 15:34 · verify L1 · passes · All 8 L1 features hold: suite re-run 270/270, artifacts, stubs, fixtures, docs and decision files ch… ([in full](progress-archive.md))
- 2026-10-25 15:25 · L1-08 · passes · Opus review of the L1 diff in docs/plans/2026-10-25-L1-review.md: 7 findings (1 Important, 4 Minor, … ([in full](progress-archive.md))
- 2026-10-25 15:06 · L1-07 · passes · session() always passes --strict-mcp-config, plus --mcp-config <wt>/.mcp.json when the worktree has … ([in full](progress-archive.md))
- 2026-10-25 14:48 · L1-06 · passes · Memory gate: mem_available_gb and mem_gate in lib/scope.sh; session() calls mem_gate for init/coding… ([in full](progress-archive.md))
- 2026-10-25 14:30 · L1-05 · passes · check.sh runs full and subset suites in harness-<run>-check-<pid> (MemoryMax=CHECK_MEMORY_MAX 3G, no… ([in full](progress-archive.md))
- 2026-10-25 14:02 · L1-04 · passes · metrics.mjs append takes a 12th arg (mem_peak_mb: number, null when uncapped) via exported metricsRo… ([in full](progress-archive.md))
- 2026-10-25 13:35 · L1-03 · passes · session() runs every claude session (init, coding, verify, retro) as timeout -k 30s SESSION_TIMEOUT … ([in full](progress-archive.md))
- 2026-10-25 13:05 · L1-02 · passes · lib/scope.sh (scope_available/unit/bytes/run/stop/peak/left/capped; peak read by a wrapper inside th… ([in full](progress-archive.md))
- 2026-10-25 12:23 · L1-01 · passes · Wrote docs/plans/2026-10-25-L1-capped-sessions.md (scope.sh API, unit names, in-scope wrapper and ti… ([in full](progress-archive.md))
- 2026-10-25 12:05 · init · passes · 25 features: L1 8 (plan, scope.sh, scoped sessions, peaks, capped suites, memory gate, strict MCP + … ([in full](progress-archive.md))
