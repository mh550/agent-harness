# Throughput and memory: parallel milestone lanes, a split suite, and one memory model with scopes (2026-10-25)

**Status: design, awaiting Michael's approval.** Nothing here is built. The rollout order and his steps are in
`docs/plans/2026-10-25-throughput-rollout.md`. Once approved, the build specs are extracted from §4, §5 and §6 of
this file (one spec per run); the queued retro-fixes and memory specs are amended as §8 says.

**Source.** Michael's ask of 2026-10-25 22:00: implement the recommendations of the 16:32 status-check session
(split and parallelize the suite; parallel milestone lanes inside a run; `MAX_PARALLEL_RUNS=2` after L5), and while
doing so make the system more parallel, less redundant and faster **without creating new work** (no hand-fixed
merge conflicts, no orphaned worktrees, branches or data); make testing more targeted; and give the harness a
memory architecture that follows CoALA's buckets, ties each store to its scope, and grows with him.

## 1. What limits a run today (measured 2026-10-25)

| Where | Finding | Source |
|---|---|---|
| The driver | Serial inside a run. The lifecycle list marks L3, L4 and L5 `after: []`; retro's F1–F3 and memory's M1, M2, M5, M6 are independent too. None of it runs side by side. `docs/architecture.md` §15 lists this as the v4 candidate | `lib/driver.sh:567-650`, the three specs |
| The suite | `tests/run.sh`: one 1,078-line file, about 270 checks, about 8 min single-threaded (`CLAUDE.md` still says 3). In the lifecycle sessions that could be timed, 8–19 of each 17–30 minutes were suite runs; L2-01 (a plan, no code) spent 19 of 28 minutes in it. 47 commits since 10-17: the most-conflicted file in the repo | the 16:32 session's `suite_time.mjs`; `git log` |
| Where session time goes | lifecycle: model 40 % · suite 31 % · other tools 26 %. measure: 25 / 29 / 45. dj build: 61 / 11 / 25. hit_list: 41 / 10 / 40 | the 15:01 portfolio_site session, from gaps between model turns |
| Usage limits | Not limiting: five-hour window at 12 %, seven-day at 83 % with daily resets. D-H18 made runs serial on 10-17 when two runs spent the five-hour window in 2 h 49 min; today's numbers show several times that headroom | the 16:32 session |
| `MAX_PARALLEL_RUNS` | Irrelevant to the next three runs: all on `agent-harness`, and the queue allows one run per project (`decisions/2026-10-21-queue-one-run-per-project`) | `lib/queue.sh:39-41` |
| Memory | 15 GB box. L1 caps a session at 6 GB and a suite at 3 GB and waits under 5 GB free. Two sessions fit; three only if real peaks are well under the caps, which `mem_peak_mb` (L1-04) now measures | lifecycle L1 |
| Merge bookkeeping | One linear run branch makes a later milestone's tag contain earlier unverified work: the `tainted-<m>`/`held` rules, the "merge in list order" rule and the run record merged into `main` with every milestone all exist because of it | `docs/architecture.md` §7–§8 |
| Verify packs | `context.md for L1: 8033 bytes, 25 items left out`; `L2: … 29 items left out`. A verify pack is the whole milestone's record squeezed into a coding-sized cap | the lifecycle run's `harness-log.md` |

## 2. Goals, non-goals, anti-goals

**Goals.**
1. A run's independent milestones run at the same time, each verified and merged on its own, and the serial path
   is the same code with one lane.
2. Every change keeps the harness's two invariants: **what lands on `main` is byte for byte what was verified**, and
   **the driver is the only writer of refs, merges and the run record**.
3. Nothing a run creates outlives its use: a lane's worktree and branch exist only while the lane is alive; a
   crash is cleaned by the stop points and `harness gc` the lifecycle run just built.
4. The harness's own suite runs in about a quarter of the time, in independent files, so sessions iterate on one
   file and run everything once, and parallel branches stop colliding on it.
5. One memory model: every fact has one store, chosen by its CoALA bucket and its scope, with one writer kind and
   one mutation rule (append or in place). Written down once, enforced where it can be by the driver.
6. The next two queued runs (retro, memory) run on the new machinery, and the queue reaches them with the least
   delay.

