<!-- harness: rendered from entries.jsonl after every session; edits here are overwritten -->
# Progress — run `agent-harness-2026-10-25-lifecycle` (agent-harness)

What this file is: the run's journal, rendered from `entries.jsonl` after every session, newest entry first (the full record is `progress-archive.md`; the driver's own notes are `harness-log.md`). Each entry says what one session did, what passed, what it found (discoveries) and what it needs from you (questions).

The spec is `docs/specs/2026-10-25-resource-lifecycle.md`: everything a run starts is capped by a systemd user scope and stopped when the run stops. Milestones: L1 capped sessions and suites · L2 run services, teardown hook, stop points · L3 scratch and tmux cleanup · L4 `harness gc` fixes (`--all-merged`, R9, `--deps`, the runner's gc) · L5 `MAX_PARALLEL_RUNS` reload (optional, last). L2 waits for L1; L3, L4 and L5 are independent, so a stuck feature in one never blocks the others. Each verified milestone merges into `main` by itself.

How to read the feature list: `feature_list.json` lists features in priority order; `passes` is the session's claim, the verify entry for a milestone is what counts. Steps are the checks a verifier re-runs. A build feature writes its decision file under `journal/decisions/`, its checks in `tests/run.sh` first, and its `docs/architecture.md` and `README.md` lines.

To steer: edit `INBOX.md` on this branch (GitHub app). Line 1 `status: pause` or `status: stop` takes effect before the next session; answers go under `## Answers`. Sessions never park on this run (the brief): they take the spec's default and record it in the decision file, so the questions below are for after the run.

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

## Older entries (in full in progress-archive.md)

- 2026-10-25 15:25 · L1-08 · passes · Opus review of the L1 diff in docs/plans/2026-10-25-L1-review.md: 7 findings (1 Important, 4 Minor, … ([in full](progress-archive.md))
- 2026-10-25 15:06 · L1-07 · passes · session() always passes --strict-mcp-config, plus --mcp-config <wt>/.mcp.json when the worktree has … ([in full](progress-archive.md))
- 2026-10-25 14:48 · L1-06 · passes · Memory gate: mem_available_gb and mem_gate in lib/scope.sh; session() calls mem_gate for init/coding… ([in full](progress-archive.md))
- 2026-10-25 14:30 · L1-05 · passes · check.sh runs full and subset suites in harness-<run>-check-<pid> (MemoryMax=CHECK_MEMORY_MAX 3G, no… ([in full](progress-archive.md))
- 2026-10-25 14:02 · L1-04 · passes · metrics.mjs append takes a 12th arg (mem_peak_mb: number, null when uncapped) via exported metricsRo… ([in full](progress-archive.md))
- 2026-10-25 13:35 · L1-03 · passes · session() runs every claude session (init, coding, verify, retro) as timeout -k 30s SESSION_TIMEOUT … ([in full](progress-archive.md))
- 2026-10-25 13:05 · L1-02 · passes · lib/scope.sh (scope_available/unit/bytes/run/stop/peak/left/capped; peak read by a wrapper inside th… ([in full](progress-archive.md))
- 2026-10-25 12:23 · L1-01 · passes · Wrote docs/plans/2026-10-25-L1-capped-sessions.md (scope.sh API, unit names, in-scope wrapper and ti… ([in full](progress-archive.md))
- 2026-10-25 12:05 · init · passes · 25 features: L1 8 (plan, scope.sh, scoped sessions, peaks, capped suites, memory gate, strict MCP + … ([in full](progress-archive.md))
