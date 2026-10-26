# P1 · One lane at a time: the lane process, the record lock, the scheduler, the coordinator: plan

Spec: `docs/specs/2026-10-26-lanes.md` §P1 (items 1–11) and its Names and Config lines. Features P1-02 to P1-05; this
file is P1-01. P1 is the serial case: `MAX_LANES=1` (the default in code) runs one lane at a time, and from the
outside a run behaves as today except that its record travels on `harness/<run>` and its code on lane branches.
P2 turns the second lane on (admission, re-base, slot reuse, record PR, status). Line numbers are `lib/driver.sh` at
`a084543` (768 lines).

## 1. Names (fixed)

| What | Name |
|---|---|
| Record branch | `harness/<run>` (as today); its worktree `$WT_ROOT/<project>/<run>` (meta.env's `WT`, unchanged) |
| Lane branch | `harness-lane/<run>/<m>` (git refuses `harness/<run>/<m>` beside `harness/<run>`) |
| Tag, PR head | `run/<run>/<m>`, `harness-merge/<run>-<m>` (as today) |
| Slot worktree | `$WT_ROOT/<project>/lanes/<run>/slot-<k>`, `k < MAX_LANES` (P1: always `slot-0`) |
| Units | `harness-<run>-<m>-s<n>`, `harness-<run>-<m>-check-<pid>`, `harness-<run>-<m>-svc`; the run-level `harness-<run>-s<n>` and `harness-<run>-svc` stay for the initializer, its init and the retro |
| Scratch | `$SCRATCH/lanes/<m>` (the lane's `HARNESS_SCRATCH`: its init.out, check.out, the session's files) |
| Lane state | `$STATE/lanes/<m>/{pid,port,slot,exit,exclude}` plus the per-lane copies in §4 |
| Record lock | `$STATE/record.lock` |
| Shared library | **`lib/record.sh`**, sourced by `lib/driver.sh` (the coordinator) and `lib/lane.sh` |
| Features with no milestone | one lane `default` (branch `harness-lane/<run>/default`), opened first |

Variables both processes use: `RWT` (the record worktree, absolute), `REC=$RWT/.harness/runs/<run>` (the record,
absolute), `RUN_DIR=.harness/runs/<run>` (relative, what prompts render; in a lane it is the slot's materialized
copy), `LIST=$REC/feature_list.json` (the record's list), `RBRANCH=harness/<run>`. In a lane only: `WT` = the slot,
`BRANCH` = the lane branch, `SLIST=$WT/$RUN_DIR/feature_list.json`, `LANE`, `LANE_SLOT`, `LANE_PORT`,
`LDIR=$STATE/lanes/$LANE`. `gh_url` always names `RBRANCH` (the phone's links point at the record, never at a lane
branch: the "Click: …/blob/harness/demo/…" checks keep their text only if it does).

Lane exit codes, with the reason also written as one line `<code> <reason>` to `$STATE/lanes/<m>/exit`:

| Code | Meaning | Reason line, e.g. | The coordinator |
|---|---|---|---|
| 0 | verified and merged; or proposed (`pr`); or verified with its PR waiting on a dependency | `0 M1 merged` | reaps, runs `merge_milestones`, goes on |
| 10 | given up `<id>` (nothing left to try in `<m>`) | `10 given up A` | reaps, goes on |
| 11 | parked `<id>` | `11 parked A` | reaps, goes on (an INBOX answer reopens it) |
| 12 | needs Michael: verify (thin, red, failed), merge (conflict, refused, main moved), base conflict, `feature-list edits` | `12 M1 needs Michael: verify evidence too thin` | reaps; `feature-list edits` ends the run as today |
| 13 | limit ended: `session cap (<N>)`, `usage limit (<n> sessions refused in a row)`, `weekly budget (<why>)` | `13 session cap (14)` | waits for every lane, `finish "<reason>"` |
| 14 | stopped (STOP or `status: stop`) | `14 stopped` | waits for every lane, `finish "$(stop_why)"` |
| 15 | deadline | `15 deadline` | waits for every lane, `finish "deadline"` |

## 2. The record lock

The helper, in `lib/record.sh`, is the spec's exact form, `record() { flock 9; "$@"; } 9> "$STATE/record.lock"`, defined
under the name `_record`, plus a guard so a wrapped function may call `note` (itself
wrapped) without a second `flock` on a new descriptor, which would deadlock the process against itself:

```bash
_record() { flock 9; "$@"; } 9> "$STATE/record.lock"   # the spec's helper: the lock is held while "$@" runs, released when fd 9 closes
record() { (( ${REC_HELD:-0} )) && { "$@"; return; }; REC_HELD=1; _record "$@"; local rc=$?; REC_HELD=0; return $rc; }
```

`HARNESS_RECORD_DELAY=<s>` (tests only, unset everywhere else): `_record` sleeps that long after taking the lock, so
a check can interleave two writers. It runs in the caller's shell, so counters it sets persist.

**What it wraps** (every write to `$RWT` or to shared run state; each call is seconds, sessions run outside it):
`take_answers`; the record `sync` (fetch and merge `origin/harness/<run>`, Michael's phone edits, then push);
`journal` (ingest, render); `note` (the append to `$REC/harness-log.md`); `MET append` to `$REC/metrics.jsonl`; the
`passes` flip (`F pass` / `F unpass` on `$LIST`); the session counter `$STATE/sessions` (replaces `n`;
`MAX_SESSIONS` is checked against it); the limit-hits counter `$STATE/limits` (replaces `limits`); `commit_all` in
`$RWT` and the push; `context` (it writes and commits `$REC/context.md`); the INBOX append of §5. Added beyond the
spec's list because they are read-modify-write files two lanes share: `F bump`/`unbump`/`grant` on
`attempts.json`, `F park`/`unpark` on `parked.json`, the `scope-seq` counter, `desk`'s commit and `LIMIT_UNTIL`'s
raise-only write.

**Never under the lock:** a session, `run_init`, `check.sh` (the red-suite `green` included), `notify`, `desk`, `gh`
calls, `sleep`. `lib/desk.sh` writes the record too: while the driver lives its `note()` appends one line to the
record's `harness-log.md` unlocked (desk.sh:132; `commit_record` returns at once, desk.sh:152); that append takes
`flock -w 10 "$STATE/record.lock"`.

**fd 9 never outlives the call:** children of a wrapped call inherit fd 9, so the network commands inside
`sync_record` (`git fetch`, `git push`: an ssh ControlPersist master would hold the lock for good) run with `9>&-`, as
`desk` (driver.sh:148) and `notify` (notify.sh:33) already close their lock fds. The coordinator's EXIT trap runs
`exec 9>&-; REC_HELD=0` before it signals and waits for the lanes: a TERM that lands while the coordinator is inside
`_record` would otherwise hold the lock while every lane's trap waits on it for its "services stopped" note.

## 3. Every function of `lib/driver.sh` and its home

`R` = `lib/record.sh` (both source it), `C` = the coordinator (`lib/driver.sh`), `L` = `lib/lane.sh`.

| Lines | Function or block | Home | Change |
|---|---|---|---|
| 23–43 | env check, `cd`, sources, `prompt_vars`, `F`/`MET`/`SUM`, `LIST LOGS ATT PARKED STATE_ROOT LIMIT_FILE USAGE LEDGER`, mkdir | R (`run_paths`) | `LIST`/`REC` absolute in the record worktree; a lane `cd`s to its slot and `prompt_vars` reads the slot's branch and the lane's port |
| 46 | `load_config` | R | a lane loads `.harness/config.sh` from its slot (main's), the coordinator from `$RWT` |
| 51–54 | cache dir, `max-attempts`, `T0`/`DEADLINE`, `waited-*` | C | `T0`, `DEADLINE` exported to lanes (`HARNESS_T0`, `HARNESS_DEADLINE`): the clock line is the segment's |
| 56–57 | `log`, `note` | R | `note` appends to `$REC/harness-log.md` under `record` |
| 63 | `services_down` | R | takes the unit, port, scratch and working directory from `SVC_UNIT`, `SVC_PORT`, `SVC_SCRATCH`, `SVC_DIR` (C: `harness-<run>-svc` in `$RWT`; L: `harness-<run>-<m>-svc` in its slot, so the teardown hook is the lane's code's); `finish` stopping a closed lane's services sets the lane's four, before the slots go; see §6 for who stops what |
| 78–81 | `notify.sh`, `deploy.sh`, `version.sh` sources | R | `gh_url` gets `RBRANCH` |
| 82 | `commit_all` | R | unchanged; record commits are `record rec_commit "<msg>"` (`( cd "$RWT" && commit_all "$1" )`) |
| 83 | `green` | R | L: the slot's tree; C: `finish` only (§7) |
| 87 | `restrict` | R | gains a third mode `runs`: revert only `.harness/runs/` (the lane-commit guard, §5). C uses `nothing` (retro) and `record` (the initializer, new: §7); L uses `record` (verify) and `runs` |
| 99–100 | refuse `main` / unknown POLICY | C and L | |
| 103–108 | `driver.pid`, `END_REASON`, EXIT trap | C | the trap first sends TERM to every live `$STATE/lanes/*/pid` and waits for them (≤ 60 s), then as today. L has its own trap (§6) |
| 111 | `sync` | R | `sync_record` (in `$RWT`, under the lock: fetch, merge, push `harness/<run>`) and `sync_lane` (push the lane branch; no fetch: only the lane and its sessions write it) |
| 121 | `sync_main` | R | L: at verify, merges `origin/main` into the lane branch; C: at start-up of a resumed run, into the record branch (keeps `.harness/config.sh` current; the branch stays record-only) |
| 130 | `take_answers` | R | under the lock, into `$REC/INBOX.md` |
| 138 | `needs_you` | R | outside the lock |
| 146 | `desk` | R | its commit and sync go through `record`; the call itself outside the lock |
| 154 | `notify_park` | L | the question from `$LDIR/question`, which the take-back saves (the copy is gone by then); the "park notification failed" `git status -- $RUN_DIR` and commit run in `$RWT` (13:289) |
| 163 | `answers_hash` | R | reads `$REC/INBOX.md` |
| 165, 172 | `control`, `stop_why` | R | read `$REC/INBOX.md` and `$STATE/STOP`/`PAUSE` |
| 179 | `demote_requests` | C | |
| 190 | `limit_wait` | R | L: before each session, its `waited-<upto>` marker in `$LDIR` (a shared marker would let the coordinator consume the wait while the lane commits, and the lane start sessions inside the window, each refused, up to `MAX_LIMIT_HITS`); C: only while no lane is alive, else it just opens nothing while the window holds |
| 201 | `prompt` | R | writes `$PROMPT` (C: `$STATE/prompt.md`; L: `$LDIR/prompt.md`) and copies it to `$STATE/prompt-<kind>.md`, the last of each kind (checks read those) |
| 208 | `clock` | R | |
| 218 | `session` | R | unit `scope_unit "$RUN_ID" "${LANE:+$LANE-}s$seq"`, `seq` from `scope-seq` under the lock (per run, all kinds, as today); the stale-`entry.json` check looks at `$RUN_DIR` in its own cwd |
| 252 | `journal` | R | the file list (`git diff … ":!$RUN_DIR"`) and `MET final` in the session's worktree; the outcome from `F passes "$SLIST"` in a lane (the claim is only in the slot until the flip; 25:5 expects `outcome: passes` on a minimal entry); then under the lock: the slot's `entry.json` moved to `$REC/entry.json`, ingest, render in `$REC`. The "edited by the session; restored" guard: record-worktree sessions as today; in a lane, the copy's `entries.jsonl` and `progress-archive.md` are compared with `$REC`'s (`cmp`) and a difference gets the same note (nothing to restore: the copy is discarded; 24:7 keeps its text) |
| 278 | `vcount` | R | reads `$REC/entries.jsonl` |
| 284 | `context` | R | builds and commits `$REC/context.md` under the lock; materialization copies it into the slot |
| 302 | `run_init` | R | L: `HARNESS_SCOPE_PREFIX=$(scope_unit "$RUN_ID" "$LANE")` exported (`prompt_env` sets the run's today, so a lane's suites would run as `harness-<run>-check-<pid>`); unit `harness-<run>-<m>-svc`, `HARNESS_PORT=$LANE_PORT`, `HARNESS_SCRATCH=$SCRATCH/lanes/<m>`, in the slot; C: the initializer's init, as today; `tests-start` once per run |
| 320 | `pr_body` | R | reads `$REC`; names `harness/<run>` as the run record; written to `$LDIR/pr-body.md` and copied to `$STATE/pr-body.md` (checks read it) |
| 331 | `verified_list` | — | **deleted** (only `touched-outside` used it) |
| 336 | `merge_one` | R | `tainted`/`held` gone; return 3 (main moved) becomes needs Michael in P1 (D1, §8); an `--open` mode pushes the PR head and opens the PR without merging (the dependency rule) |
| 373 | `merge_milestones` | R | "every verified, unmerged milestone in list order whose dependencies have `merged-<dep>`" (§8); C calls it at start-up, after each reap and in `finish`; `harness merge` too |
| 398 | `verify` | L | as it is, in the slot (§8) |
| 473 | `deadline_verify` | C + L | C decides and notes (a stop first, a limit window, else "one verify before the end") for complete, unverified milestones with no lane alive and opens verify-only lanes (`LANE_ONCE=1`); L runs `verify <m> once` for its own milestone when the deadline finds it alive |
| 487 | `verify_ready` | — | **deleted**: the lane verifies when `F milestone-done` holds; the coordinator opens a lane for a complete, unverified milestone (§9) |
| 499, 513, 527 | `retro`, `ledger`, `finish` | C | `finish` gains §7's steps |
| 572–628 | start-up: `resumed`, version, log lines, INBOX, brief, unstopped, start commit, resumed `sync_main` and config reload, `HARNESS_MERGE_ONLY` exit, journal start | C | in `$RWT`, as today |
| 632 | `deploy_check` | C | |
| 652 | `scope_available` probe | C | once per segment; `SCOPE_OK` exported so lanes never repeat the "no user systemd" note |
| 654–672 | the initializer | C | in `$RWT`; then `restrict "$istart" record initializer` (D3) |
| 674–679 | `deps-noted`, `MAX_SESSIONS=auto` | C | `MAX_SESSIONS` exported |
| 681–768 | the loop | C + L | split: §6 (lane) and §7 (coordinator) |

## 4. State layout

Unchanged, run-level (`$STATE`): `meta.env run.env port driver.pid ended run.log logs/ attempts.json parked.json
max-attempts scope-seq green/ tests-start tests-end testcount-nomatch auto-continues deploy-checked deps-noted
harness-version harness-dirty brief.md inbox.md inbox-unstopped STOP PAUSE waited-* legacy-noted entry-stale-*
teardown.out` and the per-milestone `verified-<m> needs-<m> merged-<m> proposed-<m> conflict-<m> refused-<m>
verify-rounds-<m> nomerge-<m>`. The last prompt of each kind stays `prompt-<kind>.md`, the last PR body `pr-body.md`.

New: `record.lock`; `sessions` (coding sessions started, minus those a limit gave back: today's `n`; coding logs
stay `logs/<nn>-<id>.jsonl` with `nn` from it); `limits` (refused sessions in a row: today's `limits`). Both are
**per segment**, as `n=0 limits=0` are today (driver.sh:680): the coordinator writes 0 to both at start-up, or a
continuation after a session cap would end at once (the six `dl` checks of 19);
`waits-<m>` (the "PR waits for <dep>" note given once); `lanes/<m>/pid` (the lane process; alive = open),
`port`, `slot` (`k`), `exit`, `exclude` (the slot's excludes file, §5), `prompt.md`, `before.json` (the snapshot),
`inbox-before.md`, `question`, `pr-body.md`, `tree-key` (the key of the tree it tagged, for `tests-end`),
`waited-*`, `svc-up`. `pid` is written by the coordinator (`$!`, right after `lib/lane.sh "$m" &`), never by the lane:
a lane still sourcing its libraries would otherwise look dead and be reaped or opened twice. A reap renames `exit` to
`closed` and removes `pid`; start-up removes any `pid` and `exit` an earlier segment left.

Deleted: `tainted-<m>`, `held-<m>` (and `F touched-outside`, whose only caller is gone).

## 5. The slot and the materialization

**Open** (`slot_open <m> <k>`, P1-03; the coordinator calls it from P1-04):

1. Base: `B=${BASE_REF:-origin/main}` (`harness start --base <ref>` persists `BASE_REF` in `run.env`; it replaces
   `origin/main` for the record branch and every lane). If `origin/harness-lane/<run>/<m>` exists, the lane resumes
   it instead (P1-05's `continue` rule; the one-line lookup lands in P1-03, because a segment that ended at a session
   cap mid-milestone already needs it, e.g. the deadline checks' `dl` runs).
2. First use of the slot: `git -C "$RWT" worktree add -q "$slot" -B harness-lane/<run>/<m> "$B"`. Reuse:
   `git -C "$slot" checkout -q -B harness-lane/<run>/<m> "$B"` (the slot is clean: the last lane committed and
   removed its copy; ignored build output survives).
3. Dependencies (from `F lanes`' second field, the tags of every dependency): for each tag not an ancestor of
   `origin/main` (a `pr`-held or refused dependency), `git merge --no-edit run/<run>/<dep>`. A conflict:
   `git merge --abort`, `note "<m>: its base conflicts (<dep> vs main); needs Michael"`, `touch needs-<m>`, the lane
   doesn't open (exit 12 when the lane process is the one opening it).
4. Once per repository: `git -C "$RWT" config extensions.worktreeConfig true`. Per slot:
   `git -C "$slot" config --worktree core.excludesFile "$LDIR/exclude"`, the file holding `.harness/runs/` and then
   the lines of the user's own global excludes file (`git config --global core.excludesFile`, else
   `${XDG_CONFIG_HOME:-$HOME/.config}/git/ignore`), which the worktree value would otherwise shadow. Tried on git
   2.43 in a throwaway repo: with `repositoryformatversion 0`, the slot's `git status` hides an untracked
   `.harness/runs/x/` while the main worktree still shows it (why not `.git/info/exclude`: every worktree shares it,
   and it would hide the record from the record worktree's own `git add -A`).
5. `note "lane <m> opened (slot <k>, port <n>, from <sha>)"` (`<sha>`: the slot's HEAD after step 3).

**Before each session** (coding and verify), after `run_init` and `context`, one `record materialize` call:
`rm -rf "$WT/$RUN_DIR"; mkdir -p …; cp -a "$REC/." "$WT/$RUN_DIR/"`, then `before.json` (`F snapshot "$SLIST"`) and
`inbox-before.md` taken **from the copy just made**, so a phone edit merged into `$REC` meanwhile is never counted as
the session's question nor "restored" by `F repair` (a repair counts towards `MAX_REPAIRS`).
A run whose record is tracked at the slot's base (a run whose record reached `main` through pre-lanes milestone PRs,
e.g. any continued record-only run like n8n-home-2026-10-22): first `git ls-files -z -- "$RUN_DIR" | xargs -0 -r git
update-index --skip-worktree`, so the session's `git add -A` stages none of the copy's changes (tried on git 2.43:
`add -A` stages nothing, `ls-files -v` shows `S`).

**After the session**, in this order:
1. `commit_all "WIP: <id> — uncommitted at session end (harness)"` in the slot (the copy is excluded or
   skip-worktree, so it never enters the commit); `sync_lane`.
2. The take-back, one `record` call, **before** the guard (which would otherwise delete the files it reads):
   `journal` (its `entry.json` from the copy, its outcome from `$SLIST`); the question (`node lib/notify.mjs question
   $LDIR/inbox-before.md $WT/$RUN_DIR/INBOX.md`) saved to `$LDIR/question` and inserted into `$REC/INBOX.md`
   **above** its `## Answers` line, then a blank line (appended at the end it would sit under the answers and change
   `answers_hash`, unparking the feature at once); for a verify, `F repair-verify "$SLIST" … <m>`.
3. The lane-commit guard: if `git diff --name-only $sstart HEAD -- .harness/runs/` is non-empty (a session that
   `git add -f`'d the copy), `restrict "$sstart" runs "<id>"` reverts it by a new commit, `note "<id>: a lane commit
   touched the run record; reverted"`, `sync_lane`. The `runs` mode only un-indexes an added path (`git rm --cached`,
   no `rm`): the copy is still read below.
4. The driver's own checks, outside the lock, on `$SLIST`: the limit branch, `F repair "$SLIST" $LDIR/before.json
   <id>`, the red-suite `green` and un-pass, the park (§6 step 9).
5. Under the lock: the flip, `F pass "$LIST" <id>` when `$SLIST` still passes `<id>` (never a copy of the file:
   another lane may have flipped its own feature meanwhile); for a verify, `F unpass "$LIST" <id>` for each feature of
   `<m>` the repaired `$SLIST` no longer passes; `MET append`, the notes, the record commit and `sync_record`.
6. `rm -rf "$WT/$RUN_DIR"`; with the skip-worktree case, `--no-skip-worktree` on the same paths and
   `git checkout -q HEAD -- "$RUN_DIR"`. The slot is clean again (`git status --porcelain` empty), which `checkout -B`
   on the next open and P2's `gc` rely on.

The red-suite un-pass, the limit branch and the park all act on `$SLIST` before step 5's `F pass`, so a refused
session's claim never reaches the record (today: `cp before.json`; now: nothing to undo).

## 6. The lane process (`lib/lane.sh <m>`, P1-04)

Started by the coordinator in the background (`lib/lane.sh "$m" &`), with the driver's environment plus `LANE`,
`LANE_SLOT`, `LANE_PORT`, `HARNESS_T0`, `HARNESS_DEADLINE`, `MAX_SESSIONS`, `SCOPE_OK`. Usage header, `set -uo
pipefail`, sources `config.sh prompt.sh scope.sh notify.sh record.sh`, `cd` to the slot, `load_config`, writes
`$LDIR/pid`. The loop, in today's order (lines 682–766), with `n`, `limits` and `repairs` replaced:

1. `$STATE/sessions ≥ MAX_SESSIONS` → exit 13 `session cap (<N>)` (before the verify, as today: the `dl` runs end
   "session cap (2)" with M1 complete and untagged).
2. Deadline → `deadline_verify` for `<m>` → exit 15.
3. `record take_answers; record sync_record`.
4. `control`: pause → `services_down paused`, then wait (`HARNESS_PAUSE_POLL`), the deadline checked as today; stop →
   exit 14 (the coordinator notes `stop_why` and finishes).
5. `limit_wait` (its marker in `$LDIR`).
6. `F milestone-done "$LIST" <m>` and not `verified-<m>`/`needs-<m>`: `verify <m>`; 0 → `merge_milestones <m>` (§8:
   no merge under `MERGE_POLICY=off` or with `nomerge-<m>`, the v2 and dependency rules) → exit 0 (12 with
   `nomerge-<m>`); 2 → back to 1 (a limit deferred it); 1 → exit 12 if `needs-<m>`, else
   back to 1 (a re-queued feature).
7. `weekly_over` → exit 13 `weekly budget (<why>)`.
8. `F next "$LIST" "$ATT" "$MAX_ATTEMPTS" "$PARKED" <m>`; empty → exit 11 `parked <ids>` if `F parked` lists any of
   `<m>`, else exit 10 `given up <ids>` (from `F blocked`).
9. `mem_gate` (once, as `gated` today); `record bump` (`$STATE/sessions` + 1 and `F bump`); `run_init`; `context`;
   materialize; `prompt coding`; `session coding` in `harness-<run>-<m>-s<seq>`; §5's after-steps; the limit branch
   (`F unbump`, `sessions` − 1, `limits` + 1, `MAX_LIMIT_HITS` → exit 13, `LIMIT_UNTIL`, note, record commit and
   sync); `limits` reset to 0; `F repair` on `$SLIST` (`repairs` stays a lane variable: `MAX_REPAIRS` in a row →
   exit 12 `feature-list edits`); `F passes "$SLIST" <id> && ! green` → `F unpass "$SLIST" <id>` and the note; the
   flip; `MET append … <lane>` (a 13th argument, `lane: "<m>"` in the row, P1-04); the note; the park (`F unbump`,
   `F park`, note); record commit `HARNESS: after <id> (passes=…)` and `sync_record`; `notify_park`; `desk`. §5's
   after-steps give the order; this list gives what each step does.

**EXIT trap:** `trap "" TERM INT HUP`; `scope_stop "$S_UNIT"` if a session runs; if the lane dies on a signal,
`services_down "driver exited"` (the coordinator's TERM is the driver exiting: the TERM checks keep their words);
write `exit` if the loop didn't (`12 lane exited unexpectedly`); `rm -f pid`.

**Who stops a lane's services** (D4): today the next `run_init` replaces the services silently and only the stop
points (pause, a long limit wait, the memory wait, `finish`, a signal) run the teardown with a note. The same with
lanes: a lane that closes normally leaves its `svc` scope up (`$LDIR/svc-up`); the next lane in that slot stops it
silently (`scope_stop`, as `run_init` does now) before its own init, since it reuses the port; `finish` runs
`services_down "<end reason>"` for every lane whose `svc-up` is still there; the coordinator stops the initializer's
`harness-<run>-svc` silently before opening the first lane. So a run still gets exactly one teardown and one
"services stopped (done)" note at its end.

## 7. The coordinator (`lib/driver.sh`, P1-04) and `finish`

Start-up as today (§3's rows 572–679), in `$RWT`. Then, until it finishes:

```text
start-up: echo 0 > sessions; echo 0 > limits; rm -f lanes/*/pid lanes/*/exit (an earlier segment's)
every HARNESS_LANE_POLL seconds (sleep "$POLL" & wait -n <sleep pid> <lane pids>: a lane's exit wakes it at once),
in today's order (driver.sh:682-700):
  cap: $STATE/sessions ≥ MAX_SESSIONS and no lane alive → finish "session cap (N)"
  deadline (before control, as today): note "deadline reached" once (while paused: "deadline reached while
        paused"); open nothing with features left; for complete, unverified milestones with no lane alive, the
        deadline_verify decision: stop → its note, no verify; a limit window → its note; else open verify-only lanes
        (LANE_ONCE=1, paused or not); wait for every lane; finish "deadline" (or "deadline (paused)")
  record take_answers; record sync_record; F unpark (notes as today)
  control: pause → log "paused (…)", notify, commit and sync, once per pause; open nothing
           stop  → open nothing; wait for every lane; demote_requests; note stop_why; finish it
  limit window (LIMIT_UNTIL ahead): open nothing; limit_wait itself only when no lane is alive
  weekly_over → finish "weekly budget (…)" once no lane is alive
  reap: every lanes/<m> whose pid is gone → read exit, note "lane <m> closed (<reason>)", exit → closed, free
        the slot, merge_milestones; a 13/14/15 (or 12 "feature-list edits") sets the run's end reason: open
        nothing more, wait for the rest, finish "<reason>" (14 → stop_why; 15 → "deadline", or "deadline
        (paused)" when a pause holds)
  F lanes "$LIST" "$ATT" "$MAX_ATTEMPTS" "$PARKED" "$STATE" → candidates in list order
  admission (P1): lanes alive < MAX_LANES; then slot_open (§5), start lib/lane.sh, write $! to lanes/<m>/pid
  no lane alive and no candidate → the end reason as today (lines 703–711): "done" when every feature passes;
        "blocked on <ids>"; "waiting on Michael: <ids>", which now also names needs-<m> milestones a remaining
        feature waits on (D5); else "no feature left to try"; finish
```

`finish` as today, plus, after `merge_milestones` and before the summary: wait for every lane; `services_down` for
every lane with `svc-up`; `git -C "$RWT" worktree remove --force` every slot, `worktree prune`, `rmdir` the empty
`lanes/<run>` and `lanes/`; for each `merged-<m>`, `git branch -D harness-lane/<run>/<m>` and `git push origin
--delete harness-lane/<run>/<m>`; unverified and unmerged lane branches stay. `tests-end` comes from the newest
lane's `tree-key` green marker when a lane ran this segment, else from `green` on `$RWT` as today (the `scrub`
segment that ends at its deadline before any lane). Afterwards `git worktree list` shows one worktree for the run,
the record's. `HARNESS_LANE_POLL` (default 10, the suite sets 1) joins the env list `cmd_start` passes into tmux.

## 8. Verify and merge from the lane

`verify` moves to `lib/lane.sh` as it is: `sync_main` into the lane branch (a conflict: `nomerge-<m>`, as today),
the suite cache cleared and `run_init fresh`, then per round: snapshot, `context <m>`, materialize, the verify
session in `harness-<run>-<m>-s<seq>`, `restrict "$vstart" record verify`, §5's guard and take-back,
`record rec_commit "HARNESS: journal verify <m>"`, the limit branch (no `cp before.json` needed: nothing was
flipped yet), `F evidence "$LIST" <m> "$REC/progress.md"`, the escalation; `green` on the slot's tree; `hold` →
`verified-<m>`, `git tag -a run/<run>/<m> -m "… (v3)"` at the slot's HEAD, the tag pushed, `$LDIR/tree-key`,
`note "<m> verified and tagged run/<run>/<m>"`, `record rec_commit "HARNESS: <m> verified"` and `sync_record`. The
tag is the lane tip: the base and this milestone's commits only, so no `tainted`, `held` or "stop at the first
unverified milestone" (and `grep -c 'tainted\|held' lib/driver.sh` is 0). The verify record commits keep their
subjects: "verify needs Michael goes out after the verify entry is pushed" reads `HARNESS: verify M1` on
`harness/strict` at notification time.

The lane merges through `merge_milestones <m>` (restricted to its milestone), never `merge_one` directly, so today's
two gates hold: nothing under `MERGE_POLICY=off` (driver.sh:374; eval's runs force it, and "eval run: nothing
reaches a remote" counts on it) and nothing with `nomerge-<m>` (driver.sh:447; the lane then exits 12). A direct
`merge_one` would open a PR under `off` and touch `proposed-<m>`, which also hides the v2 note of 27 and the merge
of 28. The dependency rule inside it: if every dependency of `<m>` (`F deps`, §9) has `merged-<dep>`, `merge_one <m>`;
else `merge_one <m> --open` (PR head pushed, PR opened, not merged) and `note "<m> verified; its PR waits for <dep> to
merge"` once (`waits-<m>`). `merge_milestones [<m>]` (C, the lane, and `harness merge <run>`): under `off`, nothing; for each milestone in list order,
skip `merged-`/`proposed-`, no tag, or a dependency not merged; a v2 tag keeps today's rule (merges only through
`harness merge`, noted once) but no longer stops the loop; `merge_one`. **D1**: `merge_one`'s return 3 (the tag's
tree differs from `merge-tree main tag`: main moved since the verify) becomes `note "<m> verified, but main moved
since; not merged (needs Michael)"` once per main commit (`conflict-<m>`'s pattern) and needs Michael, until P2's
re-base rule replaces it.

## 9. The scheduler (P1-02, pure)

`F lanes <list> <attempts> <max> <parked> <state dir>` → `<m>\t<base tags>` per openable milestone in list order
(`default` first). Openable: not `verified-<m>`, `needs-<m>` or open (`lanes/<m>/pid` alive); every dependency has
`verified-<dep>`; and it has a feature left to try **or every feature passes** (a complete, unverified milestone
must open to be verified: a resumed run, the `dl` deadline runs; P1-02's step 1 says only "a feature left to try":
proposed change). Its dependencies: the milestones its first feature's `after` names (a feature id counts as its
milestone), plus any milestone another of its features' `after` points into; a first feature with no `after`
depends on every earlier milestone. `F next … [<m>]` restricted to `<m>`; inside a milestone a feature with no
`after` waits on that milestone's earlier features only. `F pass <list> <id>` mirrors `unpass`. One more pure
helper the merge rule and the base need: `F deps <list> <m>` → its dependency milestones, one per line (proposed
addition to P1-02). `undeclared` and its note stay.

## 10. Checks

### 10.1 Record checks that move to the record branch (P1-03)

Counted in `tests/checks/08-scope-sh-l1-02-run-capped-services-gc-scratch.sh` (run 1, lines 76–169, and the gc
block, 306–310); the same lines are replayed silently in `13-run-2-michael-sets-desk.sh`,
`14-run-2b-stop-records.sh` and `15-run-4-same-but-queue-parked-debrief-tmux.sh` (lines 4–97): edit every copy
alike (`grep -n` the check name), so they stay identical. `tests/split.sh` is not re-run: its proof was P0's.

| Check | Asserts today | Rewrite (same intent: the record is whole on `harness/demo` and never in code) |
|---|---|---|
| "entries: the driver appends each session's entry" (08:111) | `run/demo/M2:` has no `entry.json`; its `entries.jsonl` ends with M2 | the same two on `harness/demo:` in `$T/origin.git`, plus `! git -C "$T/origin.git" cat-file -e run/demo/M2:.harness/runs/demo` (the tag carries no record) |
| "context.md carries the earlier attempt's dead end" (08:126) | `cat-file -e run/demo/M2:.harness/runs/demo/context.md` ("committed with the run record, so it merges") | `cat-file -e harness/demo:.harness/runs/demo/context.md`; the comment says "on the record branch" |
| "M1 and M2 merged into main by PRs" (08:86) | 2 `pr merge`, `on_main run/demo/M2` | text unchanged (the tags are code); the record side is the new invariant checks below |
| gc block: "gc removed the finished worktree", "gc deleted the run branch", "gc kept the tags" (08:308–310) | a branch whose only commits beyond main are record commits is deleted with its worktree | texts unchanged: `harness/demo` is now record-only from its first commit, which `record_only` already treats as done (D2); the section title becomes "gc: main has every milestone; the run branch is record-only" |
| "the driver never edits the list…" (08:161), "Click: …/blob/harness/demo/…" (08:167) | the record branch's history; links on `harness/<run>` | unchanged; they hold only if the initializer commits on the record branch and `gh_url` names `RBRANCH` |

New in 08, right after run 1's checks (before any later run merges into main; names added to
`tests/fixtures/check-names.txt`): "what lands on main is byte for byte what was verified" (`git -C
"$T/origin.git" diff --quiet run/demo/M2 main`); "no code PR touches the run record, and the record branch holds
every entry" (the stub gh records only a PR's head branch, so the diffs are read from the merges it made: for each
merge commit `c` on `main`'s first-parent history, `git diff --name-only c^1 c` lists no `.harness/runs/` path;
`jq -s length` of `harness/demo`'s `entries.jsonl` equals the `(init|coding|verify) exit` lines in `run.log` (the retro has no entry); and `git -C "$T/origin.git"
ls-tree -r main --name-only | grep -c .harness/runs/` is 0).

### 10.2 Checks whose outcome the lane rules change (not record checks)

| Check | Why it changes | Rewrite | Feature |
|---|---|---|---|
| "independent M2 verified, not merged (M1 isn't)" (13:248) | the "stop at the first unverified milestone" rule is deleted (spec item 5): M2 is `after: []`, its tag holds no M1 work, so it merges | rename to "independent M2 verified and merged alone (its tag carries no M1 work)": `on_main run/strict/M2 && [[ -n $(git -C "$T/origin.git" rev-list harness-lane/strict/M1 --not main) ]]`; the fixture line replaced | P1-03 |
| "mid-session limit: attempt given back, work kept" (16:5) | `half-A.txt` is in the lane, not the record worktree | `git -C "$T/origin.git" cat-file -e main:half-A.txt` (M1 merged) | P1-03 |
| "suite cache: a session that adds only docs/plans/x.md…" (34:39), "… edits lib/ (tracked)…" (34:41) | `HEAD:` of the record worktree has no code | `harness-lane/kyplan/M1:docs/plans/x.md`, `harness-lane/kylib/M1:lib/a.sh` on the origin (unverified at the cap, so kept) | P1-03 |
| "eval probes: the probe prompt is the driver's coding prompt" (10:137) | the driver's coding prompt renders the slot as `WT` and the lane branch | `lib/prompt.sh` as a command renders a lanes run's feature with `WT=<slot path>` and `BRANCH=harness-lane/<run>/<m>` from `$STATE/lanes/<m>/slot` (cwd stays the record worktree); check text unchanged | P1-03 |
| "each session's scope is stopped after it returns" (08:175), "every session passes --strict-mcp-config…" (08:179) | coding and verify units are `harness-demo-M1-s<n>` | the unit patterns become `harness-demo-\([A-Za-z0-9_]*-\)\?s[0-9]*` (`sd_units`, `sd_stops`, the awk regex) | P1-04 |
| "finish runs the teardown hook, then stops harness-<run>-svc, and notes it once…" (08:201) | the last init ran in `harness-demo-M2-svc` | `stop\nharness-demo-M2-svc.scope` in place of `harness-demo-svc`; the one-teardown, one-note counts hold (D4) | P1-04 |
| "PAUSE stops the services before its poll, and the next init starts them again" (08:243) | the next init is `harness-paused-M1-svc` | that unit name | P1-04 |
| "harness status lists a running run's units with MemoryCurrent…" (08:213) | the slow session is `harness-termed-M1-s<n>` | `harness-termed-M1-s[0-9]+` | P1-04 |
| "a TERM to the driver mid-session stops the session's scope…" (08:219) | the session and services are the lane's | `U` from `--unit=harness-termed-M1-s[0-9]*`, the svc stop `harness-termed-M1-svc` | P1-04 |
| "memory gate: every session starts with the services up, a verify after its wait included" (08:265) | `svc_gaps` counts only `harness-<run>-s[0-9]+` units and `harness-<run>-svc` | the awk matches `harness-<run>-([A-Za-z0-9_]+-)?s[0-9]+` and `-([A-Za-z0-9_]+-)?svc` | P1-04 |
| "a TERM to the driver mid-session stops the session's scope…" (08:219), through `termed_left` (08:216) | it finds stub sessions by a cwd under `$T/wt/proj/termed*`; a lane's is `…/lanes/termed/slot-0`, so it would pass vacuously | also match `$T/wt/proj/lanes/termed/` | P1-04 |
| "scope.sh: scope_owns matches a unit to a run…" (08:21) | it asserts `! scope_owns demo harness-demo-x-svc.scope`; the spec's regex reads `x-` as a lane prefix | that assertion becomes `! scope_owns demo harness-demo-x-y-svc.scope` (a prefix has no `-`); the overlap it allows (run `proj-<date>` owning `proj-<date>-2`'s units) is already handled by `gc`'s rule that a live owner keeps a unit | P1-02 |
| "a .harness/teardown.sh added after the run started is run at its stop points" (08:444) | `STUB_ADD_TEARDOWN` adds the hook in the initializer, which D3 now reverts | the stub adds it in the first coding session (a lane commit, so the hook is the lane's and reaches main); text unchanged | P1-03 |
| "a session's edits to the journal are restored (E4 review F1)" (24:7) | a lane verify edits an untracked, discarded copy, so the git-diff guard never fires | text unchanged: the take-back's `cmp` of the copy against `$REC` gives the note (§3 `journal` row) | P1-03 |
| "a limit-cut session's passes is reverted, A retried" (22:6) | it greps a `HARNESS: usage limit` commit in the record list's history; the record list is never touched now | same intent, on the record: `harness/claim`'s `feature_list.json` never shows A passing in a commit before A's second session's entry (`git log -p`), and A retried | P1-03 |
| eval's `commits.json` (10:130, via `lib/eval.sh:130`) | eval reads `git log base..harness/$run`, now record-only, so `work-T2a.txt` is missing | `lib/eval.sh` reads `base..` over the run's tags and lane branches (`run/<run>/*`, `harness-lane/<run>/*`); check text unchanged | P1-03 |

The teardown markers (`$T/scratch/proj/<run>/teardown-*.marker`, `init-begin`, `teardown-begin`) and the stub's
`sessions.log` and `count-*` files move with the lane's scratch. Their checks keep their text: the fixture's
`.harness/teardown.sh` (`tests/lib.sh`) and `tests/stub-claude.sh` write those to the run's scratch,
`${HARNESS_SCRATCH%%/lanes/*}` (the stub's own bookkeeping, no live shape involved; the `count` files must stay
run-wide or `STUB_LIMIT_HITS=3` would count per lane). Every other check keeps its text; a P1 session that sees a
check outside these tables go red treats it as a bug in its code, not in the check.

### 10.3 New check files (one per topic; names into `tests/fixtures/check-names.txt`, 394 today)

- `tests/checks/35-lanes-scheduler.sh` (P1-02, pure, seconds): the five `F lanes`/`F next <m>` unit checks of the
  spec, `F pass`, `F deps`, a complete unverified milestone is a candidate, `scope_owns` for the `<m>-` roles.
- `tests/checks/36-lanes-record.sh` (P1-03): the `record` lock (two background writers, `HARNESS_RECORD_DELAY=0.05`,
  20 lines each → 40 intact lines); one stub run that covers: a session committing `.harness/runs/<run>/x` (revert
  note, `harness/<run>` unchanged by it, the lane branch reverted), a question above `## Answers` landing in the
  record's INBOX above that line with `answers_hash` unchanged, two sessions' flips both landing while the record
  moved between them; the base conflict note; the record tracked on main (skip-worktree: the session's commit
  carries none of the copy); the run-id `lanes` refused (D6).
- `tests/checks/37-lanes-run.sh` (P1-04): the `MAX_LANES=1` three-feature run (`done`, two PRs, `lane M1 opened
  (slot 0` before `lane M1 closed (`, the same for M2, `lane` on every coding metrics row, every entry on
  `harness/demo`, one worktree left), pause and stop (no `lanes/` left, every lane pid dead), the exit file.
- `tests/checks/38-lanes-continue.sh` (P1-05): continue mid-M2 on the same lane branch, the legacy refusal, the
  record-only continue, the `pr`-held dependency.

Each lanes file runs its own stub runs (a fresh `$T` each); the suite's wall time grows by about one file's slot
time over 4 jobs, measured and recorded by P1-04 (a number, not a gate).

## 11. Stub flags (`tests/stub-claude.sh`, P1-03)

Each copies a real shape: a session's `git add`/`commit`/`push`, or the phone's clone-edit-push that
`STUB_PHONE_STOP` already makes.

- `STUB_COMMIT_RECORD=<id>`: that feature's first session writes `$HARNESS_RUN_DIR/x`, `git add -f` it (what a
  session would type to beat the exclude), commits and pushes its branch.
- The question above `## Answers`: the existing `STUB_PARK=<id>` (its `sed -i '/^## Answers/i …'`, commit, push,
  final `PARKED:` line) is the shape; no new flag. Its commit now has nothing to commit (the copy is excluded), as a
  real session's would.
- `STUB_RECORD_MOVE=<id>`: during that session, as the phone does, a clone of the origin pushes an INBOX.md comment
  edit to `harness/<run>`, so the record moves while the slot holds its copy.
- The delayed bookkeeping is not a stub flag: `HARNESS_RECORD_DELAY` in `lib/record.sh` (§2), honoured in tests only.
- `tests/lib.sh` exports `HARNESS_LANE_POLL=1`; `bin/harness` passes it (and `HARNESS_RECORD_DELAY`) into tmux.

## 12. Order and the suite after each

1. **P1-02** pure pieces: `features.mjs lanes/next <m>/pass/deps`, `scope_owns`' role regex, the config defaults.
   Nothing calls them yet. Suite green, 394 + about 8.
2. **P1-03** the record branch, one loop still: `lib/record.sh` (the lock, `sessions`, `limits`, record writes);
   the loop opens `slot-0` per milestone and materializes; verify on the lane tip; the merge rules; taint and held
   deleted; §10.1 and P1-03's rows of §10.2 rewritten with the new invariant checks; `36-lanes-record.sh`;
   `journal/decisions/2026-10-26-lanes.md` started (P1's finding · choice · rejected; P2 completes it);
   `docs/architecture.md` §4, §7, §8. Green, the record checks rewritten from here on.
3. **P1-04** `lib/lane.sh` and the coordinator: units and scratch per lane, P1-04's rows of §10.2, the fixture and
   stub scratch paths, `finish`'s slot and branch cleanup, `metrics` `lane`; `37-lanes-run.sh`; architecture §3,
   §5. Green; the suite's time measured and recorded.
4. **P1-05** `harness continue` (attempts reset as today), the legacy refusal in `cmd_start`'s resume path (not under
   `HARNESS_MERGE_ONLY`: `harness merge` of a legacy run still works, the `lgm` and `legacy` checks keep their
   text), the record-only continue, the `pr`-held dependency; `38-lanes-continue.sh`; README. Green.

A run is legacy when `git -C "$RWT" diff --quiet "$(git merge-base origin/main HEAD)" HEAD -- . ':!.harness/runs'`
fails (code on the run branch that main doesn't have). Its message names the three ways forward: `harness merge
<run>` for its verified milestones; a new run with `--brief` naming the old branch as the source for what is left;
finishing by hand. Exit 1.

## 13. Defaults taken (recorded here; P1-03 copies them into `journal/decisions/2026-10-26-lanes.md`)

- **D1** *default*: in P1 a verified lane whose tag no longer equals `merge-tree main tag` needs Michael (once per
  main commit); P2's re-base rule replaces it.
- **D2** *default*: `gc`'s `record_only` is unchanged, so `gc` deletes a finished lanes run's record branch and its
  worktree before any record PR exists (P2 adds it); the ledger keeps the whole record. P1 and P2 both merge
  during this run, and the live checkout only syncs when no run is alive, so no live run sees the P1-only state
  unless this run ends between them.
- **D3** *default*: the initializer runs in the record worktree, and whatever it changes outside `.harness/runs/` is
  reverted (`restrict … record initializer`, noted), so the record branch stays record-only.
- **D4** *default*: a lane's services stay up after it closes until the next lane in its slot stops them silently or
  `finish` runs the teardown with the end reason (§6).
- **D5** *default*: the end reason's "waiting on Michael" names `needs-<m>` milestones that a remaining feature waits
  on, beside parked features.
- **D6** *default*: `harness start` refuses the run id `lanes` (it would be `$WT_ROOT/<project>/lanes`), like `desk`,
  `debrief` and `queue`.
- **D7** *default*: a session's unit number is `scope-seq` (every session of the run), not `$STATE/sessions` (coding
  only), so a verify and a coding unit never share a name; P1-04's step 1 says "n from $STATE/sessions": proposed
  change.

## 14. After the run (Michael)

Nothing live during the run (build-only). One consequence for this run itself: once P1 merges, the queue runner levels
the live checkout before any start (queue.sh:72), so an automatic continuation of `agent-harness-2026-10-26` (after a
session cap) would run the P1 driver, whose legacy refusal stops it: this run's branch carries P2 code beyond main.
P1-05 makes that refusal a note and a high-priority notification, never a silent exit. If it happens, Michael's step:
`harness merge agent-harness-2026-10-26` for what is verified, then a new run with `--brief "finish P2 of
docs/specs/2026-10-26-lanes.md; harness/agent-harness-2026-10-26 is the source"` (or P2 by hand). Before the next run starts: `MAX_LANES=2` in
`~/.config/harness/config.sh` (the runner syncs the live checkout before each start; the driver reads the config at
run start). The morning after: `grep -c "lane .* waiting" <run dir>/harness-log.md`, `jq .lanes <run
dir>/summary.json`, `mem_peak_mb` in `metrics.jsonl`, no OOM lines in `journalctl --user -b`, `systemctl --user
list-units 'harness-*'` empty. To undo: `MAX_LANES=1` (one lane at a time; the record branch stays).