**Non-goals.** Parallel *features* within a milestone (§4.9 says what would make that safe later); a second
scheduler between runs (the queue stays one run per project); an LLM curator, embeddings or a facts database for
memory; changing projects' suites (a project-specific test-impact map is that project's business).

**Anti-goals** (a failure even if the code works). A night that ends with a merge conflict Michael has to fix by
hand. A lane worktree or branch left behind by a normal end. Two writers of `entries.jsonl` or `feature_list.json`.
A relaxation of the verified-tree invariant that lets unverified code reach `main`. A memory rule that lives in two
places.

## 3. Constraints

- `CLAUDE.md` of this repo binds every build: worktree only, never touch real runs or state, fakes mirror the live
  API, every behaviour visible in `harness-log.md` and checked in `tests/run.sh` test-first, a decision file per
  behaviour change, `docs/architecture.md` and `README.md` in the same milestone. bash + node stdlib + jq + git + gh
  + tmux + flock; no npm packages.
- The lifecycle run is live until about 02:00 on 10-26 and edits `lib/driver.sh`, `lib/check.sh`, `bin/harness`
  (`cmd_gc`), `lib/queue.sh` and `tests/run.sh`. Its `sync_main` merges `origin/main` into its branch before every
  verify, so anything merged to `main` tonight that touches those files would conflict there. New files are safe.
- Policy (`~/.claude/CLAUDE.md`): queue changes and run starts are Michael's; a session may run `status`,
  `report`, `parked`, `sync` and `gc` on its own project.
- The lifecycle run's L1–L4 are the base: scopes named `harness-<run>-<role>[-<n>]`, `services_down` at every stop
  point, scratch deleted at finish, `gc --all-merged --deps` run by the queue runner. Lanes must fit those names
  and stop points so no new cleanup is needed.

## 4. Parallel milestone lanes

### 4.1 The model

A **lane** is one milestone: its features in list order, then its verify, then its merge. Lanes are the unit of
parallelism, of branching and of merging. The run keeps one **record branch**, `harness/<run>`, that holds only the
run record (`.harness/runs/<run>/`) and is written by the driver alone. Code lives only on lane branches.

```
harness start ─► record worktree ~/worktrees/<p>/<run> on harness/<run> (the run record; no code commits)
  ─► initializer (in the record worktree, as today; its only product is the record)
  ─► coordinator loop:
       open a lane for every milestone whose dependencies are verified, within MAX_LANES and the memory gate
         lane worktree ~/worktrees/<p>/lanes/<run>/<m> on harness-lane/<run>/<m>, branched from
         origin/main merged with each dependency's tag (which is origin/main when they have merged)
       each lane, as its own process (lib/lane.sh): init → suite → context → coding session → bookkeeping (under the
         record lock) … → verify → tag run/<run>/<m> → merge its PR → remove its worktree and branch
       reap lanes; end when no lane is alive and none can open
  ─► finish: summary, retro, ledger, as today
```

`MAX_LANES=1` (the default) is today's behaviour in structure: milestones one after another, each on its own
worktree. There is no separate serial code path; the coordinator with one lane *is* the serial driver.

### 4.2 What changes and what doesn't

| | Today | With lanes |
|---|---|---|
| Branches | `harness/<run>` holds code and record | `harness/<run>` holds the record only; `harness-lane/<run>/<m>` holds milestone `<m>`'s code (git forbids `harness/<run>/<m>` beside `harness/<run>`) |
| Worktrees | one, `~/worktrees/<p>/<run>` | the record worktree, plus `MAX_LANES` **slots** `~/worktrees/<p>/lanes/<run>/slot-<k>`, each reused by one lane after another (`git checkout -B` keeps `node_modules`, `.venv`, `.next`, so a milestone never re-installs), all removed at `finish` |
| A milestone's tag | the run branch at the point `<m>` finished: contains every earlier commit, verified or not | the lane tip: its base (`origin/main` merged with its dependencies' verified tags) + `<m>`'s commits only. A tag never contains unverified work |
| Merge rule | list order; `tainted-<m>` and `held` for tags carrying other milestones' work | dependency order: a lane's PR is opened at verify, and merged only once every dependency is merged (one check, `merged-<dep>`; under `auto` that is seconds later, under `pr` whenever Michael merges). The taint machinery goes because a tag can't carry unverified work; "main moved" is §4.6 |
| The run record on `main` | merged with every milestone PR | never inside a code PR. At `finish` the driver opens one **record PR** (`.harness/runs/<run>/` only, from the record branch; `RECORD_PR=end`, `off` to skip) so a project's history still holds its runs, with no conflict possible (the path is unique). Until then the record branch, pushed after every session, is the phone view, and the ledger keeps a copy |
| Verify | blocks the loop | a lane job; other lanes keep going |
| A given-up or parked feature | ends the run unless everything left is independent (R10 fixes the default) | stops its lane and its dependants only; the run ends when no lane can move (R10's change 3 falls out of this) |
| Ports, scratch, scopes | one per run | one per lane: `PORT` from `BASE_PORT` upward, `$SCRATCH/lanes/<m>`, units `harness-<run>-<m>-s<n>`, `harness-<run>-<m>-check-<pid>`, `harness-<run>-<m>-svc` |
| Suite cache | `green-<key>` per tree in `$STATE` | the same, shared by all lanes (same tree, same result) |
| Session numbering, `MAX_SESSIONS`, `MAX_LIMIT_HITS` | loop counters | run-wide counters in `$STATE` under the record lock |

### 4.3 The record is single-writer

Sessions must read the record (`feature_list.json`, `context.md`, `INBOX.md`, `brief.md`, `entries.jsonl` for the
full history) and write three things: `entry.json`, their own `passes`, and a question above `## Answers` in
`INBOX.md`. In a lane:

1. Before a session, the lane **materializes** the record: it copies `.harness/runs/<run>/` from the record
   worktree into the lane worktree and excludes that path **for this worktree only** (`extensions.worktreeConfig`
   plus a per-worktree `core.excludesFile`; `.git/info/exclude` is shared by every worktree of the repository and
   would hide the record from the record worktree's own `git add -A`), so `git add -A` in the lane never stages it
   and no lane commit carries it. (`RUN_DIR` in the prompt is unchanged: the same relative path.)
2. After the session, under `flock $STATE/record.lock`: take `entry.json`; run `features.mjs repair` on the lane's
   copy against the pre-session snapshot (only the session's own feature may change, as today) and then **apply the
   flip to the record's list** (a new `features.mjs pass <list> <id>`, the mirror of `unpass`), never copy the lane's file over it, since another
   lane may have flipped its own feature meanwhile; take the lines the session added above `## Answers` in `INBOX.md` (`notify.mjs question` already computes
   them) and append them to the record's `INBOX.md`; ingest, render, append metrics, `note`, commit on the record
   branch, push. Then `rm -rf` the lane's copy so the next materialization is fresh.
3. A lane commit that touches `.harness/runs/` (a session that forced it) is reverted by a new commit, as
   `restrict` does for verify, and noted.

`take_answers`, `sync` of the record branch (Michael's phone edits), `limit_wait`'s markers and the shared
`LIMIT_UNTIL`/`USAGE_7D` all run under the same lock or are already box-wide files. Everything that was a global in
the driver loop becomes a file in `$STATE`.

### 4.4 Scheduling (pure, in `features.mjs`)

`lanes <list> <attempts> <max> <parked> <state>` → the milestones that can open now, in list order, and for each
open lane its next feature. A milestone can open when every milestone named by its first feature's `after` (and by
any other feature's `after` that points outside the milestone) has `verified-<m>` in `$STATE`, and it isn't
`needs-<m>`, verified, merged or already open. Inside a lane, a feature with no `after` depends on the earlier
features of its own milestone: this is R10's change 1, and it becomes the only rule, because cross-milestone
order is the lane graph. Features without a milestone form one lane named `default`, in list order, opened first.

A milestone whose first feature has no `after` waits on every earlier milestone (D-H25 as today) and never opens
beside one; only declared independence runs in parallel.

Admission, checked by the coordinator before each open: lanes alive `< MAX_LANES`; `MemAvailable ≥
MEM_MIN_AVAILABLE_GB + LANE_RESERVE_GB × lanes alive` (`LANE_RESERVE_GB=4`: a session's typical peak with the suite
running inside it; the worst case under L1's caps is 6 + 3 GB, and `mem_peak_mb` from L1-04 is the figure to tune
it with); the five-hour window, when the newest session reported one, under `LANE_OPEN_BELOW_5H=70` %. On this
box (15 GB, about 10 GB available idle) that is **two lanes**: a second opens at 9 GB free, a third would need 13.
A lane that can't open for headroom is logged once (`lane M4 waiting: MemAvailable 6.1 GB < 9 GB`) and tried
again next loop.

### 4.5 One lane's life (`lib/lane.sh`)

The per-feature body of today's loop moves here unchanged in substance: `run_init` (the lane's services scope and
port), `context`, the clock line, the coding session in the lane's scope, `WIP:` commit, journal, the environmental
branch (attempt given back, `LIMIT_UNTIL` set), repair, red-suite un-pass, metrics, park. The differences: every
record write is under the lock (§4.3); the lane's exit code tells the coordinator why it ended (`done`, `given up
<id>`, `parked <id>`, `needs Michael`, `limit`, `stopped`); and when the milestone is complete the same process runs
`verify` (merge `origin/main` in, the verify session, evidence count, escalation, suite green on that tree, tag,
push the tag), then `merge_one`, then removes its own worktree and branch (§4.7).

A lane honours `PAUSE`/`STOP` between sessions as the loop does today, and `services_down` runs in its EXIT trap, so
a killed lane leaves no server behind.

### 4.6 Merging: the invariant, kept, and "main moved" without a wait

`merge_one` keeps its rule: the tag merges only when `git merge-tree origin/main <tag>` yields exactly the tag's
tree. With lanes that is the normal case at verify time, because verify merged `origin/main` in first. The one new
case is common now: lane A merges while lane B is being verified, so B's tag predates A's content on `main`.

Rule: a tag that no longer satisfies the invariant is **re-based by the lane, not held for a later milestone**:
1. merge `origin/main` into the lane (a conflict → `needs Michael`, exactly today's path);
2. if the files `main` brought in are **disjoint** from the files the milestone changed
   (`git diff --name-only <tag>..HEAD` against `git diff --name-only <merge-base>..<tag>`), run the suite on the
   merged tree in the lane's check scope; green → tag the merged commit as `run/<run>/<m>` (moving the tag is a
   new annotated tag with the same name; the old object stays reachable from the PR), `note "<m> re-based on
   <main>: disjoint files, suite green; re-tagged"`, merge;
3. if they overlap, one more verify round on the merged tree (bounded by `MAX_VERIFY_ROUNDS`, as today), then tag
   and merge.

Why 2 is still the invariant: the verifier's evidence is about the milestone's files, which are unchanged; the suite
is the integration check the harness already trusts for `passes`. This is a decision file
(`decisions/<date>-lane-rebase-disjoint`), with the overlap case kept strict and its own round counter
(`MAX_REBASE_ROUNDS=1`), separate from the lane's verify rounds. `LANE_REBASE=verify` turns 2 off for a project
that wants a verify session every time.

Under `MERGE_POLICY=pr` (portfolio_site) the PR waits for Michael, possibly days, and `main` may move meanwhile.
Today `harness merge <run>` re-runs `merge_one` in a bare driver and reports "held". With lanes, `harness merge
<run>` reopens a slot from the tag, runs the same re-base, and either merges or says exactly which files overlap.
Dependants of a `pr`-held milestone still open (on `verified-<dep>`, branched from its tag) and their PRs queue
behind it, so a `pr` project loses no parallelism, only the automatic landing it already doesn't have.

### 4.7 Cleanup: a slot exists only while the run is alive, a branch only until it merges

- **Slots, not a worktree per milestone.** A lane opens in a free slot (`slot-<k>`, `k < MAX_LANES`), creating the
  worktree the first time and `git checkout -B harness-lane/<run>/<m> <base>` after that, so ignored build and
  install directories survive from one milestone to the next (today's one-worktree behaviour, per slot). With
  `MAX_LANES=1` a run has exactly one slot, so install cost is unchanged from today; with two, two installs per
  run. `HARNESS_CACHE` (L3) stays the place for installs that should outlive runs.
- When a lane's PR merges: `git branch -D` locally and `git push origin --delete harness-lane/<run>/<m>` (merged
  content: recoverable from the tag and `main`); the slot is freed; the tag stays. Under `pr`, a verified lane frees
  its slot at once and keeps its branch until the PR merges; `harness gc` deletes it then.
- At `finish`, whatever the reason: every slot is removed (`git worktree remove --force`); lane branches of
  **unverified** milestones are kept on origin (that is the unmerged work), and `harness continue` reopens each
  from `origin/harness-lane/<run>/<m>` into a slot. So after any end there is one worktree per run, the record's.
- `harness gc`: the `harness-lane/*` prefix joins the `harness/*` and `harness-merge/*` passes of L4's rewritten
  loop; a slot under `~/worktrees/<p>/lanes/` whose run has `ended` and no live driver is removed by the existing
  worktree pass (it matches `$WT_ROOT/*`); `--deps` covers slots too. Units are under `harness-<run>-…`, so L2's
  orphan-unit stop and L3's tmux and scratch rules apply unchanged.
- The record branch of a finished run: with no code on it, `gc`'s `record_only` test is always true; the branch
  goes once the record PR (§4.2) is merged and nothing is queued, as today.

### 4.8 Visibility and control

`harness status <run>` prints a line per open lane (milestone, feature, session number, port, units and
`MemoryCurrent` from L2-05). `harness-log.md` gains `lane <m> opened (from <sha>, port <n>)`, `lane <m> closed
(<why>)`, the admission waits, and the re-base notes. `harness pause|stop` apply to every lane between sessions.
`harness attach` opens the record's tmux session; lane sessions log to `logs/NN-<id>.jsonl` as today, with the
lane in each `metrics.jsonl` row (`lane: "<m>"`). The summary adds `lanes: {max_open, lane_hours, wall_hours}` so
the gain is a number in the ledger.

### 4.9 What is left to the builder, and what comes later

Builder's: the exact lock granularity (one lock for the record is the floor; a second for the push is allowed),
how the coordinator waits (a `wait -n` loop or a poll at `HARNESS_PAUSE_POLL`), the lane exit-code table, the
stub-claude flags for the new checks, port allocation when two lanes open in the same second (one lock), and the
tmux layout (one window per lane in the run's session is enough).

Later, not now: **feature-level lanes** inside a milestone. The hook is already there: a feature whose `after`
names only features outside its milestone, or `[]`, could open as a lane of one on top of its milestone's lane
branch. It is not built because milestones are planned as coherent units (plan → build → review) whose features
edit the same modules, so parallel features inside one would produce exactly the conflicts the anti-goals forbid.
If the initializer ever plans milestones whose features are independent, that rule is a `features.mjs` change and a
flag, not a redesign. Also later: `MAX_PARALLEL_RUNS=2` is Michael's one-line config change after L5, and lanes
make it safe to try (the admission gate is per box, not per run).

### 4.10 Legacy runs: no frozen driver

A frozen copy of today's driver would still call `features.mjs`, `entries.mjs`, `check.sh` and the rest, which the
very next runs change, so it would rot within a week or pin every later run to compatibility checks. Instead:

- A run whose branch carries **no code commits** beyond the record (n8n-home-2026-10-22 at 0/32: a feature list
  and nothing else) continues under the lanes driver as it stands: its record branch is already a record branch.
- A run whose branch carries **unmerged code** (rane-one-mixxx-2026-10-24, 9/19, waiting on Michael at M5-06) is
  refused by `harness continue` with the three ways forward printed: `harness merge <run>` for its verified
  milestones; a new run with `--brief` naming the old branch as the source for what is left; or finishing it by
  hand. The window to continue such a run on today's driver is before the lanes run merges.
- Every other run has ended `done`, and `harness gc` already handles their branches.

Which runs matter is Michael's call (§8 of the rollout plan asks).

## 5. Targeted and faster testing

### 5.1 The harness's own suite, split and parallel

- `tests/run.sh` becomes a runner over `tests/checks/NN-<topic>.sh`. Each file sources `tests/lib.sh` (the
  `check`, `hlog`, `list`, `on_main`, `curl_*`, `win*`, stub environment and throwaway-project setup that the top
  of today's file holds) and runs in its own `$T`, its own private tmux socket and its own state root, so files
  never share state. The sections already in the file (`# ---- …` markers: scheduler, notifications, parked,
  render, metrics, eval, deploy, journal, run 1 "misbehaving sessions", run 2 …) are the first cut; each driver run
  ("run N") is one file.
- The runner executes files in parallel, `TEST_JOBS` wide (default: `nproc/2`, at most 4), **inside the one check
  scope** `check.sh` already runs the suite in: systemd scopes don't nest, so inner scopes would be siblings
  outside the 3 GB cap and outside `scope_stop`'s reach. The whole parallel suite shares `CHECK_MEMORY_MAX`; this
  repo sets it to 4G in `.harness/config.sh` if the measured peak (L1's `mem_peak_mb`, and `check.out`'s RED line
  on a kill) says so. The runner prints `PASS`/`FAIL` lines as files finish and ends with `N/M checks passed` as
  today, so `testcount.mjs` and the driver's RED/GREEN parsing are unchanged. The one or two checks that start a
  real 64M scope (L1's rule) stay as they are: siblings by design, stopped by their own cleanup.
  `tests/run.sh <pattern>` runs the matching files only, which is what `check.sh <args>` already passes through,
  so a session iterates on `check.sh 40-gc` and runs `check.sh` once before flipping `passes`.
- A conformance check: the split suite has the same check names as the last single-file suite (a fixture list),
  so no check is lost in the move.
- Target: under 2.5 minutes wall for the whole suite on this box. The 16:32 session's estimate is 25–40 % less
  wall time per feature on agent-harness runs; the summary's `time.by_role` and `lanes.wall_hours` will say.

### 5.2 The cache key ignores what the suite never reads

`treekey.mjs` hashes the whole tracked tree, so a plan-only feature (a new file under `docs/plans/`) runs the full
suite before and after its session. `CHECK_KEY_IGNORE` (space-separated prefixes; harness default
`.harness/runs docs/plans`; a project extends it in `.harness/config.sh`, this repo adds `journal
findings-and-research ledger`) is dropped from the key. The key is a cache, not a gate: anything that changes a
tested file still runs.

### 5.3 Targeted testing in sessions, project-agnostic

Three rules, one place (`prompts/coding.md` §2, already half there), plus the driver making them cheap:

1. **Iterate on a subset, run everything once.** The prompt names the subset form and the one full run before
   `passes`; the memlint-style note `note "<id>: full suite ran <n> times in the session"` (counted from
   `check.out` timestamps) makes a session that ran it five times visible to the retro.
2. **Never re-run a command that was killed at the cap** (L1's prompt line).
3. **A verify session runs the suite once**, in full, uncached (R4), and otherwise re-runs steps, not suites.

Rejected: running the post-session suite asynchronously while the next session starts in the same lane. The suite
result gates `passes` and the next session's starting tree; overlapping them means building on a tree that may be
red and un-passing retroactively, which muddles attribution for a few minutes' gain. Lanes give the same overlap
across milestones without that cost.

## 6. The memory model, with scopes

CoALA's four buckets, each store tied to a scope, with one writer kind and one mutation rule. This table is what
M2's "Memory model" section in `docs/architecture.md` writes down; the queued memory spec builds most of it, and
§8 lists the few additions.

| Scope | Working (what this actor sees now) | Episodic (what happened; append-only ledger) | Semantic (what is true now; edited in place, one writer kind) | Procedural (how to work; in place, reviewed) |
|---|---|---|---|---|
| **Session** | the prompt; `context.md`; the auto-loaded `CLAUDE.md`. Derived by the driver, never hand-edited | its transcript (`logs/*.jsonl`, state, not committed); its `metrics.jsonl` row; its `entry.json` → one line of `entries.jsonl` | none: a session has no durable truth of its own; it proposes (entry `discoveries`, `questions`, `proposed_changes`) | none |
| **Lane** | — | the lane column in `metrics.jsonl` and the `lane …` notes | none (operational state only: port, pid, scratch; deleted with the lane) | none |
| **Run** | `context.md` per session (cap per kind, §8) | `entries.jsonl` (driver-only writer), `harness-log.md`, `progress.md`/`-archive.md` (rendered views), `brief.md` (append per segment), `INBOX.md` questions (sessions append), `retro.md`, `summary.json`/`report.md` (derived) | `INBOX.md` `status:` line and `## Answers` (Michael, in place/append); `feature_list.json` `passes` (the only session-writable truth, guarded); `discoveries` with `affects: ["run"]` (run-scoped facts, read through the pack) | the run's `brief.md` (scope for this run; never `CLAUDE.md`) |
| **Project** | — | `.harness/runs/<run>/` on its record branch; `docs/plans/` (one per milestone); specs (intent; superseded in place at the top) | the decisions store (`DECISIONS=`: a file with the "current rule set" header, or a directory of one file each; overturned → rewritten in place with one `Updated in place <date>` line); `## Gotchas` in `CLAUDE.md` (≤ 15 lines, in place); `docs/hard-won-facts.md` where a project prefers a pointer | `CLAUDE.md` (all but Gotchas), `.harness/config.sh`, `.harness/{check,init,teardown}.sh`, `.claude/settings.json` gates. Writer: Michael, or a session through a PR |
| **Harness** (the supervisor: driver, queue, debrief, desk) | the initializer's calibration line (derived from the ledger each time, never stored); the debrief's `context.md` | `ledger/runs.jsonl`, `ledger/<p>/<run>/` (the record copied at the end), `queue/runner.log`, `journal/` (iterations, sessions, evidence: Michael's narrative, append per iteration) | `ledger/retro-backlog.jsonl` (M1: keyed by id, status moved in place by the CLI, runs_seen appended; a map stored as JSONL, not a ledger); `ledger/debrief.md` (a view: overwritten, history in git) | `lib/`, `prompts/`, `policy/`, `templates/`, `journal/decisions/` (one file each, in place), `docs/architecture.md` ("the system as it is") |
| **User** | — | — | Michael's own notes (not the harness's) | `~/.claude/CLAUDE.md` (the one policy home), `~/.claude/settings.json`, `~/.config/harness/config.sh`. Writer: Michael; the harness ships templates and an apply script |

Rules that follow from the table, each enforced where the driver can:

1. **Append or in place is decided by bucket, not by file type.** Episodic stores only grow; a mistake there is a
   new entry (`dead_ends`), never an edit. Semantic stores are rewritten in place with one dated line; a dead rule
   beside a new one is the lint finding (M4). Procedural stores change through review. Working stores are
   derived and may be regenerated at any time.
2. **One writer kind per store.** The driver writes the run's episodic stores and the ledger; sessions write their
   `entry.json`, their `passes`, project semantic files, and code; Michael writes `INBOX.md` answers, user and
   policy files; the CLI moves backlog status. `restrict`, `journal()` and `repair` already enforce three of these;
   the lane materialization (§4.3) enforces the record's.
3. **Scope is declared, not inferred.** An entry's `discoveries[].affects` already carries the scope (a feature,
   a milestone, `"run"`); it gains `"project"` for a fact that outlives the run. The pack shows `"project"`
   discoveries under "Promote to Gotchas" until a coding session writes them (M3's step), which makes promotion
   visible instead of relying on the session noticing a repeat.
4. **Derive, don't store.** Test counts, file lists, calibration, "needs Michael" lists and the debrief are all
   computed from the ledger or the tree. memlint (M4) flags stored copies.
5. **Working memory has a budget per role.** `CONTEXT_PACK_BYTES` stays 8 KB for coding; verify gets
   `CONTEXT_PACK_BYTES_VERIFY=16384` with failed evidence rows first (the lifecycle log shows 25–29 items left
   out of every verify pack today). The initializer gets the calibration line and, new, the project's `## Gotchas`
   lines are already in its auto-loaded `CLAUDE.md`, so nothing to add.
6. **Lanes add no store.** A lane's state is operational and dies with it; its facts go through the same entry.

What grows with this: a new scope (a team member, a second box) is a new column with the same four buckets; a new
store must name its bucket, scope, writer and mutation rule before it exists (the architecture section is the
registry); a new actor (a review desk, a nightly auditor) is a new writer kind in rule 2.

## 7. Risks and how each is bounded

| Risk | Bound |
|---|---|
| Two lanes edit the same file (both touch `docs/architecture.md`, `README.md`, `tests/run.sh`) | §5.1 removes the biggest hotspot; §4.6 re-bases disjoint changes without a session and sends overlaps to one verify round; a true conflict is `needs Michael` once, as today. The initializer prompt gains one line: milestones that may run side by side should touch different files, and shared docs are edited in the closing review feature |
| Memory: three sessions plus three suites exceed 15 GB | the admission gate (§4.4) plus L1's per-session and per-suite caps; `MAX_LANES` defaults to 1 and the first night runs at 2 |
| The record lock serializes bookkeeping | each critical section is seconds (ingest, render, commit, push); sessions (minutes) run outside it |
| A lane process dies without its trap (SIGKILL) | `harness gc` reaps its unit, worktree and tmux window by the L2–L4 rules; `harness continue` reopens the lane from its branch |
| The first real use of lanes is a run that edits the driver | the lanes run itself is serial (built by the current driver); its first user is the retro run (F1 ∥ F2, small), the second the memory run (four lanes) |
| Usage: lanes spend the five-hour window faster | `LANE_OPEN_BELOW_5H`; `limit_wait` is box-wide already; `MAX_LIMIT_HITS` is run-wide |
| The split suite hides a lost check | the conformance check against the last single-file list |

## 8. What this does to the queued specs

- **Retro fixes** (`2026-10-21-retro-fixes.md`): R10's change 1 and change 3 are subsumed by lanes (§4.4, §4.2);
  R10's change 2 (the initializer asks for `after` on independent features) and R3's lint stay. F3 is dropped from
  the run and the spec says so at the top. F1 and F2 are unchanged and independent: two lanes.
- **Memory** (`2026-10-25-memory.md`): M1–M6 stand. Additions, small: the scope column and rules 1–6 above go
  into M2's architecture section; `"project"` as an `affects` value and the pack's "Promote to Gotchas" part join
  M3; `CONTEXT_PACK_BYTES_VERIFY` joins M3's pack change. M1, M2, M5, M6 are independent: four lanes, then M3 and
  M4.
- **Resource lifecycle**: nothing; lanes are built on its names and stop points.
- `docs/architecture.md` §15's first bullet is replaced by the lanes section; D-H18 ("runs serial", 10-17) gets a
  superseding decision file citing today's usage numbers; `decisions/2026-10-21-queue-one-run-per-project` stands.

## 9. What is left to the builder

The lock and wait mechanics (§4.9); the exact `features.mjs lanes` output format; the stub flags that make a stub
session slow, leave a server, or conflict, for the new checks; the split's file boundaries beyond the existing
section markers; the wording of the `harness status` lane lines; the decision files' text.

One thing is **in scope, not left open**: P1's acceptance "a run on lanes passes every existing check" means the
checks' intent, not their text. The checks that assert the record on a tag or on `main` (`run/demo/M2:
.harness/runs/demo/entries.jsonl`, `on_main run/demo/M2` for record files, the gc "record-only" block) are rewritten
in P1 to assert the record on the record branch and in the record PR, and that no code PR touches `.harness/runs/`.

## 10. Calls made in this design (Michael can veto any)

- Dependants open on `verified-<dep>`, not `merged-<dep>`, and merge in dependency order (§4.2, §4.6).
- The disjoint re-base (§4.6) counts as keeping the verified-tree invariant; overlaps get a verify round.
- Worktree slots reused across milestones (§4.7), not a fresh worktree per milestone.
- A run's record reaches `main` through one record PR at `finish` (§4.2), not inside code PRs.
- No frozen legacy driver; a legacy run with unmerged code is refused with its options (§4.10).
- The split suite's jobs share one check scope (§5.1); `TEST_JOBS` is bounded by that cap, not by its own.
- Lanes subsume R10's scheduling changes; the retro run shrinks to F1 and F2 (§8).
